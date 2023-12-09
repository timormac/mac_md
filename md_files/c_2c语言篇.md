# c语言概述及安装

c99是主流版本

c语言文件.c 后缀

c语言基本模版

```c
#include <stdio.h>
int main()
{
	printf("Hello");
  getchar()
	return 0;
}
```

### 安装gcc编译器

c文件需要用编译器生成可执行代码，最常见的是gcc编译器。

先下载gcc编译器，,然后配置环境变量.

mac 安装gcc ，通过homebrew 安装，brew install gcc



### 编译指令  

gcc Hello.c  生成一个可执行文件 

gcc -o gc  Hello.c  指定编译文件名字

gcc -std=c99 Hello.c  因为c有多个版本，按照c99的语法标准编译



注意c语言不需要下载像java 和python这种解释器,gcc编译出来的是机器语言，window和linux都可以直接执行



# clion使用

clion是jetbrain开发的编辑c,c++的程序

### 配置编码字符集	

settings =>Editor=>File Encodings=> 把global encoding和project encoding都改为utf-8

把properties Files也改为utf-8 ，把transparent native-to-ascii 勾选

BOM for new UTFfiles ,选择with no BOM



设置控制台字符集

Editor中 =>general =>consoles=>改为utf-8





### 配置多个可执行main

前面已经创建了一个demo1工程，项目文件夹内存在一个代码文 件，名为 。如果再创建一个C源文件，内部如果也包含 main()函数，则会报错!因为默认C工程下只能有一个main()函数

安装C/C++ Single File Execution插件

settings=>plugins=>搜索Single File Execution

安装之后新建项目，会多一个CMakeLists.txt 文件，是Single File Execution帮我们做的



新建一个c.文件，右键add Single File Execution,然后c-make-build 目录执行reload.

第三步，右上方选择你要执行的文件，如果进去代码里点执行，还是按右上方执行，还是会包重复main，默认的是已项目命名的main方法



### 新建项目

默认是c++ excution，选择c  excution ，然后选择c99标准.

右键项目目录，创建c/c++ source file,  class是类文件





# c语言

注释   //

### 链接

可以理解成配置包和依赖，比如#include <stdio.h> ，printlf就是stdio.h库中的函数

