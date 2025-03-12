# 启用Powerlevel10k即时提示。应保持靠近~/.zshrc文件顶部
# 需要处理控制台输入（密码提示、[y/n]确认等）的初始化代码必须放在此块上方；其他内容可放在下方
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# 设置提示主题
autoload -Uz promptinit  # 加载提示系统初始化模块
promptinit            # 初始化提示系统
prompt adam1          # 设置默认提示主题为adam1样式

# 历史记录配置
setopt histignorealldups  # 忽略重复命令历史
HISTSIZE=1000         # 维护1000条命令历史
SAVEHIST=1000         # 保存1000条历史到文件
HISTFILE=~/.zsh_history # 历史记录存储文件

# 使用现代补全系统
autoload -Uz compinit   # 加载补全系统初始化模块
compinit              # 初始化补全系统

# 补全系统样式配置
zstyle ':completion:*' auto-description '指定: %d'  # 自动补全描述
zstyle ':completion:*' completer _expand _complete _correct _approximate  # 补全方式
zstyle ':completion:*' format 'Completing %d'  # 补全格式
zstyle ':completion:*' group-name ''  # 不显示分组名称
zstyle ':completion:*' menu select=2  # 菜单选择模式
eval "$(dircolors -b)"  # 应用目录颜色配置
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}  # 列表颜色配置
zstyle ':completion:*' list-colors ''  # 清空默认颜色（避免覆盖）
zstyle ':completion:*' list-prompt %SAt %p: 按TAB继续或输入字符%s  # 列表提示信息
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'  # 匹配规则
zstyle ':completion:*' menu select=long  # 长列表选择模式
zstyle ':completion:*' select-prompt %SScrolling active: 当前选择%p%s  # 滚动选择提示
zstyle ':completion:*' use-compctl false  # 禁用旧式补全控制
zstyle ':completion:*' verbose true  # 显示详细补全信息

# 特定补全样式（进程管理相关）
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'  # 进程列表颜色
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'  # kill命令补全进程查询命令

if [ -f ~/.profile ]; then
  source ~/.profile  # 显式加载Bash风格的配置
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

eval "$(uv generate-shell-completion bash)"

### Zinit安装器添加部分
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}正在安装%F{33}ZDHARMA CONTINUUM%F{220}插件管理器(%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}安装成功.%f%b" || \
        print -P "%F{160}克隆失败.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# 加载Zinit基础附件（非Turbo模式）
# （此部分为附件安装所必需）
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust      

### Zinit安装器结束

# Zinit模块化管理配置
zinit ice depth"1"  # 限制插件深度为1层
zinit light romkatv/powerlevel10k  # 安装Powerlevel10k主题

# 加载常用Zsh插件
zinit light zsh-users/zsh-syntax-highlighting  # 语法高亮
zinit light zsh-users/zsh-completions          # 增强补全
zinit light zsh-users/zsh-autosuggestions      # 自动建议


# 如果存在个性化配置文件则加载
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
