#!/bin/bash
#
# Dotfiles 一键汇总安装脚本
#
# 功能（按顺序执行）：
#   1. 替换系统 / 包管理器国内镜像源（chsrc 默认，或 LinuxMirrors；可跳过）
#   2. 安装常见工具：git、curl、wget、tmux、vim、zsh、lsd、btop
#   3. 配置 zsh   —— 复用 zsh/auto_install_zsh.sh（Oh-My-Zsh + powerlevel10k + 插件 + Zinit）
#   4. 配置 vim   —— 复用 vim/auto_install_vim.sh（vim-plug + 全部插件，可选 YouCompleteMe）
#   5. 配置 tmux  —— 软链 tmux.conf、克隆 TPM（Gitee 镜像）、自动安装插件
#
# 使用方式：
#   bash setup.sh                  # 交互模式：逐步确认
#   bash setup.sh --unattended     # 静默模式：全部默认执行
#   bash setup.sh --dry-run        # 预演：仅打印将执行的动作，不实际执行
#
#   curl -fsSL https://gitee.com/ruanfumin/dotfiles/raw/master/setup.sh | bash
#   curl -fsSL https://gitee.com/ruanfumin/dotfiles/raw/master/setup.sh | bash -s -- --unattended
#
# 选项：
#   -y, --unattended       静默执行（无人值守）
#       --dry-run          仅打印将执行的动作，不实际执行
#       --no-mirror        跳过国内镜像源替换
#       --no-tools         跳过常见工具安装
#       --no-zsh           跳过 zsh 配置
#       --no-vim           跳过 vim 配置
#       --no-tmux          跳过 tmux 配置
#       --with-ycm         vim 步骤附带编译 YouCompleteMe（体积大、需编译）
#       --mirror-tool T    换源工具：chsrc（默认）| linuxmirrors
#       --mirror-src HOST  配合 linuxmirrors 的 --source（如 mirrors.tuna.tsinghua.edu.cn）
#   -h, --help             显示本帮助
#
# 提权说明：
#   root 账户可直接运行（无需 sudo，适合容器 / 最小化安装环境）；普通用户运行时经 sudo 提权。

# ========== 颜色定义 ==========
FMT_RED='\033[31m'
FMT_GREEN='\033[32m'
FMT_YELLOW='\033[33m'
FMT_BLUE='\033[34m'
FMT_BOLD='\033[1m'
FMT_RESET='\033[0m'

info()    { echo -e "${FMT_BLUE}[信息]${FMT_RESET} $*"; }
success() { echo -e "${FMT_GREEN}[成功]${FMT_RESET} $*"; }
warn()    { echo -e "${FMT_YELLOW}[警告]${FMT_RESET} $*"; }
error()   { echo -e "${FMT_RED}[错误]${FMT_RESET} $*"; }

usage() {
    cat <<'EOF'
Dotfiles 一键汇总安装脚本

用法：
  bash setup.sh                  交互模式（逐步确认）
  bash setup.sh --unattended     静默模式（全部默认执行）
  bash setup.sh --dry-run        仅打印将执行的动作，不实际执行

  curl -fsSL https://gitee.com/ruanfumin/dotfiles/raw/master/setup.sh | bash
  curl -fsSL https://gitee.com/ruanfumin/dotfiles/raw/master/setup.sh | bash -s -- --unattended

选项：
  -y, --unattended       静默执行（无人值守）
      --dry-run          仅打印将执行的动作，不实际执行
      --no-mirror        跳过国内镜像源替换
      --no-tools         跳过常见工具安装（git/tmux/lsd/btop 等）
      --no-zsh           跳过 zsh 配置
      --no-vim           跳过 vim 配置
      --no-tmux          跳过 tmux 配置
      --with-ycm         vim 步骤附带编译 YouCompleteMe（体积大、需编译）
      --mirror-tool T    换源工具：chsrc（默认）| linuxmirrors
      --mirror-src HOST  配合 linuxmirrors 的 --source（如 mirrors.tuna.tsinghua.edu.cn）
  -h, --help             显示本帮助

说明：
  root 账户可直接运行（无需 sudo）；普通用户经 sudo 提权。
  换源工具详见 mirror/README.md，tmux 插件详见 tmux/README.md。
EOF
}

# ========== 全局变量 ==========
UNATTENDED=false
DRY_RUN=false
SKIP_MIRROR=false
SKIP_TOOLS=false
SKIP_ZSH=false
SKIP_VIM=false
SKIP_TMUX=false
WITH_YCM=false
MIRROR_TOOL="chsrc"
MIRROR_SRC=""

PKG_MGR=""
SUDO=""
REPO_DIR=""
APT_UPDATED=false
TOOLS="git curl wget tmux vim zsh lsd btop"

# 步骤状态（用于最终汇总）
R_MIRROR="未执行"
R_TOOLS="未执行"
R_ZSH="未执行"
R_VIM="未执行"
R_TMUX="未执行"

# 防止 git 克隆时因凭据交互而挂起
export GIT_TERMINAL_PROMPT=0

# ========== 参数解析 ==========
while [ $# -gt 0 ]; do
    case "$1" in
        -y|--unattended) UNATTENDED=true ;;
        --dry-run) DRY_RUN=true ;;
        --no-mirror) SKIP_MIRROR=true ;;
        --no-tools) SKIP_TOOLS=true ;;
        --no-zsh) SKIP_ZSH=true ;;
        --no-vim) SKIP_VIM=true ;;
        --no-tmux) SKIP_TMUX=true ;;
        --with-ycm) WITH_YCM=true ;;
        --mirror-tool)
            shift
            MIRROR_TOOL="${1:-chsrc}"
            case "$MIRROR_TOOL" in
                chsrc|linuxmirrors) ;;
                *) error "--mirror-tool 仅支持 chsrc | linuxmirrors"; exit 1 ;;
            esac
            ;;
        --mirror-src)
            shift
            MIRROR_SRC="${1:-}"
            ;;
        -h|--help) usage; exit 0 ;;
        *) error "未知选项: $1"; echo; usage; exit 1 ;;
    esac
    shift
done

# ========== 基础工具函数 ==========

# 统一执行入口：dry-run 时仅打印
run() {
    if [ "$DRY_RUN" = true ]; then
        echo -e "${FMT_BLUE}[dry-run]${FMT_RESET} $*"
        return 0
    fi
    "$@"
}

# 提权执行：root 直接执行；普通用户经 sudo（无 sudo 时明确报错）
run_priv() {
    if [ -z "$SUDO" ]; then
        run "$@"
    elif command -v sudo >/dev/null 2>&1; then
        run sudo "$@"
    else
        error "需要特权执行: $*"
        error "当前为普通用户且系统未安装 sudo，请改用 root 运行本脚本"
        return 1
    fi
}

# 包管理器专用：brew 永远不走 sudo
run_pkg() {
    if [ "$PKG_MGR" = "brew" ]; then
        run "$@"
    else
        run_priv "$@"
    fi
}

# 交互确认：静默模式或非终端时直接返回默认值
ask() {
    local prompt="$1"
    local def="$2"
    local ans=""
    if [ "$UNATTENDED" = true ] || [ ! -t 0 ]; then
        [ "$def" = "Y" ] && return 0 || return 1
    fi
    if [ "$def" = "Y" ]; then
        printf "%s [Y/n] " "$prompt"
    else
        printf "%s [y/N] " "$prompt"
    fi
    read -r ans || ans=""
    case "$ans" in
        y|Y|yes|YES) return 0 ;;
        n|N|no|NO) return 1 ;;
        *) [ "$def" = "Y" ] && return 0 || return 1 ;;
    esac
}

# ========== 检测与准备 ==========

detect_pkg_mgr() {
    if command -v pacman >/dev/null 2>&1; then
        PKG_MGR="pacman"
    elif command -v apt-get >/dev/null 2>&1; then
        PKG_MGR="apt-get"
    elif command -v dnf >/dev/null 2>&1; then
        PKG_MGR="dnf"
    elif command -v brew >/dev/null 2>&1; then
        PKG_MGR="brew"
    else
        error "未检测到支持的包管理器（pacman / apt-get / dnf / brew）"
        return 1
    fi
    return 0
}

setup_sudo() {
    if [ "$(id -u)" -eq 0 ]; then
        SUDO=""
        info "当前为 root 用户，特权命令直接执行（无需 sudo）"
    else
        SUDO="sudo"
        if ! command -v sudo >/dev/null 2>&1; then
            warn "当前为普通用户且未安装 sudo，涉及系统配置的步骤可能失败"
        fi
    fi
    info "包管理器: $PKG_MGR"
}

ensure_apt_update() {
    [ "$PKG_MGR" = "apt-get" ] || return 0
    [ "$APT_UPDATED" = true ] && return 0
    run_priv apt-get update || warn "apt-get update 失败，继续尝试安装..."
    APT_UPDATED=true
    return 0
}

# 批量安装，失败则逐个安装以跳过仓库中不存在的包
install_pkgs() {
    local pkgs="$1"
    [ -n "$pkgs" ] || return 0
    info "安装软件包：$pkgs"
    local batch_ok=true
    local p failed=""
    ensure_apt_update
    case "$PKG_MGR" in
        pacman)  run_pkg pacman -S --noconfirm --needed $pkgs || batch_ok=false ;;
        apt-get) run_pkg apt-get install -y $pkgs || batch_ok=false ;;
        dnf)     run_pkg dnf install -y $pkgs || batch_ok=false ;;
        brew)    run_pkg brew install $pkgs || batch_ok=false ;;
        *) error "不支持的包管理器: $PKG_MGR"; return 1 ;;
    esac
    if [ "$batch_ok" = false ]; then
        warn "批量安装失败，改为逐个安装（自动跳过仓库中不存在的包）..."
        for p in $pkgs; do
            command -v "$p" >/dev/null 2>&1 && continue
            case "$PKG_MGR" in
                pacman)  run_pkg pacman -S --noconfirm --needed "$p" || failed="$failed $p" ;;
                apt-get) run_pkg apt-get install -y "$p" || failed="$failed $p" ;;
                dnf)     run_pkg dnf install -y "$p" || failed="$failed $p" ;;
                brew)    run_pkg brew install "$p" || failed="$failed $p" ;;
            esac
        done
        if [ -n "$failed" ]; then
            warn "以下软件包安装失败：$failed"
            [ "$PKG_MGR" = "pacman" ] && warn "pacman 若提示「目标未找到」，请先执行 sudo pacman -Syu 更新本地数据库"
        fi
    fi
    return 0
}

# 确保命令存在（curl / git 是后续步骤的前置依赖）
ensure_cmd() {
    local c="$1"
    command -v "$c" >/dev/null 2>&1 && return 0
    info "缺少 $c，先通过包管理器安装..."
    install_pkgs "$c"
    [ "$DRY_RUN" = true ] && return 0
    if command -v "$c" >/dev/null 2>&1; then
        return 0
    fi
    error "无法安装 $c，请手动安装后重试"
    return 1
}

# 定位仓库目录：优先脚本所在目录，其次 ~/dotfiles，最后克隆
resolve_repo_dir() {
    local script_dir=""
    script_dir=$(cd "$(dirname "$0")" 2>/dev/null && pwd) || script_dir=""
    if [ -n "$script_dir" ] && [ -f "$script_dir/zsh/auto_install_zsh.sh" ]; then
        REPO_DIR="$script_dir"
        info "使用本地仓库: $REPO_DIR"
    elif [ -f "$HOME/dotfiles/zsh/auto_install_zsh.sh" ]; then
        REPO_DIR="$HOME/dotfiles"
        info "使用已有仓库: $REPO_DIR"
    else
        REPO_DIR="$HOME/dotfiles"
        info "克隆 dotfiles 到 $REPO_DIR ..."
        if [ "$DRY_RUN" = true ]; then
            run echo "git clone（gitee.com/ruanfumin/dotfiles，失败回退 github.com/BadRuan/Dotfiles）→ $REPO_DIR"
        else
            git clone --depth=1 https://gitee.com/ruanfumin/dotfiles.git "$REPO_DIR" 2>/dev/null ||
            git clone --depth=1 https://github.com/BadRuan/Dotfiles.git "$REPO_DIR" 2>/dev/null || {
                error "dotfiles 克隆失败"
                return 1
            }
        fi
    fi
    # zsh / vim 子脚本固定使用 ~/dotfiles：不存在时软链到当前仓库，避免二次克隆造成两份配置
    if [ ! -e "$HOME/dotfiles" ] && [ "$REPO_DIR" != "$HOME/dotfiles" ]; then
        info "创建软链 ~/dotfiles → $REPO_DIR（子脚本固定使用 ~/dotfiles）"
        run ln -sfn "$REPO_DIR" "$HOME/dotfiles" || warn "软链 ~/dotfiles 创建失败"
    fi
    return 0
}

# ========== 步骤 1：国内镜像源替换 ==========

# 识别 chsrc 的系统换源对象（rhel 系不在 chsrc 覆盖范围，跳过以免写错仓库）
detect_chsrc_dish() {
    if [ "$(uname -s)" = "Darwin" ]; then
        echo "brew"
        return 0
    fi
    [ -r /etc/os-release ] || return 1
    local id id_like t
    id=$(. /etc/os-release; echo "${ID:-}")
    id_like=$(. /etc/os-release; echo "${ID_LIKE:-}")
    case "$id" in
        ubuntu|debian|fedora|arch|manjaro|deepin|openeuler)
            echo "$id"; return 0 ;;
        opensuse*|sles|suse)
            echo "opensuse"; return 0 ;;
    esac
    # 仅接受仓库兼容的家族回退；刻意不匹配 fedora/rhel（避免给 CentOS 等写 Fedora 源）
    for t in $id_like; do
        case "$t" in
            ubuntu) echo "ubuntu"; return 0 ;;
            debian) echo "debian"; return 0 ;;
            arch)   echo "arch"; return 0 ;;
            suse)   echo "opensuse"; return 0 ;;
        esac
    done
    return 1
}

# 安装 chsrc：Gitee 官方安装器（二进制也从 gitee releases 下载，全程不依赖 GitHub）
ensure_chsrc() {
    command -v chsrc >/dev/null 2>&1 && return 0
    export PATH="$HOME/.local/bin:$PATH"
    command -v chsrc >/dev/null 2>&1 && return 0
    info "安装 chsrc（Gitee 官方安装器，全程不依赖 GitHub）..."
    if [ "$DRY_RUN" = true ]; then
        run echo "curl -fsSL https://gitee.com/RubyMetric/chsrc/raw/main/tool/installer.sh | bash"
        return 0
    fi
    if curl -fsSL https://gitee.com/RubyMetric/chsrc/raw/main/tool/installer.sh | bash; then
        export PATH="$HOME/.local/bin:$PATH"
        command -v chsrc >/dev/null 2>&1 && return 0
    fi
    # 兜底：手动下载二进制到 ~/.local/bin
    local arch="" plat="" url=""
    case "$(uname -m)" in
        x86_64|amd64)   arch="x64" ;;
        aarch64|arm64)  arch="aarch64" ;;
    esac
    case "$(uname -s)" in
        Linux)  plat="linux" ;;
        Darwin) plat="macos" ;;
    esac
    if [ -n "$arch" ] && [ -n "$plat" ]; then
        url="https://gitee.com/RubyMetric/chsrc/releases/download/pre/chsrc-${arch}-${plat}"
        warn "安装器失败，改用手动下载二进制: $url"
        mkdir -p "$HOME/.local/bin"
        if curl -fsSL "$url" -o "$HOME/.local/bin/chsrc" && chmod +x "$HOME/.local/bin/chsrc"; then
            export PATH="$HOME/.local/bin:$PATH"
            command -v chsrc >/dev/null 2>&1 && return 0
        fi
    fi
    error "chsrc 安装失败"
    return 1
}

do_chsrc() {
    if ! ensure_chsrc; then
        R_MIRROR="✗ 失败（chsrc 安装失败）"
        return 1
    fi
    local dish=""
    if dish=$(detect_chsrc_dish); then
        info "切换系统软件源：chsrc set $dish（自动测速选最快镜像）..."
        local rc=0
        if [ "$dish" = "brew" ]; then
            # Homebrew 绝不能用 sudo 执行
            run chsrc set brew || rc=$?
        else
            run_priv chsrc set "$dish" || rc=$?
        fi
        if [ "$rc" -eq 0 ]; then
            success "系统软件源切换完成（chsrc set $dish）"
            R_MIRROR="✓ 完成 (chsrc $dish)"
        else
            warn "chsrc set $dish 执行失败（可执行 chsrc ls os 查看支持对象）"
            R_MIRROR="✗ 失败"
        fi
    else
        warn "chsrc 未识别当前发行版，跳过系统换源（可执行 chsrc ls os 查看支持对象，或改用 --mirror-tool linuxmirrors）"
        R_MIRROR="⚠ 未识别发行版"
        return 0
    fi
    # 开发工具源：仅交互模式询问（默认不改）
    if [ "$UNATTENDED" = false ]; then
        if ask "同时切换 pip / npm 等开发工具源？" N; then
            run chsrc set pip || warn "chsrc set pip 失败"
            run chsrc set npm || warn "chsrc set npm 失败"
        fi
    fi
    return 0
}

do_linuxmirrors() {
    local tmp="/tmp/LinuxMirrors_$$.sh"
    info "下载 LinuxMirrors 脚本..."
    if [ "$DRY_RUN" = true ]; then
        run echo "curl -fsSL https://linuxmirrors.cn/main.sh -o $tmp（备用 edgeone / gitee）"
    else
        curl -fsSL https://linuxmirrors.cn/main.sh -o "$tmp" 2>/dev/null ||
        curl -fsSL https://edgeone.linuxmirrors.cn/main.sh -o "$tmp" 2>/dev/null ||
        curl -fsSL https://gitee.com/SuperManito/LinuxMirrors/raw/main/ChangeMirrors.sh -o "$tmp" 2>/dev/null
        if [ ! -s "$tmp" ]; then
            warn "LinuxMirrors 脚本下载失败"
            rm -f "$tmp"
            R_MIRROR="✗ 失败（下载失败）"
            return 1
        fi
    fi
    if [ -n "$MIRROR_SRC" ]; then
        info "运行 LinuxMirrors（--source $MIRROR_SRC）..."
        if run_priv bash "$tmp" --source "$MIRROR_SRC"; then
            success "系统软件源已切换为 $MIRROR_SRC"
            R_MIRROR="✓ 完成 (LinuxMirrors → $MIRROR_SRC)"
        else
            warn "LinuxMirrors 执行失败"
            R_MIRROR="✗ 失败"
        fi
    elif [ "$UNATTENDED" = true ]; then
        warn "静默模式使用 LinuxMirrors 需指定 --mirror-src <镜像域名>，已跳过"
        R_MIRROR="⚠ 已跳过（缺 --mirror-src）"
    else
        info "进入 LinuxMirrors 交互菜单（可手动选择镜像与选项）..."
        if run_priv bash "$tmp"; then
            R_MIRROR="✓ 完成 (LinuxMirrors)"
        else
            R_MIRROR="✗ 失败"
        fi
    fi
    [ "$DRY_RUN" = true ] || rm -f "$tmp"
    return 0
}

do_mirror() {
    if [ "$SKIP_MIRROR" = true ]; then
        R_MIRROR="已跳过 (--no-mirror)"
        return 0
    fi
    local tool="$MIRROR_TOOL"
    if [ "$UNATTENDED" = false ]; then
        if ! ask "是否替换为国内镜像源？" Y; then
            R_MIRROR="已跳过（用户选择）"
            return 0
        fi
        # 手动选择换源工具（仅终端交互时）
        if [ "$MIRROR_TOOL" = "chsrc" ] && [ -z "$MIRROR_SRC" ] && [ -t 0 ]; then
            echo "  选择换源工具："
            echo "    1) chsrc（推荐：Gitee 源安装、自动测速）"
            echo "    2) LinuxMirrors（官网脚本，交互菜单细粒度配置）"
            echo "    3) 跳过镜像源替换"
            local c=""
            printf "  输入 [1/2/3]（默认 1）: "
            read -r c || c=""
            case "$c" in
                2) tool="linuxmirrors" ;;
                3) R_MIRROR="已跳过（用户选择）"; return 0 ;;
                *) tool="chsrc" ;;
            esac
        fi
    fi
    info "镜像源替换工具: $tool"
    case "$tool" in
        chsrc)        do_chsrc ;;
        linuxmirrors) do_linuxmirrors ;;
        *) error "未知换源工具: $tool"; R_MIRROR="✗ 参数错误" ;;
    esac
    return 0
}

# ========== 步骤 2：常见工具安装 ==========

do_tools() {
    if [ "$SKIP_TOOLS" = true ]; then
        R_TOOLS="已跳过 (--no-tools)"
        return 0
    fi
    local p missing="" still=""
    for p in $TOOLS; do
        command -v "$p" >/dev/null 2>&1 || missing="$missing $p"
    done
    if [ -z "$missing" ]; then
        success "常见工具已全部安装：$TOOLS"
        R_TOOLS="✓ 已就绪"
        return 0
    fi
    install_pkgs "$missing"
    if [ "$DRY_RUN" = true ]; then
        R_TOOLS="✓ (dry-run)$missing"
        return 0
    fi
    for p in $TOOLS; do
        command -v "$p" >/dev/null 2>&1 || still="$still $p"
    done
    if [ -z "$still" ]; then
        success "常见工具安装完成：$TOOLS"
        R_TOOLS="✓ 完成"
    else
        warn "以下工具安装失败或仓库中不存在：$still"
        warn "旧版发行版仓库可能没有 lsd / btop，可跳过或参考 mirror/README.md 手动安装"
        R_TOOLS="⚠ 部分失败:$still"
    fi
    return 0
}

# ========== 步骤 3：zsh 配置 ==========

do_zsh() {
    if [ "$SKIP_ZSH" = true ]; then
        R_ZSH="已跳过 (--no-zsh)"
        return 0
    fi
    if [ "$UNATTENDED" = false ]; then
        if ! ask "配置 zsh（Oh-My-Zsh + powerlevel10k + 插件 + Zinit）？" Y; then
            R_ZSH="已跳过（用户选择）"
            return 0
        fi
    fi
    local s="$REPO_DIR/zsh/auto_install_zsh.sh"
    if [ ! -f "$s" ]; then
        warn "未找到 $s"
        R_ZSH="✗ 失败（脚本缺失）"
        return 0
    fi
    info "运行 zsh 自动安装脚本..."
    if run bash "$s" --unattended; then
        success "zsh 环境配置完成"
        R_ZSH="✓ 完成"
    else
        warn "zsh 配置脚本执行失败，请检查上方输出"
        R_ZSH="✗ 失败"
    fi
    return 0
}

# ========== 步骤 4：vim 配置 ==========

do_vim() {
    if [ "$SKIP_VIM" = true ]; then
        R_VIM="已跳过 (--no-vim)"
        return 0
    fi
    if [ "$UNATTENDED" = false ]; then
        if ! ask "配置 vim（vim-plug + 全部插件）？" Y; then
            R_VIM="已跳过（用户选择）"
            return 0
        fi
        if [ "$WITH_YCM" = false ]; then
            if ask "是否编译安装 YouCompleteMe 补全引擎？（体积大、需编译）" N; then
                WITH_YCM=true
            fi
        fi
    fi
    local s="$REPO_DIR/vim/auto_install_vim.sh"
    if [ ! -f "$s" ]; then
        warn "未找到 $s"
        R_VIM="✗ 失败（脚本缺失）"
        return 0
    fi
    local args="--unattended"
    [ "$WITH_YCM" = true ] && args="$args --with-ycm"
    info "运行 vim 自动安装脚本..."
    if run bash "$s" $args; then
        success "vim 环境配置完成"
        R_VIM="✓ 完成"
    else
        warn "vim 配置脚本执行失败，请检查上方输出"
        R_VIM="✗ 失败"
    fi
    return 0
}

# ========== 步骤 5：tmux 配置 ==========

do_tmux() {
    if [ "$SKIP_TMUX" = true ]; then
        R_TMUX="已跳过 (--no-tmux)"
        return 0
    fi
    if [ "$UNATTENDED" = false ]; then
        if ! ask "配置 tmux（tmux.conf 软链 + TPM + 插件）？" Y; then
            R_TMUX="已跳过（用户选择）"
            return 0
        fi
    fi
    local src="$REPO_DIR/tmux/tmux.conf"
    if [ ! -f "$src" ]; then
        warn "未找到 $src"
        R_TMUX="✗ 失败（tmux.conf 缺失）"
        return 0
    fi
    # 备份并软链 ~/.tmux.conf
    if [ -L "$HOME/.tmux.conf" ]; then
        if [ "$(readlink "$HOME/.tmux.conf")" = "$src" ]; then
            # shellcheck disable=SC2088  # 展示用字面 ~，不需要展开
            info "~/.tmux.conf 软链已指向 $src，跳过"
        else
            info "更新 ~/.tmux.conf 软链 → $src"
            run ln -sfn "$src" "$HOME/.tmux.conf"
        fi
    elif [ -e "$HOME/.tmux.conf" ]; then
        local bk
        bk="$HOME/.tmux.conf.backup.$(date +%Y%m%d%H%M%S)"
        info "备份现有 ~/.tmux.conf → $bk"
        run cp -a "$HOME/.tmux.conf" "$bk"
        run ln -sfn "$src" "$HOME/.tmux.conf"
    else
        info "创建软链 ~/.tmux.conf → $src"
        run ln -sfn "$src" "$HOME/.tmux.conf"
    fi
    # TPM 插件管理器（Gitee 镜像优先）
    local tpm="$HOME/.tmux/plugins/tpm"
    if [ -d "$tpm" ]; then
        info "TPM 已存在：$tpm"
    else
        info "克隆 TPM（Gitee 镜像优先）..."
        if run git clone --depth=1 https://gitee.com/github_dep/tpm.git "$tpm"; then
            success "TPM 克隆完成（Gitee）"
        else
            warn "Gitee 克隆失败，回退 GitHub..."
            run rm -rf "$tpm"
            if run git clone --depth=1 https://github.com/tmux-plugins/tpm.git "$tpm"; then
                success "TPM 克隆完成（GitHub）"
            else
                warn "TPM 克隆失败，可稍后手动重试：git clone --depth=1 https://gitee.com/github_dep/tpm.git ~/.tmux/plugins/tpm"
            fi
        fi
    fi
    # 无人值守安装 TPM 插件（Prefix + I 的命令行等价方式）
    if [ -x "$tpm/bin/install_plugins" ]; then
        info "安装 tmux 插件（TPM）..."
        if run "$tpm/bin/install_plugins"; then
            success "tmux 插件安装完成"
        else
            warn "部分 tmux 插件安装失败（插件仓库在 GitHub）；可进入 tmux 按 Prefix + I 重试，或参考 tmux/README.md 使用加速代理"
        fi
    fi
    R_TMUX="✓ 完成"
    return 0
}

# ========== 汇总报告 ==========

print_report() {
    echo
    echo -e "${FMT_BOLD}==================== 执行结果 ====================${FMT_RESET}"
    if [ "$DRY_RUN" = true ]; then
        echo -e "  ${FMT_YELLOW}(dry-run：以上均为预演，未实际执行)${FMT_RESET}"
    fi
    printf "  %-8s %s\n" "镜像源" "$R_MIRROR"
    printf "  %-8s %s\n" "常见工具" "$R_TOOLS"
    printf "  %-8s %s\n" "zsh" "$R_ZSH"
    printf "  %-8s %s\n" "vim" "$R_VIM"
    printf "  %-8s %s\n" "tmux" "$R_TMUX"
    echo -e "${FMT_BOLD}==================================================${FMT_RESET}"
    if [ "$DRY_RUN" = true ]; then
        return 0
    fi
    echo
    case "$R_ZSH" in
        ✓*) info "zsh：执行 exec zsh 或重开终端生效" ;;
    esac
    case "$R_TMUX" in
        ✓*) info "tmux：插件未装全时进入 tmux 按 Prefix + I（Ctrl+b I）重装，见 tmux/README.md" ;;
    esac
    case "$R_MIRROR" in
        ✓*) info "换源回退：chsrc reset <对象>，详见 mirror/README.md" ;;
    esac
    case "$R_MIRROR$R_TOOLS$R_ZSH$R_VIM$R_TMUX" in
        *✗*) warn "存在失败步骤，请根据上方 [错误]/[警告] 处理后重新运行本脚本" ;;
    esac
    return 0
}

# ========== 主流程 ==========

main() {
    echo -e "${FMT_BOLD}====================================================${FMT_RESET}"
    echo -e "${FMT_BOLD}    Dotfiles 一键汇总安装（换源 / 工具 / zsh / vim / tmux）${FMT_RESET}"
    echo -e "${FMT_BOLD}====================================================${FMT_RESET}"
    if [ "$DRY_RUN" = true ]; then
        warn "dry-run 模式：仅打印动作，不实际执行"
    fi

    detect_pkg_mgr || exit 1
    setup_sudo
    ensure_cmd curl || exit 1
    ensure_cmd git || exit 1
    resolve_repo_dir || exit 1

    do_mirror
    do_tools
    do_zsh
    do_vim
    do_tmux
    print_report
}

main "$@"
