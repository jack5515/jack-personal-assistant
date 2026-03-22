# Lenny Daily Cards Task

目标：每天产出 5-10 条适合 Jack 学习 AI 产品的卡片知识，并发送到当前飞书私聊。

## 数据源
- 仓库：`external-knowledge/lennys-newsletterpodcastdata`
- 索引：`external-knowledge/lennys-newsletterpodcastdata/index.json`
- 状态文件：`memory/lenny-daily-cards-state.json`

## 选题原则
优先挑选对 AI 产品经理最有帮助的内容，尤其是：
- AI 产品方法论
- Agent / AI-native workflow
- PM 能力升级
- 设计与工程协同
- 用户研究、增长、定价、组织协作
- 对 Jack 有直接借鉴意义的产品判断

## 去重规则
- 先读取 `memory/lenny-daily-cards-state.json`
- 优先避开最近 14 天已经使用过的 source 文件
- 如果可用新 source 不足，允许复用旧 source，但必须换一个新角度
- 发送后更新状态文件，至少记录：日期、使用过的 source 文件名、卡片标题

## 输出要求
- 用中文输出
- 每天 5-10 条，默认 7 条左右
- 每条卡片尽量短，强调“可直接借鉴”
- 不要空泛总结，要像 AI 产品学习卡片
- 尽量给出原文中的具体观点，不要编造原文没有的结论
- 结果分组优先按主题，而不是按文章来源

## 推荐格式
标题：Lenny AI 产品学习卡片 Vol.X

1. 卡片标题
- 观点：一句话讲清核心判断
- 借鉴：这条对 AI 产品/Agent/PM 工作有什么启发
- 来源：文件名 + 日期

2. 卡片标题
- 观点：...
- 借鉴：...
- 来源：...

## 执行步骤
1. 读取索引和状态文件
2. 选择适合今天的 5-10 条卡片来源
3. 提炼成中文卡片
4. 在回复里直接发送给 Jack
5. 更新 `memory/lenny-daily-cards-state.json`

## 风格
- 简洁
- 直接
- 少废话
- 优先讲判断和借鉴
