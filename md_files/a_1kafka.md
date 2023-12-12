# 课程进度

p11

# paxos算法

知乎的这个是抄的，缺东西：https://zhuanlan.zhihu.com/p/31780743

下面是从知乎评论区找到的

https://www.cnblogs.com/linbingdong/p/6253479.html



# kafka遇到的坑

#### 消息排序

看知乎连接：https://zhuanlan.zhihu.com/p/351813190



# kafka历史版本特性

Kafka是一个分布式流处理平台，用于高吞吐量、可扩展的实时数据传输和处理。下面是Kafka的一些重要版本及其主要特性的概述：

1. Kafka 0.8.x系列：这是Kafka的初始版本，包括基本的消息传输和持久化功能。该版本引入了Kafka的核心概念，如主题（Topic）、分区（Partition）和消费者组（Consumer Group）。
2. Kafka 0.9.x系列：这是Kafka的重要升级版本，引入了一些关键的改进和新特性。其中一些重要的特性包括：
   - Kafka Connect：用于连接Kafka与外部系统的插件框架，简化了数据的导入和导出。
   - Kafka Streams：用于构建实时流处理应用程序的库，使得在Kafka上进行流处理更加方便。
   - 新的消费者API：引入了新的Java消费者API，提供更好的消费者管理和协调能力。
   - 消息格式兼容性：支持在不中断服务的情况下对消息格式进行升级和演进。
3. Kafka 1.0.x系列：这个版本引入了一些重要的改进和新特性，包括：
   - 事务支持：引入了事务性生产者和消费者API，使得在Kafka中实现原子性的消息处理更加容易。
   - 消息幂等性：提供了幂等性的生产者API，确保相同消息的重复发送不会导致数据重复。
   - 改进的管理工具：提供了更好的管理和监控工具，如Kafka集群管理工具、监控指标等。
4. Kafka 2.0.x系列：这个版本引入了一些重要的改进和新特性，包括：
   - Exactly-Once语义：通过引入事务性读写API和幂等性消费者API，实现了精确一次的消息处理保证。
   - Kafka Streams增强：提供了更多的流处理功能和操作，如窗口操作、状态存储等。
   - 改进的Kafka Connect：增加了更多的连接器和插件，使得与其他系统的集成更加方便。

这些是Kafka版本中的一些重要特性，升级到较新的版本可能会带来更好的性能、功能和可靠性。然而，升级也可能需要进行一些工作，如配置更改、应用程序兼容性测试等。因此，在决定是否升级之前，建议您进行充分的评估和测试，以确保升级对您的业务有实际的益处。同时，还应该考虑与其他系统和工具的兼容性，以确保整个技术栈的稳定性和一致性。





# 消息队列作用

1 消费者拓展性

消息发布者，只管往队列里传数据，谁消费自己去拉取，增加的消费者的拓展性，相比于推送消息的方式。

2  消峰缓冲作用

kafka的吞吐量很大，写入很快，对于有的框架写入很慢的，可以用kafka消峰，高峰期数据太多的问题

3 解耦

数据发送者和接受者解开，不是直接用代码联通，减少代码开发。

比如mysql,monggo,flume多个数据库，对接多个消费者(hadoop,flink,spark)，不可以n*m的方式，每种配对都写一个api

大家统一完成对kafka的接口就行，这样通过kafka就能连通了

4 异步处理

用户注册后2个操作，1返回页面   2发送短信(操作很慢),如果第一个用户访问没执行完毕，第二个用户访问不能执行

所以把发送短信操作改为写入kafka中(写入kafka执行很快)，然后另外一个程序执行这个，1个连贯动作变成2个程序来连贯。

# kafka组成与原理

kafka概要

kafka的消费者根据自己的处理速度，来去kafka中拉取数据。

zk中记录了谁是leader，kafka 2.8版本之后可以不配置zk,逐渐去zookeeper化

10个服务器中，只用安3个zk， 3-4个kafka就行，不用全装。当kafka集群性能不够时，再拓展kafka



### partition（问题？？）

设置多个partition的原因:1 提高吞吐量  2 方便分布式并行处理(对接flink等,多个map对应多个partition) 



 一个消息队列分几块，10个服务器，如果分10个的话partition的话，是每个服务器分1个吗？？那么当有10个消费者组，这样没问题。

如果只有1个消费那么要去10个服务器去拉取数据这样不合理吧？

10个partition最多能被10个consume消费，所以合理设置consumer苏亮

### learder

一个topic可以设置多个副本，比如3个副本，kafka启动时，每个partition会挑选一个副本做为leader，然后消费者，生产者和这个leader交互，follower作用是实时同步leader数据,当leader失效的时候，成为leader

这里的问题就是怎么保证leader和follower数据一致性的问题了



### 生产者发送流程

1 发送流程

mian线程=>创建个producer, 调用.send(recorder) =》会有个interceptor拦截器=》序列化器Serializer

=》Partitioner分区器来判断发送到哪个分区=〉内存开辟32M(默认)空间，创建个RecordAccumulator,装多个分区的queue

=>当每个queue中数据 producerBath达到16k(默认),sender 线程会读取queue数据，如果sender等待linger.ms时间，batch还没满

也会去queue中拉取数据=》当sender拉取batch后，会往各个分区发送请求，如果某个分区没应答，会向别的分区发送请求，最多缓存5个请求=>当分区收到数据后，会有个ack应答机制，0(不等数据罗盘就应答) ,1 (leader落盘后应答)，-1(leader和follwer都落盘再应答)

2 异步发送



# 顺序读写和随机读写

```sql
#顺序读写
顺序写入：将消息按照顺序追加到磁盘上的日志文件中，而不是随机写入。这可以通过将消息追加到文件末尾来实现，而不是在文件中寻找空闲位置进行写入。这样做可以最小化磁盘的寻道时间，提高写入效率。
顺序读取：按照消息的顺序从磁盘上的日志文件中读取消息。与随机读取相比，顺序读取可以减少磁盘寻道的次数，提高读取效率。

#顺序读写缺点
但也存在一些缺点。以下是一些常见的顺序读写的缺点：

无法随机访问：顺序读写只能按照数据的顺序依次读取或写入，无法直接访问文件中的特定位置或记录。如果需要快速访问或修改文件中的某个特定数据，顺序读写就无法满足需求。

更新困难：顺序写入只能将数据追加到文件的末尾，无法直接修改已有的数据。如果需要更新已有数据，例如修改某个记录或删除某个数据，顺序读写就不够灵活。这可能需要额外的操作来实现数据的更新或删除。

不适用于随机访问模式：如果应用程序的访问模式是随机的，需要经常在文件中不同的位置进行读写操作，顺序读写就会显得低效。每次读写都需要从文件的开头开始顺序扫描，直到找到目标位置，这会增加访问时间和开销。

难以适应动态数据：如果数据的大小经常变化，顺序读写可能会面临一些挑战。当需要追加数据时，可能需要调整文件的大小或重新分配存储空间，这可能会导致性能下降或增加复杂性。

不适用于并发访问：如果多个进程或线程需要同时读写文件，顺序读写可能无法有效地支持并发访问。由于顺序读写是按照数据的顺序进行操作，可能需要进行同步或加锁操作来保证数据的一致性和正确性，这可能会引入额外的开销和复杂性。

#随机读写
尽管顺序读写在某些情况下可以提供更高的性能，但随机读写仍然具有一定的存在意义和适用场景。以下是一些解释：

灵活性：随机读写允许在文件的任意位置进行读写操作，而不受顺序的限制。这样可以更灵活地处理数据，满足不同的需求。例如，在某些场景下，需要随机访问特定记录或进行部分更新，这时随机读写是必要的。

实时性要求：某些应用程序对实时性有较高的要求，需要立即读取或写入数据。顺序读写可能需要等待一段时间才能访问到目标数据，而随机读写可以立即进行操作。例如，某些实时分析或交互式查询的场景，需要快速访问特定数据，这时随机读写是必要的。

数据更新需求：随机读写适用于需要频繁更新数据的场景。顺序读写通常是追加数据到文件末尾，不支持直接修改已有数据。而随机读写可以在任意位置进行写入，允许对已有数据进行修改或删除。例如，数据库系统需要支持事务和更新操作，这时随机读写是必要的。

数据分布和负载均衡：某些场景下，数据可能分布在不同的存储设备或节点上，顺序读写可能无法有效利用并行性和负载均衡。随机读写可以在分布式环境中更好地实现负载均衡和并行处理。例如，分布式存储系统或分布式数据库需要支持并发读写操作，这时随机读写是必要的。

总的来说，顺序读写和随机读写各有其适用的场景。选择合适的读写方式取决于具体的应用需求、数据访问模式和性能要求。在设计和实现中，需要权衡不同因素，选择最合适的读写策略以满足特定的需求。
```



# 参数设置



#  常用指令

kafka-topic.sh 什么都不输入，就会显示有哪些参数可以输出



### 启动关闭

启动在各自节点上执行  kafka-server-start.sh -daemon $KAFAKA_HOME/config/server.properties

关闭:  各自节点执行 kafka-sever-stop.sh

### topic相关

连接服务器  --bootstrap-server   lpc@project1:9092,project2:9092

指定主题	--topic

查看所有topic    --list

创建topic   --create

删除topic  --delete

修改topic   --alter

topic详情   --describe

设置topic分区数  --partitions

设置topic副本数  --replication-factor

更新系统默认配置  --config



创建topic

kafka-topics.sh   --bootstrap-server  lpc@project1:9092   --create --topic name   --partitions 2   --replication-factor 2

删除topic

kafka-topics.sh  --bootstrap-server  lpc@project1:9092  --delete --topic  name

需要server.properties中设置delete.topic.enable=true否则只是标记删除。

查看topic详情

kafka-topics.sh --bootstrap-server dev@pre-13:9092 --describe --topic first

修改分区数

kafka-topics.sh --bootstrap-server dev@pre-13:9092 /kafka --alter --topic first --partitions 6



和topic相关的用bootstrap-server服务端

--broker-list是broker的节点。



### 发送消费数据

1 向topic中发数据（必须是broker_list）

用bootstrap_server不行，报错

kafka-console-producer.sh   --broker-list     lpc@project1:9092   --topic   maxwell

下面的是执行不了的

kafka-console-producer.sh   ---bootstrap-server     lpc@project1:9092   --topic   maxwell



2 消费topic数据

kafka-console-consumer.sh --bootstrap-server dev@pre-13:9092 --from-beginning  --topic aaa

# kafka优化

# API

### 异步发送

指从producer 发送到RecordAccumulator,装多个分区的queue的异步发送

pom

```

```







### 消费者偏移量：

kafka对有消费者组偏移量有3中，latest,earliest,none  默认是latest，可以指定是earliest	

kafka自己的API种，kafka的auto.reset.offsets
earlist:如果有offset,从offset继续消费，没有从最早消费
lastest:如果有offset,从offset继续消费，没有从最新消费

并且kafka可以代码中实现指定偏移量消费，比如一天前的消息，需要重新消费一下。这个要去kafka api去观看



# 云服务器kafka配置

就是如果你没有做hosts映射的话，你kafka配置文件需要advertised.listeners=PLAINTEXT://x.x.x.x:9092

注意不要改#listeners=PLAINTEXT:x.x.x.x//:9092，这个改了之后kafka启动不起来。