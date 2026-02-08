# Firestore Rules Migration Guide

## 🚀 **Safe Migration Steps**

### Step 1: Backup Current Rules
```bash
# Export current rules
firebase firestore:rules > firestore_rules_backup_$(date +%Y%m%d).txt

# Verify backup
cat firestore_rules_backup_*.txt
```

### Step 2: Test New Rules Locally
```bash
# Install Firebase emulator
npm install -g firebase-tools

# Start emulator with new rules
firebase emulators:start --only firestore

# Test your app against emulator
flutter run --dart-define=USE_EMULATOR=true
```

### Step 3: Deploy Gradually

#### Option A: Direct Deployment (Recommended for MVP)
```bash
# Copy improved rules to firestore.rules
cp firestore_rules_improved.txt firestore.rules

# Deploy new rules
firebase deploy --only firestore:rules

# Monitor for 24 hours
firebase firestore:rules --help
```

#### Option B: Staged Deployment (For Production)
```bash
# Deploy to staging first
firebase use staging
firebase deploy --only firestore:rules

# Test thoroughly
# Then deploy to production
firebase use production
firebase deploy --only firestore:rules
```

### Step 4: Monitor & Rollback Plan
```bash
# Monitor error rates
firebase functions:log

# If issues occur, rollback immediately
firebase deploy --only firestore:rules firestore_rules_backup_*.txt
```

## 🧪 **Testing Checklist**

### Before Deployment
- [ ] Chat creation works between matched users
- [ ] Chat creation fails for non-matched users
- [ ] Blocked users cannot send messages
- [ ] Message validation works (length limits)
- [ ] Profile updates work for allowed fields
- [ ] Profile updates fail for protected fields

### After Deployment
- [ ] Monitor error logs for 24 hours
- [ ] Check user reports for chat issues
- [ ] Verify real-time messaging still works
- [ ] Test edge cases (new matches, blocks, etc.)

## 🔄 **Rollback Procedure**

If issues occur:

1. **Immediate Rollback**
```bash
# Use backup rules
firebase deploy --only firestore:rules firestore_rules_backup_*.txt
```

2. **Investigate Issues**
```bash
# Check logs
firebase functions:log --limit 100

# Check rule evaluation
# Use Firebase console > Firestore > Rules playground
```

3. **Fix and Redeploy**
```bash
# Fix issues in improved rules
# Test locally again
# Deploy with monitoring
```

## ⚡ **Quick Implementation**

For immediate security improvement, you can implement just the critical fixes:

### Minimal Security Update
```javascript
// Add this to your existing chatThreads rule
match /chatThreads/{threadId} {
  // Add match verification to create
  allow create: if request.auth != null &&
                 request.auth.uid in request.resource.data.userIds &&
                 // Quick match check (adjust based on your match document structure)
                 exists(/databases/$(database)/documents/matches/$(request.resource.data.userIds[0] + '_' + request.resource.data.userIds[1])) ||
                 exists(/databases/$(database)/documents/matches/$(request.resource.data.userIds[1] + '_' + request.resource.data.userIds[0]));
  
  // Keep existing read/update/delete rules
}
```

### Message Length Validation
```javascript
// Add to your existing messages rule
match /chatThreads/{threadId}/messages/{messageId} {
  allow create: if request.auth != null && 
                 // ... existing conditions ...
                 request.resource.data.text.size() <= 1000; // Add this line
}
```

## 📞 **Support & Troubleshooting**

### Common Issues

1. **"Permission denied" after deployment**
   - Check if match documents exist in expected format
   - Verify userIds array structure in chatThreads

2. **Existing chats stop working**
   - May need to migrate existing chat documents
   - Consider adding temporary compatibility rules

3. **Performance issues**
   - Monitor rule evaluation time
   - Consider simplifying complex conditions

### Debug Commands
```bash
# Check rule syntax
firebase firestore:rules --help

# View current rules
firebase firestore:rules

# Test specific operations
# Use Firebase console Rules Playground
```

## 🎯 **Success Metrics**

After migration, monitor:
- [ ] Chat creation success rate
- [ ] Message delivery success rate
- [ ] User complaint reduction
- [ ] Security incident reduction
- [ ] App performance metrics

The migration should improve security without impacting user experience.
