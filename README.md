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
| [zsh/](zsh/) | zsh Shell 配置、Oh-My-Zsh、插件、主题 |
| [vim/](vim/) | Vim 编辑器配置与插件 |
| [tmux/](tmux/) | tmux 终端复用器配置（TPM 插件、Catppuccin 主题、分屏与会话管理） |
| [ssh/](ssh/) | SSH 连接配置 |
| [profile/](profile/) | `.profile` 登录 Shell 配置说明 |

## 快速开始

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
