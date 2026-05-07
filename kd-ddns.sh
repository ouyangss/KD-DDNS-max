#!/usr/bin/env bash
# KD-DDNS 一键部署（非交互式）
# 运行后自动设置 crontab 每分钟检测 IP 变化

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DDNS_SCRIPT="$SCRIPT_DIR/cf-ddns.sh"

if [ ! -f "$DDNS_SCRIPT" ]; then
  echo "错误：找不到 cf-ddns.sh，路径: $DDNS_SCRIPT"
  exit 1
fi

chmod +x "$DDNS_SCRIPT"

# 设置 crontab 每分钟执行一次
CRON_JOB="*/1 * * * * $DDNS_SCRIPT >> /var/log/cf-ddns.log 2>&1"

# 检查是否已存在相同的定时任务
if crontab -l 2>/dev/null | grep -qF "$DDNS_SCRIPT"; then
  echo "✅ crontab 定时任务已存在，无需重复添加"
else
  (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
  echo "✅ 已添加 crontab 定时任务：每分钟检测 IP 变化"
fi

echo "📋 当前 crontab："
crontab -l 2>/dev/null | grep "$DDNS_SCRIPT"

# 立即执行一次
echo ""
echo "🚀 立即执行一次 DDNS 更新..."
"$DDNS_SCRIPT"

# 安装 nyanpass 节点客户端
# 安装过程中需要确认两次 y，这里用 printf 自动输入，避免交互阻塞
echo ""
echo "🐱 正在安装 nyanpass 节点客户端..."
printf 'y\ny\n' | bash <(curl -fLSs https://dl.nyafw.com/download/nyanpass-install.sh) rel_nodeclient "-t b4e510b1-1bfa-49c5-9a08-87cdd381188e -u https://ny.pgupy.com"
