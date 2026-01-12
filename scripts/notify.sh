#!/bin/bash
# Research Task Notification Script
# Usage: ./notify.sh <status> <task_id> <task_name> [details]
#
# status: done | fail | all_done
# task_id: p0, p1, etc.
# task_name: Task description
# details: Additional info (optional)

STATUS=$1
TASK_ID=$2
TASK_NAME=$3
DETAILS=$4

case $STATUS in
  done)
    TITLE="Research Task Done"
    SOUND="Glass"
    if [ -n "$DETAILS" ]; then
      MESSAGE="${TASK_ID^^}: ${TASK_NAME}\n${DETAILS}"
    else
      MESSAGE="${TASK_ID^^}: ${TASK_NAME} 完成"
    fi
    ;;
  fail)
    TITLE="Research Task Failed"
    SOUND="Basso"
    if [ -n "$DETAILS" ]; then
      MESSAGE="${TASK_ID^^}: ${TASK_NAME}\n原因: ${DETAILS}"
    else
      MESSAGE="${TASK_ID^^}: ${TASK_NAME} 失败"
    fi
    ;;
  all_done)
    TITLE="Research Complete"
    SOUND="Hero"
    MESSAGE="所有任务已完成！"
    ;;
  *)
    echo "Usage: $0 <done|fail|all_done> <task_id> <task_name> [details]"
    exit 1
    ;;
esac

osascript -e "display notification \"${MESSAGE}\" with title \"${TITLE}\" sound name \"${SOUND}\""
