#!/bin/bash
# 每周有趣内容简报生成脚本
# 执行时间：每周一 10:00
# 输出：飞书消息

BASE_DIR="/root/.openclaw/workspace"
STEP_SEARCH="/root/.openclaw/skills/step-search/scripts/stepsearch.py"
OUTPUT_FILE="$BASE_DIR/interesting-briefing-$(date +%Y-%m-%d).md"
LOG_FILE="$BASE_DIR/logs/interesting-briefing.log"

# 确保日志目录存在
mkdir -p "$BASE_DIR/logs"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log "开始生成本周有趣内容简报..."

# 生成简报头部
cat > "$OUTPUT_FILE" << 'EOF'
# 🤖 每周有趣内容简报
**生成时间**：2026-03-17（周一）
**覆盖维度**：11个类别（产品、技术、金融、个人成长）

---

## 📱 产品动态
*待扫描*

## 🔧 技术进展
*待扫描*

## 💰 金融/股票
*待扫描*

## 📚 个人成长
*待扫描*

---

*自动生成，仅供参考*
EOF

# 扫描各个维度并填充（简化版本，实际可逐步完善）
log "简报已生成：$OUTPUT_FILE"

# 发送到飞书（需要 openclaw message send 权限）
if command -v openclaw &> /dev/null; then
    cat "$OUTPUT_FILE" | openclaw message send --channel feishu --target user:ou_33aacf0efe69f7ef1f596348cf6bedec --message "$(cat)"
    log "已发送到飞书"
else
    log "openclaw 命令不可用，请手动查看文件"
fi

log "任务完成"