# 简言

目前的hive用的是spark计算引擎，为什么第一次那么慢，因为spark的相关jar包是存在hdfs的 /spark-jars中，第一次执行需要将jar包下载到各个节点然后加载类，所以慢。 





# 问题待解决

### 未知hql问题

```mysql
select 
recipient
from(
select 
recipient,
sum( amount ) over(  partition by recipient order by amount desc ) as total ,
sum(1) over(partition by recipient order by amount desc     ) as num
from transfers
)as tmp 
where total >= 1024 and num <=3
group by recipient
;

这里有个问题就是当order by的amount相同时，sum(1),num直接有2个相同的，正常时1，2，3 相同时就是2，2，3
```



### hive导入数据

现在文本数据是txt格式，目标表建表是压缩格式，那么load的数据,会将txt改为压缩格式吗？

load是hive的的指令，所以parquet表无法识别txt表。select 查询是报错，不是个parquet文件



### hive on spark中driver内存

下面，为什么给driver设置那么大内存12G，每个task启动一个12g的driver不浪费吗

### hive 2.1版本后支持ACID

从 Hive 0.14.0 开始，通过引入 ACID（原子性、一致性、隔离性、持久性）事务特性，Hive 支持了行级别的更新和删除。要在 Hive 中启用和使用 ACID 功能，需要满足以下条件：

1. 使用的是支持事务的文件格式，如 ORC。
2. 开启事务支持，设置 `hive.support.concurrency` 为 `true`。
3. 使用适当的事务管理器，通常是 `org.apache.hadoop.hive.ql.lockmgr.DbTxnManager`。
4. 为了实现事务，Hive 表必须是事务表。可以在创建表时使用 `TBLPROPERTIES ("transactional"="true")` 来指定。

### 如何确定reduce数目

  测试中有个表是2个block数据，执行select *插入另一个表，以及group之后插入另一个表，都是只生成1个reduce文件，

这和预期的不一样，正常不应该是几个map任务对应几个reduce任务吗？还是说表太小了，默认执行的是comine inputformat

### 报错NoClassDefFoundError

hive执行一个hql时发现一直无法执行，然后在yarn界面看到的日志，找不到具体原因。具体日志如下

```
在hive的报错日志显示如下
ERROR : Job failed with org.apache.spark.SparkException: Job aborted due to stage failure: Task 0 in stage 13.0 failed 4 times, most recent failure: Lost task 0.3 in stage 13.0 (TID 44, project1, executor 2): UnknownReason

在yarn日志里的报错显示的是这个
java.lang.NoClassDefFoundError: org/antlr/runtime/tree/CommonTree
这个问题好像是只有用spark引擎才会出现这个问题，切换成mr引擎就不会出现，是偶尔出现的问题

最后的解决方法是自己好了，猜测应该是内存不够的原因，因为之前可获取内存最大是200m，后面释放出来了就够了。
```

解决方法 yarn执行任务的日志，要去/op/moudle/hadoop/logs/userlogs里面去找，这里有container的运行日志，

然后去找stuerr，然后看里面具体爆什么错误。因为集群节点很多，有时候执行的mr任务只在几个节点执行，所以要先找到出问题的节点是哪个，然后去对应的节点的hadoop目录去找日志

### 执行计划案例2有疑问

执行计划中，没看到在reduce阶段再groupby ,是map join ,那么最后应该在reduce再join一次啊



### 压缩文件不能切会怎么样

默认是256读取map任务，如果128块大小不能切，并且是压缩的，怎么办呢



### hive优化器不能发现的优化

比如10表join,有大有小，怎么执行。

如果我用大表作为主表去关联的话，会一直把大表传递下去吗？

但是关联条件如果只有主表有怎么办，

比如

订单表，关联商品表，关联商户表，关联用户表， 

如果说关联商品表后，会再所有关联后的数据shuffle关联商户表，那就太慢了，不如先关联商品表。





### map join多个场景

map join  若参与join的n个表中,有n-1个表足够小，那么map会把小表全部缓存，然后找出一个最大的表，对最大的表进行扫描关联小表
					在map端进行join。

那么当5个表，3个小表，2个大表关联的时候，怎么生成的记性计划呢。



map join 能加载的表，是按总大小计算吗？还是说只要表小于25m，那么不管多少个表，都加载内存



我连续用了2个join之后，执行计划就复杂了很多。



//变成3个表join之后，执行计划就复杂了不少
--  explain select
-- orderinfo.orderno,
-- userino.name,
-- userinfo2.name

-- from warehouse.dwd_mysql_orderinfo as orderinfo

--  left join warehouse.ods_mysql_userinfo as userino

--  on orderinfo.userid = userino.id

--  left join  warehouse.ods_mysql_userinfo as userinfo2
--  on userino.id = userinfo2.id
--  ;









### 数据倾斜场景以及解决

数据倾斜在boss上看到的

**join为什么会数据倾斜**

一般来说，数据倾斜，都是大表join小表。

倒是小表加载到内存了，不会出倾斜。

当大表关键大表时，关联条件一般是订单号，也不会倾斜啊，只有group by才会倾斜。

**hive表格式导致的倾斜待验证**

hive表，文件格式存导致数据倾斜。

比如orc格式存，用snappy

10g数据压缩后为1g，分9个block存。

倒是snappy不支持切分。所以9个block只能单节点执行。因为这9个block是一份整体数据



解决方法flume，做操作，切片回滚。

保证每个压缩后的数据是128m，这样一个块一个单份数据。

### select 优化确认

```
不过如果你再套一个子查询例如:
select 
name,
id
from(
  select 
  *
  from t1  join t2  
  on t1.id =t2.id
)as tmp

这个子查询是否会优化到最上层的select，那么不确定，需要看执行计划
```







# 问题已解决(待回顾)

### hive对orc更效率

orc格式是为了提升hive效率设计的，所以hive能更了解如何读取orc文件。

所以hive on spark处理 orc表数据，会比同样的hql放到spark on hive要快。

不过新版本spark可能会优化orc的读取性能问题

### 压缩文件的mr并行度

```sql
#不可切分的压缩格式
案例1:
如果你讲一个100g的文件，采用snappy压缩到1g,上传到hdfs上，会被切分成8个block，但是你执行mr只会启动一个map任务，因为snappy不支持切分

案例2:
你用一个hql执行insert into 另一个表，并且只有1个reduce，这个表的压缩格式是snapyy。那么也是同理，读取时只有一个map

#parquet/orc的牛逼
parquet格式，内部默认是snappy压缩，但是parquet是可以压缩+切分。就算你使用一个reduce插入的10g数据

#原因：
Parquet是一个列式存储格式，它支持嵌套的记录。Parquet文件本身包含了多个独立的行组（row groups），每个行组包含了一部分数据，并且可以被独立地读取和解压缩。这是Parquet实现可切分压缩的关键。

Snappy压缩是在每个行组的级别上应用的，而不是在整个文件上。因此，即使你设置了reduce任务的数量为1，生成的Parquet文件也会包含多个行组，每个行组都可以独立地被Map任务处理。

在Hive执行`INSERT INTO`操作时，如果reduce阶段的输出是一个大的数据集（比如10GB），并且输出格式设置为Parquet，那么reduce任务会生成一个Parquet文件，Hive可以启动多个Map任务
```



### n表关联会多次map join吗

会,  根据视频的说法：map join  若参与join的n个表中,有n-1个表足够小，那么map会把小表全部缓存，然后找出一个最大的表，对最大的表进行扫描关联小表，在map端进行join。



### spark shuffle服务问题

当一个excutor执行完毕后要进行shuffle时,输出的数据统一shuffle服务管理，这样就可以提前关闭excutor了。

视频了出的问题在p17，开启shuffle服务了,但是后面的excuotor拉取不到想要的数据，因为新版老版协议问题。



### map-join阀值过大

YARN的容器设置最大内存为8GB，并将MapJoin阈值设置为6GB，这里有几个潜在的问题：

1. 内存溢出风险：尽管容器有8GB的内存，但这不仅仅是为了MapJoin。Map任务还需要内存来处理数据、运行Hive任务以及其他可能的内存消耗。如果你把MapJoin的阈值设置得太高，接近于容器的最大内存，可能会导致内存溢出错误，因为Map任务没有足够的内存来处理所有的需求。
2. 占用过多内存, 如果不进行map join，container申请的可能只是1g，当你设置map join，并且维度表6g，每个container都会申请最大的8g，因此导致集群最后申请的container数量变少，并行度降低
4. GC（垃圾回收）压力：大内存分配通常意味着更大的GC压力。Java虚拟机（JVM）中的垃圾回收可能会变得更加频繁，这可能会影响到Map任务的性能。



### hive -e指令报错

```mysql
#易错1
sql= "create table"
echo $sql
当""前有空格，会报错找不到create table的command

#易错2
您在定义 `sql` 变量时使用了引号，这导致整个查询字符串被视为一个单独的参数传递给 `hive -e` 命令。这可能会导致语法错误或意外的行为。

要解决这个问题，您可以尝试修改脚本，将 `sql` 变量定义为仅包含查询语句，而不包含引号。然后，将查询语句直接传递给 `hive -e` 命令，如下所示：

#!/bin/bash
sql="select userid,sum(paid) as total_paid,count(*) as total_num from warehouse.dwd_mysql_orderinfo group by userid limit 20"

/opt/module/hive/bin/hive -e "$sql" > /home/lpc/shells_hadoop/hql.result


在这个修改后的脚本中，`sql` 变量只包含查询语句本身，不包含引号。然后，`"$sql"` 将会将查询语句作为一个整体传递给 `hive -e` 命令。这样，您应该能够成功执行查询并将结果保存到指定的文件中。

原来的写法是直接 hive -e $sql ,然后我在$sql变量里嵌套" 'select '" 语句是不行的
```





# 问题已记住(备份)

```sql
### 列存实现原理
有个误区，既然hive不是个数据库，那么表输出为什么能列存呢?列存不是只有数据库才有吗
什么是行存储，什么是列存。
列式存储是指一列中的数据在存储介质中是连续存储的；行式存储是指一行中的数据在存储介质中是连续存储的。

### 第一次慢原因
hive第一次在客户端执行sql的时候非常慢，要在各节点建yarn容器，建立过一次之后，在8088yarn页面上能看到一个任务一直在挂起

### idea的hive-jar找不到
api一直报错，找不到驱动，将hive-jdbc拷贝到项目下，还是不行。因为当时配置文件吧把hive地址加上了""导致的问题

### map启动数和表大小对不上

order表中大概390M 按理来说是128一个任务，为什么是2个map任务呢
客户端查看了set mapred.max.split.size  hive里设置是256M 
因为默认是combineInputFormat,  所以只开启2个任务
```



# DataGrip集成工具

### 配置hive连通





# hive历史版本特性

以下是一些 Apache Hive 的重要版本和其引入的主要特性的概述：

1. Hive 0.13.0:
   - 支持使用 ORC 文件格式作为默认存储格式，提供更高的查询性能和压缩比。
   - 引入了 Vectorized Query Execution，通过批量处理数据来提高查询性能。
   - 支持并行查询执行，提高查询性能和资源利用率。
   - 引入了 Cost-Based Optimizer（CBO），通过统计信息来优化查询计划。

2. Hive 0.14.0:
   - 引入了 ACID（原子性、一致性、隔离性、持久性）事务特性，支持行级别的更新和删除操作。
   - 支持使用 ORC 文件格式进行数据压缩和索引，提供更高的查询性能和过滤能力。
   - 引入了 Tez 执行引擎，提供更高效的查询执行和资源管理。

3. Hive 1.0.0:
   - 引入了 LLAP（Live Long and Process）执行引擎，通过长时间运行的进程提供低延迟的交互式查询。
   - 引入了 Hive-on-Spark，提供在 Apache Spark 上执行 Hive 查询的能力。
   - 引入了 HiveServer2，一个独立的服务，提供更高的并发性和连接管理。

4. Hive 2.0.0:
   - 引入了 Hive-on-LLAP，将 LLAP 执行引擎作为 Hive 的默认执行引擎，提供更低的查询延迟和更高的并发性能。
   - 支持 ACID 事务表的快照读取（Snapshot Isolation）。

5. Hive 3.0.0:
   - 引入了 Hive-on-Tez 2.0，提供更好的性能和稳定性。
   - 引入了 Hive Warehouse Connector，提供更好的集成和交互性能。
   - 支持 ACID 事务表的向后兼容性和更好的性能。

这只是一些主要版本的特性摘要，每个版本都有更多的改进和增强功能。如果您需要详细了解每个版本的特性和改进，请参阅 Apache Hive 的官方文档和发布说明。

# hive对比即席查询框架



Impala和Druid都是为了提供快速的即席查询（ad-hoc query）而设计的分布式存储和查询系统。它们之所以适合即席查询，主要是因为它们的架构和查询执行方式与传统的MapReduce模式有所不同。

Impala

Impala是一个开源的大数据查询工具，由Cloudera开发，它直接在Hadoop的存储文件（如HDFS和HBase）上运行SQL查询。Impala是为了克服Hive在即席查询上的性能瓶颈而设计的。它使用了类似于传统关系数据库的MPP（Massive Parallel Processing）架构，可以并行地在多个节点上执行查询，从而大大加快了查询速度。

Impala不使用MapReduce执行模型，而是使用自己的分布式查询引擎，这允许它在不需要启动MapReduce作业的情况下直接处理数据，从而减少了延迟。

Druid

Druid是一个为了实时分析而构建的高性能的分析型数据库。它专门用于事件驱动的数据或时间序列数据的快速聚合查询。Druid的设计重点在于提供快速的查询性能和实时数据摄入，使之非常适合于大规模的即席分析查询。

Druid通过将数据分布存储在一个由多个节点组成的集群中，并且能够在这些节点上并行处理查询，来实现高速查询。Druid还采用了列式存储格式，这样可以高效地进行数据压缩和快速的聚合操作。

Hive on Spark

Hive是一个建立在Hadoop上的数据仓库工具，它最初是使用MapReduce作为其后端执行引擎。随着Spark的出现，Hive可以使用Spark作为计算引擎，而Spark是一个更快的内存计算框架，它比MapReduce有更好的性能，特别是在处理机器学习和迭代算法时。

尽管Hive on Spark的性能有所提升，但是它通常仍然不如专门为即席查询优化的系统如Impala或Druid那样快。Hive的设计更注重于批量处理和兼容性，而不是即席查询的低延迟。

为什么还使用Hive？

尽管Impala和Druid在查询性能上有优势，但Hive仍然被广泛使用，原因包括：

1. **成熟度和稳定性**：Hive是一个非常成熟的项目，拥有大量的用户和社区支持。企业通常倾向于使用成熟的技术。
2. **兼容性**：Hive提供了与SQL标准的良好兼容性，这使得它能够更容易地集成到现有的数据仓库解决方案中。
3. **生态系统**：Hive是Hadoop生态系统的一部分，与其他工具（如Pig、Oozie等）集成良好。
4. **多引擎支持**：Hive可以使用不同的执行引擎（如MapReduce、Tez、Spark），为不同的用例提供灵活性。

总结来说，选择Impala、Druid还是Hive on Spark，取决于具体的使用场景、数据特性、性能需求以及与现有系统的兼容性。在某些情况下，组织可能会同时使用这些工具，以便在不同的场景下优化性能和资源利用。



# hive配置spark引擎



### hive用spark引擎对比presto

```mysql
#分析数据的方式
目前来说hdfs上数据，通常通过hive来管理。查询分析hive数据仓库的方式有hive,sparksql,presto,implala等

#对比impala
Impala和Presto都是为了解决Hadoop生态系统中大数据即席查询（ad-hoc query）的需求而设计的系统比基于Spark引擎的Hive更快：

1. **执行引擎**:
   - **Impala** 使用了自己的大规模并行处理（MPP）引擎，它不依赖于MapReduce模型。Impala是为了分析型查询而设计的，它直接在存储数据的节点上执行SQL查询，减少了数据移动，并且避免了MapReduce的启动延迟。
   - **Presto** 同样是一个MPP系统，它使用了一种更为现代的查询执行引擎，支持内存中的数据流处理，这意味着它可以更快地执行查询，因为它减少了对磁盘的依赖。

2. **查询优化**:
   - **Impala** 和 **Presto** 都有更先进的查询优化器。它们可以生成更有效的执行计划，尤其是对于复杂的查询。这些优化器会考虑数据的分布、列的选择性以及其他因素来生成更为高效的执行策略。

5. **服务模型**:
   - 正如你提到的，Impala和Presto都是长时间运行的守护进程，这意味着它们可以立即响应查询请求，而不需要像Spark那样每次查询都启动一个新的应用程序。这减少了查询的启动时间，使得即席查询的响应更快。

6. **资源管理**:
   - Hive通常依赖YARN进行资源管理，这会增加调度的开销。而Impala和Presto有自己的资源管理器，可以更快地分配资源，尤其是在多用户并发查询的环境中。

```



### hive on spark(需要安装spark)

```mysql
Hive on Spark需要安装Spark的原因是为了在Hive查询执行过程中利用Spark引擎的计算能力和优化功能。尽管可以使用HDFS上指定的Spark相关库包，并通过YARN执行Hive查询，但这种方式只是将Spark作为一个独立的计算框架，与Hive的集成性和优化能力有所不同。以下是一些原因解释为什么要安装Spark来集成Hive：

集成优化：Hive on Spark集成了Hive和Spark两个框架，可以充分利用Spark的计算引擎和优化功能来加速Hive查询的执行。通过将数据加载到Spark的内存中执行计算，可以提高查询性能。

动态资源分配：Spark提供了动态资源分配的功能，可以根据查询的需求自动分配和释放计算资源。这使得在多个查询之间进行资源管理更加灵活和高效。

并行计算：Spark引擎支持并行计算，可以将查询分成多个任务并在集群中的多个节点上并行执行。这种并行计算的能力可以加速查询的执行速度。

内存管理：Spark引擎具有先进的内存管理功能，可以将数据缓存在内存中以提高查询性能。这对于处理大规模数据集特别有用。

扩展性：Spark是一个通用的计算引擎，可以处理各种类型的计算任务，包括批处理、流处理和机器学习等。通过安装Spark，可以将Hive与其他Spark生态系统的组件集成，如Spark Streaming、Spark SQL和MLlib等。

总而言之，通过安装Spark并将其作为Hive的计算引擎，可以获得更高的查询性能、更好的资源管理、更灵活的计算能力和更广泛的生态系统集成。这使得Hive on Spark成为处理大规模数据集和复杂查询的理想选择。
```



### hive3.1.2兼容spark3.0.0

```mysql
#hive3.1.2 和 spark3.0的引擎不兼容
因为hive3版本，里面调用了spark2.4版本的类，有的类在spark3版本被删掉了等

#如何兼容hive3和spark3
1 spark3的纯净版jar包，即不含hadoop和hive，因为spark3里面的hive版本是2.4的，如果不排除也会出现冲突
2 hive修改源码 详情看csdn  :  https://blog.csdn.net/rfdjds/article/details/125389450

大概流程就是，先将hive源码下载，然后更改spark版本是3.0 ，然后编译的时候，看地方报错了，手动将报错的地方更换到3.0版本对应的类和方法。

#纯净包下载，上传hdfs(为了减少每次上传时间)
https://spark.apache.org/downloads.html
开头只有3.5版本，去最下面找到release archeive能找到历史版本
选择spark3.0.0-without-hadoop这版本，

#配置相关文件，和复制jar包到hive的lib下
之前的解压版jar包lib库，已经是他们给配好的了，详细看博客。https://blog.csdn.net/rfdjds/article/details/125389450




```



### 配置流程

~~~sql
要在Hive 3.1.2中集成使用Spark引擎，你需要进行一系列的配置和安装步骤。以下是详细的步骤：

### 1. 确认兼容性

首先确保你的Spark版本与Hive 3.1.2兼容。通常，Apache Hive的发布说明或官方网站会有与特定Hive版本兼容的Spark版本列表。截至我所知的最新信息，你可以考虑使用Spark 2.4.x版本，因为它通常与Hive 3.x版本兼容。

### 2. 下载Spark

你可以从Apache Spark的官方网站下载Spark的“预构建包”：

- 访问[Apache Spark下载页面](https://spark.apache.org/downloads.html)。
- 选择与Hive兼容的Spark版本。
- 选择“预构建包”来下载编译好的版本，通常是针对特定版本的Hadoop预构建的。
- 下载.tar.gz格式的文件。

### 3. 安装Spark

- 将下载的Spark压缩包解压到你的系统上。
- 设置`SPARK_HOME`环境变量，指向你解压Spark的目录。

### 4. 配置Hive以使用Spark

编辑Hive的配置文件`hive-site.xml`，通常位于`$HIVE_HOME/conf`目录下，添加或修改以下属性：

```xml
<property>
    <name>hive.execution.engine</name>
    <value>spark</value>
</property>

<property>
    <name>spark.master</name>
    <value>yarn</value> <!-- 或者 local，取决于你的Spark运行模式 -->
</property>

<property>
    <name>spark.home</name>
    <value>/path/to/spark</value> <!-- 这里填写你的SPARK_HOME路径 -->
</property>
```

如果你使用的是YARN，确保YARN配置正确，并且`yarn-site.xml`中的相关设置已经配置。

### 5. 配置Spark

编辑Spark的配置文件`spark-defaults.conf`，通常位于`$SPARK_HOME/conf`目录下，确保以下属性正确设置：

```conf
spark.master                    yarn
spark.submit.deployMode         client
spark.executor.instances        2
spark.yarn.queue                default
spark.executor.memory           1g
spark.driver.memory             1g
```

这些值取决于你的集群大小和可用资源，你可能需要根据你的实际情况进行调整。

### 6. 配置YARN

如果你在YARN上运行Spark，确保你的`yarn-site.xml`配置了与Spark交互所需的所有参数。

### 7. 测试配置

完成配置后，尝试运行一个简单的Hive查询来测试Spark引擎是否正常工作。你可以使用Hive命令行界面来执行此操作。

### 8. 遇到问题时查看日志

如果遇到问题，查看Hive和Spark的日志文件以获取错误信息。这些日志文件通常位于`$HIVE_HOME/logs`和`$SPARK_HOME/logs`。

### 注意事项

- 确保所有的节点都安装了相同版本的Spark，并且所有的环境变量和路径都正确设置。
- 你可能还需要在Spark上配置Hive的元数据仓库连接，这通常涉及到在Spark的`spark-defaults.conf`中设置`spark.sql.warehouse.dir`和`hive.metastore.uris`等属性。
- 在进行配置更改时，应该在一台机器上测试这些更改，然后再在整个集群上进行部署。

这个过程可能会根据你的具体环境和需求有所不同，所以请根据实际情况进行相应的调整。如果你在配置过程中遇到任何特定的错误或问题，你可以提供错误信息以便获得更具体的帮助。
~~~







# hive on spark调优

### 调yarn参数

```sql
#yarn.nodemanger.resource.memory-mb
这个是nodemanger最多能给container使用的内存，woker服务器节点是128G,给kafka 10-15g,给datanode 5G,还有zk,hbase等。
设置64G就行

#yarn.nodemanager.resource.cpu-vcores
设置nodemanger可使用的虚拟cpu核数。虚拟cpu数意思，你可以比物理核数多，这样会给yarn更多的cpu抢占资源
服务器是32核，那么不应全给nodemanager，你还有其他线程，如果全给yarn,那么导致其他线程被yarn争抢导致其他线程效率低。
设置为16核。一般都是内存和核数是4:1的关系

"cpu-vcores案例"
如果我yarn只设置1cpu可用核数，我同时提交8个yarn任务。
即使你只配置了 1 个虚拟 CPU 核心，YARN 通常也会启动多个 Container。这是因为 YARN 中的 CPU 资源是可以被超额订阅的（over-subscribed），它们都试图在同一时刻运行增强cpu使用


重点配置
#yarn.scheduler.maxumum-allocation-mb /minumum
每个申请container最大是多少,最小是多少，最大是16g,最小是512m
在spark-yarn模式下,driver和excutor是在container运行的，所以container最大的设置，一定要比spark里的driver和container设置最大内存要大

```



### 调spark参数(p7笔记待做)

```sql
#excutor相关
#spark.excutor.cores
一个excutor能用多少个核，决定了一个excutor能同时并行的task数量。建议4-6
一个excutor是一个jvm进程，多个task是共享一个excutor堆内存的。
前面yarn的配置的是单节点16核,那么这里配置为16的整除比较合适,如4。如果设置5，那么只能开启3个excutor还有一个核未使用

#excutor总内存
excutor运行在container里面，每个container对应一个excutor
excutor内存  =  overhead + excution&storage  2部分  
spark.executor.mermoryOverhead 堆外内存 ,jvm的额外开销，操作系统开销。默认比例excutor总内存的o.1
spark.executor.mermory 堆内存，计算和存储的内存  占总的0.9

每个excutor总内存设置为:yarn内占用的总内存/yarn能最大提供的container数，并且要小于yarn的最大container大小。
参数表里没有总内存这项，所以分别设置spark.executor.mermoryOverhead和spark.executor.mermory

#每个应用excutor个数配置

"静态分配"
每个spark应用提交时，手动指定通过spark.excutor.instances 执行excutor数


"动态分配" 
动态分配spark自动分配
spark.dynamicAllocation.schedulerBacklogTimeout  5s 
若有task任务，超过这个时间还未分配，就继续开启新的excutor，当设置为5s,可以理解成只要有task未分配，就开新的excutor

#driver相关 
spark.driver.memory        堆内存 0.9
spark.driver.memoryOverhead  堆外内存 0.1
官网推荐:如果yarn.naodemanager.resource.memor-mb(nodeg给所有container最多内存)这个参数为x,
如果x>50 则 driver为12g
如果12<x<50 则 driver为4g
如果x<12 则 driver为1g

#配置操作
这些配置参数，都是修改hive的conf目录下的,spark-defaults.conf

至于开启spark-shuffle服务，需要到yarn里配置，去开启sparkshuffle。因为不是运行spark集群，spark配置了没用。hive也无法开启这个服务，具体看p9

#shuffle服务
当一个excutor执行完毕后要进行shuffle时,输出的数据统一shuffle服务管理，这样就可以提前关闭excutor了

```



### hql调优

```mysql
先查看表数据规模，再调优。用describe formatted

#group by 开启预聚合(默认是开启的)
select name,count(*) from tb group by name;
开启map端聚合,减少shuffle量
开启预聚合后，执行计划对比
未开启: map[  tbscan->select->reduce output ]
开启后: map[  tbscan->select->group by ->reduce output ]
细节:开启预聚合后，第一个group by的mode是hash，第二个group by的mode是 aggregate trail，和之前的模式不同了

开启流程:   
set hive.map.aggr=true  开启预聚合
set hive.map.aggr.hash.percentmermory =0.5  开启map聚合是要额外费内存的,将聚合结果维护在map任务中的一个hash-table，这个参数是设置hash-table能占多大内存

#join
目前的join算法,common join ,map join ,bucket map join，skew join 

common join 根据关联字段进行分区,发送到reducer，由reducer完成关联

#map join
map join（大表join小表）  若参与join的n个表中,有n-1个表足够小，那么map会把小表全部缓存，然后找出一个最大的表，对最大的表进行扫描关联小表，在map端进行join。
流程就是:将多个小表加载成hash-table，然后序列化后放入hdfs临时文件，然后多个map任务去hdfs拉取这个hash-table,本地执行mapjoin 
map join没有shuffle，所以就变快多了


开启流程:
set hive.auto.convert.join = true;
前面设置单个excutor分的是12G内存,4个核,也就是4个task每个最多能分3g内存，所以1.5g的维度表，可以开启mapjoin
set hive auto.convert.join.noconditional.size = ;

执行的sql是订单表关联订单表
开启前：
	只有一个stage：
				map1执行tableScan->select->reduce output
				map2执行tableScan->select->reduce output
				reducer执行 join ->select ->file output
	

开启map后: 
		stage1: 小表tableScan -> select->spark hashTable sink
		stage2: 大表tablescan->select->map jpon -> select ->file output



#bucket map join (不常用，条件苛刻)
bucket map join(因为map join只能大join小，为了解决这个情况，有这个设计):
条件是2个表都是分桶表，然后关联字段是分桶字段，并且大表分桶数是小表的整数倍，这时就能实现优化.
因为当2个表都大的时候,不能小表加载到内存，当分桶后，小表只加载用到的桶的数据，桶的数据够小的时候，所以就可能完成map join

#skew join 
set hive.optimize.skewjoin =true 开启。
set hive.skewjoin.key = 10000，当某个key数量超过多少，触发。
注意只支持inner join 
具体去看hive优化中，数据倾斜的热点数据处理，思路是那个思路



#数据倾斜

#group by导致的
思路1:开启map预聚合,map端聚合
思路2:group by字段，加随机数+｜,然后按｜切分。执行2次的mr的groupby  
思路3: set hive.groupby.skewindata=true 这个参数，原理和第一种差不多，不过实现方式有区别。第一次按随机数分区，进入reduce进行一部分聚合，然后再按mr聚合一次。和第一种的区别就是第一种更费内存，而这个不吃内存。

第一次group by后,再接一个group by 。如果是mr引擎，第一次的reduce必须落盘，然后第二个map再读取。是2个stage
但是spark中,mr之后，可以直接shuffle到下一个reduce，不用再一个map。是一个stage连续接2个reduce

#join导致的
思路1 mapjoin解决,加载小表。
  这种应该能解决9层，因为数据倾斜的话，关联key一般都是维度key，维度表都很小。如果是2个大表关联，key基本都是散列的,很难出现数据倾	 斜，场景目前想不到。

思路2 skew join (原理p23挺复杂的)
set hive.optimize.skewjoin =true 开启。
set hive.skewjoin.key = 10000，当某个key数量超过多少，触发。
注意只支持inner join 

#并行度优化

#map并行度(一般不用动)
set  hive.input.format= 前缀省略.CombineInput   设置读取方式，默认是combine
set mapreduce.input.fileinputformat.split.maxsize = 25600000   设置合并文件大小

#reduce并行度

set mapreduce.job.reduces = 2  手动指定reduces个数，默认是-1为制定
set hive.exec.reducers.max = 10 这个是限定hive估算任务的最大限制,自己手动指定的不受这个限制
set hive.exec.reducers.bytes.per.reducer = 100*1024*1024 100M 如果未手动指定,hive根据数据量手动估算

hive估算的规则是  totalBytes/per.reducer 来启动reduce数。
而这个totalBytes是hive估算会产生很大误差的原因。hive获取totalBytes是根据执行计划中上一阶段的reduce output数据量来的，
看执行计划时可以看到。当你进行了map join时，这个误差会很大。
另一种场景: 你数据量很大，但是你的groupby的key只有4个。因为数据量大所以导致hive判定启动reduce的个数很多，但是你的key只有4个，导致其他的reduce都收不到数据，都是白启动的。

下面这4个参数，为了加强hive计算reduce个数准确
set hive.stats.autogather =true 当hive执行DML语句时，收集表级别的统计信息，放入表的元数据
set hive.stats.column.autogater =true 执DML时，收集字段之别信息
set spark.use.op.stats =true ; spark计算reduce并行度时，从上游orperator统计信息获取输入数据量
set hive.stats.fetch.colum.stats=true  计算reduce并行度时，根据列信息计算reduce数

#小文件合并优化
map输入端文件合并，默认的就是combine，不用管

reduce输出文件合并
set hive.merge.sparkfiles =true (默认是不开启的)，执行reducer还是多并行度，然后多了一个stage，进行小文件合并。
这个和skewjoin相同，是执行时根据数据量，动态判断是否增加一个合并阶段的，如果有小文件，则才会触发


```



# hive优化

#### 数据倾斜

```mysql
#出现场景
主要是热点问题,某个key占绝大部分数据,导致groupby或者join倾斜。
热点问题，第一个就是空值/默认值，第二个就是热点

#解决方案1 mapjoin
大表join小表
map join,默认有个20m配置,如果集群内存够大可以修改这个参数。

#方案2 热点key打散
1 空值，默认值情景打散，if判断如果key是"",则加随机数,若非空则正常，关联维度表
2 热点key打散,在groupby场景下,给key+｜随机数(1-10)先聚合一次，然后再按｜切分再聚合一次，一般有预聚合用不上
3 热点key打散,在join场景下,给key+｜随机数(1-10),然后维度表去笛卡尔积1-10扩大10倍。这个场景是维度表数量级远小于主表,但是维度表也相对大，不能mapjoin加载到内存



#方案3 热点单独处理
大表join中维度表
1 先从大表 执行group by shopid having count(*)>100000,来找出热点商铺。因为groupby 可以执行map端预聚合，所以shuffle时,数据量小,不会出现group by这里出现热点问题导致速度慢，然后存入临时表。

2 用大表 join 热点商户表,过滤出热点商户数据,因为热点商户表数据很小，这里是mapjoin没有大批量shuffle。
然后中维度表关联热点表,过滤出热点商户维度，再关联上面过滤的，中维度表过滤后，也是小表是map join 没有shuffle

3 总结为什么会快
步骤1执行后的数据,步骤2执行后的数据都是临时mr数据，因为都是mapjoin，所以reduce结果都在本节点落盘。
当在join时，把维度表作为mapjoin，这样热点数据是多服务器计算，不是单服务器，并且没有跨节点的shuffle落盘，只有本地落盘

4 再union all非热点数据，和流程2一样，区别就是非热点的商户是个大表，不能mapjoin。这里就是热点的mapjoin+非热点的shuffle

```

#### 拉链表设计模式

追踪数据每日变化的历史记录,感觉没必要,因为周期是一天，并不能精准到每次的变化，只能定位到天的变化

#### parquet格式

采用orc和parquet格式，第一个列存，最重要的是虽然是snappy压缩，但可切分，多并行度。

如果你用textfile，并且执行压缩,并且是snappy压缩，只有一个任务。

具体看:问题已解决中的压缩文件的mr并行度

#### map join

map join主要是在关联的时候使用，hive开启map join后可以将关联的小表放入[内存](https://so.csdn.net/so/search?q=内存&spm=1001.2101.3001.7020)中去执行，以此来提高脚本的运行速度

开启map join

set hive.auto.convert.join=true;

设置map join 启动时表的大小最大为1M
set hive.mapjoin.smalltable.filesize=1048576;



map join的一点小坑

map join虽然很好，但是会有如下问题：

1）map join关联多个小表时，都放入内存，则考虑内存大小需要针对上述小表大小进行累加

2）大表B表map join关联分区小表A表（200M）时，即使限制了A的分区（取10M），但依旧放入内存的大小依旧是A表的原先大小（200M）

#### 先过滤再关联

对于一些join的操作 先过滤再去关联，不要先关联再过滤，每个join都是开启一次mr，先过滤减少传输数据



#### 开启map端聚合

对于一些聚合函数比如 sum(),count() 这种，是可以提前在map端预聚合的。

比如按性别group by ，那么最后最多只有2个reduce任务，有10个map任务，在map端先聚合的话，会提升很多速度，而且传递的数据也少了很多。



并不是所有情况都是开启map聚合就是好

比如按用户id 去统计订单数，因为用户id少会出现多条重复订单，如果这时候开启map聚合，在map端聚合一次之后，数据量基本无变化，然后传递到reduce端，还要再聚合一次，反而更慢了，所以对于这种情况反而要关闭map聚合，用参数设置自动开关



开启map端口预聚合
set hive.map.aggr = true

map端会预先聚合10000条数据
set hive.groupby.mapaggr.checkinterval = 10000

map端试聚合10000得到的数量与10000的比值，如果比值<0.3 则有继续聚合，如果大于0.3没有预聚合的意义，会关闭预聚合

Hive.map.aggr.hash.min.reduction=0.3



#### 合理设置map,reduce数量

是不是map数越多越好？

答案是否定的。如果一个任务有很多小文件（远远小于块大小128m），则每个小文件也会被当做一个块，用一个map任务来完成，而一个map任务启动和初始化的时间远远大于逻辑处理的时间，就会造成很大的资源浪费。而且，同时可执行的map数是受限的。

是不是保证每个map处理接近128m的文件块，就高枕无忧了？

答案也是不一定。比如有一个127m的文件，正常会用一个map去完成，但这个文件只有一个或者两个小字段，却有几千万的记录，如果map处理的逻辑比较复杂，用一个map任务去做，肯定也比较耗时。

#### 合并小文件

（1）在map执行前合并小文件，减少map数：CombineHiveInputFormat具有对小文件进行合并的功能（系统默认的格式）。HiveInputFormat没有对小文件合并功能。

set hive.input.format= org.apache.hadoop.hive.ql.io.CombineHiveInputFormat;

（2）在Map-Reduce的任务结束时合并小文件的设置：

在map-only任务结束时合并小文件，默认true

SET hive.merge.mapfiles = true;

在map-reduce任务结束时合并小文件，默认false

SET hive.merge.mapredfiles = true;

合并文件的大小，默认256M

SET hive.merge.size.per.task = 268435456;

当输出文件的平均大小小于该值时，启动一个独立的map-reduce任务进行文件merge

SET hive.merge.smallfiles.avgsize = 16777216;





#### 合理设置reduce个数

调整reduce个数方法一

（1）每个Reduce处理的数据量默认是256MB

hive.exec.reducers.bytes.per.reducer=256000000

（2）每个任务最大的reduce数，默认为1009

hive.exec.reducers.max=1009

（3）计算reducer数的公式

N=min(参数2，总输入数据量/参数1)

2．调整reduce个数方法二

在hadoop的mapred-default.xml文件中修改

设置每个job的Reduce个数

set mapreduce.job.reduces = 15;

3．reduce个数并不是越多越好

1）过多的启动和初始化reduce也会消耗时间和资源；

2）另外，有多少个reduce，就会有多少个输出文件，如果生成了很多个小文件，那么如果这些小文件作为下一个任务的输入，则也会出现小文件过多的问题；

在设置reduce个数的时候也需要考虑这两个原则：处理大数据量利用合适的reduce数；使单个reduce任务处理数据量大小要合适；

#### jvm重用

JVM重用是Hadoop调优参数的内容，其对Hive的性能具有非常大的影响，特别是对于很难避免小文件的场景或task特别多的场景，这类场景大多数执行时间都很短。

Hadoop的默认配置通常是使用派生JVM来执行map和Reduce任务的。这时JVM的启动过程可能会造成相当大的开销，尤其是执行的job包含有成百上千task任务的情况。JVM重用可以使得JVM实例在同一个job中重新使用N次。N的值可以在Hadoop的mapred-site.xml文件中进行配置。通常在10-20之间，具体多少需要根据具体业务场景测试得出。

这个功能的缺点是，开启JVM重用将一直占用使用到的task插槽，以便进行重用，直到任务完成后才能释放。如果某个“不平衡的”job中有某几个reduce task执行的时间要比其他Reduce task消耗的时间多的多的话，那么保留的插槽就会一直空闲着却无法被其他的job使用，直到所有的task都结束了才会释放。

# gpt推荐的优化(待合并)

Hive查询的手动优化通常涉及对查询本身、数据模型和Hive配置的深入理解。这里有一些高级的优化技巧，这些技巧超出了Hive优化器（如CBO，代价基优化器）的自动优化范围：

1. **分区和分桶**:
   分区可以帮助Hive查询只扫描包含相关数据的子集，而分桶可以提供更细粒度的数据组织方式。正确使用分区和分桶可以显著提高查询性能。

2. **合并小文件**:
   如果数据由许多小文件组成，可能会导致大量的HDFS读取开销。可以使用`ALTER TABLE CONCATENATE`命令或者设置`hive.merge.mapfiles`和`hive.merge.mapredfiles`为`true`来合并这些小文件。

3. **物化视图**:
   物化视图存储查询结果，当对相同的数据执行多次查询时，可以直接从物化视图获取结果，而不是重新计算。在Hive中，可以创建物化视图来优化经常执行的复杂查询。

4. **选择合适的文件格式**:
   根据查询的性质，选择合适的文件格式（如Parquet, ORC等）可以提高性能。列式存储格式特别适合于执行大量的聚合操作。

5. **使用Hive变量**:
   可以使用Hive变量来动态调整查询，这样就可以重用查询模板，避免为不同的查询场景编写多个查询语句。

6. **调整JOIN策略**:
   Hive支持几种不同的JOIN策略，如MapJoin, SMBJoin等。在某些情况下，手动指定JOIN策略可以提高查询效率。

7. **使用合适的压缩**:
   启用压缩可以减少存储空间的使用，同时也可以减少网络传输的数据量。但是，需要根据数据的读写模式选择合适的压缩算法。

8. **调整Hive配置参数**:
   根据具体的查询和数据特征，调整Hive的配置参数，如`hive.exec.reducers.bytes.per.reducer`、`hive.exec.reducers.max`等，可以优化执行计划。

9. **使用窗口函数**:
   对于某些类型的分析，使用窗口函数而不是自连接可以大幅提高性能。

10. **减少数据倾斜**:
    数据倾斜可能会导致某些节点处理的数据量远大于其他节点。可以使用`distribute by`语句来手动控制数据的分布，减少数据倾斜的问题。

11. **向量化查询执行**:
    启用向量化查询执行可以大幅提高性能，因为它使用批处理来处理数据，减少了CPU的使用。

12. **预先计算和聚合**:
    对于一些重复的计算，可以预先计算并存储结果，以便查询时直接使用。

13. **避免笛卡尔积**:
    如果不是必须的，应该避免在查询中使用笛卡尔积，因为它会产生大量的数据组合，严重影响查询性能。

14. **分析和收集表统计信息**:
    使用`ANALYZE TABLE`命令来收集表的统计信息，这些信息可以帮助Hive优化器生成更优的执行计划。

手动优化Hive查询是一个复杂的过程，需要根据具体的数据特点和查询需求来进行。以上提到的一些技巧可以作为高级优化的起点。在实际操作中，可能还需要结合具体的业务逻辑和数据特性进行细致的调整。

# hive执行计划优化器

#### join顺序优化

#### map join优化

#### select 字段优化

```mysql
#执行sql
select 
t1.name,
t2.name
from t1  join t2  
on t1.id =t2.id

#执行计划解析
当你执行上面的sql时，不需要从一个子查询t1过滤出需要字段，然后再join 子查询t2过滤需要字段，这样可能还会降低性能，具体看执行计划
hive优化器，再执行任务时，会自动select 需要字段和关联字段，进行shuffle发送。

不过如果你再套一个子查询例如:
select 
name,
id
from(
  select 
  *
  from t1  join t2  
  on t1.id =t2.id
)as tmp

这个子查询是否会优化到最上层的select，那么不确定，需要看执行计划


```



#### where 条件优化



# hive客户端

### hive配置文件

```mysql
#hive仓库的目录,创建的database在这里,自带的default库建表也在这里,所以默认的default库别用，会很乱
    <property>
        <name>hive.metastore.warehouse.dir</name>
        <value>/hive</value>
    </property>
```




### hiveserver2

hiveserver2是hive的链接服务器，要先启动这个，才能远程连接hive

### metastore服务

客户端连接metastore服务，metastore再去连接MySQL数据库来存取元数据。有了metastore服务，就可以有多个客户端同时连接，而且这些客户端不需要知道MySQL数据库的用户名和密码，只需要连接metastore 服务即可。

### 在线链接hive服务器

beeline -u jdbc:hive2://project1:10000 -n lpc

### 执行hql方式

```sql
#执行多条sql,避免多次创建连接
hive -f hive.sql
#执行1条sql
hive -e "hql"
#查询输出到本地文件
hive -e "sql" > /home/a.txt  --把查询的sql 导入本地文件
#通过jdcb连接服务，执行hql
先开启hivesever2服务端，然后通过JDBC方式连接远程提交HQL。
```

### hive表数据导入

```
1.从hdfs或本地目录 中导入数据到hive
  load data [local] inpath  '/opt/a.txt'  [overwrite] into table t1 [partition (month=202012)]
  注意load数据之后,hdfs上的数据就没有了，如果想原文件继续存在，那么创建的表必须是外部表。
  本地文件导入之后，本地文件还存在

	提示当原数据是txt文本格式，用load 导入到设置为parquet的表中，报错不能将数据转为parquet
  
  

2.查询语句导入数据 insertoverwrite table t1 select * from t2;
3.创建表时，直接location指定hdfs目录位置，目录下的数据直接就在表中
```

### hive表数据导出

```
1. insert overwrite local directory "/home/tb" select * from t1 ;   将查询结果导入本地
2. insert overwrite local directory  row format delimited fields terminated '\t' "/home/tb" select * from t1 ;   
将查询结果导入本地,按照指定分割格式
如果想导出到hdfs上，那么把local去掉；

3.不在hive客户端执行，在hive脚本中执行   hive -e 'select * from t1' > /home/data
4.sqoop 把hive导入到mysql里面

```

### 查看锁表

```
hive> show locks;
```

# ——————hive语法———————

# hive深入细节

### overwrite/into

```sql
#insert into 多并行度,会出现污染
 INSERT INTO 操作，并且有多个 MapReduce 任务并行运行时，每个任务通常会处理表中的一部分数据。
如果在这种并行执行的情况下，一个任务因为某些原因失败了，其他任务成功了，因为每个任务独立写入自己的数据文件，会导致部分数据成功，数据被污染。

#数据污染解决思路
使用ACID表,并且开启hive的事务，hive的metastore服务器运行正常
执行hql前，使用事务模式
START TRANSACTION;
INSERT INTO tb2 SELECT * FROM tb5;
COMMIT;

#insert overwrite
执行overwirte时，Hive通过写时复制（write-ahead logging）和事务的概念来保证操作的原子性和一致性。在执行INSERT OVERWRITE操作的过程中，如果遇到错误或失败，Hive通常会尝试回滚这个操作，以保证表数据的一致性不被破坏。Hive会将新数据写入到临时目录，只有当整个写操作成功完成后，才会将这些数据移动到目标表的目录中。如果在这个过程中出现错误，操作应该会被回滚，临时目录中的数据将不会被移动到目标表目录，从而避免了数据的污染。
```

### 调度系统

```sql
在 Unix-like 系统中，一个命令执行完成后都会返回一个退出状态码。通常，如果命令成功执行，会返回 `0`；如果执行过程中发生错误，会返回非零值。
#bash脚本
hive -e "SELECT * FROM your_table"
#记录上一行脚本返回结果
exit_status=$?
if [ $exit_status -eq 0 ]; then
  echo "HQL Query executed successfully"
else
  echo "HQL Query failed with exit status $exit_status"
fi

hive -e "SELECT * FROM your_table" > output.txt 2> error.log
这样，标准输出会被写入 `output.txt`，而标准错误会被写入 `error.log`，你可以更容易地查看和排查问题。
```

### distinct效率低

```sql
#为什么distinct效率低
group by是分组函数，也可以用来去重。
hive引擎解析group by时，会执行优化，会在map端预聚，减少传输到reduce的数据量。
而hive执行distinct时，不会进行map预聚合。在DISTINCT操作中，所有的输出都需要在Reduce阶段进行去重，这意味着即使有重复的记录也需要被传输到Reducer，然后由Reducer去除重复，这可能会导致更多的网络传输和数据处理。

#预聚合的实现
预聚合是通过使用Combiner来实现的，Combiner是一种优化机制，它在Map阶段的输出结果上执行Reduce阶段的相同操作，以减少需要传输的数据量。
```



# 数据类型对比mysql

mysql类型	hive类型	java类型

tinyint		tinyint		byte

smallint	smallint	  short

int			  int				int

bigint		bigint			long

float		  float			  float

double	  double		 double

decimal	decimal		bigdecimal

char			string		string

varchar	  string		string

text			string		string

boolean    boolean    boolean

datetime	timestamp      timestamp(java.sql包里的)

timestamp timestamp

date			date



hive也有char和varchar，不过还是推荐string，方便毕竟和mysql不同，没必要限制字段长度

mysql的datetime和timestamp类型都是yyyy-mm-dd hh-mm-ss格式，不过timestamp精确到毫秒[.f...]

date 格式只有yyyy-mm-dd

hive只有一个timestamp，必须满足格式，不然hive识别就是null



# 语法注意事项

#### 制表符报错  

 在hive 客户端 不要用\t 制表符，会报错

####  存储格式转换

hive表表中load数据是直接把块记录更改，不会更改数据。如果原数据是text，表为paruqet那么识别不了

可以通过从text格式的表，insert到parqet的表，这种会更改数据格式



# DDL语法

#### 库表操作

```mysql
#创建数据库  
创建一个新库，默认存储路径是   /hive/.db 可以指定位置
使用defult库，默认建表路径是/hive，因此会比较混乱

#查看建表语句
show create table tb1;

#库相关
show databases； 查看所有库
use databases;  使用库
drop database db_hive  ;删除数据库,空数据库
drop database db_hive cascade;非空数据库加上cascade
desc  database  db1 查看库信息
desc database extended db1 查看库详细信息
#表相关
desc  tb1  查询表信息
desc  formatted  tb1 查询表详细信息
desc formatted  tb1 partition(dt="2020-06-01") 查看表某分区信息

#desc  formatted tb
可以查看hive表当前很多信息
numFiles 表目前有多少个文件
numrows  有多少行数据
totalSize  所有文件总和的大小
rowDataSize 当你文件采用压缩，解压后数据总占用空间
```





#### 建库语句

```
CREATE DATABASE [IF NOT EXISTS] database_name
[COMMENT database_comment]
[LOCATION hdfs_path]   --指定hdfs存储路径
[WITH DBPROPERTIES (property_name=property_value, ...)];
```

#### 外部表(对接hbase)

hive创建外部表external，根本用处，不是为了删除时不删表。

而是对接其他在hdfs处理的数据库或者文件系统，能直接形成映射，这样删表时，不会删其他数据库的表，比如hbase

**对接hbase原理**



```sql
#生成执行计划：
Hive会生成一个执行计划，这个计划通常是一个MapReduce作业。在这个执行计划中，Hive会包含读取HBase数据的必要步骤。
#读取HBase数据：
在执行阶段，Hive的MapReduce作业会启动，并且会使用HBase的API来读取数据。如果你的查询包含过滤操作，Hive会尝试推送这些过滤到HBase层，以减少需要传输到Hive的数据量。
#Map阶段：
在Map阶段，Hive会使用TableInputFormat（或者相似的InputFormat）来读取HBase中的数据。这个InputFormat负责将HBase的数据转换为Hive能够理解的格式。如果有可能的话，过滤操作会在这个阶段应用到HBase的扫描上，这样就不会读取所有的数据，而是只读取符合条件的行。
读取HBase数据：Map任务使用HBase的API来读取数据。Hive会尝试将查询中的过滤操作（some_column = 'some_value'）推送到HBase。
#map数量
对于Map任务的数量，Hive有一些机制来决定它们的数量：
Splitting：Hive会基于InputFormat定义的split机制来决定Map任务的数量。对于HBase来说，一个split通常对应于一个region或者一部分region。如果表很大，并且分布在多个region中，那么Hive可能会启动多个Map任务来并行处理这些数据。
数据分割：如果HBase表B跨越多个region，Hive可能会为每个region或region的一部分启动一个Map任务。这取决于HBase的InputFormat如何定义split。
```



#### 建表语句

```
Hive上创建测试表test
create [external]  table test(
name string comment "aa",
friends array<string>,
children map<string, int>,
address struct<street:string, city:string>
)

partitioned by (a1,a2)  创建分区表
clustered by (a3,a4 )   创建分桶表
row format delimited fields terminated by ','  -- 列分隔符
collection items terminated by '_'    --MAP STRUCT 和 ARRAY 的分隔符(数据分割符号)
map keys terminated by ':'  	-- MAP中的key与value的分隔符
lines terminated by '\n';    	-- 行分隔符

stored as textfile  --存储格式
location '/home/hadoop/hive/warehouse/student' 表数据存储位置


字段解释：
external 为外部表，当删除表时，数据还在，元数据删除
row format delimited fields terminated by ','  -- 列分隔符
collection items terminated by '_'  	--MAP STRUCT 和 ARRAY 的分隔符(数据分割符号)
map keys terminated by ':'				-- MAP中的key与value的分隔符
lines terminated by '\n';					-- 行分隔符
```



#### stored储存方式

```sql
#存储格式 
textFile、SequenceFile、RCfile、ORCFile，parquet  
#压缩方式
TBLPROPERTIES ( 
  'hive.exec.compress.output'='true', 
  'io.compression.codecs'='com.hadoop.compression.lzo.LzopCodec' 
);

#完整写法
STORED AS parquet
LOCATION '/warehouse/gmall/dwd/dwd_comment_info/'
TBLPROPERTIES ( 
  'hive.exec.compress.output'='true', 
  'io.compression.codecs'='com.hadoop.compression.lzo.LzopCodec' 
);

textFile：
        默认的文件格式，行存储
        优点：最简单的数据格式，便于和其它工具（pig，grep，awk）共享数据，便于查看和编辑；加载快；
        缺点：存储空间占用较大，I/O性能低；不可对数据进行切割、合并，不能进行并行操作；
        适用于小型查询，测试操作等。


ORCFile：当初为hive设计的，于paruqet都是列存，都采用了默认的压缩和编码技术，减少存储空间和读取效率。
				orc默认采用zlib压缩

Parquet：于orc都是列存，都采用了默认的压缩和编码技术，减少存储空间和读取效率。默认是snappy压缩
        优点：更高效的压缩和编码；不与任何数据处理技术绑定，可用于多种数据处理框架。
        缺点：不支持update，insert，delete，ACID
        适用于字段非常多，无更新，只读取部分列数据。


```

#### input/output/压缩格式

```sql
#之前一直错误理解了
inputformat是读取格式
outputformat是输出格式,也是存在hdfs上的格式

#input和output是配套的，并且兼容的
input 为lzo
output 为text
含义就是读取本表数据用lzo解析，存本表数据用text，是不是很奇怪。input必须是能兼容的。
也就是当本地的表用text去存时，当lzo去解析，是可以解析input的

INPUTFORMAT 'com.hadoop.mapred.DeprecatedLzoTextInputFormat'
OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'

#文档的建表语句一直理解错误了
当时sqoop导mysql数据时,采用了lzo的压缩方式, ODS层load之后还是lzo格式,
所以input格式为lzo,因为ods层表只做load，不做插入处理。所以output为text无影响

#采用lzo压缩
从ods查询数据写入dwd，如果想采用压缩lzo格式，要设置tblproperties,不写input和output默认都是lzo
TBLPROPERTIES ( 'hive.exec.compress.output'='true', 'io.compression.codecs'='com.hadoop.compression.lzo.LzopCodec' );
```





#### ACID事务表

由于 HDFS 是一个写一次读多次的文件系统，Hive 最初并不支持行级别的更新和删除操作。然而，随着 Hive 的发展，一些新特性和工具被引入，以提供对表数据的更新和删除操作支持。

在实现行级别的更新和删除操作时，Hive 会采用一种称为 "多版本并发控制" (MVCC) 的技术，以及 "基于写入的日志" (delta files) 来记录对表的更改。当执行更新或删除操作时，Hive 不会直接修改原始数据文件，而是将更改写入到 delta 文件中。在读取时，Hive 会合并原始数据和 delta 文件中的更改，以呈现最新的数据视图。

从 Hive 0.14.0 开始，通过引入 ACID（原子性、一致性、隔离性、持久性）事务特性，Hive 支持了行级别的更新和删除。要在 Hive 中启用和使用 ACID 功能，需要满足以下条件：

1. 使用的是支持事务的文件格式，如 ORC。
2. 开启事务支持，设置 `hive.support.concurrency` 为 `true`。
3. 使用适当的事务管理器，通常是 `org.apache.hadoop.hive.ql.lockmgr.DbTxnManager`。
4. 为了实现事务，Hive 表必须是事务表。可以在创建表时使用 `TBLPROPERTIES ("transactional"="true")` 来指定。



**创建acid表的流程**

在 Hive 的配置文件中启用 ACID 支持。hive-site.xml，然后添加以下配置：

```xml
<property>
  <name>hive.support.concurrency</name>
  <value>true</value>
</property>
<property>
  <name>hive.enforce.bucketing</name>
  <value>true</value>
</property>
<property>
  <name>hive.exec.dynamic.partition.mode</name>
  <value>nonstrict</value>
</property>
<property>
  <name>hive.txn.manager</name>
  <value>org.apache.hadoop.hive.ql.lockmgr.DbTxnManager</value>
</property>
<property>
  <name>hive.compactor.initiator.on</name>
  <value>true</value>
</property>
<property>
  <name>hive.compactor.worker.threads</name>
  <value>1</value>
</property>
```

上述配置中的关键属性包括：

- `hive.support.concurrency`：启用并发操作支持。
- `hive.enforce.bucketing`：强制要求表进行分桶。
- `hive.exec.dynamic.partition.mode`：设置动态分区模式为非严格模式。
- `hive.txn.manager`：设置事务管理器为 `org.apache.hadoop.hive.ql.lockmgr.DbTxnManager`

**建表必须分桶，目前只支持orc格式的acid**

```sql
CREATE TABLE acid_table (
    id String,
    name STRING
)
partitioned by (dt date)
CLUSTERED BY (id) INTO 4 BUCKETS
STORED AS orc
TBLPROPERTIES ('transactional'='true');

--一旦创建了事务表，就可以执行标准的 SQL 更新和删除操作了：
-- 更新操作
UPDATE students SET age = 20 WHERE id = 1;
-- 删除操作
DELETE FROM students WHERE id = 1;
```

这种方法类似于您提到的 HBase 的标记删除机制，其中多个相同的 rowkey 数据只会取时间最新的一条记录。在 Hive 中，这通过合并原始数据文件和 delta 文件中的变更来实现，确保读取操作总是返回最新的数据状态。

对于您提出的想法，加入一个新字段来标记是否做过修改，这通常不是必要的。因为 Hive 的 ACID 特性已经提供了这种行级别的更新和删除能力。如果您确实需要跟踪修改，可以在表中添加额外的字段来记录行的版本或最后修改时间，但这通常是为了特定的业务逻辑或数据审计目的，而不是为了实现基本的更新和删除功能。



#### 建表优化

分区分桶

行存列存方式：如果一个表select * 比较多那么就用行存，比如商品表。 如果是只取某个字段，并且grouoby count多，就用列存。

列存压缩比例高

是否进行压缩



#### 分区表

```
create table tb(
name  string,
age   int comment "年龄"
)
partitioned by (year int,month int) 
rowfomat delimited fields terminated by '\t';
先按year分区，再按month分区
```

#### 分桶表

```
create table if not exists tb(
	userid   string,
	orderno string,
	name string
)
clustered by (userid,orderno) into 4 buckets
row format delimited fields terminated by '\t'
;
哪些表需要分桶：
因为分桶表必须执行过一次mr，所以从mysql直接导过来的表，要处理一次才行。所以应该是经常使用的表，才会去分桶，比如订单信息聚合清洗之后，这种表分桶。

分桶的字段选择：
选择那些经常关联的字段

分桶表的优势：
获得更高的查询处理效率。桶为表加上了额外的结构，Hive 在处理有些查询时能利用这个结构。具体而言，连接两个在(包含连接列的)相同列上划分了桶的表，可以使用 Map 端连接 (Map-side join)高效的实现。比如JOIN操作。对于JOIN操作两个表有一个相同的列，如果对这两个表都进行了桶操作。那么将保存相同列值的桶进行JOIN操作就可以，可以大大较少JOIN的数据量
要想join能用到桶，那么必须桶的数量相同吧（猜测）

分桶数量
因为有多少个桶，必须有多少个reduce，所以你集群能同时运行多少个reduce就多少桶。
而且要想join能用到桶，那么桶的数量必须相同（猜测）
```



# DML

### hive参数配置

```sql
在hive客户端中也可以手动设置mr配置
#//查看执行引擎
set hive.execution.engine
#切换hive执行引擎，如果想临时切换，写在sql前面
set hive.execution.engine=mr/spark/tez ；
#设置队列
set mapreduce.job.queuename=queue1;
#设置reduce数量
set mapreduce.job.reduces = num; 
#设置reduce任务数
set mapreduce.reduce.tasks = num;  
#分块规则,启动map任务，hive上查看了下是256M
set mapred.max.split.size;
#开启hive最终输出数据压缩功能
set hive.exec.compress.output=true;
#开启mapreduce最终输出数据压缩
set mapreduce.output.fileoutputformat.compress=true;
#设置mapreduce最终数据输出压缩方式
set mapreduce.output.fileoutputformat.compress.codec = org.apache.hadoop.io.compress.SnappyCodec;
#开启map join
set hive.auto.convert.join=true;
#设置map join 启动时表的大小最大为1M
set hive.mapjoin.smalltable.filesize=1048576;
#开启map端口预聚合
set hive.map.aggr = true
#map端会预先聚合10000条数据
set hive.groupby.mapaggr.checkinterval = 10000
#map端试聚合10000得到的数量与10000的比值，如果比值<0.3 则有继续聚合，如果大于0.3没有预聚合的意义
Hive.map.aggr.hash.min.reduction=0.3
#打开任务并行执行
set hive.exec.parallel=true; 
#一个sql允许最大并行度，默认为8。
set hive.exec.parallel.thread.number=16; 
```

### hive对接spark参数设置

```sql
对于设置Spark任务的并行度，你可以使用以下参数：

spark.sql.shuffle.partitions: 这个参数可以设置Spark任务的reduce并行度，即shuffle操作的并行度。你可以将它设置为你想要的并行度值，比如设置为10。

spark.default.parallelism: 这个参数可以设置Spark任务的map并行度，默认情况下，它的值为集群的总核数。你可以将它设置为你想要的并行度值，比如设置为10。

spark.executor.memory: 设置每个Spark执行器的内存大小。可以通过指定值来控制Spark执行器可用的内存量，例如2g表示2GB。

spark.executor.cores: 设置每个Spark执行器可用的CPU核心数。可以通过指定值来控制Spark执行器可使用的CPU核心数量，例如4表示4个核心。

spark.executor.instances: 设置Spark执行器的实例数量。可以通过指定值来控制启动的Spark执行器实例数量，例如10表示启动10个执行器实例。

spark.sql.shuffle.partitions: 设置Spark任务的reduce并行度，即shuffle操作的并行度。通过指定值来控制reduce任务的数量，例如200表示使用200个reduce任务。

spark.default.parallelism: 设置Spark任务的map并行度，默认情况下，它的值为集群的总核数。通过指定值来控制map任务的数量，例如100表示使用100个map任务。

spark.sql.autoBroadcastJoinThreshold: 设置自动广播连接的阈值。当一个表的大小小于或等于该阈值时，Spark会自动将其广播到其他节点上，以减少数据传输开销。可以通过指定值来控制广播连接的阈值，例如10m表示10MB。

spark.sql.files.maxPartitionBytes: 设置每个文件分区的最大字节数。可以通过指定值来控制每个文件分区的大小，例如128m表示每个文件分区最大为128MB。

spark.driver.memory: 设置Spark驱动程序的内存大小。可以通过指定值来控制Spark驱动程序可用的内存量，例如2g表示2GB。

spark.driver.cores: 设置Spark驱动程序可用的CPU核心数。可以通过指定值来控制Spark驱动程序可使用的CPU核心数量，例如2表示2个核心。

spark.sql.broadcastTimeout: 设置广播超时时间。当Spark广播一个大的数据集时，可以通过指定值来控制广播的超时时间，例如300s表示300秒。

spark.sql.shuffle.partitioner: 设置shuffle操作的分区器。可以通过指定值来选择不同的分区器，例如hash表示使用哈希分区器，range表示使用范围分区器。

spark.sql.adaptive.enabled: 启用自适应执行。通过设置为true来启用Spark的自适应执行特性，该特性可以根据运行时的数据和资源情况自动调整执行计划。

spark.sql.optimizer.maxIterations: 设置优化器的最大迭代次数。可以通过指定值来控制优化器的最大迭代次数，例如100表示最大迭代100次。

spark.sql.statistics.histogram.enabled: 启用直方图统计信息。通过设置为true来启用Spark的直方图统计信息，该特性可以提供更准确的查询优化。

```



### hive解析逻辑

```sql
#1 hive对关联字段会默认加上非null过滤 
#2 hive中会对sql进行一些优化，比如先关联再where过滤，底层会先过滤再关联
#3 会对on里的非关联条件提前过滤比如on b.id>1  
有时候为了偷懒，只写个join b on b.id>5 这种sql，来过滤b表
#4 预聚合，比如执行group by count(*) 时，先map聚合再传给reduce，减少shuffle数据量，在案例2的执行计划中能看到
#  执行了2次group by 

#注意left join和join可能不太一样
执行rank()函数 会单独调用一个stage
```



### explain执行计划

explain sql  查看执行计划

explain extended sql 查看详细计划（一般不用，太细致了）

select 一条语句，相同的语句执行insert into table 两个执行计划不一样的，insert会复杂很多

```sql
explain
select 
tmp.id,
collect_set(info.info) as infos
from tmp 
join tmp_info as info 
on (tmp.id =info.id or tmp.superid=info.id )
where tmp.id >1 
group by tmp.id 
;
之前执行了一个执行计划2表关联条件是or，
然后好像是2个表执行笛卡尔积然后再进行过滤or的2个条件
```

join 后的where过滤t1.a>1,会优化在表t1表先过滤

on里面t1.a>1 需要再自己试试看



### explain执行案例解析

##### 案例1

sql : select * from tmp  where id in (select id from tmp_copy) as t2;

```
解读下面这段hQL的执行计划

| STAGE DEPENDENCIES:                                |
|   Stage-4 is a root stage                          |
|   Stage-3 depends on stages: Stage-4               |
|   Stage-0 depends on stages: Stage-3               |
|                                                    |
| STAGE PLANS:                                       |
|   Stage: Stage-4                                   |
|     Map Reduce Local Work                          |
|       Alias -> Map Local Tables:                   |
|         $hdt$_1:tmp_copy                           |
|           Fetch Operator                           |
|             limit: -1                              |
|       Alias -> Map Local Operator Tree:            |
|         $hdt$_1:tmp_copy                           |
|           TableScan                                |
|             alias: tmp_copy                        |
|             Statistics: Num rows: 11 Data size: 140 Basic stats: COMPLETE Column stats: NONE |
|             Filter Operator                        |
|               predicate: id is not null (type: boolean) |
|               Statistics: Num rows: 11 Data size: 140 Basic stats: COMPLETE Column stats: NONE |
|               Select Operator                      |
|                 expressions: id (type: int)        |
|                 outputColumnNames: _col0           |
|                 Statistics: Num rows: 11 Data size: 140 Basic stats: COMPLETE Column stats: NONE |
|                 Group By Operator                  |
|                   keys: _col0 (type: int)          |
|                   mode: hash                       |
|                   outputColumnNames: _col0         |
|                   Statistics: Num rows: 11 Data size: 140 Basic stats: COMPLETE Column stats: NONE |
|                   HashTable Sink Operator          |
|                     keys:                          |
|                       0 _col0 (type: int)          |
|                       1 _col0 (type: int)          


|   Stage: Stage-3                                   |
|     Map Reduce                                     |
|       Map Operator Tree:                           |
|           TableScan                                |
|             alias: tmp                             |
|             Statistics: Num rows: 12 Data size: 145 Basic stats: COMPLETE Column stats: NONE |
|             Filter Operator                        |
|               predicate: id is not null (type: boolean) |
|               Statistics: Num rows: 12 Data size: 145 Basic stats: COMPLETE Column stats: NONE |
|               Select Operator                      |
|                 expressions: id (type: int), name (type: string), superid (type: int) |
|                 outputColumnNames: _col0, _col1, _col2 |
|                 Statistics: Num rows: 12 Data size: 145 Basic stats: COMPLETE Column stats: NONE |
|                 Map Join Operator                  |
|                   condition map:                   |
|                        Left Semi Join 0 to 1       |
|                   keys:                            |
|                     0 _col0 (type: int)            |
|                     1 _col0 (type: int)            |
|                   outputColumnNames: _col0, _col1, _col2 |
|                   Statistics: Num rows: 13 Data size: 159 Basic stats: COMPLETE Column stats: NONE |
|                   File Output Operator             |
|                     compressed: false              |
|                     Statistics: Num rows: 13 Data size: 159 Basic stats: COMPLETE Column stats: NONE |
|                     table:                         |
|                         input format: org.apache.hadoop.mapred.SequenceFileInputFormat |
|                         output format: org.apache.hadoop.hive.ql.io.HiveSequenceFileOutputFormat |
|                         serde: org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe |
|       Execution mode: vectorized                   |
|       Local Work:                                  |
|    
|   Stage: Stage-0                                   |
|     Fetch Operator                                 |
|       limit: -1                                    |
|       Processor Tree:                              |
|         ListSink                                   |
```

##### 案例1解析

```mysql
这段HQL的执行计划描述了一个Hive查询的执行过程，分为三个阶段（Stage-4、Stage-3、Stage-0）。下面对每个阶段的执行计划进行解读：

#个人总结
一个map-reduce是一个stage
最后一个stage，如果是select语句，那么就是先写入hdfs临时文件,然后fetch读取，展示在hive客户端


**Stage-4**：
- 这是一个根阶段，没有依赖其他阶段。
- 该阶段执行本地的Map Reduce任务。
- 使用了一个本地表（Alias）$hdt$_1:tmp_copy。
- 执行了一系列操作：
  1. Fetch Operator：从表$tmp_copy$中获取数据，没有限制行数。
  2. TableScan：对表$tmp_copy$进行扫描，统计信息显示有11行数据和140字节大小。
  3. Filter Operator：根据条件$id$不为空进行过滤，统计信息显示过滤后剩下11行数据和140字节大小。
  4. Select Operator：选择表达式$id$，输出列名为$\_col0$，统计信息显示输出了11行数据和140字节大小。
  5. Group By Operator：按$\_col0$进行分组，采用hash模式，输出列名为$\_col0$，统计信息显示输出了11行数据和140字节大小。
  6. HashTable Sink Operator：输出hash表的键为$\_col0$。

**Stage-3**：
- 该阶段依赖于Stage-4。
- 该阶段执行Map Reduce任务。
- 执行了一系列操作：
  1. TableScan：对表$tmp$进行扫描，统计信息显示有12行数据和145字节大小。
  2. Filter Operator：根据条件$id$不为空进行过滤，统计信息显示过滤后剩下12行数据和145字节大小。
  3. Select Operator：选择表达式$id$、$name$、$superid$，输出列名为$\_col0$、$\_col1$、$\_col2$，统计信息显示输出了12行数据和145字节大小。
  4. Map Join Operator：进行Map连接操作，连接条件是左表的$\_col0$和右表的$\_col0$相等，输出列名为$\_col0$、$\_col1$、$\_col2$，统计信息显示输出了13行数据和159字节大小。
  5. File Output Operator：将结果输出到文件，不压缩，统计信息显示输出了13行数据和159字节大小。

**Stage-0**：
- 该阶段不依赖其他阶段。
- 执行了一系列操作：
  1. Fetch Operator：从上一阶段获取数据，没有限制行数。
  2. ListSink：将结果输出到ListSink。

这是一个简化的执行计划，描述了查询中涉及的表、操作和统计信息。具体的查询逻辑和数据处理过程可能需要查看更多的信息才能完全理解。
```

##### 案例2

```sql
 explain
 select
 userid,
 spuid,
 count(*) as buy_count,
 rank()over (partition by  userid,spuid order by count(*) desc ) as rk 
 from  ods_mysql_orderinfo as info
 join  ( select id from ods_mysql_userinfo ) as us
 on info.userid = us.id 
 group by info.userid,info.spuid
 limit 20;
```



##### 案例2解析??

```
第一个stage 查询userinfo的id ,然后发送给第二阶段mapjoin
第二个stage是过滤字段，然后map join 关联user表过滤,然后group by id,userid,count(*) 
第三个stage 在tableScan下看到是reduce output operate，说明执行shuffle了

```





# 可执行写法

### 创建视图

```mysql
#hive中有视图，没有存储过程

create view v1 as select * from t1 where id >100;
```

### with 临时表

```sql
with new_tb1 as (select * from student where sex='male' and money>5000),
    new_tb2 as (select * from student where sex='female' and money>5000)
select name,age,money,sex from new_tb1
// with里的语句当作临时表
```

### cast转换

一般用于把string转为int，比如有的字段存为string， 实际是数字，有时候需要order的时候，18 和2如果是字符串 那么排序 18是小于2的。如果是把字符串转为数字，就会是null

### sort by 局部排序

如果使用order by 那么只有一个reduce，因为为了全局排序，有时候为了快速，使用局部排序。但是如果不结合distribute,每个reduce是按什么分区的不确定，所以用distribute 可以指定分区的字段，这样就有用了，单独一个sort by 没有意义。

distribute by + sort by就是该替代方案，被distribute by设定的字段为KEY，数据会被HASH分发到不同的reducer机器上，然后sort by会对同一个reducer机器上的每组数据进行局部排序。

```
select * from tb distribute by  areaid  sort by num desc; 
```

### union/union all

```sql
#union会去重,union all不会去重

#union去重规则
会对所有字段比对,具体的去重规则如下：
对于非集合类型的字段，UNION会比较字段的值是否相等来判断行是否重复。
对于数组,只有当两个数组的元素完全相同，并且元素的顺序也相同，才会被视为重复的行。
对于包含Map、Struct等复杂集合类型的字段，UNION操作符在Hive中无法直接进行去重判断。在这种情况下，UNION会将所有行都保留，无论它们是否重复。
```

### in查询

hql支持in查询，以前以为效率低, 其实一样的,explian计划也是转为join

```sql
select * from tmp  where id in (select id from tmp_copy);

/*看执行计划里对tmp_copy表进行group了,
	然后执行的是map join  //这样的话和join就没区别了
```

### 开窗用分组后的统计

```sql
 select userid, 
 spuid,
 count(*),
 //可以在groupby分组后，开窗里直接用聚合算子count(*)排序
 rank()over ( partition by  userid,spuid order by count(*) desc ) as rk 
 from  ods_mysql_orderinfo as info
 group by info.userid,info.spuid
```



### on的非等值连接

```mysql
支持on条件非等值连接,但是底层原理好像是笛卡尔积，然后再过滤，通过explain一个案例可以看到
#案例
t1表  
name  start  end 
不及格 0  		 60

t2表
score 
10 

select * from t2 join t1 on t2.socore>t1.start and t2.score < t1.start
这个语句是可以执行的，不会报错。
keys关联条件，是没有字段。正常是有关联字段的。但是explain看到是笛卡尔积，后再过滤的。


```





# 常用函数

#### 条件函数

nvl(name,"姓名丢失")

if (age>18,a,b)

case typeid  
when 1  then '酒店'
when 2  then '食品'
else '未知'   end as type 

#### 日期函数

date_format(date,yyyy/MM/dd) 将日期转换为/的格式，不过date必须是yyyy-MM-dd 或者yyyy-MM-dd hh:mm:ss	格式

#### 字符串函数

concat(col1,clo2,col3....)

concat_ws("," col1,col2,col3) 这个函数会跳过为null的字段，所以最好加上nvl判空

split(col,'/') 返回一个array

#### 多行转单行

collect_set(col) 将一个字段去重之后汇总，返回的是一个array

#### 单行转多行

explode   

explode(col) 将hive中的array,map 进行拆分,  配合lateral view用

select  movie,cate，tmp.type
from tb
lateral view explode( split(cate,',') ) tmp as type;



#### 窗口函数

    在sql中有一类函数叫做聚合函数，例如sum(), avg(),max()等等，这类函数可以将多行数据按照规则聚集为一行，一般来讲，聚集后的行数是要少于聚集前的行数的。但是有时候我们既想要显示聚集前的数据，又要显示聚集后的函数，这个时候，我们便引入了窗口函数。窗口函数又叫OLAP函数/分析函数.
    窗口函数最重要的关键字是partition by和 order by.具体语法是：over(partition  by  用于分组的列名  order  by  用于排序的列名)
    
    partition by用来限制窗口的范围，也可以结合current row ,n proceeding等 复合范围


select name, departid,salary

row_number( ）over(partition by departid )   from  tb ;

这里的窗口范围是指，当前行的所在的departid对应的组所有数据。



over()窗口限定范围，如果over中有order by 并且没有制定范围的话，默认是受用between 第一行 and current row 

unbounded preceding 起点行

unbounded following 终止行

current row 当前行

n preceding 向前n行

n following  向后n行

具体写法  rows between   unbounded preceding  and current row



rank()     相同的会重复

row_number()相同的不会重复

dense_rank()

lag(col ,n,default)  统计窗口中向前第n行的值  lag( name ,2,'无') over( partition by age  order by num)

lead(col,n,default)统计窗口中向后第n行的值 

# 高阶函数

#### explode

```sql
会返回2行
select  explode(array(1,2));
1
2

2行2列
select explode(map("id",1,"age",18));
id  1
age 18


select "a1",explode(array) from the_nba_championship;
会报错UDTFs are not supported outside the SELECT clause, nor nested in expressions
```

1. explode函数属于UDTF函数，即表生成函数；
2. explode函数执行返回的结果可以理解为一张虚拟的表，其数据来源于源表；
3. 在select中只查询源表数据没有问题，只查询explode生成的虚拟表数据也没问题
4. 但是不能在只查询源表的时候，既想返回源表字段又想返回explode生成的虚拟表字段
5. 通俗点讲，有两张表，不能只查询一张表但是返回分别属于两张表的字段；
6. 从SQL层面上来说应该对两张表进行关联查询
7. Hive专门提供了语法lateral View侧视图，专门用于搭配explode这样的UDTF函数，以满足上述需要。

#### lateral view

  hive函数 lateral view 主要功能是将原本汇总在一条（行）的数据拆分成多条（行）成虚拟表，再与原表进行笛卡尔积，从而得到明细表。配合UDTF函数使用，一般情况下经常与explode函数搭配，explode的操作对象（列值）是 ARRAY 或者 MAP ,可以通过 split 函数将 String 类型的列值转成 ARRAY 来处理。



a/b/c

# hql案例



#### 连续3天问题

```sql

#思路1：等差数列
按日期排序,排名是每行增加1，连续日期也是每天+1, 日期 减排名得到一个日期值值，值相同的就是连续的，
按日期值聚合，出现4次，表示从这个日期开始，连续4天都登陆了
实际就是弄个连续表，当日期连续时，和等行连续表的差值为0，当某一天跳动3后，后续连续日期和等差表差值为3。
等过差值判断时候为连续，相同的即连续

#思路2：第3次比第1次日期多2即连续 
按日期排序，获取每行数据前推2天的日期，当前日期于与前推日期差值为2说明，有连续3天的数据。

#思路3:常规思路实现？？临时变量无法实现
连续4天，模拟人的思维，第一次出现连续，看下一个数是否还是连续，记录连续出现3次。
具体实现方法，通过后-前 =1来判断连续，将连续次数存入临时变量中>4,就完成了。
后-前 =1可以获取。将连续次数存入临时变量中>4，用什么思路解决呢？



```

#### 部门最早的人(不开窗取一条)

```sql
select 
split (  max( concat(createtime,"|", userid )),"|",2 ) as userid 
from tb
group by subject
```



#### 表join(条件字段在b,c范围之间)

```mysql
#题干
t1表  
name  start  end 
不及格 0  		 60

t2表
score 
10 

#目标获取t2表分数所在分段
最简单的是笛卡尔积，然后过滤满足 start<score<end

#不用笛卡尔积

```



#### 递归查找部门所属(不支持)

hive不支持递归查询，所以chatgpt给的答案是错的

```sql
with cte as(
select id,name,superid, "ttt" as maxname from tmp where superid =0
union all 
select tmp.id,tmp.name,tmp.superid,t1.name as maxname  from cte as t1
join  tmp on t1.id = tmp.superid
)select * from cte;

报错SemanticException Recursive cte cte detected (cycle: cte -> cte).
```



#### 部门前3不开窗(待定)

不用开窗，求每个部门前2

```
部门id   用户id   工资
11			1        100
11	    2        120
11      3        130
```







