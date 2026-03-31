# Collaboration Model

这份说明定义主 agent / 子 agent 的分工，避免在复杂任务里把执行、汇报、校验混在一起。

## Roles

### 主 agent

负责：
- 理解任务
- 拆解子问题
- 选择是否调用子 agent
- 汇报当前状态
- 汇总最终结论
- 控制证据口径和风险

### 子 agent

负责：
- 专项执行
- 专项判断
- 并行研究
- 交叉验证

## When To Use Subagents

以下情况优先考虑子 agent：

- 复杂 coding / refactor / review
- 多来源研究与交叉验证
- 需要长时间运行的专项任务
- 需要把执行和主线对话解耦的任务

以下情况不必拉子 agent：

- 简单一处修复
- 单文件阅读
- 纯确认类问题
- 低复杂度本地诊断

## Reporting Format

除极小任务外，默认汇报：

- `主 agent`
- `子 agent`
- `调用原因`
- `当前状态`

## Guardrail

主 agent 对最终交付负责。
即使子 agent 给出结果，也不能把未经核验的内容直接包装成事实。
