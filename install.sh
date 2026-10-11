#!/bin/bash

# ==========================================
# 终极防崩溃自引导：自动抵抗 Windows 换行符并接管终端
# ==========================================
if [ -t 0 ] && [ -z "$_QSY_RE-EXEC" ]; then
    if grep -q -U $'\r' "$0" 2>/dev/null || file "$0" 2>/dev/null | grep -q "CRLF"; then
        export _QSY_RE-EXEC=1
        tr -d '\r' < "$0" > "$0.clean" && exec bash "$0.clean" "$@"
    fi
elif [ ! -t 0 ]; then
    _TEMP_SH="/tmp/qsy_install_$$.sh"
    curl -sL "https://raw.githubusercontent.com/lixianus/qu-shui-yin/refs/heads/main/install.sh" -o "$_TEMP_SH" 2>/dev/null || wget -q "https://raw.githubusercontent.com/lixianus/qu-shui-yin/refs/heads/main/install.sh" -O "$_TEMP_SH" 2>/dev/null
    tr -d '\r' < "$_TEMP_SH" > "${_TEMP_SH}.clean"
    chmod +x "${_TEMP_SH}.clean"
    exec bash "${_TEMP_SH}.clean" < /dev/tty
    exit 0
fi

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

    # 5. 交互式输入绑定域名（用于防封和直接访问）
    echo ""
    echo "--------------------------------------------------"
    echo "请输入绑定的解析域名 (例如: qsy.keaiduo.kdns.fr)"
    echo "（注：需确保该域名已托管在 Cloudflare 账号下）"
    echo "--------------------------------------------------"
    read -p "请输入你的绑定域名: " CUSTOM_DOMAIN

    if [ -z "$CUSTOM_DOMAIN" ]; then
        echo "[-] 提示：未输入域名，后续需手动在 CF 后台绑定 Public Hostname。"
        CUSTOM_DOMAIN="未绑定域名"
    else
        echo "[✓] 已绑定域名: ${CUSTOM_DOMAIN}"
    fi

    # 6. 创建工作目录与配置文件
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

    # 7. 拉取镜像并启动（使用强制重建确保隧道容器顺利激活）
    echo "[+] 正在拉取 Docker 镜像并启动服务..."
    docker compose down 2>/dev/null || docker-compose down 2>/dev/null
    docker compose up -d --force-recreate 2>/dev/null || docker-compose up -d --force-recreate 2>/dev/null

    # 8. 创建增强版全局快捷命令 qsy（内置一键修复与日志排查菜单）
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
    echo " 3. 一键强制重建并修复隧道 (Force Recreate Containers)"
    echo " 4. 更新解析项目 (Update to Latest)"
    echo " 5. 重启服务 (Restart)"
    echo " 6. 停止服务 (Stop)"
    echo " 7. 卸载并清理全部配置 (Uninstall)"
    echo " 0. 退出菜单"
    echo "=================================================="
    read -p "请输入选项 [0-7]: " menu_choice
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
            echo "[+] 正在清理并强制重新创建容器（解决隧道未启动问题）..."
            cd "$WORK_DIR" || exit
            docker compose down 2>/dev/null || docker-compose down 2>/dev/null
            docker compose up -d --force-recreate 2>/dev/null || docker-compose up -d --force-recreate 2>/dev/null
            echo "[✓] 隧道与应用容器已强制重建并启动！"
            read -p "按回车键继续..."
            ;;
        4)
            echo "[+] 正在检查并更新 parse-video 镜像..."
            cd "$WORK_DIR" || exit
            docker compose pull parse-video 2>/dev/null || docker-compose pull parse-video
            docker compose up -d --no-deps parse-video 2>/dev/null || docker-compose up -d --no-deps parse-video
            echo "[✓] 项目更新完成！"
            read -p "按回车键继续..."
            ;;
        5)
            echo "[+] 正在重启服务..."
            cd "$WORK_DIR" && (docker compose restart 2>/dev/null || docker-compose restart)
            sleep 2
            ;;
        6)
            echo "[+] 正在停止服务..."
            cd "$WORK_DIR" && (docker compose stop 2>/dev/null || docker-compose stop)
            sleep 2
            ;;
        7)
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
    echo " 1. 本地服务映射端口: ${CUSTOM_PORT}"
    echo " 2. 绑定的访问域名:   https://${CUSTOM_DOMAIN}"
    echo " 3. Cloudflare 后台 Public Hostname 指向地址:"
    echo "    http://parse-video:8080"
    echo " ------------------------------------------------"
    echo " 💡 以后在终端随时输入: qsy"
    echo "    即可呼出菜单进行查看、一键重建修复或在线更新！"
    echo "=================================================="
}

install_main
