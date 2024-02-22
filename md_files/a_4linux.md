

# 系统环境变量

1   环境变量配置完事之后要执行：source /etc/profile ,这行命令执行的是，将/etc/profile.d下的所有*.sh文件执行

2  /etc/profile.d下的环境变量是对所有用户生效，~/.bashrc  ~/.profile  /.bash_profile 这几个只对当前登陆用户生效，所以个人脚本可以放置到这两个里面，mac里面没有bashrc 只有bash_profile

 3 path = $path::/usr/locar/new/bin    这条命令的意思为: 使PATH自增:/usr/locar/new/bin，既PATH=PATH+":/usr/locar/new/bin";

4 自定义脚本不用加入路径的话，就直接新建一个目录,然后在个人的环境变量中，把bin的path加进去，然后就可以了

操作为，在~/.bashrc  中加入 PATH=$PATH:~/bin ,然后在～新建一个bin就行



# 安装开源工具

### src和bin包区别

一般官网下载后，src.tar.gz是源码包, bin.tar.gz是二进制包

src下载解压后比bin多了很多新的目录。

**已hive的源码包为例**

```sql
#里面多了很多目录
你会发现，整个hive的目录，是一个很大的maven项目,在hive当前目录下有pom文件。
打开beeline,metastore,ql,common,service,serde等目录，发现都有pom文件，是hive大项目的子maven项目。

你可以可以用idea打开，然后修改源码。然后用maven编译整个项目。
```







gz.asc和gz.sh256文件。这2个是官网下载的压缩包的校验文件，用来校验文件是否被人更改过。

gpg --verify a.tar.gz.asc a.tar.gz 指令来校验文件





# vim编辑

dd： 退出插入模式,删除当前行



# 服务器维护指令

### 查找指定进程

ps -ef|grep kafka |grep -v grep|awk '{print $2} '|xargs kill -9

grep -v grep过滤掉自己

awk '{print $2} ' 获取第二条列据(即即进程号)

xargs kill -9 作为参数传给kill -9

### 网络使用情况查看

需要自己yum工具



### 查看进程占用内存

free   -h   显示最大内存及可用内存
top -p 进程号   查看指定进程占用内存
top   以全屏交互式的界面显示进程排名，及时跟踪包括CPU、内存等系统资源占用情况，默认情况下每三秒刷新一次，



### 查看jvm进程情况

jstat -gc  进程号  2s  20   查看kafka的gc情况。 2s 是每2s打印一次gc  20是 打印20次
jmap -heap 进程号   查看堆内存使用情况





# 常用指令

### --help

--help   对于不懂的脚本指令,百度的版本不同，一般直接在linux --help能看到指令，

			 比如hadoop --help可以查到fs等指令，然后hadoop fs --help 可以看到fs之后可以接哪些指令
	
			不同脚本获取 help方式不同，可能是-help 可以先输入个错误指令，然后查看提示指令有哪些

### ssh高级指令

```
SSH（Secure Shell）是一个功能强大的远程登录和安全文件传输工具，提供了许多高级指令和选项。以下是一些常用的高级SSH指令：

1. `ssh -D port user@host`：建立动态端口转发，将本地端口转发到远程主机，并将流量通过SSH隧道传输。
2. `ssh -L [bind_address:]port:host:hostport user@host`：建立本地端口转发，将本地端口转发到远程主机指定的端口。
3. `ssh -R [bind_address:]port:host:hostport user@host`：建立远程端口转发，将远程主机端口转发到本地指定的端口。
4. `ssh -X user@host`：启用X11转发，允许在远程主机上显示图形应用程序。
5. `ssh -C user@host`：启用压缩，减少数据传输的带宽占用。
6. `ssh -J user1@jump_host user2@final_host`：通过跳板主机（jump host）连接到最终目标主机。
7. `ssh -M -S control_socket user@host`：建立主控连接，用于多个SSH会话之间的共享连接。
8. `ssh -t user@host command`：在远程主机上执行指定的命令，然后退出。
9. `ssh -fN -L ...`：将SSH会话放入后台运行，建立本地端口转发。
10. `ssh -O forward -S control_socket user@host`：通过控制连接请求新的端口转发。

这些是一些SSH的高级指令示例，你可以通过`man ssh`命令查看更多详细的信息，了解每个指令的具体用法和选项。

ssh user@host：连接到远程主机。
ssh -p port user@host：指定远程主机上的端口号进行连接。
ssh-copy-id user@host：将本地公钥复制到远程主机，以实现无密码登录。
ssh-keygen：生成SSH密钥对（公钥和私钥）。
ssh-add：将私钥添加到SSH代理，以便在不输入密码的情况下进行身份验证。
scp file user@host:destination：将本地文件复制到远程主机。
scp user@host:file destination：从远程主机复制文件到本地。
sftp user@host：使用交互式的FTP方式与远程主机进行文件传输。
sshfs user@host:/remote/path /local/path：将远程主机的文件系统挂载到本地目录。
```



### 脚本结果输出文件

nohup  任务名    &  >> a.log

### 服务器交互相关

目录:

传送文件

服务器端口代理

```sql
# 传送文件
scp   ./cbk_kafka.jar    dev@pre-13:/home/dev/timor_dir
```

服务器端口代理

```sql
# 服务器端口代理
本地端口代理，通过ssh跳板机连数据库

用法1：远程端口映射到其他机器HostB 上启动一个 PortB 端口，映射到 HostC:PortC 上，在 HostB 上运行：HostB$ ssh -L 0.0.0.0:PortB:HostC:PortC   user@HostC用法2：本地端口通过跳板映射到其他机器HostA 上启动一个 PortA 端口，通过 HostB 转发到 HostC:PortC上，在 HostA 上运行：HostA$ ssh -L 0.0.0.0:PortA:HostC:PortC  user@HostBssh -L 127.0.0.1:3308:rm-bp192qdgcbyq9e2db.mysql.rds.aliyuncs.com:3306   timo@jump-server.caibeike.netssh -L 127.0.0.1:27018:172.16.248.138:27017  timo@jump-server.caibeike.netssh -L 127.0.0.1:27021:mongo-main-01.caibeike-in.net:27017  timo@jump-server.caibeike.net跳板机密码: ID7UBobRvbJlzJz1bPfb一次同时映射多个端口ssh -L 0.0.0.0:PortA:HostC:PortC  -L 0.0.0.0:PortB:HostB:PortB -L    user@HostBssh -L 127.0.0.1:3308:rm-bp192qdgcbyq9e2db.mysql.rds.aliyuncs.com:3306  -L 127.0.0.1:27018:172.16.248.138:27017 -L 127.0.0.1:27021:mongo-main-01.caibeike-in.net:27017  timo@jump-server.caibeike.net不过好像不好用
```





### 查看目录/文件相关

```sql
#查看目录或文件

查看文件最后几行   tail -n 10  a.txt  
持续查看文件末尾，直到退出  tail -f a.txt 
获取文件绝对路径  whereis  a.txt 
查看隐藏文件  ls -a  
显示目录下文件详细信息（读写权限，拥有者，文件大小，创建日期）   ls -l ( ll )  
显示目录树结构  tree  或  tree  目录   
查看当前目录下所有目录大小  du -sh */
```



### 服务器状态相关

查看进程   

查看内存情况

```sql
# 查看进程
[ps命令](https://so.csdn.net/so/search?q=ps命令&spm=1001.2101.3001.7020)用于报告当前系统的进程状态。可以搭配kill指令随时中断、删除不必要的程序。ps命令是最基本同时也是非常强大的进程查看命令，使用该命令可以确定有哪些进程正在运行和运行的状态、进程是否结束、进程有没有僵死、哪些进程占用了过多的资源等等，总之大部分信息都是可以通过执行该命令得到的。

#ps aux 
- a：显示当前终端下的所有进程信息，包括其他用户的进程。
- u：使用以用户为主的格式输出进程信息。
- x：显示当前用户在所有终端下的进程。

#ps -elf
- -e：显示系统内的所有进程信息。
- -l：使用长（long）格式显示进程信息。
- -f：使用完整的（full）格式显示进程信息。
```



```sql
# 查看内存情况
free   -h   显示最大内存及可用内存
top -p 进程号   查看指定进程占用内存
top   以全屏交互式的界面显示进程排名，及时跟踪包括CPU、内存等系统资源占用情况，默认情况下每三秒刷新一次，
```



### 执行程序脚本相关

```sql
#后台运行程序输出指定文件       nohup  任务名    &  >> a.log

##### nohup

不挂断地运行命令。no hangup的缩写，意即“不挂断”。

nohup Command [ Arg ... ] [　& ]

nohup 命令运行由 Command参数和任何相关的 Arg参数指定的命令，忽略所有挂断（SIGHUP）信号。
nohup放在命令的开头，表示不挂起（no hang up），也即，关闭终端或者退出某个账号，进程也继续保持运行状态，一般配合&符号一起使用。如nohup command &。


#Shell中可能经常能看到：> /dev/null 2>&1
/dev/null 代表空设备文件
  > 代表重定向到哪里，例如：echo "123" > /home/123.txt
  1 表示stdout标准输出，系统默认值是1，所以">/dev/null"等同于"1>/dev/null"
  2 表示stderr标准错误
  & 表示等同于的意思，2>&1，表示2的输出重定向等同于1
  
那么本文标题的语句：
1>/dev/null 首先表示标准输出重定向到空设备文件，也就是不输出任何信息到终端，说白了就是不显示任何信息。
2>&1 接着，标准错误输出重定向等同于 标准输出，因为之前标准输出已经重定向到了空设备文件，所以标准错误输出也重定向到空设备文件。
2>&1写在后面的原因：   
		格式：command > file 2>&1  == command 1> file 2>&1
首先是command > file将标准输出重定向到file中， 2>&1 是标准错误拷贝了标准输出，也就是同样被重定向到file中，最终结果就是标准输出和错误都被重定向到file中。

		如果改成： command 2>&1 >file
2>&1 标准错误拷贝了标准输出的行为，但此时标准输出还是输出到终端。当 >file 后，标准输出才被重定向到file，但标准错误仍然保留了先前的设置，即保持输出到终端。

> file 表示将标准输出输出到file中，也就相当于 1>file
> 是定向输出到文件，如果文件不存在，就创建文件；如果文件存在，就将其清空；一般我们备份清理日志文件的时候，就是这种方法：先备份日志，再用`>`，将日志文件清空（文件大小变成0字节）；
> >这个是将输出内容追加到目标文件中。如果文件不存在，就创建文件；如果文件存在，则将新的内容追加到那个文件的末尾，该文件中的原有内容不受影响。
> >2> error 表示将错误输出到error文件中
> >2>&1 也就表示将错误重定向到标准输出上
> >2>&1 >file ：错误输出到终端，标准输出重定向到文件file，等于 > file 2>&1(标准输出重定向到文件，错误重定向到标准输出)。
> >& 放在命令到结尾，表示后台运行，防止终端一直被某个进程占用，这样终端可以执行别到任务，配合 >file 2>&1可以将log保存到某个文件中，但如果终端关闭，则进程也停止运行。如 command > file.log 2>&1 & 。

#demo
sudo kill -9 `[ps](http://www.111cn.net/fw/photo.html) -elf |[grep](https://so.csdn.net/so/search?q=grep&spm=1001.2101.3001.7020) -v grep|grep $1|awk '{print $4}'` 1>/dev/null 2>/dev/null
命令的结果可以通过%>的形式来定义输出

```











 

