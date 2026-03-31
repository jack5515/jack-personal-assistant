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

## Rule

后续只要出现“Jack 明显把输出改好了”的场景，就值得往这里补一条。

对 `AI 巡检简报`，默认把下面这些情况视为高优先级 calibration sample：
- Jack 重写了 `Thesis 提炼`
- Jack 重写了 `创业启发`
- Jack 明确指出 signal 选错了、太泛了、证据不够硬
- Jack 要求改成更适合转发/汇报的结构或口径

不要为了记日志而记日志。
只记那些会反复提升系统质量的差异。
