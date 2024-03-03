

# 问题

### 1.资源分配有问题

# sparksql优化

# 到了p11



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
#RBO优化器
会抉择用最小花费，完成任务，上边的是rbo优化器，优化执行计划。
两方面:1 根据数据集大小，数据集所在位置，配置任务
			2 优化操作算子等


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





#广播join
当表够小时,会进行broadcast join，小表汇聚到driver，通过driver广播到各分区。
可以调整braodcastjoin的大小参数
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

