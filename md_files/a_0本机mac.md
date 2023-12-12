# 账号相关

```sql
#windows
账号 lpc
密码 lpc

#mac
账号 timor 
密码 lpc121995

#mircsoft账号
账户  a4433@riverdale.rac.sch.uk
密码  Lpc19950419

#github账号: mac
账号 2867102374@qq.com 
密码 lpc19950419

#github账号: windows
账号timorwindows
密码 Lpc19950419

#mac上 google账号
账号 2867102374@qq.com
密 lpc19950419

#windows 上google账号
账号:2049293487@qq.com 
密:lpc19950419

#新qq
2049293487
lpc19950419

#网易邮箱
lpc19950419@163.com
lpc121995

#vpn
2867102374@qq.com
lpc19950419
```

# mac连接windows虚拟机

#### win开22端口/开ssh服务器

```sql
#查看win的ip地址
为无限局域网适配器那个 ：192.168.0.108
192.168.1.1是路由器地址
192.168.1.106  是project1

#查看SSH服务器是否开启
win +R =》services.msc =>OpenSSH SSH Server否开启

#开启端口操作
控制面板=>系统和安全=》防火墙规则=》高级设置=》右键入站规则=》
端口=》下一页=》22=》默认的=》默认的=》记录个名字timor开启22端口

#开启ssh服务器
win +R =》services.msc =>找到OpenSSH SSH Server查看是否开启，被禁用了无法开启=》
=》设置=》应用=》可选功能=》查找OpenSSH服务器=》安装=》再执行上面操作，就可以开启了

#关闭防火墙
查看防火墙状态
netsh advfirewall show allprofiles
关闭windows上防火墙
netsh advfirewall set allprofiles state off
开启防火墙结束
netsh advfirewall set allprofiles state on

#每次开机开启ssh服务器
net start sshd ，要用管理员运行终端，再执行指令
或者上面第四条手动操作
```



#### mac连接虚拟机

```sql
因为wins没有ssh指令，所以没法执行，先ssh wins 再通过wins ssh虚拟机的操作

#直接通过跳板机连接project1
ssh -J lpc@192.168.0.108 lpc@192.168.1.106

#先window连接
ssh lpc@192.168.0.108
exit 回车退出windows连接，control +c 没用
#再通过winodows 连接 project1
ssh lpc@project1
wins从10开始有ssh指令，并且本地我们配置了DNS

#ssh隧道,本地8888端口 通过wins转发给project1
ssh -L 8888:192.168.1.106:3306 lpc@192.168.0.108
比如我navigate连接的是本地的8888端口，实际连的是project1的3306

#这个是一次写多个ssh隧道
ssh -L 2181:B:2181 -L 9092:B:9092 -L 2182:C:2181 -L 9093:C:9092 -L 2183:D:2181 -L 9094:D:9092 user@T

```







# mac效率工具

#### 查看新系统功能

可以选择左上方的帮助按钮，或者去网上查系统名，然后搜索相关新功能



#### 语音识别文字

soma体统带的，设置方式：

 打开左上方的系统设置=> 选择键盘=> 打开听写=> 选择快捷键即可完成。使用的时候,连续双击control快捷键, 想结束语音录制再点一下control

#### 单击桌面回到桌面

当你小窗口打开一个App的时候，可以选择单机桌面，这样系统会帮你缩小你的App。

# mac电脑设置

#### 桌面添加备忘录

右键桌面=>编辑小组件

#### 查看mac使用技巧

桌面的帮助里面有,可以查看各更新版本新增功能



# mac系统

#### 1. 没有ll指令

只有ls指令，没有ll指令，在～目录下，创建了一个 .bash_profile文件，加了一句alias ll = 'ls -alF' 之后ll就能用了

需要source ～/.bash_profile 



#### 2.mac配置环境变量

安装了homebrew ，没配置环境变量，无法直接执行brew 指令,也是在 ~/.bash_profile 加一句

export PATH="/opt/homebrew/bin:$PATH" ，这句代码执行的是，把/opt/homebrew/bin  拼接在$PATH这个变量前面，

终端打印$PATH 结果是

```
/opt/homebrew/bin /Library/Frameworks/Python.framework/Versions/2.7/bin /usr/local/bin /System/Cryptexes/App/usr/bin /usr/bin /bin /usr/sbin /sbin /usr/local/share/dotnet ~/.dotnet/tools /Library/Frameworks/Mono.framework/Versions/Current/Commands
```

具体原因如下图

```
Mac系统下的环境变量
a. /etc/profile
b. /etc/paths
c. ~/.bash_profile
d. ~/.bash_login
e. ~/.profile
f. ~/.bashrc
说明：
1、其中a和b是系统级别的，系统启动就会加载，其余是用户接别的。
2、c,d,e按照从前往后的顺序读取，如果c文件存在，则后面的几个文件就会被忽略不读了，以此类推。
3、~/.bashrc没有上述规则，它是bash shell打开的时候载入的。
4、建议在c中添加环境变量，以下也是以在c中添加环境变量来演示的
```



打开新的终端之后，配置的.bash_profile 里面的环境变量不生效

- 1、我们是在bash中配置的[环境变量](https://so.csdn.net/so/search?q=环境变量&spm=1001.2101.3001.7020)，而当前系统是使用的是shell。
- 2、查看当前使用的shell：

```bash
1、终端输入：echo $SHELL 
2、输出是/bin/zsh，说明使用的是zsh
```

解决方法  在~/.zshrc  文件加中添加source ~/.bash_profile    



#### 3.homebrew 

下载指令brew install   

brew search gcc，查找某个插件

homebrew 下载的软件不用配置环境变量就能终端直接使用，和yum差不多. 

homebrew下载的软件目录在 /usr/local里面





#### 4.java安装目录

当初下载java的时候是通过dmg文件下载的，dgm的下载的不需要自己配置 JAVA_HOME ，就可以在终端执行java

但是通过dmg下载的java目录，可以通过指令查询  /usr/libexec/java_home -V

```
/Library/Java/JavaVirtualMachines/jdk1.8.0_291.jdk/Contents/Home
```



#### 5.word和excel激活

```
账户 
a4433@riverdale.rac.sch.uk
密码
Lpc19950419

注意登陆后，需要点击右上角 关于Microft word下面一行 ，激活word才行，并不是登陆就行
```

#### 6 word乱码问题

用pages打开word不乱码, 然后用pages导出新的word，用word打开新的word就不会乱码了

# mac快捷键

#### 显示隐藏文件

 1 shift+command +. 可以显示隐藏文件

#### 切输入法

2 control + 空格  切换输入法

#### 剪切快捷键

3 command+option+v 将复制的剪切下来





# 外设键盘指令

外设连接：

键盘开蓝牙：fn + q 蓝牙1。fn +w 蓝牙2 fn +e 蓝牙3. 多设备切换也是。 

B是蓝牙，G是接收器。
