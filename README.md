# Research DevFlow

拆解复杂任务为可并行执行的子任务，支持 Git Worktree 隔离开发。

## 功能特性

- **任务拆解**: 将复杂任务分解为独立的子任务
- **并行执行**: 支持多个 Subagent 后台并行执行
- **Git Worktree**: 每个子任务在独立分支开发，避免冲突
- **状态追踪**: task-status.json 记录任务进度
- **系统通知**: 任务完成时发送 macOS 通知
- **自动合并**: 按完成顺序合并分支，处理冲突

## 安装

### 方式 1: 从 GitHub 安装（推荐）

```bash
# 添加 marketplace
/plugin marketplace add https://github.com/yanyaoer/research-devflow

# 安装并启用
/plugin install research-devflow@yanyaoer-plugins
```

### 方式 2: 本地安装

```bash
# 克隆仓库
git clone https://github.com/yanyaoer/research-devflow ~/Projects/side/research-devflow

# 添加本地 marketplace（指向包含 plugin 的目录）
/plugin marketplace add ~/Projects/side/research-devflow
```

### 方式 3: 配置文件安装

在 `~/.claude/settings.json` 中添加：

```json
{
  "enabledPlugins": {
    "research-devflow@yanyaoer-plugins": true
  },
  "extraKnownMarketplaces": {
    "yanyaoer-plugins": {
      "source": {
        "source": "directory",
        "path": "/path/to/research-devflow"
      }
    }
  }
}
```

## 使用

```bash
# 调研新方案，创建子任务
/research <query>

# 选择已有任务或新建
/research
```

## 结构

```
research-devflow/
├── .claude-plugin/
│   └── plugin.json       # Plugin 元数据
├── skills/
│   └── research/
│       ├── SKILL.md      # 主 Skill 文件
│       ├── WORKFLOW.md   # 详细工作流程
│       ├── EXECUTION-MODES.md  # 执行模式详解
│       └── TEMPLATES.md  # 文件模板
├── scripts/
│   ├── setup-worktrees.sh  # 初始化 worktree
│   ├── merge.sh            # 合并分支
│   └── notify.sh           # 发送通知
└── README.md
```

## 工作流

```
1. /research <query>     调研任务
2. 创建 context 文件      写入背景和实现步骤
3. setup-worktrees.sh    创建独立工作分支
4. 并行执行子任务         在各自 worktree 中开发
5. 完成通知              每个任务完成时通知
6. merge.sh              合并所有分支
```

## 执行模式

| 模式 | 适用场景 |
|------|----------|
| Subagent 后台并行 | 无依赖的独立任务 |
| 多终端手动启动 | 需要 MCP 或交互 |
| 当前进程顺序 | 简单任务或强依赖 |

## 脚本

```bash
# 初始化 worktree
./scripts/setup-worktrees.sh .claude/shared_files/<task>

# 任务通知
./scripts/notify.sh done p0 "任务名" "修改内容"
./scripts/notify.sh fail p0 "任务名" "错误信息"

# 合并分支
./scripts/merge.sh .claude/shared_files/<task>
```

## License

MIT

## 推荐搭配

- [claude-hud](https://github.com/jarrodwatts/claude-hud) - 状态栏显示任务进度，实时监控 Subagent 执行状态
