# 前端最佳实践

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
- **monorepo 用 pnpm workspace / turborepo**：多项目共享代码和配置
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
