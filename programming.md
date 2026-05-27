# 编程最佳实践

## 代码风格
- **一致性 > 个人偏好**：一个项目一种风格，用 linter 强制（ESLint / ruff / golangci-lint）
- **命名即文档**：变量/函数名应该自解释。`getUserById` 永远好过 `getData`
- **函数要短**：超过 30 行的函数就该拆。一个函数只做一件事
- **魔法数字死刑**：所有硬编码数字/字符串抽成常量，给个有意义的名字
- **提前 return**：减少嵌套层级，`if (!valid) return` 比 `if (valid) { ... 大段逻辑 }` 清晰得多

## 错误处理
- **不要吞异常**：`catch (e) {}` 是犯罪。至少 log 一下
- **错误信息要有上下文**：不是 "连接失败"，是 "连接 MySQL (10.0.1.5:3306) 失败: connection refused"
- **区分可恢复和不可恢复**：网络超时重试，配置错误直接炸
- **业务异常用自定义类型**：方便上层统一处理，别到处 `if err.Error() == "xxx"`
- **Go 里 error 永远放返回值最后一位**，别玩花样

## 测试
- **写测试**：核心逻辑必须有单测。别拿"没时间"说事
- **测试数据要隔离**：别依赖外部数据库状态，用 mock/fixture/testcontainers
- **一个 test case 测一件事**：`TestUserCreateAndDelete` 不如拆成两个
- **Table-driven tests**（Go）：同结构不同输入的用例用表驱动，清爽
- **覆盖率不是 KPI**：80% 的关键路径 > 100% 的 getter/setter

## 版本控制
详见 [version-control.md](version-control.md) — 分支策略、语义化版本、CHANGELOG/Product Overview、完整 Git 工作流。

## 设计原则
- **YAGNI**：别提前设计你用不到的东西。明天的问题明天解决
- **KISS**：简单的方案先上，复杂了再重构。别一上来就微服务
- **组合 > 继承**：除了少数场景，继承带来的问题比解决的多
- **依赖倒置**：上层定义接口，下层实现。业务代码不依赖具体框架
- **过早优化是万恶之源**：先让代码正确运行，再 profile 找瓶颈

## 安全
- **永远不要信任用户输入**：所有输入做校验和清洗
- **SQL 用参数化查询**：哪怕是内部工具也别拼字符串
- **密钥不进代码**：用环境变量 / vault / k8s secrets
- **最小权限原则**：数据库账号、API token 只给必要权限
- **依赖要审计**：定期 `npm audit` / `go mod tidy` / `pip audit`，别让 supply chain 出事

## 日志
- **结构化日志**：JSON 格式，方便 ELK/Loki 检索。别写散文
- **分级用对**：DEBUG 开发用，INFO 关键节点，WARN 异常但可恢复，ERROR 需要人工介入
- **别 log 敏感信息**：密码、token、手机号要脱敏
- **每个请求一个 trace_id**：微服务链路追踪的基础
