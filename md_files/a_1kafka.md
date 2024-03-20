# 视频进度

p19事务没听懂，结合笔记看

看到p85源码



# 问题待解决

#### 分区间幂等性

说是幂等性只能保证分区内的消息不重复，想不到什么场景，会分区间消息重复。

3分区，只有1个副本。有一个分区挂了，难道producer会转发到别的分区吗？如果是这样，那么确实是可以的。

或者说副本全挂了。



#### 消费者拉数据

视频说是频次是：每隔一段时间拉取，或者batch达到一定大小拉取。

时间我可以理解，API代码里也有设置。这个大小怎么理解？难道到时间了去拉取，不够的话，不拉取吗？

不太理解



#### 消费者分区策略重连 

问题是，当consumer挂了，会触发在分区。当重启之后，还能保证和原来的消费分区一致吗？

#### 消费者事务代码怎么写

当下游支持事务时，比如mysql，那么如何保证offset提交





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

5.  2.8新特性，kafka-kraft模式，把zookeeper干掉了





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



# paxos算法

知乎的这个是抄的，缺东西：https://zhuanlan.zhihu.com/p/31780743

下面是从知乎评论区找到的

https://www.cnblogs.com/linbingdong/p/6253479.html



# kafka遇到的坑

#### 消息排序

看知乎连接：https://zhuanlan.zhihu.com/p/351813190







# 查看日志排查问题

### kafka启动不起来

```mysql
#问题描述
kafka启动后,自己挂掉

#日志位置
在logs目录下的:kafkaServer.out文件
因为我在server.properties文件中设置logs.dir 为另一个目录，所以日志和数据分开了

#日志报错
找到报错如下：
[2024-03-16 16:08:39,598] ERROR Error while creating ephemeral at /brokers/ids/0, node already exists and owner '72058210558017539' does not match current session '72060294662848513' (kafka.zk.KafkaZkClient$CheckedEphemeral)
[2024-03-16 16:08:39,603] ERROR [KafkaServer id=0] Fatal error during KafkaServer startup. Prepare to shutdown (kafka.server.KafkaServer)
org.apache.zookeeper.KeeperException$NodeExistsException: KeeperErrorCode = NodeExists
	at org.apache.zookeeper.KeeperException.create(KeeperException.java:126)
	at kafka.zk.KafkaZkClient$CheckedEphemeral.getAfterNodeExists(KafkaZkClient.scala:1815)
	at kafka.zk.KafkaZkClient$CheckedEphemeral.create(KafkaZkClient.scala:1753)
	at kafka.zk.KafkaZkClient.checkedEphemeralCreate(KafkaZkClient.scala:1720)
	at kafka.zk.KafkaZkClient.registerBroker(KafkaZkClient.scala:93)
	at kafka.server.KafkaServer.startup(KafkaServer.scala:270)
	at kafka.server.KafkaServerStartable.startup(KafkaServerStartable.scala:44)
	at kafka.Kafka$.main(Kafka.scala:84)
	at kafka.Kafka.main(Kafka.scala)
	
	
#原因分析
ERROR Error while creating ephemeral at /brokers/ids/0, node already exists and owner '72058210558017539' does not match current session '72060294662848513'：这里指出在尝试创建临时节点时遇到了节点已经存在的问题，并且节点的所有者与当前会话不匹配。

org.apache.zookeeper.KeeperException$NodeExistsException: KeeperErrorCode = NodeExists：这是 Zookeeper 报告的异常，指示节点已经存在。

这种错误通常发生在以下情况下：

Kafka 服务器重启：如果 Kafka 服务器在 Zookeeper 中注册了节点，并且在重启时尝试重新注册相同的节点，就会导致此错误。

Zookeeper 数据残留：可能是由于 Zookeeper 数据未正确清理或者上一次 Kafka 服务器关闭时未正确注销节点导致的。

#解决方法
 ./zkCli.sh  -server localhost:2181  进去zk
 ls /kafka   查看zk中kafka节点问题
 
 
 #事故总结
 因为执行kafka stop 并没有关系kafka，手动kill -9 kafka进程,不知道是不是这个原因,导致了zookeeper上节点数据未清理干净
 也有可能是wifi断开的原因，具体还待回顾
```





# 客户端指令

kafka-topic.sh 什么都不输入，就会显示有哪些参数可以输出



### 启动关闭

启动在各自节点上执行  kafka-server-start.sh -daemon $KAFAKA_HOME/config/server.properties

关闭:  各自节点执行 kafka-sever-stop.sh

### topic相关

查看所有topic  

 kafka-topics.sh   --list  --bootstrap-server lpc@project1:9092 

创建topic

kafka-topics.sh   --bootstrap-server  lpc@project1:9092   --create --topic name   --partitions 2   --replication-factor 2

删除topic

kafka-topics.sh  --bootstrap-server  lpc@project1:9092  --delete --topic  name

需要server.properties中设置delete.topic.enable=true否则只是标记删除。

查看topic详情

kafka-topics.sh --bootstrap-server  lpc@project1:9092  --describe --topic first

修改分区数

kafka-topics.sh --bootstrap-server   lpc@project1:9092  --alter --topic first --partitions 6



和topic相关的用bootstrap-server服务端

--broker-list是broker的节点。



### 发送消费数据

1 向topic中发数据（必须是broker_list）

用bootstrap_server不行，报错

kafka-console-producer.sh   --broker-list     lpc@project1:9092   --topic   maxwell



2 消费topic数据

kafka-console-consumer.sh --bootstrap-server lpc@project1:9092 --from-beginning  --topic a --group group1



3查看消费者组的偏移量，不能指定话题

kafka-consumer-groups.sh --bootstrap-server   lpc@project1:9092 --group my_group1   --describe

4查看有哪些消费则组

kafka-consumer-groups.sh --bootstrap-server project1:9092    --list







# API参数调优

```sql
#合理设置kafka副本数
2个或以上，太多也不行。占用空间大，并且同步通信太慢了，延迟高。

#kafka分区数


#调整producer吞吐量
batch.size:默认16k 
linger.ms :默认为0  一般设置5-100ms  设置了就有延迟
compression.type:压缩snappy  压缩了batch能放更多数据
recordAccumulator 缓冲区大小 默认64M  ,这个调大也可以 #有疑问这个recordAccumulator和上面batch.size关系
retyies 调整为10次，默认是int最大值
配置文件开启幂等性,默认值就是true

#request默认缓存为5,若想消息分区内有序，需要设置为1
max.in.flght.request.per.connection =1 
开启幂等性后 max.in.flght.request.per.connection <= 5即可,
底层记录了最近5个request的元数据，因为幂等姓中的sequece是单调递增1的，所以能感知到数据乱序了，临时放缓存


#producer数据精准一次
数据不丢: ack=-1 且副本>=2
开启幂等性，producer开启事务



```

### kafka拦截器

```mysql
#拦截器作用
kafka消费者拦截器和消费后过滤，实现结果想通。不过一个流,每个处理都要进行数据清洗，那么设置一个拦截器更好。不需要每个业务都写这个代码。
flink创建kafka流时，能设置参数执行拦截器的类,具体问gpt。
消费者拦截器是在flink端执行，不是在kafka服务器执行
```



# producer

### 总结

```sql
#可调参数
recordAccumulator中的batchsize和linger.ms
ack级别
selector中的retries次数
```



### 概览

```sql
#main线程调用Producer
调用send(recoder)方法，要对数据进行加工，变成recoder

#Inerceptors拦截器(可选)

#序列化器Serializer

#分区器partitioner
把数据发送到按分区发送到recordAccumulator的queue

#recordAccumulator
topic 3个分区，会在recordAccumulator创建3个queue
内存大小默认32M
默认的batch.size(16k)会去发送一次数据
或者linger.ms 默认的是0ms，来一条发一条。所以会导致上面的batch失效

#sender线程
调用NetworkClient ,拉取recordAccumulator中queue。
每个对应的broker，有单独的队列，最多连续发5个request请求，不等broker回应，最多缓存5个请求。为了处理乱序，后面会讲

#selector
当应答ack返回成功后,会先清理缓存的request缓存，然后清理recordAccumulator中queque数据
当ack没有应答或者应答失败，就重试retries从sender线程里的request缓存，先broker重试，默认的int的最大值次数。可以修改


#kafka的ack等级
0  不等落盘应答
1	 leader收到落盘后，应答	
-1(all) leader和follower都落盘后,应答

#异步发送/同步发送
同步发送就是要发送的数据，完整写入broker中才行，等待ack响应。
异步发送就是要发送的数据,写入recordAccumulator的queue中,就不管了
         * 异步发送，就是直接执行发送操作，不管后续是否成功，继续下一行代码
         * 一般通过发送消息里面封装的回调函数来，处理发送失败后，应该执行什么
         * 回调函数，是异步编程的一种模式

```

### partitioner分区器

```sql
#存储负载均衡
手动控制分区任务，可以实现负载均衡,这里是指望消息存储的均衡，比如容量小的kafka节点,我们将它设置频率低些。
而不是消息的请求qps的负载均衡
#提高并行度
这个是消息的请求qps的负载均衡

#分区接口Partitioner
默认的分区器：DefaultPartitioner

```



### producer数据可靠性

```sql

#挂了的含义
是通信超过30s了，还未连接成功。不一定是挂了，也可能是短期内网络问题，过一会就连上了

#ack选择
0 基本不用
1 当leader挂了，并且follower定期同步数据没触发，下游消费会出现丢数据
-1 不会丢，但可能重复

#生产者数据可靠性
数据可靠性的含义：不重复，不丢失

#数据丢失
场景1:
producer把数据发给leader,当ack=1时,当leader应答了,producer认为数据存成功了，这时leader挂了。
kafka从副本中选一个leader,消费者消费的数据是缺少的，并且无感知。ack = -1 能避免这个问题

场景2:
ack=-1,但是副本只设置1个,这个数据不会出现丢的情况。因为leader挂了，会导致producer一直retrys。不会出现上面返回ack了，但是下游消费数据少了一条。可以理解成多个副本，同时全挂了，不会丢数据。

场景3：
ack=-1 ,副本>=2且isr里应答副本数>=2 。则数据不丢，切有容错机制

#数据重复
当ack = -1, leader通知follow都同步成功后，还未发送ack，leader网络出现问题,producer 30s没收到leader消息，
producer会找新副本当新leader。但是这个副本前一次已经同步成功了，导致数据重复


#精准一次
ack=-1且副本>=2 保证数据不丢，但是可能重复
加上broker的幂等性 = 精准一次

#幂等性
<pid,partition,seqNumber>相同的数据，broker会识别为重复数据,只会持久化一条。
pid和kakfa服务器有关，重启后会变.
partition,需要保证那条数据进入相同的分区 #leader挂了，follwer成leader出2条数据。producer那边不挂，进入分区是不会变的。
seqNumber,是分区内消息单调自增1的

#生产者事务(没听懂，想不到场景)
说是幂等性只能保证分区内的消息不重复，想不到什么场景，会分区间消息重复。
要想完全精准一次,需要生产者那边开启事务，就是代码里写事务。
必须手动指定事务id

#消息有序
场景 : flink消费kafka的数据，比如maxwell监控一条数据更改2次，那么一定要按先后去更新的，不然可能后改的先到，导致数据对不上。

kafka因为可以缓存5个request，所以当3,4成功 1,2失败导致重试的时候，会出现分区内乱序，所以设置request缓存为1就能解决分区内乱序。

```



### ISR机制

```sql
in-sync replicationg set
#概念
1个topic有多个5分区，每个分区有5个副本,leader是5个副本中的主,producer 是和leader通信传输数据。
副本的作用，容错率，当leader挂了，仍有副本数据可以用。

#isr背景
目的当ack为-1时, leader会等所有follower同步完成，才发送ack，当某一个挂了，为了防止leader一直等待，提出了isr机制。

Leader维护了一个动态的in-sync replica set (ISR)，意为和leader保持同步的follower集合。当ISR中的follower完成数据的同步之后，leader就会给producer发送ack。如果follower长时间未向leader同步数据，则该follower将被踢出ISR，该时间阈值由replica.lag.time.max.ms参数设定。
并且Leader发生故障之后，也是从ISR中选举新的leader。

```



# broker

### 对接zookeeper

```sql
#保存哪些数据
briokers,topics,seqid

#brokers
保存kafka可用节点

#topics
记录 不同topic的parttitions信息， leader信息和isr信息

#consumers
0.9版本前放在zookeep里，后面放在kafka的内部offset主题里了

#controller
里面只有一条数据，没有多分支，辅助lead选举

```

### 副本机制/lead选举

```sql
#副本个数
2-3个，不应太多。多了费磁盘，并且全同步时间会变长

#leader和follower
生产者传数据，只会和leader通信，follower定期会找leader同步数据

#leader自动平衡功能
3个kafka服务器，可能出现大部分的副本的leader都选在A broker上了，这时应该让其他broker的follower当leader更好，
不然A Broker的IO过高了
auto.leader.rebalance.enable 为true，默认时开启的
当broker的leader数量相差10%那么就会触发，这个参数可以扩大，让不触发
300s检查一次  leader.rebalance.check.inerval.seconds设置

#手动指定副本存储
可以干预副本存在哪里，如果有的服务器的磁盘小，不想放

#leader选举
具体听p31
leader就是broker的节点的子线程，所以leader挂了，就是broker挂了。
#leader挂了恢复细节
#follower挂了恢复细节

```

### 创建topic

可以指定 分区数 ，副本数，消息过期时间。等很多

```sql
在Kafka中，创建主题时可以指定多个参数来配置主题的行为和属性。除了分区数、副本数和消息过期时间，还可以指定以下参数：

cleanup.policy：指定日志清理策略，用于控制何时删除过期的消息。常见的策略包括删除策略（delete）和压缩策略（compact）。

retention.ms：指定消息在日志中保留的时间，以毫秒为单位。超过该时间的消息将被删除。

retention.bytes：指定消息在日志中保留的最大字节数。一旦达到该限制，较早的消息将被删除。

max.message.bytes：指定单个消息的最大字节数。超过此大小的消息将被拒绝。

compression.type：指定消息的压缩类型。可以选择的选项包括“none”（无压缩）、“gzip”、“snappy”和“lz4”。

unclean.leader.election.enable：指定是否允许使用未同步副本进行领导者选举。默认情况下，此选项为false，即只有同步副本才能成为领导者。

min.insync.replicas：指定至少需要确认写入的副本数。当可用副本数低于此值时，生产者将收到一个异常。

segment.bytes：指定日志段的大小，以字节为单位。当日志段达到该大小时，将创建一个新的日志段。
```



### 存储方式

```sql
#segment
 消息是按segment 去存，一个G一个文件，
 包含3个块,
 有个.log和.index，.timeindex   .log时数据文件，其他2个是索引
 
 #.log
 如何定位具体的offset位置，具体看p38。
 文件名字是文件开始的offset位置
 比如：0001.log   00301.log  0601.log
 当你定位288时，会去0001.log文件去找,然后去查index
 下一个文件时301 一次减去.inex里的相对0ffset，能定位到position下标，然后遍历
 
#.inex
 偏移量索引,当指定偏移量消费时，用这个索引定位数据位置
 是稀疏索引，log写入4kb(可以参数修改)，才会增加一个index，这样能大大减少索引数量，然后用遍历的方式。
 
 里面记录的相对offset，和postion。
 offset position
 10     6410
 25			10000

#.timeindex
 时间索引，当消费指定时间时,用这个索引定位数据位置。 定期删除数据，也是根据.timeindex删除的
 
 
 #文件清理策略
 默认是7天
 log.retention.hours
 
 
```



### 新加节点负载均衡

上线一个新节点,可以对以前的topic和分区副本，进行负载均衡，重新规划



### kafka高效读写

```sql
#并行度高
分区partiton，读写并行度高

#读数据
稀疏索引，定位数据
读数据的时候，优先走页缓存

#写数据
顺序读写，只追加，索引因为是稀疏索引,所以可以顺序写。
直接写入页缓存,读数据的时候，优先走页缓存

#页缓存+零拷贝
kafka不对数据做任何处理,不走应用层，直接进网卡，传给消费者
具体看p40
```





# consumer

### 消费流程

```sql
#消费者个数设置
消费者个数等于分区数，或者是分区数的整除数，这样不会出现数据倾斜


#coordinator
集群会选出一个broker，创建coordinator管理消费者组，分配分区由谁消费，记录offset等
并且coordinator会进行s的心跳连接。超时超过45s，消费者组会再平衡。
或者消费者处理时间过长（5分钟）,虽然有心跳，但是不拉数据(卡在某个地方了)，也会再平衡



#详细流程
在p45懒了，不想记了

```



### 消费积压参数调优

```sql
#增大每次拉取条数
增大条数,同时也要注意最大拉取大小的调整，每条1k 1000条就是1M ,最大的要比这个大。
```



### 分区策略

```sql
#默认
默认的是range + cooperaterSticky

#range策略
如果不是整数倍关系，那么前面的消费者会多分担几个partition，如果消费多个topic,并且分区都不是整数倍，那么consumer1会任务太重
重点是：当某个consumer挂了,range策略会把该consumer控制的所有分区，整体全给另一个consumer，这个是不合理的，会数据倾斜。

#roundRobin
当你消费多个topic时，会把所有topic的所有partition进行轮询，这样不会出现range策略,consumer1任务太重.
当当某个consumer挂了，会将把该consumer控制的所有分区，再轮询给剩下的consumer，不会数据倾斜。

#sticky
感觉和range差不多，再平衡也差不多，具体看文档

#问题是，当consumer挂了，重启之后，还能保证和原来的消费分区一致吗？


```



### offset

```sql
#存在哪
老版本存在zookeeper 
0.9版本之后，存在kafka的 consumer_offset的主题

#自动提交offset
enable.auto.commit 默认是开启的
auto.commit.interval.ms 提交间隔默认是5s提交一次

#手动提交offset
"同步提交"
提交offset成功后，才会继续下一次拉取数据

"异步提交"
发送offset后，就会继续拉取数据，不管是否提交offset成功

#指定offset消费
earliest：最早
latest: 最新
none：如果无偏移量报错

#按照时间消费
具体看代码

```

### 消费者事务

```sql
自动提交offset可能会漏，也可能会重复
手动提交offset，先操作再提交，可能会重复，后提交再操作可能会漏数据

需要实现kafka的offset的事务提交，以及下游支持事务，才能保证精准一次。
#具体代码待补充
```



# 企业调优案例



### producer调优

```mysql
详情看producer
```

### broker调优

```mysql

具体看pdf broker，内容很多
auto.leader.rebalance.enable 自动平衡默认是true，建议关掉，不然平衡时无法消费数据。


#内存设置
内存 = 堆内存 + 页缓存
堆内存建议10-15个g ,如果使用率超过70%就要调大了
页缓存建议 1g  详细具体看p76

#cpu核数选择
假设cpu核数是32
负责读写磁盘线程 占总核数0.5 16个 ，
副本同步leader线程，0.15 4个 ,
数据传输线程 0.3  8个  


#指令查看jvm进程情况
jstat -gc  进程号  2s  20   查看kafka的gc情况。 2s 是每2s打印一次gc  20是 打印20次
jmap -heap 进程号   查看堆内存使用情况
```

### consumer调优

```mysql
具体看pdf
```

















# 完结撒花







```

```

