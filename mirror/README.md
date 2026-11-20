# mirror — 软件源国内镜像切换说明

本目录收录在 **GitHub 等外网不通畅** 的环境下，将 macOS 与主流 Linux 发行版的包管理器默认源替换为国内镜像的工具与直接可用命令。

> 核心原则：优先使用国内镜像站（Gitee、清华、中科大、阿里云、网易、腾讯、华为等）下载工具本体，避免从 GitHub 克隆；工具安装完成后，再用工具本身完成各包管理器的源切换。

---

## 一、准备工作（外网不通时）

### 1. 确认当前网络可达的国内镜像站

```bash
# 逐个探测，优先使用能 200 OK 的站点
for u in \
  https://gitee.com \
  https://mirrors.tuna.tsinghua.edu.cn \
  https://mirrors.ustc.edu.cn \
  https://mirrors.aliyun.com \
  https://mirrors.163.com \
  https://mirrors.cloud.tencent.com \
  https://mirrors.huaweicloud.com; do
  code=$(curl -o /dev/null -s -w "%{http_code}" --connect-timeout 5 --max-time 10 "$u")
  echo "$u -> $code"
done
```

选响应正常的站点作为后续下载源，把下文中 `MIRROR_BASE` 替换为该站点地址。

### 2. 设置临时环境变量（本次会话有效）

```bash
export MIRROR_BASE="https://gitee.com"   # 或你探测可达的任一国内站
export DOWNLOAD_CMD="curl -fL --connect-timeout 10 --max-time 60"
```

---

## 二、chsrc —— 跨平台软件源切换工具

官方项目：`chsrc/chsrc`（GitHub），国内可通过 Gitee 镜像获取。

### 安装（国内镜像优先，不依赖 GitHub）

```bash
# 方式 A：从 Gitee 镜像拉取安装脚本（推荐）
curl -fL --connect-timeout 10 --max-time 120 \
  -o /tmp/chsrc-install.sh \
  "https://gitee.com/chsrc/chsrc/raw/main/install.sh" \
&& bash /tmp/chsrc-install.sh

# 方式 B：若 Gitee 也不可用，尝试清华/中科大 raw 镜像（若有搭建）
# curl -fL ... https://mirrors.tuna.tsinghua.edu.cn/git/chsrc/chsrc/raw/main/install.sh | bash

# 验证安装
chsrc --version
chsrc --help
```

### 直接使用命令

```bash
# 查看当前所有可切换的包管理器
chsrc list

# 查看某个包管理器的可用源列表（以 apt 为例）
chsrc list apt

# 切换源（交互式，会列表选择）
chsrc use apt

# 非交互式直接指定源（源名以 chsrc list 为准，例如 tuna/ustc/aliyun/163）
chsrc use apt tuna
chsrc use dnf tuna
chsrc use pacman tuna
chsrc use brew tuna

# 回滚到上一个源
chsrc rollback apt

# 查看当前正在使用的源
chsrc current apt
```

### 支持的包管理器（常见）

| 类别 | 包管理器 | 适用系统 |
|------|---------|---------|
| Linux | apt | Debian / Ubuntu |
| Linux | dnf / yum | Fedora / RHEL / CentOS / openEuler |
| Linux | pacman | Arch Linux / Manjaro |
| Linux | zypper | openSUSE |
| Linux | apk | Alpine Linux |
| macOS | brew / homebrew-core / homebrew-cask | macOS / Linux (Homebrew) |
| 语言 | pip / npm / gem / composer / cargo / go | 各语言包索引 |

> 注意：`chsrc use <mgr> <mirror>` 中的 `<mirror>` 名称随版本可能变化，运行 `chsrc list <mgr>` 查看当前可用名称，不要硬编码。

---

## 三、LinuxMirrors —— Linux 发行版源一键切换

官方项目：`SuperManito/LinuxMirrors`（GitHub），国内可通过 Gitee 镜像获取。

### 安装（国内镜像优先，不依赖 GitHub）

```bash
# 从 Gitee 镜像下载主脚本
curl -fL --connect-timeout 10 --max-time 120 \
  -o /tmp/LinuxMirrors.sh \
  "https://gitee.com/SuperManito/LinuxMirrors/raw/main/LinuxMirrors.sh" \
&& chmod +x /tmp/LinuxMirrors.sh

# 查看帮助
bash /tmp/LinuxMirrors.sh --help
```

### 直接使用命令

```bash
# 交互式切换（会列出系统检测到的发行版与可用源）
sudo bash /tmp/LinuxMirrors.sh

# 非交互式：指定发行版与源
# 示例：将 Ubuntu 源切换为中科大 USTC
sudo bash /tmp/LinuxMirrors.sh --source ubuntu --mirror ustc

# 示例：将 CentOS 源切换为阿里云
sudo bash /tmp/LinuxMirrors.sh --source centos --mirror aliyun

# 示例：将 Debian 源切换为清华 TUNA
sudo bash /tmp/LinuxMirrors.sh --source debian --mirror tuna

# 备份当前源（建议切换前先执行）
sudo bash /tmp/LinuxMirrors.sh --backup

# 恢复之前备份的源
sudo bash /tmp/LinuxMirrors.sh --restore

# 查看支持的发行版与源列表
bash /tmp/LinuxMirrors.sh --list
```

### 常用参数（以实际输出为准）

| 参数 | 含义 |
|------|------|
| `--source <发行版>` | 指定操作系统，如 ubuntu/debian/centos/fedora/opensuse/kali/deepin/uniontech 等 |
| `--mirror <源名>` | 指定镜像站，如 tuna/ustc/aliyun/163/huaweicloud/tencent 等 |
| `--backup` | 备份当前源配置文件 |
| `--restore` | 恢复之前备份的源配置 |
| `--list` | 列出支持的发行版与镜像站 |
| `--help` | 显示帮助 |

> `LinuxMirrors.sh` 默认会自动检测发行版，若检测不准可用 `--source` 显式指定。

---

## 四、Cmirror —— 镜像源切换辅助工具

> Cmirror 为较新/较小众的镜像切换工具，具体子命令与发行版支持请以安装后的 `--help` 输出为准。以下按通用模式给出，安装后请务必先运行 `cmirror --help` 确认。

### 安装（国内镜像优先）

```bash
# 尝试从 Gitee 镜像获取安装脚本（具体路径随仓库调整，按实际可达情况替换）
curl -fL --connect-timeout 10 --max-time 120 \
  -o /tmp/cmirror-install.sh \
  "https://gitee.com/cmirror/cmirror/raw/main/install.sh" 2>/dev/null \
|| curl -fL --connect-timeout 10 --max-time 120 \
  -o /tmp/cmirror-install.sh \
  "https://gitee.com/cmirror/cmirror/raw/master/install.sh"

bash /tmp/cmirror-install.sh

# 验证
cmirror --version 2>/dev/null || cmirror -v 2>/dev/null || echo "需按实际安装路径调用"
```

### 直接使用命令（模板，以 --help 输出为准）

```bash
# 查看帮助与支持的包管理器
cmirror --help
cmirror -h

# 列出可用源（示例）
cmirror list
cmirror list apt
cmirror list dnf
cmirror list pacman
cmirror list brew

# 切换源（示例，源名以 cmirror list 为准）
cmirror use apt tuna
cmirror use dnf aliyun
cmirror use pacman ustc
cmirror use brew tuna

# 查看当前源 / 回滚 / 备份
cmirror current apt
cmirror rollback apt
cmirror backup
cmirror restore
```

---

## 五、外网完全不通时的手动兜底（不依赖任何工具）

若上述工具均无法下载，可直接编辑系统源配置文件。以下给出各主流发行版的国内源配置示例，复制替换后执行对应的缓存更新命令即可。

### 5.1 Debian / Ubuntu（apt）

备份原文件，写入国内源：

```bash
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak.$(date +%Y%m%d%H%M%S)

# 以 Ubuntu 22.04 Jammy + 中科大 USTC 为例
sudo tee /etc/apt/sources.list > /dev/null <<'EOF'
deb https://mirrors.ustc.edu.cn/ubuntu/ jammy main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ jammy-security main restricted universe multiverse
EOF

sudo apt-get update
```

可将 `mirrors.ustc.edu.cn` 替换为 `mirrors.tuna.tsinghua.edu.cn`、`mirrors.aliyun.com`、`mirrors.163.com` 等。

### 5.2 Fedora / RHEL / CentOS / openEuler（dnf / yum）

```bash
sudo cp /etc/yum.repos.d/*.repo /etc/yum.repos.d/.backup.$(date +%Y%m%d%H%M%S)/ 2>/dev/null || true

# Fedora 示例：替换为清华 TUNA
sudo sed -i 's#mirrorlist=##mirrorlist=#g' /etc/yum.repos.d/fedora.repo /etc/yum.repos.d/fedora-modular.repo /etc/yum.repos.d/fedora-updates.repo /etc/yum.repos.d/fedora-updates-modular.repo 2>/dev/null || true
sudo sed -i 's##baseurl=https://download.fedoraproject.org/pub#baseurl=https://mirrors.tuna.tsinghua.edu.cn/fedora#g' /etc/yum.repos.d/fedora.repo /etc/yum.repos.d/fedora-updates.repo 2>/dev/null || true

sudo dnf makecache
```

更稳妥的做法是直接下载对应发行版的 `.repo` 文件替换：

```bash
# 示例：从国内镜像下载 Fedora repo 文件（按实际版本号替换）
sudo curl -fL --connect-timeout 10 -o /etc/yum.repos.d/fedora.repo \
  https://mirrors.tuna.tsinghua.edu.cn/fedora/releases/$(rpm -E %fedora)/Everything/x86_64/os/repo/fedora.repo
sudo dnf makecache
```

### 5.3 Arch Linux / Manjaro（pacman）

```bash
sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak.$(date +%Y%m%d%H%M%S)

# 将中科大 USTC 放到最前面（优先级最高）
sudo tee /etc/pacman.d/mirrorlist > /dev/null <<'EOF'
Server = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch
Server = https://mirrors.aliyun.com/archlinux/$repo/os/$arch
EOF

sudo pacman -Syy
```

### 5.4 Homebrew（macOS / Linux）

Homebrew 的核心仓库（homebrew-core）与烧瓶（bottles）默认从 GitHub 下载，可替换为中科大/清华镜像：

```bash
# 替换 Homebrew 仓库源（macOS Intel / Apple Silicon 均适用，路径按实际 brew --prefix 为准）
cd "$(brew --prefix)"
git remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git

# 替换 homebrew-core（如已单独 tap）
cd "$(brew --prefix homebrew/core)" 2>/dev/null \
  && git remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git 2>/dev/null || true

# 替换 bottles 源（下载二进制包的地址）
export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles
# 写入 ~/.zshrc / ~/.bash_profile 使其永久生效
echo 'export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles' >> ~/.zshrc

brew update
```

中科大 Homebrew 镜像文档：https://mirrors.ustc.edu.cn/help/homebrew-bottles.html  
清华 Homebrew 镜像文档：https://mirrors.tuna.tsinghua.edu.cn/help/homebrew/

---

## 六、使用建议与注意事项

1. **先验网络，再安装工具**：外网不通时，先用 `curl -I` 探测哪个国内镜像站可达，再从该站下载 `chsrc` / `LinuxMirrors` / `Cmirror`，不要直接从 GitHub 克隆。
2. **切换前备份**：所有工具切换源前都会修改系统配置文件，务必先执行备份（`--backup` 或手动 `cp`），出问题可一键回滚。
3. **源名称以工具实际输出为准**：`chsrc list`、`LinuxMirrors --list`、`cmirror --help` 中的源名随版本变化，脚本中不要硬编码具体源名。
4. **root 权限**：Linux 系统源切换需要 `sudo`；macOS Homebrew 源切换一般无需 sudo，但 `git remote set-url` 需在 `brew --prefix` 目录下有写权限。
5. **验证切换结果**：执行后分别运行 `sudo apt-get update` / `sudo dnf makecache` / `sudo pacman -Syy` / `brew update` 确认无 404 或 GPG 错误。

---

## 文件清单

本目录仅放本说明文档；各工具脚本建议下载到 `/tmp` 使用，不应提交到本 dotfiles 仓库，避免泄露系统源配置或体积过大。
