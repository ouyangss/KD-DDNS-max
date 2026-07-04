#!/usr/bin/env bash
# KD-DDNS 一键部署（非交互式）
# 运行后自动设置 crontab 每分钟检测 IP 变化

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DDNS_SCRIPT="$SCRIPT_DIR/cf-ddns.sh"
DDNS_URL="https://raw.githubusercontent.com/ouyangss/KD-DDNS-max/main/cf-ddns.sh"

if [ ! -f "$DDNS_SCRIPT" ]; then
  echo "⚠️ 找不到 cf-ddns.sh，正在下载到：$DDNS_SCRIPT"
  if command -v curl >/dev/null 2>&1; then
    curl -fL -o "$DDNS_SCRIPT" "$DDNS_URL"
  elif command -v wget >/dev/null 2>&1; then
    wget -O "$DDNS_SCRIPT" "$DDNS_URL"
  else
    echo "错误：未找到 curl 或 wget，无法下载 cf-ddns.sh"
    exit 1
  fi
fi

if [ ! -s "$DDNS_SCRIPT" ]; then
  echo "错误：cf-ddns.sh 下载失败或文件为空，路径: $DDNS_SCRIPT"
  exit 1
fi

chmod +x "$DDNS_SCRIPT"

# 设置定时任务：优先写入系统级 /etc/cron.d，非 root 环境回退到当前用户 crontab
CRON_SCHEDULE="*/1 * * * *"
CRON_LOG="/var/log/cf-ddns.log"
CRON_JOB="$CRON_SCHEDULE $DDNS_SCRIPT >> $CRON_LOG 2>&1"
SYSTEM_CRON_FILE="/etc/cron.d/kd-ddns"
SYSTEM_CRON_JOB="$CRON_SCHEDULE root $DDNS_SCRIPT >> $CRON_LOG 2>&1"

write_user_crontab() {
  if ! command -v crontab >/dev/null 2>&1; then
    echo "错误：未找到 crontab 命令，无法写入定时任务"
    return 1
  fi

  if crontab -l 2>/dev/null | grep -qF "$DDNS_SCRIPT"; then
    echo "✅ 用户 crontab 定时任务已存在，无需重复添加"
  else
    tmp_cron="$(mktemp)"
    crontab -l > "$tmp_cron" 2>/dev/null || true
    printf '%s\n' "$CRON_JOB" >> "$tmp_cron"
    if crontab "$tmp_cron"; then
      echo "✅ 已添加用户 crontab 定时任务：每分钟检测 IP 变化"
    else
      rm -f "$tmp_cron"
      echo "错误：写入用户 crontab 失败"
      return 1
    fi
    rm -f "$tmp_cron"
  fi

  if crontab -l 2>/dev/null | grep -qF "$DDNS_SCRIPT"; then
    return 0
  fi

  echo "错误：用户 crontab 写入后未验证到任务，请手动检查 crontab -l"
  return 1
}

write_system_cron() {
  if [ "$(id -u)" -ne 0 ] || [ ! -d /etc/cron.d ] || [ ! -w /etc/cron.d ]; then
    return 1
  fi

  {
    echo "SHELL=/bin/bash"
    echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    echo "$SYSTEM_CRON_JOB"
  } > "$SYSTEM_CRON_FILE"
  chmod 644 "$SYSTEM_CRON_FILE"

  if grep -qF "$DDNS_SCRIPT" "$SYSTEM_CRON_FILE"; then
    echo "✅ 已写入系统级定时任务：$SYSTEM_CRON_FILE"
    return 0
  fi

  echo "错误：系统级定时任务写入后未验证到任务：$SYSTEM_CRON_FILE"
  return 1
}

if ! write_system_cron; then
  echo "ℹ️ 无法写入系统级 /etc/cron.d，尝试写入当前用户 crontab..."
  write_user_crontab || exit 1
fi

echo "📋 当前 DDNS 定时任务："
if [ -f "$SYSTEM_CRON_FILE" ] && grep -qF "$DDNS_SCRIPT" "$SYSTEM_CRON_FILE"; then
  grep -F "$DDNS_SCRIPT" "$SYSTEM_CRON_FILE"
else
  crontab -l 2>/dev/null | grep -F "$DDNS_SCRIPT" || true
fi

# 立即执行一次
echo ""
echo "🚀 立即执行一次 DDNS 更新..."
"$DDNS_SCRIPT"

# 安装 nyanpass 节点客户端
# 安装过程中需要确认两次 y，这里用 printf 自动输入，避免交互阻塞
echo ""
echo "🐱 正在安装 nyanpass 节点客户端..."
printf 'y\ny\ny\n' | bash <(curl -fLSs https://dl.nyafw.com/download/nyanpass-install.sh) rel_nodeclient "-t "
