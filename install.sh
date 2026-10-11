#!/bin/bash

# 确保以 root 权限运行
if [ "$EUID" -ne 0 ]; then
  echo "[-] 请使用 root 权限运行此脚本 (例如: sudo bash 或切换 root)"
  exit 1
fi

WORK_DIR="/opt/parse-video"

install_main() {
    clear
    echo "=================================================="
    echo "   短视频解析 (Parse-Video) + CF Tunnel 一键部署    "
    echo "=================================================="

    # 1. 智能识别操作系统并安装必要依赖与 Docker
    if [ -f /etc/alpine-release ]; then
        echo "[+] 检测到 Alpine Linux 系统，正在配置环境..."
        apk update >/dev/null 2>&1
        apk add --no-cache bash curl dos2unix docker docker-cli-compose 2>/dev/null || apk add bash curl dos2unix docker docker-compose
        rc-update add docker boot 2>/dev/null
        service docker start 2>/dev/null
    elif [ -f /etc/debian_version ] || [ -f /etc/lsb-release ]; then
        echo "[+] 检测到 Ubuntu / Debian 系统，正在配置环境..."
        apt-get update -y
        apt-get install -y curl dos2unix docker.io docker-compose-v2 2>/dev/null || apt-get install -y curl dos2unix docker.io docker-compose
        systemctl start docker
        systemctl enable docker
    else
        echo "[-] 未知或不支持的 Linux 发行版，尝试基础安装..."
    fi

    # 2. 检查 Docker 是否成功就绪
    if ! command -v docker &> /dev/null; then
        echo "[-] 错误：Docker 安装失败，请手动检查系统环境。"
        exit 1
    else
        echo "[✓] Docker 环境已就绪"
    fi

    # 3. 交互式输入 Cloudflare Tunnel Token
    echo ""
    echo "--------------------------------------------------"
    echo "请前往 Cloudflare Zero Trust 后台 -> Tunnels 复制 Token"
    echo "--------------------------------------------------"
    read -p "请输入你的 Cloudflare Tunnel Token: " CF_TOKEN

    if [ -z "$CF_TOKEN" ]; then
        echo "[-] 错误：Token 不能为空！"
        exit 1
    fi

    # 4. 交互式输入自定义本地端口（默认 8080）
    echo ""
    echo "--------------------------------------------------"
    echo "请设置本地访问端口（NAT 小鸡可填服务商分配给你的公网映射端口）"
    echo "--------------------------------------------------"
    read -p "请输入自定义端口 [默认 8080]: " CUSTOM_PORT
    CUSTOM_PORT=${CUSTOM_PORT:-8080}
    echo "[✓] 已选择本地端口: ${CUSTOM_PORT}"

    # 5. 创建工作目录与配置文件
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

    # 6. 拉取镜像并启动
    echo "[+] 正在拉取 Docker 镜像并启动服务..."
    docker compose down 2>/dev/null || docker-compose down 2>/dev/null
    docker compose up -d 2>/dev/null || docker-compose up -d 2>/dev/null

    # 7. 创建全局快捷命令 qsy
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
            cd "$WORK_DIR" && (docker compose logs -f 2>/dev/null || docker-compose logs -f)
            ;;
        3)
            echo "[+] 正在检查并更新 parse-video 镜像..."
            cd "$WORK_DIR" || exit
            docker compose pull parse-video 2>/dev/null || docker-compose pull parse-video
            docker compose up -d --no-deps parse-video 2>/dev/null || docker-compose up -d --no-deps parse-video
            echo "[✓] 项目更新完成！"
            read -p "按回车键继续..."
            ;;
        4)
            echo "[+] 正在重启服务..."
            cd "$WORK_DIR" && (docker compose restart 2>/dev/null || docker-compose restart)
            sleep 2
            ;;
        5)
            echo "[+] 正在停止服务..."
            cd "$WORK_DIR" && (docker compose stop 2>/dev/null || docker-compose stop)
            sleep 2
            ;;
        6)
            read -p "确认卸载并删除所有配置？[y/N]: " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                cd "$WORK_DIR" && (docker compose down 2>/dev/null || docker-compose down)
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
    echo " 3. 以后在终端随时输入: qsy"
    echo "    即可呼出菜单进行查看、日志排查或在线更新！"
    echo "=================================================="
}

install_main
