#!/bin/bash

# ==========================================
# 🎬 短视频去水印解析 + Cloudflare Tunnel 一键安装脚本
# ==========================================

# 1. 配置你自己的独立镜像地址（防删库核心）
IMAGE_NAME="ghcr.io/lixianus/qu-shui-yin:latest"

# 2. 引导用户输入端口和 Tunnel Token
read -p "请输入服务映射端口 [默认 8080]: " CUSTOM_PORT
CUSTOM_PORT=${CUSTOM_PORT:-8080}

read -p "请输入你的 Cloudflare Tunnel Token: " CF_TOKEN
if [ -z "$CF_TOKEN" ]; then
    echo "错误：Cloudflare Tunnel Token 不能为空！"
    exit 1
fi

# 3. 创建工作目录
INSTALL_DIR="/opt/parse-video"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# 4. 编写 Docker Compose（使用你自己的独立镜像）
cat <<EOF > docker-compose.yml
services:
  parse-video:
    image: ${IMAGE_NAME}
    container_name: parse-video
    restart: always
    ports:
      - "${CUSTOM_PORT}:8080"
EOF

# 启动主服务
docker compose up -d

# 5. 独立高可用部署 cloudflared 容器（解决 1033 错误）
docker stop cloudflared-tunnel 2>/dev/null
docker rm cloudflared-tunnel 2>/dev/null
docker run -d \
  --name cloudflared-tunnel \
  --restart always \
  cloudflare/cloudflared:latest tunnel --no-autoupdate run --token "$CF_TOKEN"

# 6. 生成全功能 qsy 快捷管理命令
cat << 'EOF' > /usr/local/bin/qsy
#!/bin/bash
while true; do
    clear
    echo "=========================================="
    echo "       qsy 快捷管理面板 (高可用版)       "
    echo "=========================================="
    echo "1. 查看容器运行状态 (docker ps)"
    echo "2. 查看解析主服务日志 (parse-video logs)"
    echo "3. 查看隧道连接日志 (cloudflared logs)"
    echo "4. 一键强制重启与修复服务"
    echo "5. 更新项目到最新版"
    echo "6. 停止全部服务"
    echo "7. 卸载并清理全部配置"
    echo "0. 退出"
    echo "=========================================="
    read -p "请选择操作 [0-7]: " choice
    case $choice in
        1) docker ps ;;
        2) docker logs -f --tail=100 parse-video ;;
        3) docker logs -f --tail=100 cloudflared-tunnel ;;
        4) cd /opt/parse-video && docker compose restart && docker restart cloudflared-tunnel ;;
        5) cd /opt/parse-video && docker compose pull && docker compose up -d --force-recreate ;;
        6) cd /opt/parse-video && docker compose down && docker stop cloudflared-tunnel && docker rm cloudflared-tunnel ;;
        7) read -p "确认卸载全部服务？[y/N]: " confirm && [[ "$confirm" == "y" ]] && cd /opt/parse-video && docker compose down && docker stop cloudflared-tunnel && docker rm cloudflared-tunnel && rm -rf /opt/parse-video /usr/local/bin/qsy && echo "已完全卸载！" ;;
        0) exit 0 ;;
        *) echo "无效选择！" ;;
    esac
    read -p "按回车键继续..."
done
EOF

chmod +x /usr/local/bin/qsy
echo "安装完成！输入 qsy 即可随时管理服务。"