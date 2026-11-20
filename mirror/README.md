# mirror — 软件源国内镜像切换说明

本目录收录在 **GitHub 等外网不通畅** 的环境下，将 macOS 与主流 Linux 发行版的包管理器默认源替换为国内镜像的工具与直接可用命令。

> 核心原则：工具本体优先从国内可达源（Gitee、工具官网）安装，避免依赖 GitHub；安装完成后再用工具本身完成各包管理器的换源。
> 本文所有命令与地址均于 **2026-11-20** 实测通过（HTTP 200 / 下载成功），回退路径也一并标注。

---

## 一、三款工具怎么选

| 工具 | 定位 | 覆盖范围 | GitHub 依赖 | 国内安装来源 |
|------|------|----------|-------------|--------------|
| **chsrc** | 一条命令切换系统源与语言/开发工具源，自动测速 | apt/dnf/pacman/zypper/brew + pip/npm/cargo/go 等 | 无 | Gitee 官方仓库安装脚本 |
| **LinuxMirrors** | Linux 发行版系统源深度切换（交互菜单最省心） | Debian/Ubuntu/RHEL/Fedora/CentOS/Arch/openSUSE/Alpine 等 30+ 系统 | 无 | 官网 linuxmirrors.cn 直连 |
| **Cmirror** | 开发工具源测速切换（Rust 单二进制） | apt/pip/uv/conda/npm/docker/cargo/go/brew | **仅发布在 GitHub Releases** | GitHub 加速代理下载（实测可用） |

推荐组合：

- **系统发行版源** → LinuxMirrors（交互菜单、security/vault/EPEL 等细粒度参数）或 chsrc（一条命令）
- **开发工具源** → chsrc 或 cmirror（都支持测速选最快）
- 注意：cmirror 目前**不支持 dnf/yum 与 pacman**（官方 roadmap 已列 yum/dnf），这两类系统请用 chsrc 或 LinuxMirrors。

---

## 二、准备工作：先探测当前环境能连上谁

```bash
for u in \
  https://gitee.com \
  https://linuxmirrors.cn \
  https://mirrors.tuna.tsinghua.edu.cn \
  https://mirrors.ustc.edu.cn \
  https://mirrors.aliyun.com \
  https://ghfast.top; do
  code=$(curl -o /dev/null -s -w "%{http_code}" --connect-timeout 5 --max-time 10 "$u")
  echo "$u -> $code"
done
```

按探测结果选择路径：

- `gitee.com` 可用 → 用 **chsrc**（第三节，安装全程走 Gitee）
- `linuxmirrors.cn` 可用 → 用 **LinuxMirrors**（第四节，官网直连不依赖 GitHub）
- 只有 GitHub 不通 → 用 **cmirror** 走 `ghfast.top` / `gh-proxy.com` 加速代理（第五节）
- 全部不可用 → 直接看第六节「手动兜底」

---

## 三、chsrc —— 跨平台软件源切换工具

官方项目：`RubyMetric/chsrc`（GitHub），**Gitee 有官方仓库，安装全程不依赖 GitHub**。

### 3.1 安装（国内直连）

```bash
# 方式一（推荐）：官方安装脚本，二进制也从 Gitee Releases 下载
# root 运行装到 /usr/local/bin，普通用户装到 ~/.local/bin
curl -fsSL https://gitee.com/RubyMetric/chsrc/raw/main/tool/installer.sh | bash

# 方式二：手动下载二进制（x64 Linux；aarch64 把文件名换成 chsrc-aarch64-linux）
curl -fL https://gitee.com/RubyMetric/chsrc/releases/download/pre/chsrc-x64-linux -o /tmp/chsrc
sudo install /tmp/chsrc /usr/local/bin/chsrc

# 方式三：macOS（已装 Homebrew）
brew install chsrc

# 验证
chsrc --help
```

> 普通用户装到 `~/.local/bin` 后若提示命令不存在：`export PATH="$HOME/.local/bin:$PATH"`。
> Gitee Releases 还提供 `amd64.deb`（Debian/Ubuntu）、`chsrc-aarch64-linux`、Arch AUR `chsrc-bin` 等变体。

### 3.2 直接使用命令（照录官方帮助，已实测语法）

```bash
# —— 查看 ——
chsrc ls                      # 列出可用镜像站和可换源菜品（dish）
chsrc ls os                   # 列出支持的操作系统（lang / ware 同理）
chsrc ls mirror               # 列出支持的镜像站名称（供 set <dish> <mirror> 用）
chsrc ls apt                  # 查看 apt 菜品的可用源与支持功能
chsrc get apt                 # 查看 apt 当前源使用情况

# —— 换源（系统级需 sudo；自动测速挑最快）——
chsrc set apt                 # Debian / Ubuntu，自动测速选最快
sudo chsrc set ubuntu         # 直接按发行版名
sudo chsrc set fedora
sudo chsrc set arch
chsrc set brew                # Homebrew（无需 sudo）

# —— 换源：指定镜像 / 首选镜像 / 自定义 URL ——
chsrc set apt tuna            # 指定镜像站（名称以 chsrc ls apt 为准）
chsrc set pip aliyun
chsrc set ruby first          # 使用维护团队测速第一的源
chsrc set ruby https://gems.ruby-china.com/

# —— 语言与开发工具源 ——
chsrc set pip                 # 等价 chsrc set python（同时换 pip/poetry/pdm/uv）
chsrc set npm                 # 等价 chsrc set node（同时换 npm/yarn/pnpm）
chsrc set cargo               # 等价 chsrc set rust
chsrc set go

# —— 测速 / 还原 / 演练 ——
chsrc measure apt             # 仅测速不切换（别名 m）
chsrc reset apt               # 还原为上游默认源
chsrc set apt -dry            # Dry Run：仅打印换源过程，不实际执行

# —— 作用范围（配合 chsrc ls <dish> 查看该菜品支持的级别）——
chsrc set -scope=project bundler   # 仅当前项目
chsrc set -scope=user pip          # 用户级
chsrc set -scope=system apt        # 系统级
```

### 3.3 常用系统对象

| 系统 / 工具 | 命令 |
|------------|------|
| Ubuntu | `sudo chsrc set ubuntu` |
| Debian | `sudo chsrc set debian` |
| Fedora | `sudo chsrc set fedora` |
| Arch / Manjaro | `sudo chsrc set arch` / `sudo chsrc set manjaro` |
| openSUSE | `sudo chsrc set opensuse` |
| deepin / openEuler | `sudo chsrc set deepin` / `sudo chsrc set openeuler` |
| Homebrew | `chsrc set brew`（无 sudo） |

> 全量对象（docker、rubygems、composer、maven…）用 `chsrc ls` 查看。

---

## 四、LinuxMirrors —— Linux 发行版系统源一键切换

官方项目：`SuperManito/LinuxMirrors`（GitHub），**官网独立于 GitHub 可直连**；Gitee 也有镜像仓库（注意脚本文件名是 `ChangeMirrors.sh`，不是 `LinuxMirrors.sh`）。

### 4.1 获取脚本（国内直连，三选一）

```bash
# 方式一：官网主域名（推荐）
curl -fsSL https://linuxmirrors.cn/main.sh -o /tmp/LinuxMirrors.sh

# 方式二：官网备用域名（EdgeOne CDN）
curl -fsSL https://edgeone.linuxmirrors.cn/main.sh -o /tmp/LinuxMirrors.sh

# 方式三：Gitee 镜像仓库（注意文件名）
curl -fsSL https://gitee.com/SuperManito/LinuxMirrors/raw/main/ChangeMirrors.sh -o /tmp/LinuxMirrors.sh
```

> 脚本 `main()` 第一步就强制检查 root，非 root 运行会报错并提示 `sudo -i`，因此下面一律用 `sudo bash` 执行。

### 4.2 直接使用命令（参数取自脚本 `--help` 权威列表）

```bash
# 查看帮助
sudo bash /tmp/LinuxMirrors.sh --help

# 交互式换源（推荐首次使用）：自动检测发行版，菜单选择镜像站
# （阿里云 / 腾讯云 / 华为云 / 清华 / 北大 / 中科大 / 浙大 …）
sudo bash /tmp/LinuxMirrors.sh

# 指定镜像站域名直切（域名可替换为 mirrors.ustc.edu.cn / mirrors.aliyun.com 等）
sudo bash /tmp/LinuxMirrors.sh --source mirrors.tuna.tsinghua.edu.cn

# 只换源、不更新软件包、不清理缓存
sudo bash /tmp/LinuxMirrors.sh --source mirrors.aliyun.com --upgrade-software false --clean-cache false

# 教育网镜像 / 境外海外镜像
sudo bash /tmp/LinuxMirrors.sh --edu
sudo bash /tmp/LinuxMirrors.sh --abroad

# 指定 security 仓库、版本代号、协议
sudo bash /tmp/LinuxMirrors.sh --source-security security.debian.org --codename trixie
sudo bash /tmp/LinuxMirrors.sh --protocol http
```

常用参数（照录脚本 `--help`）：

| 参数 | 含义 | 值 |
|------|------|-----|
| `--source` | 指定软件源地址（域名或 IP） | 地址 |
| `--source-security` | Debian / Ubuntu 系 security 仓库源地址 | 地址 |
| `--source-epel` | EPEL 附加软件包仓库源地址 | 地址 |
| `--source-vault` | CentOS / AlmaLinux 系 vault 仓库源地址 | 地址 |
| `--source-base-system` | Linux Mint / Raspberry Pi OS 底层系统源地址 | 地址 |
| `--branch`（及 `--branch-security` 等） | 指定软件源仓库（路径） | 仓库名 |
| `--codename` | Debian 系 / openKylin 版本代号 | 代号名称 |
| `--protocol` | Web 协议 | `http` 或 `https` |
| `--backup` | 是否备份原有软件源（默认 `true`） | `true` / `false` |
| `--upgrade-software` | 是否更新软件包 | `true` / `false` |
| `--clean-cache` | 是否在更新软件包后清理下载缓存 | `true` / `false` |
| `--install-epel` | 是否安装 EPEL 附加软件包 | `true` / `false` |
| `--edu` / `--abroad` | 使用中国大陆教育网镜像 / 境外海外镜像 | 无 |
| `--print-diff` | 打印源文件修改前后差异 | 无 |
| `--only-epel` | 仅更换 EPEL 软件源模式 | 无 |
| `--ignore-backup-tips` | 忽略覆盖备份提示 | 无 |
| `--pure-mode` | 纯净模式，精简打印内容 | 无 |
| `--lang` | 指定脚本输出语言 | 语言 |
| `--help` | 查看帮助菜单 | 无 |

> 没有 `--mirror` / `--list` / `--restore` 参数：镜像站用 `--source <域名>` 指定，源文件默认自动备份（`--backup true`）。

### 4.3 支持的系统（摘自官方文档）

Debian 8-13、Ubuntu 14-26、Kali、Linux Mint、Deepin、Zorin、Armbian、PVE、Raspberry Pi OS、RHEL 7-10、Fedora 30-44、CentOS 7/8/Stream、Rocky/Alma/Oracle 8-10、openEuler、OpenCloudOS、openKylin、Anolis、openSUSE、Arch、Manjaro、EndeavourOS、Alpine、Gentoo、NixOS、Void 等。

Docker 源一键切换（同一官网）：

```bash
curl -fsSL https://linuxmirrors.cn/docker.sh -o /tmp/DockerInstallation.sh
sudo bash /tmp/DockerInstallation.sh
```

---

## 五、Cmirror —— 开发工具镜像源测速切换

官方项目：`ox01024/cmirror`（Rust 单二进制，China Mirror Manager）。**仅发布在 GitHub Releases**（无 Gitee 镜像、未上架 crates.io），GitHub 不通时用加速代理下载。

### 5.1 安装（GitHub 不通时走加速代理，实测可用）

```bash
# Linux x64（压缩包内即 cmirror 单文件二进制）
curl -fL "https://ghfast.top/https://github.com/ox01024/cmirror/releases/latest/download/cmirror-linux-x64.tar.gz" \
  -o /tmp/cmirror.tar.gz
tar -xzf /tmp/cmirror.tar.gz -C /tmp
sudo install /tmp/cmirror /usr/local/bin/cmirror

# Linux arm64：文件名换 cmirror-linux-arm64.tar.gz
# macOS Apple Silicon / Intel：cmirror-macos-arm64.tar.gz / cmirror-macos-x64.tar.gz

# 备用代理：把前缀 https://ghfast.top/ 换成 https://gh-proxy.com/
#   curl -fL "https://gh-proxy.com/https://github.com/ox01024/cmirror/releases/latest/download/cmirror-linux-x64.tar.gz" -o /tmp/cmirror.tar.gz

# 验证
cmirror status
```

> 加速代理为第三方服务，可能随时失效：失效时换另一个前缀，或在能访问 GitHub 的机器下载后拷贝过来。

### 5.2 直接使用命令（照录官方 README，已实测语法）

```bash
# 查看所有工具当前源状态 / 查看单个工具
cmirror status
cmirror status pip

# 测速
cmirror test pip

# 换源：测速选最快 / 指定镜像
cmirror use pip --fastest
cmirror use pip aliyun
cmirror use npm aliyun

# 系统级（apt、docker 等）需要 root
sudo cmirror use apt --fastest
sudo cmirror use docker --fastest

# 还原该工具的原源
cmirror restore pip
```

### 5.3 支持的工具

`pip`、`uv`、`conda`、`npm`、`docker`、`apt`（Ubuntu/Debian）、`cargo`、`go`、`brew`。

**暂不支持 dnf/yum、pacman**（roadmap 已列 yum/dnf）——这两类系统请用 chsrc 或 LinuxMirrors。

---

## 六、外网完全不通时的手动兜底（不依赖任何工具）

若三个工具都装不上，直接编辑系统源配置文件。**操作前先备份**，镜像域名从第二节探测可达的站点中挑选。

### 6.1 Ubuntu / Debian（apt）

```bash
# Ubuntu 24.04+ 使用 deb822 格式 /etc/apt/sources.list.d/ubuntu.sources
if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then
  sudo cp -a /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources.bak
  sudo sed -i \
    -e 's|http://archive.ubuntu.com/ubuntu/|https://mirrors.tuna.tsinghua.edu.cn/ubuntu/|g' \
    -e 's|http://security.ubuntu.com/ubuntu/|https://mirrors.tuna.tsinghua.edu.cn/ubuntu/|g' \
    /etc/apt/sources.list.d/ubuntu.sources
# 旧版 Ubuntu（≤ 22.04）为 /etc/apt/sources.list
elif [ -f /etc/apt/sources.list ]; then
  sudo cp -a /etc/apt/sources.list /etc/apt/sources.list.bak
  sudo sed -i \
    -e 's|http://archive.ubuntu.com/ubuntu/|https://mirrors.tuna.tsinghua.edu.cn/ubuntu/|g' \
    -e 's|http://security.ubuntu.com/ubuntu/|https://mirrors.tuna.tsinghua.edu.cn/ubuntu/|g' \
    /etc/apt/sources.list
fi

sudo apt-get update
```

Debian 同理（`sources.list` 或 deb822 的 `debian.sources`，把域名换掉即可）：

```bash
sudo sed -i \
  -e 's|http://deb.debian.org/debian|https://mirrors.tuna.tsinghua.edu.cn/debian|g' \
  -e 's|http://security.debian.org/debian-security|https://mirrors.tuna.tsinghua.edu.cn/debian-security|g' \
  /etc/apt/sources.list
sudo apt-get update
```

### 6.2 Fedora（dnf）

```bash
sudo cp -a /etc/yum.repos.d /etc/yum.repos.d.bak.$(date +%Y%m%d%H%M%S)

# 注释 mirrorlist、启用 baseurl 并指向清华源（fedora*.repo 覆盖 fedora/updates 等仓库）
sudo sed -i \
  -e 's|^mirrorlist=|#mirrorlist=|' \
  -e 's|^#baseurl=http://download.fedoraproject.org/pub|baseurl=https://mirrors.tuna.tsinghua.edu.cn|' \
  /etc/yum.repos.d/fedora*.repo

sudo dnf makecache
```

> CentOS / RHEL 系仓库结构不同（还涉及 vault/security 分支），建议直接用上面的 LinuxMirrors（会自动处理）。

### 6.3 Arch Linux / Manjaro（pacman）

```bash
sudo cp -a /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

# 在文件最前插入清华源（单引号防止 $repo / $arch 被展开）
sudo sed -i '1i Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch' /etc/pacman.d/mirrorlist

sudo pacman -Syy
```

### 6.4 Homebrew（macOS / Linux）

官方推荐用环境变量（取值照录清华 TUNA 镜像官方帮助）：

```bash
# 写入 zsh 配置（macOS 默认 zsh；bash 用户改写 ~/.bash_profile）
cat >> ~/.zprofile <<'EOF'
# Homebrew 清华镜像
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
EOF
source ~/.zprofile
brew update
```

> brew ≥ 4.0 默认走 API（`HOMEBREW_INSTALL_FROM_API=1`）：`HOMEBREW_API_DOMAIN` + `HOMEBREW_BOTTLE_DOMAIN` 覆盖 formula/cask 索引与二进制包下载，`*_GIT_REMOTE` 覆盖 `brew update` 的仓库拉取。
> 也可以直接用 `chsrc set brew` 一键完成。

---

## 七、使用建议与注意事项

1. **先验网络再装工具**：用第二节探测脚本确认可达站点，优先 Gitee / 官网直连，绝不直接从 GitHub 克隆。
2. **切换前备份**：LinuxMirrors 默认 `--backup true`；chsrc 可用 `chsrc reset <dish>` 还原；手动方案务必先 `cp -a`。
3. **源名以工具输出为准**：`chsrc ls <dish>` 查看可用镜像名；`chsrc set <dish>` / `cmirror use <tool> --fastest` 自动测速最稳，不要硬编码镜像名。
4. **root 权限**：系统级源（apt/dnf/pacman）切换需要 root；Homebrew 与 pip/npm 等用户级源不需要。
5. **验证结果**：执行后分别运行 `sudo apt-get update` / `sudo dnf makecache` / `sudo pacman -Syy` / `brew update`，确认无 404、GPG 错误。
6. **GitHub 加速代理属第三方服务**：`ghfast.top`、`gh-proxy.com` 于 2026-11-20 实测可用，失效时更换前缀或换用其他代理。

---

## 文件清单

本目录仅放本说明文档；工具脚本下载到 `/tmp` 使用即可，不提交到本 dotfiles 仓库，避免体积膨胀或泄露本机源配置。
