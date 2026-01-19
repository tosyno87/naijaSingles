#!/bin/bash
# Helper script to deploy createTestUsers function using temporary index approach
# This is needed because the function uses runWith() options and can't be deployed
# together with existing Gen 1 functions

set -e

cd "$(dirname "$0")/.."

echo "🚀 Deploying createTestUsers function..."
echo ""

cd functions

# Create temporary index file
cat > src/index.deploy.ts << 'EOF'
import * as admin from 'firebase-admin';
import {TestUserHandlers} from './handlers/testUserHandlers';
admin.initializeApp();
const testUserHandlers = new TestUserHandlers();
export const createTestUsers = testUserHandlers.createTestUsers;
EOF

# Backup and swap
if [ -f src/index.ts ]; then
  mv src/index.ts src/index.full.ts
fi
cp src/index.deploy.ts src/index.ts

# Build
echo "📦 Building..."
npm run build

# Deploy
echo "🚀 Deploying..."
cd ..
firebase deploy --only functions:createTestUsers

# Restore
cd functions
mv src/index.full.ts src/index.ts
rm -f src/index.deploy.ts

echo ""
echo "✅ Deployment complete!"
