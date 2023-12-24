# 问题待解决

1  hbase如何设置字段类型

2  如何一次插入同一个rowkey的多条数据

3  二级索引怎么实现的

4 如何范围查询？？



# Phoenix

### 简介

看文章：https://www.jianshu.com/p/e1ea1359dfb6

phoenix是一个集成hbase的项目，很有用Apache Phoenix与Spark、Hive、Pig、Flume、Map Reduce等Hadoop产品完全集成。

在我们的应用和 HBase 之间添加了 Phoenix，并不会降低性能，而且我们也少写了很多代码。

 phoenix 特点

- 将 SQL 查询编译为 HBase 扫描
- 完美支持 HBase 二级索引创建
- 支持完整的ACID事务、UDF、分页查询
- 确定扫描 Rowkey 的最佳开始和结束位置、扫描并行执行
- 将 where 子句推送到服务器端的过滤器



### 客户端指令

```sql
#启动phonix客户端
./bin/sqlline.py project1,project2:2181


#指令
!table  查看所有表  注意:没有分号;
drop table student;

#建表语句,想要表小写用"" 指定命名空间dev.放引号外面
#不过建议别用，查询的时候也必须加""
CREATE TABLE IF NOT EXISTS dev."timor_table"(
id VARCHAR primary key,
name VARCHAR,
age bigint);

#插入数据 必须用小引号,大的报错
upsert into student values('1','jake',10)

#创建二级索引
create  index my_index on timor_table(name);






#phonix数据类型,虽然hbase没有数据类型这一说
在 Phoenix 中，可以使用以下数据类型来创建表：
   - TINYINT：8位有符号整数。
   - SMALLINT：16位有符号整数。
   - INTEGER：32位有符号整数。
   - BIGINT：64位有符号整数。
   - FLOAT：单精度浮点数。
   - DOUBLE：双精度浮点数。
   - DECIMAL：任意精度的十进制数。

   - VARCHAR：可变长度字符串。
   - CHAR：定长字符串。
   - BOOLEAN：布尔值（true 或 false）。

   - DATE：日期，格式为 'YYYY-MM-DD'。
   - TIME：时间，格式为 'HH:MI:SS'.
   - TIMESTAMP：时间戳，包含日期和时间信息。




```



# hbase概览

###  使用场景

有一些数据没办法存到mysql里面，比如实时需求里面的记录用户今天首次登陆时间等等，这种没有存mysql没有意义。

hbase支持幂等性，这个比较好

### 查询数据

按rowkey获取指定数据

按rowkey的起始和终止位置扫描

按列族过滤，这个写法很复杂，这种按列族过滤，就是全表扫描。还是用pheonix生成吧

### 二级索引

目前hbase创建2J索引，可以通过es创建，或者phoenix创建，或者直接在本地创建

因为hbase按列族过滤会全表扫描，如果我想查询所有name = "lpc"的数据，那么需要建立个二级索引表。

具体二级索引的怎么设计，不知道pheonix怎么实现的。



# 组成架构

### 存储方式

行列存，一个列族下多个列是行存，多个列族是行存，想行存就设置1个列族

### 数据模型

namespace 类似detabase的概念

table 

row: 表的一行数据右rowkey和多个column组成，查数据只能按rowkey检索

colum:列族和列名来限定，column Family ， Column Qualifier

timeStamp：相同rowkey有新插入，有多条数据根据时间戳找最新的

cell：确定唯一单元





# 客户端指令

注意不能加；;是拼接多个指令用的，回车不会直接执行

进入客户端  bin/hbase shell

### ddl表操作

查看库  list_namespace

创建库  create_namespace    "dev"

查看库中表 list_namespace_tables  "dev"

清空表 truncate "tb1"

查看所有表 list

创建表: create  'tb1' , 'cols_a','cols_b' 

创建表指定库create  'namspace: tb1' , 'cols_a','cols_b' 

查看表结构 describe "tb1" 指定库  describe "dev:tb1"

删除表  先disable "tb"  再 drop "tb"



### dml数据操作

增加一条数据put 表名,rowkey,"列族:列名",值    ｜  put "tb1" ,1001,"cols1:name",lpc

删除某一列  delete "tb", 1000 ,"info:name"

删除一行数据  deleteall "tb1" , 1000

查看某行的列组:get  "student" 1001, 'info:name'



### 查询操作

查看整表数据 scan "tb1" 

查看指定行get "studnet" , '1001'

查看某行的列组:get  "student" 1001, 'info:name'

统计表数据条数 count "tb"  1个rk算一条

shell的过滤查询很麻烦，还是用Phoniex吧

# API





# 不重要问题



1.

ClickHouse 和 HBase 是两种不同的数据库系统，它们之间的主要区别如下:

1. 数据模型: ClickHouse 是一个列式存储的数据库，而 HBase 是一个键值存储的数据库。
2. 性能: ClickHouse 以高性能和大数据处理能力著称，而 HBase 则更适用于大规模数据存储和实时数据读写。
3. 数据处理: ClickHouse 支持 SQL 查询语言，支持复杂的数据分析和处理，而 HBase 更适合于实时读写数据。
4. 分布式架构: ClickHouse 采用分布式集群架构，而 HBase 是基于 Hadoop 的分布式数据库。

总的来说，ClickHouse 更适合于大数据分析和报表系统，而 HBase 更适合于大规模数据存储和实时数据读写。



clickhouse是一个为了OLAP而生的列数据库

clickhouse也支持join，那么这不是所有的都比hive+hdfs好了吗？

能存大量数据，还是个数据库，还有自己的数据计算引擎。

之前就有想过，怎么用hive对接habase的索引。这是类似的实现吗？

