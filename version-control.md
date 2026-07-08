# 版本管理规范

## 分支策略

### 主分支
- **develop 优先**：如果仓库有 `develop` 分支，一切开发从 develop 拉出；没有就用 `main`
- **main 只接受合并**：main 上的代码必须是可发布的稳定版本，不直接在 main 上开发

### 开发流程
```
main ─────────────────────────────────────●──●── (release tag)
          \                              /
develop ───●──●──────────────────●──────●
              \                  /
feature/xxx ───●──●──●──────────
```

1. 从 develop（没有则 main）拉 feature 分支
2. 在 feature 分支开发 + 提交
3. 完成后提 PR 合回 develop
4. 准备发布时，develop → main，打 tag

### 分支命名
```
feature/<功能名>      # feature/user-auth, feature/payment
fix/<问题描述>        # fix/login-timeout, fix/typo
release/<版本号>      # release/v1.2.0
hotfix/<问题描述>     # hotfix/critical-bug
```

## 语义化版本号

格式：`MAJOR.MINOR.PATCH`（如 `1.4.2`）

| 变更类型 | 版本号 | 说明 |
|---------|--------|------|
| PATCH | 1.4.X → 1.4.X+1 | bug 修复，行为不变 |
| MINOR | 1.X → 1.X+1.0 | 新增功能，向后兼容 |
| MAJOR | X → X+1.0.0 | 破坏性变更，不兼容旧 API |

### 版本号在哪改
- Go 项目：源码里声明 `var Version = "1.2.3"`（编译时 ldflags 注入也行）
- 前端项目：`package.json` 的 `version` 字段
- Python 项目：`pyproject.toml` / `__init__.py` 里的 `__version__`
- 多项目仓库：各子项目独立版本号，根目录 CHANGELOG 汇总

### 每次改动前先想
- 这是修 bug？→ PATCH
- 加了新功能但 API 没变？→ MINOR
- 删了接口 / 改了字段类型 / 行为不兼容？→ MAJOR

### macOS/iOS 项目：Build 号同步

- 语义化版本写入 `CFBundleShortVersionString`（用户可见版本号）
- `CFBundleVersion` / `CURRENT_PROJECT_VERSION`（Build 号）每次发版 **+1**，从 1 开始递增，不重置
- 改版本号时必须同时改 Build 号，两者不能脱节
- 在哪改：`Info.plist` / `.xcconfig` / Xcode 项目设置 `CURRENT_PROJECT_VERSION`

## CHANGELOG.md

每次提交必须更新。按时间倒序，最新在最上面。

### 格式模板
```markdown
# Changelog

## [1.2.0] - 2026-05-27

### Added
- 用户注册接口 /api/auth/register
- 登录失败 5 次锁定 15 分钟

### Changed
- 密码哈希从 md5 改为 bcrypt

### Fixed
- 修复 token 过期后不自动刷新的问题

### Deprecated
- /api/v1/login 将于 v2.0 移除，请迁移到 /api/v2/auth

---

## [1.1.0] - 2026-05-20

### Added
- 仪表盘页面
```

### 分类标准
- **Added**：新增功能
- **Changed**：修改已有功能
- **Fixed**：Bug 修复
- **Removed**：删除功能
- **Deprecated**：即将删除，先标废弃
- **Security**：安全修复

### 规则
- 一个版本一个 `## [版本号]` 段落
- 没有对应内容的分段直接省略（别写 "None"）
- 每条用一句话说清改了什么，附上 PR 号更好

## PRODUCT_OVERVIEW.md

**这是项目的"当前状态说明书"**——不看代码也能知道项目是什么、有什么功能、怎么跑。

### 格式模板
```markdown
# Product Overview

> 最后更新：2026-05-27 | 当前版本：v1.2.0

## 项目简介
一句话说清楚这个项目是干什么的。

## 核心功能
- 用户注册/登录（支持手机号 + 邮箱）
- 仪表盘数据概览
- 工单创建与流转
- ...

## 技术栈
- 后端：Go 1.23 + chi + sqlx + MySQL 8.0
- 前端：React 19 + TypeScript + Vite + Tailwind CSS
- 部署：Go embed 单文件，systemd 守护

## API 概览
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /api/auth/login | 用户登录 |
| GET | /api/users/me | 当前用户信息 |
| ... | ... | ... |

## 部署
- 编译：`make build`
- 运行：`./bin/server`
- 配置：环境变量 `APP_PORT` `DB_DSN`

## 已知问题 / 待办
- [ ] 密码重置流程未实现
- [ ] 大屏适配（移动端）
```

### 规则
- 每次发版后更新版本号和最后更新时间
- 新增功能时同步更新核心功能列表和 API 概览
- **这份文档给新人看的**——他应该能靠这个文档把项目跑起来

## 提交流程

### 每次开发结束的标准动作
```bash
# 1. 改版本号
# 2. 更新 CHANGELOG.md
# 3. 更新 PRODUCT_OVERVIEW.md（如果有功能变化）

# 4. 提交
git add .
git commit -m "chore: bump version to v1.2.0

- Add user registration endpoint
- Fix token refresh bug"

# 5. 推送
git push origin feature/user-auth

# 6. 提 PR：feature/user-auth → develop

# 7. 合并后打 tag
git tag -a v1.2.0 -m "Release v1.2.0"
git push origin v1.2.0
```

### Commit Message 规范
```
type(scope): summary

详细说明（可选，可多行）
```

| type | 用途 |
|------|------|
| feat | 新功能 |
| fix | Bug 修复 |
| docs | 文档变更 |
| style | 格式（不影响代码逻辑） |
| refactor | 重构 |
| perf | 性能优化 |
| test | 测试 |
| chore | 构建/工具/版本号 |
| ci | CI/CD 变更 |

### 别做的事
- 别直接在 main/develop 上 commit
- 别一个 PR 混 feat + fix + refactor
- 别忘了 push tag（别人拉不到）
- 别改完版本号不写 changelog
- 别让 CHANGELOG 和代码不同步

## .gitignore

每个项目根目录必须有 `.gitignore`。以下是在各种项目中常见的忽略条目：

### 通用
```
.DS_Store
*.swp
*.swo
*~
.env
.env.local
*.log
.cache
```

### Node / 前端
```
node_modules/
dist/
build/
.next/
.nuxt/
.cache/
```

### Go
```
.local-cache/
vendor/（除非使用 vendor 模式）
```

### Python
```
__pycache__/
*.pyc
.venv/
venv/
.pytest_cache/
.mypy_cache/
.ruff_cache/
```

### macOS / iOS
```
DerivedData/
*.xcworkspace/xcuserdata/
Pods/
.build/
```

### 规则
- **能匹配目录的用 `/` 结尾**（如 `node_modules/`），避免误伤同名文件
- **优先用 `*` 模式**，别逐条写几百行
- **敏感文件必须列在 `.gitignore`**（`.env`、密钥文件等）
- **别临时 `git add -f` 忽略的文件**——除非真的有理由打破规则

## 完整 workflow 示例

```
想做一个用户头像上传功能：

1. git checkout develop && git pull
2. git checkout -b feature/avatar-upload
3. 开发...
4. 改版本号：v1.2.0 → v1.3.0（新功能，MINOR）
5. 更新 CHANGELOG.md
6. 更新 PRODUCT_OVERVIEW.md（接口、功能列表）
7. git commit -m "feat(avatar): add avatar upload endpoint"
8. git push origin feature/avatar-upload
9. PR: feature/avatar-upload → develop
10. 合并后 git tag v1.3.0 && git push --tags
```
