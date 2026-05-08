# KD-DDNS

KD-DDNS 是一个用于 Cloudflare DDNS 更新和一键部署的脚本仓库。

## 文件说明

- `cf-ddns.sh`：Cloudflare 动态 DNS 更新脚本
- `kd-ddns.sh`：一键部署脚本，会自动下载 `cf-ddns.sh`、设置定时任务、执行一次更新，并继续安装 `nyanpass`

## 使用方式

### 1. 下载一键脚本

```bash
curl -L -O -s https://raw.githubusercontent.com/ouyangss/KD-DDNS-max/main/kd-ddns.sh
chmod +x kd-ddns.sh
./kd-ddns.sh
```

### 2. 脚本会自动处理

`kd-ddns.sh` 会自动完成以下步骤：

- 检查本地是否存在 `cf-ddns.sh`
- 如不存在则自动从仓库下载
- 为 `cf-ddns.sh` 添加执行权限
- 写入 crontab，每分钟检查一次公网 IP
- 立即执行一次 DDNS 更新
- 继续执行 `nyanpass` 安装流程

### 3. nyanpass 安装说明

`kd-ddns.sh` 在安装 `nyanpass` 时会自动预填 3 次 `y`，对应以下交互项：

- 请输入服务名：默认直接回车使用 `nyanpass`
- 是否优化系统参数：自动选择 `y`
- 是否安装常用工具：自动选择 `y`

这样可以避免安装过程卡在交互提示。

## `cf-ddns.sh` 使用参数

你也可以单独运行 `cf-ddns.sh`：

```bash
./cf-ddns.sh -k your_cloudflare_key -u your_email -z example.com -h home -t A
```

常用参数：

- `-k`：Cloudflare API Key
- `-u`：Cloudflare 账号邮箱
- `-z`：主域名
- `-h`：子域名或完整记录名
- `-t`：记录类型，`A` 或 `AAAA`
- `-f true`：强制更新

## 说明

- `A` 记录用于 IPv4
- `AAAA` 记录用于 IPv6
- 如果记录名不是完整域名，脚本会自动补全

## 提示

建议在固定目录中维护脚本，避免后续路径变化影响 crontab 任务。
