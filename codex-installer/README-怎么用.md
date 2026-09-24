# Codex 中文一键安装器 · 怎么用

> 1.0.0 · 2026-09-24 · **未发布**（没上传 CDN、没推 GitHub、网站没挂）。照「Claude Code 中文一键安装器」（2026-09-23 已上线）改出来的 Codex 版。

**装完能干嘛**：桌面多出一个「打开 Codex」图标。双击它，就在「Codex工作区」文件夹里打开 OpenAI 官方的 AI 编程助手 Codex；第一次选「Sign in with ChatGPT」，浏览器登录 ChatGPT 账号就能用。

## 三步用法

### Windows
1. 把压缩包**全部解压**（右键 → 全部解压缩），别在压缩包里直接双击
2. 双击「**双击安装.bat**」。如果弹出蓝色的「Windows 已保护你的电脑」：点「**更多信息**」→「**仍要运行**」
3. 等它跑完（3～10 分钟），回桌面双击「**打开 Codex**」

### Mac
1. 双击压缩包解压
2. **右键**点「**双击安装.command**」→「打开」→ 再点「打开」。如果提示「无法验证开发者」：打开「系统设置 → 隐私与安全性」，拉到底点「**仍要打开**」
3. 等它跑完（3～10 分钟），回桌面双击「**打开 Codex**」

## 官方安装方式核实（2026-09-24 联网核实，不凭印象）

| 项 | 官方结论 | 出处 |
|---|---|---|
| npm 包名 | `@openai/codex`，装法 `npm install -g @openai/codex`；9-24 最新 0.156.1，许可证 Apache-2.0 | github.com/openai/codex README；registry.npmjs.org/@openai/codex/latest |
| Node 最低版本 | package.json `engines.node` = `>=16`（本安装器取 18 以上，没有就装 LTS） | registry.npmjs.org/@openai/codex/latest |
| 安装脚本（有无 postinstall） | 主包和平台包（win32-x64 / darwin-arm64 等）都**没有** install 脚本；程序本体在按平台拆开的可选依赖里（win32-x64 解压后约 440 MB） | 同上 + `@openai/codex@0.156.1-win32-x64` 元数据 |
| 官方安装脚本 | Mac/Linux：`curl -fsSL https://chatgpt.com/codex/install.sh \| sh`；Windows：`powershell -ExecutionPolicy ByPass -c "irm https://chatgpt.com/codex/install.ps1 \| iex"`（两个地址 302 到 releases.openai.com，脚本从 GitHub Release 下载）；装到 Mac `~/.local/bin/codex`、Windows `%LOCALAPPDATA%\Programs\OpenAI\Codex\bin\codex.exe` | github.com/openai/codex README；developers.openai.com/codex/cli（现 308 到 learn.chatgpt.com/docs/codex/cli，页面有 macOS/Linux、Windows、npm、Homebrew 四个安装标签）；脚本原文 |
| Homebrew | `brew install --cask codex` | github.com/openai/codex README |
| 登录 | 第一次运行选「Sign in with ChatGPT」走浏览器；无头环境 `codex login --device-auth`；也可 API key（`codex login --with-api-key`）；凭证存 `~/.codex/auth.json` 或系统钥匙串 | learn.chatgpt.com/docs/codex/cli；learn.chatgpt.com/docs/auth |
| 启动命令 | 在项目文件夹里运行 `codex` | 同上 |
| 哪些账号能用 | 官方原文：「ChatGPT Work and Codex are included in your ChatGPT Free, Go, Plus, Pro, Business, Edu, or Enterprise plan」——**免费版也包含，只是额度少**；所以文案写「常用建议 Plus / Pro」，不写「必须 Plus」 | learn.chatgpt.com/docs/pricing |
| CC Switch 支不支持 Codex | 支持。官方 README：「Manage Claude Code, Claude Desktop, Codex, Gemini CLI, … from a single interface」 | github.com/farion1231/cc-switch README |

## 装了什么、装在哪（不要管理员密码，不改系统）

| 东西 | 什么时候装 | Windows 装到 | Mac 装到 |
|---|---|---|---|
| Node.js LTS | 电脑上没有 18 以上版本时 | `%LOCALAPPDATA%\Programs\lingji-node\` | `~/.local/share/lingji-node/`（命令链接到 `~/.local/bin`） |
| Codex（官方 npm 包 @openai/codex） | 没装过时 | npm 全局目录（我们装的 Node 就在 Node 目录里） | `~/.local/bin/codex` |
| CC Switch（**可选，默认不装**） | `config.json` 里 `cc_switch.enabled` 改成 `true` 才装 | `%LOCALAPPDATA%\Programs\CC-Switch\` | `~/Applications/CC Switch.app` |
| 桌面图标 | 桌面上还没有时 | `打开 Codex.lnk`（先存英文临时名再改中文名，文件真存在才报成功） | `打开 Codex.command` |
| 工作文件夹 | — | `%USERPROFILE%\Codex工作区` | `~/Codex工作区` |

已经装过的会自动跳过，重复双击不会重复装。安装日志：Windows `%LOCALAPPDATA%\Codex中文安装器.log`，Mac `~/Library/Logs/Codex中文安装器.log`。
**不预填任何 key，不改 `~/.codex` 配置，不内置任何代理 / 翻墙。**

## 下载走哪里
- Node.js：先国内镜像 `npmmirror.com/mirrors/node`，失败再官方 `nodejs.org/dist`
- Codex：先国内 npm 镜像 `registry.npmmirror.com`（9-24 核实平台包在镜像上可下），失败再官方脚本 `chatgpt.com/codex/install.sh` / `install.ps1`（要能打开 GitHub）
- CC Switch（可选）：原作者 GitHub Release

## 为什么 CC Switch 默认关
Codex 默认用 ChatGPT 账号登录，不需要它；桌面多一个图标对小白是负担，也跟「ChatGPT Plus 充值」的推广方向打架。用中转 key 的用户，把 `cc_switch.enabled` 改成 `true` 重新双击即可。

## 从 Claude Code 版吸取的坑（都已带上）
- npm 新版会拦安装后脚本：命令带 `--allow-scripts=@openai/codex`（Codex 目前没有安装脚本，只为以后加了不出事）
- 桌面文件夹不存在：两个系统都先建再放图标
- 中文名快捷方式：先存英文临时名再改名，`.lnk` 真存在才报成功；测试脚本回读 `.lnk` 也先复制成英文名
- Windows 测试步骤用 `shell: pwsh`
- Mac 脚本里 `$变量` 后面紧跟中文会被 bash 吞变量名：一律写 `${变量}`（本次 DryRun 当场抓到一处，已修）
- 演练模式和「已装过」分支都**不运行** codex（只报路径），真装才跑 `codex --version`

## 测试开关（普通用户用不到）
- Mac：`./双击安装.command --dry-run [--pretend-fresh] [--no-pause]`
- Windows：`双击安装.bat -DryRun [-PretendFresh] [-NoPause]`
- 云端真机测试：`repo/.github/workflows/installer-test.yml`（手动触发，未推送）

## 重新打包
`python3 build_pack.py [云端桌面截图.png]` → 生成 `codex-installer-{windows,mac}-happyai-v1.0.0.zip`（七件套：01 先看我 / 02 必看海报 / 03 长图 / 04 官网快捷方式 / 05 ChatGPT Plus 充值快捷方式 / 06 关于 / 安装器）。
