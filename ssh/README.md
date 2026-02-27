# SSH

SSH 是什么？

- 基于密钥加密的远程登录协议，默认端口 `22`。
- 支持命令执行、文件传输（SCP/SFTP）、端口转发等。

## 一、常用命令

```zsh
# 生成密钥对（Ed25519 更安全）
ssh-keygen -t ed25519 -a 100 -C "your@email.com"

# 将公钥复制到服务端（自动化方式）
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@host

# 连接测试
ssh -v user@host  # -v 显示调试信息
```

## 二、使用技巧

## 1.给IP地址取别名

编辑`/etc/hosts`这个文件，由于是系统文件，需要使用管理员权限。

```zsh
sudo nvim /etc/hosts
```

比如我想给`10.22.75.177`取名叫`lab1`，添加下面一行：
```zsh
10.22.75.177 lab1
```

在以后的使用中，凡是需要用到ip地址，可以直接用别名代理，比如
```zsh
ping lab1
```

## 2.一键SSH连接

在主用户目录下的`.ssh`目录新建`config`文件：

```
Host jdcloud
	HostName IP地址
	User root
	Port 22
	IdentityFile ssh文件地址
```

上述使用别名这种配置方式，同时也为`scp`命令提供了方便。

比如向远程服务器传输文件：

```zsh
scp hello.tar.gz  jdcloud:/root 
```



## 三、SSH 服务端配置

服务端主配置文件：`/etc/ssh/sshd_config`

常用参数详解：
| 参数                  | 说明                                                                 | 推荐值                     |
|-----------------------|----------------------------------------------------------------------|---------------------------|
| `Port 22`             | 监听端口（可改其他端口防扫描）                                       | 自定义非22端口            |
| `PermitRootLogin`     | 是否允许 root 直接登录                                               | `prohibit-password`       |
| `PasswordAuthentication` | 是否启用密码登录                                                   | `no`（配合密钥认证使用）  |
| `PubkeyAuthentication` | 是否启用公钥认证                                                   | `yes`                     |
| `AllowUsers user1`    | 限制允许登录的用户（多个用空格分隔）                                 | 根据需求配置              |
| `ClientAliveInterval` | 检测客户端活跃间隔（秒），超时断开                                   | `300`（5分钟）            |

修改生效命令：
```bash
sudo systemctl restart sshd  # 重启服务
sudo systemctl reload sshd   # 重新加载配置（不中断现有连接）
sudo systemctl status sshd   # 查看状态
```
