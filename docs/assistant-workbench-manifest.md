# Assistant Workbench Manifest

这份文件用于描述当前 workspace 里已经存在的主要能力、入口、状态和验证方式。

目标不是替代 `MEMORY.md`，而是把“我现在到底能做什么、做到什么程度、如何验证、哪里容易坏”结构化写清楚。

## Status Labels

- `已验证`：真实执行过，并有日志或结果证据
- `部分可用`：主链路存在，但稳定性、输入约束或验收仍不完整
- `待整理`：能力可能存在，但清单、入口或验证还没整理好
- `仅设想`：方向已明确，但尚未形成稳定实现

## Capability Table

| Name | Status | Entry | Input | Output | State / Log | Verify | Failure Modes |
|---|---|---|---|---|---|---|---|
| `dual-channel-send` | 已验证 | `scripts/send-dual-channel.sh` | message file, state value | 飞书 + 微信发送 | `memory/*.feishu` `memory/*.weixin`, `logs/*` | `scripts/send-dual-channel.sh --help` | 目标会话错误、channel ack 成功但客户端不可见、state 命中导致 skip |
| `lenny-daily-cards-generate` | 部分可用 | `scripts/generate-lenny-daily-cards.sh` | task file, state, dataset | `workfiles/lenny-daily-cards-latest.md` | `memory/lenny-daily-cards-state.json`, `logs/lenny-daily-cards-generate.log` | `scripts/workbench-verify.sh lenny` | agent 结果格式不匹配、payload 为空、source 选择不稳定 |
| `lenny-daily-cards-send` | 已验证 | `scripts/send-lenny-daily-cards.sh` | latest card file | 双发结果 | `memory/lenny-daily-cards-send-state.txt.*`, `logs/lenny-daily-cards-send.log` | `tail -n 5 logs/lenny-daily-cards-send.log` | 自动发送成功但微信不可见、state 残留、文件日期不符 |
| `stock-finance-daily` | 已验证 | `scripts/run-stock-finance-daily.sh` | task prompt, public info | `workfiles/stock-finance-daily-latest.md` | `memory/stock-finance-daily-state.json`, `memory/stock-finance-daily-send-state.txt.*`, `logs/stock-finance-daily.log` | `scripts/workbench-verify.sh stock-finance` | 晨报结构不合法、公开信息证据不足、发送层与可见性不一致 |
| `ai-trend-watch` | 部分可用 | `scripts/run-ai-trend-watch.sh` | task prompt, external search / agent output | `workfiles/ai-trend-watch-latest.md` | `memory/ai-trend-watch-state.json`, `memory/ai-trend-watch-send-state.txt.*`, `logs/ai-trend-watch.log` | `scripts/workbench-verify.sh ai-trend` | 搜索受限、返回过程性文本、阈值判断过松或过严 |
| `vision-check` | 已验证 | `scripts/check-openclaw-vision.sh` | local image path or URL | 视觉读取结果 | 终端输出 | `scripts/check-openclaw-vision.sh --help` | 配置路径错误、provider key 缺失、只验证 API 不等于完整聊天链路 |
| `channel-handoff` | 部分可用 | `scripts/update-channel-handoff.sh` | source, status, optional content | `memory/channel-handoff.md` | `memory/channel-handoff.md` | `scripts/update-channel-handoff.sh --help` | handoff 过长、写入了不该跨端共享的内容 |
| `audio-transcribe` | 待整理 | `scripts/stepfun-transcribe.sh` | audio file | transcript | script output | `scripts/stepfun-transcribe.sh --help` | 环境变量缺失、音频输入格式不兼容 |
| `image-generate` | 待整理 | `scripts/stepfun-generate-image.sh` | prompt | generated image | script output | `scripts/stepfun-generate-image.sh --help` | provider 依赖、结果未纳入统一工作流 |
| `workbench-status` | 已验证 | `scripts/workbench-status.sh` | none | 当前工作台结构状态 | terminal output | `scripts/workbench-status.sh` | 只反映文件存在性，不等于业务链路健康 |
| `workbench-verify` | 已验证 | `scripts/workbench-verify.sh` | capability name | 非破坏性校验结果 | terminal output | `scripts/workbench-verify.sh all` | 只能验证骨架和入口，不能代替真实业务验收 |

## Verification Commands

```bash
scripts/workbench-verify.sh all
scripts/workbench-verify.sh docs
scripts/workbench-verify.sh dual-channel
scripts/workbench-verify.sh lenny
scripts/workbench-verify.sh stock-finance
scripts/workbench-verify.sh ai-trend
scripts/workbench-verify.sh vision
scripts/workbench-status.sh
```

## Architecture Shape

当前这套 workbench 已开始形成更清楚的结构：

- `workbench_core/`
  - 共用主实现层，负责 manifest 读取、summary、status payload、verify 规则、runtime residue 规则
- `scripts/`
  - 薄包装层，负责对外入口，如 `summary / status / verify / precommit`
- `docs/`
  - 解释层和索引层，负责 manifest、状态模型、边界说明、方法文档
- `memory/` / `workfiles/` / `logs/`
  - 运行态和结果态

这还不是一个完整的 `src/` 风格主系统，但已经不再只是脚本堆，而是 `core + wrappers + docs + runtime` 的轻量 workbench 架构。

## Verification Philosophy

- 先验证“入口是否存在、脚本是否可执行、依赖文件是否存在”
- 再验证“结果结构是否正确”
- 最后验证“真实发送 / ack / 客户端可见性”

也就是说，`verify ok` 只代表骨架可用，不代表整条业务链路已经完全稳定。

## Current Gaps

- 缺少统一的真实发送 smoke test
- 缺少按能力输出最近一次运行摘要的结构化状态文件
- 缺少面向 Git 提交的“变更分层检查”
- 仍有部分能力的真实依赖散落在脚本和记忆文件里

## Intended Direction

后续这份 manifest 应逐步升级成一份更明确的工作台索引，至少补齐：

- capability owner
- exact verification command
- cron / heartbeat trigger source
- failure recovery steps
- pushability (`safe to commit` vs `local runtime only`)
