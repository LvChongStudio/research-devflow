---
description: "拆解复杂任务为并行子任务"
argument-hint: "[query]"
---

执行 research skill 进行任务拆解和并行处理。

**⚠️ 强制要求**: 必须先创建任务文档（task-status.json, context-common.md），再启动调研或开发任务。禁止跳过文档创建直接执行。

如果提供了 query 参数，进入调研模式创建新任务。
如果没有参数，列出已有任务供选择。

请调用 research skill 来处理用户请求。
