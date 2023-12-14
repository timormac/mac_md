# 课程进度

到p108容错机制 p108跳过了

109到114的检查点算法听的不太懂，后续有机会自己消化一下

p166-169没听

# 项目bug记录

### 水位线不推进

为了解决乱序问题，手动指定分区规则，4个分区，整除3漏了一个，导致有个分区一直没数据。

下游消费的时候并行度设置为4，导致某个无数据，水位线不推进。



# 问题记录

### 可用slut为0但是能提交任务

yarn-application模式，可用slots是0，但是能提交一个3并行度的任务,不知道为什么

只能提交第一个任务，第二个任务提交时，提交不了了，一直卡在了，显示

Deployment took more than 60 seconds. Please check if the requested resources are available in the YARN cluster
Deployment took more than 120 seconds. Please check if the requested resources are available in the YARN cluster



如果时先启动yarn-session服务器，发现连第一个任务都启动不了，不知道为什么，一直卡在申请container



### log4j日志不打印

代码里指定了log4j打印目录，在idea能自己创建目录，上传到集群，log日志无法生成



### flink任务每次临时下载jar包

fink任务每次临时下载jar包，那么如果我执行多个任务，下载多次吗？

还是说第一次下载jar包后，存在本地某个目录，以后先去目录找，再决定是否下载

### hdfs的项目包无法执行

下面2个都是yarn-application模式，不过本地的jar能正常执行，但是hdfs上的jar无法正常执行，报错如下：

 No ClusterClientFactory found. If you were targeting a Yarn cluster, please make sure to export the HADOOP_CLASSPATH  environment variable or have hadoop in your classpath.

​	个人理解就是如果通过hdfs 必须在hdfs上有jar包并且必须参数指定lib才行，或者说是没有连接上project1:8020就是没找到hdfs所在的执行环境

```shell
./bin/flink run-application -t yarn-application -c com.timor.flink.learning.demo.A3_WordCountStreamSocket  hdfs://project1:8020/flink-jars/git_flink_learning_1.17-1.0-SNAPSHOT.jar


./bin/flink run-application -t yarn-application -c com.timor.flink.learning.demo.A3_WordCountStreamSocket   ./git_flink_learning_1.17-1.0-SNAPSHOT.jar
```



2任务槽设置中，是在flink配置文件设定的，但是flink on yarn，其他子节点都没安装flink，设置插槽数量有什么用？？

### batch应用场景

什么时候用batch批，什么时候用stream流模式

flink的分区策略有什么用，大部分flink是消费消息队列kafka，而kafka的API应该是有自己的数据发送模式，flink设置了应该没用

### 三流join怎么实现

  3流以上的join怎么实现的，目前用connect+ process只能实现2流join

 有个问题就是窗口我之前的map流设置并行度为2，keyby返回的流不能设置并行度，但是用keyby获得的窗口默认并行度是8



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

### 传入方法在哪被调用

看一些源码的时候，有时候需要传入一个借口，实现某个方法，比如flink的自定义map方法，有个问题，就是我现在想知道，这个传入的map方法，到底是谁在哪一步开始调用的，现在一直没头绪

### watermark传递机制

flink中waterMark是怎么传递的，比如先map 然后 process，不同算子之间，是根据流过的数据来更新watermark吗

### 定时器重复注册

keyBy后的流，同一个key，注册多次定时器，会发生什么因为topn代码中，流的process注册了定时器，并且同一个key重复注册了，

不会出问题吗？

### ArrayIndexOutOfBoundsException

A2_TopnWindowAll有个bug，就是总是报错.ArrayIndexOutOfBoundsException: -2147483648，不知道原因

已经确定不是nc输出错误数据的问题了。好像设置并行度为2的时候就不会出问题了

### windowall并行度不为1

在 A2_TopnWindowAll有个问题，就是用了windowall，最后输出结果还是多个并行度结果

### 不同执行模式区别

去csdn查一下，session和standalone，application模式应用场景与区别



### checkpoint未整理问题

1  为什么cep设置为hdfs路径时，pom文件要导入hadoop依赖，代码里没有用haddoop的包啊

3  checkpoint不是应该和status状态编程连用吗？为什么demo里可以单独用

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



# 问题已解决

### 水位线不推进

1  事件水位线推进，自己的代码有bug：

```java
/*bug原因找到了,因为没设置并行度导致默认是8个线程，而水位线必须8个流里的数据都有数据并且事件时间更新到10s时才触发process执行
*因为之前输入的key都是a,b导致其他线程没数据，导致其他线程水位线时间不更新，所以尽管a,1000但是还是不触发process窗口关闭
* 后面设置并行度为2,就好了，不过必须a,b 2个事件时间都超过10
          * 为了避免这种情况可以设置空闲时间等待.withIdleness(Duration.ofSeconds(10))
          * //空闲等待10s，即当10s内其他分区没有数据更新事件时间是，等10s，按最大的时间时间同步到其他没数据的分区
* */
```

### 定时器重复注册

在KeyedProcessFunction中可以住车定时器。processElement函数中每次处理一条数据，这样重复注册定时器，不会导致定时任务重复调用吗？

答案是不会，应为Flink内部使用的HeapPriorityQueueSet来存储定时器，一个注册请求到来时，其add()方法会检查是否已经存在，如果存在则不会加入。并且是根据key来注册的。如果重复注册并且更改触发时间的话，需要自己去测一下

### 找不到flink-kafka类

flink本身并不包含这些拓展文件，虽然我们代码里有kafkasource，但是是pom自己导入的，不是flink自带的，所以需要我们自己打包带的jar包，或者上传服务器

pom里配置了这个

<!--  连接kafka流 -->
<dependency>
    <groupId>org.apache.flink</groupId>
    <artifactId>flink-connector-kafka</artifactId>
    <version>${flink.version}</version>
    <scope>provided</scope>
</dependency>









### yarn-session模式起不来任务

```sql
#slut为0 
看到flink UI界面，显示slut 为0 ，看到各集群free -h  剩余没有大于1.5G的内存。看了下配置文件,需要task的内存默认是1.7G,所以可以插槽为0 
#application任务被杀
启动任务后显示任务被yarn杀掉
原因： 如果 Flink 或者用户代码分配超过容器大小的非托管的堆外（本地）内存，部署环境可能会杀掉超用内存的容器，造成作业执行失败。
#更改配置文件后连yarn-sesion都起不来
为了资源够slut,更改flink配置文件，发现起不来了。后面查阅发现，好像比如jobmanager和taskmanager有一定内存比例的，而且分给某些线程的内存要在固定60m-256m范围之间，因为只改了jobmanager和taskmanager的内存配置，所以起不来了。
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



# Flink集群

### 客户端指令

启动：在project2中执行 bin/start-cluster.sh  

UI端口 8081

# flink-yarn模式

### 会话部署(session)

```sql
#会话模式场景
在会话模式下，Flink集群会一直运行，并在需要时接受多个应用程序的提交和执行。
应用程序可以通过Flink的客户端提交到集群，并保持运行状态，直到显式地取消或终止。
这种模式适用于需要交互式开发和测试多个应用程序的场景，或者需要长时间运行的应用程序。

#启动session集群命令，启动后有UI界面，并且提交的application任务
/bin/yarn-session.sh -nm tiomr_session

---------------------------------------------------------------------------------
#会话模式，会提交到session集群中
bin/flink run-application -t yarn-application -c Wordcount  a.jar 

#应用模式和会话模式写法相同，不过应用模式，不需要提前启动session集群
bin/flink run-application -t yarn-application -c WordCount a.jar 
#单作业
bin/flink run -d -t yarn-per-job -c WordCount a.jar



其他参数
#指定yarn的lib目录,减少flink依赖包上传时间，其他节点没安装flink没有相关lib
-Dyarn.provided.lib.dirs="hdfs://project1:8020/flink-dist/*"
#指定主类
-c com.atguigu.wc.SocketStreamWordCount
#jar路径可为hdfs路径
hdfs://hadoop102:8020/a.jar

#通过--help 指令查看帮助，可能用到的
-qu，——queue <arg>指定YARN队列。 
 -at，——applicationType <arg>为YARN上的应用设置自定义应用类型 
-D <property=value>使用给定属性的值 
-d，——detached如果存在，则以分离模式运行作业 
-h，——help Yarn会话命令行帮助。 
-id，——applicationId <arg>附加到正在运行的YARN会话 
-j，——jar <arg> Flink jar文件的路径 
-jm，——jobManagerMemory <arg> JobManager容器内存，可选单位(默认:MB) 
-m，——jobmanager <arg>要连接的jobmanager (master)的地址。使用此标志连接到与配置中指定的JobManager不同的JobManager。 
-nl，——nodeLabel <arg>指定YARN应用的YARN节点标签 
-nm，——name <arg>设置YARN上应用程序的自定义名称 
-q，——query显示可用YARN资源(内存，内核) 
-s，——slots <arg>每个TaskManager的插槽数 
-t，——ship <arg>发送指定目录下的文件(t用于传输) 
-tm，——taskManagerMemory <arg>每个TaskManager容器的内存，可选单位(默认:MB) 
-yd，——yarndetached如果存在，则以分离模式运行作业(已弃用;使用非特定于yarn的选项代替) 
-z，——Zookeeper Namespace <arg> Namespace用于创建高可用模式下的Zookeeper子路径
```



### 单作业模式

```sql
#使用场景
单作业模式下，每个应用程序都会启动一个独立的Flink集群，并在应用程序执行完成后自动关闭。
这种模式适用于需要独立部署和管理的单个应用程序，每个应用程序有自己的资源需求和环境要求。

#启动命令
bin/flink run -d -t yarn-per-job -c WordCount a.jar
```



### 应用模式

```sql
#使用场景
应用模式是在YARN上运行Flink应用程序的一种模式，它可以将Flink应用程序作为YARN应用程序提交和执行。
YARN会为Flink应用程序分配资源，并负责管理应用程序的生命周期。
相当于通过yarn启动了个session集群


#启动命令
bin/flink run-application -t yarn-application -c WordCount a.jar 

#指定lib路径，减少上传hdfs
-Dyarn.provided.lib.dirs="hdfs://project1:8020/flink-dist/*"
#jar可指定hdfs路径
hdfs://project1:8020/a.jar


#全命令演示
./bin/flink run-application -t yarn-application    -Dyarn.provided.lib.dirs="hdfs://project1:8020/flink_need/flink_jars_lib"      -c FlinkTestMain  hdfs://project1:8020/flink_need/demo_jars/flink_test-1.0.jar

```







# —————FlinkAPI———————



# pom依赖

```xml
    <properties>
        <!--  写好flink版本，后续变更不需要每个都改，只改properties的属性    -->
        <flink.verson>1.17.0</flink.verson>
        <maven.compiler.source>8</maven.compiler.source>
        <maven.compiler.target>8</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

 <dependencies>
   
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-streaming-java</artifactId>
            <version>${flink.verson}</version>
        </dependency>

        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-clients</artifactId>
            <version>${flink.verson}</version>
        </dependency>
</dependencies>
```





# 环境与算子

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

dataset写法是一个批处理方式，已经过时了。1.12以后已经用DataStream的API通过set batch参数就能用一个代码，同时可实现流处理和批处理

#### 自定义可序列化

Flink对POJO类型的要求如下：

l 类是公有（public）的

l 有一个无参的构造方法

l 所有属性都是公有（public）的

l 所有属性的类型都是可以序列化的

并且实现了searilized接口

#### 常用算子

基本算子map,filter,flatMap  聚合算子 keyBy,sum,min,max,minBy,maxBy,reduce

聚合算子sum,reduce等，必须在keyby之后,也就是KeyedStream类型才能调用这些



#### 分区策略

常见的物理分区策略有：随机分配（Random）、轮询分配（Round-Robin）、重缩放（Rescale）和广播（Broadcast）

分区策略是指同一个消息源，按什么方式发送给并行度,比如2个并行度，如果按random，运气不好可能全发给2线程

random策略通过 ds.shuffle()来调用

轮询策略通过ds.rebalance()来调用

广播策略通过ds.broadcast()调用，所有的消息发送给所有并行度，重复数据



#### 分流合流

union省略过

connect 如果用process进行

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





#### process函数

process的方法，可以拿到context上下文，这个context能拿到侧输出流,能拿到wiondow(对于窗口stream的process方法)



触发器

移除器

时间语义

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



#### window join

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

# 状态管理

在process方法中，定义一个ValueState<Interger>，即是状态，和自己定义一个变量 int a有区别

当keyby分区的时候，定义的ValueState不同的key有各自的，而定一个int a不同key公用一个.

必须在open中初始化，如果在定义时初始化，会因为类加载问题报错。

如果不够flink提供的State类，那么自己存的话，要用map去存，存一个key对应的value



### checkpoint

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



# Flink优化

### 内存模型



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



# CDC

用了和canal和maxwell一个类似的框架，derbzem来实现flink直接监控mysql变化的。

用处，不通过maxwell和kafka直接去mysql里监控，少一层。









