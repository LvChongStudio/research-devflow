#!/bin/bash
# Research Task Setup Script
# Usage: ./setup-worktrees.sh <task-dir>
#
# Creates git worktrees for all tasks based on task-status.json

set -e

TASK_DIR=$1

if [ -z "$TASK_DIR" ]; then
    echo "Usage: $0 <task-dir>"
    echo "Example: $0 .claude/shared_files/optimize-input"
    exit 1
fi

STATUS_FILE="$TASK_DIR/task-status.json"

if [ ! -f "$STATUS_FILE" ]; then
    echo "Error: task-status.json not found in $TASK_DIR"
    exit 1
fi

# Read task info
TASK_SLUG=$(jq -r '.task_slug' "$STATUS_FILE")
BASE_BRANCH=$(jq -r '.base_branch // "main"' "$STATUS_FILE")
WORKTREE_ENABLED=$(jq -r '.worktree_enabled // true' "$STATUS_FILE")

if [ "$WORKTREE_ENABLED" != "true" ]; then
    echo "Worktree is disabled for this task."
    exit 0
fi

echo "=== Research Task Worktree Setup ==="
echo "Task: $TASK_SLUG"
echo "Base branch: $BASE_BRANCH"
echo ""

# Create worktrees directory
WORKTREES_DIR="$TASK_DIR/worktrees"
mkdir -p "$WORKTREES_DIR"

# Get all task IDs
TASK_IDS=$(jq -r '.tasks[].id' "$STATUS_FILE")

echo "Creating worktrees for tasks:"
for TASK_ID in $TASK_IDS; do
    BRANCH=$(jq -r ".tasks[] | select(.id == \"$TASK_ID\") | .branch" "$STATUS_FILE")
    WORKTREE_PATH=$(jq -r ".tasks[] | select(.id == \"$TASK_ID\") | .worktree_path" "$STATUS_FILE")
    FULL_PATH="$TASK_DIR/$WORKTREE_PATH"
    NAME=$(jq -r ".tasks[] | select(.id == \"$TASK_ID\") | .name" "$STATUS_FILE")

    echo ""
    echo "  $TASK_ID: $NAME"
    echo "    Branch: $BRANCH"
    echo "    Path: $FULL_PATH"

    if [ -d "$FULL_PATH" ]; then
        echo "    [Already exists, skipping]"
    else
        git worktree add "$FULL_PATH" -b "$BRANCH" "$BASE_BRANCH"
        echo "    ✓ Created"
    fi
done

echo ""
echo "=== Worktree setup complete! ==="
echo ""
echo "Each subagent should:"
echo "  1. cd $TASK_DIR/worktrees/<task_id>"
echo "  2. Complete development in that directory"
echo "  3. git add -A && git commit"
echo "  4. Update ../task-status.json"
echo ""
echo "After all tasks complete, run:"
echo "  ./scripts/merge.sh $TASK_DIR"
