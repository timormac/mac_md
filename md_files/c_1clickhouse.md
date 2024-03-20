# 学习进度



# 个人理解

```mysql
#对标
clickhouse对标的是doris,都是分布式mpp数据库,olap引擎

#查询场景
对于一些数据查询，比如实时统计订单表今天累积销售额，去重人数
方案一：把etl后的数据存在clickhouse,doris,hbase。通过clickhouse和doris引擎临时查询。或者phoenix查询hbase，不过hbase并不			善于做这个事情
方案二：直接把要的指标结果用flink的状态去累积计算值，并且定期去刷写到外部系统


```



# 简介

#### 文章相关

讲述clickhouse实际应用的 https://www.infoq.cn/article/vggxs8hqbewg1z3ndtt0

#### 大概理解

```mysql
#文章网站
https://www.infoq.cn/article/vggxs8hqbewg1z3ndtt0

#错误理解
认为ck统计这么快，为什么不用ck代替hive进行数仓管理？
ck只有在一些层面上聚合快，例如单表某维度，统计某字段计算快。在对于多表join，以及窗口函数等复杂处理，并不在行。

他的计算快的原理，我感觉是，你建表时需要指定你聚合的口径，累加哪些数值。比如你按时间聚合，统计当天的总金额，总单数，可能会像kylin一样，预聚合，临时插入的数据尚未聚合的，进行临时聚合,来保证速度。


#优点
1）数据压缩比高，存储成本低。


ClickHouse 最大的特点就是快，其他的比如数据压缩比高、存储成本低等等，所以以前我们有很多的功能埋点都集中在 ES 里面，但是从年初开始到现在应该是把所有的 ES 埋点全部转成 ClickHouse，所以根据 ClickHouse 的数据压缩比，首先就可以评估到我们硬件成本比采用 ES 的方案时它至少降低 60%以上，日志在 ES 和 ClickHouse 上面的查询性能这里就不展开对比。



2）支持常用的 SQL 语法，写入速度非常快，适用于大量的数据更新


它的语法跟 MySQL 比较类似，但是它有一个特点就是它的 join 不能太复杂，A 表 join B 表的时候不能直接 join C 表，需要把 A 表 join B 表的 AS 成一个带别名的临时表以后再去 join C 表，所以它的语法主要还是在 join 上面会比较独特。如果你的查询语句很复杂，你的 join 就会看起来很长，所以查询语句可读性不像 SQL 那么好理解。但是它的写入速度非常快，特别适合于像我们的离线数据每天都是几亿几十亿数据量的更新。官方资料介绍它是按照每秒钟 50-200 兆导入速度。



3）依赖稀疏索引，列式存储，CPU/内存的充分利用造就了优秀的计算能力，并且不用考虑左侧原则


它是依赖稀疏索引，列式存储。我们在去取数据的时候，经常会只取某几个字段，按列存储对 IO 比较友好，减少 IO 的次数，也是在查询速度上一个辅助。再就是它很大程度利用了 CPU，我们都知道 MySQL 是单线程获取数据的，但是 ClickHouse 服务器上面有多少个 CPU，它就会用服务器的一半 CPU 去拉，像我们平时用的 40 核或者 32 核的物理机，基本上拿一半的核去拉数据。当然，这个可以修改配置文件每个 query 用多少 CPU。因为它一个查询需要消耗太多的 CPU，所以在高并发上面是一个短板。当然，我们也不需要考虑什么左侧原则之类的，就算你的查询条件不在索引里面，ClickHouse 的查询一样非常快。


2、缺点
1）不支持事务，没有真正的 update/delete


不支持事务，没有真正的 update/delete，主要还是高并发的短板，所以我们应用都在一些能 Hold 住的场景下。如果对外放在公网，这个 QPS 就可能很难控制，这种场景用 ClickHouse 就要谨慎。

2）不支持高并发，可以根据实际情况修改 qps 相关配置文件


ClickHouse 吃 CPU，可能团队十个人通过执行同一个查询就可以把一台 CPU 40C 的物理机打爆，但是为什么我前面说我们有 700 亿的数据只需要十台物理机就可以扛得住呢？其实我们对 ClickHouse 做了很多保护。


```



#### 代替es

```mysql
当你使用定位全文检索，比如定位错误日志时,使用es更好用。当你做的是日志分析的时候，clickhouse比较好

公司可能会在多个不同的场景中更侧重于日志数据的分析和聚合，而不是全文搜索。以下是一些具体的使用案例：

1. **用户行为分析**：
   - **案例**：在线服务提供商可能会分析用户的点击流日志来理解用户行为，优化用户界面，提高转化率。
   - **维度**：时间、用户属性（如地区、设备类型）、用户行为（如页面浏览、点击事件）。

2. **系统性能监控**：
   - **案例**：SaaS 提供商可能需要监控其服务的性能，分析响应时间和系统负载，以确保满足服务水平协议（SLA）。
   - **维度**：时间、服务名称、响应时间、系统资源使用情况（CPU、内存、磁盘IO）。

3. **安全事件分析**：
   - **案例**：企业可能需要分析安全日志来检测和响应潜在的安全威胁或违规行为。
   - **维度**：时间、用户账号、事件类型（如登录尝试、权限提升）、源IP地址。

4. **运营效率分析**：
   - **案例**：物流公司可能分析车辆和货物的日志数据，以优化路线规划和减少运输成本。
   - **维度**：时间、车辆ID、位置、速度、货物类型。

5. **业务流程优化**：
   - **案例**：电子商务平台可能分析订单处理日志，以发现瓶颈并优化业务流程。
   - **维度**：时间、订单状态、处理时间、关联的用户和产品。

6. **财务和交易分析**：
   - **案例**：金融机构可能需要分析交易日志，以监控交易模式、防止欺诈行为并确保合规性。
   - **维度**：时间、交易类型、金额、用户ID、交易状态。

7. **产品性能跟踪**：
   - **案例**：软件公司可能会分析产品的使用日志，以跟踪功能的使用频率和性能，从而指导产品的迭代开发。
   - **维度**：时间、功能模块、使用频率、执行时间、错误率。

8. **网络流量分析**：
   - **案例**：互联网服务提供商（ISP）可能会分析网络流量日志，以优化网络带宽分配和缓解拥塞。
   - **维度**：时间、IP地址、流量类型（如视频、邮件）、数据包大小。

在这些案例中，ClickHouse 的列式存储和高效的数据聚合功能可以使这些分析更快速、更经济地执行。由于日志数据通常是多维度的，列式数据库特别适合执行涉及多个维度的复杂查询和聚合操作。而且，ClickHouse 的强大 SQL 支持使得执行这些分析变得更加灵活和强大。
```



#### 对接hive查询

对于实时分析查询,clickhouse只能2个表join，不适合多个表join,所以想全面的分析，还是要通过hive去处理大部分数据集。

每天将hive处理好的当天数据导入clickhouse，通过clickhouse进行实时分析。



# 架构



```mysql
#适合场景
不适合存初始数据，适合存已经处理过的的宽表，不需要再join等操作的宽表。

```
