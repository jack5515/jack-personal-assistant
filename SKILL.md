# Jack's Personal Assistant Skill

**版本**: 1.0.0  
**作者**: Jack  
**许可证**: MIT  
**描述**: Jack 的个人助理技能包 - 包含工作原则、巡检维度、定时任务、Agency Agents 专家团队集成

---

## 📋 目录

- [概述](#概述)
- [安装](#安装)
- [配置](#配置)
- [功能说明](#功能说明)
- [使用示例](#使用示例)
- [文件结构](#文件结构)
- [维护](#维护)

---

## 概述

这是一个为 Jack 定制的 OpenClaw 技能，整合了：

- ✅ 工作原则（秒回、第一性原理、Codex 外包、主动巡检、成本控制、上下文管理、持续提交、环境预检、代码整洁、值班心态、长任务汇报）
- ✅ "有趣内容"巡检维度（11个子类：产品动态、技术方向、金融方向、个人成长）
- ✅ 定时任务配置（每周简报、财经新闻等）
- ✅ 146 个 Agency Agents 专家团队（覆盖工程、设计、营销、游戏、空间计算等领域）
- ✅ 本地自定义脚本（简报生成、任务管理等）
- ✅ 心跳巡检机制（HEARTBEAT.md 检查项）

---

## 安装

### 方式一：自动安装（推荐）

```bash
# 克隆仓库
git clone https://github.com/yourusername/jack-personal-assistant.git
cd jack-personal-assistant

# 运行安装脚本
./install.sh
```

### 方式二：手动复制

```bash
# 复制技能到 OpenClaw 技能目录
cp -r . ~/.openclaw/skills/jack-personal-assistant/

# 这台机器启用了本地 restart guard；普通 restart 可能被拦截。
# 仅在确认需要重启时，使用：
openclaw gateway restart --force
```

---

## 配置

### 必需环境变量

| 变量名 | 说明 | 示例 |
|--------|------|------|
| `STEPFUN_API_KEY` | StepFun Search API 密钥，用于"有趣内容"巡检 | `sk-xxx` |

### 可选配置

编辑 `config.json`：

```json
{
  "heartbeat_interval_minutes": 5,
  "weekly_briefing_day": 1,
  "weekly_briefing_hour": 10,
  "scan_categories": [
    "product-releases",
    "agent-frameworks",
    "open-source",
    "productivity-tools",
    "market-sentiment",
    "compliance"
  ],
  "feishu_target_user": "ou_33aacf0efe69f7ef1f596348cf6bedec"
}
```

---

## 功能说明

### 0. Custom Agents Layer

`jack-personal-assistant/agents/` 目录下维护了一套 Jack 定制的专属子 agent 系统，用于覆盖高频工作流：

- `briefing-scout`：简报候选扫描
- `market-watch`：市场与个股观察
- `signal-skeptic`：脏数据与异常结论校验
- `automation-operator`：cron / heartbeat / 日志值班
- `pm-radar`：AI 产品与竞品洞察
- `knowledge-librarian`：知识库与 repo 整理
- `workflow-architect`：自动化流程设计
- `service-designer`：服务化与产品化抽象

配套文件：
- `agents/task-routing.md`
- `agents/collaboration-map.md`
- `agents/activation-guide.md`
- `agents/decision-policy.md`
- `agents/task-states.md`
- `agents/runtime-bindings.md`

使用原则：
- 优先把任务路由到最贴近场景的自定义 agent
- 对高风险摘要、金融结论、极端数据，默认追加 `signal-skeptic`
- 对定时任务、heartbeat、脚本异常，默认追加 `automation-operator`


### 1. 自动巡检（Heartbeat）

每次心跳会检查：

- [ ] Codex 任务进度
- [ ] 定时任务执行状态
- [ ] 本周简报是否生成
- [ ] Agency Agents 智能体可用性

配置位置：`HEARTBEAT.md`

### 2. 每周简报生成

每周一 10:00 自动运行：

- 调用 `step-search` 扫描 11 个维度的最新动态
- 整理成 Markdown 简报
- 发送到飞书

脚本：`scripts/interesting-briefing-weekly.sh`

### 3. Agency Agents 专家团队

146 个专业智能体，可直接在对话中激活：

```
激活小红书运营智能体，帮我设计种草笔记策略
```

```
使用前端开发者智能体审查这个 React 组件
```

智能体列表：`agency-agents-zh/`（已安装到 `~/.openclaw/agency-agents/`）

### 4. 工作原则提醒

在每次长任务（>20秒）执行时，自动应用：

- 每 10 秒汇报一次进度
- 使用便宜模型进行 heartbeat 检查
- 执行前后自动 commit（如果修改了文件）

---

## 使用示例

### 激活智能体

```
激活抖音策略师，为我的新APP设计短视频推广方案
```

### 手动触发简报

```bash
# 立即生成本周简报
./scripts/interesting-briefing-weekly.sh
```

### 查看工作原则

```bash
cat MEMORY.md | grep -A 20 "工作原则"
```

### 心跳巡检检查

系统会自动执行 HEARTBEAT.md 中的检查项，你也可以手动运行：

```bash
# 查看心跳检查清单
cat HEARTBEAT.md
```

---

## 文件结构

```
jack-personal-assistant/
├── SKILL.md              # 本说明文档
├── skill.json            # 技能元数据
├── config.json           # 配置文件
├── install.sh            # 安装脚本
├── MEMORY.md             # 长期记忆（工作原则、用户档案）
├── USER.md               # 用户身份信息
├── HEARTBEAT.md          # 心跳巡检检查项
├── scripts/
│   ├── interesting-briefing-weekly.sh  # 每周简报生成
│   └── mag7-bxtrender-report.py       # Mag7 盯盘（已废弃）
├── agency-agents-zh/     # 146个智能体源码（Git 子模块）
└── docs/
    ├── interesting-content-dimensions.md  # 巡检维度详解
    ├── agency-agents-list.md             # 智能体清单
    └── troubleshooting.md                # 故障排除
```

---

## 维护

### 更新 Agency Agents

```bash
cd agency-agents-zh
git pull origin main
./scripts/convert.sh --tool openclaw
./scripts/install.sh --tool openclaw
```

### 添加新的巡检维度

编辑 `MEMORY.md` 中的"有趣内容"维度，然后更新 `config.json`。

### 调试

查看日志：

```bash
tail -f /root/.openclaw/workspace/logs/weekly-briefing-cron.log
```

检查智能体安装：

```bash
ls ~/.openclaw/agency-agents/ | wc -l  # 应显示 146
```

---

## License

MIT - 自由使用、修改和分发。

---

## 致谢

- 感谢 [agency-agents-zh](https://github.com/jnMetaCode/agency-agents-zh) 提供的 146 个专业智能体
- 感谢 OpenClaw 团队打造的强大 Agent 平台

---

**祝使用愉快！** 🚀
