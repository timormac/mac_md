# 个人理解

```mysql
#框架选择
每5秒实时统计当天订单交易数，去重用户数。
目前有有2个方案，第一个通过flink实时把etl后的订单写到clickhouse中，然后每5秒通过clickhouse执行临时sql查询，
第二个方案，是通过flink框架，内部计算当天累积值，然后每5秒，刷写到mysql中，然后后台查询mysql去更新数据。

方案二，速度最快,不过开发效率低。
当实时需求不多,并且统计维度不多，同一个订单表任务不多时，flink+mysql,每个都手动就可以，不引入额外框架

方案一,当未知任务多，并且同一个表统计维度很多，那还是存clickhouse去临时存吧

```



# 问题待解决

### windowJoin又是什么

```
1. **Window Join**：在有限的窗口范围内连接两个流。窗口可以是时间窗口（例如，10分钟的滚动窗口）或者是其他类型的窗口。窗口 join 通常用于连接两个流的元素，这些元素在某个时间段内是相关的。


3. **Join Function**：可以自定义一个 join 函数来指定如何连接两个流的元素。这通常是在 `DataStream` API 中使用 `join` 操作时进行的。

4. **CoGroup Function**：类似于 SQL 中的 `FULL OUTER JOIN`，`coGroup` 允许你为两个流的每个键分别分组元素，然后可以在结果迭代器上执行操作。

```

### intervaljoin关联不到数据

```
关联不到
```





### yarn-session无法提交job

启动yarn-sesion，正常会按conf里面的，开启job和taskmanager

我手动指定yarn-session的总task和job的内存，slot后，还是为0，所以有问题了

但是现在的yarn session可用slot为0 ，所以提交不成功。



### FlinkKafkaConsumer过时

实现sourceFunction的kafka有3个,FlinkKafkaShuffleConsumer，FlinkKafkaConsumer，FlinkKafkaConsumerBase

FlinkKafkaConsumer过时了

FlinkKafkaShuffleConsumer是他的继承类，不过没有public构造器,也没找到buider不知道怎么办

### 可用slut为0但是能提交任务

yarn-application模式，可用slots是0，但是能提交一个3并行度的任务,不知道为什么

只能提交第一个任务，第二个任务提交时，提交不了了，一直卡在了，显示

Deployment took more than 60 seconds. Please check if the requested resources are available in the YARN cluster
Deployment took more than 120 seconds. Please check if the requested resources are available in the YARN cluster



如果时先启动yarn-session服务器，发现连第一个任务都启动不了，不知道为什么，一直卡在申请container



### log4j日志不打印

代码里指定了log4j打印目录，在idea能自己创建目录，上传到集群，log日志无法生成





### 无继承关系却满足范型

```
 //问题 :forGenerator方法需要传入一个WatermarkGeneratorSupplier，但是老师模仿的实现的是WatermarkGenerator
 //这2个不一样WatermarkGenerator和WatermarkGeneratorSupplier没有父子关系为什么能传进去
// WatermarkStrategy.forGenerator()
```

下面问题也是一样的

```java
WatermarkStrategy<WaterSensor> watermarkStrategy = WatermarkStrategy
    .<WaterSensor>forBoundedOutOfOrderness(Duration.ofSeconds(2))
    .withTimestampAssigner(new SerializableTimestampAssigner<WaterSensor>() {
      @Override
      public long extractTimestamp(WaterSensor element, long recordTimestamp) {
      });
 //WatermarkStrategy.forBoundedOutOfOrderness()方法，点进源码看到的是:
 static <T> WatermarkStrategy<T> forBoundedOutOfOrderness(Duration maxOutOfOrderness) {
        return (ctx) -> new BoundedOutOfOrdernessWatermarks<>(maxOutOfOrderness);
    }
   //源码显示的方法返回值是WatermarkStrategy，不过new BoundedOutOfOrdernessWatermarks<>(maxOutOfOrderness)，点进去并没有实现WatermarkStrategy接口，看不懂了，为什么new BoundedOutOfOrdernessWatermarks能用WatermarkStrategy接
   
   BoundedOutOfOrdernessWatermarks类,实现了WatermarkGenerator接口，并且这个接口是个初始接口，和watermarkStrategy没关系
  class BoundedOutOfOrdernessWatermarks<T> implements WatermarkGenerator<T>    
```



### watermark传递机制

flink中waterMark是怎么传递的，比如先map 然后 process，不同算子之间，是根据流过的数据来更新watermark吗



### flink-session起不来

更改配置文件后连yarn-sesion都起不来
为了资源够slut,更改flink配置文件，发现起不来了。后面查阅发现，好像比如jobmanager和taskmanager有一定内存比例的，而且分给某些线程的内存要在固定60m-256m范围之间，因为只改了jobmanager和taskmanager的内存配置，所以起不来了。

要怎么配置内存占比呢，才能让集群跑起来



# 问题已解决(待回顾)

### 定时器重复注册

```mysql
#定时器秒触发
因为设置的定时器为registerTimeTimer(5000L)，应该是事件时间+5000L，不然系统时间肯定是大于5000ms的。

#定时器是否覆盖
flink对于keyby后的流，是按key和定时器的触发时间，来作为map的key存储的。
前后多条数据，你都设置同一个触发时间，会发生覆盖。
但是一般都是设置，事件时间+定时间隔，所以这种情况基本遇不到，极端情况会有
```





### 想要的TTL

```sql
#存在背景
TTL为了防止内存无限制扩大

#想要的TTL
但是我想要的情况，是ListState中某些数据过期后,把list中过期数据清除，然后新建一个更小的list替换当前这个很大内存的list。

#需求实现
状态中,每个用户统计当天的数据，第二天只要第二天的数据，想要第一天数据过期
使用date|userid作为key，这样日子不同key不同,然后设置ttl为1天，这样第三天，第一天的数据就全部没有了。

#案例1 
对于按键分区的流，比如记录每个用户24小时内浏览的页面，放入liststate中。设置ttl为24小时
如果24小时内，这个用户没有数据来,那么这个listState就会删除，节省空间

#案例2
如果我想要ListState中的元素，每个按照过期时间删除，目前flink的TTL不支持，只能手动实现。
手动实现通过定时器list.remove删除，并不会节省内存，因为数组长度已经固定了。
但是可以存在rocksDB，除了临时缓存，其他放不下的数据是存在磁盘的，最终的list.remove会传递到rockDB磁盘

```



### TableApi用moudule时找不到类

把hadoop-mapreduce-..jar拷贝到flink中，其他的方法都不解决根本。这个最好使，在word里

坑已经被视频趟过了



### kafka.consumer.OffsetResetStrategy

```mysql
#报错
cannot assign instance of org.apache.kafka.clients.consumer.OffsetResetStrategy to field org.apache.flink.connector.kafka.source.enumerator.initializer.ReaderHandledOffsetsInitializer.offsetResetStrategy of type org.apache.kafka.clients.consumer.OffsetResetStrategy in instance of org.apache.flink.connector.kafka.source.enumerator.initializer.ReaderHandledOffsetsInitializer

#原因
根本原因是Flink从Java和UserCode Classpath动态加载依赖项。有些类可以由不同的类加载器加载，然后将它们的类型分配给彼此。

#解决方法：
flink的conf.yaml文件加一条
echo 'classloader.resolve-order: parent-first' >> flink/conf/flink-conf.yaml

#问题解决来源
https://stackoverflow.com/questions/72266646/flink-application-classcastexception

```



### flink参数设置单容器核数不生效

因为容量调度里里是按内存分核的，所以要改yarn的配置。是yarn的问题



### flink连接hive时报错找不到方法

NoSuchMethodError: com.google.common.base.Preconditions.checkArgument

基本已经定位到了就是hadoop-common再个包导致的，视频没导入，gpt推荐的，很坑

具体链接：https://blog.51cto.com/u_15278282/4221694

在hadoop目录下的/export/server/hadoop/share/hadoop/common/lib文件夹中，存在着guava-27.0-jre.jar这个包，而在/export/server/hive/lib文件夹中，存在着guava-19.0.jar和guava-27.0-jre.jar这两个对应的包，此时发生了包冲突，产生了错误，因此这里需要把guava-19.0.jar的包删除



# 问题已记住(备份)

### 基础问题

```sql
#reduce/Aggregate的state用途
valueState + 逻辑,可以代替这2个,并且更通用。
reduce/Aggregate 是为了代码简洁

### 三流join怎么实现
看了下源码,connect流只能存2个流数据，当多流join，只能按照hql的解析方式，拆分为多个join任务，先关联一个处理后再关联下一个。你也可以自定义个一个connect流，然后自己生成多流join逻辑。

### 水位线不推进
没设置并行度导致默认是8个线程，而水位线必须8个流里的数据都有数据并且事件时间更新到10s时才触发process执行
因为之前输入的key都是a,b导致其他线程没数据，导致其他线程水位线时间不更新，所以尽管a,1000但是还是不触发process窗口关闭
* 后面设置并行度为2,就好了，不过必须a,b 2个事件时间都超过10
* 为了避免这种情况可以设置空闲时间等待.withIdleness(Duration.ofSeconds(10))
* //空闲等待10s，即当10s内其他分区没有数据更新事件时间是，等10s，按最大的时间时间同步到其他没数据的分区

### kafka的配置在哪找
在import org.apache.kafka.clients.consumer.ConsumerConfig里可以看到，property里面可以设置哪些配置


#checkpoint单独使用
即使没注册状态,checkpoint也可以用，比如记录kafka的消费,有checkpoint提交偏移量，可以保证不丢。
checkpoint也能结合下游事务，比如两阶段提交，flink会自动结合checkpoint做事务。


### yarn-session模式起不来任务
"application任务被杀"
启动任务后显示任务被yarn杀掉
原因： 如果 Flink 或者用户代码分配超过容器大小的非托管的堆外（本地）内存，部署环境可能会杀掉超用内存的容器，造成作业执行失败。
"更改配置文件后连yarn-sesion都起不来"
为了资源够slut,更改flink配置文件，发现起不来了。后面查阅发现，好像比如jobmanager和taskmanager有一定内存比例的，而且分给某些线程的内存要在固定60m-256m范围之间，因为只改了jobmanager和taskmanager的内存配置，所以起不来了。

### sink接口无实现类
找到问题了，下面还有个sinkTo方法是接sink2.Sink的
在DataStream的sinkTo方法，需要实现connector.sink.Sink接口，打开idea去看,发现没有实现类。
用KafkaSink.build创建的KafkaSink,看源码是：
public class KafkaSink  implements StatefulSink,TwoPhaseCommittingSink{}
这两个接口实现的是connector.sink2.Sink,是2个不同的包的Sink接口，但是idea没报错。

### 算子里异常不会终止
代码Flink_learing中a9包的A2代码，map里出异常1/0，不会终止，而是重复执行方法体，不知道是不是因为checkpoint 。
注意：如果设置了检查点，它可以从最近的检查点恢复，也就是说当你处理1，2，3，异常数据时，会再执行一次1，2，3数据，
有重复的数据，比如超时重试等。

```

### 复杂问题

```mysql

```



# flink版本特性

Flink是一个开源的流处理和批处理框架，用于大规模数据处理和分析。下面是Flink的一些重要版本及其主要特性的概述：

1. Flink 1.x系列：这是Flink的初始版本，引入了流处理和批处理的功能。其中一些重要特性包括：
   - 流处理：提供了基于事件时间的流处理，支持窗口操作、状态管理等功能。
   - 批处理：支持批处理作业，与流处理作业可以无缝切换。
   - 事件时间处理：支持基于事件发生时间的数据处理。

2. Flink 1.1.x系列：这是Flink的重要升级版本，引入了一些关键的改进和新特性。其中一些重要的特性包括：
   - 改进的流处理引擎：提升了流处理的性能和稳定性。
   - 改进的批处理引擎：提升了批处理的性能和稳定性。
   - 改进的状态管理：引入了增量快照（Incremental Checkpointing）技术，提高了状态管理的效率和可靠性。

3. Flink 1.2.x系列：这是Flink的进一步升级版本，带来了一些重要的改进和新特性。其中一些重要的特性包括：
   - 改进的流处理引擎：引入了事件时间处理的改进和优化，提高了处理的准确性和性能。
   - 改进的批处理引擎：增加了更多的批处理优化，提高了批处理的性能。
   - 改进的状态后端：引入了RocksDB作为默认的状态后端，提供了更好的状态管理性能和可靠性。

4. Flink 1.3.x系列：这是Flink的又一个重要升级版本，带来了一些关键的改进和新特性。其中一些重要的特性包括：
   - 改进的流处理引擎：引入了异步快照（Asynchronous Checkpointing）技术，提高了流处理的容错性和性能。
   - 改进的批处理引擎：增加了更多的批处理优化和功能，提高了批处理的性能和灵活性。
   - 改进的状态管理：引入了增量快照的改进，提高了状态管理的效率和可靠性。

这些是Flink版本中的一些重要特性，升级到较新的版本可能会带来更好的性能、功能和开发体验。然而，升级也可能需要进行一些工作，如代码迁移、配置更改、应用程序兼容性测试等。因此，在决定是否升级之前，建议您进行充分的评估和测试，以确保升级对您的业务有实际的益处。同时，还应该考虑与其他系统和工具的兼容性，以确保整个技术栈的稳定性和一致性。





# 代码案例

### hdfs精准一次

```sql
#两阶段提交+预写日志
这2个操作是能保证，文件被精准一次的事务写入的，它保证的是flink的内部事务，而不是整体链路的事务。

#什么是flink的内部事务
即当checkpoint触发时,flieSink会触发真正的commit,然后会把临时目录的文件，改到目标路径。
因为移动文件是原子性的，不会出现1个文件的一部分写入了，而另一部分没成功。
两阶段提交保证的事务是：flink检查点正常触发时,这个检查点内的所有数据，都被精准一次写入，不会出现部分写入，部分失败情况。

你想要checkPoint失败了,数据不会重复写入这个事务，两阶段提交是办不到的。要么hdfs支持事务，要么hdfs支持幂等性

#案例
由checkpoint提交kafka的偏移量。当fileSink到了滚动条件刷写到hdfs上时，但是还没有到checkpoint的触发时间，我手动把程序杀死。
那么重启时，FiilSink会重复写入。

#FileSink
FileSink实现了两阶段提交和预写日志接口：TwoPhaseCommittingSink +WithPreCommitTopology
但是单独一个预写日志+两阶段提交是无法保证精准事务的，可能会出现重复
因为hdfs是不支持事务的
```

# flink-yarn模式



### 三种模式概览

```sql
#总结
session只会启动一个flink集群,适合长久运行和频繁提交作业
per-job和run-application，每个任务都会单独启动集群，不过run-application和yarn对接更好，如历史服务器等。

run-application模式下，JobManager 和 TaskManager 是一起的。JobManager 和 TaskManager 运行在同一进程中，共享相同的资源，这种模式适用于单机或小规模的部署。
但是session模式下,JobManager 和 TaskManager是分开的，所有任务共享一个JobManager


#详细
1. **Session模式**：
   - **区别**：在Session模式下，用户首先在YARN上启动一个长期运行的Flink集群（即一个YARN session），然后可以提交多个Flink作业到这个集群上。这个集群会一直运行，直到用户显式地停止它。
   - **使用场景**：适用于当有多个作业需要运行，并且这些作业可以共享相同的资源配置时。由于集群启动时间只计算一次，这种模式适用于频繁提交作业的场景，可以减少每次作业启动的开销。

2. **Per-Job模式**：
   - **区别**：Per-Job模式为每个提交的Flink作业启动一个独立的YARN集群。集群的生命周期与作业的生命周期相同，当作业结束时，集群也会自动停止。
   - **使用场景**：适用于作业较大或者需要隔离资源的场景。每个作业都有自己的资源，不与其他作业共享，从而可以保证作业不会相互影响。

3. **Application（Run-Application）模式**：
   - **区别**：Application模式是Flink 1.11及以后版本引入的。在这种模式下，每个作业都会提交给YARN作为一个独立的Application来运行。这种模式与Per-Job模式类似，但它提供了更好的YARN集成，比如更好的日志管理和YARN应用生命周期的管理。
   - **使用场景**：适用于需要更紧密与YARN集成的场景，例如在企业环境中，可能需要更好地控制作业的日志记录和监控。此模式也适用于作业需要更细粒度资源管理的情况。
   
   
```



### yarn -session

```sql
#会话模式场景
在yarn上申请一个flink集群,集群会一直运行,不会随flink提交任务结束而终止。
当你启动一个 Flink Session 集群时，JobManager 和所有配置的 TaskManager 都会启动并保持运行状态。
后续你加入任务，直接加入而不是临时启动。所有的任务共享一个JobManager

#启动session集群
启动session时你可以指定task和job的内存大小，并且指定启动多少个task

当你提交一个任务到 Session 集群时：
- 不会为该任务临时启动新的 JobManager 或 TaskManager。任务会使用已经启动的集群资源。
- 每个提交的任务，不会独享TaskManager 或 JobManager。任务会在可用的 TaskManager slot 中运行。如果有足够的空闲 slot，多个任务可以并行运行。
- 如果集群中的资源（如内存或 CPU）不足以启动新的任务，该任务将等待直到有足够的资源可用。

如果你的任务很小，并且不需要很多资源，你可以在一个 TaskManager 上运行多个任务的实例（通过增加 slot 的数量）。这样可以更有效地利用集群资源。


#启动session集群命令，启动后有UI界面，并且提交的application任务
/bin/yarn-session.sh -nm tiomr_session
#配置启动参数
/yarn-session.sh -n 1 -s 3 -jm 2048 -tm 2048  -nm tiomr_session

#会话模式，会提交到session集群中
（这个目前可能有问题,没有指定session集群，并且和application模式一样，无法判断）
bin/flink run-application -t yarn-application -c Wordcount  a.jar 

其他参数
#指定yarn的lib目录,减少flink依赖包上传时间，其他节点没安装flink没有相关lib
-Dyarn.provided.lib.dirs="hdfs://project1:8020/flink-dist/*"
#指定主类
-c com.atguigu.wc.SocketStreamWordCount
#jar路径可为hdfs路径
hdfs://hadoop102:8020/a.jar

```



### yarn-application

```sql
#使用场景
每个任务单独启动个flink集群和per-job类似
run-application模式下，JobManager 和 TaskManager 是一起的。JobManager 和 TaskManager 运行在同一进程中，共享相同的资源，这种模式适用于单机或小规模的部署。
但是session模式下,JobManager 和 TaskManager是分开的，所有任务共享一个JobManager

#启动命令
bin/flink run-application -t yarn-application -c WordCount a.jar 

#配置启动参数
bin/flink run-application  -n 1 -s 3 -jm 2048 -tm 2048    -t yarn-application -c WordCount a.jar 
这里的-n,-s,-jm,-tm都是配置临时启动的flink集群可用核数

#指定lib路径，减少上传hdfs
-Dyarn.provided.lib.dirs="hdfs://project1:8020/flink-dist/*"
#jar可指定hdfs路径
hdfs://project1:8020/a.jar


#全命令演示
./bin/flink run-application -t yarn-application    -Dyarn.provided.lib.dirs="hdfs://project1:8020/flink_need/flink_jars_lib"      -c FlinkTestMain  hdfs://project1:8020/flink_need/demo_jars/flink_test-1.0.jar

```



### per-job

```sql
#使用场景
单作业模式下，每个应用程序都会启动一个独立的Flink集群，并在应用程序执行完成后自动关闭。
这种模式适用于需要独立部署和管理的单个应用程序，每个应用程序有自己的资源需求和环境要求。

#启动命令
bin/flink run -d -t yarn-per-job -c WordCount a.jar
```



# flink架构

### taskmanager

```sql
#简介
是一个jvm进程，每个taskmanager，都需要启动个yarn的container
slot时taskmanager的线程，taskmanager的jvm可以有多个线程slot,

#注意
虽然多个slot是一个taskmanager的jvm下，但是slot不共享内存，2个算子还是要序列化和反序列化。
可以理解成每个slot是单独的程序，只是在同一个jvm下运行

#案例
yarn-session模式下，启动时设置4个taskmanager,每个4个插槽，共16个slot。你占用15个，剩下一个还是可以提交flink任务的。
因此同一个jvm,不同slot可以执行不同的flink任务，所以slot之间不互通

一个jvm可以执行多个不同的java任务。java a.class指令，每次执行会单独创建一个jvm。可以通过工具提交java任务，到之前的jvm。
这个就是以前不理解的jvm重用，现在理解了。

```





### slot含义

3个map算子到key by 到1个keyed算子，一共4个任务:3+1    3个slot就可以执行

一个slot可以执行多个算子，既可以在map阶段算子，也可以处理reduce阶段的算子。

如果某个算子工作量大，可以不设置slot共享，这样那个算子会单独占用一个slot。

#注意
虽然多个slot是一个taskmanager的jvm下,虽然多个slot共享内存，2个算子还是要序列化和反序列化。
可以理解成每个slot是单独的程序，只是在同一个jvm下运行。

个人理解是flink拆解任务时，不能根据你slot的上下游是否在一个taskmanager中，来优化不用序列化

因为有的是不在一个taskmanager中的，必须序列化，为了统一只能统一都序列化

#案例
yarn-session模式下，启动时设置4个taskmanager,每个4个插槽，共16个slot。你占用15个，剩下一个还是可以提交flink任务的。
因此同一个jvm,不同slot可以执行不同的flink任务，所以slot之间不互通

```
如果没有其他算子也设置为1，那么就为独享
map(s->s).slotSharingGroup("1") 
```

算子最大并行度 = task数*task的slot数

### flink如何确定task数量

当你的并行度为9时，并且session集群的slot参数为2(及每个taskmanager有2个slot)，那么会申请5个task。

并行度/slot数。

注意当禁用算子链，1个task 2个slot，可执行2个算子，slot是线程，虽然2个slot都在一个jvm执行，

但是2个算子还是要序列化和反序列化，通过task的网络栈来传数据。

算子链是很有用的。





# DataStream

### 详细的检查点文献

```
https://www.cnblogs.com/liugp/p/16260166.html#%E4%B8%80flink%E4%B8%AD%E7%9A%84%E7%8A%B6%E6%80%81
可以去看一下
```



### keyed流算子

```mysql
#connect
keyed流进行connect必须也是keyed流(不然会报错),通过process方法,自己存状态，可以实现2流join。
现已确认keyed的流，每个key单独维护一个自己keyed状态。和并行度无关，只和key有关

#join(待整理)
相同窗口,2个流中,key都存在才会关联成功

#intervalJoin
当s1流数据，前后5秒内,来数据就能join到，不然join不到
S1.keyby(id)
	.intervalJoin( s1.keyby(id) )
	.between(Time.seconds(-5),Time.seconds(-5))
	.process()
	
底层就是用2个keyed流进行connect后，实现的可以自己实现一下	

```



### 非keyed流算子

```mysql
#connect



```





### 窗口函数

```sql
#类型模式
计数，计时间

#计数窗口
计数窗口，是全局窗口,执行countWindowAll后，并行度变为1。
如果想多并行度进行，keyby后，执行countWindow方法

#keyby流也有计数窗口
对于keyby后的的流,计时窗口，当不同的key其中一个水位线到了，会触发所有key的窗口关闭，好管理。
如果keyby后计数窗口，那么每个key都有自己的计数器，并且需要独自的窗口关闭，不能关闭所有key

#全局窗口globalwindow
会把key相同的放在一个窗口。默认是不关闭的，需要自己定义触发器。countWindow就是globalwindow实现的。

#底层窗口
滑动，滚动，都是窗口分配器+触发器实现的，没有基础实现的窗口接口了




```

### watermark

watermark是用来保证事件时间乱序到齐的一种策略，并不一定要和窗口结合用。

不过事件时间窗口，是经常需要处理乱序事件的，所以经常连用。

如果不设置watermark那么窗口可能因为乱序提前关闭。



watermark即当前真实时间 =   当前最大事件时间 - 延迟处理

案例：窗口是1-10  延迟为3  那么当有一个15的事件时间来时，会把当前真实时间推到12，

比12小的窗口都会关闭。



### Pojos

```sql
在 Apache Flink 中，POJO（Plain Old Java Object）类是一种普通的 Java 类，用于表示数据流中的元素。POJO 类在 Flink 中有一些规定和要求，以便能够正确地进行序列化、反序列化和处理。以下是一些常见的规定：

#无参构造器
必须有一个无参数的默认构造函数：Flink 使用反射来创建 POJO 对象，因此必须提供一个无参数的默认构造函数。
#字段为public或设置getter/setter
所有字段必须是公共的（public）或者有相应的 getter 和 setter 方法：Flink 使用反射来访问字段，因此字段必须是公共的，或者有对应的 getter 和 setter 方法。
#字段为flink支持的类型
字段必须是 Flink 支持的类型：基本类型,集合类型,Flink的特定类型（如 Tuple、Row 等）或者pojo类型
若不是这些类型，需要实现接口（如 Serializable、Value 等）来进行序列化和反序列化。
#不需要实现serializable
满足以上,会自动识别为Pojo,不需要实现searizible

```



### 状态编程

```sql
目前状态分为2类，keyed状态，非keyed状态，两种注册方式不一样。也可以自定义状态自己管理

#keyed流状态
keyed的流注册状态，每个key单独享有一个状态。
目前状态有：value,list,map,Aggregating，Reducing

#TTL(对上面所有的state做控制用的)
这个是对keyed流中,若某个key的状态很久没有使用了，定期会删除。
但是我想要的情况，是ListState中某些数据过期后,把list中过期数据清除，然后新建一个更小的list替换当前这个很大内存的list

#非keyed流状态
非keyby的流，注册的状态，共享一个
目前状态有:list,UnionList,broadcast

#注意区分广播状态和广播流
```



### flink状态管理

```mysql
托管状态,自控状态
托管分区keyed和operateState
```



### TTL

```sql
#存在背景
TTL为了防止内存无限制扩大

#案例1 
对于按键分区的流，比如记录每个用户24小时内浏览的页面，放入liststate中。设置ttl为24小时
如果24小时内，这个用户没有数据来,那么这个listState就会删除，节省空间

#案例2
如果我想要ListState中的元素，每个按照过期时间删除，目前flink的TTL不支持，只能手动实现。
手动实现通过定时器list.remove删除，并不会节省内存，因为数组长度已经固定了。
但是可以存在rocksDB，除了临时缓存，其他放不下的数据是存在磁盘的，最终的list.remove会传递到rockDB磁盘

```



### statebackend



```sql
 #误区
 状态后端只是选择状态的存储方式,比如memoryStateBackend,HashMapStateBackend都是设置内存级的后端，为了快
 fsStateBackend  fs是为了省内存,只维护小状态，大状态将数据存在磁盘临时读取,
 RocksDBStateBackend,EmbeddedRocksDB,是hbase理念，设置缓存,有近乎内存的速度，大部分还是存在磁盘。
 
 并且source端的消费进度,是检查点的barrier记录的,状态后端不会记录source消费进度
 就算设置为fsStateBackend,状态存在本地磁盘。不设置checkpoint,故障重启时flink也不知道从哪个位置加载状态。
 
RocksDBStateBackend，memoryStateBackend，fsStateBackend已经过时了。目前推荐的是hashmap和EmbeddedRocksDB

 fsStateBackend
 RocksDBStateBackend
memoryStateBackend
HashMapStateBackend
这4个区别，hash和memory都是把数据直接存在内存上。而rockdb是个数据库体系，只存索引，具体的数据存在硬盘，查询时先查索引，然后再查磁盘位置。
RocksDBStateBackend适合存大状态

```



### checkpoint

checkpoint就是对状态的快照保存。statebackend就是状态的使用以及容错方式的指定

- **作用**: 检查点是 Flink 容错机制的核心。它是在特定时间点对状态的一致性快照。如果发生故障，Flink 可以从最近的检查点恢复状态和计算，从而保证了数据处理的精确一次性（exactly-once）语义。
- **实现**: 当执行检查点时，Flink 会调用状态后端来持久化状态信息。对于 `HashMapStateBackend`，状态被持久化到配置的检查点存储位置（如分布式文件系统）。对于 `RocksDBStateBackend`，状态已经存储在磁盘上，因此检查点主要涉及将状态的增量变化持久化到远程存储。
- 检查点会存储哪些数据：状态，kafka消费偏移量等
- Operator State: 每个操作符（如map, reduce, filter等）可以有自己的状态，这些状态包括列表、映射等数据结构，用于保存中间计算结果。在checkpoint时，这些状态会被保存。

  Keyed State: 对于需要根据键值进行分区的操作符，Flink 会为每个键值维护一个状态。这种状态通常用于需要按键分组的操作，如 keyed windows 或 aggregations。checkpoint 会保存所有键的状态。

  Buffered Data: 数据在流向下一个操作符之前可能会在网络缓冲区中缓存。在checkpoint时，这些缓存的数据也会被保存，以确保在恢复时数据不会丢失。



##### barrier三种方式

去看前面详细文章地址，有图。看懂了为什么要对齐了，因为不然状态记录的不准。

exactly once的实现，就是通过barrier对齐。

barrier对齐，最大的难度就是多并行度，下一个算子变为1个并行多。比如2个并行度合并到1个。当a的barrier来时，不会记录状态，这时候a后面的数据不进行处理进行缓存，当b的barrier来了,这时记录此时算子所有的状态.



atleast once就是不等barrier对齐，所以可能会重复消费的。

```sql
barrier是一个触发检查点保存的数据结构,由jobmaster发送给所有task的source源头,保存source的偏移量，遇到shuffle会广播给下游所有shuffle算子。
所以下游算子要等上游所有分支都到到齐后才开始保存状态，这时候会把数据做缓存不处理

等待barrier到齐。 因此当出现背压的时候，可能导致barrier那个数据结构无法走到下游，检查点不处罚保存。

#这里word还是没看懂，待后续补上
```

设置检查点时，checkpointMode 有exactly-once 和at-least-once 默认是精准一次，至少一次处理效率更高，吞吐量更大。

exactly-once能保证事件只被消费一次,at-least-once可能出现重复消费，不过吞吐量更大。



##### savepoint

和checkpoint原理一样，不过手动触发，具体场景是调整并行度，更新flink版本等。

手动触发操作，在word里

### changelog

- **作用**: Changelog 是 Flink 1.12 引入的一种新的状态后端（如 `ChangelogStateBackend`），它记录状态的变化日志，不仅仅是定期的检查点。这使得 Flink 可以在故障恢复时更加灵活和高效，因为它可以使用这些变化日志来恢复状态，而不是从完整的检查点状态开始。
- **实现**: Changelog 状态后端通常与其他状态后端结合使用，比如 `HashMapStateBackend` 或 `RocksDBStateBackend`。它记录每个状态更新的变化日志，并定期与检查点一起持久化。这样，即使在检查点之间发生故障，也能够利用这些变化日志来恢复到最新的状态。

每次保存checkpoint都是完整保存，那么用时太久了，开启changelog可以只保存状态的变化，更快的保存。

要引入依赖，并且代码里开启









# TableAPI

### 理解

```mysql
sql 会转化为tableAPI ,而table API的底层join等，也不是用通过dataStreamAPI 用connect流实现的，而是更底层的控制
```



### savepoint

flink客户端，关闭任务时，执行save point,要事先设置save point制定路径，不然会报错。

如果临时执行reset save point ,后面要重置为空，不然后面所有的作业，都以这个save point路径保存

### catalog

catalog不持久化，下次进去就删除，但是表不删除。建了同名的cataloge，tables就出现了

flink能对接hive表,不过flink不是个流吗？难道能监控hive表中数据变化吗？



### 待解决问题

```mysql
#找表不到
2个kafka流能正常join，但是一个kafka lookup join另一个mysql，显示找不到kafka的表。

#建表和查询一起
excute( create table select * from a )和 sqlQuery (select * from a)之后再执行createTemporyview区别？？？
我现在想create一个table，通过select语句好像不行,建表一定要指定类型。可以先query查询，然后再创建视图来做

```

### 细节需注意

```mysql
#upsert-kafka
uperset-kafka能更新kafka消息，如果是实时的，我已经消费了怎么撤回呢？还是我理解错了

#sql中创建表要求
1 字段和类型中间只能有1个空格，不能多
2 data map<String,String>
3 maxwell监控的字段有table,type,建表时应该用‘table’使用时也是‘table’
4 关键字 partition,order注意， mock_order as order，检验的时候报错
```



### explain执行计划

```mysql
是的，Flink 提供了 `EXPLAIN` 命令，它可以用来查看 Table API 或 SQL 查询的逻辑和物理执行计划。执行计划为你提供了查询的详细信息，包括查询将如何被转化为底层的 DataStream API 操作。

要使用 `EXPLAIN` 命令，你可以在 TableEnvironment 上调用 `explain` 方法。这个方法可以接受一个 Table 对象或者一个 String 类型的 SQL 查询，并返回一个描述执行计划的字符串。

String explanation = tableEnv.explainSql("SELECT * FROM YourTable WHERE ...");
System.out.println(explanation);


执行计划通常包含以下几个部分：
1. **Abstract Syntax Tree (AST)**：这是 SQL 查询或 Table API 调用的抽象语法树表示，反映了用户的原始意图。
2. **Optimized Logical Plan**：这是优化器处理 AST 后的结果，它会应用各种优化规则来改进查询的执行效率。
3. **Physical Plan**：这是逻辑计划的物理实现，它包括了具体的算子和它们的配置，比如过滤、聚合、连接等。
4. **Execution Plan**：这是最终的执行计划，它会被提交到 Flink 集群上执行。这部分包括了任务的并行度、数据的分区策略等具体的运行时信息。
通过查看这些执行计划，你可以更好地理解 Flink 是如何处理你的查询的，以及可能在哪些地方进行了优化。这对于调试查询性能问题非常有用。


#案例：2个kafka流join
 select 
 mock_order.data['orderno'],
mock_order.data['spuid'],
mock_cupon.data['activity']
from mock_order 
join mock_cupon 
on mock_order.data['orderno'] = mock_cupon.data['orderno'] 

#执行计划
== Abstract Syntax Tree ==
LogicalProject(EXPR$0=[ITEM($0, _UTF-16LE'orderno')], EXPR$1=[ITEM($0, _UTF-16LE'spuid')], EXPR$2=[ITEM($2, _UTF-16LE'activity')])
+- LogicalJoin(condition=[=($1, $3)], joinType=[inner])
   :- LogicalProject(data=[$2], $f1=[ITEM($2, _UTF-16LE'orderno')])
   :  +- LogicalFilter(condition=[=($1, _UTF-16LE'mock_order')])
   :     +- LogicalTableScan(table=[[default_catalog, default_database, kafka_maxwell]])
   +- LogicalProject(data=[$2], $f1=[ITEM($2, _UTF-16LE'orderno')])
      +- LogicalFilter(condition=[=($1, _UTF-16LE'mock_cupon')])
         +- LogicalTableScan(table=[[default_catalog, default_database, kafka_maxwell]])

== Optimized Physical Plan ==
Calc(select=[ITEM(data, _UTF-16LE'orderno') AS EXPR$0, ITEM(data, _UTF-16LE'spuid') AS EXPR$1, ITEM(data0, _UTF-16LE'activity') AS EXPR$2])
+- Join(joinType=[InnerJoin], where=[=($f1, $f10)], select=[data, $f1, data0, $f10], leftInputSpec=[NoUniqueKey], rightInputSpec=[NoUniqueKey])
   :- Exchange(distribution=[hash[$f1]])
   :  +- Calc(select=[data, ITEM(data, _UTF-16LE'orderno') AS $f1], where=[=(table, _UTF-16LE'mock_order':VARCHAR(2147483647) CHARACTER SET "UTF-16LE")])
   :     +- TableSourceScan(table=[[default_catalog, default_database, kafka_maxwell]], fields=[database, table, data, type, ts])
   +- Exchange(distribution=[hash[$f1]])
      +- Calc(select=[data, ITEM(data, _UTF-16LE'orderno') AS $f1], where=[=(table, _UTF-16LE'mock_cupon':VARCHAR(2147483647) CHARACTER SET "UTF-16LE")])
         +- TableSourceScan(table=[[default_catalog, default_database, kafka_maxwell]], fields=[database, table, data, type, ts])

== Optimized Execution Plan ==
Calc(select=[ITEM(data, 'orderno') AS EXPR$0, ITEM(data, 'spuid') AS EXPR$1, ITEM(data0, 'activity') AS EXPR$2])
+- Join(joinType=[InnerJoin], where=[($f1 = $f10)], select=[data, $f1, data0, $f10], leftInputSpec=[NoUniqueKey], rightInputSpec=[NoUniqueKey])
   :- Exchange(distribution=[hash[$f1]])
   :  +- Calc(select=[data, ITEM(data, 'orderno') AS $f1], where=[(table = 'mock_order')])
   :     +- TableSourceScan(table=[[default_catalog, default_database, kafka_maxwell]], fields=[database, table, data, type, ts])(reuse_id=[1])
   +- Exchange(distribution=[hash[$f1]])
      +- Calc(select=[data, ITEM(data, 'orderno') AS $f1], where=[(table = 'mock_cupon')])
         +- Reused(reference_id=[1])
```



### 数据类型

```mysql
#map
声明 data map<String,String>
使用 data["id"]
```





### FlinkTable优化

```mysql
#窗口优化
滑动窗口的时候步长和时间要是整数，这样TVF的API会优化，把滑动窗口，切分成多个滚动窗口，这样不会有太多重复数据

#tableAPi设置checkPoint
和流一样，在env设置checkpoint
```

# sql语法

#### 基本语法

```mysql
#代码语法
tableEnv.excuteSql() 执行sql，返回一个结果集
tableEnv.sqlQuery() 返回的是一个table，不一样
tableEnv.explainSql()

#设置checkpoint
直接env设置checkpoint就行

#设置ttl
目前只支持窗口设置ttl吗？不清楚


#sql语法
create tb(
	id string,
  pt as proctime(), --处理时间
  et as cast(currrent_timestamp as timestamp(3)), --当前时间转为timestamp(3)
  watermark for et as et - interval '0.1' second , --watermark延迟，把上面的et作为事件时间

)

```



#### join的几种

~~~mysql
### join的几种

```mysql
#lookup join
当2个表通过lookup join时，会根据关联key，实时查询维度表。lookup join后的就是维度表

固定写法：
SELECT o.order_id, o.total, c.country, c.zip
FROM Orders AS o
JOIN Customers FOR SYSTEM_TIME AS OF o.proc_time AS c
ON o.customer_id = c.id;

Lookup Join（临时访问）:
当你在Flink SQL中执行一个维度表关联查询时，默认情况下，Flink会使用所谓的lookup join。这意味着对于流中的每条消息，Flink会发起一个查询到外部系统（在这种情况下是MySQL）来检索关联的维度数据。这是一个同步的操作，可能会因为网络延迟或外部系统的查询性能而影响整体的处理延迟。
Temporal Join with Versioned Tables:
如果你使用时态表（temporal table）的概念，Flink可以利用MySQL中的数据变化来处理时态关联。这通常需要在MySQL中有一个变化数据捕获（CDC）机制的支持，比如使用Debezium来捕获变化并将其发送到Kafka，然后Flink从Kafka中读取这些变化。这种方法允许Flink处理维度数据的历史变化，但它不会将整个MySQL表加载到状态中。
Caching:
Flink SQL也支持在状态后端中缓存维度数据，以减少对外部系统的访问次数。这可以通过配置lookup join的缓存策略来实现，例如，可以定义缓存大小和过期时间。这种方法可以减少对MySQL的查询次数，但是会增加Flink状态的大小，并且需要处理缓存数据可能过时的问题。
```


~~~

