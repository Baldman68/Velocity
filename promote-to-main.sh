#!/bin/zsh

# Git Promotion Script: development -> test -> main
# Velocity Coaster Chaser
# This script promotes changes through your git branches safely

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_step() {
    echo "${BLUE}==>${NC} $1"
}

print_success() {
    echo "${GREEN}✓${NC} $1"
}

print_warning() {
    echo "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo "${RED}✗${NC} $1"
}

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not in a git repository!"
    exit 1
fi

# Save the current branch
ORIGINAL_BRANCH=$(git symbolic-ref --short HEAD)
print_step "Starting from branch: $ORIGINAL_BRANCH"

# Ensure we always return to development, even on error
return_to_development() {
    CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "unknown")
    if [ "$CURRENT_BRANCH" != "development" ]; then
        print_step "Returning to development branch..."
        git checkout development 2>/dev/null || true
    fi
}
trap return_to_development EXIT

# Confirm with user
echo ""
print_warning "This script will:"
echo "  1. Commit and push all changes on development"
echo "  2. Merge development into test and push"
echo "  3. Merge test into main and push (triggers Xcode Cloud builds)"
echo ""
echo -n "Continue? (y/n): "
read REPLY
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_error "Aborted by user"
    exit 1
fi

# ============================================
# STEP 1: DEVELOPMENT BRANCH
# ============================================
print_step "Step 1: Processing development branch..."

# Switch to development if not already there
if [ "$ORIGINAL_BRANCH" != "development" ]; then
    git checkout development
    print_success "Switched to development branch"
fi

# Check if there are any changes to commit
if [[ -n $(git status -s) ]]; then
    print_step "Found uncommitted changes. Adding all changes..."
    git add -A
    
    # Prompt for commit message
    echo ""
    print_step "Enter commit message:"
    read COMMIT_MESSAGE
    
    if [ -z "$COMMIT_MESSAGE" ]; then
        COMMIT_MESSAGE="Update: $(date '+%Y-%m-%d %H:%M:%S')"
        print_warning "No message provided. Using: $COMMIT_MESSAGE"
    fi
    
    git commit -m "$COMMIT_MESSAGE"
    print_success "Changes committed"
else
    print_success "No uncommitted changes on development"
fi

# Push development
print_step "Pushing development branch..."
git push origin development
print_success "Development branch pushed"

# ============================================
# STEP 2: TEST BRANCH
# ============================================
print_step "Step 2: Processing test branch..."

# Switch to test
git checkout test
print_success "Switched to test branch"

# Pull latest from remote
print_step "Pulling latest test branch..."
git pull origin test
print_success "Test branch updated"

# Push test (in case there were remote changes)
print_step "Pushing test branch..."
git push origin test
print_success "Test branch pushed"

# Merge development into test
print_step "Merging development into test..."
if git merge development --no-edit; then
    print_success "Development merged into test successfully"
else
    print_error "Merge conflict detected!"
    print_warning "Please resolve conflicts manually, then run:"
    echo "  git add ."
    echo "  git commit"
    echo "  git push origin test"
    echo "  Then continue with: git checkout main && git pull && git merge test && git push"
    exit 1
fi

# Push test after merge
print_step "Pushing merged test branch..."
git push origin test
print_success "Test branch pushed with merge"

# ============================================
# STEP 3: MAIN BRANCH
# ============================================
print_step "Step 3: Processing main branch..."

# Switch to main
git checkout main
print_success "Switched to main branch"

# Pull latest from remote
print_step "Pulling latest main branch..."
git pull origin main
print_success "Main branch updated"

# Push main (in case there were remote changes)
print_step "Pushing main branch..."
git push origin main
print_success "Main branch pushed"

# Merge test into main
print_step "Merging test into main..."
if git merge test --no-edit; then
    print_success "Test merged into main successfully"
else
    print_error "Merge conflict detected!"
    print_warning "Please resolve conflicts manually, then run:"
    echo "  git add ."
    echo "  git commit"
    echo "  git push origin main"
    exit 1
fi

# Final push to main (this triggers Xcode Cloud!)
print_step "Pushing final main branch (will trigger Xcode Cloud builds)..."
git push origin main
print_success "Main branch pushed"

# ============================================
# COMPLETION
# ============================================
echo ""
print_success "=========================================="
print_success "Git promotion completed successfully!"
print_success "=========================================="
echo ""
print_step "Branch promotion summary:"
echo "  • development: committed and pushed"
echo "  • test: merged from development and pushed"
echo "  • main: merged from test and pushed"
echo ""
print_warning "Xcode Cloud build should now start for:"
echo "  • VelocityCoasterChaser Distribution"
echo ""
print_step "Check build status at:"
echo "  • Xcode: Report Navigator -> Cloud tab"
echo "  • App Store Connect: Xcode Cloud section"
echo ""

print_success "Done!"
