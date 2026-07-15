# Architecture

> 最后更新：2026-07-15 | 当前版本：v0.19.0

## 架构概览

Alma 规则库是一个以 Markdown 规范文档为核心、Ruby 生成与校验脚本为辅助的轻量规则工具链。它不提供运行中的服务；使用者既可按主题阅读规则，也可生成单文件规则包，或在真实项目中初始化带作用域与父级继承关系的分层 `AGENTS.md`。

## 系统上下文

```text
开发者 / AI 助手
        │ 阅读、引用、维护
        ▼
Alma 规则库（Markdown 主题规范）
        │
        ├── 画像选择与整合 ──► 单文件 CLAUDE.md / AGENTS.md
        │
        └── 项目扫描 + 模板 ─► 根 AGENTS.md + 模块 AGENTS.md
```

## 模块与职责

| 模块 | 职责 | 依赖 / 通信方式 |
|------|------|-----------------|
| 根目录主题文档 | 定义编程、设计、版本、部署、数据库、前端与平台规范；每篇顶部「硬约束」小节是 AI 必守层，正文为细节层 | Markdown 链接交叉引用 |
| `PRODUCT_OVERVIEW.md` | 说明规则库用途、当前能力与待办 | 与 CHANGELOG、主题文档保持一致 |
| `ARCHITECTURE.md` | 记录本仓库的系统边界、文档职责和架构演进 | 与 README、脚本和主题文档保持一致 |
| `CHANGELOG.md` | 按版本记录规则库变更 | 版本变更时同步维护 |
| `scripts/generate_claude_md.rb` | 交互选择规则主题并生成整合的 AI 协作规则文档；`--compact` 模式只提取各文档「硬约束」小节 | Ruby 标准库；可选 `tty-prompt` |
| `scripts/generate_project_agents.rb` | 扫描项目构建清单，选择通用/React/Go/Go + React 模板，创建缺失的根目录与模块级 `AGENTS.md`；禁止覆盖已有文件 | Ruby 标准库、单文件规则生成器、ERB 模板 |
| `templates/agents/` | 定义可人工维护的根目录与模块级 `AGENTS.md` 初始结构，包括 Scope、Parent、命令和局部规则 | ERB；由项目脚手架读取 |
| `scripts/verify_rules.rb` | 校验硬约束、必选规则、版本、生成产物和嵌套 AGENTS 上溯链，并用临时多模块项目验证脚手架首次生成与重复执行安全性，输出 JSON/Markdown 报告 | Ruby 标准库、两个生成器 |
| `.github/workflows/verify-rules.yml` | 在 PR 与分支推送时验证规则库 | GitHub Actions、Ruby 校验脚本 |
| `.github/workflows/release-claude.yml` | 校验 tag 版本与主分支归属后，为版本 tag 生成最终 `CLAUDE.md` 并发布 GitHub Release 附件 | GitHub Actions、Ruby 脚本、GitHub CLI |

## 数据与接口

- 主要数据载体是仓库内 Markdown 文档，Git 历史提供版本追溯。
- 单文件生成器读取预定义主题文件，并把规则组合为完整文档或供模板嵌入的规则片段。
- 项目脚手架只扫描目标目录内的构建清单和约定目录，不读取业务数据；它只创建缺失的 `AGENTS.md`，不修改已存在文件。
- 仓库不处理用户业务数据、不暴露网络 API，也不保存凭据。

## 部署与运行

- 规则文档可直接在本地仓库、Git 托管平台或目标项目中阅读。
- 使用生成脚本时需 Ruby 运行环境；安装 `tty-prompt` 可获得更好的交互体验，缺失时脚本应降级为基础终端选择。
- 发布方式为 Git 提交、版本号和 Git tag。CI 先校验规则结构、生成产物和版本一致性；只有指向默认分支、且与文档版本一致的 `v*` tag 才会生成对应的精简版 `CLAUDE.md` 并作为 GitHub Release 附件。变更前后需同步维护 CHANGELOG、Product Overview 与本文件。

## 关键决策与演进

- 规则采用按主题拆分的 Markdown，而非单一超长文档，便于按项目画像组合并控制单文件体积。
- 分层 `AGENTS.md` 采用“根级完整基线 + 子级局部差异”模型；子级显式链接最近父级，避免复制整套规则导致漂移。
- 项目脚手架产物是可人工维护的初始化文件，不是持续覆盖的生成产物；重复运行必须跳过已有文件。
- `ARCHITECTURE.md` 固定放在项目根目录，作为架构事实来源；模块级细节可在子目录 README 或 ADR 中补充。
- 新项目和架构变更必须更新架构文档，防止关键技术决策只停留在聊天记录或个人记忆中。
