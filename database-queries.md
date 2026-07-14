# 数据库查询最佳实践

## 硬约束

> 本节是 AI 必守清单，违反即错误；下文各节是背景、示例和细节，按需阅读。

- **MUST**：一律参数化查询；动态表名/列名无法参数化时用白名单校验
- **MUST**：WHERE / JOIN / ORDER BY 的高频列有索引，并用 EXPLAIN 验证索引实际被使用
- **MUST**：深分页用游标（`WHERE id > last_id`），不用大 offset
- **MUST**：ORM 关联查询避免 N+1（eager loading / JOIN FETCH / preload）
- **MUST**：批量写入用批量语句，不循环单条
- **MUST NOT**：`SELECT *`；明确列出需要的列
- **MUST NOT**：把 `password_hash` 等敏感列查出传给前端，哪怕前端不用
- **MUST NOT**：长事务；一个事务控制在秒级

## SQL 编写规范
- **关键字大写，表名列名小写**：`SELECT id, name FROM users WHERE status = 1`
- **别用 SELECT ***：明确列出需要的列。减少传输，避免列增减导致 bug
- **别名要清晰**：`u` 代表 `users`，`o` 代表 `orders`。别 `a, b, c, d`
- **JOIN 优先于子查询**：大多数情况下 JOIN 比嵌套子查询性能好（但要看执行计划）
- **WHERE 条件顺序**：把过滤性最强的条件放前面，但不绝对——看索引

## 索引
- **高频查询必须有索引**：WHERE / JOIN / ORDER BY 涉及的列
- **联合索引最左前缀**：(a, b, c) 索引能覆盖查 a、a+b、a+b+c，但覆盖不了只查 b
- **避免索引失效**：
  - `WHERE func(col) = x` → 函数包裹索引列
  - `WHERE col LIKE '%xxx'` → 前导模糊
  - `WHERE col != x` 或 `NOT IN` → 否定条件
  - 隐式类型转换：`WHERE phone = 13800138000` 当 phone 是 varchar
- **覆盖索引**：查询的列都在索引里，避免回表。`EXPLAIN` 里 `Extra: Using index`
- **别瞎建索引**：每个索引都有写入成本。用 `EXPLAIN` 验证索引是否被用到
- **定期分析**：`ANALYZE TABLE` 更新统计信息，让优化器做正确选择

## 查询优化
- **分页用游标不用 offset**：`WHERE id > last_id ORDER BY id LIMIT 20` 比 `LIMIT 100000, 20` 快无数倍
- **COUNT(*) 大表慢**：考虑用近似值（`EXPLAIN` 的 rows 估算）或缓存计数
- **批量操作**：1000 条一条 INSERT 比 1000 次单条 INSERT 快几十倍
- **避免 N+1**：ORM 最经典陷阱。用 `eager loading` / `JOIN FETCH` / `preload`
- **大事务拆小**：长事务锁住资源导致连锁反应。一个事务控制在秒级
- **读写分离**：读走从库，写走主库。注意主从延迟，刚写完立刻读可能读不到

## EXPLAIN 解读
- **type 列**：从好到差：const > eq_ref > ref > range > index > ALL。出现 ALL 要警惕
- **rows 列**：扫描行数。越小越好
- **Extra 列**：
  - `Using index`：覆盖索引，最优
  - `Using where`：需要回表过滤
  - `Using temporary` / `Using filesort`：需要临时表/排序，能避免就避免
- **key 列**：看实际用了哪个索引。NULL = 没走索引，需要优化

## ORM 使用
- **知道 ORM 在干什么**：开发环境开启 SQL 日志，看到实际生成的查询
- **批量操作用原生 SQL**：ORM 的批量 insert/update 通常不如手写
- **复杂查询用 Query Builder 或原生 SQL**：别用 ORM 拼复杂的多表关联
- **连接池配置**：
  - max_connections：看数据库能承受多少。别设置 200 然后数据库只支持 100
  - idle_timeout：空闲连接及时回收
  - connection_lifetime：定期重建，避免长时间连接的各种坑

## 安全（再强调）
- **参数化查询永远第一位**：`WHERE id = ?` 不拼字符串
- **动态表名/列名无法参数化**：必须白名单校验。别接受用户传的 ORDER BY 字段名
- **最小数据暴露**：别把 password_hash 查出来传前端，哪怕前端不用
