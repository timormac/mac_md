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



# 问题已解决

#### pom导入依赖报错

Could not find artifact org.pentaho:pentaho-aggdesigner-algorithm:jar:5.1.5-jhyde

自己maven配置文件的阿里云镜像源找不到这个依赖

windows当初能下载是用了默认的maven的conf.xml，没有用更改的阿里云的源

在mac上更改配置文件为maven自带的就行，仓库还用自己的仓库存jar包



# spark比对MR优势



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



# sparkOOM的解决方案

第四条，持久化存储？？

```
优化查询操作：对于复杂的查询操作，可以尝试优化查询计划，减少中间结果的生成和存储。使用合适的索引、分区和压缩等技术也可以减少数据量和内存消耗。

调整配置参数：合理设置Spark集群的相关配置参数，包括内存分配、任务并发度和调度策略等，以适应实际的数据处理需求。

使用持久化存储：对于需要多次使用的中间结果，可以使用持久化存储（如缓存或持久化表）将结果存储在内存或磁盘上，以避免重复计算和减少内存消耗。

使用内存管理技术：Spark提供了一些内存管理技术，如内存序列化和堆外内存，可以帮助减少内存开销并提高性能。
```



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