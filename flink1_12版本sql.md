# 开户断点需求问题

```mysql
#会话窗口必然关闭问题
现在设置一个会话窗口,视频超过18分钟没来数据发短信,身份证验证超过15分钟没数据发短信
其他数据超过30分钟,发短信。
问题是视频和身份验证都正常，到最后一步提交了，整个status = 0的状态都走完事了。
最后进kafka的数据是status =1的数据,窗口必然会关闭一次，输出一个消息。

每次会话窗口关闭时，取最后一条,如果最后一条信息的提交开户申请，那么说明流程走完，那么不需要提醒了。要做where 判断


#kafka线上数据样式拉取
等庄辉老师拉取


#groupby + row_num问题



```



# 目前需解决问题

```mysql
#2
代码测试groupby + lastValue() 是不是每次更新就输出一条? 不更新就不输出。目前代码报错

#待解决1
会话窗口+group by mobie + lastValue()
窗口关闭时会输出什么呢？？？

#3
测试 groupby + row_number的能执行的逻辑，意义用途.
这个是为了,开窗口后取第一条,然后获取价格最高的订单整条信息，
但是因为不group by的字段,无法select出来。所以groupby把你需要的所有字段都弄过来。

但是执行逻辑是怎么回事呢？？？？


#4 窗口内不group by 全输出
目前将窗口的数据全输出，并加一个窗口开始时间的标记
然后用partition by 开窗函数来做筛选，来拿整条

# 滑动窗口的写法有几种？？？

#5 时间窗口,获取窗口内部row_number排序,然后获取整条数据
select 
orderno,
spuid,
price,
create_time
from(
    select 
    orderno,
    spuid,
    price,
    create_time,
    row_number()over( partition by spuid  order by price desc , create_time desc  ) as rk
    from mock_order 
    group by TUMBLE( proctime(), INTERVAL '20' second)
)
where rk = 1

现在的问题就是group by来实现开窗,但是orderno不在groupby字段里,
目前我的需求就是按spuid聚合，然后获取价格最高，时间最近的那条数据



#窗口中的TUMBLE_ROWTIME(time_attr, interval)是什么？
这个TUMBLE_ROWTIME是什么？开窗获取每一行时间吗？？
当我用TUMBLE_PROCTIME( proctime(), INTERVAL '20' second) as w_processtime
 报错：A proctime window cannot provide a rowtime attribute.
```



# 问题已解决

```mysql
#临时视图,where无法过滤到数据
因为`data` map<string, string> ,所以status是String形式,所以要status = '0' 如果是status = 0没有数据
```



# 内网操作

#### 生产kafka拉取

登陆生产的袋鼠云，直接看kafka数据预览，然后复制出来,放到生产的安渡里

打开开发环境的安渡，把开发环境的安渡传到jira







# 语法细节

#### 1.12和1.10区别

```mysql
#袋鼠云勾选
勾选嵌套json平铺
{"b":{"c":3}} 会被拆成{"b_c":c} ，这个需要注意
```

#### 不支持的写法

```mysql
#不支持不开窗直接用TUMBLE_START，想用窗口时间必须有TUMBLE(orderTime, INTERVAL '60' SECOND)
SELECT
orderno,
TUMBLE_START(ptm, INTERVAL '20' SECOND) as window_start
FROM mock_order
```

#### 细节注意

```mysql
SESSION(PROCTIME, INTERVAL '30' second) 都要大写

```

#### 时间相关

```mysql
#处理时间

CREATE TABLE user_actions (
  user_name STRING,
  data STRING,
  user_action_time AS PROCTIME() -- 声明一个额外的列作为处理时间属性
  
) WITH (
  ...
);


#事件时间
CREATE TABLE user_actions (
  user_name STRING,
  data STRING,
  user_action_time TIMESTAMP(3),
  -- 声明 user_action_time 是事件时间属性，并且用 延迟 5 秒的策略来生成 watermark
  WATERMARK FOR user_action_time AS user_action_time - INTERVAL '5' SECOND
) WITH (
  ...
);
```



#### 开窗函数

```mysql
#窗口函数报错
"OVER windows' ordering in stream mode must be defined on a time attribute"

说法1: 原因是窗口order必须指定watermark，而gpt说的，排序必须是时间类型，gpt不对，瞎说的。说法1也是不对的
说法2:开窗函数必须跟着where rk <10这个条件，这个改了之后正确了

官方文档：
WHERE rownum <= N: Flink 需要 rownum <= N 才能识别一个查询是否为 Top-N 查询。 N 代表最大或最小的 N 条记录会被保留。
[AND conditions]: 在 where 语句中，可以随意添加其他的查询条件，但其他条件只允许通过 AND 与 rownum <= N 结合使用

```



#### 会话窗口

```mysql
会话窗口,按处理时间开窗,按mobile_tel，user_id groupby聚合
注意必须用PROCTIME()
group by SESSION(PROCTIME(), INTERVAL '30' MINUTE)  ,mobile_tel  ,user_id
```



#### 窗口聚合

```mysql
#滚动窗口聚合
SELECT user, SUM(amount)
FROM Orders
GROUP BY TUMBLE(rowtime, INTERVAL '1' DAY), user


TUMBLE(time_attr, interval)	定义一个滚动窗口。滚动窗口把行分配到有固定持续时间（ interval ）的不重叠的连续窗口。比如，5 分钟的滚动窗口以 5 分钟为间隔对行进行分组。滚动窗口可以定义在事件时间（批处理、流处理）或处理时间（流处理）上。

HOP(time_attr, interval, interval)	定义一个跳跃的时间窗口（在 Table API 中称为滑动窗口）。滑动窗口有一个固定的持续时间（ 第二个 interval 参数 ）以及一个滑动的间隔（第一个 interval 参数 ）。若滑动间隔小于窗口的持续时间，滑动窗口则会出现重叠；因此，行将会被分配到多个窗口中。比如，一个大小为 15 分组的滑动窗口，其滑动间隔为 5 分钟，将会把每一行数据分配到 3 个 15 分钟的窗口中。滑动窗口可以定义在事件时间（批处理、流处理）或处理时间（流处理）上。

SESSION(time_attr, interval)	定义一个会话时间窗口。会话时间窗口没有一个固定的持续时间，但是它们的边界会根据 interval 所定义的不活跃时间所确定；即一个会话时间窗口在定义的间隔时间内没有时间出现，该窗口会被关闭。例如时间窗口的间隔时间是 30 分钟，当其不活跃的时间达到30分钟后，若观测到新的记录，则会启动一个新的会话时间窗口（否则该行数据会被添加到当前的窗口），且若在 30 分钟内没有观测到新纪录，这个窗口将会被关闭。会话时间窗口可以使用事件时间（批处理、流处理）或处理时间（流处理）。



辅助函数	描述
TUMBLE_START(time_attr, interval)
HOP_START(time_attr, interval, interval)
SESSION_START(time_attr, interval)
返回相对应的滚动、滑动和会话窗口范围内的下界时间戳。

TUMBLE_END(time_attr, interval)
HOP_END(time_attr, interval, interval)
SESSION_END(time_attr, interval)
返回相对应的滚动、滑动和会话窗口范围以外的上界时间戳。

注意： 范围以外的上界时间戳不可以 在随后基于时间的操作中，作为 行时间属性 使用，比如 interval join 以及 分组窗口或分组窗口上的聚合。

TUMBLE_ROWTIME(time_attr, interval)
HOP_ROWTIME(time_attr, interval, interval)
SESSION_ROWTIME(time_attr, interval)
返回相对应的滚动、滑动和会话窗口范围以内的上界时间戳。

返回的是一个可用于后续需要基于时间的操作的时间属性（rowtime attribute），比如interval join 以及 分组窗口或分组窗口上的聚合。

TUMBLE_PROCTIME(time_attr, interval)
HOP_PROCTIME(time_attr, interval, interval)
SESSION_PROCTIME(time_attr, interval)
返回一个可用于后续需要基于时间的操作的 处理时间参数，比如interval join 以及 分组窗口或分组窗口上的聚合.

#案例
// 计算每日的 SUM(amount)（使用事件时间）
Table result1 = tableEnv.sqlQuery(
  "SELECT user, " +
  "  TUMBLE_START(rowtime, INTERVAL '1' DAY) as wStart,  " +
  "  SUM(amount) FROM Orders " +
  "GROUP BY TUMBLE(rowtime, INTERVAL '1' DAY), user");

// 计算每日的 SUM(amount)（使用处理时间）
Table result2 = tableEnv.sqlQuery(
  "SELECT user, SUM(amount) FROM Orders GROUP BY TUMBLE(proctime, INTERVAL '1' DAY), user");

// 使用事件时间计算过去24小时中每小时的 SUM(amount) 
Table result3 = tableEnv.sqlQuery(
  "SELECT product, SUM(amount) FROM Orders GROUP BY HOP(rowtime, INTERVAL '1' HOUR, INTERVAL '1' DAY), product");

// 计算每个以12小时（事件时间）作为不活动时间的会话的 SUM(amount) 
Table result4 = tableEnv.sqlQuery(
  "SELECT user, " +
  "  SESSION_START(rowtime, INTERVAL '12' HOUR) AS sStart, " +
  "  SESSION_ROWTIME(rowtime, INTERVAL '12' HOUR) AS snd, " +
  "  SUM(amount) " +
  "FROM Orders " +
  "GROUP BY SESSION(rowtime, INTERVAL '12' HOUR), user");
```

#### kafkasource和sink

```mysql
当

#kafkasource

"CREATE TABLE kafka_maxwell( \n" +
                "`database` string, " +
                "`table` string, " +
                "`data` map<string, string>, " +
                "`type` string, " +
                "`ts` string  " +
                ")WITH (\n" +
                "  'connector' = 'kafka',\n" +
                "  'properties.bootstrap.servers' = 'localhost:9092',\n" +
                "  'topic' = 'maxwell',\n" +
                "  'properties.group.id' = 'atguigu',\n" +
                "  'scan.startup.mode' = 'latest-offset',\n" +
                "  'format' = 'json'\n" +
                ") \n";
                
当写入sink时，如果指定key.format，那么就要指定key的字段,key.fields="" .upsertkafka中，指定了PRIMARY KEY (spuid)
如果没有key，那么就不谢key.format

#追加sink



#upsert sink
"CREATE TABLE kafka_sink( \n" +
                "`spuid` String , " +
                "`num` bigint ," +
                "PRIMARY KEY (spuid) NOT ENFORCED" +
                ")WITH (\n" +
                "  'connector' = 'upsert-kafka',\n" +
                "  'properties.bootstrap.servers' = 'localhost:9092',\n" +
                "  'topic' = 'kafka_sink',\n" +
                "  'properties.group.id' = 'atguigu',\n" +
                "  'key.format' = 'json',\n" +
                "  'value.format' = 'json'\n" +
                ") \n";
```





# 函数

#### 聚合函数

```mysql

STDDEV_POP([ ALL | DISTINCT ] expression)
STDDEV_SAMP([ ALL | DISTINCT ] expression)

VAR_POP([ ALL | DISTINCT ] expression)

VAR_SAMP([ ALL | DISTINCT ] expression)

COLLECT([ ALL | DISTINCT ] expression)
VARIANCE([ ALL | DISTINCT ] expression)

RANK()
DENSE_RANK()
ROW_NUMBER()
LEAD(expression [, offset] [, default] )
LAG(expression [, offset] [, default])
FIRST_VALUE(expression)
LAST_VALUE(expression) 只能取一个字段，不能整条数据，需要用很多first_value，获取全部的字段，来获取一条数据
```



# 窗口创建和场景

#### 滚动窗口

```mysql
#方式1
SELECT
  window_start,
  window_end,
  COUNT(*),
  ...
FROM TABLE(
  TUMBLE(TABLE my_source, DESCRIPTOR(rowtime), INTERVAL '10' MINUTES)
)
GROUP BY window_start, window_end, ...

#方式2
SELECT
  TUMBLE_START(event_time, INTERVAL '10' MINUTES) as wStart,
  COUNT(*),
  ...
FROM my_source
GROUP BY TUMBLE(event_time, INTERVAL '10' MINUTES)

#方式3

SELECT
  window_start,
  window_end,
  COUNT(*),
  ...
FROM my_source
WINDOW TUMBLE (SIZE INTERVAL '10' MINUTES) AS w
GROUP BY w


```



# 场景

#### 滚动窗口做聚合操作

#### 滚动窗口不做聚合

```

```



#### 多条数据只取一条

```mysql
#方案一？？？？
注意这里开窗后，如何区rk=1，目前没有直接的写法
开窗然后rk =1,并且保证这个rk是不会变的，那么只有一条

#方案二
如果是代码，那么按照需要的数据来groupby，然后内部做一个状态，如果为1则不collect,为0那么collect

#方案3
开窗,然后groupby 然后用first_value(name)，那么一个窗口只有一条数据

```

#### 5分钟输出最近的最高价格？？？

```mysql
SELECT 
*
FROM (
      SELECT 
      *,
      ROW_NUMBER() OVER (PARTITION BY windowStart, windowEnd ORDER BY price DESC) as rownum
      FROM(
            SELECT *,
            TUMBLE_START(orderTime, INTERVAL '60' SECOND) as windowStart,
            TUMBLE_END(orderTime, INTERVAL '60' SECOND) as windowEnd
            FROM Orders
            GROUP BY orderId, price, orderTime, TUMBLE(orderTime, INTERVAL '60' SECOND)
      )a1
)a2
WHERE rownum = 1



#逻辑分析
SELECT *,
TUMBLE_START(orderTime, INTERVAL '60' SECOND) as windowStart,
TUMBLE_END(orderTime, INTERVAL '60' SECOND) as windowEnd
FROM Orders
GROUP BY orderId, price, orderTime, TUMBLE(orderTime, INTERVAL '60' SECOND)
这个可以理解成,每一条数据单独开一个60的窗口,然后获取windowStart，windowEnd

然后60s之后输出，每个数据单独输出
再partiton by windowStart, windowEnd,这样能保证窗口相同的数据汇聚到一块，然后按价格排序。

目前想直接在窗口里做处理,窗口局部排序获取最想要的那条没法直接实现


```





# 断点需求疑问

#### 待解决问题

```mysql
#kafka upsert流
虽然kafka能更新数据，但是如果我有一个流，实时读取数据，那么更新有什么用呢？？
如果不是实时读取数据，而是隔一天读取数据那么没问题。尝试了下，虽然是更新流，但是from beginning读取，还是
{"spuid":"0","num":1}
{"spuid":"0","num":2}
{"spuid":"0","num":3}
并不是只能读取最后一条数据

#kafka临时中间表
需要那么多kafka临时中间表吗？？？
可以不配置源，在内存中做一个catalog表，代码里可以创建temporyview
```



#### 代码疑问

```mysql
#group by然后开窗是什么意思？？
select
name ,
age ,
row_number() over(partition by name ,age order by daytime ) as rk
from tb1
group by name ,age,daytime


##这个写法能写？？？？，能正常运行
select 
spuid,status,rk
from(
select 
spuid,status,
row_number() over( partition by spuid,status order by status) as rk
from mock_order
group by spuid,status
) tmp
where rk < 10;


#这个写法逻辑？？这么写的目的是什么？？？
--这个写法每来一条数据,就会更新输出一条，因为更新了lastvalue(event_id)
并且是个回撤流，有I和+U和-U

通过OPERATION字段来获取，类型就是+I和+U和

select  
mobile,
occur_date,
lastvalue(event_id) as event_id,
lastvalue(event_name) as event_name,
from source_stream_mot_e_event_flow_smot_cc_mid
group by mobile,occur_date


```



#### kafka链接器更新流

```mysql
#场景
insert into kafka_sink
selectspuid,
count(*) as num
from mock_order
group by spuid

当你执行这个sql时，每次来消息，会更新count(*)，每次来消息，都会产生2个消息，回退流和更新流

用kakfa链接器会报错：kafka_sink' doesn't support consuming update changes which is produced by node GroupAggregate

必须用upsert-kafka链接器

虽然有回退流,但是查看数据只有更新数据 
{"spuid":"0","num":1}
{"spuid":"0","num":2}
{"spuid":"0","num":3}


#upsert -kafka的原理
在 Kafka 中实现更新（upsert）和删除操作的概念并不是通过修改已经存在的记录来实现的，因为 Kafka 的数据是不可变的。相反，这是通过发送新的消息来实现的，这些消息具有与旧记录相同的键（key），但有不同的值（value）。这种方式是基于 Kafka 的日志压缩（log compaction）特性来实现的。

Kafka 的 log compaction 特性允许它在保留数据的同时，删除具有相同键的旧记录。这是通过以下方式完成的：

1. **相同键的更新**：当 Kafka 的一个分区启用了日志压缩，如果一个新的消息与之前的消息有相同的键，新的消息会被视为对该键的更新。消费者在读取时会看到最后写入的消息。

2. **删除**：要在 Kafka 中表示一个键的记录被删除，可以发送一个键相同但值为 `null` 的消息。日志压缩会保留这个 "墓碑"（tombstone）记录一段时间，以确保所有的消费者都能观察到这个删除操作。经过一定时间后，这个键及其所有旧的记录将从日志中清除。

当使用 Flink 的 "upsert-kafka" 连接器时，它会根据定义的 PRIMARY KEY 来发送数据到 Kafka。如果数据流中有一个新的记录具有与旧记录相同的键，但是值不同，Flink 会发送这个新的记录到 Kafka。由于 Kafka 的日志压缩特性，这将导致最终只有最新的记录被保留。

如果 Flink 发送了一个值为 `null` 的记录，这将在 Kafka 中表示为一个删除操作。消费者在消费数据时会得到最新的状态，就像在数据库中进行了更新或删除操作一样。

通过上述机制，"upsert-kafka" 连接器允许 Flink 在 Kafka 中模拟更新和删除操作。这对于实现事件源（event sourcing）或者在 Kafka 上构建可查询的状态存储非常有用。然而，这种模式的一个限制是，消费者可能需要处理重复的数据，并且需要能够处理 null 值作为删除操作的指示。



```



# kafka1.11版本

#### topic相关指令

```mysql
#查看topic列表
bin/kafka-topics.sh --list --zookeeper localhost:2181

#创建topic：
bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic tp1

#查看topic的详细信息：
bin/kafka-topics.sh --describe --zookeeper localhost:2181 --topic my_topic

#删除topic
bin/kafka-topics.sh --delete --zookeeper localhost:2181 --topic my_topic

```

