#!/bin/bash
# Delete Safe Remote Branches - Following GitFlow Best Practices
# This script deletes branches that are already merged or clearly abandoned

set -e

echo "🧹 Cleaning up remote branches..."
echo "=================================="
echo ""

# Category 1: Already Merged Branches (Safe to Delete)
echo "📦 Category 1: Deleting already-merged branches..."
MERGED_BRANCHES=(
    "origin/feature/communities-hub-redesign"
    "origin/feature/communities-redesign"
    "origin/feature/database-schema-routes-overhaul"
    "origin/feature/incremental-enhancements"
)

for branch in "${MERGED_BRANCHES[@]}"; do
    branch_name=$(echo "$branch" | sed 's|origin/||')
    echo "  🗑️  Deleting $branch_name (already merged)..."
    git push origin --delete "$branch_name" 2>&1 | grep -v "GitHub found" || echo "    ⚠️  Branch may already be deleted"
    echo ""
done

# Category 2: Abandoned/Inactive Branches (No recent activity, very outdated)
echo "📦 Category 2: Deleting abandoned/inactive branches..."
ABANDONED_BRANCHES=(
    "origin/feature/cultural-community-appeal"
    "origin/feature/event-discovery-phase-c"
    "origin/feature/events-enhancement"
    "origin/feature/mutual-likes-detection"
    "origin/feature/new-development"
    "origin/feature/push-notifications-review"
    "origin/feature/template-population-enhancement"
    "origin/fix/dialog-button-text-bleeding"
)

for branch in "${ABANDONED_BRANCHES[@]}"; do
    branch_name=$(echo "$branch" | sed 's|origin/||')
    echo "  🗑️  Deleting $branch_name (abandoned/inactive)..."
    git push origin --delete "$branch_name" 2>&1 | grep -v "GitHub found" || echo "    ⚠️  Branch may already be deleted"
    echo ""
done

# Category 3: Legacy/Duplicate Branches
echo "📦 Category 3: Deleting legacy/duplicate branches..."
LEGACY_BRANCHES=(
    "origin/master"  # Legacy branch, use 'main' instead
)

for branch in "${LEGACY_BRANCHES[@]}"; do
    branch_name=$(echo "$branch" | sed 's|origin/||')
    echo "  🗑️  Deleting $branch_name (legacy/duplicate)..."
    git push origin --delete "$branch_name" 2>&1 | grep -v "GitHub found" || echo "    ⚠️  Branch may already be deleted"
    echo ""
done

echo "✅ Safe branch deletions complete!"
echo ""
echo "📋 Summary:"
echo "  - Deleted: 12 branches (merged + abandoned + legacy)"
echo "  - Kept: main, develop, feature/establish-development-workflow"
echo ""
echo "⚠️  Manual Review Needed:"
echo "  - origin/feature/security-ios-fixes (check if security fixes in main)"
echo "  - origin/feature/new-features-clean (review if 9 commits have value)"
echo "  - origin/fix-critical-issues (resolve conflicts before merge/deletion)"
echo ""

