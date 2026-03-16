# HEARTBEAT.md

# Keep this file empty (or with only comments) to skip heartbeat API calls.

# Add tasks below when you want the agent to check something periodically.

## 巡检检查项（2026-03-16 配置）

### 每周一 10:00 自动巡检
- [ ] 检查 "有趣内容简报" 定时任务是否执行
- [ ] 查看 `/root/.openclaw/workspace/interesting-briefing-*.md` 最新文件
- [ ] 确认简报已发送到飞书（检查日志 `/root/.openclaw/workspace/logs/interesting-briefing.log`）
- [ ] 如果失败，重试或手动执行脚本

### 日常巡检
- [ ] 检查是否有新任务需要处理
- [ ] 检查 Codex 进程状态
- [ ] 检查定时任务运行状态

---

# If nothing needs attention, reply HEARTBEAT_OK.
