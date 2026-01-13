# Research DevFlow

Claude Code 开发工作流插件套件，将开发流程各环节抽象为 Skill 工具，通过知识沉淀提高团队效率。

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
git clone https://github.com/yanyaoer/research-devflow ~/Projects/research-devflow

# 添加本地 marketplace
/plugin marketplace add ~/Projects/research-devflow
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

## Skills 概览

### 开发核心流程

| Skill | 命令 | 用途 |
|-------|------|------|
| [research](skills/research/) | `/research` | 任务拆解与并行开发 |
| [postmortem](skills/postmortem/) | `/postmortem` | 事故复盘与根因分析 |
| [review](skills/review/) | `/review` | 代码审查辅助 |

### 质量保障

| Skill | 命令 | 用途 |
|-------|------|------|
| [tech-debt](skills/tech-debt/) | `/tech-debt` | 技术债务追踪 |
| [test-strategy](skills/test-strategy/) | `/test-strategy` | 测试策略生成 |
| [security-scan](skills/security-scan/) | `/security-scan` | 安全检查 |

### 持续改进

| Skill | 命令 | 用途 |
|-------|------|------|
| [dependency](skills/dependency/) | `/dependency` | 依赖管理与漏洞检查 |
| [release](skills/release/) | `/release` | Changelog 与发布说明 |
| [onboarding](skills/onboarding/) | `/onboarding` | 新人上手指南 |

## Skill 联动

```
research ──────────────────────────────┐
    │                                  │
    ▼                                  ▼
postmortem ◄──────── review ──────► tech-debt
    │                   │
    ▼                   ▼
test-strategy    security-scan
                       │
                       ▼
              RULES-CODE-QUALITY
                       │
    ┌──────────────────┴──────────────────┐
    ▼                                      ▼
dependency ──────► release ──────► onboarding
```

## 共享资源

| 文件 | 说明 |
|------|------|
| [docs/META-SCHEMA.md](docs/META-SCHEMA.md) | 统一文档元信息格式 |
| [docs/RULES-CODE-QUALITY.md](docs/RULES-CODE-QUALITY.md) | 代码质量检查规则 |
| [scripts/rule_query.py](scripts/rule_query.py) | 规则查询工具 |

## 知识沉淀目录

```
.claude/
├── shared_files/     # research 任务上下文
├── postmortem/       # 事故复盘报告
├── reviews/          # 代码审查记录
├── tech-debt/        # 技术债务报告
├── test-strategy/    # 测试策略文档
├── security-scan/    # 安全扫描报告
├── dependency/       # 依赖分析报告
├── release/          # 发布说明
└── onboarding/       # 上手指南
```

## 推荐搭配

- [claude-hud](https://github.com/jarrodwatts/claude-hud) - 状态栏显示任务进度，实时监控 Subagent 执行状态

## License

MIT
