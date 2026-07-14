# Changelog

## [0.14.0] - 2026-07-15

### Added
- 新增 `ai-guardrails.md` AI 协作红线：禁止 shell 重定向/heredoc 写文件、破坏性操作先确认、禁止强推共享分支、如实汇报执行结果；标记为 required，所有画像自动包含。
- 编程规范硬约束新增单文件行数限制：超过 2000 行考虑拆分，超过 3000 行必须拆分。
- 仓库根目录提交 `GENERATED_CLAUDE.md`：`--all --compact` 全量硬约束精简版示例，可直接复制到项目或对照检查。
- 新增仓库 `.gitignore`。

### Changed
- README、Product Overview 和生成脚本 DOCS 挂入 AI 协作红线入口。

## [0.13.0] - 2026-07-15

### Added
- 全部 11 个主题文档顶部新增「硬约束」小节：只含 MUST / MUST NOT 的 AI 必守清单，正文降级为背景与细节。
- 规则生成脚本新增 `--compact` 模式，只整合各文档的「硬约束」小节（全量 1800+ 行精简为约 240 行），推荐注入 `CLAUDE.md` / `AGENTS.md`。

### Changed
- 版本号规则与全局约定对齐：默认约定下 bugfix 只递增 rc 号，功能新增才提升正式版本位并重置 rc；标准 SemVer（PATCH 递增）保留为对外发布库/包的例外，一个项目只能用一套。
- 测试规范明确分层：API 层测试与端到端测试优先用 Ruby 编写并输出 JSON + Markdown 报告；单元测试用语言原生框架（Go test、Vitest、JUnit、pytest），浏览器 E2E 可用 Playwright。
- monorepo 包管理由 pnpm workspace 改为 yarn workspaces，与「优先 yarn」保持一致；已有 pnpm/npm 体系沿用现状。
- 迁移与部署回滚规则收拢到单一来源：`go.md`、`deployment.md` 中重复的迁移/备份条目改为链接 `database-migrations.md` 与 `deployment.md`。

### Fixed
- 生成脚本读取规则文件时显式指定 UTF-8 编码，修复非 UTF-8 locale 下 `invalid byte sequence` 报错。

## [0.12.0] - 2026-07-12

### Changed
- 明确 `PRODUCT_OVERVIEW.md` 与 `ARCHITECTURE.md` 的职责边界、必答问题和不应包含的内容。
- 为两份文档补充可复制模板、架构图示例和按变更类型判断更新目标的对照表。

## [0.11.0] - 2026-07-12

### Added
- 新增根目录 `ARCHITECTURE.md`，记录规则库的系统边界、文档职责和维护方式。
- 版本管理规范新增 `ARCHITECTURE.md` 约束：新项目必须创建，架构变更必须在同一改动中同步维护，并提供最小模板。

### Changed
- 设计规范、通用编程规范和规则生成脚本统一要求新项目生成 `ARCHITECTURE.md`，并在技术栈、模块、通信、存储、接口、认证、部署或关键集成变化时更新。
- README 与 Product Overview 增加架构文档入口和维护说明。

## [0.10.0] - 2026-07-08

### Added
- 规则生成脚本新增按输出文件名自适应标题和交互提示，支持生成 `CLAUDE.md`、`AGENTS.md` 或其他等价 AI 协作规则文档。
- 规则生成脚本默认说明新增 docs 文档沉淀提醒，要求新项目关键决策落到 `docs/product-brief.md`、`docs/architecture.md`、`docs/design-system.md`、`docs/ui-tokens.md`、`docs/i18n.md` 和 `docs/decisions/`。

### Changed
- 更新规则生成脚本中的设计规范、版本管理规范摘要。
- README 和 Product Overview 将工具说明从 Claude 专属改为通用 AI 协作规则文档。

## [0.9.0] - 2026-07-08

### Added
- 版本管理规范新增 macOS/iOS 项目 Build 号同步规则，要求 `CFBundleShortVersionString` 与 `CFBundleVersion` / `CURRENT_PROJECT_VERSION` 同步维护。
- 版本管理规范新增 `.gitignore` 基线，覆盖通用、Node/前端、Go、Python、macOS/iOS 常见忽略项和敏感文件规则。

### Changed
- Product Overview 更新当前版本和版本控制规范说明。

## [0.8.0] - 2026-07-08

### Added
- 设计规范新增“UI 规范方向推荐”，按 Web、H5、iOS、macOS、Android、游戏娱乐、数据大屏等平台/应用类型推荐 UI 方向。
- 设计规范新增“文档优先，不靠 Memory”规则，要求架构、数据库、设计规范、UI token、多语言、部署和验收标准落入仓库文档。
- 启动文档模板新增项目文档索引、推荐 UI 方向、选定 UI 方向、参考产品和禁用风格字段。

### Changed
- 通用编程规范、前端规范和 Claude 生成脚本同步强调跨 Agent 协作时以仓库文档为准。

## [0.7.0] - 2026-07-08

### Added
- 新增“推荐优先，确认兜底”规则，要求 AI 对架构、数据库、部署、权限、测试等工程决策先给最佳实践建议，再让用户确认或指出例外。
- 设计规范新增默认工程建议表，覆盖模块化单体、React 技术栈、REST 接口、PostgreSQL/MySQL/SQLite 选型、迁移、权限、部署、UI token 和测试策略。

### Changed
- 新项目推荐提问模板改为先给默认建议，再确认用户约束。
- 通用编程规范、前端规范和 Claude 生成脚本默认说明同步强调“不要把选型责任全丢给用户”。

## [0.6.0] - 2026-07-08

### Added
- 新项目第一轮确认清单强化数据库、数据与权限主题，要求确认 SQLite/MySQL/PostgreSQL 等数据库选型、开发/生产差异、迁移工具、备份恢复、全文检索、导入导出、数据量级和事务要求。
- 启动文档模板新增“数据库与数据”章节。

### Changed
- 通用编程规范和 Claude 生成脚本默认说明同步强调数据库选型必须问清楚。

## [0.5.0] - 2026-07-08

### Added
- 设计规范新增“新项目第一轮确认清单”，按项目定位、用户场景、首版范围、平台设备、设计方向、多语言、数据权限、交付验收 8 个主题组织。
- 设计规范新增推荐提问模板和沟通节奏，要求第一轮沟通克制、带默认假设、优先确认不可逆事项。

### Changed
- 通用编程规范、前端规范和 Claude 生成脚本同步强调新项目第一轮只问 6-8 个高价值主题，避免把确认项拆得过碎。
- README 和脚本文档摘要更新为包含第一轮确认清单。

## [0.4.0] - 2026-07-08

### Added
- 新项目启动门禁新增多语言计划确认项，要求先询问首发语言、后续支持语言、默认语言、fallback 语言、日期/数字/货币格式和 RTL 需求。
- 设计规范新增多语言与本地化最小规则，覆盖字体回退、文案长度、格式本地化、RTL 预判和文案资源管理。

### Changed
- 通用编程规范、前端规范和 Claude 生成脚本默认说明同步强调“先问清计划支持哪些语言”。
- Product Overview 更新当前版本。

## [0.3.0] - 2026-07-08

### Added
- 设计规范新增“新项目启动门禁”，要求 AI 开工前判断项目阶段，必要时先沟通并生成 `AGENTS.md` / `CLAUDE.md` / `PRODUCT_OVERVIEW.md` 等协作规则文档。
- 设计规范新增启动文档模板，覆盖产品定义、平台技术栈、设计规范、UI token、交互状态、工程规则和验收标准。
- 设计规范新增 UI 体系最小集，包含字体族、字号体系、颜色语义、间距圆角、布局断点和组件状态。

### Changed
- 通用编程规范、前端规范和 Claude 生成脚本的默认说明强化“先判断新项目，再落文档，再实现”的流程。
- Product Overview 更新当前版本和新项目启动门禁说明。

## [0.2.0] - 2026-07-08

### Added
- 新增 Ruby 交互脚本 `scripts/generate_claude_md.rb`，支持按项目画像或指定文档生成整合版 `CLAUDE.md`。
- 脚本优先使用 `tty-prompt` 提供多选终端界面，未安装时自动降级为基础终端选择。

### Changed
- README 增加工具脚本入口。
- Product Overview 更新当前版本和工具说明。

## [0.1.0] - 2026-07-08

### Added
- 新增多端产品设计规范，覆盖新项目设计沟通、H5、电脑版网页、macOS App、Android App 和多端一致性。
- 新增项目概览文档，记录规则库用途、当前版本、维护方式和待办事项。

### Changed
- README 增加设计规范、变更记录和项目概览入口。
- 通用编程规范与前端规范增加“新项目启动前先确认设计规范”的要求。
