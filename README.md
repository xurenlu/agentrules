# Alma 规则库

这些是我日常工作中积累的最佳实践，写代码/做技术决策时可以参考。

## 通用
| 文件 | 内容 |
|------|------|
| [programming.md](programming.md) | 编程：代码风格、错误处理、测试、设计原则、安全、日志 |
| [design.md](design.md) | 多端设计：新项目启动门禁、第一轮确认清单、启动文档模板、UI 体系、多端规范 |
| [version-control.md](version-control.md) | 版本管理：分支策略、语义化版本、CHANGELOG、Product Overview、Git 工作流 |
| [deployment.md](deployment.md) | 服务部署：发布检查、迁移、产物备份、健康检查、回滚、CI/CD |
| [database-migrations.md](database-migrations.md) | 数据库迁移：版本管理、执行规范、回滚、工具选择、CI/CD 集成 |
| [database-queries.md](database-queries.md) | 数据库查询：SQL 规范、索引设计、查询优化、EXPLAIN、ORM |
| [database-sync.md](database-sync.md) | 数据库同步：同步策略、增量设计、一致性、冲突解决、工具选型 |
| [linux-server.md](linux-server.md) | Linux 服务器：安全基线、监控、备份、日志、性能调优、Docker、应急响应 |

## 语言/平台
| 文件 | 内容 |
|------|------|
| [go.md](go.md) | Go：项目结构、命名、错误处理、并发、DI、测试、性能、常用库 |
| [python.md](python.md) | Python：环境、风格、类型注解、异步、SQLAlchemy、FastAPI、测试 |
| [frontend.md](frontend.md) | 前端：TypeScript、React、状态管理、CSS、性能、Vite、安全 |

## 项目文档
| 文件 | 内容 |
|------|------|
| [CHANGELOG.md](CHANGELOG.md) | 规则库变更记录 |
| [PRODUCT_OVERVIEW.md](PRODUCT_OVERVIEW.md) | 规则库当前状态、适用范围和维护说明 |

## 工具脚本
| 文件 | 内容 |
|------|------|
| [scripts/generate_claude_md.rb](scripts/generate_claude_md.rb) | 交互选择规则文档并生成整合版 AI 协作规则文档（如 `CLAUDE.md` / `AGENTS.md`） |

> 这些不是教条，是我踩过坑之后总结的。有不同意见随时改。
