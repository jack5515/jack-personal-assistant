# Git Boundaries

这份说明定义什么内容适合进入 Git，什么内容应该留在本地运行时。

## Safe To Commit

以下内容默认适合进入 Git：

- `scripts/` 下可复用的执行脚本
- `docs/` 下的方法说明、manifest、运维说明
- `README.md`、`SKILL.md`、`install.sh`
- 通用任务模板和长期结构文件
- 与验证相关、可复用的诊断脚本

## Runtime Only

以下内容默认不应进入 Git：

- `logs/` 下的运行日志
- `memory/*state*`、`memory/*send-state*` 等运行状态
- `workfiles/*-latest.md` 这类当前结果物
- 临时测试消息、手工重发产物、调试输出
- `tmp/`、`generated/`、`media/` 等本地产物目录
- 跨端 handoff 的即时摘要

## Daily Notes

`memory/YYYY-MM-DD.md` 默认视为本地值班记忆，不默认进入公共 Git 历史。
如需沉淀，应先提炼进 `MEMORY.md` 或正式文档。

## Review Rule

准备提交时，优先问 3 个问题：

1. 这是不是能力层代码或文档？
2. 这是不是运行现场快照？
3. 别人在另一台机器上拿到它，会更容易理解和复用，还是只会更困惑？
