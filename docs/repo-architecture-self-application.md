# Repo Architecture Self-Application

这份说明记录一个更具体的迁移动作：
不是抽象地“自我进化”，而是把一个清楚分层、诚实表达状态、可验证推进的仓库组织方法，迁移到 assistant 自己身上。

## Learned Pattern

从外部仓库上真正值得借鉴的不是某个技术栈，而是这 5 个组织动作：

1. 把研究对象和当前实现分开
2. 把仓库定义成工作台，而不是假装成完整产品
3. 用清晰 layout 讲明每一层在干什么
4. 给当前状态诚实命名，不夸大完成度
5. 给系统补最小验证入口，而不是只写故事

## Applied To This Assistant

### 1. 从“技能包叙事”改成“工作台叙事”

- `README.md` 现在优先描述这是一个 assistant workbench
- 不再把所有内容都包装成生产就绪的统一技能

### 2. 从混合文件堆改成四层结构

- `execution`: `scripts/`
- `state`: `memory/*state*`, `memory/channel-handoff.md`
- `knowledge`: `MEMORY.md`, `AGENTS.md`, `docs/*.md`
- `delivery`: `workfiles/*`

### 3. 从口头规则改成结构化工件

以下规则已从“只存在于记忆里”迁到可读文档：
- 状态模型
- git 边界
- collaboration model
- honesty and verification

### 4. 从人工感知改成最小验证入口

已新增：
- `scripts/workbench-status.sh`
- `scripts/workbench-verify.sh`
- `scripts/workbench-precommit-check.sh`

### 5. 从人脑索引改成机器可读索引

已新增：
- `docs/assistant-workbench-manifest.md`
- `docs/assistant-workbench-manifest.json`

## What This Changes In Practice

之后如果要继续改进 assistant，本质上优先做的是：

- 改结构，不只改描述
- 加验证，不只加规则
- 补边界，不只补愿景
- 写 manifest，不只靠记忆

## Remaining Gaps

- 还没有统一的实时健康状态文件
- 还没有把所有自动化都纳入统一 registry 驱动
- 真实 smoke test 仍不足
- 运行态文件虽然已被 ignore，但历史脏文件还没完全从 git 边界中剥离
