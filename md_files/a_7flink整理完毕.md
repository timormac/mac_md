# 整理进度

a3包的广播



# 问题待解决

### 计数时间滑动窗口怎么做

需求:1分钟内  登陆超过35次认为是爬虫

直观思路   每来一个事件开个1分钟的窗口,窗口关闭统计次数和35比较

目前不能实现，需要转换思路。

### intervalJoin又是什么

```
Apache Flink 是一个流处理框架，它支持多种类型的流数据连接（join）操作。在 `keyBy` 操作之后，流数据被分区到不同的任务中，以便可以进行更有效的处理。以下是 Flink 中 `keyBy` 之后可以使用的一些 join 操作类型及其区别：

1. **Window Join**：在有限的窗口范围内连接两个流。窗口可以是时间窗口（例如，10分钟的滚动窗口）或者是其他类型的窗口。窗口 join 通常用于连接两个流的元素，这些元素在某个时间段内是相关的。

2. **Interval Join**：在指定的时间区间内连接两个流。与窗口 join 类似，但是它允许每个元素定义一个时间范围，而不是使用固定的窗口大小。

3. **Join Function**：可以自定义一个 join 函数来指定如何连接两个流的元素。这通常是在 `DataStream` API 中使用 `join` 操作时进行的。

4. **CoGroup Function**：类似于 SQL 中的 `FULL OUTER JOIN`，`coGroup` 允许你为两个流的每个键分别分组元素，然后可以在结果迭代器上执行操作。

这些 join 操作的主要区别在于它们如何处理时间和窗口约束，以及它们如何处理流中的元素。

除了 join 操作，Flink 还提供了 `connect` 操作，它可以将两个保持它们类型的流连接在一起。`connect` 与 join 的主要区别在于：

- **Connect**：
  - `connect` 操作只能用于两个流。
  - 连接后的流会保持各自的数据类型，生成一个 `ConnectedStreams` 对象。
  - `ConnectedStreams` 可以使用 `CoMap` 或 `CoFlatMap` 函数来处理两个流的数据，这些函数可以处理两种类型的数据，并且可以共享状态。
  - `connect` 更适用于当两个流的数据需要被共同处理，但不需要按键进行连接的情况。

- **Join**：
  - join 操作是针对两个流的元素按键进行配对。
  - join 结果是一个新的数据流，并且结果流的类型是两个输入流元素类型的组合。
  - join 操作通常用于当你需要将两个流中相关的元素结合起来时。

总之，选择 join 还是 connect 取决于你的具体需求，例如是否需要按键连接元素、是否需要处理不同类型的数据流，以及是否需要在特定的时间窗口内处理数据。
```



### connect是怎么运行的

应该有理解错误,connect流和join流是2个东西。最好别弄混了

2个keyed流,会把key同的流数据放到一块， 每个key单独一个小区域,  可以理解

那么当一个keyed流，一个dataStream，这个connect怎么走呢？？



### FlinkKafkaConsumer过时

实现sourceFunction的kafka有3个,FlinkKafkaShuffleConsumer，FlinkKafkaConsumer，FlinkKafkaConsumerBase

FlinkKafkaConsumer过时了

FlinkKafkaShuffleConsumer是他的继承类，不过没有public构造器,也没找到buider不知道怎么办



### 不keyby想用mapstate

不keyby想用state会报错



### checkpoint的2种barrier区别

这个没搞懂



# 问题已解决(待回顾)



### 想要的TTL

```sql
#存在背景
TTL为了防止内存无限制扩大

#想要的TTL
但是我想要的情况，是ListState中某些数据过期后,把list中过期数据清除，然后新建一个更小的list替换当前这个很大内存的list

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

```

### 复杂问题



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



### kafka精准一次

写入kafka时



# flink-yarn启动模式

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

当你提交一个任务到 Session 集群时：
- 不会为该任务临时启动新的 JobManager 或 TaskManager。任务会使用已经启动的集群资源。
- 每个提交的任务，不会独享TaskManager 或 JobManager。任务会在可用的 TaskManager slot 中运行。如果有足够的空闲 slot，多个任务可以并行运行。
- 如果集群中的资源（如内存或 CPU）不足以启动新的任务，该任务将等待直到有足够的资源可用。

如果你的任务很小，并且不需要很多资源，你可以在一个 TaskManager 上运行多个任务的实例（通过增加 slot 的数量）。这样可以更有效地利用集群资源。


#启动session集群命令，启动后有UI界面，并且提交的application任务
/bin/yarn-session.sh -nm tiomr_session

#会话模式，会提交到session集群中
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

是一个jvm进程，每个taskmanager，都需要启动个yarn的container

slot时taskmanager的线程，taskmanager的jvm可以有多个线程slot

### slot含义

3个map算子到key by 到1个keyed算子，一共4个任务:3+1    3个slot就可以执行

一个slot可以执行多个算子，既可以在map阶段算子，也可以处理reduce阶段的算子。

如果某个算子工作量大，可以不设置slot共享，这样那个算子会单独占用一个slot。

```
如果没有其他算子也设置为1，那么就为独享
map(s->s).slotSharingGroup("1") 
```

算子最大并行度 = task数*task的slot数

### flink如何确定task数量

当你的并行度为9时，并且你的slot参数参数为2，那么会申请5个task。

并行度/slot数。

注意当禁用算子链，1个task 2个slot，可执行2个算子，slot是线程，虽然2个slot都在一个jvm执行，

但是2个算子还是要序列化和反序列化，通过task的网络栈来传数据。

算子链是很有用的。





# DataStream

### 窗口函数

```sql
#类型模式
计数，计时间





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

总结一下，状态后端负责实时管理状态，检查点负责周期性地持久化状态以便故障恢复，而 Changelog 提供了一种更细粒度的状态变化记录，允许在检查点之间进行更快的状态恢复。这三者共同构成了 Flink 的强大容错和状态管理体系。

```sql
 #作用
 状态后端负责管理和维护所有的状态信息。它定义了状态的存储方式（内存、磁盘等），以及状态在故障恢复时如何被访问和恢复。
 
 #声明状态后端
 如果注册了状态变量，当不设置状态后端时，默认时memoryStateBackend,这个不好用。在进行checkpoint时，状态会被序列化后存储到JobManager的内存中，会出现丢失情况
 #HashMapStateBackend
 我们可以手动设置HashMapStateBackend（将状态保存在 JVM 堆内存中)，与检查点存储，如FileSystemCheckpointStorage结合用
 HashMapStateBackend有内存的速度，还可以定期存在文件中，使用只用内存，存文件中是用来恢复。
 #EmbeddedRocksDB
 EmbeddedRocksDB是走内嵌的rocksDB磁盘存状态后端的,和hbase差不多有缓存，可以存很大的状态后端，而hashmap不行。
 虽然已经存在本地的rocksdb，但是因为节点可能故障，所以还是要存在检查点里面。
 
 RocksDBStateBackend，memoryStateBackend，fsStateBackend已经过时了。目前推荐的是hashmap和EmbeddedRocksDB
 
 #statebackend和checkpoint关系
 当你选择状态后端模式时，如果你不开启checkpoint，那么将不会把状态后端保存，故障时会出现无法恢复(即使是rockdb也可能节点故障)
 当你开启checkpoint后，会自动将状态后端存在checkpoint的指定位置，checkpoint主要就是存状态后端的的，其次还有一些其他的东西。
 
```

### changelog

- **作用**: Changelog 是 Flink 1.12 引入的一种新的状态后端（如 `ChangelogStateBackend`），它记录状态的变化日志，不仅仅是定期的检查点。这使得 Flink 可以在故障恢复时更加灵活和高效，因为它可以使用这些变化日志来恢复状态，而不是从完整的检查点状态开始。
- **实现**: Changelog 状态后端通常与其他状态后端结合使用，比如 `HashMapStateBackend` 或 `RocksDBStateBackend`。它记录每个状态更新的变化日志，并定期与检查点一起持久化。这样，即使在检查点之间发生故障，也能够利用这些变化日志来恢复到最新的状态。

每次保存checkpoint都是完整保存，那么用时太久了，开启changelog可以只保存状态的变化，更快的保存。

要引入依赖，并且代码里开启



### checkpoint

checkpoint就是对状态的快照保存。statebackend就是状态的使用以及容错方式的指定

- **作用**: 检查点是 Flink 容错机制的核心。它是在特定时间点对状态的一致性快照。如果发生故障，Flink 可以从最近的检查点恢复状态和计算，从而保证了数据处理的精确一次性（exactly-once）语义。
- **实现**: 当执行检查点时，Flink 会调用状态后端来持久化状态信息。对于 `HashMapStateBackend`，状态被持久化到配置的检查点存储位置（如分布式文件系统）。对于 `RocksDBStateBackend`，状态已经存储在磁盘上，因此检查点主要涉及将状态的增量变化持久化到远程存储。
- 检查点会存储哪些数据



##### barrier三种方式(有未看懂的)

这个和代码里的checkpoint的mode有什么关系，算法怎么实现的。

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







# TableAPI

### 查看执行计划

```
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
```

