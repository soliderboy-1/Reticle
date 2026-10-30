# 测试合约样本

从 `dataset/localization_eval/` 中挑选的 7 个代表性合约，可直接在前端「新建检测任务」上传（支持 `.sol` 与 `.zip`）。

| 文件 | 漏洞类型 | 说明 |
|---|---|---|
| `01_reentrancy_PERSONAL_BANK.sol` | 重入 | 经典 `call.value` 先转账后扣余额，含 `Collect` 重入点 |
| `02_access_control_FibonacciBalance.sol` | 访问控制 / 算术 | **含 2 个合约**，可同时演示跨合约调用图 |
| `03_arithmetic_integer_overflow.sol` | 整数溢出 | 无 SafeMath 的加减运算 |
| `04_unchecked_low_level_call.sol` | 未检查低层调用 | `call()` 返回值未校验 |
| `05_bad_randomness_guess.sol` | 弱随机数 | 用 `block.timestamp/blockhash` 做猜数 |
| `06_locked_ether.sol` | 锁死以太 | 可收款但无转出路径 |
| `07_timestamp.sol` | 时间戳依赖 | 逻辑依赖 `now` |

`all_samples.zip` 是上述 7 个文件的压缩包，用于验证 zip 上传路径。

## 怎么试

1. 打开 http://127.0.0.1:5173 并登录（`demo_auditor` / `demo-pass-123`）
2. 点击左侧「新建检测任务」或首页主按钮
3. 选择上面的 `.sol` 文件（或 `all_samples.zip`）
4. 检测模式建议先从 `full_audit`（全面审计）开始；想看跨合约图可用 `cross_contract_scan`
5. 提交后会自动跳转到审计详情页，任务完成可查看**函数风险排名 / 推理路径 / 报告**

## 实测结果（2026-10-28）

| 样本 | 状态 | 发现 | 预警 |
|---|---|---|---|
| `03_arithmetic_integer_overflow.sol` | 成功 | 1 | 0 |
| `05_bad_randomness_guess.sol` | 成功 | 5 | 0 |
| `04_unchecked_low_level_call.sol` | 成功 | 4 | 1 |

> 说明：当前环境未安装 TensorFlow / PyTorch，模型证据为静态代理分；DeepSeek 余额不足使 LLM 推理结论为 `inconclusive`。流程与报告仍完整可用。
