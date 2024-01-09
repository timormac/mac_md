# shell注意事项

注意 ：shell语法对空格有很多要求不然就报错了注意

2 if  [  $1=asd  ]  注意等号前后必须写空格，不然一直显示是true

0 shell是按行执行，即使第一行报错了还是会执行下一行不会中断,exit是中断

1  word=asd   变量赋值等号前后不能有空格。前有空格把word当linux指令,后有空格把asd当linux指令

2 if  [  $1 = asd  ] if和then后面必须有空格，并且[]前后也必须有空格 

3 for((i=0;i<=5;i++)) for循环第一层括号必须没有空格

4 <号只能for中使用,  在[]中使用>会当作linx指令，报错没有这样的文件

5 变量赋值   word=$[$a+$b]

6 自定义函数调用时没有() 直接func 就行

7 a=$(pwd)  先执行pwd然后将返回结果赋值给a



# shell模版

#### 获取父目录

 通过;分开 可以多指令复合

 pdir=$(cd -P $(dirname $file); pwd)







# shell语言

## 脚本格式

\#!/bin/bash    指定用/bin/bash脚本执行文件

## 执行器

sh a.sh   sh就是bash指令的软连接

bash a.sh  bash执行器

./b.sh  需要脚本有可执行权限

## 变量声明

#### 系统变量

set指令可以查看说有系统变量

系统变量$HOME $PWD $PATH $USER

$HOME 查看家目录路径

 $PWD  脚本中的$PWD获取执行脚本文件时，终端所在的路径，而不是脚本文件的路径

 $PATH 获取环境变量里面的PATH

 $USER 获取登陆的用户

#### 数据类型

###### 字符串

注意：等号两侧不能有空格

变量类型默认字符串，不用引号，单双引号都可以，如果字符串里有特殊符号用引号

支持换行，不需要额外操作

word="a

bc

"

word="asd"  

word1=asd

#### 自定义变量

word="asd"  

使用变量

 echo $word  

w2="p$word"   可以放在""里使用

```shell
##变量使用
a=123
w1=$ac  #这种识别不出来$a  没有ac变量，w1是个空值
w2=$a-c #符号这种可以识别出来
```





#### 自定义数组

数组调用必须是${arr[1]}   ${arr[@]}是数组全体

```shell
#!/bin/bash
arr=(a b c)
echo ${arr[1]}
```



#### linux指令结果赋值

a=$(pwd)  先执行pwd然后将返回结果赋值给a



#### 变量运算式赋值

a=$[算式]   或$((算式))

word=1*2+3   会当成字符串

word=$[1*2+3]

word=$((1*2+3)) 必须是双括号

#### 特殊变量(脚本参数)

$n(脚本参数)   ：$0为脚本名称，1-9为脚本参数，${10} 10以上用大括号

$# (参数个数)  ：获取参数个数，一半用于循环几次

$* ：命令行中所有的参数，$*把所有的参数看成一个整体,与for连用

$@ ：命令行中所有的参数，不过$@把每个参数区分对待,与for连用

$@ 与$* 区别，就是当加上""时，传入for循环，$*是打印个整体 而$@还是分开的

$？ ：最后一次执行的命令的返回状态。如果这个变量的值为0，证明上一个命令正确执行；如果这个变量的值为非0（具体是哪个数，由			命令自己来决定），则证明上一个命令执行不正确了。）

```shell
#!/bin/bash
echo $PWD
#这里打印的$?是0
echo $?   
bash b.sh
#因为脚本不存在,$?的值是127
echo $?
```

#### 注释

#单行注释

## 条件判断（文档有点没看懂）

注意[]前后必须有空格

注意等号前后必须有空格，不然一直是true

[   $1 = asd   ] 

这里的比较只能用在[]条件判断中，for循环的条件判断可以>=

= 字符串比较

-eq数字比较

-lt 数字小于

-gr数字大于

-ne 不等于

## 流程控制

#### exit

退出脚本，后面语句不执行

#### if(写空格)

if ,then 后必须有空格,注意等号前后必须有空格，不然[]内一直出true

```shell
#!/bin/bash
if [ $1 = a ]
	then echo 参数1是a
elif [ $1 = b ]
	then echo 参数是b
else echo 参数不是a,b
fi
```

#### case

注意case里的分支里，执行语句无法嵌套if，写过失败了

case $变量名 in 

 "值1"） echo 1   ;; 

 "值2"） echo 2  ;;

 *） echo3 ;;

esac

注意事项：

（1）case行尾必须为单词“in”，每一个模式匹配必须以右括号“）”结束。

（2）双分号“**;;**”表示命令序列结束，相当于java中的break。

（3）最后的“*）”表示默认模式，相当于java中的default。

```shell
#!/bin/bash
case $1 in 
"a") echo a ;;
"b") echo b ;;
*) echo 其他 ;;
esac
```

#### for

第一种

for ((初始值;循环控制条件;变量变化)) 

 do echo1 

 done

```shell
#!/bin/bash
for((i=0;i<=5;i++))
do  echo aaa
done
```

第二种

for 变量  in  值1 值2   /或$*(全体参数)

```shell
#!/bin/bash
for  i  in  a b c
do echo $i
done

##遍历数组
arr=(1 2 3)
for i in {arr[@]}

#!/bin/bash
for  i  in  $*
do echo $i
done
```

#### while

<号只能for中使用,  在[]中使用>会当作linx指令，报错没有这样的文件

```shell
#!/bin/bash
s=0
while [ $s -le 5 ]
do 
	echo $s
	s=$[$s+1]
done
```



## 自定义函数

shell中自定义函数的参数没有参数列表，通过使用时直接传参数,调用时没有()

```shell
#!/bin/bash
function sum(){
	echo $[$1+$2]
}
##使用函数
sum 4 5
```



#### 自定义函数返回值

注意函数的返回值没法被变量获取只能通过$?获取

```shell
function func1(){
#因为没有mmm指令所以会报错
mmmm
echo 1
}
func1 
echo $?  ##打印的是0  ##虽然mmm指令报错了，但是因为函数的echo1是最后一行所以调用函数的$?还是0


function func2(){
 return $(mmmm)
echo 1
}
func2 
echo $?   ##$?是mmmm的执行情况
```



# linux常用指令(重点)

### ｜

管道符，可以把前面的输出作为一个临时文件，传递给后面的指令来执行

### set 

能看到系统中的所有变量，能看到自己编辑的HADOOP_HOME还有PAH等

### cut(感觉没用)

可以配合grep 使用

剪切文件并返回   -f  获取第几列   -d 指定分隔符切割  

fd必须一起用-d是分割成列，-f获取第几列

```shell
a s d
1 2 3
cut  -f 2  -d " " a.txt   ##返回的是第二列 

##可以配合管道符使用
ps -ef|grep timor|cut -d \t -f 2
```

### awk

awk是按行读取数据的   -F可以指定分隔符  执行操作写在'{print} 里，可以选择第几列注意必须是单引'{print}'

默认的-F是空格分割.

还有复杂的模式匹配，通配符什么的先不用了

```shell
##{print$1}可以只写一个，也可以不写括号
ps -ef|awk -F"\t"  '{print $1,$2}'
```

### which

查找linux指令在哪个bin目录下  ：  which ls

### find

在当前路径下递归查找文件或者目录

find ./  -name "*.txt"



