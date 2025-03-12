# Dotfiles

## dotfiles是啥

dotfiles 翻译过来就是「点文件」，就是以.开头的文件，常见的如.bash_profile,.vimrc,.zshrc等等。

linux（mac）下有各种app，每个人会根据自己的喜好和习惯来设置一些（快捷键，变量等等），而dotfiles就是保存了这些自定义设置的文件，如果换一台电脑，只要备份了dotfiles文件，一样可以快速回归到自己熟悉的设置。

## Git备份

### 创建dotfiles目录

```shell
mkdir dotfiles // 创建一个dotfiles的文件夹
cd dotfiles
pwd // 查看文件夹路径
/Users/ruan/dotfiles
git init //创建git
```

### 软链接各文件

思路将真实配置文件存储在 Git 仓库中，通过软链接指向主目录位置。

```shell
cd ~    // 去到根目录
mv .vimrc /Users/ruan/dotfiles/vimrc // 把系统里配置文件移动到dotfiles目录以便git管理
mv .zshrc  /Users/ruan/dotfiles/zshrc
ln -s /Users/ruan/dotfiles/vimrc .vimrc // 建立软链接
ln -s /Users/ruan/dotfiles/zshrc .zshrc
```

## 目录

- [zsh](/zsh)
