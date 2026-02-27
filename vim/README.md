# Vim 

## vim 配置文件

默认路径为用户根目录，`.vimrc`配置文件，方便管理需要新建`.vim`目录，文件名修改为`vimrc`即可：

```
# 默认
~/.vimrc

# 调整
~/.vim/vimrc
```

## 操作备忘

1. 剪切几个字符：`d3l`表示往右**剪切**3个字符，按`p`可以粘贴。
2. 剪切一行：`dd`表示**剪切**当前行，按`p`可以粘贴。
3. 复制几个字符：`y5h`表示往左**复制**5个字符，按`p`可以粘贴。
4. 删除双号中所有文字内容：`ci"`。

## 插件安装 (Vim-Plug)


使用工具Vim插件管理工具[vim-plug](https://github.com/junegunn/vim-plug)，安装Shell命令：

```zsh
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

设置`.vimrc`配置文件：

```vim
call plug#begin()

Plug 'tpope/vim-sensible'

call plug#end()
```

比如安装插件[vim-airline](https://github.com/vim-airline/vim-airline?tab=readme-ov-file)：

```vim
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
```

### vim-plug 国内源

将`plug.vim`克隆下载后复制到`autoload`目录下:
```bash
git clone https://gitcode.com/gh_mirrors/vi/vim-plug
mkdir ~/.vim/autoload
cp vim-plug/plug.vim ~/.vim/autoload/
```

编辑`.vimrc`文件，在前面增加如下内容：
```vim
call plug#begin('~/.vim/plugged')

" 示例插件（按需添加，这里是neovim的插件安装示例）
Plug 'https://gitcode.com/neoclide/ncoc.vim', {'branch': 'release'}  " 自动补全
Plug 'https://gitcode.com/nvim-treesitter/nvim-treesitter'          " 语法高亮
Plug 'https://gitcode.com/scrooloose/nerdtree'                      " 文件树

call plug#end()
```

要注意的是，要在插件名称前面添加：`https://gitcode.com/`。否则无法访问国外的网站导致无法安装。

### 插件推荐

#### 1. vim-airline : 状态栏增强，显示更多信息。

```vim
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
```
#### 2. YouCompleteMe : 代码补全，支持多种语言。

```vim
Plug 'ycm-core/YouCompleteMe'
```

#### 3. Syntastic : 语法检查，实时提示错误。

```vim
Plug 'scrooloose/syntastic'
```

#### 4. vim-surround : 快速编辑包围符号（如引号、括号）。

```vim
Plug 'tpope/vim-surround'
```

#### 5. fzf.vim : 模糊查找文件、内容等。

```vim
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
```

#### 6. Tagbar : 代码结构浏览，显示函数、类等。

```vim
Plug 'majutsushi/tagbar'
```

#### 7. vim-gitgutter : 显示 Git 差异（新增、修改、删除的行）。

```vim
Plug 'airblade/vim-gitgutter'
```

#### 8. NERDCommenter : 快速注释代码。

```vim
Plug 'preservim/nerdcommenter'
```

#### 9. vim-polyglot : 多语言语法高亮，支持多种编程语言。

```vim
Plug 'sheerun/vim-polyglot'
```

#### 10. vimcdoc : 中文文档手册

```vim
Plug 'yianwillis/vimcdoc'
```

### 11. coc.nvim : 智能补全插件

> [Coc.nvim](https://github.com/neoclide/coc.nvim) 是一个基于NodeJS 的适用于Vim8, Neovim 的Vim 智能补全插件。  
拥有完整的LSP 支持。配置、使用方式及插件系统的整体风格类似 VSCode.


#### 12. vim主题 vim-gotham

[vim-gotham](https://github.com/whatyouhide/vim-gotham)

## vim 教程

- [Vim语法高亮插件的推荐与配置实用指南](https://www.trae.cn/article/706612994)
- 语法高亮：[vim-polyglot](https://github.com/sheerun/vim-polyglot?tab=readme-ov-file)
