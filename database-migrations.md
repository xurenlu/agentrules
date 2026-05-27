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

## 执行前检查
- **先跑 dry-run**：不管什么工具，先看生成的 SQL 长什么样
- **检查锁表风险**：`SHOW ENGINE INNODB STATUS` 了解当前锁情况
- **备份**：prod 迁移前至少确认最近一次备份可用。大变更备份当前表
- **错峰执行**：别在高峰期跑大表迁移
- **评估时间**：迁移脚本加上预估耗时注释。`-- estimated: ~30s on 5M rows`

## 回滚预案
- **down 脚本要测试过**：别只写了 up，down 从来没跑过
- **回滚不丢数据**：如果 down 要删字段，先备份该字段数据
- **灰度回滚**：出问题先停流量再回滚，别反过来

## 工具选择
- **Go 项目**：golang-migrate、goose
- **Python 项目**：Alembic（SQLAlchemy 生态）、Django migrations
- **Node 项目**：knex migrations、Prisma migrate、TypeORM migrations
- **通用**：Flyway（Java 生态但任何语言都能用）
- **K8s 里**：用 init container 或 Job 跑迁移，别嵌在应用启动逻辑里

## CI/CD 集成
- **迁移是部署的一部分**：先跑迁移再部署新代码（forward compatible 原则）
- **自动化检查**：CI 里校验迁移文件格式、检查 down 脚本存在、dry-run 验证
- **禁止自动执行 prod 迁移**：prod 迁移必须人工审批。自动化的最多到 staging
- **迁移状态上报**：跑完通知到 Slack/钉钉，附上耗时和版本号

## 特殊场景
- **多实例部署**：用分布式锁确保只有一个实例跑迁移（或依赖迁移工具自带的锁机制）
- **蓝绿部署**：迁移必须同时兼容新旧两个版本（新增列有默认值，删除列先标记 deprecated）
- **分库分表**：迁移脚本要考虑所有分片，逐个执行并验证
- **NoSQL（MongoDB 等）**：虽然 schema-less 但也需要迁移脚本管理索引、validator、数据清洗
