# 问题记录

#### 背压机制内存溢出

帖子说如果reciver上游数据比消费速度要快，消息积压,会造成内存溢出

问题是kafka是消费者pull模式，为什么还会出现消息积压？不应该是由spark自己控制消费速率吗？没做优化？

#### mr会出现内存oom吗？

按照spark对比mr，mr会落盘。也就是spark比mr更容易oom.

mr程序如果每个map任务是读取128m的块文件，那么基本1G的container不会报错。

可能在连续的map任务，jvm重用之后可能会oom

一个表有20个128的块。集群有3个，那么20个map任务，只能3个节点一个个执行，因为服务器设置的是4G 内存，最多开3个。

也就是最多同时9个map，其他的要等 



gpt解释的mr出现 oom的原因

```
数据量过大：如果Hive查询操作的数据量非常大，超过了集群可用的内存资源，就容易导致OOM。这可能发生在处理大型数据集或执行复杂的聚合操作时。

过多的中间数据：Hive查询通常会生成中间数据，例如在MapReduce的Shuffle阶段产生的数据。如果中间数据量很大，内存不足以容纳所有的中间数据，就会导致OOM。

错误的配置参数：Hadoop集群的配置参数对内存的分配和管理非常重要。如果配置参数设置不合理，例如将可用内存分配给其他任务或过度分配给Hive任务，就可能导致OOM。

复杂的查询操作：某些复杂的查询操作可能会导致计算过程中产生大量的中间结果，占用大量的内存空间。如果这些中间结果不能及时释放或溢写到磁盘，就会导致OOM。
```



#### groupby算子放_不通过

```scala
//这里放_会提示错误
val groupBy:RDD[(String,Iterable[String] )] = flatmap.groupBy(s=>s)
```

#### 内存数据io必须落盘吗

个人觉得内存数据想通过网络io发送，必须落盘，因为网络io接口应该只支持文件格式。除非spark自己手写从内存传数据

#### rdd的collesc源码是否落盘

查看下源码，看看缩减之后的分区，是不是直接调内存，没有落盘



#### Stream流的checkpoint

什么时候执行ck，并且中间状态kafka等状态，会存哪些



#### stream中log4j2文件不生效

可能是因为spark用的不是log4j2作为日志文件系统



#### 每个rdd都创建一次连接

stream流中，每5秒，就会创建一个mysql连接，这个效率太低了，有没有更好的？

上面用的是mappartition。

```
在Spark Streaming中，同一个executor的不同批次确实是在同一个JVM进程中顺序执行的，但每个批次是作为独立的Spark作业提交的。这意味着每个批次开始时，Spark会创建新的RDD、DAG和任务，然后这些任务被分发到各个executor上执行。在每个批次结束后，与该批次相关的资源通常会被释放，包括广播变量和累加器等。因此，Spark的设计并不是为了在批次之间保持长期运行的状态，如打开的数据库连接。

然而，你可以通过一些策略来实现类似“共享连接”的效果：

1. **静态连接对象**：在executor的JVM中，你可以尝试使用静态对象来存储数据库连接。这样，即使是不同批次的任务，也可以检查该静态对象是否已经存在一个打开的连接，并在需要时重用该连接。这种方法要求你非常小心地管理连接的生命周期，确保不会出现连接泄漏，并且要确保连接对象是线程安全的。

   object MySqlConnectionPool {
     private var connection: Connection = _

     def getConnection(): Connection = {
       if (connection == null || connection.isClosed) {
         connection = createNewConnection()
       }
       connection
     }
   }

   在这个例子中，`getConnection` 方法会检查现有的连接对象是否存在且未关闭，如果是这样，它就返回现有的连接。否则，它将创建一个新的连接。

2. **连接池**：使用连接池是另一种方法。连接池可以管理多个连接，并在内部处理连接的创建和复用。在executor中，每个批次的任务可以从连接池中获取连接，用完后归还连接。连接池会确保连接的有效性，并在需要时创建新连接或关闭空闲连接。

3. **广播变量**：虽然不能直接通过广播变量共享数据库连接，但可以通过广播变量共享数据库连接的配置信息，然后在每个executor上按需创建连接。

总之，虽然Spark不是为了在不同批次之间直接共享状态而设计的，但你可以通过上述方法来实现类似的效果。重要的是要确保连接管理逻辑是健壮的，避免因为连接共享而引起的并发问题、连接泄漏或其他资源管理问题。
```





# 问题已解决(待回顾)

#### pom导入依赖报错

Could not find artifact org.pentaho:pentaho-aggdesigner-algorithm:jar:5.1.5-jhyde

自己maven配置文件的阿里云镜像源找不到这个依赖

windows当初能下载是用了默认的maven的conf.xml，没有用更改的阿里云的源

在mac上更改配置文件为maven自带的就行，仓库还用自己的仓库存jar包



#### cache的落盘和checkpoint

cache等级有全部落盘等级，那和checkpoint有什么区别呢？

checkpoint和cache区别：
ck可以设置hdfs路径是高可用。cache当设置存在磁盘时也是本地，不是高可用
ck切段血缘关系,cache不会切断



# 问题已记住( 备份)

```mysql



```



# 概览

### spark历史版本特性

Spark是一个开源的分布式计算框架，用于高性能的大规模数据处理和分析。下面是Spark的一些重要版本及其主要特性的概述：

1. Spark 1.x系列：这是Spark的初始版本，引入了Resilient Distributed Datasets（RDD）的概念，提供了基本的分布式数据处理功能。其中一些重要特性包括：
   - Spark Core：提供了RDD的API和基本的分布式计算功能。
   - Spark SQL：支持结构化数据处理和SQL查询。
   - Spark Streaming：支持实时数据流处理。
   - MLlib：提供了机器学习算法库。

2. Spark 2.x系列：这是Spark的重要升级版本，引入了一些关键的改进和新特性。其中一些重要的特性包括：
   - DataFrame和Dataset API：引入了基于DataFrame和Dataset的结构化数据处理API，提供了更高级别的抽象和优化。
   - 改进的SQL引擎：提供了更好的SQL查询性能和优化。
   - 结构化流处理：引入了结构化流处理（Structured Streaming），使得流处理和批处理可以统一编程模型。
   - 分布式机器学习：增加了分布式机器学习库，如MLlib的改进版本和新的机器学习算法。

3. Spark 3.x系列：这是Spark的最新版本，带来了一些重要的改进和新特性。其中一些重要的特性包括：
   - 分布式Pandas API：引入了Pandas UDF（User-Defined Function），可以在Spark中使用Pandas库进行数据处理和分析。
   - 改进的SQL引擎：进一步提升了SQL查询性能和优化。
   - 改进的结构化流处理：增加了更多的功能和优化，如事件时间处理、状态管理等。
   - 改进的机器学习库：提供了更多的机器学习算法和功能，如图神经网络、模型解释等。

这些是Spark版本中的一些重要特性，升级到较新的版本可能会带来更好的性能、功能和开发体验。然而，升级也可能需要进行一些工作，如代码迁移、配置更改、应用程序兼容性测试等。因此，在决定是否升级之前，建议您进行充分的评估和测试，以确保升级对您的业务有实际的益处。同时，还应该考虑与其他系统和工具的兼容性，以确保整个技术栈的稳定性和一致性。

### spark比对MR优势

迭代计算是指通过多次迭代运算来逐步逼近问题的解决方法。在迭代计算中，每一次迭代都会根据上一次迭代的结果进行计算，并将计算结果作为下一次迭代的输入，直到满足某个终止条件或达到预定的迭代次数。

spark更适合迭代计算,案例

```sql
#当只调用map,filter等算子，拿无论迭代多少次，和Mr没有区别。在mr里也是通过map进行的，至少不涉及分区shuffle就不会reduce
spark:data.map.filter

#shuffle分区器的算子优化
可以针对性分区

#数据集多次使用
当涉及到一个处理后的数据集多次使用，这时候就比mr高效。因为这个数据集是在内存里，
而mr要落盘，然后再通过落盘的数据，再执行多个任务

#spark内存数据直接io传递出去，可以不落盘。而mr的设计模式就是缓冲区满了就溢写
Spark可以在计算过程中将数据保留在内存中，并通过网络IO将数据传输到需要使用该数据的任务或节点上，通过避免磁盘IO，，Spark可以更快地访问数据，从而加速数据处理过程。

```



Spark框架相对于MapReduce框架在以下几个场景下可能更加高效：

1. 迭代计算：Spark提供了内存计算和数据共享的功能，可以在迭代计算任务中显著提高性能。相比之下，MapReduce需要将中间结果写入磁盘，导致IO开销较大。
2. 内存计算：Spark将数据存储在内存中，通过弹性分布式数据集（RDD）提供高效的数据操作。这使得Spark在需要频繁访问数据的场景下比MapReduce更加高效，因为MapReduce会频繁地读写磁盘



即使用hive on spark也比mr快一些

```sql
#spark任务启动快，spark是通过fork线程，mr时通过创建新进程

#算子优化  对于一些join会采用取样，来判断是按hash分区还是什么分区

#如果用sql来说的话，子查询的话，spark用内存，而mr是用多个mr
但是hive有自己有优化，会把子查询在过滤时，会合并。谓词下推的操作，所以这个体现不出来

#spark缓存比hive好

#hive中如果想减少reduce文件数为1,最后只有1个reduce程序。spark中可以先多并行度reduce，然后最后collese算子减少为1个分区
#不过这里有个问题，如何在hive上执行这种操作的？还是说我们必须手写sparksql呢
```

### spark比mr快的原因案例

```sql
#IO次数减少
mr，每次进行shuffle都要先io落盘，才会进行shuffle传输，而spark只有在必要时才会落盘。
并且对于处理过的数据集可以重复使用，mr的逻辑不行，要重新处理

#DAG优化
spark会将一些任务进行优化，串行一些操作。
但是有hive的优化器，mr这方面不会差太多，也会进行串行

#连续group
第一次group by后,再接一个group by 。如果是mr引擎，第一次的reduce必须落盘，然后第二个map再读取。是2个stage
但是spark中,mr之后，可以直接shuffle到下一个reduce，不用再一个map。是一个stage连续接2个reduce

```





### spark和flink设计理念区别

```sql
Apache Spark Streaming的微批处理模型（micro-batching）和Apache Flink的事件驱动模型（event-driven or stream processing）各自体现了不同的设计理念和技术选择。在Spark Streaming最初的设计中，选择了微批处理模型，主要是由于以下几个原因：

1. **基于Spark的核心设计**：Spark Streaming在设计之初，是作为Apache Spark的一个扩展，利用了Spark的核心概念——弹性分布式数据集（RDD）。RDD是一种不可变的分布式数据集合，Spark的所有计算都是围绕RDD进行的。Spark Streaming通过创建一系列短时间间隔的RDD，来模拟流处理。这样做的好处是可以复用Spark的调度、容错和内存管理机制，而不需要从头开始构建一个全新的系统。

2. **容错性**：微批处理模型可以借助Spark的RDD来提供天然的容错机制。如果在处理过程中出现了节点故障，可以利用RDD的 lineage（血统信息）来重新计算丢失的数据分区，而不是重新处理整个数据流。

3. **易于理解和实现**：微批处理模型相对于真正的流处理模型来说，在概念上更容易理解和实现。开发者可以使用与批处理相同的API来处理流数据，这降低了学习成本，并且可以让开发者更快地开发和部署流处理应用。

4. **成熟度和稳定性**：当Spark Streaming被开发的时候，Apache Spark已经是一个相对成熟和稳定的大数据处理框架。通过在这个已经稳定的基础上增加流处理能力，可以快速提供一个可靠的流处理解决方案。

5. **性能考虑**：尽管微批处理在理论上可能不如事件驱动模型的实时性，但是通过减小批处理的时间间隔，可以在实践中达到近乎实时的处理效果。同时，批处理模型可以更好地利用资源，因为它可以在每个批次中处理大量数据，减少了调度开销。

相比之下，Flink从一开始就被设计为一个纯粹的流处理引擎，它支持事件驱动的真实流处理，以及对事件时间和处理时间的深入支持。Flink的设计允许它更好地处理事件顺序和时间窗口，这在某些流处理场景中是非常关键的。

随着时间的推移，Spark也引入了结构化流处理（Structured Streaming），这是对Spark Streaming的一个重大改进，它提供了更好的事件驱动处理模型和对事件时间的支持，从而在一定程度上弥补了Spark Streaming与Flink之间的差距。
```



### sparkOOM的解决方案

第四条，持久化存储？？

```
优化查询操作：对于复杂的查询操作，可以尝试优化查询计划，减少中间结果的生成和存储。使用合适的索引、分区和压缩等技术也可以减少数据量和内存消耗。

调整配置参数：合理设置Spark集群的相关配置参数，包括内存分配、任务并发度和调度策略等，以适应实际的数据处理需求。

使用持久化存储：对于需要多次使用的中间结果，可以使用持久化存储（如缓存或持久化表）将结果存储在内存或磁盘上，以避免重复计算和减少内存消耗。

使用内存管理技术：Spark提供了一些内存管理技术，如内存序列化和堆外内存，可以帮助减少内存开销并提高性能。
```



### spark语句优化器

预聚合，自动识别shuffle分区器等

# scala源码解读

#### scala额外知识

```scala
//type关键字 类型别名
type MyString = Java.Basic.String 
//元组类型别名
type MyTuple = (String,Int,Int)
//函数类型别名
type Myfunc[T] = T => Boolean  

//用法:这样就能简化写法
def f1( func:Myfunc[T] ) ={}

```



#### rdd的flatmap

```scala
//Return a new RDD by first applying a function to all elements of this RDD, and then flattening the results.
//传入的函数返回值是 TraversableOnce类型，会对这个类型进行扁平化处理
  def flatMap[U: ClassTag](f: T => TraversableOnce[U]): RDD[U] = withScope {
    val cleanF = sc.clean(f)
    new MapPartitionsRDD[U, T](this, (_, _, iter) => iter.flatMap(cleanF))
  }
//TraversableOnce的源码 是Scala这个类中声明的
type TraversableOnce[+A] = scala.collection.TraversableOnce[A]

/**
在这个例子中，TraversableOnce[+A]通过定义类型别名，我们可以使用更简短的名称TraversableOnce来引用这个类型，而不需要每次都写出完整的scala.collection.TraversableOnce
**/
```





# spark任务提交

#### 执行脚本

```shell
bin/spark-submit \
--class org.apache.spark.examples.SparkPi \
--master local[*] \
./examples/jars/spark-examples_2.12-3.0.0.jar \
```

#### 可配置参数

```java
//执行模式
--master local[*]     //可选  yarn  local[*]  注意yarn模式分client是本地dirver测试用和cluser是集群模式
  
--
--executor-memory 1G
--total-executor-cores 2
--executor-cores
--application-jar
--application-arguments
```

# spark运行架构



### excutor内存模型

```sql

#excutor总内存
excutor运行在container里面，每个container对应一个excutor
excutor内存  =  overhead + excution&storage  2部分  
spark.executor.mermoryOverhead 堆外内存 ,jvm的额外开销，操作系统开销。默认比例excutor总内存的o.1
spark.executor.mermory 堆内存，计算和存储的内存  占总的0.9

每个excutor总内存设置为:yarn内占用的总内存/yarn能最大提供的container数。
参数表里没有总内存这项，所以分别设置spark.executor.mermoryOverhead和spark.executor.mermory

#每个应用excutor个数配置

"静态分配"
每个spark应用提交时，手动指定通过spark.excutor.instances 执行excutor数



动态分配





```











# sparkCore

#### RDD

spark的有向无环图，对于hive来说也有微词下推能代替

Rdd只记录运算逻辑，所以我们可以手动实现一个操作类，对rdd进行封装,然后再返回一个rdd。

但是这个类是要实现序列化的，所以说RDD只是记录逻辑。

#### 宽窄依赖

宽依赖会shuffle，肯定重分区了。

窄依赖可能会分区，但是不触发shuffle，比如缩减分区，可能会涉及到文件落盘传输,或者内存直接传输。

个人觉得内存数据想通过网络io发送，必须落盘，因为网络io接口应该只支持文件格式。除非spark自己手写从内存传数据

个人理解宽窄依赖是为了后面生成执行计划stage的，不同算子继承了宽窄依赖。然后根据是否有宽依赖确定时候分stage

#### cache/persist

```mysql
#cache功能
当某一个rdd你多次调用action算子时,比如同一个rdd你执行2次collect
那么这个rdd如果是通过map生成的，那么会重新执行2次map，因为缓存cache是不会自动调用的
当你执行rdd.cache()，那么当多次调用rdd，会从缓存拿，而不会多次重新计算map

#persist设置缓存级别 
map.persist(StorageLevel.MEMORY_AND_DISK_2)
具体看work文档
```



#### checkpoint

就是将rdd的中间结果写入磁盘，避免血缘依赖过长，当出问题时，全部重新算。

具体看代码，主要要加cache，不然就和多次调用行动算子一样，重跑一次rdd生成逻辑。



checkpoint和cache区别：

​			 ck可以设置hdfs路径是高可用。cache当设置存在磁盘时也是本地，不是高可用

​			ck切段血缘关系,cache不会切断





# sparksql

shark分析引擎是基于hive，针对spark架构做了修改，能运行在spark引擎上。

后面觉得对hive依赖太多了，依赖hive的语法解析器，有瓶颈。就专门弄了sparksql。

但是hive on spark好像也优化了，他俩现在应该一样的



#### dataframe

#### dataset

#### 查询优化器

也有优化，比如先join再filter时，执行计划会被先filter 再join





# sparkStreaming

不学spark structured Streaming

#### 待解决

spark中的group by key等是对当前批次的进行key by ，那么我想今天数据group by key怎么办?

#### 手动实现侧输出流

#### 