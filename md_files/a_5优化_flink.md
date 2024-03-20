# 学习进度

反压的定位涉及内存那块没太懂

checkpoint和状态编程还有barrier重听

到p21数据倾斜



# 待解决问题

#### checkpoint增量和全存

在p9里，chekpoint增量不应该把所有的增量都保存吗。

全存只需要把当前状态更新一次就行，感觉数据多了之后，全存应该更好。

checkpoint全存会不会删除之前的检查点，gpt说会留3个



#### 两阶段提交事务是什么

如果下游不支持事务呢，怎么两阶段提交，什么场景需要两阶段提交。举个demo

两阶段提交案例

```
两阶段提交（Two-Phase Commit，简称2PC）是分布式计算领域中用于确保分布式系统中的事务的原子性的一种协议。在Apache Flink中，两阶段提交通常用于保证在状态管理和容错计算中数据的一致性，特别是在需要确保精确一次（exactly-once）语义的输出时。

### 两阶段提交的工作原理：

1. **准备阶段（Prepare Phase）**：
    - 事务协调者（通常是Flink作业的一个组件）向所有参与者（可以是不同的存储系统，如数据库、消息队列等）发出事务准备请求。
    - 每个参与者执行事务操作，并将数据写入到日志中，但不提交事务，然后回复协调者它已经准备好。

2. **提交阶段（Commit Phase）**：
    - 一旦协调者从所有参与者接收到准备好的确认，它就会发出提交请求。
    - 参与者根据协调者的请求提交事务，并将结果回复给协调者。
    - 如果所有参与者都成功提交，整个分布式事务就成功了；如果有任何参与者失败，协调者可以决定中止事务，并通知所有参与者回滚。

### 需要两阶段提交的场景：

两阶段提交通常在以下场景中使用：

- 当需要跨多个分布式组件（如数据库、消息系统等）进行事务操作时。
- 当需要确保事务要么完全成功要么完全失败，不留下中间状态时。
- 当Flink作业需要向外部系统提供精确一次的输出语义时。

### 举例案例：

假设有一个Flink作业，它读取Kafka中的实时交易数据，并需要将计算结果同时写入到两个外部系统中：一个是Elasticsearch用于搜索和分析，另一个是关系型数据库用于事务处理。

为了确保数据的一致性和完整性，你不能只是简单地将数据写入这两个系统，因为这可能会在发生故障时导致不一致的状态。比如，如果数据已经写入Elasticsearch，但在写入数据库时Flink作业失败了，那么这两个系统的数据就会不一致。

使用两阶段提交协议，Flink作业会首先在两个系统中准备事务，确保它们都可以提交。只有在两个系统都准备好之后，Flink作业才会通知它们提交事务。如果其中任何一个系统在准备阶段失败，Flink作业可以决定中止整个事务，并确保两个系统都不会提交任何数据，从而保持数据的一致性。

在实际操作中，Flink提供了`TwoPhaseCommitSinkFunction`，这是一个用于实现两阶段提交的抽象基类，用户可以根据需要向不同的外部系统扩展这个基类。通过这种方式，Flink可以确保即使在发生故障的情况下，也能够提供精确一次的处理语义。
```

hdfs不支持两阶段提交

```
Flink 提供了与 HDFS（Hadoop Distributed File System）集成的功能，可以将数据写入 HDFS。然而，Flink 本身并不提供针对 HDFS 的内置两阶段提交机制。

在 Flink 中，数据的写入通常是通过 Flink 的 Sink 函数来实现的。Flink 提供了多种 Sink 函数，包括将数据写入文件系统（如 HDFS）、消息队列、数据库等。

对于将数据写入 HDFS，Flink 提供了 `org.apache.flink.streaming.connectors.fs.bucketing.BucketingSink` 和 `org.apache.flink.streaming.connectors.fs.RollingSink` 这两个 Sink 函数。这些 Sink 函数可以将数据以批量或滚动的方式写入 HDFS。

然而，需要注意的是，这些 Sink 函数并没有内置的两阶段提交机制。如果需要在 Flink 中实现 HDFS 上的数据写入的两阶段提交，可能需要自行实现相应的机制。一种常见的做法是使用外部的分布式事务协议，如 Apache Hudi、Apache Gobblin 等，来实现数据写入 HDFS 的两阶段提交。

这些外部的分布式事务协议可以与 Flink 集成，并提供了更高级别的数据一致性保证。通过使用这些协议，可以在 Flink 中实现将数据写入 HDFS 的两阶段提交，以确保数据的原子性和一致性。
```



#### barrier对齐是什么？

#### checkpoint的extract once

#### 可用插槽和slot也是0

看了下视频里的flink界面的可用插槽和slot也是0



#### flink任务参数作用

指定taskmanager内存 还有核数 ，到时候会生成几个container



# 已解决问题



# 设计优化

### 状态大小

```sql
#解决方法
1 合理设置ttl 时间
2 可以对listState里用RockDB，并且设置定时器定期删除list中老数据，注意必须用rockRB ，详情看md文档
3 增量checkpoint
4 选择合理的state，如果比较大用rockdb，不会内存溢出


"状态过大的危害"
#内存oom
内存和状态后端压力增大（MemoryStateBackend）或者 RocksDB（RocksDBStateBackend）中。状态增长过大可能导致内存不足，甚至可能导致 OutOfMemoryError，从而影响 Flink 任务的稳定性。

#频繁gc影响性能
垃圾回收压力增大**：对于基于 JVM 的状态后端，如 MemoryStateBackend，大量状态可能导致频繁的垃圾回收（GC），这会影响任务的性能，导致处理延迟增加。

#checkpoint备份慢
**Checkpoint 延迟**：Checkpoint 是 Flink 确保容错的机制，它会定期保存状态的快照。如果状态过大，Checkpoint 的时间会增长，这不仅影响了作业的处理时间，也可能导致 Checkpoint 间隔的延迟，从而影响恢复时间（Recovery Time Objective, RTO）。

#恢复变慢
**恢复时间增长**：在发生故障时，Flink 需要从最近的 Checkpoint 恢复状态，如果状态过大，恢复的时间也会随之增加，影响系统的快速恢复能力

#hdfs存储浪费
**存储资源消耗**：大状态意味着需要更多的存储资源来保存 Checkpoint 数据，这可能导致存储成本增加，特别是当使用外部持久化存储（如 HDFS）时。

```



### 状态管理

```mysql
memory
hashmap
emroccksdb
fsstate 
过期状态等，是由数据来了，才能触发清理操作，也可以设置为定时触发。
不然对一些ttl的状态比如key为 小时｜用户id，并不会清理掉。
```





# 参数优化

### 内存模型

具体看word

### 查看内存使用率

```sql
flink run \
-t yarn-per-job \  --不同flink版本提交指令不同，这个是统一的提交方式
-d \
-p 5 \ 指定并行度
-Dyarn.application.queue=test \ 指定 yarn 队列
-Djobmanager.memory.process.size=2048mb \ JM2~4G 足够
-Dtaskmanager.memory.process.size=4096mb \ 单个 TM2~8G 足够
-Dtaskmanager.numberOfTaskSlots=2 \ 与容器核数 1core：1slot 或 2core：1slot
-c com.atguigu.flink.tuning.UvDemo \
/opt/module/flink-1.13.1/myjar/flink-tuning-1.0-SNAPSHOT.jar


#如何确定内存分配情况
在flink task manager看内存使用率，来确定内存分配是否过多。

#如何有效利用内存
队友有的状态后端，如果不用rocksdb，可以把有一个默认的0.1内存给设置为0，不然就是浪费了，永远用不上。

#如何设置并定度与task里面的core数
一个taskmanager 对应一个yarn container。一个contaioner里可以设置多个插槽。比如并行度是5，一个容易有3个核，那么2个taskemanager就可以了。但是为什么每个容器申请3个核，最后yarn只给一个核呢，和yarn的调度器规则有关系。
具体原因："在flink调优的p4里5分钟开始"

```



### checkpoint设置间隔

若设置太长1h的话，虽然io少，但是那一次执行的时间会特别长，那一下的延迟会特别高。

如果设置太短，那么延迟会小，不过次数多，总体费时会增加。



### 定位背压原因

找到背压的算子节点，然后可以UI界面看每个并行度节点的数据输入和输出数量，来看是否倾斜

火焰图flamegragh定位问题



##### 外部对接交互慢

比如hbase rowkey热点问题，rowkey设计不合理，不够散列

kafka是否分区少，导致并行低，速度不够

代码问题，比如创建连接不释放,导致hbase的链接打满了进不去。可以去hbase查看当前链接



# 代码优化

纬表关联，可以加一个缓存在open里在开启时把数据库纬度表加载到map里或者用guava的缓存，然后用流来更新纬表变化。

