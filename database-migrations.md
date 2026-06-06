# 数据库迁移最佳实践

## 迁移文件管理
- **版本化**：每个迁移文件有唯一递增版本号（时间戳或序号），不可修改已提交的迁移
- **up + down 成对**：每个迁移必须能回滚。`up` 创建的表，`down` 必须删掉。别留烂摊子
- **幂等性**：迁移可以安全重复执行。用 `IF NOT EXISTS` / `IF EXISTS`
- **禁止手改数据库**：所有 DDL 变更走迁移文件。别在 prod 上临时 `ALTER TABLE` 然后忘了

## 迁移内容规范
- **一个迁移做一件事**：别把"加字段 + 建索引 + 改表名"混一起
- **数据迁移和结构迁移分开**：先改表结构，确认无误后再跑数据迁移
- **大表变更要小心**：
  - `ALTER TABLE ... ADD COLUMN` 对千万级表 + 默认值可能锁表（MySQL 8.0+ instant DDL 好很多）
  - 大表加索引用 `ALGORITHM=INPLACE, LOCK=NONE`（MySQL）/ `CONCURRENTLY`（PostgreSQL）
  - 实在不行用 pt-online-schema-change 或 gh-ost
- **外键约束**：开发环境要，prod 看情况。高并发场景外键是性能杀手，用应用层保证一致性

## 建表规范

### 必须有的列
每张业务表必须包含：
```sql
created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
```
- **created_at**：记录创建时间，写入后不再修改
- **updated_at**：记录最后修改时间，每次 UPDATE 自动更新
- PostgreSQL 用 `TIMESTAMPTZ`，MySQL 用 `TIMESTAMP` 或 `DATETIME(3)`（毫秒精度）
- 别用 `datetime` 字符串，别靠应用层传时间

### 索引规范
- **主键必须有**：每张表一个自增 `BIGINT` 或 UUID 主键。别用业务字段当主键
- **外键建索引**：所有外键列必须建索引，不然 JOIN 和级联操作全表扫描
- **高频 WHERE 列建索引**：看查询最多的 5 条 SQL，WHERE 条件里的列都得有索引
- **联合索引按区分度排**：区分度高的列放最左。`status`（3 种值）和 `user_id`（百万种），`user_id` 放前面
- **唯一约束 = 唯一索引**：业务上不重复的字段直接建唯一索引，别靠应用层检查
- **软删除要带索引**：有 `deleted_at` 的表，查询索引要包含 `deleted_at IS NULL` 条件，或者联合索引把 deleted_at 放前面
- **别每个列都建索引**：写入慢、占磁盘。用 EXPLAIN 验证索引被实际用到再建
- **命名规范**：
  - 普通索引：`idx_<表名>_<列名>`，如 `idx_users_email`
  - 唯一索引：`uk_<表名>_<列名>`，如 `uk_users_phone`
  - 联合索引：`idx_<表名>_<col1>_<col2>`，如 `idx_orders_user_status`

### 建表示例
```sql
CREATE TABLE orders (
    id         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id    BIGINT UNSIGNED NOT NULL,
    order_no   VARCHAR(32)     NOT NULL,
    status     TINYINT         NOT NULL DEFAULT 0,
    amount     DECIMAL(10,2)   NOT NULL,
    created_at TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_orders_order_no (order_no),
    INDEX      idx_orders_user_id (user_id),
    INDEX      idx_orders_status_created (status, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

## 执行前检查
- **先跑 dry-run**：不管什么工具，先看生成的 SQL 长什么样
- **检查锁表风险**：`SHOW ENGINE INNODB STATUS` 了解当前锁情况
- **备份**：prod 迁移前至少确认最近一次备份可用。大变更备份当前表
- **错峰执行**：别在高峰期跑大表迁移
- **评估时间**：迁移脚本加上预估耗时注释。`-- estimated: ~30s on 5M rows`

## 启动与命令行
- **启动自动 up**：数据相关 migration 一般作为服务启动流程的一部分自动执行一次 `migration up`，让应用版本和数据库结构同步，别靠人肉登录服务器敲命令续命
- **失败即停止启动**：启动迁移失败时，服务不得继续提供流量；日志必须包含迁移版本、文件名、数据库连接目标（脱敏后）和错误上下文
- **提供 CLI 子命令**：服务或运维工具应提供 `migrate up`、`migrate down`、`migrate status` 等命令，至少支持按步数回滚，如 `migrate down --steps 1`
- **自动 up 要可观测**：每次启动迁移完成后记录执行结果、耗时、迁移前版本和迁移后版本，方便部署后复盘

## 回滚预案
- **down 脚本要测试过**：别只写了 up，down 从来没跑过
- **回滚不丢数据**：如果 down 要删字段，先备份该字段数据
- **灰度回滚**：出问题先停流量再回滚，别反过来
- **回滚说明要随部署输出**：每次部署后必须反馈本次可回滚到哪个应用版本、旧二进制备份路径、是否需要执行 `migrate down`、对应命令和风险提示

## 工具选择
- **Go 项目**：golang-migrate、goose
- **Python 项目**：Alembic（SQLAlchemy 生态）、Django migrations
- **Node 项目**：knex migrations、Prisma migrate、TypeORM migrations
- **通用**：Flyway（Java 生态但任何语言都能用）
- **K8s 里**：用 init container 或 Job 跑迁移，别嵌在应用启动逻辑里

## CI/CD 集成
- **迁移是部署的一部分**：一般由新版本服务启动时自动执行 `migration up`；特殊场景也可以在部署流水线中先跑迁移再切流量，但必须遵守 forward compatible 原则
- **自动化检查**：CI 里校验迁移文件格式、检查 down 脚本存在、dry-run 验证
- **高风险 prod 迁移要审批**：大表 DDL、不可逆数据变更、删字段/删表等高风险迁移必须人工审批；普通幂等迁移可以随服务启动自动 up
- **迁移状态上报**：跑完通知到 Slack/钉钉，附上耗时和版本号

## 特殊场景
- **多实例部署**：用分布式锁确保只有一个实例跑迁移（或依赖迁移工具自带的锁机制）
- **蓝绿部署**：迁移必须同时兼容新旧两个版本（新增列有默认值，删除列先标记 deprecated）
- **分库分表**：迁移脚本要考虑所有分片，逐个执行并验证
- **NoSQL（MongoDB 等）**：虽然 schema-less 但也需要迁移脚本管理索引、validator、数据清洗
