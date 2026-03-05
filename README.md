# Dotfiles

## Dotfiles 是啥

dotfiles 翻译过来就是「点文件」，就是以.开头的文件，常见的如.bash_profile,.vimrc,.zshrc等等。

linux（mac）下有各种app，每个人会根据自己的喜好和习惯来设置一些（快捷键，变量等等），而dotfiles就是保存了这些自定义设置的文件，如果换一台电脑，只要备份了dotfiles文件，一样可以快速回归到自己熟悉的设置。

## Git备份

将配置文件存储在 Git 仓库中，通过软链接指向主目录位置。

```zsh
ln -s ~/Documents/dotfiles/vim/vimrc ~/.vim/vimrc

ln -s ~/Documents/dotfiles/zsh/zshrc ~/.zshrc
```

## 目录

- [zsh](/zsh/README.md)
- [profile](/profile/README.md)
- [vim](/vim/README.md)
- [ssh](/ssh/README.md)

## 自动安装

自动安装ZSH配置命令：
```zsh
sh -c "$(curl -fsSL https://gitee.com/ruanfumin/dotfiles/raw/master/zsh/auto_install_zsh.sh)"
```
