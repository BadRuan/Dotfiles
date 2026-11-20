# Vim

> Vim 编辑器配置与插件。通过一键安装脚本可在新机器上自动搭建完整的 Vim 环境，所有组件优先使用 **GitCode 国内镜像**，镜像未收录时自动回退 **GitHub 加速代理** 与 **GitHub 直连**。

## 一键安装

在新的 Linux / macOS 机器上，运行以下命令即可自动安装完整的 Vim 环境：

```bash
# 标准安装
sh -c "$(curl -fsSL https://gitee.com/ruanfumin/dotfiles/raw/master/vim/auto_install_vim.sh)"

# 无人值守模式（跳过所有交互确认）
curl -fsSL https://gitee.com/ruanfumin/dotfiles/raw/master/vim/auto_install_vim.sh | bash -s -- --unattended

# 同时安装 YouCompleteMe 补全引擎（体积大、需编译，默认跳过）
bash auto_install_vim.sh --with-ycm
```

安装脚本会自动完成：

1. **检测包管理器** — 支持 pacman、apt-get、dnf、brew
2. **安装依赖** — git、vim、fzf（fzf.vim 模糊查找需要）
3. **克隆 dotfiles** — 拉取本仓库（Gitee 国内源优先）
4. **创建软链接** — `~/.vimrc` 与 `~/.vim/vimrc`（已有真实文件会自动备份为 `*.backup.时间戳`）
5. **安装 vim-plug** — 插件管理器（国内镜像下载）
6. **安装全部插件** — 14 个插件按镜像链逐级回退安装
7. **Vim 启动自检** — 确认配置无报错

### 插件更新机制

插件从国内镜像克隆后，脚本会把 git origin **改写回 GitHub 规范地址**（与 `vimrc` 中的 `Plug` 短名一致，通过 vim-plug 的 URI 校验），并在插件仓库内配置 `url.insteadOf` 重定向。因此：

- Vim 内执行 `:PlugUpdate` 更新插件时，git 流量会**自动重定向回国内镜像**，无需任何额外配置；
- `vimrc` 保持规范短名（如 `Plug 'tpope/vim-surround'`），在任何网络环境下都可读、可移植；
- 重新运行安装脚本可补齐缺失的插件（已安装的自动跳过）。

## 支持的系统

| 系统 | 包管理器 | 手动安装命令 |
|------|---------|------------|
| Arch Linux / Manjaro | pacman | `sudo pacman -S vim git fzf` |
| Debian / Ubuntu | apt-get | `sudo apt-get install vim git fzf` |
| Fedora | dnf | `sudo dnf install vim git fzf` |
| macOS / Linux | Homebrew | `brew install vim git fzf` |

## vim 配置文件

默认路径为用户根目录 `.vimrc` 配置文件，方便管理需要新建 `.vim` 目录，文件名修改为 `vimrc` 即可：

```
# 默认
~/.vimrc

# 调整
~/.vim/vimrc
```

本项目通过软链接管理（安装脚本会自动完成，且两个位置都会链接，兼容不同版本的 Vim 查找顺序）：

```bash
mkdir -p ~/.vim
ln -s ~/dotfiles/vim/vimrc ~/.vim/vimrc
ln -s ~/dotfiles/vim/vimrc ~/.vimrc
```

## 手动安装

不使用一键安装脚本时，可按以下步骤手动安装。

### 1. 安装 vim-plug

下载 `plug.vim` 到 `~/.vim/autoload/` 目录：

```bash
# 国内镜像（推荐，raw.gitcode.com 实测可用）
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.gitcode.com/gh_mirrors/vi/vim-plug/raw/master/plug.vim

# GitHub 加速代理（备选）
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://gh-proxy.com/https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# 官方源（需要能访问 GitHub）
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

也可以克隆仓库后复制：

```bash
git clone --depth=1 https://gitcode.com/gh_mirrors/vi/vim-plug
mkdir -p ~/.vim/autoload
cp vim-plug/plug.vim ~/.vim/autoload/
```

### 2. 配置 vimrc 并安装插件

将本目录的 `vimrc` 软链接到 `~/.vimrc`（见上文），启动 vim 后执行：

```vim
:PlugInstall
```

> **注意**：`:PlugInstall` 会按 `vimrc` 中的 `Plug` 短名从 GitHub 克隆。国内网络无法直连 GitHub 时，请直接运行一键安装脚本（走国内镜像链）；或在 `vimrc` 的 `plug#begin()` 之前临时加入下面一行，让 vim-plug 通过加速代理克隆：
>
> ```vim
> let g:plug_url_format = 'https://gh-proxy.com/https://github.com/%s.git'
> ```

### vim-plug 常用命令

- `:PlugInstall` 安装插件
- `:PlugUpdate` 安装或更新插件
- `:PlugStatus` 查看插件状态
- `:PlugDiff` 查看上次更新的变更
- `:PlugClean` 清理不在列表中的插件

## 镜像源对照表

安装脚本对每个插件按以下顺序尝试，成功即止：

```
GitCode 镜像 → gh-proxy.com 加速代理 → ghfast.top 加速代理 → GitHub 直连
```

| 组件 | GitCode 国内源（实测） | GitHub 国际源 |
|------|----------------------|--------------|
| vim-plug | `gitcode.com/gh_mirrors/vi/vim-plug` | `junegunn/vim-plug` |
| vim-airline | `gitcode.com/gh_mirrors/vi/vim-airline` | `vim-airline/vim-airline` |
| vim-airline-themes | `gitcode.com/gh_mirrors/vi/vim-airline-themes` | `vim-airline/vim-airline-themes` |
| vimcdoc | `gitcode.com/gh_mirrors/vi/vimcdoc` | `yianwillis/vimcdoc` |
| syntastic | `gitcode.com/gh_mirrors/sy/syntastic` | `vim-syntastic/syntastic` |
| vim-surround | —（走加速代理） | `tpope/vim-surround` |
| fzf | `gitcode.com/gh_mirrors/fz/fzf` | `junegunn/fzf` |
| fzf.vim | `gitcode.com/gh_mirrors/fz/fzf.vim` | `junegunn/fzf.vim` |
| vim-polyglot | —（走加速代理） | `sheerun/vim-polyglot` |
| vim-gitgutter | `gitcode.com/gh_mirrors/vi/vim-gitgutter` | `airblade/vim-gitgutter` |
| nerdcommenter | `gitcode.com/gh_mirrors/ne/nerdcommenter` | `preservim/nerdcommenter` |
| vim-gotham | `gitcode.com/gh_mirrors/vi/vim-gotham` | `whatyouhide/vim-gotham` |
| vim-go | `gitcode.com/gh_mirrors/vi/vim-go` | `fatih/vim-go` |
| python-syntax | —（走加速代理） | `vim-python/python-syntax` |
| vim-js | —（走加速代理） | `yuezk/vim-js` |
| YouCompleteMe（可选） | `gitcode.com/gh_mirrors/yo/YouCompleteMe` | `ycm-core/YouCompleteMe` |

> GitCode 的 GitHub 自动镜像命名规则为 `gitcode.com/gh_mirrors/<仓库名前两位>/<仓库名>`。"走加速代理"表示 GitCode 未收录该仓库，脚本会自动改用 `gh-proxy.com` / `ghfast.top` 代理克隆 GitHub（均已实测可用）。加速代理为社区服务，若某个失效可在脚本顶部的 `GH_PROXY_1` / `GH_PROXY_2` 变量中替换。

## 插件说明

当前 `vimrc` 已配置的插件：

| 插件 | 用途 |
|------|------|
| vim-airline / vim-airline-themes | 状态栏增强，显示更多信息 |
| vimcdoc | 中文帮助文档（`:h` 显示中文） |
| syntastic | 语法检查，实时提示错误 |
| YouCompleteMe | 代码补全（可选，见下文） |
| vim-surround | 快速编辑包围符号（如 `ci"` 删除双引号内内容） |
| fzf / fzf.vim | 模糊查找文件、内容（`:Files`、`:Rg`，依赖系统 fzf 命令） |
| vim-polyglot | 多语言语法高亮 |
| vim-gitgutter | 显示 Git 差异（新增、修改、删除的行） |
| nerdcommenter | 快速注释代码 |
| vim-gotham | 主题（`gotham256` 配色） |
| vim-go / python-syntax / vim-js | Go、Python、JavaScript 语言支持 |

### YouCompleteMe（可选安装）

> [YouCompleteMe](https://github.com/ycm-core/YouCompleteMe) 是代码补全引擎，支持多种语言，需要编译安装，体积较大（约 1 GB 磁盘空间）。

```bash
bash auto_install_vim.sh --with-ycm
```

脚本会自动：通过 GitCode 镜像克隆主仓库（子模块 ycmd 经加速代理拉取）→ 安装 cmake 等编译依赖 → 运行 `python3 install.py --clangd-completer` 编译。

国内网络下 `install.py` 需从 GitHub Releases 下载 clangd，可能失败。两种解决办法：

```bash
# 方法一：安装系统 clangd 后指定路径编译（推荐）
sudo dnf install clang-tools-extra   # Debian/Ubuntu: apt install clangd；Arch: pacman -S clang
cd ~/.vim/plugged/YouCompleteMe
python3 install.py --clangd-completer --clangd-binary-path $(command -v clangd)

# 方法二：为下载设置代理
cd ~/.vim/plugged/YouCompleteMe
https_proxy=http://127.0.0.1:7890 python3 install.py --clangd-completer
```

未完成编译前，Vim 启动时 YouCompleteMe 会提示不可用，不影响其他插件。

### 更多插件推荐

以下插件的 GitCode 镜像均已实测可用，按需在 `vimrc` 的 `plug#begin()` 块中添加，并同步添加到安装脚本的 `PLUGIN_LIST`（或直接 `:PlugInstall`）：

```vim
Plug 'preservim/nerdtree'            " 文件树（gitcode.com/gh_mirrors/ne/nerdtree）
Plug 'preservim/tagbar'              " 代码结构浏览，需系统 ctags（gitcode.com/gh_mirrors/ta/tagbar）
Plug 'neoclide/coc.nvim', {'branch': 'release'}  " 智能补全，需 Node.js（gitcode.com/gh_mirrors/co/coc.nvim）
```

> [coc.nvim](https://github.com/neoclide/coc.nvim) 是基于 Node.js 的 Vim8 / Neovim 智能补全插件，拥有完整的 LSP 支持，配置与插件系统风格类似 VSCode。

## 操作备忘

1. 剪切几个字符：`d3l`表示往右**剪切**3个字符，按`p`可以粘贴。
2. 剪切一行：`dd`表示**剪切**当前行，按`p`可以粘贴。
3. 复制几个字符：`y5h`表示往左**复制**5个字符，按`p`可以粘贴。
4. 删除双号中所有文字内容：`ci"`。

## 常见问题

| 问题 | 原因与解决 |
|------|-----------|
| 启动报 `E185: Cannot find color scheme` | 主题插件未安装。`vimrc` 已做兜底（自动回退内置 `desert` 配色），重新运行安装脚本补齐插件即可 |
| 启动提示 `vim-plug 未安装` | `~/.vim/autoload/plug.vim` 缺失，重新运行安装脚本，或按上文手动安装 vim-plug |
| `:PlugInstall` / `:PlugUpdate` 卡住或失败 | 国内网络直连 GitHub 超时。重新运行安装脚本补齐；或临时启用 `g:plug_url_format` 加速代理（见"手动安装"一节） |
| `Invalid URI ... PlugClean required` | 插件目录的 origin 地址与 `vimrc` 中 `Plug` 名称不一致（例如手动用镜像地址克隆过）。删除 `~/.vim/plugged/<插件名>` 目录后重新运行安装脚本 |
| `:Files` 提示找不到 fzf | 系统未安装 fzf 命令：`sudo dnf install fzf`（Debian/Ubuntu 用 apt，Arch 用 pacman，macOS 用 brew） |

## vim 教程

- [Vim语法高亮插件的推荐与配置实用指南](https://www.trae.cn/article/706612994)
- 语法高亮：[vim-polyglot](https://github.com/sheerun/vim-polyglot?tab=readme-ov-file)
