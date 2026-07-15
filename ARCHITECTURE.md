# Architecture

> 最后更新：2026-07-15 | 当前版本：v0.18.0

## 架构概览

Alma 规则库是一个以 Markdown 规范文档为核心、Ruby 脚本为辅助的轻量规则仓库。它不提供运行中的服务；使用者按主题阅读规则，或通过脚本将所选规则组合为项目内的 AI 协作规则文档。

## 系统上下文

```text
开发者 / AI 助手
        │ 阅读、引用、维护
        ▼
Alma 规则库（Markdown 主题规范）
        │ 选择并整合
        ▼
Ruby 生成脚本 ─────────────► 目标项目的 AGENTS.md / CLAUDE.md
```

## 模块与职责

| 模块 | 职责 | 依赖 / 通信方式 |
|------|------|-----------------|
| 根目录主题文档 | 定义编程、设计、版本、部署、数据库、前端与平台规范；每篇顶部「硬约束」小节是 AI 必守层，正文为细节层 | Markdown 链接交叉引用 |
| `PRODUCT_OVERVIEW.md` | 说明规则库用途、当前能力与待办 | 与 CHANGELOG、主题文档保持一致 |
| `ARCHITECTURE.md` | 记录本仓库的系统边界、文档职责和架构演进 | 与 README、脚本和主题文档保持一致 |
| `CHANGELOG.md` | 按版本记录规则库变更 | 版本变更时同步维护 |
| `scripts/generate_claude_md.rb` | 交互选择规则主题并生成整合的 AI 协作规则文档；`--compact` 模式只提取各文档「硬约束」小节 | Ruby 标准库；可选 `tty-prompt` |
| `scripts/verify_rules.rb` | 校验硬约束、必选规则、版本、生成产物和嵌套 AGENTS 上溯链，输出 JSON/Markdown 报告 | Ruby 标准库、规则生成器 |
| `.github/workflows/verify-rules.yml` | 在 PR 与分支推送时验证规则库 | GitHub Actions、Ruby 校验脚本 |
| `.github/workflows/release-claude.yml` | 校验 tag 版本与主分支归属后，为版本 tag 生成最终 `CLAUDE.md` 并发布 GitHub Release 附件 | GitHub Actions、Ruby 脚本、GitHub CLI |

## 数据与接口

- 主要数据载体是仓库内 Markdown 文档，Git 历史提供版本追溯。
- Ruby 脚本读取预定义主题文件，并将组合结果写入目标项目指定的协作规则文档。
- 仓库不处理用户业务数据、不暴露网络 API，也不保存凭据。

## 部署与运行

- 规则文档可直接在本地仓库、Git 托管平台或目标项目中阅读。
- 使用生成脚本时需 Ruby 运行环境；安装 `tty-prompt` 可获得更好的交互体验，缺失时脚本应降级为基础终端选择。
- 发布方式为 Git 提交、版本号和 Git tag。CI 先校验规则结构、生成产物和版本一致性；只有指向默认分支、且与文档版本一致的 `v*` tag 才会生成对应的精简版 `CLAUDE.md` 并作为 GitHub Release 附件。变更前后需同步维护 CHANGELOG、Product Overview 与本文件。

## 关键决策与演进

- 规则采用按主题拆分的 Markdown，而非单一超长文档，便于按项目画像组合并控制单文件体积。
- `ARCHITECTURE.md` 固定放在项目根目录，作为架构事实来源；模块级细节可在子目录 README 或 ADR 中补充。
- 新项目和架构变更必须更新架构文档，防止关键技术决策只停留在聊天记录或个人记忆中。
