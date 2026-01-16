# Research 详细工作流程

## ⚠️ 强制执行规则

**在执行任何调研或开发任务之前，必须完成以下门禁检查点：**

| 门禁 | 验证条件 | 验证命令 |
|------|----------|----------|
| **GATE-1** | 任务目录已创建 | `ls -la .claude/shared_files/<yymmdd-task-slug>/` |
| **GATE-2** | task-status.json 已写入 | `cat .claude/shared_files/<yymmdd-task-slug>/task-status.json \| jq '.tasks \| length'` |
| **GATE-3** | context-common.md 已写入 | `head -20 .claude/shared_files/<yymmdd-task-slug>/context-common.md` |
| **GATE-4** | 用户已确认执行方式 | 使用 AskUserQuestion 询问 |

**🚫 禁止行为：**
- 禁止在未创建 task-status.json 前启动 Task agent 进行调研
- 禁止跳过 AskUserQuestion 直接执行子任务
- 禁止使用 Task agent 做"快速调研"而不记录到任务文档

---

## Git Worktree 隔离开发

### 为什么使用 Worktree

并行开发时，多个子任务可能修改相同文件，直接在主分支开发会导致：
- 代码冲突
- 状态混乱
- 难以回滚

**解决方案**: 每个子任务使用独立的 git worktree 分支开发。

### Worktree 创建流程

**Step 1: 创建 worktrees 目录**
```bash
mkdir -p .claude/shared_files/<yymmdd-task-slug>/worktrees
```

**Step 2: 为每个并行任务创建 worktree**
```bash
# 获取当前分支名
BASE_BRANCH=$(git branch --show-current)

# 创建 P0 的 worktree
git worktree add .claude/shared_files/<yymmdd-task-slug>/worktrees/p0 -b research/<yymmdd-task-slug>/p0

# 创建 P1 的 worktree
git worktree add .claude/shared_files/<yymmdd-task-slug>/worktrees/p1 -b research/<yymmdd-task-slug>/p1

# 创建更多...
```

**Step 3: 更新 task-status.json**
```json
{
  "task_name": "任务名称",
  "task_slug": "task-slug",
  "base_branch": "main",
  "worktree_enabled": true,
  "tasks": [
    {
      "id": "p0",
      "branch": "research/task-slug/p0",
      "worktree_path": ".claude/shared_files/task-slug/worktrees/p0",
      "merge_status": "pending",
      ...
    }
  ]
}
```

### 子任务开发流程

**每个 Subagent 必须**:

1. **切换到自己的 worktree 目录**
   ```bash
   cd .claude/shared_files/<yymmdd-task-slug>/worktrees/p0
   ```

2. **在 worktree 中完成所有开发**
   - 所有文件修改都在此目录进行
   - 不要切换到其他目录修改代码

3. **提交到分支**
   ```bash
   git add -A
   git commit -m "feat(<scope>): <description>"
   ```

4. **更新状态**
   ```bash
   # 回到主项目目录更新 task-status.json
   cd <project_root>
   # 更新 status 为 completed
   # 发送通知
   ```

### 合并流程（关键！）

**按完成顺序合并，后完成的任务负责解决冲突**:

```bash
# 回到主项目目录
cd <project_root>

# 切换到基础分支
git checkout main

# 合并第一个完成的任务（通常无冲突）
git merge research/<yymmdd-task-slug>/p0 --no-ff -m "merge: P0 - <任务名>"

# 合并第二个任务（可能有冲突）
git merge research/<yymmdd-task-slug>/p1 --no-ff -m "merge: P1 - <任务名>"
# 如有冲突：
#   1. 仔细检查冲突文件
#   2. 保留两个任务的功能
#   3. 运行测试确保无破坏
#   4. git add . && git commit

# 继续合并其他任务...
```

### 冲突解决策略

**原则**: 后完成的任务负责解决冲突

**Step 1: 识别冲突**
```bash
git merge research/<yymmdd-task-slug>/p1
# Auto-merging src/file.kt
# CONFLICT (content): Merge conflict in src/file.kt
```

**Step 2: 分析冲突**
```bash
# 查看冲突文件
git diff --name-only --diff-filter=U

# 查看具体冲突
cat src/file.kt
```

**Step 3: 解决冲突**
```kotlin
// 冲突标记示例
<<<<<<< HEAD
// P0 的修改
fun featureA() { ... }
=======
// P1 的修改
fun featureB() { ... }
>>>>>>> research/task/p1

// 解决后：保留两者
fun featureA() { ... }
fun featureB() { ... }
```

**Step 4: 验证**
```bash
# 运行测试
./gradlew test

# 构建验证
./gradlew assembleDebug
```

**Step 5: 完成合并**
```bash
git add .
git commit -m "merge: resolve conflicts between P0 and P1"
```

### 清理 Worktree

所有任务完成并合并后:

```bash
# 删除 worktree
git worktree remove .claude/shared_files/<yymmdd-task-slug>/worktrees/p0
git worktree remove .claude/shared_files/<yymmdd-task-slug>/worktrees/p1

# 删除分支（可选）
git branch -d research/<yymmdd-task-slug>/p0
git branch -d research/<yymmdd-task-slug>/p1

# 发送全部完成通知
osascript -e 'display notification "所有任务已完成并合并！" with title "Research Complete" sound name "Hero"'
```

---

## 模式 1: 新建研究任务（有 query）

### Step 1: 分析任务

1. 探索代码库，理解问题背景 (推荐使用 LSP `definition`/`references` 深入分析依赖)
2. 如有 additionalDirectories，参考相关项目实现
3. 识别可并行执行的子任务
4. **判断任务类型**（调研型 / 开发型 / 混合型）

**子任务拆分原则**:
- 每个子任务 1-2 小时可完成
- 最小化依赖关系
- 明确的输入输出

### Step 2: [GATE-1] 创建共享文件目录

**目录命名规范**: 使用 kebab-case，如 `optimize-long-sentence-input`

```bash
mkdir -p .claude/shared_files/<yymmdd-task-slug>
```

**验证**: `ls -la .claude/shared_files/<yymmdd-task-slug>/`

### Step 3: [GATE-2] 写入 task-status.json

```bash
# 验证
cat .claude/shared_files/<yymmdd-task-slug>/task-status.json | jq '.tasks | length'
```

### Step 4: [GATE-3] 写入 context-common.md

```bash
# 验证
head -20 .claude/shared_files/<yymmdd-task-slug>/context-common.md
```

### Step 5: 写入各 context-pX-xxx.md

**context-pX-xxx.md 模板**:

```markdown
# PX: 任务名称

## 任务目标

一句话描述目标。

## 依赖任务

- 无 / P0, P1 等

## 当前问题

问题的具体描述和代码位置。

## 解决方案

方案概述。

## 实现步骤

### Step 1: xxx

详细代码示例...

### Step 2: xxx

详细代码示例...

## 涉及文件

| 文件 | 操作 | 说明 |
|------|------|------|
| path/to/file.kt | 新建/修改 | 说明 |

## 验证方法

1. 运行测试: `./gradlew test`
2. 手动验证: xxx

## 完成标准

- [ ] 功能实现
- [ ] 测试通过
- [ ] 文档更新
- [ ] Git 提交
```

### Step 6: 创建 Git Worktree（开发型任务）

如果是开发型或混合型任务，需要创建 worktree：

```bash
./scripts/setup-worktrees.sh .claude/shared_files/<yymmdd-task-slug>
```

### Step 7: [GATE-4] 询问执行方式

**必须使用 AskUserQuestion 工具**，提供以下选项:

```
header: "执行方式"
question: "选择任务执行方式"
options:
  - label: "Subagent 后台并行 (推荐)"
    description: "自动并发执行无依赖任务"
  - label: "多终端手动启动"
    description: "在多个终端手动启动，支持 MCP"
  - label: "当前进程顺序执行"
    description: "按依赖顺序逐个执行"
```

### Step 8: 执行任务

根据用户选择执行。详见 [EXECUTION-MODES.md](EXECUTION-MODES.md)

### Step 9: 完成通知

每个子任务完成后:

```bash
# 更新状态
# 编辑 task-status.json，将对应任务的 status 改为 "completed"

# 发送通知
osascript -e 'display notification "P0: <具体任务名> 完成\n修改: file1.kt, file2.kt" with title "Research Task Done" sound name "Glass"'

# Git 提交
git add -A && git commit -m "feat(<scope>): <description>"
```

---

## 模式 2: 选择已有任务（无 query）

### Step 1: 扫描任务

```bash
ls .claude/shared_files/*/task-status.json 2>/dev/null
```

### Step 2: 解析并列出

读取每个 task-status.json，统计完成状态，格式化输出:

```
## 已有研究任务

1. **optimize-long-sentence** (3/5 完成)
   - [x] P0: T9引擎重构
   - [x] P1: 词库优化
   - [x] P2: 多音字支持
   - [ ] P3: 联想词功能
   - [ ] P4: 缩写输入

2. **add-dark-mode** (0/3 完成)
   - [ ] P0: 主题系统设计
   - [ ] P1: 组件适配
   - [ ] P2: 持久化存储

---
输入任务编号继续，或输入新主题开始调研：
```

### Step 3: 处理用户输入

- **数字**: 进入对应任务，显示待完成的子任务
- **文字**: 作为新 query，进入模式 1

---

## 子任务执行指南

当执行子任务时:

### 1. 读取上下文

```
请先阅读:
1. .claude/shared_files/<yymmdd-task-slug>/context-common.md
2. .claude/shared_files/<yymmdd-task-slug>/context-pX-xxx.md
```

### 2. 检查依赖

```python
# 读取 task-status.json
# 检查 dependencies 中的任务是否都是 "completed"
```

### 3. 按步骤实现

严格按照 context 文件中的实现步骤执行。

### 4. 验证

执行 context 文件中定义的验证方法。

### 5. 更新状态并通知

```bash
# 1. 更新 task-status.json
jq '.tasks |= map(if .id == "p0" then .status = "completed" | .completed_at = "2025-01-12" | .notes = "实现了xxx" else . end)' task-status.json > tmp.json && mv tmp.json task-status.json

# 2. 发送通知
osascript -e 'display notification "P0: T9引擎重构 完成" with title "Research Task Done" sound name "Glass"'

# 3. Git 提交
git add -A && git commit -m "feat(engine-t9): implement incremental segmentation"
```

---

## 错误处理

### 子任务执行失败

1. 不要将状态改为 completed
2. 在 notes 中记录错误信息
3. 发送失败通知:
   ```bash
   osascript -e 'display notification "P0: <任务名> 失败\n原因: xxx" with title "Research Task Failed" sound name "Basso"'
   ```
4. 创建新的修复任务或请求用户帮助

### 依赖未满足

1. 检查依赖任务状态
2. 如果依赖未完成，先执行依赖任务
3. 或者询问用户是否跳过

---

## 最佳实践

1. **任务粒度**: 1-2 小时可完成
2. **依赖最小化**: 尽量减少任务间依赖
3. **上下文完整**: 每个 context 包含足够信息
4. **验证明确**: 每个任务有清晰的验证方法
5. **及时通知**: 完成后立即发送通知
6. **原子提交**: 每个子任务单独提交
