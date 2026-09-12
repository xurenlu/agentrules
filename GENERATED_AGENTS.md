<!-- GENERATED FILE — DO NOT EDIT.
     Source: Alma rule documents and scripts/generate_claude_md.rb -->

# GENERATED_AGENTS.md

> 由 `scripts/generate_claude_md.rb` 生成；请修改规则源文件后重新生成。
> 规则画像：自定义选择
> 生成来源：Alma 规则库。
> 模式：按需读取索引版（--index），不内嵌主题规则正文。

## 使用说明

- 本文件是规则索引，不内嵌主题规则正文；不要因为看到索引就一次性读取全部规则。
- 指令优先级：系统 / 开发者 / 用户指令 > 目标仓库内更具体的 `AGENTS.md` / `CLAUDE.md` > 本索引。
- 开工前根据任务类型，只读取下方索引中直接相关的规则文件；任务范围扩大时再补读。
- 修改任何文件前先检查目标仓库的本地规则、工作区状态和既有实现，保留用户已有改动。
- 涉及代码时至少读取 `ai-guardrails.md`、`programming.md`；涉及提交、版本或发布时再读取 `version-control.md`。
- 不得输出或提交密钥、Token、凭据、个人隐私数据；疑似敏感信息先停止扩散并脱敏处理。
- 规则源文件以 GitHub 默认分支为准；本地存在 agentrules 仓库时优先读取同名本地文件。

## 按需规则索引
- [AI 协作红线](https://github.com/xurenlu/agentrules/blob/main/ai-guardrails.md)（`ai-guardrails.md`）：文件编辑方式、破坏性操作确认、共享分支保护和如实汇报
- [编程通用规范](https://github.com/xurenlu/agentrules/blob/main/programming.md)（`programming.md`）：代码风格、错误处理、测试、版本控制、安全和日志
- [多端产品设计规范](https://github.com/xurenlu/agentrules/blob/main/design.md)（`design.md`）：新项目启动门禁、UI 规范方向、docs 文档沉淀和多端规范
- [前端规范](https://github.com/xurenlu/agentrules/blob/main/frontend.md)（`frontend.md`）：TypeScript、React、状态管理、CSS、性能、安全和测试
- [Go 规范](https://github.com/xurenlu/agentrules/blob/main/go.md)（`go.md`）：Go 项目结构、错误处理、并发、DI、测试、性能和 Go + React embed
- [Python 规范](https://github.com/xurenlu/agentrules/blob/main/python.md)（`python.md`）：Python 环境、类型、异步、数据库、测试和常用库
- [数据库迁移规范](https://github.com/xurenlu/agentrules/blob/main/database-migrations.md)（`database-migrations.md`）：迁移版本、建表、索引、启动迁移、回滚和 CI/CD
- [数据库查询规范](https://github.com/xurenlu/agentrules/blob/main/database-queries.md)（`database-queries.md`）：SQL 编写、索引、查询优化、EXPLAIN 和 ORM
- [数据库同步规范](https://github.com/xurenlu/agentrules/blob/main/database-sync.md)（`database-sync.md`）：全量、增量、实时同步、一致性、冲突解决和监控
- [服务部署规范](https://github.com/xurenlu/agentrules/blob/main/deployment.md)（`deployment.md`）：发布检查、迁移、产物备份、健康检查、回滚和 CI/CD
- [Linux 服务器规范](https://github.com/xurenlu/agentrules/blob/main/linux-server.md)（`linux-server.md`）：安全基线、监控、备份、日志、性能调优、Docker 和应急响应
- [版本管理规范](https://github.com/xurenlu/agentrules/blob/main/version-control.md)（`version-control.md`）：分支策略、语义化版本、Build 号、CHANGELOG、.gitignore 和 Git 工作流
