# Reticle 本地部署与运行说明（前端 + 后端）

> 验证日期：2026-10-28　　验证范围：FastAPI 后端 + Vue 3 前端 + PostgreSQL 持久化 + 一次完整合约审计链路
> 结论：**系统已在本机跑通**，前端页面、后端 API、数据库、审计流水线均可用；深度学习模型与 LLM 在外部条件不足时自动降级（见第 5 节）。

---

## 1. 运行状态（已验证）

| 组件 | 地址 | 说明 |
|---|---|---|
| 前端（Vue 3 + Vite + Tailwind） | http://127.0.0.1:5173 | 登录页、仪表盘、审计详情、报告页均正常渲染 |
| 后端（FastAPI + Uvicorn） | http://127.0.0.1:8000 | `/docs` 可交互调试，`/api/v1/health` 返回 `status=ok` |
| 数据库（PostgreSQL 17） | `localhost:5432/reticle` | 与 `.env` 中 `SCG_DATABASE_URL` 一致，7 张表自动创建 |
| 演示账号 | `demo_auditor` / `demo-pass-123` | 通过 `/api/v1/auth/register` 创建，可用于前端登录 |

服务进程：

- `postgres.exe`（`.conda\envs\pg`），数据目录 `pgdata/`
- `.conda\envs\backend\python.exe -m uvicorn backend.api.app:app --host 127.0.0.1 --port 8000`
- `frontend` 目录下 `npm run dev`（Vite 8）

---

## 2. 一键启停

```powershell
# 启动（已在运行的服务会自动跳过）
powershell -ExecutionPolicy Bypass -File .\start-all.ps1

# 停止
powershell -ExecutionPolicy Bypass -File .\stop-all.ps1
```

脚本会依次启动 PostgreSQL → 后端 → 前端，并等待端口/健康检查通过后打印访问地址。

> 脚本内控制台输出为英文：Windows PowerShell 5.1 会按 ANSI 读取无 BOM 的 `.ps1`，中文会导致解析错误。

---

## 3. 从零部署步骤

### 3.1 Node 依赖

```powershell
npm install                                 # 根目录：solc 0.4/0.8 多版本编译器
cd frontend
npm ci                                      # 前端：Vue/Router/Pinia/ECharts/Monaco/Tailwind
```

> 若 npm 缓存目录不可写，先设置：`$env:npm_config_cache = "<项目>\.npm-cache"`
> `frontend/node_modules` 若安装不完整（例如缺 `@jridgewell/remapping/dist`），删除后重新 `npm ci` 即可。

### 3.2 Python 环境（后端）

若 PyPI 访问受限，可用 conda-forge 提供依赖：

```powershell
$env:CONDA_ENVS_PATH = "<项目>\.conda\envs"
$env:CONDA_PKGS_DIRS = "<项目>\.conda\pkgs"

conda create -p .conda\envs\backend -c conda-forge "python=3.12" fastapi uvicorn `
    python-multipart numpy psycopg python-dotenv scikit-learn -y
conda install -p .conda\envs\backend -c conda-forge libpq -y   # psycopg 需要 libpq
```

运行后端时必须让 `libpq.dll` 在 `PATH` 中（`start-all.ps1` 已处理）：

```powershell
$env:PATH = "<项目>\.conda\envs\backend\Library\bin;<项目>\.conda\envs\backend;<项目>\.conda\envs\backend\Scripts;" + $env:PATH
.conda\envs\backend\python.exe -m uvicorn backend.api.app:app --host 127.0.0.1 --port 8000
```

### 3.3 PostgreSQL（便携版，无需管理员权限）

```powershell
conda create -p .conda\envs\pg -c conda-forge "postgresql=17" -y

$pgbin = ".conda\envs\pg\Library\bin"
# 密码从 .env 的 SCG_DATABASE_URL 中解析，写入临时 pwfile
& "$pgbin\initdb.exe" -D pgdata -U postgres --pwfile=<临时密码文件> -E UTF8 --locale=C `
    --auth-host=scram-sha-256 --auth-local=trust
& "$pgbin\pg_ctl.exe" -D pgdata -l .runtime\pg.log -o "-p 5432" -w start
& "$pgbin\createdb.exe" -h 127.0.0.1 -p 5432 -U postgres reticle
```

> `--locale=C` 是必须的：默认区域 `Chinese (Simplified)_China.936` 在 Windows 版 initdb 中没有可用的文本检索配置。
> 表结构由后端启动时的 `init_schema()` 自动创建（`scg_users`、`scg_sessions`、`scg_contracts`、`scg_audit_tasks`、`scg_audit_events`、`scg_audit_reports`、`scg_audit_artifacts`）。

### 3.4 前端

```powershell
cd frontend
npm run dev        # http://127.0.0.1:5173，/api 已由 vite.config.ts 代理到 :8000
```

---

## 4. 验证记录

| 验证项 | 结果 |
|---|---|
| 后端健康检查 | `{"status":"ok","database":{"configured":true,"ready":true}}` |
| 用户注册/登录 | 成功，Token（Bearer）可用，任务按用户隔离 |
| 前端登录页 | 正常渲染（`docs/screenshots/login.png`） |
| 前端仪表盘 | 正常：任务统计、最近任务、检测流程、能力卡片（`docs/screenshots/dashboard.png`） |
| 审计详情 | 正常：合约异常结果、函数风险排名 TOP10 |
| 端到端审计 | FibonacciBalance.sol：2 合约 / 5 函数 / 6 findings / 1 warning / 14 条证据，约 40 秒完成 |
| 数据持久化 | 服务重启后任务仍在，报告 JSON/Markdown 落盘于 `backend_outputs/api_tasks/<task_id>/` |
| 无 TensorFlow 降级 | LSTM/DeepSVDD 适配器自动走 `static_fallback_h5_unavailable`，流水线不中断 |
| LLM 不可用降级 | 调用失败时 findings 标记为 `inconclusive` 并记录原因，不中断流程 |

审计产物示例：`backend_outputs/api_tasks/<task_id>/`
（`<task>.json`、`<task>.md`、`audit.log`、`status.json`）

---

## 5. 已知限制与补齐方式

| 限制 | 现象 | 补齐方式 |
|---|---|---|
| TensorFlow 未安装 | `.h5` 模型不可推理，LSTM/DeepSVDD 用静态特征回退 | `.conda\envs\backend\python.exe -m pip install tensorflow==2.20.0`，或 `pip install -r requirements-backend.txt` |
| LLM 余额不足/未配置 | 推理/验证请求返回错误，结论为 `inconclusive` | 配置 `.env` 中 `SCG_LLM_API_KEY`，或切换 `SCG_LLM_BASE_URL/MODEL` |
| Slither 未安装 | `need_verification=true` 时无法做静态验证 | `pip install slither-analyzer`（需 solc 选择器/网络） |
| PyTorch 未安装 | GCN 跨合约子进程模式（`cross_contract_scan`）不可用 | `conda install -p .conda\envs\backend -c pytorch pytorch` |
| PyPI 访问受限 | `pip install` 超时/连接重置 | 使用代理或可达镜像，或改用 conda-forge |

> 以上限制均**不影响**系统主流程：无模型/无 LLM 时会自动降级为静态规则 + RAG 知识库并照常出报告。

---

## 6. 常用接口

| 方法 | 路径 | 说明 |
|---|---|---|
| POST | `/api/v1/auth/register` | 注册（用户名 ≥3，密码 ≥8） |
| POST | `/api/v1/auth/login` | 登录，返回 Bearer Token |
| POST | `/api/v1/audits/upload` | 上传 `.sol`/`.zip` 创建审计（multipart，`mode=full_audit`） |
| GET | `/api/v1/audits` | 任务列表（带 Token 时返回当前用户任务） |
| GET | `/api/v1/audits/{id}` | 状态/进度/阶段 |
| GET | `/api/v1/audits/{id}/report` | JSON 报告 |
| GET | `/api/v1/audits/{id}/agents` | 多智能体运行详情（供“智能体运行”页） |
| GET | `/api/v1/health` / `/api/v1/llm/status` | 健康检查 / LLM 配置状态 |

---

## 7. 目录速查

```
reticle/
├─ backend/                  # FastAPI 应用与审计流水线
├─ frontend/                 # Vue 3 + Vite 前端
├─ pgdata/                   # 本地 PostgreSQL 数据目录
├─ .conda/envs/pg            # PostgreSQL 17 便携环境
├─ .conda/envs/backend       # 后端 Python 3.12 环境
├─ .runtime/                 # 启动脚本日志
├─ docs/screenshots/         # 界面截图
├─ backend_outputs/          # 审计产物 / 上传文件
├─ start-all.ps1 / stop-all.ps1
└─ .env                      # 数据库与 LLM 配置（不要外传）
```
