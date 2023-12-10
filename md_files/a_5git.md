# 问题待解决

1  现在本地创建个idea项目pro1,创建添加git依赖,生成的.git文件在pro1目录下，

​	当通过idea上传到github后，会在rep1库下出现个pro1目录

​	用git本地clone库的时候，本地会创建一个rep目录.git目录是在rep目录下，而不是在pro1目录下。

​	当手动用idea导入项目时，要选定rep下的pro1项目.

​	直接用idea导入项目会找不到maven项目,应该是因为把rep整个库当作idea项目了所以读取不到

2 为什么flink_realtime那个项目没有把项目目录上传到github上，只把子项目的目录上传到github



# 问题记录

#### 提交落后于远程分支

[! [rejected\] master -> master (non-fast-forward)      具体报错

更新被拒绝，因为您当前分支的最新提交落后于其对应的远程分支

原因: github创建库的时候，添加了read.md文件，这样github仓库就有了一次commit

​		 本地用idea创建项目后，有commit提交。当push时，导致2边的head不一致

解决方法:删除github库创建一个没有commit提交记录的库



#### 连接不上github服务器

http拉取会失败,ssh没有问题

github代码突然不能push 也不能clone了，因为改成了http

#### 无上游分支

当前分支 master 没有对应的上游分支

把md目录上传github管理遇到问题：当前分支 master 没有对应的上游分支，为推送当前分支并建立与远程上游的跟踪。

 执行 git push --set-upstream 远仓别名 master

#### 代码pull失败代码冲突

警告:your local changes will be overwritten by merge. commit, statsh,or revert them to proceed

```sql
这句话是Git在执行合并操作时给出的警告信息，意思是你的本地更改因为没进行commit提交过，直接拉取会被覆盖。

处理这个警告的方法取决于你希望如何处理你的本地更改。以下是几种可能的处理方式：

#先git add,commit再pull，这样自己和云端代码都有
提交（commit）：如果你希望保留你的本地更改并将其合并到最新的代码中，你可以先使用git add命令将更改添加到暂存区，然后使用git commit命令提交更改。这样你的更改将被保存并与合并后的代码一起提交。

#先暂存再pull，之后pop stash,注意这时候你的更改没有git add过,和第一种方法就区别在这里了
暂存（stash）：如果你希望在合并之前暂时保存你的本地更改，可以使用git stash命令。这将把你的更改保存在一个临时存储区，然后你可以执行合并操作。合并完成后，你可以使用git stash pop命令将你的更改重新应用到合并后的代码中。

#丢弃自己更改
还原（revert）：如果你希望完全取消你的本地更改并将代码恢复到合并之前的状态，可以使用git revert命令。这将创建一个新的提交，撤销你的更改，并将代码恢复到合并之前的状态。

具体选择哪种处理方式取决于你的需求和代码库的状态。在进行任何操作之前，建议你先使用git status命令查看当前的更改状态，并确保你理解你的更改将如何影响合并操作。
```



文件改动无法合并问题

当clone库后，通过idea做了些vcs文件修改，导致.idea中的.vcs发生变化，然后当去从原仓库pull时候，导致没法合并。

这个时候git stash 封存修改  再git pull ，然后再git stash pop 把修改还原，这种操作是保存本地修改。

idea操作方法:

右键 --> Git --> Repository --> Stash Changes --> Create Stash 将本地的全部改动临时保存到本地仓库，并撤销了本地的所有改动；然后再pull 最后再点击 UnStash Changes --> Pop Stash ，这样就将之前的改动合并到本地。



####  fork库不更新

当原库更新的时，fork的仓库不会更新。创建2个remote远程仓库，一个是开源仓库，一个是fork库。

本地写完代码,先pull开源仓库源码,再推送到fork库

#### 创建git管理失败

git管理的目录不能下的目录，不能再有.git文件，不然会报错。

场景是:所有的java项目都在mac_project目录下，想管理mac_project目录，将所有的项目上传github，但是其中有的项目通过idea创建了git管理，所以最mac_project的git管理就有问题了

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

#git restore  a.txt

撤销暂存的文件：如果你使用了 git add 命令将文件添加到暂存区，但是后来决定不想提交这些文件，你可以使用 git restore 命令将暂存的文件还原到最近一次提交的状态。

还原修改的文件：如果你在工作目录中对文件进行了修改，但是还没有提交到 Git 仓库，你可以使用 git restore 命令还原文件到最近一次提交的状态。


丢弃工作区改动,a.txt返回到上一个commit版本。执行后,查看文件之前的操作没有了

#git checkout 


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
#创建分支
git  branch    分支名    
#切换分支
git checkout  分支名   
#删除分支
git  branch -d  分支名  


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





















