# 🎬 在线短视频去水印解析 (Parse-Video) + Cloudflare Tunnel 一键部署工具

基于 Go 语言开发的强大短视频去水印解析面板，支持跨平台（Ubuntu、Debian、Alpine Linux），完美集成 Cloudflare 隧道穿透，实现安全、免服务器公网 IP、防封防墙的 HTTPS 访问。

---

## 📋 目前支持平台
抖音 / 皮皮虾 / 火山 / 微视 / 最右 / 快手 / 全民小视频 / 皮皮搞笑 / 梨视频 / 西瓜 / 微博 / 虎牙 / 绿洲 / 好看 / 逗拍 / 美拍 / 新片场 / A站 / 全民K歌 / 6间房

---

## ✨ 项目特点
- 🚀 **全自动一键安装**：智能识别系统环境（`apt` / `apk`），自动配置 Docker 与核心依赖。
- 🛡️ **双重防错自引导**：内置终端接管与 Windows 换行符（CRLF / `\r`）实时清洗机制，彻底告别管道执行报错。
- 🌐 **Cloudflare 隧道穿透**：通过独立高可用 `cloudflared` 容器挂载，安全直连，告别繁琐端口映射。
- 🛠️ **便捷管理面板（`qsy`）**：全局内置快捷管理命令，支持独立日志查看、一键强制重建、项目更新与完全卸载。

---

## 📥 一键安装命令

在你的 Linux 服务器（Ubuntu / Debian / Alpine）上以 **root** 权限执行以下一行命令即可：

```bash
bash <(curl -sL https://raw.githubusercontent.com/lixianus/qu-shui-yin/refs/heads/main/install.sh | tr -d '\r')
