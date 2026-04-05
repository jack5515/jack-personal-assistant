# Jack's Personal Assistant Workspace

这是 Jack 的 OpenClaw 助手工作台，不是一个“已经封装完整的产品”，而是一套持续演进中的 agent workspace。

当前更准确的理解方式是：
- `scripts/` 负责执行能力
- `memory/` 负责状态与连续性
- `workfiles/` 负责输入输出与结果物
- `docs/` 负责方法、说明和结构化清单

目标不是把所有东西都塞进一个技能说明，而是把这套 workspace 做成一个清楚分层、诚实表达当前状态、可验证推进的 agent workbench。

## Current Status

当前这套 workspace 已经具备一批可工作的能力，但成熟度不同。

### 已验证能力

- `dual-channel-send`
  - 能把同一份内容发送到飞书和微信
  - 支持按 channel 记录 state，避免重复发送
  - 相关脚本：`scripts/send-dual-channel.sh`
- `lenny-daily-cards`
  - 能生成并发送每日 Lenny 学习卡片
  - 相关脚本：`scripts/generate-lenny-daily-cards.sh`、`scripts/send-lenny-daily-cards.sh`
- `stock-finance-daily`
  - 能生成并双发股票财经晨报
  - 相关脚本：`scripts/run-stock-finance-daily.sh`
- `ai-trend-watch`
  - 能执行 AI 巡检、生成结果、按结果双发
  - 相关脚本：`scripts/run-ai-trend-watch.sh`
- `vision-check`
  - 能对当前 OpenClaw 图片读取链路做最小诊断
  - 相关脚本：`scripts/check-openclaw-vision.sh`

### 本地工具封装

- `any2pdf`
  - 本地 Markdown 转 PDF 封装
  - 相关脚本：`scripts/any2pdf.sh`
- `md2pptx`
  - 本地 Markdown 转可编辑 PPTX 封装
  - 相关脚本：`scripts/md2pptx.sh`
- `deck-images-pexels`
  - 本地 Pexels 搜图与下载封装
  - 相关脚本：`scripts/pexels-search.sh`、`scripts/pexels-search.py`

### 已存在但仍需继续产品化的部分

- 能力清单还没完全结构化，仍有一部分知识散落在 `MEMORY.md`、`AGENTS.md` 和脚本内部
- 运行状态文件、本地产物、日志文件与可提交代码尚未完全分层
- 有些验证动作已经存在，但还没统一成一个清晰的 `status / verify / dry-run` 入口

## Workspace Layout

```text
.
├── README.md                        # 当前工作台说明
├── AGENTS.md                        # workspace 行为约束
├── MEMORY.md                        # 长期记忆与原则
├── USER.md                          # 用户画像
├── HEARTBEAT.md                     # heartbeat 巡检清单
├── docs/                            # 文档、说明、manifest
├── scripts/                         # 自动化执行脚本
├── workfiles/                       # 任务输入输出与结果物
├── memory/                          # 运行状态、日记、handoff
├── logs/                            # 本地日志
├── agency-agents-zh/                # 专家 agents 子模块
└── generated/ tmp/ media/           # 生成物和临时目录
```

## Design Principles

这套 workspace 后续按以下原则继续整理：

- `分层清楚`
  - 执行层、状态层、知识层、交付层分开维护
- `状态诚实`
  - 不把“脚本存在”说成“能力稳定”
  - 默认区分：已验证 / 部分可用 / 待修复 / 仅设想
- `验证优先`
  - 重要改动默认附最小验证证据，而不是只给口头结论
- `跨端做薄`
  - 飞书和微信视为独立 session，跨端连续性依赖 handoff，而不是 raw transcript
- `Git 边界明确`
  - 只提交能力与文档，不把本地状态、日志、latest 产物混进仓库

## What This Repository Is Not

这不是：
- 一个已经封装完成、对外稳定分发的通用产品
- 一个不依赖本地环境和私有凭证的纯开源样板
- 一个可以脱离 `MEMORY.md` / `AGENTS.md` 就完整运行的最小仓库

## Recommended Next Steps

建议下一步按这个顺序推进：

1. 补全能力 manifest，统一记录每条自动化的入口、输入、输出、状态文件和日志文件
2. 收紧 `.gitignore`，把运行态文件和可提交代码分开
3. 给关键能力补统一的 `verify` 思路
4. 将“实事求是 / 视觉证据自检 / 生成-发送-触发分层验收”沉淀成更正式的工程说明

## Manifest

当前能力清单见：`docs/assistant-workbench-manifest.md`
