## Tmux 配置环境

> [tmux](https://github.com/tmux/tmux) 是一个终端复用器（terminal multiplexer）：在一个终端窗口里管理多个会话、窗口和窗格，断开连接后任务仍在后台运行，重新 attach 即可恢复现场。非常适合 SSH 远程开发、长时间跑任务。

本目录的 [tmux.conf](tmux.conf) 基于 tmux 原生配置，并集成了 [TPM](https://github.com/tmux-plugins/tpm)（Tmux Plugin Manager）插件管理器，使用 [Catppuccin](https://github.com/catppuccin/tmux) 主题美化状态栏与窗口标签。

### 安装的插件

| 插件 | 作用 |
|------|------|
| `catppuccin/tmux` | Catppuccin 主题：状态栏、窗口标签配色美化（默认 mocha 深色） |
| `tmux-plugins/tmux-cpu` | 状态栏显示 CPU 占用 |
| `tmux-plugins/tmux-battery` | 状态栏显示电池电量 |
| `tmux-plugins/tmux-yank` | 复制内容到系统剪贴板（`Prefix + y`） |

### 安装 tmux

| 系统 | 安装命令 |
|------|---------|
| Arch Linux / Manjaro | `sudo pacman -S tmux` |
| Debian / Ubuntu | `sudo apt-get install tmux` |
| Fedora | `sudo dnf install tmux` |
| macOS / Linux (Homebrew) | `brew install tmux` |

### 手动创建软链接

tmux 默认读取 `~/.tmux.conf`，将本仓库的配置软链接过去即可：

```bash
# 若 ~/.tmux.conf 已存在，请先备份：mv ~/.tmux.conf ~/.tmux.conf.bak
ln -s ~/dotfiles/tmux/tmux.conf ~/.tmux.conf
```

> **注意**：`tmux.conf` 中 `run '~/.tmux/plugins/tpm/tpm'` 硬编码了 TPM 的默认路径，因此**建议将配置软链接到 `~/.tmux.conf`**，并使用下文的默认插件路径方案。若坚持使用 tmux 3.1+ 的 XDG 路径 `~/.config/tmux/tmux.conf`，需同步将配置最后一行改为 `run '~/.config/tmux/plugins/tpm/tpm'`（此时 TPM 插件目录也会自动变为 `~/.config/tmux/plugins/`）。

### 使用 TPM 安装插件（完整步骤）

#### 第 1 步：克隆 TPM 到默认路径

国内网络优先使用 Gitee 镜像，连不上时回退 GitHub 官方源：

```bash
# 国内镜像（推荐）
git clone --depth=1 https://gitee.com/github_dep/tpm.git ~/.tmux/plugins/tpm

# 国际源（国内镜像失败时使用）
git clone --depth=1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

#### 第 2 步：软链接配置文件（若尚未执行）

```bash
ln -s ~/dotfiles/tmux/tmux.conf ~/.tmux.conf
```

#### 第 3 步：启动 tmux 并安装插件

```bash
tmux
```

进入 tmux 后按 **`Prefix + I`**（大写 I，先按 `Ctrl+b` 松开再按 `I`），TPM 会逐个克隆 `tmux.conf` 中声明的插件到 `~/.tmux/plugins/`，完成后提示 `done` 并自动重载配置。

#### 第 4 步（可选）：安装 Nerd Font 字体

Catppuccin 主题的状态栏图标依赖 [Nerd Font](https://www.nerdfonts.com/)，否则图标可能显示为乱码方块：

```bash
# Arch Linux
sudo pacman -S ttf-jetbrains-mono-nerd

# Fedora
sudo dnf install google-noto-sans-mono-nerd-fonts-common

# Debian / Ubuntu（手动下载）
wget https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
unzip JetBrainsMono.zip -d ~/.local/share/fonts/ && fc-cache -fv
```

安装后在终端设置中将字体切换为对应的 Nerd Font（如 `JetBrainsMono Nerd Font`）。

### TPM 快捷键

| 快捷键 | 功能 |
|--------|------|
| `Prefix + I` | 安装 / 重装 tmux.conf 中声明的插件 |
| `Prefix + U` | 更新插件（可多选） |
| `Prefix + Alt + u` | 清理已不再使用的插件 |

### 插件下载源说明

TPM 本体有 Gitee 国内镜像（见上文第 1 步），但配置中引用的 4 个**插件仓库目前均无现成的 Gitee 镜像**，`Prefix + I` 安装插件时默认走 **GitHub**（TPM 会将 `owner/repo` 拼接为 `https://github.com/<owner>/<repo>` 后克隆）。

国内网络下载插件失败（`Prefix + I` 提示 `download fail`）时，推荐如下解决方式：

**方法一：在 Gitee 导入 GitHub 仓库，再用完整 Git URL 声明插件**。Gitee 支持「从已有地址导入仓库」（新建仓库 → 导入仓库 → 填写 GitHub 地址）。为需要的插件建好个人镜像后，把 `tmux.conf` 中对应声明改为完整 URL 即可——TPM 对 `@plugin` 会先尝试将其作为 Git 地址直接克隆，失败才拼接 GitHub 前缀：

```bash
set -g @plugin 'https://gitee.com/<你的账号>/tmux.git'          # catppuccin/tmux
set -g @plugin 'https://gitee.com/<你的账号>/tmux-cpu.git'
set -g @plugin 'https://gitee.com/<你的账号>/tmux-battery.git'
set -g @plugin 'https://gitee.com/<你的账号>/tmux-yank.git'
```

修改后按 `Prefix + I` 安装生效。

**方法二：手动克隆插件到 TPM 插件目录**。插件目录名必须与仓库同名，克隆后在 tmux 内按 `Prefix + r` 重载：

```bash
mkdir -p ~/.tmux/plugins
cd ~/.tmux/plugins

git clone --depth=1 <镜像或GitHub地址> tmux          # catppuccin/tmux
git clone --depth=1 <镜像或GitHub地址> tmux-cpu
git clone --depth=1 <镜像或GitHub地址> tmux-battery
git clone --depth=1 <镜像或GitHub地址> tmux-yank
```

> 若 `tmux.conf` 中的 `@plugin` 声明保持 `owner/repo` 形式不变，手动克隆也完全有效——TPM 检测到目录已存在会直接跳过网络安装。

### 使配置生效

```bash
# 已有 tmux 会话中重载（本配置绑定了 Prefix + r）
tmux source-file ~/.tmux.conf

# 或在 tmux 内按 Prefix + r，会提示 "Config reloaded!"
```

新启动的 tmux 会话会自动加载配置。

### 配置亮点

- **Catppuccin Mocha 主题**：圆角窗口标签、图标化状态栏模块（会话 / 程序 / CPU / 电池 / 日期时间）
- **256 色 + RGB 真彩色**支持（`tmux-256color` + `xterm-256color:RGB`）
- **Escape 零延迟**（`escape-time 0`），Vim/Neovim 中按 Esc 不再卡顿
- **鼠标支持**：滚轮翻页、点击切换窗格、拖拽调整窗格大小
- **50000 行**历史回滚，看日志更从容
- 窗口/窗格编号**从 1 开始**，关闭窗口后自动重排编号
- 分屏、新建窗口**继承当前目录**
- **Vi 风格**复制模式与窗格操作
- **tmux-yank**：复制内容直达系统剪贴板

### 主题切换

Catppuccin 提供 4 种配色，修改 `tmux.conf` 中的 `@catppuccin_flavor` 后按 `Prefix + r` 重载即可：

| 取值 | 风格 |
|------|------|
| `latte` | 浅色 |
| `frappe` | 柔和深色 |
| `macchiato` | 中深色 |
| `mocha` | 最深（默认） |

```bash
set -g @catppuccin_flavor 'mocha'
```

### 快捷键速查

前缀键（Prefix）为默认的 `Ctrl+b`，下表 `Prefix + x` 表示先按 `Ctrl+b` 松开再按 `x`。

#### 窗格与窗口

| 快捷键 | 功能 |
|--------|------|
| `Prefix + \|` | 左右分屏（继承当前目录） |
| `Prefix + -` | 上下分屏（继承当前目录） |
| `Prefix + c` | 新建窗口（继承当前目录） |
| `Prefix + h / j / k / l` | Vim 风格切换窗格（左/下/上/右，可长按连续移动） |
| `Prefix + H / J / K / L` | 调整窗格大小（每次 5 格，可长按连续调整） |
| `Prefix + r` | 重载配置文件 |
| `Prefix + y` | 复制 tmux 缓冲区内容到系统剪贴板（tmux-yank） |

> 原生的 `Prefix + "`（上下分屏）和 `Prefix + %`（左右分屏）已被替换为更直观的 `-` 和 `|`。

#### 复制模式（Vi 风格）

| 快捷键 | 功能 |
|--------|------|
| `Prefix + [` | 进入复制模式（可用方向键 / `hjkl` 移动，`q` 退出） |
| `v` | 开始选择 |
| `y` | 复制选中内容到系统剪贴板并退出复制模式 |

开启鼠标后，也可以直接用滚轮进入复制模式翻页、鼠标拖选。

#### 常用原生操作（未改动）

| 快捷键 / 命令 | 功能 |
|--------|------|
| `Prefix + d` | 脱离（detach）当前会话，任务继续后台运行 |
| `Prefix + s` | 列出并切换会话 |
| `Prefix + ,` | 重命名当前窗口 |
| `Prefix + 数字` | 跳转到对应编号窗口 |
| `tmux new -s 名称` | 新建命名会话 |
| `tmux attach -t 名称` | 恢复会话 |
| `tmux ls` | 列出所有会话 |

### 常见问题

**Q：启动 tmux 状态栏没有颜色 / 显示 `{E:@catppuccin_status_session}` 之类的原始文本？**
A：插件尚未安装或未被加载。确认已完成 TPM 克隆（第 1 步），进入 tmux 按 `Prefix + I` 安装插件，或手动克隆后按 `Prefix + r` 重载。

**Q：状态栏图标显示为乱码方块？**
A：终端字体不含图标字符，安装 Nerd Font 并在终端设置中切换（见第 4 步）。不影响功能使用。

**Q：`Prefix + I` 提示插件 `download fail`？**
A：GitHub 不可达，参照「插件下载源说明」手动从镜像克隆或改用完整 Git URL。

**Q：电池模块不显示？**
A：台式机等无电池设备上 `tmux-battery` 会显示为空，属正常现象。
