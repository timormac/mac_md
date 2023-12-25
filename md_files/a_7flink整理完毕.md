# 整理进度

a3包的广播



# 问题待解决

### 计数时间滑动窗口怎么做

需求:1分钟内  登陆超过35次认为是爬虫

直观思路   每来一个事件开个1分钟的窗口,窗口关闭统计次数和35比较

目前不能实现，需要转换思路。

### intervalJoin又是什么



### connect是怎么运行的

应该有理解错误,connect流和join流是2个东西。最好别弄混了

2个keyed流,会把key同的流数据放到一块， 每个key单独一个小区域,  可以理解

那么当一个keyed流，一个dataStream，这个connect怎么走呢？？



### FlinkKafkaConsumer过时

实现sourceFunction的kafka有3个,FlinkKafkaShuffleConsumer，FlinkKafkaConsumer，FlinkKafkaConsumerBase

FlinkKafkaConsumer过时了

FlinkKafkaShuffleConsumer是他的继承类，不过没有public构造器,也没找到buider不知道怎么办

### 想要的TTL

#TTL(对上面所有的state做控制用的)
这个是对keyed流中,若某个key的状态很久没有使用了，定期会删除。
但是我想要的情况，是ListState中某些数据过期后,把list中过期数据清除，然后新建一个更小的list替换当前这个很大内存的list



### 广播状态和广播流

这2个区分一下

### 不keyby想用mapstate

不keyby想用state会报错



### reduce/Aggregate的state用途

目前感觉valueState + 逻辑可以代替这2个



### checkpoint的2种barrier区别

这个没搞懂



# 问题已解决

### sink接口无实现类

找到问题了，下面还有个sinkTo方法是接sink2.Sink的

```java
在DataStream的sinkTo方法，需要实现connector.sink.Sink接口，打开idea去看,发现没有实现类。
用KafkaSink.build创建的KafkaSink,看源码是：
public class KafkaSink  implements StatefulSink,TwoPhaseCommittingSink{}
这两个接口实现的是connector.sink2.Sink,是2个不同的包的Sink接口，但是idea没报错。
```



# 代码案例

### 端到端精准一次

如果是hdfs，那么用预写日志完成事务，还要结合幂等操作等，自己一个预习日志是不能完成精准事务的。

### kafka如何实现精准一次

写入kafka时

# flink架构

### taskmanager

是一个jvm进程，每个taskmanager，都需要启动个yarn的container

slot时taskmanager的线程，taskmanager的jvm可以有多个线程slot

### sloth含义

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

