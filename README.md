# Dotfiles

个人开发环境配置仓库，用于在新的 Linux / macOS 环境下快速搭建熟悉的命令行工具链。

## Dotfiles 是什么

dotfiles 就是以 `.` 开头的配置文件，如 `.bashrc`、`.vimrc`、`.zshrc` 等。

Linux / macOS 下的各种应用都支持通过配置文件自定义行为（快捷键、变量、主题等）。将这些 dotfiles 存储在 Git 仓库中，换一台电脑时只需拉取仓库并创建软链接，即可快速恢复到熟悉的开发环境。

## 支持的系统

| 系统 | 包管理器 |
|------|---------|
| Arch Linux / Manjaro | pacman |
| Debian / Ubuntu | apt-get |
| Fedora | dnf |
| macOS / Linux | Homebrew |

## 目录结构

| 目录 | 说明 |
|------|------|
| [setup.sh](setup.sh) | 一键汇总安装脚本（换源 / 常见工具 / zsh / vim / tmux） |
| [zsh/](zsh/) | zsh Shell 配置、Oh-My-Zsh、插件、主题 |
| [vim/](vim/) | Vim 编辑器配置与插件 |
| [tmux/](tmux/) | tmux 终端复用器配置（TPM 插件、Catppuccin 主题、分屏与会话管理） |
| [ssh/](ssh/) | SSH 连接配置 |
| [profile/](profile/) | `.profile` 登录 Shell 配置说明 |
| [mirror/](mirror/) | 包管理器国内镜像源切换说明（chsrc / LinuxMirrors / Cmirror） |

## 快速开始

### 一键全量安装（汇总脚本）

根目录的 [setup.sh](setup.sh) 可一次完成 **换源 → 常见工具 → zsh → vim → tmux** 全流程，支持静默与交互两种模式：

```bash
# 交互模式：逐步确认
bash setup.sh

# 静默模式：全部默认执行
bash setup.sh --unattended

# 预演：仅打印将执行的动作，不实际执行
bash setup.sh --dry-run

# 云端直接运行（无需先克隆仓库）
curl -fsSL https://gitee.com/ruanfumin/dotfiles/raw/master/setup.sh | bash
curl -fsSL https://gitee.com/ruanfumin/dotfiles/raw/master/setup.sh | bash -s -- --unattended
```

脚本按顺序执行：
1. **替换国内镜像源** — 默认 chsrc（Gitee 安装、自动测速），可选 LinuxMirrors（`--mirror-tool linuxmirrors`，静默模式需配合 `--mirror-src <镜像域名>`）
2. **安装常见工具** — git、curl、wget、tmux、vim、zsh、lsd、btop（仓库中不存在的包自动逐个重试并告警，不中断流程）
3. **配置 zsh** — 复用 [zsh/auto_install_zsh.sh](zsh/)（Oh-My-Zsh、powerlevel10k、插件、Zinit）
4. **配置 vim** — 复用 [vim/auto_install_vim.sh](vim/)（vim-plug + 全部插件，`--with-ycm` 可选补全引擎）
5. **配置 tmux** — 软链 `tmux.conf`、克隆 TPM（Gitee 镜像优先）、命令行自动安装插件

常用选项：`--no-mirror`、`--no-tools`、`--no-zsh`、`--no-vim`、`--no-tmux` 跳过对应步骤，`-y/--unattended` 静默，`--dry-run` 预演，完整选项见 `bash setup.sh --help`。

> **说明**：root 账户可直接运行（无需 sudo）；换源工具细节见 [mirror/README.md](mirror/)；tmux 插件仓库在 GitHub，网络不通时安装失败可参考 [tmux/README.md](tmux/) 使用加速代理或手动克隆。执行结果会在末尾以汇总表输出，失败步骤可修复后重新运行本脚本。

### 一键安装 ZSH 环境

在新的 Linux / macOS 机器上，运行以下命令即可自动安装完整的 zsh 开发环境：

```bash
sh -c "$(curl -fsSL https://gitee.com/ruanfumin/dotfiles/raw/master/zsh/auto_install_zsh.sh)"
```

安装脚本会自动完成：
1. **检测包管理器** — 支持 pacman、apt-get、dnf、brew
2. **安装依赖** — git、zsh
3. **克隆 dotfiles** — 拉取本仓库并创建 `.zshrc` 软链接
4. **安装 Oh-My-Zsh** — 使用国内 Gitee 镜像
5. **安装 powerlevel10k 主题** — 美观的终端主题
6. **安装插件** — autosuggestions、syntax-highlighting、autocomplete
7. **安装 Zinit** — 插件管理器
8. **设置默认 Shell** — 将 zsh 设为登录 Shell

所有组件优先使用 **Gitee 国内镜像**，国内源不可用时自动回退到 GitHub。

> **提权说明**：支持以 **root 账户直接运行**（无需 sudo，适合容器 / 最小化安装环境）；普通用户运行时自动经 sudo 提权。

### 一键安装 Vim 环境

在新的 Linux / macOS 机器上，运行以下命令即可自动安装完整的 Vim 环境：

```bash
sh -c "$(curl -fsSL https://gitee.com/ruanfumin/dotfiles/raw/master/vim/auto_install_vim.sh)"
```

安装脚本会自动完成：
1. **检测包管理器** — 支持 pacman、apt-get、dnf、brew
2. **安装依赖** — git、vim、fzf
3. **克隆 dotfiles** — 拉取本仓库并创建 `.vimrc` 软链接
4. **安装 vim-plug** — Vim 插件管理器
5. **安装全部插件** — airline、syntastic、fzf、vim-surround、nerdcommenter 等 14 个插件
6. **Vim 启动自检** — 确认配置无报错

所有组件优先使用 **GitCode 国内镜像**，镜像未收录时自动回退 **GitHub 加速代理** 与 **GitHub 直连**。插件安装后 `:PlugUpdate` 也会自动走国内镜像。可选安装 YouCompleteMe 补全引擎（`--with-ycm`），详见 [vim/README.md](vim/README.md)。

### 手动配置软链接

如果只想手动配置某个组件：

```bash
# zsh 配置（若 ~/.zshrc 已存在，请先备份：mv ~/.zshrc ~/.zshrc.bak）
ln -s ~/dotfiles/zsh/zshrc ~/.zshrc

# vim 配置
mkdir -p ~/.vim
ln -s ~/dotfiles/vim/vimrc ~/.vim/vimrc

# tmux 配置（若 ~/.tmux.conf 已存在，请先备份：mv ~/.tmux.conf ~/.tmux.conf.bak）
ln -s ~/dotfiles/tmux/tmux.conf ~/.tmux.conf
```

> **注意**：手动软链接 `zshrc` 前，需先安装 Oh-My-Zsh 及相关插件（命令见 [zsh/README.md](zsh/)），否则主题和插件无法生效；tmux 配置依赖 [TPM 插件管理器](tmux/)与 Catppuccin 主题插件，软链接 `tmux.conf` 后还需克隆 TPM 并按 `Prefix + I` 安装插件，完整步骤见 [tmux/README.md](tmux/)。全新机器建议直接使用上方的一键安装脚本完成 zsh 环境的全部安装与软链接。

## 镜像源

本项目所有 Git 仓库地址均提供 Gitee 国内镜像，确保国内网络环境下的安装速度。详细的镜像源对照表请参阅 [zsh/README.md](zsh/)。

### 包管理器国内镜像源切换

若 GitHub 等外网不通畅，需将 macOS 与主流 Linux 发行版的包管理器默认源替换为国内镜像（apt、dnf、pacman、brew 等），请参阅 [mirror/README.md](mirror/README.md) 中的工具说明与直接使用命令，包含 **chsrc**、**LinuxMirrors**、**Cmirror** 三款工具的安装与使用，以及外网完全不通时的手动兜底配置。
