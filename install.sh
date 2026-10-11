#!/bin/bash

# 确保以 root 权限运行
if [ "$EUID" -ne 0 ]; then
  echo "[-] 请使用 root 权限运行此脚本 (使用 sudo bash 或切换 root)"
  exit 1
fi

WORK_DIR="/opt/parse-video"

install_main() {
    clear
    echo "=================================================="
    echo "   短视频解析 (Parse-Video) + CF Tunnel 一键部署    "
    echo "=================================================="

    # 1. 检查并安装 Docker
    if ! command -v docker &> /dev/null; then
        echo "[+] 检测到未安装 Docker，正在自动安装..."
        apt-get update && apt-get install -y curl docker.io docker-compose || yum install -y curl docker docker-compose
        systemctl start docker
        systemctl enable docker
    else
        echo "[✓] Docker 已安装"
    fi

    # 2. 交互式输入 Cloudflare Tunnel Token
    echo ""
    echo "--------------------------------------------------"
    echo "请前往 Cloudflare Zero Trust 后台 -> Tunnels 复制 Token"
    echo "--------------------------------------------------"
    read -p "请输入你的 Cloudflare Tunnel Token: " CF_TOKEN

    if [ -z "$CF_TOKEN" ]; then
        echo "[-] 错误：Token 不能为空！"
        exit 1
    fi

    # 3. 交互式输入自定义本地端口（默认 8080）
    echo ""
    echo "--------------------------------------------------"
    echo "请设置本地访问端口（NAT 小鸡可填服务商分配给你的公网映射端口）"
    echo "--------------------------------------------------"
    read -p "请输入自定义端口 [默认 8080]: " CUSTOM_PORT
    
    CUSTOM_PORT=${CUSTOM_PORT:-8080}
    echo "[✓] 已选择本地端口: ${CUSTOM_PORT}"

    # 4. 自动创建目录与配置文件
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR" || exit

    echo "[+] 正在生成 Docker Compose 配置文件..."
    cat <<DOCKEREOF > docker-compose.yml
services:
  parse-video:
    image: wujunwei928/parse-video:latest
    container_name: parse-video
    restart: always
    ports:
      - "${CUSTOM_PORT}:8080"
    networks:
      - app-net

  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    restart: always
    command: tunnel --no-autoupdate run --token ${CF_TOKEN}
    networks:
      - app-net
    depends_on:
      - parse-video

networks:
  app-net:
    driver: bridge
DOCKEREOF

    # 5. 拉取镜像并启动
    echo "[+] 正在拉取 Docker 镜像并启动服务..."
    docker compose down 2>/dev/null
    docker compose up -d

    # 6. 创建全局快捷命令 qsy（内置在线更新功能）
    cat << 'EOF' > /usr/local/bin/qsy
#!/bin/bash
WORK_DIR="/opt/parse-video"
while true; do
    clear
    echo "=================================================="
    echo "        短视频解析 (Parse-Video) 管理面板         "
    echo "=================================================="
    echo " 1. 查看容器运行状态 (docker ps)"
    echo " 2. 查看实时运行日志 (Logs)"
    echo " 3. 更新解析项目 (Update to Latest)"
    echo " 4. 重启服务 (Restart)"
    echo " 5. 停止服务 (Stop)"
    echo " 6. 卸载并清理全部配置 (Uninstall)"
    echo " 0. 退出菜单"
    echo "=================================================="
    read -p "请输入选项 [0-6]: " menu_choice
    case $menu_choice in
        1)
            docker ps -a --filter name=parse-video --filter name=cloudflared
            read -p "按回车键继续..."
            ;;
        2)
            echo "=== 正在查看日志 (按 Ctrl+C 退出日志) ==="
            cd "$WORK_DIR" && docker compose logs -f
            ;;
        3)
            echo "[+] 正在检查并更新 parse-video 镜像..."
            cd "$WORK_DIR" || exit
            # 仅拉取并更新解析镜像，不影响 Cloudflare 隧道和配置文件
            docker compose pull parse-video
            docker compose up -d --no-deps parse-video
            echo "[✓] 项目更新完成！"
            read -p "按回车键继续..."
            ;;
        4)
            echo "[+] 正在重启服务..."
            cd "$WORK_DIR" && docker compose restart
            sleep 2
            ;;
        5)
            echo "[+] 正在停止服务..."
            cd "$WORK_DIR" && docker compose stop
            sleep 2
            ;;
        6)
            read -p "确认卸载并删除所有配置？[y/N]: " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                cd "$WORK_DIR" && docker compose down
                rm -rf "$WORK_DIR"
                rm -f /usr/local/bin/qsy
                echo "[✓] 卸载完成，全局快捷命令已移除。"
                exit 0
            fi
            ;;
        0)
            exit 0
            ;;
        *)
            echo "无效选项，请重新输入"
            sleep 1
            ;;
    esac
done
EOF
    chmod +x /usr/local/bin/qsy

    echo ""
    echo "=================================================="
    echo "              [!] 部署全部完成！                  "
    echo "=================================================="
    echo " 1. 服务已成功启动，本地端口映射为: ${CUSTOM_PORT}"
    echo " 2. Cloudflare 后台 Public Hostname 指向: http://parse-video:8080"
    echo " 3. 【全新升级】以后在终端输入: qsy"
    echo "    即可呼出菜单，选择【选项 3】一键在线更新项目！"
    echo "=================================================="
}

install_main