这次直接为你去除所有的包裹与特殊格式干扰，确保在 GitHub 编辑器里粘贴即呈现**无缝完美排版**！

请直接复制以下下方**所有文本**粘贴到 GitHub 的 `README.md` 中：

# 🎬 在线短视频去水印解析 (Parse-Video) + Cloudflare Tunnel 一键部署工具

基于 Go 语言开发的强大短视频去水印解析面板，支持跨平台（Ubuntu、Debian、Alpine Linux），完美集成 Cloudflare 隧道穿透，实现安全、免服务器公网 IP、防封防墙的 HTTPS 访问。

---

## 📋 目前支持平台

抖音 / 皮皮虾 / 火山 / 微视 / 最右 / 快手 / 全民小视频 / 皮皮搞笑 / 梨视频 / 西瓜 / 微博 / 虎牙 / 绿洲 / 好看 / 逗拍 / 美拍 / 新片场 / A站 / 全民K歌 / 6间房

---

## ✨ 项目特点

* 🚀 **全自动一键安装**：智能识别系统环境（`apt` / `apk`），自动配置 Docker 与核心依赖。
* 🛡️ **双重防错自引导**：内置终端接管与 Windows 换行符（CRLF / `\r`）实时清洗机制，彻底告别管道执行报错。
* 🌐 **Cloudflare 隧道穿透**：通过独立高可用 `cloudflared` 容器挂载，安全直连，告别繁琐端口映射。
* 🛠️ **便捷管理面板（`qsy`）**：全局内置快捷管理命令，支持独立日志查看、一键强制重建、项目更新与完全卸载。

---

## 📥 一键安装命令

在你的 Linux 服务器（Ubuntu / Debian / Alpine）上以 **root** 权限执行以下一行命令即可：

```bash
bash <(curl -sL https://raw.githubusercontent.com/lixianus/qu-shui-yin/refs/heads/main/install.sh | tr -d '\r')

```

### 💡 安装过程中的交互提示：

1. **Cloudflare Tunnel Token**：前往 Cloudflare Zero Trust 后台 -> Tunnels 复制专用的 Token 密钥。
2. **自定义本地端口**：设置容器映射端口（默认 `8080`，NAT 小鸡可填写服务商分配的公网映射端口）。
3. **绑定访问域名**：输入你的专属解析域名（例如 `qsy.keaiduo.kdns.fr`，需托管在 Cloudflare 账号下）。

---

## 🧰 全局日常管理命令

安装完成后，在任意终端输入全局快捷命令即可呼出管理面板：

```bash
qsy

```

**面板功能菜单：**

* `1` - 查看容器运行状态 (`docker ps`)
* `2` - 查看解析主服务日志 (`parse-video logs`)
* `3` - 查看隧道连接日志 (`cloudflared logs`)
* `4` - 一键强制重启/修复全部服务 (`Restart & Fix`)
* `5` - 更新解析项目到最新版 (`Update to Latest`)
* `6` - 停止全部服务 (`Stop`)
* `7` - 卸载并清理全部配置 (`Uninstall`)
* `0` - 退出菜单

---

## ⚠️ 常见排查与避坑指南（FAQ）

### 1. 访问网页提示 `Error 1033 (Cloudflare Tunnel error)`？

* **原因**：Cloudflare 边缘节点无法连接到本地的 `cloudflared` 隧道客户端。
* **排查与解决**：
1. 在终端输入 `qsy`，选择 **`3`** 查看隧道日志，检查 Token 是否填写正确。
2. 确保在 Cloudflare Zero Trust 后台配置 **Public Hostname** 时，**Service（服务地址）** 的填写正确：
* 格式应填写为：`http://你的服务器IP:端口`（例如 `[http://88.218.102.123:12345]([http://8.220.214.167:23456]([http://88.218.102.123:12345](http://88.218.102.123:12345)))`）。
* **注意**：切勿填写 `http://localhost:...` 或 `[http://127.0.0.1](http://127.0.0.1):...`（Docker 隔离网络无法识别宿主机本地）。





### 2. 执行脚本时提示 `/dev/fd/xx: line ... $\r': command not found`？

* **原因**：由于在 Windows 环境下编辑或保存了 `.sh` 脚本，导致文件被沾染了隐藏的 Windows 换行符（CRLF）。
* **解决**：安装命令中已经强制加入了 `| tr -d '\r'` 管道清洗，请确保复制的是带有清洗逻辑的标准一键命令。

---

## 📌 温馨提示

1. 粘贴视频地址时**无需删除文案**，但如果视频链接正确却解析失败，请尝试删掉多余文案后重试。
2. 点击下载视频跳转时，可能会被对应网站识别报 `403 Forbidden`。此时可以在 **下载视频** 按钮上**右键复制链接地址**，在浏览器新标签页中打开即可正常下载。
