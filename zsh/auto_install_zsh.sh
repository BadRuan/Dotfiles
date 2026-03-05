#!/bin/bash

command_exists() {
    command -v "$1" > /dev/null 2>&1
}

package_install() {
    local pkg_mgr=$1
    local package_name=$2
    echo "即将使用包管理器$pkg_mgr 安装 $package_name"

    case $pkg_mgr in 
        pacman)
            $pkg_mgr -S --noconfirm $package_name
            ;;
        apt-get)
            echo "正在更新软件源..."
            # $pkg_mgr update >/dev/null 2>&1
            $pkg_mgr install -y $package_name
            ;;
        brew)
            echo "正在更新Homebrew..."
            # brew update
            brew install $package_name
            ;;
        *)
            echo "不支持包管理器: $pkg_mgr"
            exit 1
            ;;
    esac
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
fi

echo "包管理器: $pkg_mgr"

echo "开始检测Git安装状态..."
if  command_exists git; then
    git --version
    echo "Git 已安装."
    # exit 0
else
    echo "Git 未安装."
    package_install $pkg_mgr git 
fi


echo "下载个人Dotfile文件: "
cd ~
git clone https://gitee.com/ruanfumin/dotfiles.git 


echo "开始安装zsh SHELL: "
package_install $pkg_mgr zsh 
rm ~/.zshrc > /dev/null 2>&1
ln -s ~/dotfiles/zsh/zshrc ~/.zshrc


echo "开始安装Oh-My-Zsh: "
sh -c "$(curl -fsSL https://gitee.com/ruanfumin/dotfiles/raw/master/zsh/install_oh_my_zsh.sh)"
echo "开始安装powerlevel10k主题: "
git clone --depth=1 https://gitee.com/ruanfumin/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

echo "开始安装zsh-autosuggestions插件: "
git clone https://gitee.com/ruanfumin/zsh-autosuggestions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

echo "开始安装zsh-syntax-highlighting插件: "
git clone https://gitee.com/ruanfumin/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

echo "开始安装zsh-autocomplete插件: "
git clone https://gitee.com/ruanfumin/zsh-autocomplete.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autocomplete
#!/bin/bash

command_exists() {
    command -v "$1" > /dev/null 2>&1
}

package_install() {
    local pkg_mgr=$1
    local package_name=$2
    echo "即将使用包管理器$pkg_mgr 安装 $package_name"

    case $pkg_mgr in 
        pacman)
            $pkg_mgr -S --noconfirm $package_name
            ;;
        apt-get)
            echo "正在更新软件源..."
            # $pkg_mgr update >/dev/null 2>&1
            $pkg_mgr install -y $package_name
            ;;
        brew)
            echo "正在更新Homebrew..."
            # brew update
            brew install $package_name
            ;;
        *)
            echo "不支持包管理器: $pkg_mgr"
            exit 1
            ;;
    esac
}


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
fi

echo "包管理器: $pkg_mgr"

echo "开始检测Git安装状态..."
if  command_exists git; then
    git --version
    echo "Git 已安装."
    # exit 0
else
    echo "Git 未安装."
    package_install $pkg_mgr git 
fi


echo "下载个人Dotfile文件: "
git clone https://gitee.com/ruanfumin/dotfiles.git ~


echo "开始安装zsh SHELL: "
package_install $pkg_mgr zsh 
rm ~/.zshrc > /dev/null 2>&1
ln -s ~/dotfiles/zsh/zshrc ~/.zshrc


echo "开始安装Oh-My-Zsh: "
sh -c "$(curl -fsSL https://gitee.com/ruanfumin/dotfiles/raw/master/zsh/install_oh_my_zsh.sh)"
echo "开始安装powerlevel10k主题: "
git clone --depth=1 https://gitee.com/ruanfumin/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

echo "开始安装zsh-autosuggestions插件: "
git clone https://gitee.com/ruanfumin/zsh-autosuggestions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

echo "开始安装zsh-syntax-highlighting插件: "
git clone https://gitee.com/ruanfumin/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

echo "开始安装zsh-autocomplete插件: "
git clone https://gitee.com/ruanfumin/zsh-autocomplete.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autocomplete
