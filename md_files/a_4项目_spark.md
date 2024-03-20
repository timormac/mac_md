

# 问题

### 1.资源分配有问题

### 2.内存不够溢写，为什么oom

```mysql
MapReduce（MR）和Apache Spark是两种流行的大数据处理框架，它们都有机制来处理大量数据。在处理大规模数据集时，内存管理是这两个框架都必须面对的一个关键问题。尽管它们都有能力在内存不足时将数据溢写到磁盘，但仍然可能会发生内存溢出（OOM，Out of Memory）错误，原因可能包括：

1. **内存管理策略**：
   - **MapReduce**：在MapReduce中，shuffle阶段会将中间数据写入本地磁盘。如果一个map任务产生的数据量超过了JVM堆内存的限制，即使有溢写机制，也可能因为没有足够的内存来存储和处理这些数据而导致OOM。
   - **Spark**：Spark使用内存来存储和处理数据，但是当内存不足时，它会将数据溢写到磁盘。Spark的内存管理是基于一种称为RDD（Resilient Distributed Dataset）的抽象概念，它可以将数据缓存在内存中。如果一个任务的数据集大小超出了可用内存，并且因为GC（垃圾回收）压力或缓存策略不当，导致无法有效地溢写到磁盘，那么也可能发生OOM。

2. **内存配置不当**：
   - 对于MR和Spark，如果内存配置（如Java堆大小、Spark的executor内存等）过低，那么即使在内存不足时可以溢写到磁盘，但在溢写前的处理过程中仍然可能耗尽内存。

3. **数据倾斜**：
   - 在MR和Spark中，如果数据分布不均匀，导致某个节点或某个任务处理的数据量远大于其他节点或任务，可能会导致该节点或任务出现OOM。这种现象称为数据倾斜。

4. **大对象处理**：
   - 如果在处理过程中创建了大量的大对象，并且这些对象的生命周期较长，那么垃圾回收器可能无法及时回收这些对象占用的内存，从而导致OOM。

5. **并发任务数过多**：
   - 如果同时运行的任务数过多，每个任务分配的内存可能不足以处理数据。

6. **Shuffle行为**：
   - 在shuffle过程中，数据需要在不同节点间传输，如果shuffle产生的数据量非常大，可能会消耗大量内存。

解决OOM问题通常需要综合考虑资源配置、任务调度、数据分布和代码优化等多方面因素。例如，可以通过调整内存设置、优化数据分区、处理数据倾斜、使用更有效的数据结构和算法，或者增加集群的资源等方式来解决OOM问题。
```



# sparksql优化



# p26看完了(看27)

### spark配置文件

```mysql
#yarn相关
已知道yarn的默认单节点最大内存分配2g，单个容器是512-1024m，spark参数应该对应yarn

#spark参数
spark/conf下没有默认的配置文件,每次提交的时候都是临时置顶driver和excutor内存的。
并且你设置的driver和excutor不能超过yarn的容器大小，不然yarn会拒绝启动容器
```



### explain计划

```mysql
#p3看执行计划
4种计划，有个代码计划，可以查看具体的可执行java代码
webui上有sql执行的执行图，能看到,spark执行预聚合了，最后在sink端又聚合一次

```







### 资源分配（？？）

```mysql
#p4 如何设定资源
1 excutor-cores 每个excutor用几个核
2 num-executors 启动多少excutor数
3 excutor-memory 一个excutor分配多少内存，yarn最大100内存/启动excutor，就是值


driver 内存设置，一般不动因为不用colesc算子，一般driver不会存数据


storage和exution内存，可以互相动态互相占用，所以不用改占比，默认各占50%
#storage内存:？？？？加载数据块的内存在哪呢
cache，广播变量，用的内存。如果存不下就落盘

storage内存= 广播变量大小+cache/Excutor数 大概分配

#excution内存（核心）:？？？？下面设置的正好是加载数据的内存,shuffle内存，算子链内存呢？难道要落盘再启动reduce任务吗，
#不是说map和reduce不落盘，直接走内存传递吗？？这么设置不合理吧
存shuffle数据的内存。

spark默认的并行度是200(配置文件可以改)，就是说你1个G和10g都会分成200个task,每个task 500m数据大小
一个excuoter是4个核，同时能执行4个任务，那么至少分配4*500m内存给每个excutor，这样至少能一次性把所有数据加载到内存




#other内存:
用户定义的数据结构内存,比如自定义的map。spark内部的元数据
```



### cache

```mysql
默认cache是memory_only这种执行最快,不过费内存？？为什么费内存，正常执行缓存也要序列化啊？还是说直接不序列化呢，从内存直接拿对象呢？？？？当你设置缓存策略为MEMORY_ONLY，Spark会尝试将RDD或DataFrame的数据存储在JVM的堆内存中。这里的关键点是，数据默认情况下是以非序列化的形式存储的，也就是说，数据以Java对象的形式直接存储在内存中。
用memory_onliy_ser 序列化缓存，能减少内存使用，使用kryo也能减少内存使用。序列化的存储通常会占用更少的内存（因为序列化的对象通常更小），但是在反序列化时需要消耗额外的CPU资源。

注意cache设置了之后，有时候现实缓存30%也就是内存不够完全存下数据的。
dataset的cache默认是memory_and_disk，dataset，序列化并不使用java或者kryo格式序列化，是一个特殊格式选择器可能是kyro。
dataframe和dataset序列化效果更好，比rdd的kyro还好
dataframe默认的cache是memory_only.
性能上dataframe和dataset大于rdd,开发中使用dataset和dataframe

```

### cpu？？？

```mysql
1）并行度较低、数据分片较大容易导致 CPU 线程挂起 2）
并行度过高、数据过于分散会让调度开销更多 ,Executor 接收到 TaskDescription 之后，首先需要对 TaskDescription 反序列化才能读取任务信息，然后将任务代码再反序列化得到可执行代码，最后再结合其他任务信息创建 TaskRunner。当数据过于分散，分布式任务数量会大幅增加，但每个任务需要处理的数据量却少之又少，就 CPU 消耗来说，相比花在数据处理上的比例，任务调度上的开销几乎与之分庭抗礼。显然，在这种情况下，CPU 的有效利用率也是极低的。

#并行度设置？？？？？
申请10个excutor,每个excutor 4核，每个excuotor 4g

总结：一共40核，1核平均1g内存。
那么多个个map任务呢，按理来说1个核一个map任务最好，不过一般一个核处理2-3任务，防止有的执行快浪费cpu
并且每个任务最好是1g的数据量，1g的数据量具体能处理多少大小的文件块呢？？？？？？？？

40核，应该安排120个task任务。如何安排120个任务呢？？？？？？
还是说应该因为sql处理的数据量来分配核呢？？？？？
```



### 并行度

```mysql
#默认并行度
spark.sql.shuffle.partitions 默认是200,就是reduce阶段默认并行度。这个参数只能控制sparkSQL,dataframe,dataSet，对于rdd是没用的。

对于只有10个excuter也可以有200个reduce，原理和map一样，1个reduce收集完，换下一个

#sparksql和hive数据分片有区别
1 task数太少
默认是200个task，加入有1000g的数据，还是200task，那么每个task处理5g数据，导致数据分片过大
而hive是根据文件大小/128自动启动map数的，不一样，spark是固定的。
2 task数量太大
如果1个g数据，你设置1000个task，这样每个task处理一点数据，反而切换任务更费时间。

官方推荐就是task数是 core数的2-3倍。
也就是说1000g数据，你excutor每个核分配1g内存，那么一个task最多处理1g内存。那么应该分1000个task。
应该有330个core来执行这个任务。需要手动设置task数，然后手动设置core数来定配
```



### rbo优化器

```mysql
#谓词下推
select 
tb1.name,
tb2.cores
tb1 join tb2
on tb1.id =tb2.id
and tb1.age>18
and tb2.age>20
where cores>100;

join后的where会自动帮你优化到t1,t2的map端口提前过滤，然后再join，减少io传输。并且都会自动帮你过滤关联key为null值的数据
但是on的过滤，不会全部，以后尽量用where去过滤，这样优化器能识别，where和on过滤效果不同
left Join（on来过滤） 只下推右表,不是最佳优化  
inner/left（where过滤） 两表都下推，是最佳优化

#inner join(条件放在where)
a join b on  a.id = b.id where a.id<2
具体解析:因为关联条件是id，虽然过滤条件是a.id<2,但是优化器能识别出关联字段是id，因为是inner join 所以b表的id也可以过滤b.id<2优化

#left join(条件放在on)
a left join b on  a.id = b.id and a.id<2
具体解析:因为是left join所以认为是保留左边全部数据,然后右边b.id<2优化，最后join之后,再过滤id<2
所以这个优化引擎,优化的不够好,因为最佳优化是map端a.id和b.id都过滤，但是优化器只过滤b.id
总结:过滤条件不要放在on里，放在where里,能识别

##left join(条件放在where)
a left join b on  a.id = b.id where a.id<2
这个是最佳优化，2个map端都提前过滤id

#列裁剪
io只传输sql里需要的 列


```

### cbo优化器

```mysql
#CBO优化器
会抉择用最小花费，完成任务，上边的是rbo优化器，优化执行计划。
两方面:1 根据数据集大小，数据集所在位置，配置任务
			2 优化操作算子等

#开启CBO
不开启不起作用
通过 "spark.sql.cbo.enabled" 来开启，默认是 false。配置开启 CBO 后，CBO 优化器可以
基于表和列的统计信息，进行一系列的估算，最终选择出最优的查询计划。比如：Build 侧
选择、优化 Join 类型、优化多表 Join 顺序等


spark.sql.cbo.enabled CBO，默认false, 总开关
要使用该功能，需确保相关表和列的统计信息已经生成。

spark.sql.cbo.joinReorder.enabled 默认flase,使用 CBO 来自动调整连续的 inner join 的顺序。
要使用该功能，需确保相关表和列的统计信息已经生成。
举例:a join b join c join d 正常是先a,b完事去join c再d。优化器根据表和列的统计信息可能，c,d先join之之后再跟ab结果join

spark.sql.cbo.joinReorder.dp.threshold 使用 CBO 来自动调整连续 inner join 的表的个数阈值。
默认是12表以下join才开启，上面的inner join调整





#统计表信息
生成表级别统计信息（扫表）：
ANALYZE TABLE 表名 COMPUTE STATISTICS

生成表级别统计信息（不扫表）：
ANALYZE TABLE src COMPUTE STATISTICS NOSCAN

生成列级别统计信息
ANALYZE TABLE 表名 COMPUTE STATISTICS FOR COLUMNS 列 1,列 2,列 3

显示统计信息
DESC FORMATTED 表名

显示列统计信息：
DESC FORMATTED 表名 列名
有列的min,max最小值，最大值,null值数量,平均长度，最大长度

查看表信息，列信息，如果不执行上面的生成收集计划，是看不到的，执行之后能看到收集到的具体表信息。
执行完收集任务之后，会持久化到hive在mysql的元数据库，去tb_para里能看到，执行收集后，会发现多了很多数据

#sortmerg join
默认的就是这个，没有优化，和mr一样，对关联key，进行shuffle，然后进行排序，然后传到redcue，reduce再整体排序


#broadcast join
当表够小时,会进行broadcast join，小表汇聚到driver，通过driver广播到各分区。
可以调整braodcastjoin的大小参数。

强行广播：如果有个表500m，可以临时设置广播join大小参数，或者强行广播某个表。
通过sql写法，暗示就可以，具体看idea代码

SQL Hint方式
1:
    |select /*+  BROADCASTJOIN(sc) */
    |  sc.courseid,
    |  csc.courseid
    |from sale_course sc join course_shopping_cart csc
    |on sc.courseid=csc.courseid
2:
    |select /*+  BROADCAST(sc) */
    |  sc.courseid,
    |  csc.courseid
    |from sale_course sc join course_shopping_cart csc
    |on sc.courseid=csc.courseid
3.
    |select /*+  MAPJOIN(sc) */
    |  sc.courseid,
    |  csc.courseid
    |from sale_course sc join course_shopping_cart csc
    |on sc.courseid=csc.courseid
4. 通过代码调用    
val sc: DataFrame = sparkSession.sql("select * from sale_course").toDF()
val csc: DataFrame = sparkSession.sql("select * from course_shopping_cart").toDF()
println("=======================DF API=============================")
import org.apache.spark.sql.functions._
broadcast(sc)
  .join(csc,Seq("courseid"))
  .select("courseid")
  .explain()


#smb join(分桶表join)
如果原来表没有设置分桶，那么做一个临时的分桶表。通过2个分桶表join，2个分桶表的join必须，桶数相同，或者成整数倍。

注意如果是3表join，2个分桶，一个不分桶，那么先分桶表之间先join，如果先join非分桶的，那么得到的结果就是非分桶表了，
后序无法smb join

```



### 数据倾斜

```mysql
#表现
看sparkUI图,然后发现其他任务比较短，个别任务长度长。太久了坑出现oom

#找到大key
通过抽样执行，而不是通过sql整个表查询。
抽样代码
val df: DataFrame = sparkSession.sql("select " + keyColumn + " from " + tableName)
val top10Key = df
  .select(keyColumn).sample(false, 0.1).rdd // 对key不放回采样
  .map(k => (k, 1)).reduceByKey(_ + _) // 统计不同key出现的次数
  .map(k => (k._2, k._1)).sortByKey(false) // 统计的key进行排序
  .take(10)
top10Key

#groupby数据倾斜
默认就是开启预聚合，hashAggregate,这个就是预聚合，执行计划中都是成对出现，先map端预聚合，再reduce聚合一次。
基本来说groupby大部分的情况。
对于将id打散前缀加1-10，先聚合，再聚合，这种方法运用场景不多。

#join数据倾斜
1 广播join
2 热点数据单独处理 join
比如订单大表，关联poi大表。无法广播，把热点poid找出，然后分别join就行广播了，然后union
3 大key打散｜前缀1-10，然后维度表扩大10倍，join。先对key采样，只对热点key进行打散，然后union 非热点key的正常join
这个场景订单大表1000个g，维度表1g，不适合广播维度表，把维度表变为10倍。再join,还是shuffle，不太行
这种不好，最完美就是把维度表广播

```



### job代码优化??

```mysql
#算子优化
当聚合时，用reducebykey或aggregatebykey，这个会预聚合，直接用groupbykey不会预聚合

#读取小文件优化  详情在p23 5:03
读取的数据源有很多小文件，会造成查询性能的损耗，大量的数据分片信息以及对应
产生的 Task 元信息也会给 Spark Driver 的内存造成压力，带来单点问题。
设置参数：
spark.sql.files.maxPartitionBytes=128MB 默认 128m
spark.files.openCostInBytes=4194304 默认 4m   文件开销，何3个文件,12m是文件开销，剩下的才是给文件的 具体作用看p23 5:03

#????？
如果是这个逻辑，为什么说spark默认的task数是200个呢？？？不应该根据并行度和切片数来执行任务吗？？？
还是说200是shuffle的task个数呢？？

#map端buffer优化
能减少shuffle时，write的时间。之前说的如果数据不大，不落盘直接走内存，不存在，域值就5m肯定要落盘的
具体p24

#合理设置reduce数
生成文件等于shuffle并行度，默认时200个文件，
1）可以在插入表数据前进行缩小分区操作来解决小文件过多问题，如 coalesce、repartition 算子。
就是先正常shuffle，不会减少shuffle的速度，然后多一个coalesce算子，减少分区数。
2）调整 shuffle 并行度，有 Shuffle 的情况下，上面的 Task 数量 就变成了 spark.sql.shuffle.partitions（默认值
200


#小文件问题
动态分区，
1）没有 Shuffle 的情况下。最差的情况下，每个 Task 中都有表各个分区的记录，那文
件数最终文件数将达到 Task 数量 * 表分区数。这种情况下是极易产生小文件的。
INSERT overwrite table A partition ( aa )
SELECT * FROM B;
2）有 Shuffle 的情况下，上面的 Task 数量 就变成了 spark.sql.shuffle.partitions（默认值
200）。那么最差情况就会有 spark.sql.shuffle.partitions * 表分区数。
当 spark.sql.shuffle.partitions 设 置 过 大 时 ， 小 文 件 问 题 就 产 生 了 ； 当
spark.sql.shuffle.partitions 设置过小时，任务的并行度就下降了，性能随之受到影响。
最理想的情况是根据分区字段进行 shuffle，在上面的 sql 中加上 distribute by aa。把同
一分区的记录都哈希到同一个分区中去，由一个 Spark 的 Task 进行写入，这样的话只会产
生 N 个文件, 但是这种情况下也容易出现数据倾斜的问题。
```

### hint暗示join

```mysql
# broadcasthast join 广播
sparkSession.sql("select /*+ BROADCAST(school) */ * from test_student
student left join test_school school on student.id=school.id").show()

# sort merge join（适合大数据集，需要排序，可以不需要将整个数据集加载到内存，通过磁盘排序和合并，能处理大数据集）
sparkSession.sql("select /*+ SHUFFLE_MERGE(school) */ * from
test_student student left join test_school school on
student.id=school.id").show()
sparkSession.sql("select /*+ MERGEJOIN(school) */ * from test_student
student left join test_school school on student.id=school.id").show()
sparkSession.sql("select /*+ MERGE(school) */ * from test_student
student left join test_school school on student.id=school.id").show()

#shuffle_hash join( 没有排序炒作，key相同的发送到相同节点上，需要都加载到内存   )
sparkSession.sql("select /*+ SHUFFLE_HASH(school) */ * from test_student
student left join test_school school on student.id=school.id").show()

# shuffle_replicate_nl join
使用条件非常苛刻，驱动表（school 表）必须小,且很容易被 spark 执行成 sort merge
join。
```



### 提交模式

```mysql
#yarn-cluster
driver在任意一个服务器,关闭当前提交节点的窗口，也不会推出，需要kill来杀死。

#yarn-client
提交到测试服务器
driver在提交任务的节点，实时收集各个excutor执行情况，关闭后分布式任务停止
一般用去测试集群调试，查看sparksql执行情况

#local
idea

#stand-alone

```



# 案例

#### 故障恢复状态回去

```
spark用mysql，存kafka消费偏移量，当前累积值

flink我想用状态自动做这个操作，不过好像失败了



```

#### 双流join缓存处理

```mysql
用redis做30s缓存,不能永久,不然redis扛不住.
最后对redis过期数据做,监控，实现测输出流的功能。

```

