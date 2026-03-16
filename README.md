# Jack's Personal Assistant Skill

[OpenClaw Skill](https://clawhub.com) - 为 AI 产品经理 Jack 定制的个人助理技能包

## 🎯 功能亮点

- ✅ **工作原则集成**：秒回、第一性原理、Codex外包、主动巡检、成本控制等11条核心原则
- ✅ **智能巡检维度**：11个子类（产品、技术、金融、个人成长）自动发现有趣内容
- ✅ **定时任务**：每周简报自动生成 + 财经新闻监控
- ✅ **146个Agency Agents**：工程、设计、营销、游戏、空间计算等全领域专家团队
- ✅ **心跳巡检**：自动检查任务进度、智能体状态、报告生成

## 📦 包含内容

| 组件 | 说明 |
|------|------|
| `MEMORY.md` | 长期记忆（工作原则、用户档案、决策记录） |
| `USER.md` | 用户身份信息（Jack, AI产品经理, 北京时间） |
| `HEARTBEAT.md` | 心跳巡检检查清单 |
| `scripts/interesting-briefing-weekly.sh` | 每周简报生成脚本 |
| `agency-agents-zh/` | 146个专业AI智能体（子模块） |
| `config.json` | 配置文件（巡检频率、目标用户等） |

## 🚀 快速开始

### 安装

```bash
# 克隆仓库
git clone https://github.com/yourusername/jack-personal-assistant.git
cd jack-personal-assistant

# 安装技能（复制到 OpenClaw）
./install.sh

# 重启 OpenClaw 网关
openclaw gateway restart
```

### 使用

激活智能体：
```
激活小红书运营智能体，帮我设计种草笔记策略
```

查看工作原则：
```
查看我的工作原则
```

---

## 📁 文件结构

```
jack-personal-assistant/
├── SKILL.md              # 技能说明文档
├── skill.json            # 技能元数据
├── package.json          # NPM 风格元数据
├── MEMORY.md             # 长期记忆
├── USER.md               # 用户档案
├── HEARTBEAT.md          # 巡检清单
├── config.json           # 配置
├── install.sh            # 安装脚本
├── scripts/
│   └── interesting-briefing-weekly.sh
└── agency-agents-zh/     # 146个智能体（Git子模块）
```

---

## 🔧 配置

必需环境变量：
- `STEPFUN_API_KEY` - 用于内容搜索

可选配置（`config.json`）：
- `heartbeat_interval_minutes`
- `weekly_briefing_day` / `weekly_briefing_hour`
- `scan_categories`
- `feishu_target_user`

---

## 📊 当前状态

- **版本**: 1.0.0
- **智能体数量**: 146
- **覆盖领域**: 工程/设计/营销/销售/产品/项目管理/测试/支持/游戏/空间计算/战略
- **国内平台**: 小红书/抖音/微信/B站/快手/淘宝/百度/微博/播客/跨境电商
- **状态**: ✅ 生产就绪

---

## 🤝 贡献

欢迎 Issue 和 PR！

---

## License

MIT

---

**Made with ❤️ for Jack**