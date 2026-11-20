#!/bin/bash
#
# Dotfiles Vim 自动安装脚本
#
# 功能：
#   1. 自动检测系统包管理器并安装 git、vim、fzf
#   2. 克隆 dotfiles 仓库并创建 ~/.vimrc、~/.vim/vimrc 软链接
#   3. 安装 vim-plug 插件管理器（国内镜像优先）
#   4. 安装 vimrc 中的全部插件（GitCode 镜像 → GitHub 加速代理 → GitHub 直连，逐级回退）
#   5. 可选安装 YouCompleteMe 代码补全引擎（--with-ycm）
#   6. 安装完成后执行 Vim 启动自检
#
# 支持的系统：
#   - Arch Linux / Manjaro (pacman)
#   - Debian / Ubuntu (apt-get)
#   - Fedora (dnf)
#   - macOS / Linux (Homebrew)
#
# 使用方式：
#   sh -c "$(curl -fsSL https://gitee.com/ruanfumin/dotfiles/raw/master/vim/auto_install_vim.sh)"
#
# 无人值守模式（跳过所有交互确认）：
#   curl -fsSL https://gitee.com/ruanfumin/dotfiles/raw/master/vim/auto_install_vim.sh | bash -s -- --unattended
#
# 同时安装 YouCompleteMe（体积大、需编译，默认跳过）：
#   bash auto_install_vim.sh --with-ycm
#
# 说明：
#   插件从国内镜像克隆后，脚本会把 git origin 改写回 GitHub 规范地址（与 vimrc 中的
#   Plug 短名保持一致，通过 vim-plug 的 URI 校验），并在插件仓库内配置 url.insteadOf
#   重定向，因此之后在 Vim 内执行 :PlugUpdate 也会自动走国内镜像加速。
#

set -e

# ========== 颜色定义 ==========
FMT_RED='\033[31m'
FMT_GREEN='\033[32m'
FMT_YELLOW='\033[33m'
FMT_BLUE='\033[34m'
FMT_BOLD='\033[1m'
FMT_RESET='\033[0m'

# ========== 全局变量 ==========
UNATTENDED=false
WITH_YCM=false
YCM_INSTALLED=false

DOTFILES_REPO_CN="https://gitee.com/ruanfumin/dotfiles.git"
DOTFILES_REPO_INTL="https://github.com/BadRuan/Dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"

VIM_DIR="$HOME/.vim"
AUTOLOAD_DIR="$VIM_DIR/autoload"
PLUGGED_DIR="$VIM_DIR/plugged"

# GitHub 加速代理（国内可达，用于 GitCode 未收录的仓库）
GH_PROXY_1="https://gh-proxy.com"
GH_PROXY_2="https://ghfast.top"

# 插件清单：每行 "owner/repo|GitCode镜像路径"，GitCode 路径留空表示无镜像、直接走加速代理
PLUGIN_LIST='
vim-airline/vim-airline|gh_mirrors/vi/vim-airline
vim-airline/vim-airline-themes|gh_mirrors/vi/vim-airline-themes
yianwillis/vimcdoc|gh_mirrors/vi/vimcdoc
vim-syntastic/syntastic|gh_mirrors/sy/syntastic
tpope/vim-surround|
junegunn/fzf|gh_mirrors/fz/fzf
junegunn/fzf.vim|gh_mirrors/fz/fzf.vim
sheerun/vim-polyglot|
airblade/vim-gitgutter|gh_mirrors/vi/vim-gitgutter
preservim/nerdcommenter|gh_mirrors/ne/nerdcommenter
whatyouhide/vim-gotham|gh_mirrors/vi/vim-gotham
fatih/vim-go|gh_mirrors/vi/vim-go
vim-python/python-syntax|
yuezk/vim-js|
'

# ========== 工具函数 ==========

info()    { printf "${FMT_BLUE}[INFO]${FMT_RESET} %s\n" "$*"; }
success() { printf "${FMT_GREEN}[OK]${FMT_RESET} %s\n" "$*"; }
warn()    { printf "${FMT_YELLOW}[WARN]${FMT_RESET} %s\n" "$*"; }
error()   { printf "${FMT_RED}[ERROR]${FMT_RESET} %s\n" "$*" >&2; }

command_exists() {
    command -v "$1" > /dev/null 2>&1
}

# git 克隆统一参数：禁交互凭据提示 + 低速中断（避免坏镜像长时间挂起，兼容 macOS 无 timeout 命令）
git_clone() {
    GIT_TERMINAL_PROMPT=0 git -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=30 \
        clone --depth=1 -q "$@"
}

# 使用包管理器安装软件包
package_install() {
    pkg_mgr="$1"
    package_name="$2"
    info "使用 $pkg_mgr 安装 $package_name ..."

    case "$pkg_mgr" in
        pacman)
            $SUDO pacman -S --noconfirm "$package_name"
            ;;
        apt-get)
            $SUDO apt-get update -y
            $SUDO apt-get install -y "$package_name"
            ;;
        dnf)
            $SUDO dnf install -y "$package_name"
            ;;
        brew)
            brew install "$package_name"
            ;;
        *)
            error "不支持的包管理器: $pkg_mgr"
            return 1
            ;;
    esac
}

# 生成某个插件的镜像 URL 尝试顺序：GitCode → 加速代理1 → 加速代理2 → GitHub 直连
plugin_urls() {
    repo="$1"
    gitcode_path="$2"
    if [ -n "$gitcode_path" ]; then
        echo "https://gitcode.com/${gitcode_path}.git"
    fi
    echo "${GH_PROXY_1}/https://github.com/${repo}.git"
    echo "${GH_PROXY_2}/https://github.com/${repo}.git"
    echo "https://github.com/${repo}.git"
}

# 安装单个插件：按镜像链克隆，成功后改写 origin 并配置国内加速重定向
install_plugin() {
    repo="$1"
    gitcode_path="$2"
    dir="${repo##*/}"
    target="$PLUGGED_DIR/$dir"
    gh_url="https://github.com/${repo}.git"

    if [ -d "$target" ]; then
        success "$dir 已存在，跳过"
        return 0
    fi

    for url in $(plugin_urls "$repo" "$gitcode_path"); do
        info "安装插件 $dir（$url）..."
        rm -rf "$target" 2>/dev/null || true
        if git_clone "$url" "$target" 2>/dev/null; then
            # origin 改写为 GitHub 规范地址，保证 vim-plug URI 校验通过（vimrc 使用 Plug 短名）
            git -C "$target" remote set-url origin "$gh_url" 2>/dev/null || true
            # 若克隆自国内镜像，配置 insteadOf 重定向，使 :PlugUpdate 的 git fetch 继续走该镜像
            if [ "$url" != "$gh_url" ]; then
                git -C "$target" config url."$url".insteadOf "$gh_url" 2>/dev/null || true
            fi
            success "$dir 安装完成"
            return 0
        fi
        warn "$dir 该镜像克隆失败，尝试下一个源..."
    done

    rm -rf "$target" 2>/dev/null || true
    error "$dir 安装失败（所有镜像源均不可用）"
    return 1
}

# 安装 vim-plug（下载 plug.vim 到 ~/.vim/autoload/）
install_vim_plug() {
    if [ -f "$AUTOLOAD_DIR/plug.vim" ]; then
        success "vim-plug 已安装，跳过: $AUTOLOAD_DIR/plug.vim"
        return 0
    fi

    # 方式一：直接下载单文件 plug.vim
    for url in \
        "https://raw.gitcode.com/gh_mirrors/vi/vim-plug/raw/master/plug.vim" \
        "${GH_PROXY_1}/https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" \
        "${GH_PROXY_2}/https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" \
        "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"; do
        info "下载 vim-plug: $url"
        if curl -fL --connect-timeout 15 --max-time 120 -o "$AUTOLOAD_DIR/plug.vim.tmp" "$url" 2>/dev/null \
            && [ -s "$AUTOLOAD_DIR/plug.vim.tmp" ] \
            && grep -q "plug#begin" "$AUTOLOAD_DIR/plug.vim.tmp" 2>/dev/null; then
            mv "$AUTOLOAD_DIR/plug.vim.tmp" "$AUTOLOAD_DIR/plug.vim"
            success "vim-plug 下载完成"
            return 0
        fi
        rm -f "$AUTOLOAD_DIR/plug.vim.tmp" 2>/dev/null || true
    done

    # 方式二：克隆仓库后复制
    tmpdir="$VIM_DIR/.plug-tmp.$$"
    for url in \
        "https://gitcode.com/gh_mirrors/vi/vim-plug.git" \
        "${GH_PROXY_1}/https://github.com/junegunn/vim-plug.git" \
        "https://github.com/junegunn/vim-plug.git"; do
        info "克隆 vim-plug: $url"
        rm -rf "$tmpdir" 2>/dev/null || true
        if git_clone "$url" "$tmpdir" 2>/dev/null && [ -f "$tmpdir/plug.vim" ]; then
            cp "$tmpdir/plug.vim" "$AUTOLOAD_DIR/plug.vim"
            rm -rf "$tmpdir" 2>/dev/null || true
            success "vim-plug 安装完成"
            return 0
        fi
    done

    rm -rf "$tmpdir" 2>/dev/null || true
    error "vim-plug 安装失败（所有镜像源均不可用）"
    return 1
}

# 安装 YouCompleteMe（可选，--with-ycm）
install_ycm() {
    target="$PLUGGED_DIR/YouCompleteMe"
    gh_url="https://github.com/ycm-core/YouCompleteMe.git"

    if [ -d "$target" ]; then
        success "YouCompleteMe 已存在，跳过克隆"
    else
        info "克隆 YouCompleteMe（含 ycmd 子模块，体积较大）..."
        # 主仓库走 GitCode 镜像；子模块 ycmd 无国内镜像，通过加速代理重写 github.com/ 前缀
        rm -rf "$target" 2>/dev/null || true
        if GIT_TERMINAL_PROMPT=0 git \
                -c url."${GH_PROXY_1}/https://github.com/".insteadOf="https://github.com/" \
                -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=60 \
                clone --depth=1 --recursive --shallow-submodules -q \
                "https://gitcode.com/gh_mirrors/yo/YouCompleteMe.git" "$target" 2>/dev/null \
            || GIT_TERMINAL_PROMPT=0 git \
                -c url."${GH_PROXY_1}/https://github.com/".insteadOf="https://github.com/" \
                -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=60 \
                clone --depth=1 --recursive --shallow-submodules -q \
                "$gh_url" "$target" 2>/dev/null; then
            git -C "$target" remote set-url origin "$gh_url" 2>/dev/null || true
            git -C "$target" config url."https://gitcode.com/gh_mirrors/yo/YouCompleteMe.git".insteadOf "$gh_url" 2>/dev/null || true
            success "YouCompleteMe 克隆完成"
        else
            rm -rf "$target" 2>/dev/null || true
            error "YouCompleteMe 克隆失败"
            return 1
        fi
    fi

    # 编译依赖检查
    if ! command_exists cmake || ! command_exists python3; then
        warn "编译 YouCompleteMe 需要 cmake 和 python3，尝试安装..."
        case "$pkg_mgr" in
            pacman)  package_install pacman "cmake" || true; package_install pacman "python" || true ;;
            apt-get) package_install apt-get "cmake" || true; package_install apt-get "python3" || true; package_install apt-get "build-essential" || true ;;
            dnf)     package_install dnf "cmake" || true; package_install dnf "python3" || true; package_install dnf "gcc-c++" || true ;;
            brew)    package_install brew "cmake" || true; package_install brew "python3" || true ;;
        esac
    fi

    info "编译 YouCompleteMe（install.py 需下载 clangd，可能耗时较长）..."
    if (cd "$target" && python3 install.py --clangd-completer); then
        success "YouCompleteMe 编译完成"
    else
        warn "YouCompleteMe 编译失败（国内网络通常因无法访问 GitHub Releases 下载 clangd 导致）"
        warn "可任选以下方式手动完成："
        warn "  1) 安装系统 clangd 后重新编译（Fedora: dnf install clang-tools-extra / Debian: apt install clangd / Arch: pacman -S clang）"
        warn "     cd $target && python3 install.py --clangd-completer --clangd-binary-path \$(command -v clangd)"
        warn "  2) 设置代理后重试：https_proxy=http://127.0.0.1:7890 python3 install.py --clangd-completer"
        warn "未完成编译前，Vim 启动时 YouCompleteMe 会提示不可用，不影响其他插件。"
    fi
}

# Vim 启动自检
run_vim_check() {
    if ! command_exists vim; then
        warn "未检测到 vim 命令，跳过启动自检"
        return 0
    fi
    info "执行 Vim 启动自检..."
    vim_out=$(vim --not-a-term -Nu "$HOME/.vimrc" -c 'qa!' </dev/null 2>&1 || true)
    if printf '%s' "$vim_out" | grep -qE "E[0-9]{2,}|Error detected"; then
        warn "Vim 启动时检测到错误信息："
        printf '%s\n' "$vim_out" | grep -E "E[0-9]{2,}|Error detected" | head -5
    else
        success "Vim 启动自检通过"
    fi
}

# ========== 参数解析 ==========
for arg in "$@"; do
    case "$arg" in
        --unattended)
            UNATTENDED=true
            ;;
        --with-ycm)
            WITH_YCM=true
            ;;
        -h|--help)
            echo "用法: bash auto_install_vim.sh [--unattended] [--with-ycm]"
            echo "  --unattended  无人值守模式，跳过所有交互确认"
            echo "  --with-ycm    同时安装 YouCompleteMe（体积大、需编译，默认跳过）"
            exit 0
            ;;
    esac
done

# root 免 sudo；无人值守模式用 sudo -n 快速失败，避免管道安装时卡在密码提示
if [ "$(id -u)" = "0" ]; then
    SUDO=""
elif [ "$UNATTENDED" = true ]; then
    SUDO="sudo -n"
else
    SUDO="sudo"
fi

# ========== 主流程 ==========

echo ""
printf "${FMT_BOLD}========================================${FMT_RESET}\n"
printf "${FMT_BOLD}   Dotfiles Vim 环境自动安装脚本${FMT_RESET}\n"
printf "${FMT_BOLD}========================================${FMT_RESET}\n"
echo ""

# --- 1. 检测包管理器 ---
info "检测系统包管理器..."
pkg_mgr=""
if command_exists pacman; then
    pkg_mgr="pacman"
elif command_exists apt-get; then
    pkg_mgr="apt-get"
elif command_exists dnf; then
    pkg_mgr="dnf"
elif command_exists brew; then
    pkg_mgr="brew"
fi
if [ -n "$pkg_mgr" ]; then
    success "包管理器: $pkg_mgr"
else
    warn "未检测到支持的包管理器（pacman/apt-get/dnf/brew）"
    if command_exists git && command_exists vim; then
        warn "git 与 vim 已存在，跳过依赖安装，继续执行"
    else
        error "缺少 git 或 vim，且无可用包管理器，请先手动安装后重试"
        exit 1
    fi
fi

# --- 2. 安装 git ---
if command_exists git; then
    success "Git 已安装: $(git --version)"
elif [ -n "$pkg_mgr" ]; then
    info "Git 未安装，正在安装..."
    package_install "$pkg_mgr" git
    success "Git 安装完成"
else
    error "Git 未安装"
    exit 1
fi

# --- 3. 安装 vim ---
if command_exists vim; then
    success "Vim 已安装: $(vim --version | head -1)"
elif [ -n "$pkg_mgr" ]; then
    info "Vim 未安装，正在安装..."
    package_install "$pkg_mgr" vim || warn "Vim 安装失败，请手动安装"
else
    warn "Vim 未安装"
fi

# --- 4. 安装 fzf（可选，fzf.vim 模糊查找依赖）---
if command_exists fzf; then
    success "fzf 已安装: $(fzf --version 2>/dev/null | head -1)"
elif [ -n "$pkg_mgr" ]; then
    info "fzf 未安装，正在安装（fzf.vim 模糊查找需要）..."
    package_install "$pkg_mgr" fzf \
        && success "fzf 安装完成" \
        || warn "fzf 安装失败，:Files/:Rg 等模糊查找功能不可用，可稍后手动安装"
else
    warn "fzf 未安装，:Files/:Rg 等模糊查找功能不可用，可稍后手动安装"
fi

# --- 5. 克隆 dotfiles 仓库 ---
info "下载 dotfiles 配置文件..."
if [ -d "$DOTFILES_DIR" ]; then
    success "dotfiles 目录已存在，跳过克隆: $DOTFILES_DIR"
    if [ -d "$DOTFILES_DIR/.git" ]; then
        info "尝试更新 dotfiles..."
        (cd "$DOTFILES_DIR" && GIT_TERMINAL_PROMPT=0 git pull --ff-only 2>/dev/null) || warn "dotfiles 更新失败，使用现有版本"
    fi
else
    if git_clone "$DOTFILES_REPO_CN" "$DOTFILES_DIR" 2>/dev/null; then
        success "dotfiles 克隆成功（Gitee 国内源）"
    else
        warn "国内源克隆失败，尝试国际源..."
        rm -rf "$DOTFILES_DIR" 2>/dev/null || true
        if git_clone "$DOTFILES_REPO_INTL" "$DOTFILES_DIR" 2>/dev/null; then
            success "dotfiles 克隆成功（GitHub 国际源）"
        else
            warn "国际源克隆失败，尝试 GitHub 加速代理..."
            rm -rf "$DOTFILES_DIR" 2>/dev/null || true
            if git_clone "${GH_PROXY_1}/${DOTFILES_REPO_INTL}" "$DOTFILES_DIR" 2>/dev/null \
                || git_clone "${GH_PROXY_2}/${DOTFILES_REPO_INTL}" "$DOTFILES_DIR" 2>/dev/null; then
                success "dotfiles 克隆成功（GitHub 加速代理）"
            else
                error "dotfiles 克隆失败（国内源、国际源和加速代理均不可用）"
                exit 1
            fi
        fi
    fi
fi

if [ ! -f "$DOTFILES_DIR/vim/vimrc" ]; then
    error "未找到 $DOTFILES_DIR/vim/vimrc，请检查 dotfiles 仓库是否完整"
    exit 1
fi

# --- 6. 创建 vimrc 软链接 ---
info "配置 vimrc 软链接..."
mkdir -p "$AUTOLOAD_DIR" "$PLUGGED_DIR"
ts=$(date +%Y%m%d%H%M%S)

# 备份已存在的真实文件（软链接直接替换，指向旧软链接的目标文件不受影响）
if [ -f "$HOME/.vimrc" ] && [ ! -L "$HOME/.vimrc" ]; then
    warn "已备份原有 ~/.vimrc 到 $HOME/.vimrc.backup.$ts"
    mv "$HOME/.vimrc" "$HOME/.vimrc.backup.$ts"
fi
if [ -f "$VIM_DIR/vimrc" ] && [ ! -L "$VIM_DIR/vimrc" ]; then
    warn "已备份原有 ~/.vim/vimrc 到 $VIM_DIR/vimrc.backup.$ts"
    mv "$VIM_DIR/vimrc" "$VIM_DIR/vimrc.backup.$ts"
fi

ln -sfn "$DOTFILES_DIR/vim/vimrc" "$VIM_DIR/vimrc"
ln -sfn "$DOTFILES_DIR/vim/vimrc" "$HOME/.vimrc"
success "软链接已创建: ~/.vimrc 与 ~/.vim/vimrc -> $DOTFILES_DIR/vim/vimrc"

# --- 7. 安装 vim-plug ---
info "安装 vim-plug 插件管理器..."
install_vim_plug || error "vim-plug 安装失败，插件无法加载，请检查网络后重新运行脚本"

# --- 8. 安装插件 ---
info "安装 Vim 插件（GitCode 镜像 → GitHub 加速代理 → GitHub 直连）..."
FAILED_PLUGINS=""
while IFS='|' read -r repo gitcode_path; do
    [ -z "$repo" ] && continue
    install_plugin "$repo" "$gitcode_path" || FAILED_PLUGINS="$FAILED_PLUGINS ${repo##*/}"
done <<PLUGIN_LIST_EOF
$PLUGIN_LIST
PLUGIN_LIST_EOF

# --- 9. 安装 YouCompleteMe（可选）---
if [ "$WITH_YCM" != true ] && [ "$UNATTENDED" != true ] && [ -t 0 ]; then
    echo ""
    printf "${FMT_YELLOW}是否安装 YouCompleteMe 代码补全引擎？（体积大、需编译，国内网络可能需要手动配置）[y/N] ${FMT_RESET}"
    read -r opt
    case "$opt" in
        [Yy]*) WITH_YCM=true ;;
    esac
fi
if [ "$WITH_YCM" = true ]; then
    info "安装 YouCompleteMe..."
    if install_ycm; then
        YCM_INSTALLED=true
    else
        YCM_INSTALLED=false
        warn "YouCompleteMe 安装未完成，可稍后重新运行: bash $0 --with-ycm"
    fi
else
    info "跳过 YouCompleteMe（如需安装: bash auto_install_vim.sh --with-ycm）"
fi

# --- 10. Vim 启动自检 ---
run_vim_check

# --- 完成 ---
echo ""
printf "${FMT_BOLD}========================================${FMT_RESET}\n"
printf "${FMT_GREEN}${FMT_BOLD}   安装完成！${FMT_RESET}\n"
printf "${FMT_BOLD}========================================${FMT_RESET}\n"
echo ""
echo "已安装的组件："
printf "  ${FMT_GREEN}✓${FMT_RESET} vimrc 配置（~/.vimrc 与 ~/.vim/vimrc 软链接）\n"
printf "  ${FMT_GREEN}✓${FMT_RESET} vim-plug 插件管理器\n"
printf "  ${FMT_GREEN}✓${FMT_RESET} Vim 插件（airline、vimcdoc、syntastic、surround、fzf、polyglot、\n"
printf "    gitgutter、nerdcommenter、gotham 主题、vim-go、python-syntax、vim-js）\n"
if [ "$YCM_INSTALLED" = true ]; then
    printf "  ${FMT_GREEN}✓${FMT_RESET} YouCompleteMe（如编译失败请见上方提示）\n"
fi
if [ -n "$FAILED_PLUGINS" ]; then
    echo ""
    printf "${FMT_YELLOW}以下插件安装失败，请检查网络后重新运行脚本补齐：${FMT_RESET}\n"
    echo "  $FAILED_PLUGINS"
fi
echo ""
echo "后续步骤："
printf "  1. 打开 ${FMT_BOLD}vim${FMT_RESET} 即可使用（配置与插件已就绪）\n"
printf "  2. Vim 内 ${FMT_BOLD}:PlugStatus${FMT_RESET} 查看插件状态，${FMT_BOLD}:PlugUpdate${FMT_RESET} 更新插件（自动走国内镜像）\n"
echo "  3. 重新运行本脚本可补齐缺失的插件（已安装的自动跳过）"
echo ""
