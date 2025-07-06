#!/bin/bash

echo "🚀 Setting up GitHub Actions for NaijaSingles"
echo "============================================="

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ This is not a Git repository. Please run 'git init' first."
    exit 1
fi

# Check if GitHub workflows directory exists
if [ ! -d ".github/workflows" ]; then
    echo "✅ GitHub workflows directory created"
else
    echo "✅ GitHub workflows directory already exists"
fi

echo ""
echo "📋 GitHub Actions workflows created:"
echo "   1. flutter_tests.yml - Runs on every push/PR"
echo "   2. code_quality.yml - Checks code quality"
echo "   3. build_and_deploy.yml - Builds releases"
echo "   4. comprehensive_tests.yml - Full test suite"

echo ""
echo "🔧 Next steps:"
echo "   1. Commit these workflow files:"
echo "      git add .github/"
echo "      git commit -m 'Add GitHub Actions workflows'"
echo ""
echo "   2. Push to GitHub:"
echo "      git push origin main"
echo ""
echo "   3. Go to your GitHub repository"
echo "   4. Click 'Actions' tab to see workflows running"

echo ""
echo "⚡ What happens automatically:"
echo "   ✅ Tests run on every code push"
echo "   ✅ Code quality checks"
echo "   ✅ Bio screen single selection test"
echo "   ✅ Performance monitoring"
echo "   ✅ Security vulnerability checks"
echo "   ✅ Build artifacts for releases"

echo ""
echo "📊 You'll get notifications when:"
echo "   🟢 All tests pass - ready to deploy"
echo "   🔴 Tests fail - need to fix issues"
echo "   📈 Performance degrades"
echo "   🔒 Security issues found"

echo ""
echo "🎯 Benefits:"
echo "   • No more manual testing before releases"
echo "   • Catch bugs before users do"
echo "   • Automatic quality assurance"
echo "   • Team collaboration with PR checks"
echo "   • Deployment confidence"

echo ""
echo "✨ Your NaijaSingles app now has enterprise-level CI/CD!"
