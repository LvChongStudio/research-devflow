---
id: code-quality-rules
version: "1.1"
updated_at: "2025-01-13"
---

# 代码质量检查规则

## 支持的语言

规则检查命令覆盖以下主流语言：

| 语言 | 扩展名 | rg --type |
|------|--------|-----------|
| TypeScript/JavaScript | ts, tsx, js, jsx | ts, js |
| Python | py | py |
| Rust | rs | rust |
| Go | go | go |
| Java | java | java |
| Kotlin | kt, kts | kotlin |
| Swift | swift | swift |
| C/C++ | c, cpp, cc, h, hpp | c, cpp |

### 快捷 Glob 模式

```bash
# 全语言扫描
CODE_GLOB='*.{ts,tsx,js,jsx,py,rs,go,java,kt,swift,c,cpp,cc,h,hpp}'

# 使用示例
rg "pattern" -g "$CODE_GLOB"
```

## 规则格式说明

```yaml
- id: 规则唯一标识
  name: 规则名称
  category: security | robustness | performance | maintainability
  severity: critical | high | medium | low
  applies_to: [review, postmortem]
  review_action: review 时的检查动作
  postmortem_action: postmortem 时的分析动作
  check_command: 检查命令
  fix_hint: 修复提示
```

---

## 安全类 (security)

```yaml
- id: S01
  name: SQL 注入
  category: security
  severity: critical
  applies_to: [review, postmortem]
  review_action: 检查是否使用参数化查询
  postmortem_action: 追溯注入路径和攻击向量
  check_command: |
    rg "execute\(.*\+|query\(.*\+|raw\(.*\+|executeQuery.*\$\{|\.query.*\$\{" -g '*.{ts,js,py,java,kt,go,swift}'
    rg "format!.*SELECT|fmt\.Sprintf.*SELECT" -g '*.{rs,go}'
    rg "stringWithFormat.*SELECT|NSString.*SELECT" -g '*.{swift,m,mm}'
  fix_hint: 使用参数化查询或 ORM

- id: S02
  name: XSS 跨站脚本
  category: security
  severity: critical
  applies_to: [review, postmortem]
  review_action: 检查用户输入是否转义输出
  postmortem_action: 分析攻击载荷和影响范围
  check_command: |
    rg "innerHTML\s*=|v-html|dangerouslySetInnerHTML|document\.write\(" -g '*.{ts,tsx,js,jsx}'
    rg "html!|Html::raw" -g '*.rs'
    rg "template\.HTML" -g '*.go'
  fix_hint: 使用 textContent 或框架的安全输出方式

- id: S03
  name: 命令注入
  category: security
  severity: critical
  applies_to: [review, postmortem]
  review_action: 检查 shell 命令拼接
  postmortem_action: 还原命令执行路径
  check_command: |
    rg "exec\(.*\+|spawn\(.*\+|system\(.*\+" -g '*.{ts,js,py,java,kt,swift,c,cpp}'
    rg "subprocess\.(run|call|Popen).*shell=True" -g '*.py'
    rg "Runtime\.getRuntime\(\)\.exec|ProcessBuilder" -g '*.{java,kt}'
    rg "Command::new.*format!|std::process::Command" -g '*.rs'
    rg "exec\.Command|os/exec" -g '*.go'
    rg "Process\(|NSTask|launchPath" -g '*.swift'
    rg "popen|execvp|execl" -g '*.{c,cpp,cc}'
  fix_hint: 使用参数数组而非字符串拼接

- id: S04
  name: 认证绕过
  category: security
  severity: critical
  applies_to: [review, postmortem]
  review_action: 检查认证逻辑完整性
  postmortem_action: 还原绕过路径
  check_command: |
    rg "isAuthenticated|isAuthorized|checkAuth|@PreAuthorize|@Secured|RequireAuth" -g '*.{ts,js,py,java,kt,go,rs,swift}'
    rg "middleware.*auth|#\[authorize\]" -g '*.{go,rs}'
  fix_hint: 确保所有敏感路由都有认证检查

- id: S05
  name: 敏感信息泄露
  category: security
  severity: high
  applies_to: [review, postmortem]
  review_action: 检查硬编码密钥和日志输出
  postmortem_action: 评估泄露范围和影响
  check_command: |
    rg "(password|secret|api_key|apikey|token)\s*[:=]\s*['\"][^'\"]{8,}['\"]" -i -g '*.{ts,js,py,java,kt,go,rs,swift,c,cpp}'
    rg "(print|log|console)\w*\(.*password" -i -g '*.{ts,js,py,java,kt,go,rs,swift}'
  fix_hint: 使用环境变量或密钥管理服务
```

---

## 健壮性 (robustness)

```yaml
- id: R01
  name: 空值处理缺失
  category: robustness
  severity: high
  applies_to: [review, postmortem]
  review_action: 检查可能为 null/undefined 的变量使用
  postmortem_action: 追溯空值来源和传播路径
  check_command: |
    rg "\.unwrap\(\)|\.expect\(" -g '*.rs'
    rg "NullPointerException|\.get\(\)\." -g '*.{java,kt}'
    rg "Cannot read propert|undefined is not|null is not" -g '*.{ts,js}'
    rg "AttributeError: 'NoneType'" -g '*.py'
    rg "nil pointer|invalid memory address" -g '*.go'
    rg "unexpectedly found nil|fatal error: unexpectedly found nil" -g '*.swift'
    rg "nullptr|NULL|segmentation fault" -i -g '*.{c,cpp,cc}'
  fix_hint: 使用可选链(?.)、Option/Result 或显式空值检查

- id: R02
  name: 边界条件未处理
  category: robustness
  severity: high
  applies_to: [review, postmortem]
  review_action: 检查数组索引和范围边界
  postmortem_action: 还原边界触发条件
  check_command: |
    rg "IndexOutOfBounds|index out of range|slice bounds|ArrayIndexOutOfBoundsException" -i -g '*.{ts,js,py,java,kt,go,rs,swift,c,cpp}'
  fix_hint: 添加边界检查，使用安全访问方法

- id: R03
  name: 并发竞态条件
  category: robustness
  severity: high
  applies_to: [review, postmortem]
  review_action: 检查共享状态的并发访问
  postmortem_action: 还原竞态时序
  check_command: |
    rg "async|await|Promise\.|setTimeout|setInterval" -g '*.{ts,js}'
    rg "threading|asyncio|concurrent\.futures" -g '*.py'
    rg "synchronized|ReentrantLock|Atomic" -g '*.{java,kt}'
    rg "go\s+func|sync\.(Mutex|RWMutex)|<-\s*chan" -g '*.go'
    rg "Arc<Mutex|tokio::spawn|async fn" -g '*.rs'
    rg "DispatchQueue|@MainActor|actor\s+" -g '*.swift'
    rg "pthread_|std::mutex|std::thread" -g '*.{c,cpp,cc}'
  fix_hint: 使用锁、原子操作或不可变数据

- id: R04
  name: 异常处理不当
  category: robustness
  severity: medium
  applies_to: [review, postmortem]
  review_action: 检查 try-catch 覆盖和错误处理
  postmortem_action: 分析异常传播和吞没
  check_command: |
    rg "catch\s*\([^)]*\)\s*\{\s*\}" -g '*.{ts,js,java,kt,cpp}'
    rg "except:\s*$|except Exception:\s*(pass|\.\.\.)" -g '*.py'
    rg "if err != nil \{\s*\}" -g '*.go'
    rg "\.unwrap_or\(\)|\.unwrap_or_default\(\)" -g '*.rs'
    rg "catch\s*\{\s*\}" -g '*.swift'
  fix_hint: 记录错误详情，避免空 catch 块

- id: R05
  name: 资源泄露
  category: robustness
  severity: medium
  applies_to: [review, postmortem]
  review_action: 检查文件/连接是否正确关闭
  postmortem_action: 分析资源累积和系统影响
  check_command: |
    rg "open\(|createConnection|createPool|new FileInputStream" -g '*.{py,ts,js,java,kt}'
    rg "File::open|TcpStream::connect" -g '*.rs'
    rg "os\.Open|sql\.Open|net\.Dial" -g '*.go'
    rg "FileHandle|URLSession|InputStream" -g '*.swift'
    rg "fopen|malloc|new\s+\w+\[" -g '*.{c,cpp,cc}'
  fix_hint: 使用 try-finally、defer、use/with、RAII 或 ARC
```

---

## 性能 (performance)

```yaml
- id: P01
  name: N+1 查询问题
  category: performance
  severity: medium
  applies_to: [review, postmortem]
  review_action: 检查循环内的数据库查询
  postmortem_action: 分析查询日志和性能数据
  check_command: |
    rg "for.*(find|query|fetch|select)" -i -g '*.{ts,js,py,java,kt,go,rs,swift}'
  fix_hint: 使用批量查询或 JOIN

- id: P02
  name: 无限循环风险
  category: performance
  severity: high
  applies_to: [review, postmortem]
  review_action: 检查循环终止条件
  postmortem_action: 还原循环卡死条件
  check_command: |
    rg "while\s*\(\s*(true|1|YES)\s*\)|for\s*\(\s*;;\s*\)|while\s+True:|loop\s*\{" -g '*.{ts,js,py,java,kt,go,rs,swift,c,cpp}'
  fix_hint: 确保有明确的退出条件和超时机制

- id: P03
  name: 内存泄漏风险
  category: performance
  severity: medium
  applies_to: [review, postmortem]
  review_action: 检查事件监听器和定时器清理
  postmortem_action: 分析内存增长模式
  check_command: |
    rg "addEventListener|setInterval|subscribe\(" -g '*.{ts,js}'
    rg "Box::leak|mem::forget|static mut" -g '*.rs'
    rg "addObserver|NotificationCenter" -g '*.{java,kt,swift}'
    rg "malloc|realloc|new\s+\w+\[" -g '*.{c,cpp,cc}'
  fix_hint: 组件卸载时清理监听器和定时器
```

---

## 可维护性 (maintainability)

```yaml
- id: M01
  name: 硬编码配置
  category: maintainability
  severity: low
  applies_to: [review, postmortem]
  review_action: 检查硬编码的 URL、端口、路径
  postmortem_action: 分析配置错误影响
  check_command: |
    rg "http://localhost|127\.0\.0\.1|:3000|:8080|:8000" -g '*.{ts,js,py,java,kt,go,rs,swift,c,cpp}'
  fix_hint: 使用环境变量或配置文件

- id: M02
  name: 魔法数字
  category: maintainability
  severity: low
  applies_to: [review]
  review_action: 检查未命名的数字常量
  postmortem_action: N/A
  check_command: |
    rg "[=<>]\s*\d{3,}[^0-9]" -g '*.{ts,js,py,java,kt,go,rs,swift,c,cpp}'
  fix_hint: 提取为命名常量

- id: M03
  name: 过长函数
  category: maintainability
  severity: low
  applies_to: [review]
  review_action: 检查函数行数是否超过阈值
  postmortem_action: N/A
  check_command: |
    ast-grep -p 'function $NAME($$$) { $$$BODY$$$ }' --lang typescript
    ast-grep -p 'fn $NAME($$$) { $$$BODY$$$ }' --lang rust
    ast-grep -p 'func $NAME($$$) { $$$BODY$$$ }' --lang go
    ast-grep -p 'func $NAME($$$) { $$$BODY$$$ }' --lang swift
  fix_hint: 拆分为多个职责单一的小函数
```

---

## 使用方式

### Review 场景

```bash
# 获取所有 review 规则
python scripts/rule_query.py --query review

# 获取特定分类
python scripts/rule_query.py --query review --category security
```

### Postmortem 场景

```bash
# 获取 postmortem 分析规则
python scripts/rule_query.py --query postmortem

# 按根因类型匹配规则
python scripts/rule_query.py --query postmortem --category robustness
```

### 执行检查

```bash
# 对变更文件执行所有检查命令
python scripts/rule_query.py --query review --format json | \
  jq -r '.rules[].check_command' | \
  while read cmd; do eval "$cmd"; done
```
