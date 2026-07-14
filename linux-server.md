# Linux 服务器管理最佳实践

## 硬约束

> 本节是 AI 必守清单，违反即错误；下文各节是背景、示例和细节，按需阅读。

- **MUST**：SSH 禁用 root 登录和密码认证，只留密钥；防火墙最小开放
- **MUST**：监控 CPU、内存、磁盘（空间和 inode 都要），超过 80% 告警
- **MUST**：备份自动化，且定期做恢复演练——没验证过的备份等于没有
- **MUST**：所有应用日志配 logrotate 轮转
- **MUST**：应急时先保留现场（top、free、df、dmesg、应用日志）再操作；回滚优先于修复
- **MUST**：运维脚本幂等，执行 10 次和 1 次结果一样
- **MUST**：容器设置 `--memory` / `--cpus` 资源限制
- **MUST NOT**：Docker 镜像用 `latest` 标签，版本 pin 死
- **MUST NOT**：共用登录账号；一人一号，操作可追溯
- **MUST NOT**：不理解含义的内核参数乱调

## 安全基线
- **禁用 root SSH 登录**：`PermitRootLogin no`，用普通用户 + sudo
- **SSH 密钥认证，禁止密码登录**：`PasswordAuthentication no`
- **改默认 SSH 端口**：不是安全措施但有实际效果——减少 99% 的扫描噪音
- **防火墙最小开放**：`ufw` / `firewalld`。只开 80/443 和你改过的 SSH 端口
- **fail2ban**：防暴力破解。SSH、nginx 异常请求都配上
- **定期更新**：`unattended-upgrades`（Ubuntu）/ `yum-cron`（CentOS）自动安全更新
- **SELinux / AppArmor**：别关。学习成本有，但真出事时能救命

## 用户与权限
- **一人一个账号**：别共用。出问题能追溯到人
- **sudo 要日志**：`Defaults logfile=/var/log/sudo.log`
- **最小权限**：开发不要 prod 权限。DBA 不要 root
- **定期审计**：`last` 检查登录记录，`cat /etc/passwd` 清理离职人员账号

## 监控
- **三大件必须有**：CPU、内存、磁盘。任一超过 80% 告警
- **磁盘是定时炸弹**：inode 用完和空间用完一样致命。`df -h` 和 `df -i` 都要监控
- **服务存活**：进程在 ≠ 服务正常。要健康检查 endpoint
- **日志集中**：别登服务器看日志。上 ELK / Loki / 阿里云 SLS
- **监控工具**：
  - 小规模：Netdata（开箱即用，界面好看）
  - 中等规模：Prometheus + Grafana + Node Exporter
  - 大规模/多云：Datadog / 阿里云云监控
- **告警要分级**：P0 立刻打电话，P1 发消息，P2 邮件。别所有告警同等对待

## 备份
- **3-2-1 原则**：3 份数据，2 种介质，1 份异地
- **自动化备份**：cron + 脚本。别靠人记
- **备份要验证**：定期恢复演练。没验证过的备份等于没有
- **数据库备份**：
  - MySQL：`mysqldump --single-transaction`（InnoDB）或 xtrabackup（大库）
  - PostgreSQL：`pg_dump` + WAL 归档
  - MongoDB：`mongodump` 或 filesystem snapshot
- **保留策略**：日备保留 7 天，周备保留 4 周，月备保留 12 月

## 日志管理
- **logrotate**：所有应用日志配轮转。别让一个日志文件长到 50G
- **journald 限制大小**：`SystemMaxUse=500M`。默认可能吃满 /var/log
- **应用日志输出到 stdout/stderr**：让 systemd/journald 或容器运行时管理，别自己写文件
- **旧日志自动清理**：`find /var/log -name "*.gz" -mtime +30 -delete`

## 性能调优
- **swap 不是洪水猛兽**：`vm.swappiness=1` 而非 0。完全关闭 swap OOM 时会直接杀进程
- **文件描述符限制**：`ulimit -n 65535`。高并发服务（nginx/数据库）必须改
- **内核参数**：`/etc/sysctl.conf` 常用调优：
  - `net.core.somaxconn = 1024`：TCP 连接队列
  - `net.ipv4.tcp_tw_reuse = 1`：TIME_WAIT 复用
  - `fs.inotify.max_user_watches = 524288`：文件监控（前端构建工具需要）
- **别瞎调内核**：不理解含义的参数别动。默认值大多数情况下够用

## 自动化
- **Ansible > 手敲命令**：服务器超过 2 台就上配置管理
- **基础设施即代码**：Terraform / Pulumi 管云资源，Ansible 管服务器配置
- **CI/CD 部署**：别手动 scp + restart。Git push → CI build → 自动部署
- **新版本安装前备份旧二进制**：替换应用二进制前，先把当前文件复制到带版本号/时间戳的备份目录，确保可以快速切回
- **部署结果要带回滚说明**：每次部署完成后，必须反馈旧二进制备份路径、恢复命令、重启命令、健康检查结果，以及是否需要执行数据库 `migrate down`
- **Cron 任务要监控**：dead man's switch。关键 cron 任务挂了要告警
- **脚本必须幂等**：`ansible-playbook` 或运维脚本执行 10 次和执行 1 次结果一样

## Docker（如果用到）
- **别用 latest 标签**：版本 pin 死。`nginx:1.25` 而不是 `nginx:latest`
- **一个容器一个进程**：别在容器里跑 supervisord 管多个服务
- **日志输出 stdout**：别写容器内文件，让 docker log driver 处理
- **资源限制**：`--memory` 和 `--cpus` 必须设。一个容器 OOM 不该影响宿主机
- **定期清理**：`docker system prune -f`（cron 定时跑），旧镜像吃磁盘很快

## 应急响应
- **重启不是第一反应**：先保留现场：`top`、`free -m`、`df -h`、`dmesg | tail`、应用日志
- **回滚优先于修复**：出问题先回滚到上一个稳定版本，再慢慢排查
- **先恢复二进制再动数据库**：应用回滚优先切回部署前备份的二进制；只有新迁移导致旧版本无法运行时，才按预案执行 `migrate down`
- **变更记录**：出问题后检查最近的部署、配置变更、数据库迁移。90% 的故障是变更引起的
- **复盘**：事故后写 Post-mortem。不追责，追根因和改进措施

## 快速排查工具箱
```bash
# 系统负载
top -bn1 | head -20           # CPU/内存 top 进程
free -h                       # 内存使用
df -h && df -i                # 磁盘空间 + inode
iostat -x 1                   # 磁盘 IO

# 网络
ss -tunlp                     # 所有监听端口
netstat -s | grep -i retrans  # TCP 重传统计
iftop -i eth0                 # 实时流量

# 进程
ps aux --sort=-%mem | head 10 # 内存大户
lsof -p <pid>                 # 进程打开的文件
strace -p <pid> -c            # 进程系统调用统计

# 日志
journalctl -u <service> --since "10 min ago"
tail -f /var/log/syslog | grep -i error
```
