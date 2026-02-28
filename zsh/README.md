## zsh

> zsh 是一个兼容 bash 的 shell，相较 bash 具有以下优点：
- Tab 补全功能强大。命令、命令参数、文件路径均可以补全。
- 插件丰富。快速输入以前使用过的命令、快速跳转文件夹、显示系统负载这些都可以通过插件实现。
- 主题丰富。
- 可定制性高。

### Install

macOS：

```zsh
brew install zsh
```

ubuntu：
```zsh
sudo apt-get install zsh
```

ArchLinux/Manjaro：

```zsh
sudo pacman -S zsh
```

### Change Shell

安装好后查看`zsh`路径: `which zsh`

使用 ``cat /etc/shells`` 查看系统可以用的 shell。

使用 chsh -s /bin/zsh 命令将 zsh 设置为系统默认 shell。新开一个 Shell Session，就可以开始使用 zsh 了。

### zsh 配置文件

zsh 的配置文件用于定制和配置 shell 的行为，默认路径为 `~/.zshrc`。


## oh-my-zsh

> oh-my-zsh 是一个开源、成熟且使用众多的zsh框架。Oh My Zsh 是基于 zsh 命令行的一个扩展工具集，提供了丰富的扩展功能。

- 官网: [ohmyz.sh](https://ohmyz.sh/)
- 仓库地址: [github.com](https://github.com/ohmyzsh/ohmyzsh)
- 使用介绍: [zsh 安装与配置：9步打造高效命令行](https://zhuanlan.zhihu.com/p/441676276)

### Install

```zsh
# curl
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# wget
sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
```

### 安装 oh-my-zsh 主题

推荐安装`powerlevel10k`主题：
```zsh
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
```

修改`.zshrc`文件：
```zshrc
ZSH_THEME="powerlevel10k/powerlevel10k"
```

执行 `source ~/.zshrc` 配置生效。

### 安装 oh-my-zsh 插件

oh-my-zsh 已经内置了 git 插件，内置插件可以在 `～/.oh-my-zsh/plugins` 中查看 [awesome-zsh-plugins](https://github.com/unixorn/awesome-zsh-plugins) 里查看。

#### 1. zsh-autosuggestions

> [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) 是一个命令提示插件，当你输入命令时，会自动推测你可能需要输入的命令，按下右键可以快速采用建议。

安装步骤：

1. 把插件下载到本地的 `~/.oh-my-zsh/custom/plugins` 目录：
```zsh
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```
2. 在 `.zshrc` 中，把 `zsh-autosuggestions` 加入插件列表：
```zshrc
plugins=(
    # other plugins...
    zsh-autosuggestions  # 插件之间使用空格隔开
)
```
3. 开启新的 Shell 或执行 `source ~/.zshrc` 就可以开始体验插件。

#### 2. zsh-syntax-highlighting

> [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) 是一个命令语法校验插件，在输入命令的过程中，若指令不合法，则指令显示为红色，若指令合法就会显示为绿色。

```zsh
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

#### 3. zsh-autocomplete

```zsh
git clone https://github.com/marlonrichert/zsh-autocomplete.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autocomplete
```

#### 4. Z

> z 是一个文件夹快捷跳转插件，对于曾经跳转过的目录，只需要输入最终目标文件夹名称，就可以快速跳转，避免再输入长串路径，提高切换文件夹的效率。

oh-my-zsh 内置了 z 插件，所以只需要在 `.zshrc` 中，把 z 加入插件列表：

```zshrc
plugins=(
     # other plugins...
     zsh-autosuggestions
     zsh-syntax-highlighting
     zsh-autocomplete
     z
)
```