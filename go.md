# Go 最佳实践

## 项目结构
- **标准布局**：`cmd/` 入口、`internal/` 私有包、`pkg/` 可暴露库、`api/` proto/swagger
- **别过度设计目录**：小项目平铺也行。`handler.go` + `service.go` + `repo.go` 三个文件能搞定的别拆 15 个目录
- **一个 package 一个职责**：别把 HTTP handler 和数据库操作塞同一个 package
- **main 要瘦**：`main.go` 只做依赖注入和启动，逻辑全在 `internal/` 里

## 命名
- **包名小写单数**：`user` 不是 `users`，`handler` 不是 `handlers`
- **接口名 -er 后缀**：`Reader`、`Writer`、`UserRepository`。单方法接口优先
- **Getter 别用 Get 前缀**：`user.Name()` 不是 `user.GetName()`
- **缩写都大写或都小写**：`HTTPServer` 或 `httpServer`，别 `HttpServer`
- **避免 stuttering**：`user.UserService` → 直接 `user.Service`；`config.ConfigPath` → `config.Path`

## 错误处理
- **error 永远最后**：`func Do(a int) (Result, error)` 不是 `(error, Result)`
- **wrap error 保留上下文**：`fmt.Errorf("failed to fetch user %d: %w", id, err)`
- **errors.Is / errors.As**：判断错误类型用标准库，别 `err.Error() == "xxx"`
- **sentinel error 要小写**：`var ErrNotFound = errors.New("user not found")`
- **别 panic 做流程控制**：panic 只给不可恢复的错误（配置缺失、启动失败）
- **defer 里的 error 别忽略**：`defer f.Close()` 改成具名返回值处理

## 并发
- **goroutine 生命周期要可控**：用 context 取消，用 WaitGroup 等待，别泄漏
- **channel 原则**：谁写谁 close；读端永远别 close channel
- **select + ctx.Done()**：所有阻塞操作都要可取消
- **sync.Mutex 保护的数据别暴露指针**：外部拿到了就能绕过锁
- **别过早用并发**：先写串行，profile 确认是瓶颈了再并发。goroutine 不是免费的
- **errgroup**：多个 goroutine 并发执行，一个出错全部取消

## 依赖注入
- **构造函数的参数就是依赖**：`func NewService(db *sql.DB, cache Cache) *Service`
- **别用反射 DI 框架**：wire（Google）可以，编译期生成代码。运行时反射的太魔法
- **接口定义在使用方**：`internal/service/` 里定义 `type UserRepo interface {}`，而不是 `internal/repo/` 里定义然后被 import

## 测试
- **表驱动测试**：Go 的标配。`func TestXxx(t *testing.T) { tests := []struct{name, input, want}{} }`
- **testify 谨慎用**：assert/require 方便但过度使用会掩盖信息。简单判断自己写 if
- **mock 用接口实现**：别用 monkey patch 全局函数。测试要能并行跑
- **integration test 用 build tag**：`//go:build integration` 分隔单测和集成测试
- **_test.go 可以和 package 同名**：测内部逻辑用 `package x`，测导出行为用 `package x_test`

## 性能
- **slice 预分配容量**：`make([]int, 0, expectedSize)` 避免多次扩容
- **strings.Builder > + > fmt.Sprintf**：循环里拼字符串用 Builder
- **sync.Pool**：高频创建销毁的对象用池化
- **pprof 是你的朋友**：`import _ "net/http/pprof"` 开起来，出问题第一时间看 profile
- **别过早优化内存**：先写对，再看 heap profile。GC 的压力比你想象的小

## Web 服务部署（Go + React embed）

**核心原则：React 编译产物用 Go 1.16+ embed 打包进二进制，单文件部署。**

### 项目结构
```
project/
├── cmd/server/main.go       # 入口
├── internal/
│   ├── api/                 # API handler
│   ├── migrate/             # 数据库迁移封装
│   └── web/                 # embed + spa handler
├── web/                     # React 源码（Vite 项目）
│   ├── src/
│   ├── package.json
│   └── vite.config.ts
├── Makefile
└── go.mod
```

### Go 侧 embed 实现
```go
package web

import "embed"

//go:embed dist/*
var Assets embed.FS

// SPA 回退到 index.html
func Handler() http.Handler {
    sub, _ := fs.Sub(Assets, "dist")
    return spaHandler{fs: http.FS(sub)}
}
```

### Makefile 一键构建
```makefile
build:
	cd web && npm run build
	go build -o bin/server ./cmd/server
```

### 迁移与启动
- **启动自动 up 一次**：数据相关 migration 一般在服务启动时自动执行一次 `migration up`；执行失败必须阻止服务继续启动，并输出当前版本、目标版本、失败 SQL/迁移文件等上下文
- **CLI 必须可手动操作**：服务二进制应提供迁移子命令，如 `server migrate up`、`server migrate down --steps 1`、`server migrate status`，方便部署、排障和回滚
- **down 谨慎执行**：`migration down` 只能在确认数据备份、回滚范围和兼容性后手动执行；涉及删字段/删表的 down 要先备份数据
- **多实例加锁**：多实例部署时，启动自动迁移必须使用数据库锁、迁移工具自带锁或分布式锁，确保同一时间只有一个实例执行 migration

### 部署
- `scp bin/server user@host:/opt/app/` 拷过去直接 `./server`
- 一个二进制包含前端+后端，无外部依赖
- 配合 systemd 或 supervisor 做进程守护
- **安装前备份旧二进制**：部署新版本前必须把当前运行的二进制备份到带版本号/时间戳的目录，例如 `/opt/app/releases/server-v1.2.3-20260606T120000`
- **发布后反馈回滚方法**：每次部署完成后，部署脚本或发布记录必须输出本次备份路径、恢复旧二进制命令、重启命令，以及是否需要执行 `migration down`
- **优先二进制回滚**：服务异常时优先恢复旧二进制并重启；只有数据库迁移确实不兼容旧版本时，才在备份确认后执行 `migration down`

### React 侧注意
- Vite base 配成 `/`（或 `/app/` 如果做路径前缀）
- API 请求用相对路径或反向代理，别硬编码 `localhost:3000`
- react-router 用 `BrowserRouter`，Go 侧 SPA handler 做 fallback

## 常用库
| 需求 | 推荐 |
|------|------|
| HTTP 框架 | chi / gin |
| 数据库 | sqlx / sqlc / ent |
| 迁移 | golang-migrate |
| 配置 | viper / envconfig |
| 日志 | zerolog / slog（1.21+） |
| 测试断言 | testify |
| Mock | mockery / gomock |
| 验证 | validator |
| CLI | cobra |
| 任务队列 | asynq / machinery |
