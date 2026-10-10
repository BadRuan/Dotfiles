#!/bin/bash

set -e

command_exists() {
    command -v "$1" > /dev/null 2>&1
}

package_install() {
    local pkg_mgr=$1
    local package_name=$2
    echo "即将使用包管理器 $pkg_mgr 安装 $package_name"

    case "$pkg_mgr" in
        pacman)
            sudo "$pkg_mgr" -S --noconfirm "$package_name"
            ;;
        apt-get)
            echo "正在更新软件源..."
            sudo "$pkg_mgr" update -y
            sudo "$pkg_mgr" install -y "$package_name"
            ;;
        brew)
            echo "正在更新Homebrew..."
            brew update
            brew install "$package_name"
            ;;
        *)
            echo "不支持包管理器: $pkg_mgr"
            exit 1
            ;;
    esac
}

clone_if_not_exists() {
    local repo_url=$1
    local target_dir=$2
    if [ -d "$target_dir" ]; then
        echo "目录已存在，跳过: $target_dir"
    else
        git clone "$repo_url" "$target_dir"
    fi
}

# ------

echo "开始检测系统包管理器..."
pkg_mgr=""
if command_exists pacman; then
    pkg_mgr="pacman"
elif command_exists apt-get; then
    pkg_mgr="apt-get"
elif command_exists brew; then
    pkg_mgr="brew"
else
    echo "错误: 未检测到支持的包管理器"
    echo "支持的包管理器: apt-get (Debian/Ubuntu), pacman (Arch), brew (macOS/Linux)"
    exit 1
fi

echo "包管理器: $pkg_mgr"

echo "开始检测Git安装状态..."
if command_exists git; then
    git --version
    echo "Git 已安装."
else
    echo "Git 未安装."
    package_install "$pkg_mgr" git
fi

echo "下载个人Dotfile文件..."
if [ -d "$HOME/dotfiles" ]; then
    echo "dotfiles 目录已存在，跳过克隆。"
else
    git clone https://gitee.com/ruanfumin/dotfiles.git "$HOME/dotfiles"
fi

echo "开始安装zsh SHELL..."
if command_exists zsh; then
    echo "zsh 已安装."
else
    package_install "$pkg_mgr" zsh
fi

rm -f "$HOME/.zshrc"
ln -s "$HOME/dotfiles/zsh/zshrc" "$HOME/.zshrc"

echo "开始安装Oh-My-Zsh..."
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "Oh-My-Zsh 已安装，跳过。"
else
    sh -c "$(curl -fsSL https://gitee.com/ruanfumin/dotfiles/raw/master/zsh/install_oh_my_zsh.sh)"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

echo "开始安装powerlevel10k主题..."
clone_if_not_exists "https://gitee.com/ruanfumin/powerlevel10k.git" "$ZSH_CUSTOM/themes/powerlevel10k"

echo "开始安装zsh-autosuggestions插件..."
clone_if_not_exists "https://gitee.com/ruanfumin/zsh-autosuggestions.git" "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

echo "开始安装zsh-syntax-highlighting插件..."
clone_if_not_exists "https://gitee.com/ruanfumin/zsh-syntax-highlighting.git" "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

echo "开始安装zsh-autocomplete插件..."
clone_if_not_exists "https://gitee.com/ruanfumin/zsh-autocomplete.git" "$ZSH_CUSTOM/plugins/zsh-autocomplete"

echo ""
echo "安装完成！请运行 'zsh' 开始使用。"