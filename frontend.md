# 前端最佳实践

## 硬约束

> 本节是 AI 必守清单，违反即错误；下文各节是背景、示例和细节，按需阅读。

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

## 启动前设计确认
- **先判断是不是新项目**：如果仓库缺少产品定义、设计系统、`AGENTS.md`/`CLAUDE.md` 或只有脚手架，先按新项目处理，不直接写页面
- **先落启动文档**：新前端项目应先生成或更新协作规则文档，明确设计规范、UI token、组件状态、多语言计划、i18n、版本、测试和验收标准
- **第一轮别问碎**：先确认平台设备、核心用户、首版流程、视觉气质、UI 体系、多语言和验收标准；字号、圆角、按钮状态等细节可在启动文档里用默认 token 承接
- **按平台推荐 UI 方向**：Web 后台默认稳重工作台，官网可选品牌/现代科技，iOS/macOS 优先原生规范，Android 优先 Material 3，游戏/娱乐再考虑卡通或强视觉方案
- **设计规范落到 docs**：选定 UI 方向后，把设计系统、UI token、组件状态、平台差异写入 `docs/design-system.md`、`docs/ui-tokens.md` 或等价文档，不只保存在 memory
- **涉及持久化先给数据库建议**：全栈、后台或带本地数据的新项目先给数据库推荐方案，再确认 SQLite/MySQL/PostgreSQL/其他数据库、开发/生产差异、迁移和备份策略
- **界面项目先问清设计规范**：新建或重做 H5、电脑版网页、后台、移动 Web 等前端项目时，先确认目标平台、用户角色、核心场景、视觉气质、信息密度和设计参照，再写页面
- **多语言先问范围**：先确认首发支持语言、后续计划语言、默认语言、fallback 语言、日期/数字/货币格式和 RTL 需求，再选 i18n 方案和布局策略
- **平台规范优先**：H5 和电脑版网页的布局、交互、状态、响应式与性能要求详见 [design.md](design.md)
- **先简报后实现**：需求不完整时先输出设计简报和默认假设，用户确认后再进入代码实现

## TypeScript 优先
- **新项目默认 TS**：别开倒车用纯 JS。类型安全带来的收益远超学习成本
- **strict 模式全开**：`strict: true`，别偷懒关 `strictNullChecks`
- **type > interface**：除非需要 declaration merging，否则用 type
- **any 是毒药**：`@typescript-eslint/no-explicit-any: error`。实在不行用 `unknown` + 类型守卫
- **as 断言最小化**：`as` 绕过类型检查，只在边界用（API 响应等）
- **enum 谨慎用**：TS enum 有运行时开销，`as const` + union type 更好

## 组件设计
- **单一职责**：一个组件做一件事。超过 200 行就该拆
- **容器与展示分离**：Container 管数据和逻辑，Presentational 只管渲染
- **Props 下传，Events 上抛**：数据单向流动。别让子组件直接改父组件状态
- **别过度拆组件**：复用 3 次再抽。只用一次的东西别急着抽象
- **defaultProps 用解构默认值替代**：`{ size = 'md' }: Props` 比 `Component.defaultProps` 好

## React 特定
- **函数组件 + Hooks**：类组件历史遗留问题。新代码全用函数组件
- **React 文案走 i18n**：对外可见文本不要直接写在 JSX/TSX 里，使用 React 生态的 i18n 字典/资源文件
- **useEffect 最小化**：大多数情况其实是 event handler 的逻辑，不需要 effect
- **别用 useEffect 做数据请求**：用 React Query / SWR / RTK Query
- **useMemo / useCallback 别滥用**：先有性能问题再优化。没有依赖的 memo 是负优化
- **key 用稳定的 ID**：别用 `index` 做 key。列表有增删操作时 index 必出 bug
- **自定义 Hook 抽逻辑**：`useDebounce`、`useAuth`、`usePagination`。视图和逻辑分离

## 状态管理
- **能不用就不用**：`useState` + props 能解决的别上状态库
- **服务端状态：React Query**：缓存、去重、乐观更新、后台刷新全搞定。90% 的"状态"其实是服务端数据
- **客户端状态：Zustand / Jotai**：需要全局共享的客户端状态。选一个别混用
- **Context 不是状态管理**：高频更新的值别放 Context，会导致大范围重渲染
- **Redux 谨慎用**：样板代码太多。老项目维护可以，新项目有其他更好的选择

## CSS / 样式
- **Tailwind CSS**：团队协作首选。生成的 CSS 小，风格统一，新人上手快
- **CSS Modules**：需要隔离的组件用。比 CSS-in-JS 省运行时
- **别用行内样式**：`style={{color: 'red'}}` 无法被 CSS 覆盖，主题切换也麻烦
- **CSS 变量做主题**：`var(--primary)` 支持深浅色切换，比 JS 方案简单
- **响应式 mobile-first**：`@media (min-width: 768px)` 别用 `max-width`

## 性能
- **bundle 要分析**：`vite-bundle-visualizer` / `@next/bundle-analyzer`。大依赖一眼看到
- **路由懒加载**：`React.lazy()` + `Suspense`。首页只加载用到的代码
- **图片优化**：WebP/AVIF 格式，responsive sizes，loading="lazy"
- **防抖/节流**：搜索输入防抖 300ms，滚动事件节流 100ms
- **虚拟滚动**：长列表必用。react-window / @tanstack/virtual
- **别过早优化**：先让功能跑通，React DevTools Profiler 找瓶颈

## 工程化
- **Vite > Webpack**：开发体验好太多。新项目默认 Vite
- **ESLint + Prettier**：代码风格统一。别让格式化问题进 code review
- **pre-commit hook**：lint-staged + husky。在提交前拦住低级错误
- **环境变量规范**：`VITE_` 前缀（Vite）暴露给前端。别把后端密钥放里面
- **monorepo 用 yarn workspaces / turborepo**：多项目共享代码和配置，包管理与单项目保持一致用 yarn；接手已有 pnpm/npm 体系的仓库则沿用现状，别为了换工具而换
- **Go embed 部署模式**：搭配 Go 后端时，React 编译产物通过 Go `embed.FS` 打进单文件，`scp` 拷走即部署。详见 [go.md#web-服务部署go--react-embed](go.md)

## 安全
- **XSS 防御**：React 默认转义 JSX 输出。`dangerouslySetInnerHTML` 必须 sanitize（DOMPurify）
- **API 请求验证**：前端校验是 UX，后端校验才是安全。前端校验只能当糖衣
- **token 存储**：access token 放内存，refresh token 放 httpOnly cookie。别放 localStorage
- **CSP Header**：Content-Security-Policy 配置好，防 XSS 的最后一道防线

## 测试
- **Vitest > Jest**：和 Vite 生态无缝，快得多
- **组件测试用 Testing Library**：测用户行为，别测实现细节
- **E2E 用 Playwright**：比 Cypress 快，多浏览器支持好
- **别追求 100% 覆盖率**：关键用户流程的 E2E + 核心组件测试就够了

## 常用库
| 需求 | 推荐 |
|------|------|
| 框架 | React / Next.js |
| 构建 | Vite |
| 状态（服务端） | TanStack Query (React Query) |
| 状态（客户端） | Zustand / Jotai |
| 样式 | Tailwind CSS |
| 组件库 | shadcn/ui / Ant Design |
| 表单 | react-hook-form + zod |
| 请求 | ky / ofetch (轻) / axios (重) |
| 测试 | Vitest + Testing Library |
| E2E | Playwright |
| 图表 | ECharts / Recharts |
