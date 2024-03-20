# 问题待解决



# 问题已解决(待回顾)





#### 无上游分支

当前分支 master 没有对应的上游分支

把md目录上传github管理遇到问题：当前分支 master 没有对应的上游分支，为推送当前分支并建立与远程上游的跟踪。

 执行 git push --set-upstream 远仓别名 master



#### 代码pull失败代码冲突

最好用idea去pull，能直接看到哪几个文件冲突，可以选择合并/选择他/选择你的

警告:your local changes will be overwritten by merge. commit, statsh,or revert them to proceed





文件改动无法合并问题

当clone库后，通过idea做了些vcs文件修改，导致.idea中的.vcs发生变化，然后当去从原仓库pull时候，导致没法合并。

这个时候git stash 封存修改  再git pull ，然后再git stash pop 把修改还原，这种操作是保存本地修改。

idea操作方法:

右键 --> Git --> Repository --> Stash Changes --> Create Stash 将本地的全部改动临时保存到本地仓库，并撤销了本地的所有改动；然后再pull 最后再点击 UnStash Changes --> Pop Stash ，这样就将之前的改动合并到本地。



#### 连接github超时

```mysql
#问题描述
之前没问题，有一天在wins上，git pull报错连接github超时（connection time out）
但是电脑能正常访问github网页

#问题原因
Git文档说的原因是有可能是防火墙完全拒绝允许 SSH 连接
通过http创建ssh连接，大部分防火墙允许。不过可能是代理问题产生干扰

#解决方法
找到windows下git的安装目录， 然后在Git\etc\ssh\中找到 ssh_config文件，然后在这个文件的末尾加上下面这段设置：
Host github.com
User XXXX@163.com(github账号) 
Hostname ssh.github.com
PreferredAuthentications publickey
Port 443

mac系统: .ssh目录下添加一个文件：config
Host github.com
User XXXX@163.com(github账号) 
Hostname ssh.github.com
PreferredAuthentications publickey
Port 443

```



# 问题已理解(备份)

```sql
####  fork库不更新
当原库更新的时，fork的仓库不会更新。创建2个remote远程仓库，一个是开源仓库，一个是fork库。
本地写完代码,先pull开源仓库源码,再推送到fork库

#### 创建git管理失败
git管理的目录不能下的目录，不能再有.git文件，不然会报错。
场景是:所有的java项目都在mac_project目录下，想管理mac_project目录，将所有的项目上传github，但是其中有的项目通过idea创建了git管理，所以最mac_project的git管理就有问题了

#### 连接不上github服务器
http拉取会失败,ssh没有问题
github代码突然不能push 也不能clone了，因为改成了http

#### 提交落后于远程分支
[! [rejected\] master -> master (non-fast-forward)      具体报错
更新被拒绝，因为您当前分支的最新提交落后于其对应的远程分支
原因: github创建库的时候，添加了read.md文件，这样github仓库就有了一次commit
本地用idea创建项目后，有commit提交。当push时，导致2边的head不一致
解决方法:删除github库创建一个没有commit提交记录的库
```



# git企业管理

```sql
#企业中哪些用git管理
hadoop等，tomcat等的框架的配置文件用git管理

#jar包管理
git是文件管理系统，每个版本会做快照，不适合管理jar包这些，不然会出现多分快照，体积很大
jar包的管理，有持续集成jekins会保留每次的jar包。以及Artifactory、Nexus等二进制管理仓库，用来记录各版本用哪些jar包

#企业回滚
通过git记录配置文件,jekins保留jar包，Nexus管理二进制仓库。
通过自动化脚本来处理回滚流程，自动回滚git版本，Nexus版本等

```





# idea相关git操作

### idea项目添加git管理

点击vcs =》add git respotory   然后选择目录(默认是在项目目录下创建.git文件)

因为默认是在项目目录下创建.git文件，所以传递github是只会上传src,pom等



### idea创建git项目

当你idea新建的项目在已经有.git管理的目录下，并且选择了增加git支持，那么项目目录下也会有.git文件

一般新建项目添加git支持，可以用来本地更改代码记录，不一定非要上传云端



### 手动git管理项目对接idea

idea已有的项目，我们自己在项目目录下执行了git init , git指令手动添加remote，idea就能自己识别到了



### idea项目上传github

先在github上创建一个git_hdfs库

通过idea创建包含git的项目,然后上传云端,编写代码，之后commit，然后commit再push时会让你绑定一个url，将github仓库的url粘贴过来就行。注意这种上传云端只会把src目录传过去，项目目录不会传递过去

### idea拉取github项目

1 如果用本地的git去clone  github上的库，会默认创建一个和库名相同的目录

2 用idea 通过vsc创建项目，输入url后，只会下载仓库内的文件，不会新建一个仓库目录。之前的flink是因为把flink目录也传给github上了，hdfs只传了个src目录，所以需要自己建项目名。





当本地更改代码后，push会报错，显示permission deny，没有权限。

应为clone的项目,push默认推送到clone的仓库，所以需要配置权限,并且另一方通过后。winodow的账号的github会出现mac的库。

当widows push代码时，会直接合并，因为是团队合作。

需要确认的是fork的仓库，fork仓库才能通过pull request申请通过



### idea中切换分支

选择git => branches=>check out (不是check out as )



### .gitignore

```
### IntelliJ IDEA ###
out/
###忽略所有目录下的out文件,没太懂，既然是通配符，为啥还要写src/main###
!**/src/main/**/out/
!**/src/test/**/out/
!**/target/
.idea/
### 忽略本身自己
.gitignore
### Mac OS ###
.DS_Store
```

当配置了.gitignore后，添加了.idea。虽然自己新添加的测试文件，git status看不到了， . idea之前的系统文件还是能看到。

因为我们误解了.gitignore文件的用途，该文件只能作用于Untracked Files。

需要执行 git rm -r   --cached  ./.idea ，这个指令的目的是，递归删除git对 ./idea下文件的管理,并不会删除文件,只会删除管理

这样.idea下的原有文件, git status就看不到了。

再执行 git rm --cached .gitignore删除对igonre管理就行了。



总结来说:当在.ignore文件中过滤了.idea目录，那么以后的.dea新增的文件都不会记录。但是之前已经记录的不会消失，需要手动去除





# github操作

github上的库3种来源：自己创建，fork别人，别人把你拉入开发组(你的gihub上会有对应的项目仓库)

### 团队协作

选定仓库，在github仓库点settings=>collaborator=>add people ，等对方同意后。对方才有提交权限，如果没有add那么对方只能clone，push的时候会显示没权限。

当被邀请人同意之后，他的github上会出现对应的仓库,和fork不同，开头名字是发起人的名字。

### github高级搜索

 in:name flink  项目名字包含flink

in:description flink   描述信息里包含flink

pushed:>2023-06-01  最新push在6月后

stars:>1000  stars超过1000





### fork项目开源开发

fork

是对一个仓库的克隆。克隆一个仓库允许你自由试验各种改变，而不影响原始的项目。
一般来说，forks 被用于去更改别人的项目（贡献代码给已经开源的项目）或者使用别人的项目作为你自己想法的初始开发点。
提出更改别人的项目.Fork 这个仓库，进行更改，向这个项目的拥有者提交一个 pull requset，如果这个项目的拥有者认同你的成果，他们可能会将你的修复更新到原始的仓库中！



pull requests 

先fork一个仓库，然后你在a2仓库工作，commit,push等。当你希望原始仓库合并你的代码，可以在github上发起一个pullrequest，

请求合并你的分支，审核通过就合并了



在github上登录自己账号，找到别人的项目或者将别人的项目链接发给你，然后fork

fork之后，你的github会出现对应的仓库，不过和团队邀请不懂，这个前缀名字是你自己的名字

1 然后clone 自己fork的仓库 =》 写代码，当要push的时候，先把原仓库的代码拉取然后合并，再push到自己fork仓库

 =〉最后在fork仓库来 提交pull request ，经过原仓库审核合并。

2  fork的仓库代码修改后，windows点pull request=> new pull request=>mac进入pull request点击合并同意

3 fork实时同步问题：winodows每次写代码的时候先从mac库pull，然后写完之后,在push到windows库，git pull的时候可以选择从哪个	远程仓库拉取。



### 单库多项目

github上一个repository，里面放多个目录。当用本地git 执行clone操作时，会创建一个和github库名相同的目录，该目录有.git文件





# git本地操作

### 本地clone

当用本地git 执行clone操作时，会创建一个和github库名相同的目录，该目录有.git文件



### 配置本地信息

进去仓库目录，git init 初始化目录

git config  user.name  查看当前登陆用户

git config  user.email  查看当前用户登陆邮箱

git config  --global user.name  "timormac" 设置用户名

git config  --global user.email  "286710"设置用户名

git config --global user.password 'password' 

git config  --global --list  查看用户名和邮箱

git remote -v  查看所有远程仓库别名

git remote add 别名 远程地址  将别名和远程仓库建立连接

git remote rename  old  new   更改别名

git remote set-url origin   新地址，更改远程仓库地址



### 基本命令

##### git pull做了什么

当执行git pull orgin master --后

```sql
#下面是 git reflog记录
1174b66 (HEAD -> master) HEAD@{0}: pull origin master --rebase (finish): returning to refs/heads/master
1174b66 (HEAD -> master) HEAD@{1}: pull origin master --rebase (pick): mac-test
5242c08 (origin/master) HEAD@{2}: pull origin master --rebase (start): checkout 5242c0829f2e059f5fd1
edc495e HEAD@{3}: commit: mac-test
7ab28f5 HEAD@{4}: commit: 12-17git版本冲突实验

#分析
7ab28f5是创建文件,是winodw和mac共同的版本开始  
edc495e  mac-test是mac修改后commit的版本
5242c08查看了，是windows修改commit提交后的版本号
1174b66 就是把edc495e当前mac的commit提交 和windows的commit提交合并后的仓库版本

#总结
git pull会直接把github的最新版本与最后一次commit的版本进行merge，然后直接在commit的仓库区生成新版本，所以pull后不需add
因为git pull会直接合并到仓库区, 所以在pull前，都会提示请将工作区代码commit不然会被覆盖。
git status比较的是工作区和最新仓库区的差别

```

##### 版本冲突测试

```sql
#最开始文件               winodw              mac
这一行是大家都要的   			这一行是大家都要的			这一行是大家都要的
这一行是大家都要的					windows修改了这一行		这一行是大家都要的
												windows加入了这一行		mac增加了这一行
												
#当各仓库commit后,pull情况
window推到github上，mac执行git pull --reabase ,发现能直接合并，这种修改方式不会出现无法merge的情况。
虽然第二行被winodows改了,但是mac合并不会报错，并不会发现被别人修改了。

#合并后
这一行是大家都要的
windows修改了这一行
windows加入了这一行
mac增加了这一行
```

##### 冲突解决记录

```sql

#公共状态									#mac提交的状态									#windows状态	
这一行是大家都要的					第二次mac修改了第一行				第二次windows修改了地一行，同时删除了第4行内容为"mac增加了这一行"
windows修改了这一行				windows修改了这一					 windows修改了这一行
windows加入了这一行				windows加入了这一行					windows加入了这一行
mac增加了这一行						mac增加了这一行							

#简述
mac修改了第一行
windows修改了第一行，并且删除了第四行

#流程
2边都git add => git commit => wins push  然后 mac pull --rebase指令

#git pull --rebase返回结果
git pull origin master --rebase
来自 github.com:timormac/mac_md
 * branch            master     -> FETCH_HEAD
   1174b66..56fe382  master     -> origin/master
自动合并 git_test版本冲突.md
冲突（内容）：合并冲突于 git_test版本冲突.md
错误：不能应用 73d2f7a... mac第二次测试冲突

并且这个时候不小心操作了git.md，想增加文件内容时，显示文件被其他应用打开。因为git pull合并失败，pull是merging状态，文件被锁了，才会提示。

#执行git status 查看失败pull的状态
timor@lixianshengdeMacBook-Pro Desktop % git status

交互式变基操作正在进行中；至 56fe382
最后完成的命令（1 条命令被执行）：
   pick 73d2f7a mac第二次测试冲突
未剩下任何命令。
您在执行将分支 'master' 变基到 '56fe382' 的操作。
  （解决冲突，然后运行 "git rebase --continue"）
  （使用 "git rebase --skip" 跳过此补丁）
  （使用 "git rebase --abort" 以检出原有分支）

要提交的变更：
  （使用 "git restore --staged <文件>..." 以取消暂存）
  修改：     md_files/a_5git.md
  
未合并的路径：
  （使用 "git restore --staged <文件>..." 以取消暂存）
  （使用 "git add <文件>..." 标记解决方案）
  双方修改：   git_test版本冲突.md
  

#打开冲突文件，会看到如下，最好用类似idea的工具大概，这个可读性太差了
#<< HEAD 到 ===之间是你的本地修改，=== 到 >>> 1234567890abcdef 之间是远程分支的修改。

<<<<<<< HEAD
第二次windows修改了地一行，同时删除了第4行内容为"mac增加了这一行"
=======
第二次mac修改了第一行
>>>>>>> 73d2f7a (mac第二次测试冲突)
windows删除了这一行
windows加入了这一行
<<<<<<< HEAD
=======
mac增加了这一行
mac又增加了这一行
>>>>>>> 73d2f7a (mac第二次测试冲突)

#idea人性化对比冲突文件
右键空白，git,resolve conflicts就能看到2次版本对比
  
#手动解决冲突
解决冲突时，要把====  <<<<HEAD删除，并且把文件改成你想要的样子,修改后执行git add 冲突文件名字


#再执行git status,如下
交互式变基操作正在进行中；至 56fe382
最后完成的命令（1 条命令被执行）：
   pick 73d2f7a mac第二次测试冲突
未剩下任何命令。
您在执行将分支 'master' 变基到 '56fe382' 的操作。
  （所有冲突已解决：运行 "git rebase --continue"）
  
  
#git rebase --continue  
执行git rebase --continue ,执行这个后会弹出个介绍，直接q退出就行。出来后，看到所有的都被commit了
相当于把git pull之前中断的部分，解决完冲突后，执行完毕了。

注意git pull 默认有个合并后commit的版本，这个版本的 -m介绍 就是你本地的那次 -m介绍
当你合并了冲突push后，windows版本再拉取时，就不用再解决冲突了，直接拉取就成功了

#错误操作
当解决冲突后执行,git add冲突文件，然后应该直接执行git rebase --continue 
但是我先执行了git commit，然后执行git rebase --continue,显示如下，并且状态是(master|rebase 1/1)

”“”
$ git rebase --continue
Applying: 2024-01-29 WINS提交代码
No changes - did you forget to use 'git add'?
If there is nothing left to stage, chances are that something else
already introduced the same changes; you might want to skip this patch.

Resolve all conflicts manually, mark them as resolved with
"git add/rm <conflicted_files>", then run "git rebase --continue".
You can instead skip this commit: run "git rebase --skip".
To abort and get back to the state before "git rebase", run "git rebase --abort".
“”“

如果你确定commit是正确的，执行git rebase --skip就可以

```



##### git stash

```sql
#git中什么场景使用git stash 和git stash pop，为什么不在pull时直接解决冲突

git stash 和 git stash pop 在Git中的使用通常与工作流程中的临时需求和上下文切换有关。以下是一些使用这些命令的场景：

上下文切换：假设你正在开发一个新功能或修复一个bug，并且你的工作还没有完成到一个可以提交的程度。突然你需要切换到另一个分支处理更紧急的任务。你可以使用 git stash 将当前的工作存储起来，然后干净地切换到另一个分支。

避免中断：如果你有一些改动，而这些改动你不想立即提交（可能需要更多的测试或审查），你可以暂时用 git stash 将它们存储起来，以便稍后再继续工作。

快速清理：当你想要快速回到一个干净的工作目录，比如要运行一个从最近的提交开始的构建测试，你可以用 git stash 来保存当前的改动，然后在测试结束后用 git stash pop 恢复这些改动。

至于为什么不在 git pull 时直接解决冲突，这实际上取决于你的工作流程和个人偏好。有几个原因可能促使你使用 git stash：

避免冲突：如果你知道远程分支有更新，并且你的本地改动可能会和这些更新冲突，你可以先用 git stash 存储本地改动，然后执行 git pull 来获取远程分支的更新。之后，你可以尝试用 git stash pop 来恢复你的本地改动，并在一个已经更新的代码基础上处理可能出现的冲突。

保持工作区干净：有时候，你可能想要避免在 git pull 的过程中处理冲突，因为你希望保持工作区干净，或者你想要更仔细地审查远程所做的更改，以便更好地理解如何整合你的本地改动。

工作流程要求：某些工作流程可能要求你在拉取远程更改之前提交或存储你的本地改动，以确保远程更改不会影响你当前的工作。

git stash pop 恢复了之前被暂存的改动，并尝试将它们重新应用到当前的工作目录中。如果在你暂存改动之后，代码库发生了变化，可能会出现冲突。在这种情况下，Git会警告你，并允许你手动解决这些冲突。这可以让你有机会在一个清晰的上下文中理解和解决冲突，而不是在 git pull 期间匆忙处理。

#为什么切换分支时要git stash,直接切换不行吗？

直接切换分支是可以的，但是这取决于你当前工作目录和暂存区的状态。以下是一些需要考虑使用 git stash 的情况：

未完成的工作：如果你正在一个分支上进行工作，但这些改动尚未完成到可以提交的地步，直接切换分支可能会产生问题。Git通常不允许你带着未提交的改动切换分支，因为这些改动可能与新分支上的文件冲突。

干净的工作区域：即使Git允许你带着未提交的改动切换分支（例如，当改动的文件在两个分支上没有差异时），你可能出于组织原因希望保持工作区域的干净。git stash 允许你保存当前的进度，然后干净地切换到另一个分支进行工作。

潜在的冲突：如果你的改动可能与你要切换到的分支上的文件冲突，Git将阻止你切换分支，以避免自动合并可能导致的问题。在这种情况下，你需要提交改动，或者使用 git stash 来临时保存这些改动。

工作流程要求：有些工作流程可能要求在切换分支之前保持一个干净的工作目录，以确保每个分支上的工作是独立和清晰的。

总之，git stash 是一个非常有用的工具，可以在你需要切换上下文但又不想提交半成品代码时，帮助你保存当前的工作状态。这样做可以让你的工作流程更加灵活和有序。当你准备好继续之前的工作时，可以使用 git stash pop 或 git stash apply 来恢复你的改动。
```



##### git指令详解

```sql
#git分区
工作区,缓存区,仓库区
工作区:就是通过鼠标a.txt所看到的内容就是工作区内容
缓存区:当远程仓库有代码更细时，fetch后是在缓存区进行操纵的，不可能直接更改你本地的文件，这也不合理
仓库区:当你再缓存区确认无问题合并后,commit提交到仓库区，会生成一个版本号，用户历史回滚

#.gitignore文件
如果想要让git不跟踪某些文件,.gitignore在文件中加入这些文件或者目录,写法如下：
a.txt  不跟踪a.txt文件
dir1/  不跟踪dir1目录

.gitignore文件只会影响尚未被跟踪的文件和目录,如果已经被git跟中，需要下面2个指令删除
#git  rm -r   --cached   dir 
删除已经被git管理的目录
#git rm   --cached   file 
删除已经被git管理的文件

#git status
查看当前工作区和最后一次commit时的差别变更

#git add  a.txt
将工作区变更提交到缓冲区,这里会有个缓冲区版本
#git add -A 
把工作区的修改都提交到缓冲区，包括修改，新增文件，删除文件

#git restore --staged  a.txt

撤销暂存的文件：如果你使用了 git add 命令将文件添加到暂存区，但是后来决定不想提交这些文件，git restore --staged a.txt 
会把已经变绿的修改为变红

##git restore   a.txt
还原修改的文件：如果你在工作目录中对文件进行了修改，但是还没有提交到缓冲区，可以直接不要文件的改动
#git checkout a.txt
和git restore   a.txt一个作用，不过还可以用来切换分支


#git commit -m "123"  
将缓冲区数据提交到仓库区，形成版本号

#git fetch  origin   main  
从远程仓库获取最新变更,放入到缓冲区

#git log  -p main  origin/main  
比较本地main分支和远仓main分支区别，一般是配合fetch使用。查看下是否合适

#git merge origin/master
把fetch获取的缓冲区变更，合并到工作区。注意当有文件冲突时，会合并不了

#git pull orgin  master:master 
pull相当于fetch + merge。

#git pull orgin  master  --rebase  
当远程仓库有人提交过变更时,pull会报错，这时候执行这个执行，这个执行是在和合并的时候，会展示哪里合并不了，需要你手动更改冲突

#这个是git当时推荐的pull失败的解决方法全都不行，用的 --rebase才成功的
git config pull.rebase false：这个指令将配置 Git 的 pull 命令使用合并（merge）方式。当你执行 git pull 时，Git 会将远程分支的最新提交合并到你的本地分支上。
git config pull.rebase true：这个指令将配置 Git 的 pull 命令使用变基（rebase）方式。当你执行 git pull 时，Git 会将你的本地提交暂时保存，然后将远程分支的最新提交应用到你的本地分支上，最后再将你的本地提交重新应用在之后。
git config pull.ff only：这个指令将配置 Git 的 pull 命令只允许快进（fast-forward）。当你执行 git pull 时，Git 只会在你的本地分支能够直接快进到远程分支的情况下才执行更新，否则会报错。
取消快进的配置：git config --unset pull.ff

#git push  origin master
把本地commit的版本，推到远程仓库。
注意如果远程仓库有人提交过，那么就会push失败。会警告：当前仓库比远程仓库低一个版本，需要先pull再push

```



##### 常用指令

```sql
#为当前目录添加git管理
git init
#只需一个空目录就行，不需要git init，clone后的目录下自带.git文件管理
git clone <版本库的网址>  

# 查看当前仓库状态,分支信息
git status  
#丢弃工作区改动,返回到上一个commit版本
git restore a.txx

#丢弃工作区改动,返回到上一个commit版本
git checkout -- a.txx


#将仓库改动提交到暂存区
git add/rm  文件(新增或者删除)    
#将暂存区改动保存，生成1个版本号，可以用于历史回滚
git commit -m "备注"   
#把远程仓库某个分支合并到本地仓库指定的分支
git pull 元仓别名  远程分支名:本地分支名  
#本地仓库推上到远程仓库指定的分支,
git push  远仓别名   分支名
#本地仓库推到远程仓库同名分支时候，可省略写法
git push

#从远程获取最新版本到本地。和gitpull区别：不会自动合并
git fetch    origin   main           
#比较本地main分支和远仓main分支区别，一般是配合fetch使用
git log  -p main  origin/main  ，配合fetch
#把远程仓库的main分支合并到当前分支，一般是git log查看后，使用
git merge origin/main   

#查看历史记录（获取版本号)
git reflog 
# 回到某版本
git reset --hard 版本号     


#查看所有分支
git  branch  


#创建分支(当前分支所在状态会复制过去)
git  branch    分支名    
#切换分支
git checkout  分支名   
#删除分支
git  branch -d  分支名  

#从远程仓库下载并在本地创建对应分支
git checkout -b feature-branch origin/feature-branch



//.gitignore文件只会影响尚未被跟踪的文件和目录,如果已经被git跟中，需要下面2个指令删除
#删除目录下文件的管理
git  rm -r   --cached   dir 
#删除文件的管理
git rm   --cached   file 
```

### 本地仓库关联github

点击github仓库的code图标,找到ssh连接地址： git@github.com:timormac/git_warehouse.git

git remote add  别名   git@github.com:timormac/git_warehouse.git     将别名和远程仓库创建连接

git push  远仓别名  分支名字  （会发现失败连接不上github）

ssh -T git@github.com   查看能否登陆到github上 （失败）

ssh -keygen -t rsa -C 2867102374@qq.com       执行后会生成～/.ssh/id_rsa.pub文件，复制到github上

流程github settings，点击SSH and GPG ，点击New SSH  复制

配置之后ssh -T git@github.com   ，使用push还是失败，提示因为远程仓库包含您本地尚不存在的提交，需要先pull

git pull origin  master,还是失败，显示拒绝合并无关的历史，这是因为在pull之前，自己新建过一个项目，执行了add和commit,

所以需要执行下面命令，忽略历史 git pull origin main  --allow-unrelated-histories



### git操作规范

commit提交,当你功能完成的时候才提交，不要完成一半的时候就git add 提交。

答案：会有这个疑惑的，请先问问自己，使用git时候是否都是所有的修改全部提交了，根本没有考虑到多个修改文件，是和多个功能有关，而每一个功能应该单独做成一次提交，这样可以保证提交历史的清晰。否则，当你想要回滚历史的时候，你会无所适从，根本分不清每个版本包含了哪些功能，修复了哪些bug.而暂存区的作用就是为了，可以选择提交，比如你在开发B功能的时候，发现A功能还存在Bug，这时候就需要先修复A中的Bug，然后先提交修复的A中的Bug,然后再提交B功能开发的文件。这样就可以提高提交版本历史记录的清晰，方便回滚。而提交是原子性操作，文件的选择就交于暂存区去做，每一次提交都是一个完整的功能开发，保证commit的干净，降低commit的粒度。

例子：比如你在优化功能a开发了一半，然后有个紧急bug要你修复。然后你修复了b就要赶紧提交了。但是你a才优化到一半，不可能把a也提交了，不然的话a功能不能用了。如果没有缓冲区的话，你只能等a优化完才能一起提交。而且这个提交包含了两个功能，优化和改bug。不太好。版本提交应该功能分工明确。而且对于紧急的bug修改应该改了立刻提交，而不是等到a开发完成。缓冲区你可以add你要提交文件。所以比直接把整个代码库提交要好。





















# 





















