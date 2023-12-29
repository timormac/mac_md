# 课程进度

到p108容错机制 p108跳过了

109到114的检查点算法听的不太懂，后续有机会自己消化一下

p166-169没听

# 注意事项

### kafka的配置在哪找

在import org.apache.kafka.clients.consumer.ConsumerConfig里可以看到，property里面可以设置哪些配置



### checkponit和rockdb

Checkpoint 是 Flink 中的一种机制，用于将任务的状态异步地持久化到持久化存储系统，以实现任务的容错性。Checkpoint 会将任务的状态数据写入到持久化存储中，以便在任务失败或重启时进行恢复。

RocksDB 是 Flink 中的一种状态后端（State Backend），它用于将任务的状态数据持久化到本地磁盘上。RocksDB 状态后端使用 RocksDB 数据库引擎来管理状态数据的存储和访问。

区别如下：

1. **Checkpoint**：Checkpoint 是 Flink 中的容错机制，用于将任务的状态异步地持久化到持久化存储系统。Checkpoint 可以将状态数据持久化到分布式文件系统、对象存储或其他支持的存储系统中。它是一种任务级别的持久化机制，可以保证任务的状态在失败或重启时能够恢复。
2. **RocksDB**：RocksDB 是 Flink 中的一种状态后端，用于将任务的状态数据持久化到本地磁盘上。RocksDB 使用 RocksDB 数据库引擎来管理状态数据的存储和访问。RocksDB 状态后端可以提供更高的状态容量，并且可以有效地处理大规模的状态。

总结起来，Checkpoint 是 Flink 的容错机制，用于将任务的状态持久化到持久化存储系统，而 RocksDB 是 Flink 的一种状态后端，用于将任务的状态数据持久化到本地磁盘上。Checkpoint 可以选择使用 RocksDB 状态后端来实现状态的持久化。



```
Apache Flink 是一个分布式流处理框架，用于在高吞吐量和低延迟的情况下进行大规模数据处理。为了保证数据处理的一致性和容错性，Flink 提供了一种名为 "checkpoint" 的机制来定期捕获应用程序状态的快照。

当开启 Flink 的 checkpoint 机制时，以下几个方面的信息会被定期保存：

Operator State: 每个操作符（如map, reduce, filter等）可以有自己的状态，这些状态包括列表、映射等数据结构，用于保存中间计算结果。在checkpoint时，这些状态会被保存。

Keyed State: 对于需要根据键值进行分区的操作符，Flink 会为每个键值维护一个状态。这种状态通常用于需要按键分组的操作，如 keyed windows 或 aggregations。checkpoint 会保存所有键的状态。

Buffered Data: 数据在流向下一个操作符之前可能会在网络缓冲区中缓存。在checkpoint时，这些缓存的数据也会被保存，以确保在恢复时数据不会丢失。

Program Counter: Flink 会保存程序的执行点，这样在恢复时可以从上一个checkpoint继续执行。

Task State: 除了用户定义的状态外，Flink 还会保存任务的内部状态，例如当前正在处理的事件或定时器。

当checkpoint被触发时，Flink 会将状态数据写入到预定义的持久化存储（比如HDFS、S3、RocksDB等）。状态的保存通常是以一种增量或差异的方式进行的，这意味着只有自上一个checkpoint以来发生变化的状态部分才会被保存。这样可以大大减少存储需求和checkpoint的时间。

Flink 支持两种状态后端来存储状态信息：

内存状态后端（MemoryStateBackend）：将状态作为对象存储在JobManager的内存中，适用于小状态的场景。在进行checkpoint时，状态会被序列化后存储到JobManager的内存中。

文件系统状态后端（FsStateBackend）：将状态存储在TaskManager的内存中，但会将checkpoint写入到配置的文件系统（如HDFS）中。

RocksDB状态后端（RocksDBStateBackend）：将状态存储在本地的RocksDB实例中，适合大状态的场景。在checkpoint时，改变的部分会被持久化到配置的文件系统中。

开启checkpoint是为了确保即使在发生故障时，Flink作业也能从最近的一致状态恢复过来，从而保证数据处理的精确一次性（exactly-once）语义或至少一次性（at-least-once）语义。
```



### flink程序大状态存储

如果状态很大的话，用rocks DB存，这个是存在本地磁盘的。

如果用内存来存很大的状态的话，taskmanager要分配很大内存，即flink任务要申请很大内存，不划算

### 水位线不推进

为了解决乱序问题，手动指定分区规则，4个分区，整除3漏了一个，导致有个分区一直没数据。

下游消费的时候并行度设置为4，导致某个无数据，水位线不推进。

### 算子里异常不会终止

代码Flink_learing中a9包的A2代码，map里出异常1/0，不会终止，而是重复执行方法体，不知道是不是因为checkpoint 。

注意：如果设置了检查点，它可以从最近的检查点恢复，也就是说当你处理1，2，3，异常数据时，会再执行一次1，2，3数据，

有重复的数据，比如超时重试等。

```sql
Apache Flink 是一个分布式流处理框架，它的设计理念是能够容忍错误并且保证数据处理的准确性。在 Flink 中，当你的数据流处理逻辑中出现异常时（比如你提供的代码中的除以零操作），Flink 并不会直接中断整个流处理作业。这是因为在实时流处理中，数据源源不断地到来，一个异常数据项不应该导致整个数据流的处理终止。

Flink 提供了不同的容错机制来保证作业的稳定性：

Checkpointing: Flink 支持周期性的检查点（checkpoint），这意味着它会定期保存作业的状态。如果作业失败，它可以从最近的检查点恢复，而不是从头开始。这样即使发生异常，Flink 也能从最近的健康状态恢复作业的执行。

重试机制: 当遇到异常时，Flink 可以配置重试策略，比如重新尝试执行失败的任务或者重新读取数据。

容错操作符: Flink 的 API 提供了一些可以处理异常的操作符，比如 flatMap 可以在遇到异常时输出一个空的结果。

在你的代码示例中，当 map 方法中出现 1/0 这样的除以零操作时，Flink 会捕获这个异常，并尝试应用其容错机制。如果配置了重试策略，它会尝试重新运行失败的任务。如果设置了检查点，它可以从最近的检查点恢复。这样设计的目的是为了确保数据流的处理是鲁棒的，并且能够处理各种异常情况而不会直接导致整个作业失败。

如果你希望在异常发生时中断作业，你需要在 map 函数中捕获异常并手动停止 Flink 作业，或者配置作业失败策略，使得在异常发生时不进行重试并直接停止作业。但请注意，这通常不是流处理的推荐做法，因为这会导致数据处理的不连续性和潜在的数据丢失。
```

### idea中flink写入hive注意事项

1  insert into 后直接写表，不能写table ，不支持

2 必须类型匹配,int 不能插入string的字段



### flink写入hive速度如何

hbase是依赖hdfs存储数据的，那么为什么通过hbase客户端插入数据那么快。而通过hive客户端执行“insert into table ”这个hql，就算插入一条数据也要将近20s，为什么呢？flink对接hive，是通过hive服务器插入数据？还是直接往hdfs上更改数据的？



HBase 和 Hive 都是大数据生态系统中的重要组件，但它们的设计理念和使用场景有很大的不同，这也是导致它们在数据插入速度上有显著差异的原因。

**HBase**

HBase 是一个分布式的、面向列的 NoSQL 数据库，它以 HDFS 作为其底层存储，但是提供了一个可以随机实时读写数据的能力。HBase 的数据模型和存储机制允许它在单条记录层面上进行高效的读写操作。HBase 的写操作被直接写入内存中的 MemStore，然后定期刷新到磁盘上的 StoreFiles。这种设计允许 HBase 快速插入数据，因为它不需要像传统的 RDBMS 那样每次插入都进行磁盘 I/O。

**Hive**

Hive 是一个建立在 Hadoop 生态系统上的数据仓库工具，它将 SQL 查询转换成 MapReduce、Tez 或 Spark 作业来执行。Hive 的设计目标是为了处理大规模数据集的批处理作业，并且优化了读取大量数据的场景。因此，Hive 在执行数据修改操作（如插入）时，通常不如 HBase 那么快。Hive 的插入操作可能需要执行多个步骤，包括：

1. 解析 HQL 语句。
2. 生成对应的执行计划。
3. 在 HDFS 上创建临时文件。
4. 执行 MapReduce 或其他框架的作业来实际写入数据。
5. 更新 Hive 元数据。

这些步骤导致即使是插入一条数据也需要较长时间。

**Flink 对接 Hive**

Apache Flink 是一个流处理和批处理都支持的数据处理框架。当 Flink 对接 Hive 时，通常有两种方式：

1. **通过 Hive 服务器插入数据：** Flink 可以使用 Hive 的 JDBC 驱动来连接 Hive 服务器，这时候 Flink 的作业会通过 Hive 服务来执行数据的插入操作。这种方式会受到 Hive 性能的限制，因为它是通过 Hive 来处理数据。

2. **直接往 HDFS 上更改数据：** Flink 也可以直接写入 HDFS，绕过 Hive 的处理逻辑。在这种情况下，Flink 需要负责维护与 Hive 元数据兼容的数据格式，以及在作业完成后更新 Hive 元数据。这种方式可以更快地写入数据，因为它减少了 Hive 处理的开销。

在实际使用中，选择哪种方式取决于具体的需求和架构设计。如果对实时性要求很高，可能会优先考虑直接写入 HDFS 的方式；如果对数据一致性和兼容性要求更高，则可能会通过 Hive 服务器来保证这些要求。



##### 代码案例直接写hdfs

要实现 Flink 直接向 HDFS 写入数据，而不是通过 Hive 服务器，你可以使用 Flink 的 `FileSystem` API。以下是一个简单的示例，展示了如何使用 Flink API 将数据直接写入 HDFS：

```java
import org.apache.flink.api.common.serialization.SimpleStringEncoder;
import org.apache.flink.core.fs.Path;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.functions.sink.filesystem.StreamingFileSink;

public class FlinkHdfsSinkExample {
    public static void main(String[] args) throws Exception {
        // 设置 Flink 执行环境
        final StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        // 创建一个简单的数据源
        DataStream<String> text = env.fromElements(
                "First line",
                "Second line",
                "Third line"
        );

        // 定义一个 StreamingFileSink，将数据写入 HDFS
        final StreamingFileSink<String> sink = StreamingFileSink
                .forRowFormat(new Path("hdfs://namenode:8020/path/to/destination"), new SimpleStringEncoder<String>("UTF-8"))
                .build();

        // 将 sink 添加到数据流
        text.addSink(sink);

        // 执行 Flink 作业
        env.execute("Flink HDFS Sink Example");
    }
}
```

在这个示例中，`namenode` 是你的 HDFS NameNode 的地址，`8020` 是 HDFS 服务的端口号，而 `/path/to/destination` 是目标路径，你需要根据你的实际 HDFS 设置进行替换。`SimpleStringEncoder` 用于将字符串数据编码为字节，并写入 HDFS。

关于第二个问题，当使用 Flink 的 Table API 并创建 Hive Catalog 时，Flink 会通过 Hive Metastore 客户端与 Hive Metastore 通信来访问 Hive 表的元数据。数据的实际写入操作可以通过 Flink 的文件系统连接器完成，这样 Flink 就可以直接将数据写入与 Hive 表相对应的 HDFS 文件中。这里，Flink 负责维护数据格式和目录结构，以确保它与 Hive 表的格式兼容。

下面是一个使用 Flink Table API 和 Hive Catalog 的示例：

```java
import org.apache.flink.table.api.EnvironmentSettings;
import org.apache.flink.table.api.TableEnvironment;
import org.apache.flink.table.catalog.hive.HiveCatalog;

public class FlinkHiveCatalogExample {
    public static void main(String[] args) {
        // 设置 Flink 表环境
        EnvironmentSettings settings = EnvironmentSettings.newInstance().useBlinkPlanner().inBatchMode().build();
        TableEnvironment tableEnv = TableEnvironment.create(settings);

        // 创建 HiveCatalog
        String name = "myhive";
        String defaultDatabase = "default";
        String hiveConfDir = "/path/to/hive/conf"; // Hive 的配置目录

        HiveCatalog hive = new HiveCatalog(name, defaultDatabase, hiveConfDir);
        tableEnv.registerCatalog("myhive", hive);

        // 使用 HiveCatalog
        tableEnv.useCatalog("myhive");

        // 你现在可以使用 Flink Table API 执行操作，这些操作会反映在 Hive 中
        // 例如，将一个 Table 写入 Hive 表
        tableEnv.executeSql("INSERT INTO my_hive_table SELECT * FROM my_flink_table");
    }
}
```

在这个示例中，`/path/to/hive/conf` 是 Hive 配置文件（如 `hive-site.xml`）的目录。`my_hive_table` 是 Hive 中的表，而 `my_flink_table` 是 Flink 程序中的表。这段代码将 Flink 表的内容写入 Hive 表中，实际的数据写入是通过 Flink 直接对 HDFS 进行的，但是所有的元数据操作（如表结构的读取和更新）都是通过 Hive Metastore 完成的。

请确保你的 Flink 环境已经配置了对应的 Hadoop 和 Hive 依赖，并且正确设置了相关的配置文件，以便能够与你的 Hive 和 HDFS 环境进行交互。



在 Flink 中，控制数据写入 HDFS 的频率通常涉及到以下几个方面：

1. **缓冲区大小（Buffer Size）**：在写入文件系统时，可以设置缓冲区大小，以便在刷新到磁盘之前在内存中积累更多的数据。
2. **刷新间隔（Flush Interval）**：对于流式文件接收器（如 `StreamingFileSink`），你可以设置一个自动刷新的时间间隔，这样数据就会定期刷新到 HDFS。
3. **检查点（Checkpointing）**：在 Flink 流作业中，启用检查点机制可以保证状态的一致性，同时也会触发数据的写入。

以下是如何在 `StreamingFileSink` 中设置这些参数的示例：

```java
import org.apache.flink.streaming.api.functions.sink.filesystem.StreamingFileSink;
import org.apache.flink.streaming.api.functions.sink.filesystem.rollingpolicies.DefaultRollingPolicy;

import java.util.concurrent.TimeUnit;

StreamingFileSink<String> sink = StreamingFileSink
    .forRowFormat(new Path("hdfs://namenode:8020/path/to/destination"), new SimpleStringEncoder<String>("UTF-8"))
    .withRollingPolicy(
        DefaultRollingPolicy.builder()
            .withRolloverInterval(TimeUnit.MINUTES.toMillis(15)) // 每15分钟滚动一次文件
            .withInactivityInterval(TimeUnit.MINUTES.toMillis(5)) // 5分钟无数据写入时滚动文件
            .withMaxPartSize(1024 * 1024 * 128) // 设置每个文件的最大大小为128MB
            .build()
    )
    .build();
```

在这个配置中：

- `withRolloverInterval` 设定了文件滚动的时间间隔，即使文件没有达到最大大小也会因为时间间隔而滚动。
- `withInactivityInterval` 设定了如果在指定时间内没有新数据到来，当前的文件就会关闭并滚动。
- `withMaxPartSize` 设定了每个文件的最大大小，达到这个大小后，当前文件会关闭并创建新文件。

这些策略结合使用可以帮助你控制数据写入到 HDFS 的频率和时机。通过调整这些参数，你可以根据你的具体需求平衡写入的即时性和效率。

除此之外，Flink 的检查点机制也会影响数据写入的行为。当启用检查点时，`StreamingFileSink` 会在每个检查点时刻保证至少有一次数据的持久化。检查点的间隔也可以配置，这样可以控制数据写入的最长延迟时间：

```java
// 设置检查点间隔
env.enableCheckpointing(60000); // 每60秒执行一次检查点
```

上述配置会影响数据的写入频率，但是请注意，过大的缓冲区和过长的刷新间隔可能会导致在发生故障时丢失更多的数据。因此，设置这些参数时需要在数据可靠性和系统性能之间做出权衡。





# 问题待解决

### 定时器重复注册

在KeyedProcessFunction中可以住车定时器。processElement函数中每次处理一条数据，这样重复注册定时器，不会导致定时任务重复调用吗？

答案是不会，应为Flink内部使用的HeapPriorityQueueSet来存储定时器，一个注册请求到来时，其add()方法会检查是否已经存在，如果存在则不会加入。并且是根据key来注册的。如果重复注册并且更改触发时间的话，需要自己去测一下



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



### ArrayIndexOutOfBoundsException

A2_TopnWindowAll有个bug，就是总是报错.ArrayIndexOutOfBoundsException: -2147483648，不知道原因

已经确定不是nc输出错误数据的问题了。好像设置并行度为2的时候就不会出问题了

### windowall并行度不为1

在 A2_TopnWindowAll有个问题，就是用了windowall，最后输出结果还是多个并行度结果

### 不同执行模式区别

去csdn查一下，session和standalone，application模式应用场景与区别



### checkpoint中barrie

2	cep会将数据携带一个barrier，让各个算子记录当前状态，不过没有那么简单

例如 kafka源2个并行度消费，那么每个并行度需要记录消费了几个分区，并且每个分区消费位置,

当某个算子从2并行度更改到4并行度，那么如果只是给一个数据携带barrier那么会出现某个并行度没有barrier，

所以具体怎么样实现的barrier不清楚。以及当从4并行度聚合到2个并行度，那么barrier又是怎么实现的也不清楚。

当2并行度聚合到1个并行度，当上游的2个barrier数据到达时间有延迟，比如一个分支到了3个数据，另外一个分支的barrier才到

那么合并后的barrier什么时候保存状态

### flink-session起不来

更改配置文件后连yarn-sesion都起不来
为了资源够slut,更改flink配置文件，发现起不来了。后面查阅发现，好像比如jobmanager和taskmanager有一定内存比例的，而且分给某些线程的内存要在固定60m-256m范围之间，因为只改了jobmanager和taskmanager的内存配置，所以起不来了。

要怎么配置内存占比呢，才能让集群跑起来





# ——————flink文档——————



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



# Flink优化总结

#### 反压机制

Flink反压（Backpressure）是指当数据流在Flink任务中的操作链上出现处理速度不匹配时，通过一种机制来限制数据流的速度，以防止数据流的上游操作快于下游操作，导致下游操作无法及时处理数据而导致的问题。

在Flink中，数据流由一系列的算子（operators）组成，每个算子都有自己的处理速度。当上游算子的处理速度超过下游算子的处理速度时，下游算子可能无法及时处理所有的数据，导致数据积压。为了解决这个问题，Flink引入了反压机制。

Flink的反压机制通过在数据流的上下游之间建立反压通信，使得上游算子能够感知下游算子的处理能力，并根据下游算子的处理能力来调整自身的处理速度。当下游算子无法及时处理数据时，上游算子会收到反压信号，从而降低自身的处理速度，以减少数据的产生速率。

要查看Flink中的反压情况，可以使用Flink的Web界面或者命令行界面。在Web界面中，可以通过任务的Metrics选项卡查看反压指标，如输入速率、输出速率、反压比例等。在命令行界面中，可以使用`flink list -r`命令查看任务的反压情况。

需要注意的是，反压只是一种机制，它可以帮助解决数据流速度不匹配的问题，但并不是万能的解决方案。在设计和优化Flink任务时，还需要考虑到数据倾斜、资源分配、并行度设置等因素，以获得更好的性能和稳定性。



Flink的反压机制是通过以下方式实现的：

1. 算子链中的每个算子都会维护一个输入缓冲区，用于存储从上游算子接收到的数据。当下游算子无法及时处理数据时，输入缓冲区会积累数据。
2. 当下游算子的处理能力不足以处理输入缓冲区中的数据时，它会向上游算子发送反压信号。这个信号通常是通过特殊的数据元素（如反压标记）或者回调函数的方式来实现的。
3. 上游算子在接收到反压信号后，会根据信号的内容降低自身的处理速度。具体来说，它可能会采取以下措施之一：
   - 降低数据的产生速率，例如通过限制输入数据源的速度或者降低数据生成的频率。
   - 调整内部的数据缓冲策略，减少数据在内存中的积压量。
   - 通过协调与其他上游算子的通信，减少数据的发送频率。
4. 上游算子降低处理速度后，数据流的速度会逐渐减慢，直到与下游算子的处理速度达到匹配。这样可以避免数据积压问题，并确保整个任务的稳定运行。



需要注意的是，Flink的反压机制是基于协作的，依赖于上下游算子之间的通信和协调。上游算子需要能够感知到下游算子的处理能力，并主动调整自身的处理速度。这也是为什么在代码中已经写好处理逻辑的情况下，Flink仍然能够控制上游算子的处理速度的原因。

在Flink中，反压机制是默认启用的，但也可以通过配置参数进行调整或禁用。通过合理的配置和调优，可以使得Flink任务在不同的场景下获得更好的性能和稳定性。





是的，如果Flink程序的源头是Kafka，并且在源头之后有多个算子执行，Flink的反压机制会降低消费Kafka的速度。

当下游算子无法及时处理数据时，Flink的反压机制会通过向上游算子发送反压信号来降低整个数据流的速度。对于Kafka源头，这意味着Flink会减慢对Kafka分区的消费速率，以控制数据的产生速度，以便与下游算子的处理能力保持匹配。

具体来说，Flink的Kafka消费者会根据下游算子的处理能力调整自身的消费速率。它会根据反压信号中的指示，动态调整消费的速度，以便在不超过下游算子处理能力的同时，尽可能高效地消费Kafka分区中的数据。

这种方式可以避免数据在整个任务链中的积压问题，并保证数据的稳定流动。通过反压机制，Flink能够根据下游算子的处理能力动态调整整个任务的速度，以实现数据流的平衡处理。



#### 反压失效

```
在 Apache Flink 和 Apache Spark 中，反压（backpressure）或背压（backpressure）机制是为了防止流处理系统在处理能力受限时被过载的一种措施。这些机制通常在可控的数据源（如 Apache Kafka）中效果最佳，因为可以根据处理能力调整数据拉取的速率。

但是，确实存在一些数据源是推送型（push-based）的，而不是拉取型（pull-based），在这种情况下，数据的生产者会按照自己的节奏发送数据，而不考虑消费者的处理能力。这种情况下，反压机制可能就不那么有效了，因为数据源不会响应消费者的压力信号。

以下是一些可能导致反压机制不生效的场景：

1. **HTTP推送型数据流**：如果一个服务通过HTTP POST请求推送数据到流处理系统，流处理系统可能没有办法告诉发送方减慢发送速度。

2. **物联网（IoT）设备**：许多IoT设备会按照固定的间隔发送传感器数据。这些设备可能不会响应来自流处理系统的反压信号，因此在数据量激增时可能会导致问题。

3. **实时数据库变更数据捕获（CDC）**：某些数据库的CDC工具会推送变更事件到流处理系统，而这些工具可能不支持基于消费者反压的流控制。

4. **日志文件监控**：例如，监控日志文件并将新行推送到流处理系统的工具可能不会响应消费者的处理能力。

5. **传统消息队列**：一些较旧的或简单的消息队列系统可能不支持背压，它们可能会持续推送消息而不考虑消费者的处理速率。

在这些场景下，如果流处理系统无法处理输入的速度，可能会出现内存溢出、延迟增加或其他性能问题。为了缓解这些问题，可能需要采取其他策略，比如：

- **增加处理能力**：通过增加更多的处理节点或提高每个节点的资源来处理更高的负载。
- **限流**：在数据进入流处理系统之前应用限流策略，比如在API网关层面限制请求速率。
- **缓冲和溢写**：使用缓冲区来吸收短时间内的高负载，并在必要时将数据溢写到磁盘或其他存储。
- **数据抽样**：在无法处理全部数据时，选择性地只处理数据的一个子集。
- **优先级队列**：对进入的数据进行优先级排序，确保处理最重要的数据。

总的来说，对于那些不支持或不完全支持反压的数据源，系统设计时需要考虑到这一点，并采取适当的措施来确保系统的稳定性。
```



#### 查看资源利用情况

Flink中，可以通过监控和度量指标来查看任务的资源使用情况，以确定是否给任务分配了过多的资源。以下是一些常用的方法：

1. **Flink Web UI**：Flink提供了一个Web界面，可以通过它来监视和管理Flink集群和任务。在Web界面中，您可以查看任务的运行状态、度量指标和资源使用情况。通过查看任务的CPU使用率、内存使用率和网络IO等指标，可以初步判断任务是否使用了过多的资源。
2. **Flink Metrics**：Flink提供了丰富的度量指标，可以通过度量系统（如Prometheus、InfluxDB等）来收集和可视化这些指标。您可以配置Flink以将度量指标导出到所选的度量系统中，并使用相应的仪表板来监视任务的资源使用情况。
3. **日志文件**：Flink生成详细的日志文件，其中包含有关任务的各种信息，包括资源分配和使用情况。您可以查看任务的日志文件，以了解任务是否存在资源浪费的迹象。特别是关注与资源相关的警告或错误信息。
4. **操作系统工具**：您还可以使用操作系统提供的工具来监视任务的资源使用情况。例如，使用top命令或任务管理器来查看任务的CPU和内存使用情况。如果任务的资源使用率持续较低，可能是因为分配了过多的资源。

通过综合使用上述方法，您应该能够获得关于任务资源使用情况的全面了解，从而判断是否给任务分配了过多的资源。如果任务的资源使用率较低，可以考虑减少任务的并行度或调整资源分配，以更好地利用资源。



#### flink精准一次性消费

如果某一个值是kakfa数据字段累加的话，为了保证一次性消费，第一个就是相加之后提交offset，

如果这时候kafka那边出现问题了，那么offset没有提交成功。下次开起后还会再重新再消费一次。

为了保证下游幂等性操作，把消息的transitionid存在集合里，大概10条，定期删除。每次累加去集合里遍历。

这样多次消费同一条数据也没事，其实设置一条就行了。



#### flink到hive精准一次

~~~java
在 Flink 流处理中实现从 Kafka 到 Hive 的精准一次性消费（exactly-once semantics），你需要使用 Flink 提供的事务性写入特性和状态后端来保证状态的一致性。下面是一些关键步骤来实现这个需求：

1. **启用 Checkpointing**: Flink 通过 Checkpointing 机制来保证状态的一致性和故障恢复。你需要在你的 Flink 程序中启用并配置 Checkpointing。

    ```java
    StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
    env.enableCheckpointing(10000); // 启用 Checkpoint，例如每 10 秒钟进行一次
    ```

2. **选择状态后端**: 状态后端用于存储状态和控制 Checkpoint 的存储位置。Flink 支持多种状态后端，如 RocksDB、FsStateBackend 等。

    ```java
    env.setStateBackend(new RocksDBStateBackend("hdfs:///flink/checkpoints", true));
    ```

3. **配置 Kafka 消费者**: 使用 Flink Kafka Connector，配置 Kafka 消费者以使用 Flink 的 Checkpoint 机制。

    ```java
    Properties properties = new Properties();
    properties.setProperty("bootstrap.servers", "localhost:9092");
    properties.setProperty("group.id", "test");
    FlinkKafkaConsumer<String> kafkaConsumer = new FlinkKafkaConsumer<>(
        "topic",
        new SimpleStringSchema(),
        properties
    );
    kafkaConsumer.setStartFromGroupOffsets(); // 从 Kafka 的 committed offset 开始消费
    ```

4. **启用 Kafka 的事务性写入**: 当你将数据写入 Hive 时，你需要确保这个过程是事务性的。在 Flink 中，你可以使用 `TwoPhaseCommitSinkFunction` 来实现事务性的写入。

5. **实现自定义 Sink**: 由于 Hive 不支持幂等写入，你可能需要实现自己的 `SinkFunction` 或 `TwoPhaseCommitSinkFunction`，在这个 Sink 中，你将控制写入 Hive 的过程，并利用 Hive 的事务特性（如果可用）来保证精准一次性的语义。

6. **处理重启和失败**: 当 Flink 任务失败并重启时，它会从最后一个成功的 Checkpoint 恢复。这意味着，如果你的 Sink 实现正确，你的 Flink 任务会从上一个一致的状态开始重新处理数据，而不会导致数据重复。

7. **手动提交 Offset**: 通常，你不需要手动提交 Kafka offset，因为 Flink Kafka Consumer 集成了 Flink 的 Checkpointing 机制，这会确保 offset 在 Checkpoint 时自动提交。

8. **确保 Hive 支持 ACID 操作**: 如果你使用的是 Hive 3.x 以上版本，Hive 支持事务表。确保你的 Hive 表是事务性的，这样你可以利用 Hive 的 ACID 特性来保证数据的精准一次性写入。

这里是一个大概的代码示例框架，展示了如何集成 Kafka 消费者和自定义 Sink：

```java
StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
env.enableCheckpointing(10000);
env.setStateBackend(new RocksDBStateBackend("hdfs:///flink/checkpoints", true));

Properties properties = new Properties();
// 配置 Kafka 消费者属性
properties.setProperty("bootstrap.servers", "localhost:9092");
properties.setProperty("group.id", "test");
FlinkKafkaConsumer<String> kafkaConsumer = new FlinkKafkaConsumer<>(
    "topic",
    new SimpleStringSchema(),
    properties
);
kafkaConsumer.setStartFromGroupOffsets();

DataStream<String> stream = env.addSource(kafkaConsumer);
stream.addSink(new TwoPhaseCommitSinkFunction<...>(){
    // 实现你的事务性写入逻辑到 Hive
});

env.execute("Flink Kafka to Hive Exactly-Once");
```

请根据你的实际需求调整以上示例。需要注意的是，实现精准一次性消费可能会增加系统的复杂性，并可能影响到吞吐量。在实际部署前，你应该充分测试并调优你的 Flink 应用程序。
~~~

#### table从kafka到hive精准一次

```
在 Apache Flink 1.17 版本中，Flink Table API 支持多种方式来与外部系统交互，并且它的设计目标之一就是简化流处理和批处理的统一编程模型。使用 Flink Table API 时，Flink SQL Client 或者编程接口可以让你以声明式的方式来定义数据流的处理和转换。

对于从 Kafka 到 Hive 的精准一次性消费，Flink Table API 提供了一些内置的连接器和策略来支持这种需求。以下是实现这一目标的关键步骤：

配置 Kafka Source: 使用 Flink Table API 创建 Kafka 表，这会自动管理 offset 存储和提交，从而支持故障恢复时的精准一次性消费。

配置 Hive Sink: 使用 Flink Table API 创建 Hive 表，并配置相应的连接器属性。

启用 Checkpointing: 对于 Table API，你也需要启用和配置 Checkpointing 来保证状态的一致性。

使用 Flink SQL 或 Table API: 你可以使用 Flink SQL 或者 Table API 来定义数据的转换和处理逻辑。

确保 Hive 版本和配置支持 ACID: 如果你使用的 Hive 版本支持 ACID 操作，确保你的 Hive 表是事务性的，并且 Hive Metastore 正确配置。

下面是一个简化的示例，展示了如何使用 Flink Table API 来从 Kafka 读取数据并写入到 Hive 表：

StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
StreamTableEnvironment tableEnv = StreamTableEnvironment.create(env);

// 启用 Checkpointing
env.enableCheckpointing(10000);

// Kafka Source 表
tableEnv.executeSql(
    "CREATE TABLE kafka_source_table (" +
    "  `id` STRING," +
    "  `data` STRING," +
    "  `event_time` TIMESTAMP(3) METADATA FROM 'timestamp'," +
    "   WATERMARK FOR event_time AS event_time" +
    ") WITH (" +
    "  'connector' = 'kafka'," +
    "  'topic' = 'your-topic'," +
    "  'properties.bootstrap.servers' = 'kafka-broker:9092'," +
    "  'properties.group.id' = 'flink-group'," +
    "  'format' = 'json'," +
    "  'scan.startup.mode' = 'latest-offset'" +
    ")"
);

// Hive Sink 表
tableEnv.executeSql(
    "CREATE TABLE hive_sink_table (" +
    "  `id` STRING," +
    "  `data` STRING," +
    "  `event_time` TIMESTAMP(3)" +
    ") PARTITIONED BY (dt STRING) STORED AS ORC TBLPROPERTIES (" +
    "  'sink.rolling-policy.file-size' = '128MB'," +
    "  'sink.rolling-policy.rollover-interval' = '15 min'," +
    "  'sink.partition-commit.trigger' = 'partition-time'," +
    "  'sink.partition-commit.delay' = '0 s'," +
    "  'sink.partition-commit.policy.kind' = 'metastore,success-file'" +
    ")"
);

// 插入语句
tableEnv.executeSql(
    "INSERT INTO hive_sink_table " +
    "SELECT id, data, event_time, DATE_FORMAT(event_time, 'yyyy-MM-dd') as dt " +
    "FROM kafka_source_table"
);
在上述代码中，我们定义了一个 Kafka 表作为 Source，一个 Hive 表作为 Sink，并且使用了一个插入语句将数据从 Kafka 流式传输到 Hive。Flink Table API 会在内部处理状态管理和 Checkpointing，以保证精准一次性消费。

请注意，上述代码只是一个示例，你可能需要根据你的具体环境和需求进行调整。特别是，你需要确保 Hive 的配置支持事务性写入，并且你的 Hive 版本支持 ACID 特性。

在使用 Flink Table API 时，一定要确保你已经正确配置了 Flink 的状态后端和 Checkpointing 参数，以及 Hive 的连接器参数，这样才能确保精准一次性的语义。
```





# flink中概念

### 状态一致性

有3个级别，exactly-once精准一次，atleast-once,atmost-once,

flink内部通过checkpoint可以实现精准一次

还有个概念端到端状态一致性：

3个要求：

source故障恢复时支持重读

sink故障恢复时,要么支持事务写入可以就滚，要么支持幂等性

checkpoint 记录source消费的位置,记录内部任务链状态，记录sink端写入状态



如果sink端支持幂等性，那么checkpoint,直接读取上个保存点source坐标，不管后面数据是否已经写入sink了，重复写就行。

如果不支持幂等性，那么必须支持事务写入，checkpoint的保存必须和那边的写入二阶段提交。二阶段提交是事务保证的一种方式



```sql
#两阶段提交
在 Flink 中，两阶段提交（Two-Phase Commit，简称 2PC）是一种常用的事务处理机制，用于实现分布式系统中的事务一致性。它主要涉及到两个角色：事务协调器（Transaction Coordinator）和事务参与者（Transaction Participant）。
下面是 Flink 中两阶段提交的工作流程：
事务协调器发送预提交请求：当一个 Flink 作业需要执行事务写入时，事务协调器会向所有的事务参与者发送预提交请求。预提交请求包含了要写入的数据和事务的元数据。
事务参与者执行预提交：事务参与者接收到预提交请求后，会执行相应的写入操作，并将写入的结果保存在本地的事务日志中，但此时并未将数据提交到源系统。
事务协调器发送提交请求：当所有的事务参与者都执行了预提交操作后，事务协调器会向所有的事务参与者发送提交请求。
事务参与者进行提交操作：事务参与者接收到提交请求后，会将之前的写入操作提交到源系统中。
事务协调器发送最终提交或回滚请求：如果所有的事务参与者都成功提交了数据，事务协调器会发送最终提交请求，表示事务提交成功。否则，如果有任何一个事务参与者提交失败，事务协调器会发送回滚请求。
事务参与者执行最终提交或回滚操作：事务参与者接收到最终提交或回滚请求后，会执行相应的操作。如果是最终提交请求，事务参与者会确认提交操作；如果是回滚请求，事务参与者会撤销之前的写入操作。
通过这样的两阶段提交流程，Flink 可以保证在分布式环境下的事务一致性。然而，如果 Sink 的源不支持回滚操作，那么在事务失败时无法撤销之前的写入操作，这可能导致数据的不一致性。
在这种情况下，Flink 无法完全保证事务的一致性，但可以通过其他手段来尽量减少数据不一致的风险。例如，可以使用幂等性操作来确保相同的数据重复写入不会产生副作用。此外，还可以通过监控和异常处理机制来及时发现和处理事务失败的情况，以减少数据不一致的影响。
总之，Flink 中的两阶段提交机制在大多数情况下可以保证事务的一致性，但如果 Sink 的源不支持回滚操作，需要通过其他手段来尽量减少数据不一致的风险。

#支持两阶段提交的sink数据源
Flink 的 Sink 数据源并不是直接支持两阶段提交的事务，而是通过特定的 Sink 实现来实现事务一致性。以下是一些常见的 Flink Sink 实现，它们支持两阶段提交的事务：
Flink JDBC Sink：Flink 提供了 JDBC Sink，可以将数据写入关系型数据库。通过配置合适的数据库和事务管理器，可以实现基于数据库的两阶段提交事务。
Flink Kafka Sink：Flink 提供了 Kafka Sink，可以将数据写入 Kafka 主题。Kafka 本身支持事务，可以与 Flink 的事务机制结合使用，实现两阶段提交事务。
Flink Elasticsearch Sink：Flink 提供了 Elasticsearch Sink，可以将数据写入 Elasticsearch。Elasticsearch 支持事务，可以通过配置合适的 Elasticsearch 版本和事务管理器来实现两阶段提交事务。
```



### flink精准一次到kafka

```sql

在 Apache Flink 中实现对 Kafka 的事务写入，确实需要使用 Flink 的 checkpoint 机制以及 Kafka 的事务支持。两阶段提交（2PC）是通过 Flink 的 FlinkKafkaProducer 实现的，这个生产者可以提供语义上的精确一次（exactly-once）的处理语义。
请注意，为了实现精确一次的语义，你需要确保以下几点：
Kafka 集群需要配置为支持事务（即：transactional.id 配置项需要被设置）。
Flink 作业需要启用 checkpoint。
使用的 FlinkKafkaProducer 需要配置为使用事务。


#kafka配置文件支持事务
首先，确保你的 Kafka 集群已经配置了事务支持。Kafka 代理（broker）的配置文件中应该包含如下设置：
transaction.state.log.replication.factor=3
transaction.state.log.min.isr=2

#启用 checkpoint 和搭配 FlinkKafkaProducer。kafka通过幂等性+多次保证精准一次。

public class KafkaExactlyOnceExample {
    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        // 开启 checkpoint
        env.enableCheckpointing(10000); // 比如每 10 秒钟进行一次 checkpoint

        // 配置 Kafka 生产者
        String kafkaServers = "localhost:9092"; // Kafka 集群地址
        String kafkaTopic = "your_topic"; // Kafka 主题

        Properties properties = new Properties();
        properties.setProperty("bootstrap.servers", kafkaServers);
        // 设置事务超时时间
        properties.setProperty("transaction.timeout.ms", 60000 * 15 + "");
        // 设置事务ID前缀，Flink 会为每个并行实例创建一个事务ID
        properties.setProperty("transactional.id", "flink-tx-" + UUID.randomUUID().toString());

        // 创建 Kafka 生产者
        FlinkKafkaProducer<String> flinkKafkaProducer = new FlinkKafkaProducer<>(
            kafkaTopic,
            new SimpleStringSchema(),
            properties,
            FlinkKaf
```



### 状态存储后端选择

state backend和checkpoint可以分开配置，老的flink文档说的不对：

```sql
#说的不准确，是可以分开存的
• MemoryStateBackend
state等状态,将它们存储在TaskManager的JVM堆上；而将checkpoint存储在JobManager的内存中。
• FsStateBackend
将checkpoint存到远程的持久化文件系统（FileSystem）上。而对于本地状态，跟MemoryStateBackend一样，也会存在TaskManager的JVM堆上。
• RocksDBStateBackend
将所有状态序列化后，存入本地的RocksDB中存储。
```



statebackedn和checkponit配置,当state很大的时候，适合用rocksDB

```sql
在Apache Flink中，算子状态（Operator State）和Checkpoint机制是紧密相关的。但是，Flink的状态后端（State Backend）和Checkpoint存储（Checkpoint Storage）是可以分开配置的。
状态后端（State Backend）：这决定了Flink作业的状态是如何存储和维护的。Flink提供了多种状态后端，比如内存状态后端（MemoryStateBackend）、FsStateBackend（将状态作为TaskManager的本地文件系统上的文件存储）和RocksDBStateBackend（将状态存储在RocksDB中，RocksDB是一个嵌入式的key-value存储，适合大状态的场景）。状态后端不仅用于常规的状态管理，而且在Checkpoint时也会用到。
Checkpoint存储（Checkpoint Storage）：这决定了Checkpoint数据是如何存储的。Checkpoint数据可以存储在不同的存储系统中，比如本地文件系统、HDFS等。Flink的Checkpoint机制确保了作业在发生故障时能够从之前的状态恢复。
你可以选择RocksDBStateBackend作为状态后端来存储算子状态，这意味着算子状态会在本地的RocksDB数据库中维护，这对于大状态是很有用的，因为RocksDB可以有效地处理大量数据。然后，你可以配置Checkpoint存储将Checkpoint数据保存在HDFS上。这种配置可以通过Flink的配置文件或作业提交时的代码进行设置。
例如，以下是如何在Flink配置中设置RocksDB作为状态后端和HDFS作为Checkpoint存储的示例：
// 设置状态后端为RocksDB
env.setStateBackend(new RocksDBStateBackend("hdfs:///flink/checkpoints", true));

// 设置Checkpoint存储路径为HDFS
env.getCheckpointConfig().setCheckpointStorage("hdfs:///flink/checkpoints");
在这个例子中，状态后端使用了RocksDB，并且指定了一个HDFS路径来存储RocksDB的数据和Checkpoint数据。true参数表示启用增量Checkpoint，这意味着只有变化的部分会被写入到Checkpoint中，这可以大大减少Checkpoint的大小和Checkpoint的时间。
请注意，这些配置需要根据你的具体Flink版本和部署环境来进行适当的调整。另外，确保Flink集群可以访问HDFS，且有适当的权限来读写指定的路径。
```





# —————FlinkAPI———————









# 环境与算子



### changelog后端和checkpoint区别



#### 环境获取

getExecutionEnvironment()会自动识别，当在idea执行时会默认创建本地模拟集群。用flink脚本执行jar时，会识别创建远程集群自动传递yarn等参数。

不建议在代码中指定流式批式，一套代码流批同用，用参数传递bin/flink run -Dexecution.runtime-mode=BATCH

```java
StreamExecutionEnvironment.getExecutionEnvironment(); //会自动识别是本地还是远程，通过传configure来改变
StreamExecutionEnvironment.createLocalEnvironment(); //开启一个本地模拟集群
StreamExecutionEnvironment.createRemoteEnvironment("host",8088,"jarPath"); //连接远程集群
env.setRuntimeMode(RuntimeExecutionMode.BATCH); //设置代码是流式还是批处理

```



#### 并行度

当env环境和算子同时设置并行度时，算子优先级高于env全局指定，其他没有设置并行度的算子，按env全局并行度来。

当用flink脚本执行时，临时指定 -p 3 指定并行度   优先级别是  算子指定> env指定 > 参数指定

idea执行单代码时，若算子不指定并行度默认和本机核数相同

```java
 //  这个是idea执行创建一个有webUI的en,登陆localhost:8081能看到flinkweb界面,开发时使用
StreamExecutionEnvironment env = StreamExecutionEnvironment.createLocalEnvironmentWithWebUI(newConfiguration());

//环境设置并行度
env.setParallelism(3);

//也可以算子单独设置，比如最后sink时设置为1
```

#### 算子链

默认没有shuffle 重分区的算子，都可以合到一块执行，有时候可能需要算子不合并执行，比如很复杂的2个map任务，这样可能map之后，在第二个map分到别的节点，这样效率快

比如当有个算子链报错，你定位不到具体是哪里出问题，可以禁用算子链定位到哪个算子出错

```java
Ds.map(v -> 10*v).disableChaining() //这个map算子不会和后面的合在一起
.map(v -> 10*v)

 env.disableOperatorChaining()  //全局禁用算子链合并
.startNewChain() //重新开始算子链合并

```

#### 任务槽

在Flink的/opt/module/flink-1.17.0/conf/flink-conf.yaml配置文件中，可以设置TaskManager的slot数量，默认是1个slot。

taskmanager.numberOfTaskSlots: 8

需要注意的是，slot目前仅仅用来隔离内存，不会涉及CPU的隔离。在具体应用时，可以将slot数量配置为机器的CPU核心数，尽量避免不同任务之间对CPU的竞争。这也是开发环境默认并行度设为机器CPU数量的原因。



# DataStream API核心

#### 窗口

窗口如果不用keyby的话，则无论怎么设置并行度，强制变为1  。用keyby的话，才有并行度。

aggreagte算子只有窗口流才能用,keyby的流没有这个方法



分类:滚动窗口，滑动窗口，会话窗口

滚空窗口:  把数据按时间或者次数切分,多个窗口之间是连续的

滑动窗口: 按时间或者次数获取窗口, 按设置的步长时间或步长次数滑动，步长为重叠部分。

会话窗口: 如果超过多少秒没有来事件，则会划分窗口( 具体怎么划分待测验)

全局窗口:待测验，看word



窗口的创建时机，比如10s的间隔并不是每10s创建一个，而是又事件触发临时new一个，如果没数据来，不会创建窗口

窗口创建的事件，是设置间隔的整数倍，当来一个数据时，会获取当前时间，然后向下取整。这也就是为什么没数据来，也能按固定的间隔创建窗口

```java
/**
 *  触发器、移除器： 现成的几个窗口，都有默认的实现，一般不需要自定义
 *
 *  以 时间类型的 滚动窗口 为例，分析原理：
    TODO 1、窗口什么时候触发 输出？
            时间进展 >= 窗口的最大时间戳（end - 1ms）

    TODO 2、窗口是怎么划分的？
            start= 向下取整，取窗口长度的整数倍
            end = start + 窗口长度

            窗口左闭右开 ==》 属于本窗口的 最大时间戳 = end - 1ms

    TODO 3、窗口的生命周期？
            创建： 属于本窗口的第一条数据来的时候，现new的，放入一个singleton单例的集合中
            销毁（关窗）： 时间进展 >=  窗口的最大时间戳（end - 1ms） + 允许迟到的时间（默认0）

    remainder = (timestamp - offset) % windowSize;
 ·  （13s - 0 ）% 10 = 3
    （27s - 0 ）% 10 = 7
    if (remainder < 0) {
        return timestamp - (remainder + windowSize);
    } else {
        return timestamp - remainder;
        13 -3 = 10
        27 - 7 = 20
    }

 */
```



#### 水位线watermark

注意水位线并不是只有窗口才用得到，普通的流也可以用到watermark，并且设置定时器



事件时间 ，通过数据里的时间来推进，不随着系统时间走动。

水位线就是时间事件进展的标记：数据量小的时候可以每个事件获取水位线。当数据量非常大时，每隔一段时间生成一个水位线。

乱序+数据量小:判断事件时间和当前水位线大小比较，若小于不更新

乱序+数据量大：

迟到数据怎么处理：设置一个延迟时间，比如2s，则时间时间水位线(假设10s)会到12s时，10s窗口才关闭，若迟到太晚了，对应的窗口已经关闭，只能侧输出流。实际watermark等于事件事件 - 设置延迟



水位线传递，不同算子之间的watermark都不同，由前到后前面的算子比后面的算子水位线快。

水位线没听懂，多个map算子，会把最小的水位线，传递给下游。不太明白水位线传递给下游干什么。

为什么水位线是传递的，而不是通过事件每个算子重新生成一个，可能是map，process之后，传递类型不同了，获取不到事件时间，

所以只能传递。难道不可以数据，带一个watermark吗？如果这样的话，聚合算子带哪个watermark呢？



在多个上游并行任务中，如果有其中一个没有数据，由于当前Task是以最小的那个作为当前任务的事件时钟，就会导致当前Task的水位线无法推进，就可能导致窗口无法触发。这时候可以设置空闲等待，通过.wtihIdleness(Duration.ofSenconds)设置空闲等待时间。



窗口关闭，可以设置水位线延迟+允许迟到 



窗口迟到数据进入不到窗口的,





### window join

窗口之间的关联，比如滑动窗口。如果关联的数据分到2个窗口的话，会导致关联不上比如a,1   另一个流是a,11 那么关联不到。因为不同mysql表中创建数据的event time也是不同的，会出现事件事件相差很多的情况



为了减少这种情况，有iterval join 。iterval join只支持事件时间。iterval join的思路就是针对一条流的每个数据，开辟出其时间戳前后的一段时间间隔，看这期间是否有来自另一条流的数据匹配。已经不是窗口的join模式了，是2个思路。可以理解成每个数据各自开一个窗口，去匹配元属。

并且intterval join只能获取到关联到的数据，未关联的数据1.17版本支持直接获取，之前的版本不支持直接获取







# ProcessFunction底层API

#### process函数类别

Flink提供了8个不同的处理函数：

（1）ProcessFunction

最基本的处理函数，基于DataStream直接调用.process()时作为参数传入。

（2）KeyedProcessFunction



对流按键分区后的处理函数，基于KeyedStream调用.process()时作为参数传入。要想使用定时器，比如基于KeyedStream。

（3）ProcessWindowFunction

开窗之后的处理函数，也是全窗口函数的代表。基于WindowedStream调用.process()时作为参数传入。

（4）ProcessAllWindowFunction

同样是开窗之后的处理函数，基于AllWindowedStream调用.process()时作为参数传入。

（5）CoProcessFunction

合并（connect）两条流之后的处理函数，基于ConnectedStreams调用.process()时作为参数传入。关于流的连接合并操作，我们会在后续章节详细介绍。

（6）ProcessJoinFunction

间隔连接（interval join）两条流之后的处理函数，基于IntervalJoined调用.process()时作为参数传入。

（7）BroadcastProcessFunction

广播连接流处理函数，基于BroadcastConnectedStream调用.process()时作为参数传入。这里的“广播连接流”BroadcastConnectedStream，是一个未keyBy的普通DataStream与一个广播流（BroadcastStream）做连接（conncet）之后的产物。关于广播流的相关操作，我们会在后续章节详细介绍。

（8）KeyedBroadcastProcessFunction

按键分区的广播连接流处理函数，同样是基于BroadcastConnectedStream调用.process()时作为参数传入。与BroadcastProcessFunction不同的是，这时的广播连接流，是一个KeyedStream与广播流（BroadcastStream）做连接之后的产物。



#### process方法：

窗口的process方法，数据是攒一批然后统一处理，参数是个iterable

流的process方法,是一条一条来的，一条一条处理的。





#### 定时器timer

定时器必须是keyby中后的流才能使用,相同的key如果注册多次定时器，后注册的会替换老的定时器





# checkpoint

```
/**
 * TODO 检查点算法的总结
 * 1、Barrier对齐： 一个Task 收到 所有上游 同一个编号的 barrier之后，才会对自己的本地状态做 备份
 *      精准一次： 在barrier对齐过程中，barrier后面的数据 阻塞等待（不会越过barrier）
 *      至少一次： 在barrier对齐过程中，先到的barrier，其后面的数据 不阻塞 接着计算
 *
 * 2、非Barrier对齐： 一个Task 收到 第一个 barrier时，就开始 执行备份，能保证 精准一次（flink 1.11出的新算法）
 *      先到的barrier，将 本地状态 备份， 其后面的数据接着计算输出
 *      未到的barrier，其 前面的数据 接着计算输出，同时 也保存到 备份中
 *      最后一个barrier到达 该Task时，这个Task的备份结束
 */
```















# Table API

Flink1.12版本基本做到了完善，即使在1.17当前版本中TableAPI 和SQL依旧不算稳定

### 官网文档

在applicationg develop(应用开发)里面



### 优化

滑动窗口的时候步长和时间要是整数，这样TVF的API会优化，把滑动窗口，切分成多个滚动窗口，这样不会有太多重复数据

### savepoint

flink客户端，关闭任务时，执行save point,要事先设置save point制定路径，不然会报错。

如果临时执行reset save point ,后面要重置为空，不然后面所有的作业，都以这个save point路径保存

### catalog

catalog不持久化，下次进去就删除，但是表不删除。建了同名的cataloge，tables就出现了

flink能对接hive表,不过flink不是个流吗？难道能监控hive表中数据变化吗？

### 对接hive

每次执行sql，都执行个mr程序，这也太慢了？怎么控制执行的频率呢？

### 流批一体

tableapi 虽然看着是流，不过会根据你的数据来源头，决定是流处理还是批处理，一个sql，多场景使用











