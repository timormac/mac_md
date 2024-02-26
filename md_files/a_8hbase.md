# 问题待解决

### 对接hive

```mysql
hbase中用订单号做个rowkey，按日期扫描，就算我在hbase中设计了2级索引，那么hive解析sql时会怎么用这个二级索引呢？
hive会自动用吗？想用二级索引,需要怎么设置呢？
```

### 预分区

hbase每个区的字符集从什么开始的？如何设计rowkey的加盐规则，预分区避免什么了



#### 高效读写和二级索引

```mysql
hbase是按字典进行索引的，因此想写入快,最好连续写入的数据都是rowkey连续的，比入前缀都相同.
想读取快，比如我想读某一天的全部订单，如果这些订单都是顺序写的，读取会很快。
那么我怎么才能保证顺序写呢？通过二级索引,是先去查rowkey，再通过rowkey去主表查具体字段吗？如果这样主表的数据不是顺序连续的，那么读写就不快了，怎么解决呢。
```



1  hbase如何设置字段类型

2  如何一次插入同一个rowkey的多条数据

3  二级索引怎么实现的

4 如何范围查询？？



# Phoenix

### 简介

看文章：https://www.jianshu.com/p/e1ea1359dfb6

phoenix是一个集成hbase的项目，很有用Apache Phoenix与Spark、Hive、Pig、Flume、Map Reduce等Hadoop产品完全集成。

在我们的应用和 HBase 之间添加了 Phoenix，并不会降低性能，而且我们也少写了很多代码。

 phoenix 特点

- 将 SQL 查询编译为 HBase 扫描
- 完美支持 HBase 二级索引创建
- 支持完整的ACID事务、UDF、分页查询
- 确定扫描 Rowkey 的最佳开始和结束位置、扫描并行执行
- 将 where 子句推送到服务器端的过滤器



### 客户端指令

```sql
#启动phonix客户端
./bin/sqlline.py project1,project2:2181


#指令
!table  查看所有表  注意:没有分号;
drop table student;

#建表语句,想要表小写用"" 指定命名空间dev.放引号外面
#不过建议别用，查询的时候也必须加""
CREATE TABLE IF NOT EXISTS dev."timor_table"(
id VARCHAR primary key,
name VARCHAR,
age bigint);

#插入数据 必须用小引号,大的报错
upsert into student values('1','jake',10)

#创建二级索引
create  index my_index on timor_table(name);






#phonix数据类型,虽然hbase没有数据类型这一说
在 Phoenix 中，可以使用以下数据类型来创建表：
   - TINYINT：8位有符号整数。
   - SMALLINT：16位有符号整数。
   - INTEGER：32位有符号整数。
   - BIGINT：64位有符号整数。
   - FLOAT：单精度浮点数。
   - DOUBLE：双精度浮点数。
   - DECIMAL：任意精度的十进制数。

   - VARCHAR：可变长度字符串。
   - CHAR：定长字符串。
   - BOOLEAN：布尔值（true 或 false）。

   - DATE：日期，格式为 'YYYY-MM-DD'。
   - TIME：时间，格式为 'HH:MI:SS'.
   - TIMESTAMP：时间戳，包含日期和时间信息。




```



# hbase概览

### rowkey存储和查询

~~~mysql
HBase 是一个分布式的、可扩展的大数据存储系统，它基于 Google 的 Bigtable 架构设计。在 HBase 中，数据是按行（RowKey）进行存储的，而且这些数据是按照 RowKey 的字典顺序排序的。这种设计使得基于 RowKey 前缀的查询变得非常高效，因为具有相同前缀的 RowKeys 会被存储在一起。

### RowKey 设计

在设计 RowKey 时，将日期作为 RowKey 的一部分是常见的做法，尤其是在需要按时间顺序进行快速查询的场景下。例如，可以设计 RowKey 格式为 `日期_订单号`。这样，所有同一日期的订单会在 HBase 中相邻存储，便于快速检索。

### 过滤前缀的查询

使用 HBase 的客户端 API 可以实现基于前缀的过滤查询。以下是一个 Java 代码示例，展示了如何使用 HBase 的 `Scan` 和 `PrefixFilter` 来获取特定日期的所有订单：

```java
import org.apache.hadoop.hbase.client.*;
import org.apache.hadoop.hbase.util.Bytes;
import org.apache.hadoop.hbase.filter.PrefixFilter;

// ...

Configuration config = HBaseConfiguration.create();
try (Connection connection = ConnectionFactory.createConnection(config);
     Table table = connection.getTable(TableName.valueOf("your_table_name"))) {

    // 设定需要查询的日期前缀
    String datePrefix = "20240223"; // 例如，查询 2024 年 2 月 23 日的订单
    Scan scan = new Scan();
    scan.setFilter(new PrefixFilter(Bytes.toBytes(datePrefix)));

    // 执行查询
    try (ResultScanner scanner = table.getScanner(scan)) {
        for (Result result : scanner) {
            // 处理每一行数据
        }
    }
}
```

在这个例子中，我们创建了一个 `Scan` 对象，并设置了一个 `PrefixFilter`，这个过滤器会限制扫描只返回那些以特定日期为前缀的 RowKeys。

### HBase 的 RegionServer 分配

HBase 会将表数据切分成多个区域（Regions），每个 Region 包含一部分 RowKey 的范围。这些 Regions 被分配给不同的 RegionServers。HBase 通过使用一个起始和终止 RowKey 来定义一个 Region 的边界。当一个 Region 的数据量达到一定阈值时，它会被分裂（split）成两个新的 Regions，这个过程是自动的。

Region 的分配采用以下规则：

1. **连续性**：同一个 Region 包含的 RowKeys 是连续的。
2. **排序性**：因为 RowKeys 是按照字典顺序排序的，所以相近的 RowKeys 通常会在同一个 Region 或相邻 Regions 中。
3. **负载均衡**：HBase 会尝试将 Regions 平均分配到所有的 RegionServers 上，以实现负载均衡。

当设计 RowKey 时，应该注意避免热点问题，即不要让所有的写操作都集中在一个 Region 上。例如，如果使用时间戳作为 RowKey 的前缀，并且数据写入是连续的，那么新写入的数据总是在表的末尾，这可能导致最后一个 Region 成为热点。为了避免这个问题，可以考虑使用散列或者其他方法来使得 RowKey 的分布更加均匀。
~~~



###  使用场景

有一些数据没办法存到mysql里面，比如实时需求里面的记录用户今天首次登陆时间等等，这种没有存mysql没有意义。

hbase支持幂等性，这个比较好

### 查询数据

按rowkey获取指定数据

按rowkey的起始和终止位置扫描

按列族过滤，这个写法很复杂，这种按列族过滤，就是全表扫描。还是用pheonix生成吧

### 二级索引(还是没看懂)

~~~mysql
按你说法索引表为日期+订单表，那么这个索引都在一个region上，当我过滤单独日期那么只有一个region服务器，这样不效

对不起，我之前的解释可能有误。确实，如果索引表的rowkey是简单地将日期放在前面，那么同一天的所有订单都会在同一个region上，这可能会导致热点问题，尤其是在高负载时。

为了避免这个问题，我们可以采取以下策略来确保索引分布在多个RegionServer上：

1. **盐值**: 在日期前加上一个盐值，这个盐值可以基于日期的hash值。由于盐值是随机的，所以即使是相同的日期，也会被分散到不同的regions。

   例如，rowkey设计可以是这样的：
   ```
   [salt]-[date]-[order-id]
   ```
   其中`[salt]`是基于`[date]`计算的一个随机值或散列值的前几位。

2. **散列分区**: 使用一个散列函数来转换日期，并将散列值作为rowkey的一部分。

   例如，rowkey设计可以是这样的：
   ```
   [hashed-date]-[original-date]-[order-id]
   ```
   其中`[hashed-date]`是对`[original-date]`应用散列函数的结果。

在查询时，你需要知道如何反向工程你的盐值或散列值，以便能够查询特定日期的所有可能的rowkey。这通常涉及到在应用程序层面上执行一些额外的逻辑来生成所有可能的rowkey前缀，并对它们进行扫描。

为了进一步提高效率，你可以实现一个范围查询，它会生成一个散列值的范围，然后在这个范围内进行扫描。这样，你就可以并行地在多个RegionServer上执行查询，这比单个RegionServer上的单点查询更加高效。
~~~





### 服务器优化策略

```mysql
在HBase中，一个表的设计对于查询性能至关重要，尤其是当你希望查询能够高效地调用多个RegionServer时。以下是一些设计表时可以考虑的关键点，以确保能够利用HBase集群的并行处理能力：

1. **预分区（Pre-Splitting）**: 在创建表的时候预先分区可以防止RegionServer的热点问题。通过预分区，你可以确保数据在物理上分布在不同的RegionServer上，这样查询时就可以并行地进行。

2. **Row Key设计**: Row Key的设计至关重重要。你应该避免使用顺序ID或者时间戳作为Row Key的前缀，因为这会导致写入操作在一个Region上形成热点。使用散列前缀或者反转时间戳等策略可以使得写入操作更加均匀地分布在所有的Region上。

3. **列族（Column Family）策略**: 列族中的数据是一起存储的，因此应该将经常一起查询的数据放在同一个列族中。同时，尽量减少列族的数量，因为每个列族都是独立存储的，太多列族会增加IO。

4. **使用复合Row Key**: 如果查询模式是已知的，可以使用复合Row Key，将查询中的过滤条件作为Row Key的一部分，这样可以通过Row Key的前缀扫描来高效地查询数据。

5. **数据局部性**: 如果你的查询是基于地理位置或者其他具有自然局部性的属性，考虑将这些属性编码到Row Key中，以确保相关数据在物理上靠近，这样可以减少查询时跨RegionServer的通信。

6. **均匀的数据分布**: 为了保证数据在RegionServer之间均匀分布，可以使用哈希算法或者一些自定义算法来生成Row Key，从而避免某个RegionServer变成热点。

7. **Region大小和分裂策略**: 监控你的Region大小和分裂，确保没有过大的Region，这样可以避免查询时因为Region过大而导致的性能问题。

8. **缓存策略**: 合理利用HBase的BlockCache和Bloom Filter可以提高读取性能，尤其是对于频繁访问的数据。

9. **协处理器（Coprocessors）**: 对于复杂的查询操作，可以使用协处理器在RegionServer端进行数据的预处理，减少数据在网络中的传输。

10. **监控和调优**: 使用HBase自带的监控工具，如HBase Master UI，以及其他第三方监控工具来监控Region的分布和负载情况，根据监控数据进行调优。

设计HBase表时，你需要根据你的应用场景和查询模式来决定上述建议的适用性。通常需要在设计阶段进行充分的测试和模拟，以确定最佳的设计方案。
```



# 细节总结

### 增加读效率，写效率

```mysql
在HBase中，确保数据的顺序写入和顺序读取涉及到对行键（Row Key）的设计和对表的访问模式的理解。以下是一些确保数据顺序写入和顺序读取的策略：

### 顺序写入

1. **行键设计**：HBase中的数据是按照行键的字典序存储的。设计行键时，如果你能够保证新插入的行键总是字典序上的“最后”一个，那么写入就是顺序的。例如，你可以将时间戳作为行键的前缀，并确保时间戳是单调递增的。

2. **预分区**：在创建HBase表时，可以预先定义分区（Region），这样可以避免在数据写入时发生频繁的分区拆分操作。如果你知道行键的分布，你可以根据行键来预分区，以便更均匀地分布写入负载。

3. **批量写入**：使用HBase的批处理接口可以减少写入延迟。如果数据是按照行键的顺序生成的，那么批量写入也是顺序的。

### 顺序读取

1. **扫描操作**：在HBase中，顺序读取通常是通过扫描（Scan）操作来实现的。扫描操作可以指定起始行键和终止行键，HBase会按照行键的字典序返回结果。

2. **过滤器**：可以使用HBase提供的各种过滤器来精确控制扫描的结果，例如，只返回特定前缀的行键或满足某些条件的行。

3. **缓存和批量**：在执行扫描操作时，可以设置缓存和批量大小，以减少RPC调用的次数，提高顺序读取的效率。

4. **共处理器**：HBase共处理器（Co-processor）可以在服务器端执行自定义逻辑，可以用来优化顺序读取的性能。

### 注意事项

- **热点问题**：如果使用时间戳作为行键的前缀，并且数据写入速度非常快，可能会导致所谓的“热点”问题，即所有的写入操作都集中在一个Region Server上。这会导致写入性能瓶颈。为了避免这个问题，可以在时间戳前面加上一个随机数或散列值。

- **时序数据**：对于时序数据，可以考虑使用反转时间戳（当前时间减去事件发生的时间戳）作为行键的一部分，这样最新的数据就会被写入到表的不同区域，避免了热点问题。

- **设计合理的行键**：行键的设计应该既要满足顺序写入和读取的需要，也要考虑到负载均衡和避免热点问题。

通过上述策略的合理应用，可以在HBase中实现高效的顺序写入和读取。然而，具体的实施细节会依赖于你的应用场景和数据特征，需要进行细致的规划和测试。
```

### 加盐设计

~~~mysql
在HBase中使用盐值时，确实会影响到筛选条件的设置，因为盐值会改变行键的前缀。读取时，你需要对每个可能的盐值都执行一次扫描，然后将结果合并。这样可以确保你检索到所有相关的行。

假设你使用了一个简单的单字节盐值，比如0-9，你的行键可能看起来像这样：`1_<timestamp>_restOfKey`，`2_<timestamp>_restOfKey`，等等。

在这种情况下，如果你想扫描所有在特定时间范围内的行，你需要：

1. 对于每个可能的盐值（在这个例子中是0-9），执行一个扫描操作。
2. 每个扫描操作都使用时间范围作为过滤条件。
3. 合并所有的扫描结果。

以下是一个简化的Java代码示例，说明如何使用HBase的API来实现这一点：

```java
Table table = connection.getTable(TableName.valueOf("your_table"));
List<Scan> scans = new ArrayList<>();

for (int i = 0; i < 10; i++) { // 假设盐值范围是0-9
    Scan scan = new Scan();
    byte[] startRow = Bytes.toBytes(i + "_" + desiredStartTimestamp);
    byte[] stopRow = Bytes.toBytes(i + "_" + desiredStopTimestamp);
    scan.setStartRow(startRow);
    scan.setStopRow(stopRow);
    scans.add(scan);
}

ResultScanner[] scanners = new ResultScanner[scans.size()];
// 对于每个盐值执行扫描
for (int i = 0; i < scans.size(); i++) {
    scanners[i] = table.getScanner(scans.get(i));
}

// 然后你需要合并这些扫描器的结果
// 这可能涉及到对结果进行排序，因为它们不会按照时间顺序返回
// 这个排序可以在客户端进行，或者通过MapReduce等分布式处理方式在多个节点上进行

// 最后，不要忘记关闭扫描器和表连接
for (ResultScanner scanner : scanners) {
    scanner.close();
}
table.close();
```

在实际应用中，你可能需要根据自己的业务逻辑对这个基本示例进行调整。

这种方法的缺点是它增加了客户端的复杂性，并且可能会导致更多的扫描操作。不过，它确实可以帮助你在使用盐值的同时，检索到所有相关的数据。如果读取性能成为瓶颈，可能需要重新考虑使用盐值的策略或者改进行键设计。
~~~



### 对接hive

```mysql
hbase中用订单号做个rowkey，按日期扫描，就算我在hbase中设计了2级索引，那么hive解析sql时会怎么用这个二级索引呢？
hive会自动用吗？想用二级索引,需要怎么设置呢？
```





# 组成架构

### 存储方式

行列存，一个列族下多个列是行存，多个列族是行存，想行存就设置1个列族

### 数据模型

namespace 类似detabase的概念

table 

row: 表的一行数据右rowkey和多个column组成，查数据只能按rowkey检索

colum:列族和列名来限定，column Family ， Column Qualifier

timeStamp：相同rowkey有新插入，有多条数据根据时间戳找最新的

cell：确定唯一单元





# 客户端指令

注意不能加；;是拼接多个指令用的，回车不会直接执行

进入客户端  bin/hbase shell

### ddl表操作

查看库  list_namespace

创建库  create_namespace    "dev"

查看库中表 list_namespace_tables  "dev"

清空表 truncate "tb1"

查看所有表 list

创建表: create  'tb1' , 'cols_a','cols_b' 

创建表指定库create  'namspace: tb1' , 'cols_a','cols_b' 

查看表结构 describe "tb1" 指定库  describe "dev:tb1"

删除表  先disable "tb"  再 drop "tb"



### dml数据操作

增加一条数据put 表名,rowkey,"列族:列名",值    ｜  put "tb1" ,1001,"cols1:name",lpc

删除某一列  delete "tb", 1000 ,"info:name"

删除一行数据  deleteall "tb1" , 1000

查看某行的列组:get  "student" 1001, 'info:name'



### 查询操作

查看整表数据 scan "tb1" 

查看指定行get "studnet" , '1001'

查看某行的列组:get  "student" 1001, 'info:name'

统计表数据条数 count "tb"  1个rk算一条

shell的过滤查询很麻烦，还是用Phoniex吧

# API





# 不重要问题



1.

ClickHouse 和 HBase 是两种不同的数据库系统，它们之间的主要区别如下:

1. 数据模型: ClickHouse 是一个列式存储的数据库，而 HBase 是一个键值存储的数据库。
2. 性能: ClickHouse 以高性能和大数据处理能力著称，而 HBase 则更适用于大规模数据存储和实时数据读写。
3. 数据处理: ClickHouse 支持 SQL 查询语言，支持复杂的数据分析和处理，而 HBase 更适合于实时读写数据。
4. 分布式架构: ClickHouse 采用分布式集群架构，而 HBase 是基于 Hadoop 的分布式数据库。

总的来说，ClickHouse 更适合于大数据分析和报表系统，而 HBase 更适合于大规模数据存储和实时数据读写。



clickhouse是一个为了OLAP而生的列数据库

clickhouse也支持join，那么这不是所有的都比hive+hdfs好了吗？

能存大量数据，还是个数据库，还有自己的数据计算引擎。

之前就有想过，怎么用hive对接habase的索引。这是类似的实现吗？

