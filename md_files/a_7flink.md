# 课程进度

到p108容错机制 p108跳过了

109到114的检查点算法听的不太懂，后续有机会自己消化一下

p137 flinksql开始 

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



### 报错:kafka.consumer.OffsetResetStrategy

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







# Flink优化

#### 反压机制

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





### SQL

Flink1.12版本基本做到了完善，即使在1.17当前版本中TableAPI 和SQL依旧不算稳定

### 官网文档

在applicationg develop(应用开发)里面

### savepoint

flink客户端，关闭任务时，执行save point,要事先设置save point制定路径，不然会报错。

如果临时执行reset save point ,后面要重置为空，不然后面所有的作业，都以这个save point路径保存

### catalog

flink能对接hive表,不过flink不是个流吗？难道能监控hive表中数据变化吗？



### 优化

滑动窗口的时候步长和时间要是整数，这样TVF的API会优化，把滑动窗口，切分成多个滚动窗口，这样不会有太多重复数据



# CDC

flink cdc









