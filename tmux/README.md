## Tmux 配置环境

> [tmux](https://github.com/tmux/tmux) 是一个终端复用器（terminal multiplexer）：在一个终端窗口里管理多个会话、窗口和窗格，断开连接后任务仍在后台运行，重新 attach 即可恢复现场。非常适合 SSH 远程开发、长时间跑任务。

本目录的 [tmux.conf](tmux.conf) 为纯原生配置，**不依赖任何插件**，开箱即用。

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

tmux 3.1+ 也支持 XDG 路径 `~/.config/tmux/tmux.conf`，二选一即可（两者同时存在时 `~/.tmux.conf` 优先）：

```bash
mkdir -p ~/.config/tmux
ln -s ~/dotfiles/tmux/tmux.conf ~/.config/tmux/tmux.conf
```

### 使配置生效

```bash
# 已有 tmux 会话中重载（本配置绑定了 Prefix + r）
tmux source-file ~/.tmux.conf

# 或在 tmux 内按 Prefix + r，会提示 "Config reloaded!"
```

新启动的 tmux 会话会自动加载配置。

### 配置亮点

- **256 色 + RGB 真彩色**支持（`tmux-256color` + `xterm-256color:RGB`）
- **Escape 零延迟**（`escape-time 0`），Vim/Neovim 中按 Esc 不再卡顿
- **鼠标支持**：滚轮翻页、点击切换窗格、拖拽调整窗格大小
- **50000 行**历史回滚，看日志更从容
- 窗口/窗格编号**从 1 开始**，关闭窗口后自动重排编号
- 分屏、新建窗口**继承当前目录**
- **Vi 风格**复制模式与窗格操作
- 底部状态栏：左侧会话名，右侧日期时间

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

> 原生的 `Prefix + "`（上下分屏）和 `Prefix + %`（左右分屏）已被替换为更直观的 `-` 和 `|`。

#### 复制模式（Vi 风格）

| 快捷键 | 功能 |
|--------|------|
| `Prefix + [` | 进入复制模式（可用方向键 / `hjkl` 移动，`q` 退出） |
| `v` | 开始选择 |
| `y` | 复制选中内容并退出复制模式 |

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
