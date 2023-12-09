# 课程记录

p56可以重听

p66-p73跳过了，先听dwd 听到76

# 明日待做

代码逻辑有问题，应该是获取config表的字段，然后流数据过滤掉字段。

并且如何在算子中创建链接



# 问题记录

### 查看流中具体谁调用的map

flink流中,点进去都是借口，我想看到是哪个对象，调用的传入的map方法。
而且这个对象是在哪里创建的？创建的代码在哪里，目前找不到

```java
//想找到map里的print1是谁弄的
SingleOutputStreamOperator<String> map = kafkaDS.map(s -> {
    System.out.println("1");
}
                                                     
//找到上一行是 processElement()方法调用了map                                            
public class StreamMap<IN, OUT> extends class AbstractUdfStreamOperator {
    @Override
    public void processElement(StreamRecord<IN> element) throws Exception {
      //想知道这个output是什么
        output.collect(element.replace(userFunction.map(element.getValue())));
    }
}
                                                     
//现在想知道这个output是，找到的是抽象类的一个属性。因为上面StreamMap继承了下面的类，所以能直接用output
public abstract class AbstractStreamOperator<OUT>{
protected transient Output<StreamRecord<OUT>> output;
}
///现在想知道的就是这个 StreamMap类的对象在哪里？？谁创建的 ？？怎么找呢                                              
                                                                                                    
```

### 实时数仓有些为什么不用后端做

一些业务场景,在下面数仓库出现背景中，有一些我觉得用后端做会很简单，为什么大数据做



### 杂碎问题待解决

a  在flink中用到代码中的集合,那么这个集合的是每个并行度分开自有的吗

1 就是通过mysql采集的数据，经处理之后，但是突然订单的完成状态修改了，从下单，到付款了，但是下单状态已经处理过了，这种修改操做后续怎么处理。

2 调度框架，编写脚本时，怎么获取每个job任务执行的返回值，判断job是否正确完成了呢？

3 maxwell通过kafka传到ods层，那么对于变更的数据怎么，同步到hdfs上呢？增加的好弄，变更的怎么弄

原来的是通过sql批量处理，覆盖重写。

4 开发一个mysql ddl转hive ddl的脚本

5  kafka是如何实现2个流的交互的，我自己写不出来,都是while true来拉取，没法交互，只能用多线程来实现了，可以尝试下

6 做一个功能，根据mysql表名，查到的查询集，自动封装成对应dao类的集合，现在不知道怎么实现

7  flink中关于集合的运用，在外面创建的集合和内部集合的分布式问题，是否是每个并行度单独有自己的集合

8 理解一下flink中哪些代码会多次执行，为什么连接池技术可以被多个并行度获取，是每个并行度自己建立链接池吗

# 问题已解决

### kafka反序列化类找不到

之前没问题的代码，执行时突然报错找不到反序列化器

NoClassDefFoundError: org/apache/flink/api/common/serialization/DeserializationSchema

因为pom文件中的依赖是 provided，执行时不带入







### jdbc没有时分秒

mock数据的时候,mysql只有日期没有时分秒，mysql中的时间类型，Date,DateTime,TimeStamp。不过这里的timestamp并不是时间戳，也是日期格式。jdbc里应该用setTimstamp插入数据，我用的是setDate. Date只有年月日

### 执行找不到类

运行代码找不到类,不过自己手动能找到这个类，因为pom配置的是provided，运行时不会把依赖带进去

两种解决方式：1 把provided去掉

2 点进run=》点击edit configrations=>edit template=>applictions=>modify options=>add denpendency with provided

这个模版配置一次，以后就不用配置了.windows上的操作是run=>edit configrations=>application选中类名=> configuration=>勾选provided

### 侧输出流:POJO报错

POJO type expected but was: String

String 不满足POJO类型

```
/*Flink对POJO类型的要求如下：
        l 类是公有（public）的
        l 有一个无参的构造方法
        l 所有属性都是公有（public）的
        l 所有属性的类型都是可以序列化的
```

源码报错问题所在

```java
OutputTag wrongStream = new OutputTag("s1stream", Types.POJO(String.class));

//这是Types.POJO方法的代码，源码在这里
public static <T> TypeInformation<T> POJO(Class<T> pojoClass) {
    final TypeInformation<T> ti = TypeExtractor.createTypeInfo(pojoClass);
    if (ti instanceof PojoTypeInfo) {
        return ti;
    }
    throw new InvalidTypesException("POJO type expected but was: " + ti);
}
```



### 连接不能序列化

数据库连接不能序列化是因为连接对象包含了底层的网络连接和状态信息，这些信息无法被序列化

在process中不想每次都新建一个连接，所以提出来了，然后报错链接不能序列化。

在addsink算子中，创建的hbaseconnect不会报错，但是在process算子中就报错

```java
SingleOutputStreamOperator<JSONObject> needDimDs = connect.process(new CoProcessFunction() {
    HashSet<String> configSet = new HashSet<>();
    HbaseConnect hbaseConnect;
}
```

gpt给的答案是ds.mapPartition里面创建数据库连接，这个是对一个分区的数据整体处理，这个应该是批计算。

流计算gpt给的答案是用数据库连接池技术管理，用的时候拿一个，用完归还。但是hbase没有连接池

个人理解: 

  				数据库连接池的创建，应该是每个并行度会自己加载一次连接池在java虚拟机中,所以连接虽然不能序列化

​				  但是连接池获取的链接在各个并行度中是可以重复使用的。

​				  写在算子外面的代码获取链接因为无法序列化所以不能传递到算子里面



### habase建表已存在

因为建表语句写在广播变量里面，导致建表执行了4次，报错表已存在，应该是多线程问题导致的，代码在A1_GetData里



# 集群规配置

组件版本

hadoop  3.1.3

zk	3.5.7

kafka 3.0.0

spark 3.0.0

flink	1.13.0

hbase 2.0.5

mysql  5.7.116

hive  3.1.2

flume 1.9

redis  6.0.8

datax 3.0.0

dolphin 2.0.3

maxwell 1.29.2







8个服务器

组件hadoop	 kafka	 zookeeper	 hbase		mysql  hive  	spark	 flink	flume	datax	maxwell  dolphinScheduler

hdsf  2个nn 放1，2服务器 ,datanaode是3-8服务器

yarn 2个rm放1，2服务器  ,nodemanager放3-8

kafka	3个放 3-5  

zookerper 	3个放 6-8

hbase 	3个放6-8



mysql放1

flume放1

hive放1 和mysql放一起，方便读取元数据



# 实时数仓出现背景

一些业务对实时性数据要求比较高,而离线数据仓库满足不了

**出现背景**

```sql
#实时广告投放：
广告平台需要实时计算来分析用户行为数据并实时调整广告投放策略；
#IoT应用：
物联网应用需要实时计算来处理传感器数据并触发相应的操作；
#电商大促：
电商平台需要实时计算券的核销数据并实时调整券的投放策略；
#彩贝壳直播房型临时加量
直播会便宜，总有一些买不到的，当快没了，会额外放出一些库存房型。
#资金风控：
线上活动场景中，黄牛党/羊毛党的识别需要秒级反馈，因为每秒都意味着几万/几十万的资金损失；

有个问题就是，这些为什么不是后端来做呢？
后端做不了吗？通过调用后台优惠券发送数量，或者在发券的时候，弄个状态记录？
```





# 实时数仓和离线数仓区别

1  离线数仓的mysql数据是每天凌晨通过sqoop用sql来过滤的。实时的是通过maxwell => kafka => hdfs => hive load

​     因为实时数仓，maxwell会把每个数据的变动也传递到hdfs上，也就是能把每条数据的历史状态也能获取到，这个不错。





# 实时数仓链路

flume 采集用户行为日志到hdfs

datax 将mysql数据采集到hdfs

maxwell 加载实时更新数据

dophin调度器



### flume

### maxwell(有待解决问题)

问题:maxwell通过kafka传到ods层，那么对于变更的数据怎么，同步到hdfs上呢？增加的好弄，变更的怎么弄

原来的是通过sql批量处理，覆盖重写。 可不可以像hbase那样，标记取最新的一条，弄个字段做标记。

弄个标记字段是否更改过，where 标记字段 is  否  union  where 标记字段 为是 and 时间为最新的一条



监控binlog日志实时监控mysql变更操作，然后把变更数据以json格式发给kakfa。

我们把实时数据和业务数据都放在kafka，业务数据通过flume的kafkachannel，上传到hdfs的ods层

##### 数据样式

更新数据样式 update

```
{"database":"flink_warehouse_db","xid":5189,

"data":{"create_time":"2023-10-20 16:16:41","modify_time":"2023-10-20 16:16:41","name":"李苹J29428888","id":1000},

"old":{"name":"李苹果J2942"},
"commit":true,
"type":"update",
"table":"userinfo",
"ts":1698397760}

```

新增数据样式 insert

```
{
    "database":"flink_warehouse_db",
    "table":"userinfo",
    "type":"insert",
    "ts":1698414338,
    "xid":58899,
    "commit":true,
    "data":{
        "id":10284,
        "name":"钱华为E7657",
        "create_time":"2023-10-27 14:45:38",
        "modify_time":"2023-10-27 14:45:38"
    }
}
```



### hive

离线数据从kafka写到hdfs上之后,需要用hive去load到我们的ods表中，让hive管理。 





# 实时数仓分层

计算框架:flink，存储框架:储存的数据放消息队列



#### ods(有问题待解决)

使用场景：新增一条数据,读取并加工处理，再让别人读取，用kafka存

问题?????感觉变更的表数据，用kafka存会出现重复数据

#### dim

使用场景：

新增过来一条存储，并且要保存所有数据，保持维表数据全都有，并且永久存储,

事实表会根据主建从dim的表中获取对应数据，用hbase存。



从已有框架中选择

kafka：没有主见查找功能,并且只能存7天

hbase: 可以存,可以设置行列存，行存和列存都行，所以可以用hbase存可以

redis:用户表数据量大,用内存存不合适

clickhouse: 并发不行,并且是列存，不适合拿一整条数据

es：默认给所有字段创建索引，没必要

mysql：不合适，因为每条数据就访问一个mysql，对业务mysql压力大。



#### dwd

场景:来一条新数据，读取处理，加工，储存让别人拉取

kafka存



#### dws(问题)

场景:从dwd拉取数据做聚合，每有一条数据就聚合一次，没法存kafka，不然重复数据了。

需求是要读一条，然后累加，存起来覆盖之前那一条。



用clickHouse存，因为从dws到ads肯定会做聚合。

比如dws层有用户，省份，商品维度的gmv 3个表。那么ads层统计总的至少3个flink任务

好像用clickhouse可以一个sql就能得出3个ads指标



#### ads (问题)

不落盘,如果存mysql，每秒更新一次没必要存。实质是一个接口,通过clickHouse的sql去统计dws的数据，形成ads

有个问题，有的ads层指标sql执行的慢的话，不会存在问题吗？

# 分层具体操作实现

## dim(？？？)

#### 代码细节

1  生产模式下，chekpoint必须打开就是老师注释的代码

2 flinkkafka的API创建时，反序列化的simpleString不好用，当来的消息是个null的时候，会报错，需要自己实现个flinkkafka序列化接口自己写,比如把null转为""空数据，不然会报错

#### 流程

kafka数据  => 校验json格式 =》 错误的写入侧输出流保存=>正确的写入hbase

#### 优化

kafka从topic_db(包含所有业务表数据),过滤出想要的数据。第一次获取全部的业务数据，通过maxwell将所有数据采集

这里有个问题，以后要是要增加维度表过滤的话，需要修改代码，再上传，所以需要哪些表，最好是动态获取的。



优化1:不修改代码,只重启任务

把需要的表写在配置文件里，关闭任务，然后修改配置文件，重新读取配置文件



优化2:不修改代码，不重启任务

(我的想法)从mysql中读数据，然后放在集合里，每过一段时间从mysql读数据，更新集合

(老师的思路)专门有个特殊的表记录哪些表是dim需要过滤出来的，监控binlog有数据变化那么就更新(如何在一个代码里执行2个kafka消费，是个待解决的问题）



优化实现

用flink的conncet流，然后keyby后用process函数实现

流1是所有的maxwell数据，流2是配置流数据，都是kafka流

这里有个问题就是，masxwell流，多节点执行没问题。配置流如果kafka多节点消费的话，每个节点只有部分信息，所以groupid必须是通过节点号生成

#### 流程问题待问题

1 流1是所有的maxwell数据，流2是配置流数据，都是kafka流

这里有个问题就是，masxwell流，多节点执行没问题。配置流如果kafka多并行度消费的话，每个节点只有部分信息

 (我的思路) 配置流多并行度消费，每个消费者生成不同的groupid。

(第二个思路)配置kakfa数据进入分区策略，保证maxwell流和配置流相同表的数据,进入同一个kafka消费者

(老师的思路) 广播流 配置表的流是个广播流(缺点配置表数据冗余)。可以flink流 keyby(缺点可能数据倾斜)

如果配置表是用户信息这种，就不能用广播流(内存消耗太大)



2  maxwell过滤维度表数据时，新增，变化要，删除要不要? 删除可以不要，就算导致mysql和hbase已有的数据不一致，但是不影响分析，因为mysql删除的数据，实时表不会出现相关联的数据

9 如果任务挂了,重启成功了,要想配置流中有完整数据，kafka消费策略，一定要设置从最早数据读取



问题：???

这里有个问题，所有的都放一个topic，效率不低吗？每次都要过滤自己想要的数据，不能多个topic吗？

还是说kafka topic太多不好？

也就是说maxwell会把所有的改动都传入到kafka中，不能分表吗？

#### 代码问题待处理



###### hbase建表报错

​	虽然建表的时候代码有判断表是否存在，但是在广播变量后还是出现表已存在的报错，估计是线程问题，4个线程同时建表，看看视频代码怎么写的

#### 已解决代码问题

###### 库连接重复使用

​		用addsink 重写Rich函数的open方法可以在open里初始化数据库连接，这种在invoke中可以使用连接

​		遇到的问题时,connect流中，一个流是向Hbase写数据，这里的连接怎么重复利用,在connect中，

​		写在外面的代码块来执行初始化连接，之前代码出现过问题



## dwd

#### 流程

日志数据：

​		1   消费ods主题=》拆表写入不同kafka主题=〉多kafka主题关联。

​			 因为行为数据太多了，拆表合适，不过多个写入动作效率低

​		2





业务数据：

​		0  消费ods主题=》过滤需要的数据=〉多表关联

​			业务数据相对较少1秒就几条，所以不查表，这样效率高

​		1   把业务数据过滤出来，然后不同表分成多个流，用侧输出流

​		2  事实数据，维度退化，多表关联，把需要数据放到一张表里





#### 需解决问题

#### 优化

 1  业务数据消费一次主题，通过侧输出流来分多个表( 原本的想法是用一次消费一次topic)

#### 代码细节

#### 待做







## dws



## ads







