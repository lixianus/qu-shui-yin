#!/bin/bash

# ==========================================
# 🎬 短视频去水印解析 + Cloudflare Tunnel 一键安装脚本 (高可用定制版)
# ==========================================

# 1. 颜色定义
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[36m'
PLAIN='\033[0m'

# 2. 检查 root 权限
[[ $EUID -ne 0 ]] && echo -e "${RED}错误：请使用 root 用户运行此脚本！${PLAIN}" && exit 1

# 3. 引导用户输入核心配置
echo -e "${BLUE}=== 欢迎使用短视频去水印一键部署工具 ===${PLAIN}"

read -p "请输入服务映射端口 [默认 8080]: " CUSTOM_PORT
CUSTOM_PORT=${CUSTOM_PORT:-8080}

read -p "请输入你的 Cloudflare Tunnel Token: " CF_TOKEN
if [ -z "$CF_TOKEN" ]; then
    echo -e "${RED}错误：Cloudflare Tunnel Token 不能为空！${PLAIN}"
    exit 1
fi

read -p "请输入绑定的自定义域名 (例如: parse.example.com): " CUSTOM_DOMAIN
CUSTOM_DOMAIN=${CUSTOM_DOMAIN:-未绑定}

# 获取当前服务器公网 IP
PUBLIC_IP=$(curl -s https://api.ipify.org || curl -s ifconfig.me || echo "获取失败")

# 4. 创建工作目录
INSTALL_DIR="/opt/parse-video"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# 5. 持久化保存配置信息（供 qsy 面板读取展示）
cat <<EOF > config.env
CUSTOM_PORT="$CUSTOM_PORT"
CF_TOKEN="$CF_TOKEN"
CUSTOM_DOMAIN="$CUSTOM_DOMAIN"
PUBLIC_IP="$PUBLIC_IP"
EOF

# 6. 编写 Docker Compose（使用你自己的独立 GHCR 镜像）
cat <<EOF > docker-compose.yml
services:
  parse-video:
    image: ghcr.io/lixianus/qu-shui-yin:latest
    container_name: parse-video
    restart: always
    ports:
      - "${CUSTOM_PORT}:8080"
EOF

# 启动主服务
echo -e "${YELLOW}正在启动解析主服务...${PLAIN}"
docker compose up -d

# 7. 独立高可用部署 cloudflared 容器（解决 1033 错误）
echo -e "${YELLOW}正在启动 Cloudflare Tunnel 隧道...${PLAIN}"
docker stop cloudflared-tunnel 2>/dev/null
docker rm cloudflared-tunnel 2>/dev/null
docker run -d \
  --name cloudflared-tunnel \
  --restart always \
  cloudflare/cloudflared:latest tunnel --no-autoupdate run --token "$CF_TOKEN"

# 8. 生成全功能 qsy 快捷管理命令（内含配置查看功能）
cat << 'EOF' > /usr/local/bin/qsy
#!/bin/bash
while true; do
    clear
    echo "=========================================="
    echo "       qsy 快捷管理面板 (高可用版)       "
    echo "=========================================="
    echo "1. 查看当前服务配置信息 (域名/端口/IP/Token)"
    echo "2. 查看容器运行状态 (docker ps)"
    echo "3. 查看解析主服务日志 (parse-video logs)"
    echo "4. 查看隧道连接日志 (cloudflared logs)"
    echo "5. 一键强制重启与修复服务"
    echo "6. 更新项目到最新版"
    echo "7. 停止全部服务"
    echo "8. 卸载并清理全部配置"
    echo "0. 退出"
    echo "=========================================="
    read -p "请选择操作 [0-8]: " choice
    case $choice in
        1)
            echo "=========================================="
            echo "         当前服务配置信息详情             "
            echo "=========================================="
            if [ -f /opt/parse-video/config.env ]; then
                source /opt/parse-video/config.env
                echo -e "🔗 绑定域名 : \033[32m${CUSTOM_DOMAIN}\033[0m"
                echo -e "🌐 本地端口 : \033[32m${CUSTOM_PORT}\033[0m"
                echo -e "📍 服务器IP : \033[32m${PUBLIC_IP}\033[0m"
                echo -e "🔑 隧道Token: \033[33m${CF_TOKEN}\033[0m"
            else
                echo -e "\033[31m未找到配置文件，可能安装不完整。\033[0m"
            fi
            echo "=========================================="
            read -p "按回车键返回主菜单..."
            ;;
        2) docker ps ;;
        3) docker logs -f --tail=100 parse-video ;;
        4) docker logs -f --tail=100 cloudflared-tunnel ;;
        5) cd /opt/parse-video && docker compose restart && docker restart cloudflared-tunnel ;;
        6) cd /opt/parse-video && docker compose pull && docker compose up -d --force-recreate ;;
        7) cd /opt/parse-video && docker compose down && docker stop cloudflared-tunnel && docker rm cloudflared-tunnel ;;
        8) read -p "确认卸载全部服务？[y/N]: " confirm && [[ "$confirm" == "y" ]] && cd /opt/parse-video && docker compose down && docker stop cloudflared-tunnel && docker rm cloudflared-tunnel && rm -rf /opt/parse-video /usr/local/bin/qsy && echo "已完全卸载！" && exit 0 ;;
        0) exit 0 ;;
        *) echo "无效选择！" ;;
    esac
    read -p "按回车键继续..."
done
EOF

chmod +x /usr/local/bin/qsy

echo -e "${GREEN}==========================================${PLAIN}"
echo -e "${GREEN}       🎉 安装与配置全部完成！            ${PLAIN}"
echo -e "${GREEN}==========================================${PLAIN}"
echo -e "🔗 绑定域名: ${GREEN}${CUSTOM_DOMAIN}${PLAIN}"
echo -e "🌐 本地端口: ${GREEN}${CUSTOM_PORT}${PLAIN}"
echo -e "📍 服务器IP: ${GREEN}${PUBLIC_IP}${PLAIN}"
echo -e "💡 随时在终端输入 ${YELLOW}qsy${PLAIN} 即可管理服务或查看配置！"
