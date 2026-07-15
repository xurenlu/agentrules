# GENERATED_CLAUDE.md

> 由 `scripts/generate_claude_md.rb` 于 2026-07-15 生成。
> 规则画像：自定义选择
> 生成来源：Alma 规则库。
> 模式：硬约束精简版（--compact），完整背景与细节见规则库原文。

## 使用说明

- 本文件是面向 Claude / Codex / 其他 AI 编程助手的整合规则入口。
- 若本文件与项目内更具体、更晚出现的 `AGENTS.md`、`CLAUDE.md` 或用户指令冲突，以更具体、更晚出现的指令为准。
- AI 开工前先判断当前仓库是新项目、半成品还是既有项目迭代；判断不清时按新项目处理。
- 新项目或规则缺失时，先生成/更新 `AGENTS.md`、`CLAUDE.md`、`PRODUCT_OVERVIEW.md`、`ARCHITECTURE.md` 或等价文档，写清产品定义、技术栈、模块边界、数据流、设计规范、UI token、多语言计划、版本和验收标准。
- 新项目必须创建根目录 `ARCHITECTURE.md`；技术栈、模块边界、服务通信、数据存储、接口协议、认证授权、部署拓扑或关键集成发生变化时，必须同步更新。
- 新项目关键决策应沉淀到 `docs/product-brief.md`、`ARCHITECTURE.md`、`docs/design-system.md`、`docs/ui-tokens.md`、`docs/i18n.md` 和 `docs/decisions/`，不要只依赖 memory 或聊天记录。
- 新项目第一轮沟通只问 6-8 个高价值主题：定位、用户场景、首版范围、平台设备、设计方向、多语言、数据库/数据权限、交付验收；能从仓库判断的内容写成默认假设。
- 架构、数据库、部署、测试、权限等工程决策先给最佳实践建议，再让用户确认；不要把选型责任全丢给用户。
- UI 规范按平台和应用类型先给 2-4 套推荐方向，再让用户选择；选定后沉淀到 `docs/design-system.md`、`docs/ui-tokens.md` 等仓库文档。
- 架构、设计规范、数据库、多语言、部署和验收等关键决策必须落入仓库文档；memory 和聊天记录不能作为唯一事实来源。
- 涉及界面项目时，先按设计规范与用户确认平台、用户、核心场景、视觉气质、信息密度、UI 体系和计划支持语言，再进入实现。
- 修改代码后必须同步版本号、CHANGELOG 和必要的产品概览文档。
- 不得输出或提交密钥、Token、凭据、个人隐私数据。

## 本次整合文档
- `ai-guardrails.md`：文件编辑方式、破坏性操作确认、共享分支保护和如实汇报
- `programming.md`：代码风格、错误处理、测试、版本控制、安全和日志
- `design.md`：新项目启动门禁、UI 规范方向、docs 文档沉淀和多端规范
- `frontend.md`：TypeScript、React、状态管理、CSS、性能、安全和测试
- `go.md`：Go 项目结构、错误处理、并发、DI、测试、性能和 Go + React embed
- `python.md`：Python 环境、类型、异步、数据库、测试和常用库
- `database-migrations.md`：迁移版本、建表、索引、启动迁移、回滚和 CI/CD
- `database-queries.md`：SQL 编写、索引、查询优化、EXPLAIN 和 ORM
- `database-sync.md`：全量、增量、实时同步、一致性、冲突解决和监控
- `deployment.md`：发布检查、迁移、产物备份、健康检查、回滚和 CI/CD
- `linux-server.md`：安全基线、监控、备份、日志、性能调优、Docker 和应急响应
- `version-control.md`：分支策略、语义化版本、Build 号、CHANGELOG、.gitignore 和 Git 工作流

---

# AI 协作红线

> 来源：`ai-guardrails.md`

## 硬约束

- **MUST**：创建/更新文件用编辑/写文件能力（直接写入文件、应用补丁），确保变更可审计、可回滚、可 review
- **MUST NOT**：用管道、`cat`、`echo` 重定向、heredoc 等 shell 方式生成或覆写文件内容
- **MUST**：破坏性或不可逆操作先向用户确认后再执行：删除数据、覆盖未读过的文件、强制推送、对外发布、执行 `migrate down`
- **MUST NOT**：`git push --force` 到 main / develop 等共享分支
- **MUST NOT**：执行不带 WHERE 的 UPDATE / DELETE，或 DROP / TRUNCATE 等语句，除非用户明确要求且已确认备份可恢复
- **MUST NOT**：`rm -rf` 删除仓库外目录或用户数据；批量清理前先列出将删除的内容让用户确认
- **MUST**：如实报告执行结果——测试失败就说失败并附输出，跳过的步骤明确说明；不把未验证的工作说成已完成
- **MUST**：发现疑似密钥/敏感信息时优先脱敏或移除并提示风险，不复述到回复、日志或提交信息里
- **MUST NOT**：做与任务无关的改动（顺手重构、重排格式、改无关命名）；改动范围与任务对齐
- **MUST NOT**：把用户写给 AI/开发者的需求说明、验收标准、Prompt、规则、实现备注、调试信息或运维/发布元数据，未经判断就当作最终用户可见文案。需求默认只定义产品行为，不等于界面文案；仅当用户明确指定其为展示文案，或该信息确实是最终用户完成当前任务所必需时，才可展示，并须改写为符合最终用户角色、目标与操作场景的产品语言

---

# 编程通用规范

> 来源：`programming.md`

## 硬约束

- **MUST**：开工前先判断项目阶段（新项目 / 半成品 / 迭代）；新项目先落启动文档，再进入大规模编码
- **MUST**：一个项目一种代码风格，用 linter 强制
- **MUST**：用户可见文案走 i18n/本地化资源，不硬编码在视图代码里；业务值与展示文案分离
- **MUST**：核心逻辑有单元测试，测试数据隔离，不依赖外部环境状态
- **MUST**：API 层测试和端到端测试优先用 Ruby 编写，输出 JSON + Markdown 两种格式报告；单元测试用语言原生框架（Go test、Vitest、JUnit、pytest 等），不受 Ruby 约束
- **MUST**：错误信息带上下文（目标、参数、原因），业务异常用自定义类型
- **MUST**：SQL 一律参数化查询
- **MUST**：结构化日志，分级正确，敏感信息脱敏
- **MUST**：关键决策（架构、数据库、设计、多语言、部署、验收）落仓库文档，不只留在 memory 或聊天记录
- **MUST NOT**：吞异常（空 catch / 裸 except 不 log）
- **MUST NOT**：密钥、Token、凭据进代码、日志、示例或提交
- **MUST NOT**：魔法数字/字符串散落代码，必须抽成有名字的常量
- **MUST**：单个文件不超过 3000 行——超过 2000 行就要考虑拆分，超过 3000 行必须拆分

---

# 多端产品设计规范

> 来源：`design.md`

## 硬约束

- **MUST**：界面项目开工前先判断项目阶段（新项目 / 半成品 / 迭代）并说明依据；判断不清（不确定性 ≥ 30%）按新项目处理，先确认再动手
- **MUST**：新项目先生成/更新 `AGENTS.md`、`CLAUDE.md`、`PRODUCT_OVERVIEW.md`、`ARCHITECTURE.md` 或等价启动文档，再进入大规模实现
- **MUST**：新项目第一轮沟通合并为 6-8 个高价值问题；能从仓库/截图判断的内容写成默认假设让用户确认
- **MUST**：架构、数据库、部署、权限、测试等工程决策先给推荐方案和理由，再让用户确认；不把选型责任全丢给用户
- **MUST**：用户要求直接开工时，显式列出采用的默认设计假设并写入启动文档，标注"待确认"
- **MUST**：界面项目先定义最小 UI 体系（字体、字号、颜色 token、间距、圆角、组件状态），可以简洁但不能缺席
- **MUST**：新项目确认多语言范围（首发/后续语言、默认语言、fallback、日期/数字/货币格式、是否 RTL）后再选 i18n 方案
- **MUST**：所有可见文案走 i18n/平台本地化资源，不散落在视图代码里
- **MUST**：加载、空状态、错误、无权限、成功反馈、危险操作确认等状态必须设计
- **MUST**：需求变化时同步回写启动文档；影响系统边界/模块/数据流/部署时同步更新 `ARCHITECTURE.md`
- **MUST NOT**：关键决策只放 memory 或聊天记录；仓库文档是唯一事实来源
- **MUST NOT**：多端产品把一张设计图硬套到所有平台；语义一致，布局交互按平台习惯落地

---

# 前端规范

> 来源：`frontend.md`

## 硬约束

- **MUST**：框架在 Vue 与 React 之间选择时优先 React；新项目默认 React + TypeScript，`strict: true` 全开
- **MUST**：包管理器优先 yarn（安装依赖、执行脚本都用 yarn）
- **MUST**：JSX/TSX 不硬编码对外可见文案（UI 文案、按钮、提示、错误信息、枚举展示名），一律走 i18n 字典/资源文件
- **MUST**：数据请求用 React Query / SWR / RTK Query，不用裸 useEffect 拉数据
- **MUST**：`dangerouslySetInnerHTML` 必须先 sanitize（DOMPurify）
- **MUST**：新界面项目开工前先确认平台、用户、视觉气质、UI 体系和多语言计划，再写页面
- **MUST NOT**：使用 `any`（用 `unknown` + 类型守卫）；ESLint 配置 `no-explicit-any: error`
- **MUST NOT**：列表有增删时用 index 做 key
- **MUST NOT**：token 放 localStorage（access token 放内存，refresh token 放 httpOnly cookie）
- **MUST NOT**：后端密钥放进 `VITE_` 前缀环境变量或任何前端可见配置

---

# Go 规范

> 来源：`go.md`

## 硬约束

- **MUST**：error 永远放返回值最后一位；wrap 时保留上下文（`fmt.Errorf("...: %w", err)`）
- **MUST**：错误类型判断用 `errors.Is` / `errors.As`，不比对 `err.Error()` 字符串
- **MUST**：goroutine 生命周期可控——context 取消 + WaitGroup/errgroup 等待，不泄漏
- **MUST**：接口定义在使用方 package，不在实现方定义再被 import
- **MUST**：同结构多用例的测试用表驱动
- **MUST**：`main` 只做依赖注入和启动，业务逻辑放 `internal/`
- **MUST**：涉及迁移与部署时遵守 [database-migrations.md](database-migrations.md) 与 [deployment.md](deployment.md) 的硬约束（启动自动 up、失败停启动、多实例锁、部署前备份旧二进制）
- **MUST NOT**：panic 做流程控制；panic 只给不可恢复错误（配置缺失、启动失败）
- **MUST NOT**：channel 读端执行 close；谁写谁 close
- **MUST NOT**：用运行时反射的 DI 框架；要 DI 用构造函数参数或 wire

---

# Python 规范

> 来源：`python.md`

## 硬约束

- **MUST**：一个项目一个虚拟环境（pyenv + virtualenv / poetry），不动系统 Python
- **MUST**：依赖锁版本（`requests==2.31.0`，不是 `>=2`）
- **MUST**：函数签名和公共 API 写类型注解
- **MUST**：状态、类型、选项用 Enum，不用裸字符串到处传
- **MUST**：数据库迁移用 Alembic / Django migrations，生成的脚本人工 review
- **MUST**：单元测试用 pytest；外部 HTTP 依赖用 mock，不真打外部 API
- **MUST NOT**：裸 `except:` 或 `except Exception` 不 log 就吞掉
- **MUST NOT**：async 函数里调用阻塞的同步 IO（如 `time.sleep()`、同步 DB 驱动）
- **MUST NOT**：异常只 print；用 `logger.exception()` 保留 traceback

---

# 数据库迁移规范

> 来源：`database-migrations.md`

## 硬约束

- **MUST**：所有 DDL 变更走迁移文件，禁止手改数据库
- **MUST**：up/down 成对，down 必须实际测试过；删字段/删表的 down 先备份数据
- **MUST**：每张业务表有主键（自增 BIGINT 或 UUID）、`created_at`、`updated_at`
- **MUST**：所有外键列建索引；索引命名 `idx_<表>_<列>` / `uk_<表>_<列>`
- **MUST**：服务启动时自动执行一次 `migration up`；失败即阻止启动并输出迁移版本、文件名和错误上下文
- **MUST**：多实例部署时迁移必须加锁（数据库锁 / 迁移工具自带锁 / 分布式锁）
- **MUST**：提供 `migrate up` / `migrate down --steps N` / `migrate status` CLI 子命令
- **MUST**：prod 迁移前确认最近备份可恢复
- **MUST**：高风险迁移（大表 DDL、不可逆数据变更、删字段/删表）人工审批，不随启动自动执行
- **MUST NOT**：修改已提交的迁移文件
- **MUST NOT**：一个迁移混多件事（加字段 + 建索引 + 改表名拆开写）
- **MUST NOT**：`migration down` 在未确认备份和影响范围前执行

---

# 数据库查询规范

> 来源：`database-queries.md`

## 硬约束

- **MUST**：一律参数化查询；动态表名/列名无法参数化时用白名单校验
- **MUST**：WHERE / JOIN / ORDER BY 的高频列有索引，并用 EXPLAIN 验证索引实际被使用
- **MUST**：深分页用游标（`WHERE id > last_id`），不用大 offset
- **MUST**：ORM 关联查询避免 N+1（eager loading / JOIN FETCH / preload）
- **MUST**：批量写入用批量语句，不循环单条
- **MUST NOT**：`SELECT *`；明确列出需要的列
- **MUST NOT**：把 `password_hash` 等敏感列查出传给前端，哪怕前端不用
- **MUST NOT**：长事务；一个事务控制在秒级

---

# 数据库同步规范

> 来源：`database-sync.md`

## 硬约束

- **MUST**：每条同步操作幂等，可安全重放（唯一键 + upsert / ON DUPLICATE KEY UPDATE）
- **MUST**：有 checkpoint 断点续传机制，任务挂掉能从断点继续
- **MUST**：双向同步前先定义并测试冲突策略；能单向就不要双向
- **MUST**：同步限流，不打满目标库，给正常业务留空间
- **MUST**：配置同步延迟、失败率、数据差异（checksum）三类监控告警
- **MUST**：上线前完成初始全量同步并校验一致性；准备好"关闭同步不影响业务"的回滚方案
- **MUST NOT**：跨系统同步追求实时强一致；定义可接受的延迟窗口

---

# 服务部署规范

> 来源：`deployment.md`

## 硬约束

- **MUST**：每次部署可快速回滚；替换前备份旧产物到带版本号/时间戳的目录，至少保留最近 3 个版本
- **MUST**：新版本通过健康检查（进程、端口、健康接口、版本接口、关键业务接口）后再承载流量
- **MUST**：发布前确认前端、后端、API header、构建产物中的版本号一致
- **MUST**：部署完成后反馈版本、部署结果、迁移结果、备份路径和具体回滚命令
- **MUST**：出问题先回滚应用（恢复旧产物），`migrate down` 只在确认备份且新迁移不兼容旧版本时手动执行
- **MUST**：高风险变更（大表 DDL、不可逆变更、跨服务联动）人工审批后再发布
- **MUST**：部署脚本幂等，重复执行不产生脏状态
- **MUST NOT**：静默失败；部署、迁移、重启、健康检查任一步失败必须明确报告原因和下一步建议
- **MUST NOT**：配置、密钥、证书打进构建产物；走环境变量或密钥管理

---

# Linux 服务器规范

> 来源：`linux-server.md`

## 硬约束

- **MUST**：SSH 禁用 root 登录和密码认证，只留密钥；防火墙最小开放
- **MUST**：监控 CPU、内存、磁盘（空间和 inode 都要），超过 80% 告警
- **MUST**：备份自动化，且定期做恢复演练——没验证过的备份等于没有
- **MUST**：所有应用日志配 logrotate 轮转
- **MUST**：应急时先保留现场（top、free、df、dmesg、应用日志）再操作；回滚优先于修复
- **MUST**：运维脚本幂等，执行 10 次和 1 次结果一样
- **MUST**：容器设置 `--memory` / `--cpus` 资源限制
- **MUST NOT**：Docker 镜像用 `latest` 标签，版本 pin 死
- **MUST NOT**：共用登录账号；一人一号，操作可追溯
- **MUST NOT**：不理解含义的内核参数乱调

---

# 版本管理规范

> 来源：`version-control.md`

## 硬约束

- **MUST**：每次修改代码后同步更新版本号和 `CHANGELOG.md`
- **MUST**：版本号采用语义化格式，允许 rc 预发布标识（如 `1.2.3-rc2`）
- **MUST**：功能新增才提升正式版本位（MINOR/MAJOR），并把 rc 重置为 `rc1`；bugfix 只递增 rc 号（`-rc2` → `-rc3`），不得提升正式版本位（对外发布、须遵循标准 SemVer 的库/包除外，详见 `version-control.md` 语义化版本号一节）
- **MUST**：前端与后端版本号保持一致；服务端 API 通过响应 header（如 `X-App-Version`）暴露当前版本
- **MUST**：用户要求 git 提交时，打 `v{版本号}` tag 并随代码一起推送（远程是 GitHub 时推到 GitHub）
- **MUST**：新项目创建根目录 `.gitignore` 和 `ARCHITECTURE.md`；架构变更在同一改动中更新文档
- **MUST**：敏感文件（`.env`、密钥等）必须列入 `.gitignore`，不得提交
- **MUST NOT**：直接在 main/develop 上 commit；一律走 feature 分支 + PR
- **MUST NOT**：一个 PR 混 feat + fix + refactor
- **MUST NOT**：改了版本号不写 CHANGELOG，或 CHANGELOG 与代码不同步
