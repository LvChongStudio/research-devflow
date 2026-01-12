#!/bin/bash
# Research Task Merge Script
# Usage: ./merge.sh <task-dir> [--dry-run]
#
# Merges all completed task branches in order

set -e

TASK_DIR=$1
DRY_RUN=$2

if [ -z "$TASK_DIR" ]; then
    echo "Usage: $0 <task-dir> [--dry-run]"
    echo "Example: $0 .claude/shared_files/optimize-input"
    exit 1
fi

STATUS_FILE="$TASK_DIR/task-status.json"

if [ ! -f "$STATUS_FILE" ]; then
    echo "Error: task-status.json not found in $TASK_DIR"
    exit 1
fi

# Read base branch
BASE_BRANCH=$(jq -r '.base_branch // "main"' "$STATUS_FILE")
TASK_SLUG=$(jq -r '.task_slug' "$STATUS_FILE")

echo "=== Research Task Merge ==="
echo "Task: $TASK_SLUG"
echo "Base branch: $BASE_BRANCH"
echo ""

# Get completed tasks sorted by completed_at
COMPLETED_TASKS=$(jq -r '.tasks | sort_by(.completed_at) | .[] | select(.status == "completed" and .merge_status == "pending") | .id' "$STATUS_FILE")

if [ -z "$COMPLETED_TASKS" ]; then
    echo "No completed tasks pending merge."
    exit 0
fi

echo "Tasks to merge (in order):"
echo "$COMPLETED_TASKS"
echo ""

if [ "$DRY_RUN" == "--dry-run" ]; then
    echo "[Dry run mode - no changes will be made]"
    echo ""
fi

# Checkout base branch
if [ "$DRY_RUN" != "--dry-run" ]; then
    git checkout "$BASE_BRANCH"
fi

# Merge each completed task
for TASK_ID in $COMPLETED_TASKS; do
    BRANCH=$(jq -r ".tasks[] | select(.id == \"$TASK_ID\") | .branch" "$STATUS_FILE")
    NAME=$(jq -r ".tasks[] | select(.id == \"$TASK_ID\") | .name" "$STATUS_FILE")

    echo "Merging: $TASK_ID ($NAME)"
    echo "  Branch: $BRANCH"

    if [ "$DRY_RUN" != "--dry-run" ]; then
        if git merge "$BRANCH" --no-ff -m "merge: $TASK_ID - $NAME"; then
            echo "  ✓ Merged successfully"

            # Update merge_status in task-status.json
            TEMP_FILE=$(mktemp)
            jq "(.tasks[] | select(.id == \"$TASK_ID\")) |= . + {merge_status: \"merged\", merged_at: \"$(date +%Y-%m-%d)\"}" "$STATUS_FILE" > "$TEMP_FILE"
            mv "$TEMP_FILE" "$STATUS_FILE"

            # Add to merge_order
            TEMP_FILE=$(mktemp)
            jq ".merge_order += [\"$TASK_ID\"]" "$STATUS_FILE" > "$TEMP_FILE"
            mv "$TEMP_FILE" "$STATUS_FILE"
        else
            echo "  ✗ Conflict detected!"
            echo ""
            echo "Please resolve conflicts manually:"
            echo "  1. Edit conflicting files"
            echo "  2. git add ."
            echo "  3. git commit"
            echo "  4. Re-run this script"

            # Update merge_status to conflict
            TEMP_FILE=$(mktemp)
            jq "(.tasks[] | select(.id == \"$TASK_ID\")) |= . + {merge_status: \"conflict\"}" "$STATUS_FILE" > "$TEMP_FILE"
            mv "$TEMP_FILE" "$STATUS_FILE"

            # Send notification
            osascript -e "display notification \"$TASK_ID 合并冲突，需要手动解决\" with title \"Research Merge Conflict\" sound name \"Basso\""
            exit 1
        fi
    else
        echo "  [Would merge $BRANCH]"
    fi
    echo ""
done

echo "=== All tasks merged successfully! ==="

# Cleanup worktrees
echo ""
echo "Cleaning up worktrees..."
for TASK_ID in $COMPLETED_TASKS; do
    WORKTREE_PATH=$(jq -r ".tasks[] | select(.id == \"$TASK_ID\") | .worktree_path" "$STATUS_FILE")
    FULL_PATH="$TASK_DIR/$WORKTREE_PATH"

    if [ -d "$FULL_PATH" ] && [ "$DRY_RUN" != "--dry-run" ]; then
        echo "  Removing: $FULL_PATH"
        git worktree remove "$FULL_PATH" --force 2>/dev/null || true
    fi
done

# Send completion notification
if [ "$DRY_RUN" != "--dry-run" ]; then
    osascript -e 'display notification "所有任务已合并完成！" with title "Research Complete" sound name "Hero"'
fi

echo ""
echo "Done!"
