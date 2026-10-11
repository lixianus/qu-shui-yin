<div align="center">

# 🎬 Qu-Shui-Yin
### 短视频去水印解析一键部署工具（适配 NAT 小鸡与普通 VPS）

<p>
  <a href="https://github.com/wujunwei928/parse-video"><img src="https://img.shields.io/badge/Base_Project-parse--video-blue" alt="Base Project"></a>
  <a href="https://www.docker.com/"><img src="https://img.shields.io/badge/Docker-Enabled-2496ED?logo=docker&logoColor=white" alt="Docker"></a>
  <a href="https://www.cloudflare.com/"><img src="https://img.shields.io/badge/Cloudflare-Tunnel-F38020?logo=cloudflare&logoColor=white" alt="Cloudflare"></a>
</p>

</div>

---

## 📖 项目简介

本项目基于原作者 [wujunwei928/parse-video](https://github.com/wujunwei928/parse-video) 开发，完美适配 **NAT 小鸡（无独立公网 IPv4）** 或普通 VPS。

通过 **Docker + Cloudflare Tunnel** 的零端口暴露方案，实现安全、免端口映射、自带 HTTPS 的短视频去水印解析服务。同时内置了强大的 `qsy` 快捷可视化管理菜单，支持状态查看、日志跟踪、在线更新与一键卸载。

---

## 🚀 一键安装命令

在你的 VPS 终端（需具备 **Root** 权限）中，直接复制并运行以下命令：

```bash
bash <(curl -sL [https://raw.githubusercontent.com/lixianus/qu-shui-yin/refs/heads/main/install.sh](https://raw.githubusercontent.com/lixianus/qu-shui-yin/refs/heads/main/install.sh))
