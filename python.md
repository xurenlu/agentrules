# Python 最佳实践

## 硬约束

> 本节是 AI 必守清单，违反即错误；下文各节是背景、示例和细节，按需阅读。

- **MUST**：一个项目一个虚拟环境（pyenv + virtualenv / poetry），不动系统 Python
- **MUST**：依赖锁版本（`requests==2.31.0`，不是 `>=2`）
- **MUST**：函数签名和公共 API 写类型注解
- **MUST**：状态、类型、选项用 Enum，不用裸字符串到处传
- **MUST**：数据库迁移用 Alembic / Django migrations，生成的脚本人工 review
- **MUST**：单元测试用 pytest；外部 HTTP 依赖用 mock，不真打外部 API
- **MUST NOT**：裸 `except:` 或 `except Exception` 不 log 就吞掉
- **MUST NOT**：async 函数里调用阻塞的同步 IO（如 `time.sleep()`、同步 DB 驱动）
- **MUST NOT**：异常只 print；用 `logger.exception()` 保留 traceback

## 环境管理
- **pyenv + virtualenv / poetry**：系统 Python 别动。一个项目一个环境
- **requirements.txt 要锁版本**：`requests==2.31.0` 而不是 `requests>=2`
- **pyproject.toml > setup.py**：新项目用前者，配置、依赖、工具设置全在一起
- **.python-version**：pyenv 自动切换版本，进目录不用手动 `pyenv activate`

## 代码风格
- **Black + isort + ruff**：格式化交给工具，别在 code review 里讨论格式
- **类型注解要写**：def 签名 + 公共 API 至少要有。`def get_user(id: int) -> User | None:`
- **mypy 严格模式**：`--strict` 慢慢加。至少先 `--check-untyped-defs`
- **dataclass > namedtuple > dict**：结构化数据用 dataclass，别传 dict 满天飞
- **Enum 用对**：状态、类型、选项全用 Enum。别用字符串 `"pending"` 到处飞

## 项目结构
```
project/
├── src/package_name/    # 源代码
│   ├── __init__.py
│   ├── models.py        # 数据模型
│   ├── services.py      # 业务逻辑
│   └── cli.py           # 命令行入口
├── tests/
│   ├── conftest.py      # 共享 fixture
│   └── test_services.py
├── pyproject.toml
└── Dockerfile
```
- **src layout**：避免 `import package_name` 和本地目录冲突
- **__init__.py 只做 re-export**：`from .models import User` 方便外部用

## 依赖
- **别滥用依赖**：能标准库解决的不装第三方。`pathlib`、`dataclasses`、`functools` 都很能打
- **直接依赖和传递依赖分开**：`pyproject.toml` 只列你直接 import 的
- **定期更新**：`pip list --outdated` / poetry show --outdated
- **安全审计**：`pip-audit` / `safety check` 扫漏洞

## 异步
- **async/await 不是银弹**：CPU 密集型用多进程，IO 密集型才用异步
- **FastAPI 标配 async**：handler 和 DB 调用都用 async，别混用同步阻塞
- **asyncio.gather > 循环 await**：多个独立 IO 操作并发执行
- **anyio / trio**：比原生 asyncio 更好用的结构化并发。FastAPI 生态还是 asyncio 为主
- **注意 sync-in-async 陷阱**：async 函数里调 time.sleep() 会阻塞整个 event loop

## 错误处理
- **别用裸 except**：`except Exception` 至少限定范围。`except BaseException` 更糟
- **自定义异常层次**：`AppError → ValidationError, NotFoundError, AuthError`
- **traceback 要 log 不要 print**：`logger.exception("msg")` 自动附带 stack trace
- **重试用 tenacity**：`@retry(stop=stop_after_attempt(3), wait=wait_exponential())`

## 数据库
- **SQLAlchemy 2.0 style**：用 `select(User).where(...)` 别用 `User.query`
- **session 管理**：请求进来创建，请求结束关闭。FastAPI 依赖注入天然适合
- **alembic 迁移**：每个版本手动 review 生成的迁移脚本
- **连接池**：SQLAlchemy `pool_size` + `max_overflow` 合理配置。FastAPI 别用默认的 5

## 测试
- **pytest + fixture > unittest**：pytest 是事实标准
- **conftest.py 是共享 fixture 的家**：DB session、test client、mock 数据都放这
- **mock 外部依赖**：HTTP 调用用 responses / httpretty，别真去打外部 API
- **数据库测试用 factory_boy + pytest-postgresql**：每个测试独立数据
- **parametrize 多用**：同样的测试逻辑不同输入输出一目了然

## 性能
- **列表推导 > map/filter**：可读性好，性能不差。有副作用的循环用 for
- **生成器省内存**：大文件读 `for line in file` 别 `file.readlines()`
- **functools.lru_cache**：纯函数计算结果缓存，简单好用
- **profile 用 py-spy**：不需要改代码，直接 attach 看火焰图
- **gunicorn + uvicorn workers**：FastAPI 生产部署标配，worker 数 = CPU 核数 × 2 + 1

## 常用库
| 需求 | 推荐 |
|------|------|
| Web 框架 | FastAPI (API) / Django (全栈) |
| 数据库 ORM | SQLAlchemy 2.0 |
| 迁移 | Alembic |
| 数据验证 | Pydantic v2 |
| HTTP 客户端 | httpx |
| 任务队列 | Celery / arq |
| 测试 | pytest + pytest-asyncio |
| 格式化 | black + isort + ruff |
| 日志 | loguru / structlog |
| 配置 | pydantic-settings |
