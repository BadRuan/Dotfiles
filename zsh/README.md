## ZSH 配置环境

> zsh 是一个兼容 bash 的 shell，相较 bash 具有以下优点：
- Tab 补全功能强大。命令、命令参数、文件路径均可以补全。
- 插件丰富。快速输入以前使用过的命令、快速跳转文件夹、显示系统负载这些都可以通过插件实现。
- 主题丰富。
- 可定制性高。

### 一键安装

使用以下命令一键安装 zsh 及全部配置：

```bash
# 标准安装（有交互确认）
sh -c "$(curl -fsSL https://gitee.com/ruanfumin/dotfiles/raw/master/zsh/auto_install_zsh.sh)"

# 无人值守模式（跳过所有确认）
curl -fsSL https://gitee.com/ruanfumin/dotfiles/raw/master/zsh/auto_install_zsh.sh | bash -s -- --unattended
```

> **提权说明**：脚本支持以 **root 账户直接运行**（无需 sudo，适合容器 / 最小化安装环境）；普通用户运行时自动经 sudo 提权，系统未安装 sudo 时会在需要提权处给出明确报错。
>
> **容器 / 旧系统说明**：pacman 下载失败（SSL 证书过旧或缺失、镜像不可达、过期数据库 404，或容器镜像缺少同步数据库导致 `target not found`）时，脚本会自动把 `/etc/pacman.d/mirrorlist` 切换为国内源（清华 / 中科大 / 阿里云，原配置备份为 `mirrorlist.dotfiles-backup`），执行 `pacman -Sy` 同步数据库并重试；HTTPS 仍不通时会临时改用 HTTP 完成 `ca-certificates` / `archlinux-keyring` 更新，成功后再切回 HTTPS。签名 / 密钥环仍失败时会打印手动修复指引。

安装脚本会自动完成以下工作：
1. 检测系统包管理器并安装 git、zsh
2. 克隆 dotfiles 仓库并创建 `.zshrc` 软链接
3. 安装 Oh-My-Zsh（国内 Gitee 镜像源优先）
4. 安装 powerlevel10k 主题
5. 安装 zsh 插件（autosuggestions、syntax-highlighting、autocomplete）
6. 安装 Zinit 插件管理器
7. 设置 zsh 为默认 Shell

### 支持的系统

| 系统 | 包管理器 | 安装命令 |
|------|---------|---------|
| Arch Linux / Manjaro | pacman | `sudo pacman -S zsh` |
| Debian / Ubuntu | apt-get | `sudo apt-get install zsh` |
| Fedora | dnf | `sudo dnf install zsh` |
| macOS / Linux | Homebrew | `brew install zsh` |

### 手动安装 zsh

如果不使用一键安装脚本，可以手动安装 zsh：

**macOS：**
```bash
brew install zsh
```

**Ubuntu / Debian：**
```bash
sudo apt-get install zsh
```

**Arch Linux / Manjaro：**
```bash
sudo pacman -S zsh
```

**Fedora：**
```bash
sudo dnf install zsh
```

### 切换默认 Shell

安装好 zsh 后查看路径：`which zsh`

使用 `cat /etc/shells` 查看系统可用的 shell。

使用 `chsh -s /bin/zsh` 命令将 zsh 设置为系统默认 shell。新开一个 Shell Session 即可生效。

### zsh 配置文件

zsh 的配置文件用于定制和配置 shell 的行为，默认路径为 `~/.zshrc`。

本项目通过软链接管理配置文件（若 `~/.zshrc` 已存在，请先备份：`mv ~/.zshrc ~/.zshrc.bak`）：
```bash
ln -s ~/dotfiles/zsh/zshrc ~/.zshrc
```

> 手动软链接前请先安装 Oh-My-Zsh 及插件（见下文各节），或直接使用一键安装脚本。未安装 Oh-My-Zsh 时 `zshrc` 会给出提示而不会报错中断。


## Oh-My-Zsh

> oh-my-zsh 是一个开源、成熟且使用众多的 zsh 框架。Oh My Zsh 是基于 zsh 命令行的一个扩展工具集，提供了丰富的扩展功能。

- 官网: [ohmyz.sh](https://ohmyz.sh/)
- 仓库地址: [github.com](https://github.com/ohmyzsh/ohmyzsh)
- 使用介绍: [zsh 安装与配置：9步打造高效命令行](https://zhuanlan.zhihu.com/p/441676276)

### 安装 Oh-My-Zsh

```bash
# 使用国内镜像安装（推荐）
REMOTE=https://gitee.com/ruanfumin/ohmyzsh.git sh -c "$(curl -fsSL https://gitee.com/ruanfumin/ohmyzsh/raw/master/tools/install.sh)"

# 使用官方源安装
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### 安装 powerlevel10k 主题

```bash
# 国内镜像（推荐）
git clone --depth=1 https://gitee.com/ruanfumin/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# 国际源（回退）
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
```

修改 `.zshrc` 文件：
```bash
ZSH_THEME="powerlevel10k/powerlevel10k"
```

执行 `source ~/.zshrc` 使配置生效。首次启动会引导配置主题外观，后续可运行 `p10k configure` 重新配置。

### 安装 Oh-My-Zsh 插件

oh-my-zsh 已经内置了 git 插件，更多插件可在 [awesome-zsh-plugins](https://github.com/unixorn/awesome-zsh-plugins) 中查看。

#### 1. zsh-autosuggestions

> [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) 是一个命令提示插件，当你输入命令时，会自动推测你可能需要输入的命令，按下 `→` 右键可以快速采用建议。

```bash
# 国内镜像（推荐）
git clone https://gitee.com/ruanfumin/zsh-autosuggestions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# 国际源
git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```

#### 2. zsh-syntax-highlighting

> [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) 是一个命令语法校验插件，输入命令时，若指令不合法则显示为红色，合法则显示为绿色。

```bash
# 国内镜像（推荐）
git clone https://gitee.com/ruanfumin/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# 国际源
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

#### 3. zsh-autocomplete

> [zsh-autocomplete](https://github.com/marlonrichert/zsh-autocomplete) 提供实时自动补全功能，输入时自动显示可能的补全项。

```bash
# 国内镜像（推荐）
git clone https://gitee.com/ruanfumin/zsh-autocomplete.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autocomplete

# 国际源
git clone https://github.com/marlonrichert/zsh-autocomplete.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autocomplete
```

#### 4. z（目录快捷跳转）

> z 是一个文件夹快捷跳转插件，对于曾经跳转过的目录，只需要输入最终目标文件夹名称即可快速跳转，避免输入长串路径。

oh-my-zsh 内置了 z 插件，只需在 `.zshrc` 的 plugins 列表中加入 `z` 即可。

### 启用插件

在 `.zshrc` 中配置插件列表：

```bash
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-autocomplete
    z
)
```

执行 `source ~/.zshrc` 或开启新的 Shell 使配置生效。


## Zinit 插件管理器

> [Zinit](https://github.com/zdharma-continuum/zinit) 是一个灵活的 zsh 插件管理器，支持懒加载等高级功能。

```bash
# 国内镜像（推荐）
git clone --depth=1 https://gitee.com/ruanfumin/zinit.git ~/.local/share/zinit/zinit.git

# 国际源
git clone --depth=1 https://github.com/zdharma-continuum/zinit.git ~/.local/share/zinit/zinit.git
```


## 镜像源说明

所有组件均优先使用 **Gitee 国内镜像源**，确保在国内网络环境下也能快速安装。当国内源不可用时，安装脚本会自动回退到 GitHub 国际源。

| 组件 | Gitee 国内源 | GitHub 国际源 |
|------|-------------|--------------|
| Oh-My-Zsh | `gitee.com/ruanfumin/ohmyzsh` | `github.com/ohmyzsh/ohmyzsh` |
| powerlevel10k | `gitee.com/ruanfumin/powerlevel10k` | `github.com/romkatv/powerlevel10k` |
| zsh-autosuggestions | `gitee.com/ruanfumin/zsh-autosuggestions` | `github.com/zsh-users/zsh-autosuggestions` |
| zsh-syntax-highlighting | `gitee.com/ruanfumin/zsh-syntax-highlighting` | `github.com/zsh-users/zsh-syntax-highlighting` |
| zsh-autocomplete | `gitee.com/ruanfumin/zsh-autocomplete` | `github.com/marlonrichert/zsh-autocomplete` |
| Zinit | `gitee.com/ruanfumin/zinit` | `github.com/zdharma-continuum/zinit` |
