# Output Calibration Log

这份文档用于记录：
- AI 原始输出 `v1`
- Jack 调整后的更优输出 `v2`
- 两者之间的关键差异
- 差异应该反向更新到哪一层

目标不是只优化 prompt，而是把“Jack 为什么会改”系统化沉淀出来。

## Why This Exists

很多输出质量问题，不是单纯 prompt 少一句话，而是属于不同层次的问题：
- signal 选错了
- 证据强度不够
- 判断深度不够
- thesis 没提炼出来
- 结构组织不对
- 口吻不对
- 产物类型就错了

如果把所有问题都塞进 prompt，prompt 会越来越长、越来越脏。

所以每次校准，都要回答：
- 差异是什么
- 差异为什么出现
- 该更新哪一层

## Fixed Fields

每条样本默认记录 5 栏：

- `任务`
- `AI 原输出 v1`
- `Jack 优化后输出 v2`
- `差异原因`
- `应该更新哪一层`

### 差异原因标签

默认优先从这些标签里选：
- `signal 选择`
- `证据强度`
- `判断深度`
- `thesis 提炼`
- `结构组织`
- `表达口吻`
- `创业启发质量`
- `可执行性`
- `信息密度`

### 更新层级标签

默认优先归到这些层：
- `prompt`
- `template`
- `watchlist`
- `thesis register`
- `judgment framework`
- `memory / background`
- `task definition`

## Sample 001

### 任务
`AI 巡检简报` / 目标：从 signal 中提炼更长期的 thesis，并反向指导下一轮巡检。

### AI 原输出 v1
- 有 signal
- 有 insight
- 但容易停在“这条新闻对 Jack 有启发”
- 缺少更稳定的 `Thesis 提炼`
- 缺少“下一轮巡检要盯什么”这一层

### Jack 优化后输出 v2
- 不只要 signal 和 insight
- 还要有 `Thesis 提炼`
- 还要有 `下一轮巡检要盯什么`
- 目标不是把简报写得更好看，而是让巡检和长期判断形成闭环

### 差异原因
- `thesis 提炼`
- `判断深度`
- `结构组织`

### 应该更新哪一层
- `template`
- `judgment framework`
- `task definition`

## Sample 002

### 任务
`AI 巡检简报` / 目标：从“高质量行业观察”升级成“创业决策支持”。

### AI 原输出 v1
- 更像高质量信息整理
- 默认偏官方博客 / 公开发布 / 新闻层
- 能做产品判断，但不一定落到创业动作
- 无强 signal 时，容易停在“今天没大事”

### Jack 优化后输出 v2
- 默认优先抓 `论坛 / Reddit / X / GitHub issue / App Store 差评 / 竞品社区`
- 每条高价值输入都要回答：验证哪条 thesis、削弱哪条 thesis、本周做什么动作、对资源分配意味着什么
- 没有强 signal 时，自动补 `反证 / 机会拆解 / 关键证据缺口`
- 输出目标从“日报”改成“决策资产”

### 差异原因
- `signal 选择`
- `创业启发质量`
- `可执行性`
- `结构组织`

### 应该更新哪一层
- `task definition`
- `watchlist`
- `template`
- `judgment framework`
- `thesis register`

## Rule

后续只要出现“Jack 明显把输出改好了”的场景，就值得往这里补一条。

对 `AI 巡检简报`，默认把下面这些情况视为高优先级 calibration sample：
- Jack 重写了 `Thesis 提炼`
- Jack 重写了 `创业启发`
- Jack 明确指出 signal 选错了、太泛了、证据不够硬
- Jack 要求改成更适合转发/汇报的结构或口径

不要为了记日志而记日志。
只记那些会反复提升系统质量的差异。
