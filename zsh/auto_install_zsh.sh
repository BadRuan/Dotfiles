#!/bin/bash
#
# Dotfiles ZSH 自动安装脚本
#
# 功能：
#   1. 自动检测并使用系统包管理器安装 git 和 zsh
#   2. 克隆 dotfiles 仓库并创建 .zshrc 软链接
#   3. 安装 Oh-My-Zsh（使用国内镜像源）
#   4. 安装 powerlevel10k 主题
#   5. 安装 zsh 插件：autosuggestions、syntax-highlighting、autocomplete
#   6. 安装 Zinit 插件管理器
#
# 支持的系统：
#   - Arch Linux / Manjaro (pacman)
#   - Debian / Ubuntu (apt-get)
#   - Fedora (dnf)
#   - macOS / Linux (Homebrew)
#
# 使用方式：
#   sh -c "$(curl -fsSL https://gitee.com/ruanfumin/dotfiles/raw/master/zsh/auto_install_zsh.sh)"
#
# 无人值守模式（跳过所有交互确认）：
#   curl -fsSL https://gitee.com/ruanfumin/dotfiles/raw/master/zsh/auto_install_zsh.sh | bash -s -- --unattended
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
DOTFILES_REPO_CN="https://gitee.com/ruanfumin/dotfiles.git"
DOTFILES_REPO_INTL="https://github.com/ruanfumin/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"

# 国内镜像源（优先使用）
REPO_ZINIT_CN="https://gitee.com/ruanfumin/zinit.git"
REPO_AUTOSUGGESTIONS_CN="https://gitee.com/ruanfumin/zsh-autosuggestions.git"
REPO_SYNTAX_HIGHLIGHTING_CN="https://gitee.com/ruanfumin/zsh-syntax-highlighting.git"
REPO_AUTOCOMPLETE_CN="https://gitee.com/ruanfumin/zsh-autocomplete.git"
REPO_POWERLEVEL10K_CN="https://gitee.com/ruanfumin/powerlevel10k.git"
REPO_OHMYZSH_CN="https://gitee.com/ruanfumin/ohmyzsh.git"

# 国际源（国内源连接失败时回退）
REPO_ZINIT_INTL="https://github.com/zdharma-continuum/zinit.git"
REPO_AUTOSUGGESTIONS_INTL="https://github.com/zsh-users/zsh-autosuggestions.git"
REPO_SYNTAX_HIGHLIGHTING_INTL="https://github.com/zsh-users/zsh-syntax-highlighting.git"
REPO_AUTOCOMPLETE_INTL="https://github.com/marlonrichert/zsh-autocomplete.git"
REPO_POWERLEVEL10K_INTL="https://github.com/romkatv/powerlevel10k.git"

# ========== 工具函数 ==========

info()    { echo -e "${FMT_BLUE}[INFO]${FMT_RESET} $*"; }
success() { echo -e "${FMT_GREEN}[OK]${FMT_RESET} $*"; }
warn()    { echo -e "${FMT_YELLOW}[WARN]${FMT_RESET} $*"; }
error()   { echo -e "${FMT_RED}[ERROR]${FMT_RESET} $*" >&2; }

command_exists() {
    command -v "$1" > /dev/null 2>&1
}

# 使用包管理器安装软件包
package_install() {
    local pkg_mgr="$1"
    local package_name="$2"
    info "使用 $pkg_mgr 安装 $package_name ..."

    case "$pkg_mgr" in
        pacman)
            sudo "$pkg_mgr" -S --noconfirm "$package_name"
            ;;
        apt-get)
            sudo "$pkg_mgr" update -y
            sudo "$pkg_mgr" install -y "$package_name"
            ;;
        dnf)
            sudo "$pkg_mgr" install -y "$package_name"
            ;;
        brew)
            brew update
            brew install "$package_name"
            ;;
        *)
            error "不支持的包管理器: $pkg_mgr"
            exit 1
            ;;
    esac
}

# 克隆仓库，优先国内源，失败后回退国际源
clone_with_fallback() {
    local cn_url="$1"
    local intl_url="$2"
    local target_dir="$3"
    local name="$4"

    if [ -d "$target_dir" ]; then
        success "$name 已存在，跳过: $target_dir"
        return 0
    fi

    info "正在克隆 $name（国内源）..."
    if git clone --depth=1 "$cn_url" "$target_dir" 2>/dev/null; then
        success "$name 克隆成功（国内源）"
        return 0
    fi

    warn "国内源克隆失败，尝试国际源..."
    rm -rf "$target_dir" 2>/dev/null || true
    if git clone --depth=1 "$intl_url" "$target_dir" 2>/dev/null; then
        success "$name 克隆成功（国际源）"
        return 0
    fi

    error "$name 克隆失败（国内源和国际源均不可用）"
    return 1
}

# ========== 参数解析 ==========
for arg in "$@"; do
    case "$arg" in
        --unattended)
            UNATTENDED=true
            ;;
    esac
done

# ========== 主流程 ==========

echo ""
echo -e "${FMT_BOLD}========================================${FMT_RESET}"
echo -e "${FMT_BOLD}   Dotfiles ZSH 环境自动安装脚本${FMT_RESET}"
echo -e "${FMT_BOLD}========================================${FMT_RESET}"
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
else
    error "未检测到支持的包管理器"
    error "支持: pacman (Arch), apt-get (Debian/Ubuntu), dnf (Fedora), brew (macOS/Linux)"
    exit 1
fi
success "包管理器: $pkg_mgr"

# --- 2. 安装 Git ---
info "检测 Git 安装状态..."
if command_exists git; then
    success "Git 已安装: $(git --version)"
else
    info "Git 未安装，正在安装..."
    package_install "$pkg_mgr" git
    success "Git 安装完成"
fi

# --- 3. 安装 zsh ---
info "检测 zsh 安装状态..."
if command_exists zsh; then
    success "zsh 已安装: $(zsh --version)"
else
    info "zsh 未安装，正在安装..."
    package_install "$pkg_mgr" zsh
    success "zsh 安装完成"
fi

# --- 4. 克隆 dotfiles 仓库 ---
info "下载 dotfiles 配置文件..."
if [ -d "$DOTFILES_DIR" ]; then
    success "dotfiles 目录已存在，跳过克隆: $DOTFILES_DIR"
    # 尝试更新
    if [ -d "$DOTFILES_DIR/.git" ]; then
        info "尝试更新 dotfiles..."
        (cd "$DOTFILES_DIR" && git pull --ff-only 2>/dev/null) || warn "dotfiles 更新失败，使用现有版本"
    fi
else
    clone_with_fallback "$DOTFILES_REPO_CN" "$DOTFILES_REPO_INTL" "$DOTFILES_DIR" "dotfiles"
fi

# --- 5. 创建 .zshrc 软链接 ---
info "配置 .zshrc..."
# 备份已有的 .zshrc
if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
    backup_name=".zshrc.backup.$(date +%Y%m%d%H%M%S)"
    warn "已备份原有 .zshrc 到 $HOME/$backup_name"
    mv "$HOME/.zshrc" "$HOME/$backup_name"
fi

rm -f "$HOME/.zshrc"
ln -s "$DOTFILES_DIR/zsh/zshrc" "$HOME/.zshrc"
success ".zshrc 软链接已创建: $HOME/.zshrc -> $DOTFILES_DIR/zsh/zshrc"

# --- 6. 安装 Oh-My-Zsh ---
ZSH="${ZSH:-$HOME/.oh-my-zsh}"
info "安装 Oh-My-Zsh..."
if [ -d "$ZSH" ]; then
    success "Oh-My-Zsh 已安装，跳过"
else
    export REMOTE="$REPO_OHMYZSH_CN"
    export CHSH=no
    export RUNZSH=no
    export KEEP_ZSHRC=yes
    # 使用本地安装脚本
    if [ -f "$DOTFILES_DIR/zsh/install_oh_my_zsh.sh" ]; then
        sh "$DOTFILES_DIR/zsh/install_oh_my_zsh.sh" --unattended
    else
        sh -c "$(curl -fsSL $REPO_OHMYZSH_CN/raw/master/tools/install.sh)" "" --unattended
    fi

    # 如果国内源安装的 oh-my-zsh 有问题，尝试国际源
    if [ ! -d "$ZSH" ]; then
        warn "国内源 Oh-My-Zsh 安装失败，尝试国际源..."
        export REMOTE="https://github.com/ohmyzsh/ohmyzsh.git"
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
    success "Oh-My-Zsh 安装完成"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"

# --- 7. 安装 powerlevel10k 主题 ---
info "安装 powerlevel10k 主题..."
clone_with_fallback \
    "$REPO_POWERLEVEL10K_CN" \
    "$REPO_POWERLEVEL10K_INTL" \
    "$ZSH_CUSTOM/themes/powerlevel10k" \
    "powerlevel10k"

# --- 8. 安装 zsh 插件 ---
info "安装 zsh-autosuggestions 插件..."
clone_with_fallback \
    "$REPO_AUTOSUGGESTIONS_CN" \
    "$REPO_AUTOSUGGESTIONS_INTL" \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions" \
    "zsh-autosuggestions"

info "安装 zsh-syntax-highlighting 插件..."
clone_with_fallback \
    "$REPO_SYNTAX_HIGHLIGHTING_CN" \
    "$REPO_SYNTAX_HIGHLIGHTING_INTL" \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" \
    "zsh-syntax-highlighting"

info "安装 zsh-autocomplete 插件..."
clone_with_fallback \
    "$REPO_AUTOCOMPLETE_CN" \
    "$REPO_AUTOCOMPLETE_INTL" \
    "$ZSH_CUSTOM/plugins/zsh-autocomplete" \
    "zsh-autocomplete"

# --- 9. 安装 Zinit ---
info "安装 Zinit 插件管理器..."
ZINIT_DIR="$HOME/.local/share/zinit/zinit.git"
clone_with_fallback \
    "$REPO_ZINIT_CN" \
    "$REPO_ZINIT_INTL" \
    "$ZINIT_DIR" \
    "Zinit"

# --- 10. 设置 zsh 为默认 Shell ---
info "设置默认 Shell..."
current_shell=$(basename "$SHELL" 2>/dev/null || echo "")
if [ "$current_shell" = "zsh" ]; then
    success "zsh 已经是默认 Shell"
else
    zsh_path=$(command -v zsh 2>/dev/null || echo "")
    if [ -z "$zsh_path" ]; then
        warn "找不到 zsh 可执行文件，请手动设置默认 Shell"
    elif command_exists chsh; then
        if [ "$UNATTENDED" = true ]; then
            info "无人值守模式：自动切换默认 Shell 为 zsh..."
            if grep -q "^$zsh_path$" /etc/shells 2>/dev/null; then
                sudo chsh -s "$zsh_path" "$USER" 2>/dev/null || warn "chsh 需要密码，请手动执行: chsh -s $zsh_path"
            else
                warn "zsh 未在 /etc/shells 中注册，请手动添加并执行: chsh -s $zsh_path"
            fi
        else
            echo ""
            printf '%s是否将 zsh 设置为默认 Shell？[Y/n] %s' "$FMT_YELLOW" "$FMT_RESET"
            read -r opt
            case "$opt" in
                [Yy]*|"")
                    if grep -q "^$zsh_path$" /etc/shells 2>/dev/null; then
                        sudo chsh -s "$zsh_path" "$USER" 2>/dev/null \
                            && success "默认 Shell 已设置为 zsh" \
                            || warn "chsh 失败，请手动执行: sudo chsh -s $zsh_path $USER"
                    else
                        # 将 zsh 添加到 /etc/shells
                        echo "$zsh_path" | sudo tee -a /etc/shells > /dev/null
                        sudo chsh -s "$zsh_path" "$USER" 2>/dev/null \
                            && success "默认 Shell 已设置为 zsh" \
                            || warn "chsh 失败，请手动执行: sudo chsh -s $zsh_path $USER"
                    fi
                    ;;
                *)
                    info "跳过默认 Shell 设置"
                    ;;
            esac
        fi
    else
        warn "系统不支持 chsh，请手动设置默认 Shell"
    fi
fi

# --- 完成 ---
echo ""
echo -e "${FMT_BOLD}========================================${FMT_RESET}"
echo -e "${FMT_GREEN}${FMT_BOLD}   安装完成！${FMT_RESET}"
echo -e "${FMT_BOLD}========================================${FMT_RESET}"
echo ""
echo -e "已安装的组件："
echo -e "  ${FMT_GREEN}✓${FMT_RESET} Oh-My-Zsh"
echo -e "  ${FMT_GREEN}✓${FMT_RESET} powerlevel10k 主题"
echo -e "  ${FMT_GREEN}✓${FMT_RESET} zsh-autosuggestions（命令建议）"
echo -e "  ${FMT_GREEN}✓${FMT_RESET} zsh-syntax-highlighting（语法高亮）"
echo -e "  ${FMT_GREEN}✓${FMT_RESET} zsh-autocomplete（自动补全）"
echo -e "  ${FMT_GREEN}✓${FMT_RESET} Zinit 插件管理器"
echo ""
echo -e "后续步骤："
echo -e "  1. 运行 ${FMT_BOLD}zsh${FMT_RESET} 进入新 Shell"
echo -e "  2. 首次启动会引导配置 powerlevel10k 主题"
echo -e "  3. 如需重新配置主题，运行 ${FMT_BOLD}p10k configure${FMT_RESET}"
echo ""
