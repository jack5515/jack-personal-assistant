#!/bin/bash
# Jack's Personal Assistant Skill 安装脚本

set -e

echo "🎯 安装 Jack's Personal Assistant Skill..."

# 复制到 OpenClaw 技能目录
TARGET_DIR="${HOME}/.openclaw/skills/jack-personal-assistant"
mkdir -p "$TARGET_DIR"

echo "📦 复制文件..."
cp -r . "$TARGET_DIR/"

# 设置脚本权限
chmod +x "$TARGET_DIR/scripts/"*.sh 2>/dev/null || true

# 检查 agency-agents-zh 子模块
if [ -d "$TARGET_DIR/agency-agents-zh/.git" ]; then
    echo "🔄 更新 agency-agents-zh 子模块..."
    git submodule update --init --recursive
fi

echo "✅ 安装完成！"
echo ""
echo "📝 后续步骤："
echo "1. 确保环境变量 STEPFUN_API_KEY 已设置"
echo "2. 重启 OpenClaw 网关: openclaw gateway restart"
echo "3. 测试技能: 激活小红书运营智能体"
echo ""
echo "🚀 祝你使用愉快！"