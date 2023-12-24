# Hudi简介

```
Hive 和 Hudi 是两个不同的项目，它们都是在大数据生态系统中使用的，但它们的目的和功能有所不同。
Hive 是一个建立在 Hadoop 上的数据仓库软件，用于数据摘要、查询和分析。Hive 使得那些熟悉 SQL 的人可以通过 HiveQL（一种类似于 SQL 的查询语言）编写查询。这些查询然后被转换成一系列的 MapReduce、Tez 或 Spark 作业来执行。Hive 旨在提供一个 SQL 接近的接口来查询存储在 Hadoop 文件系统（HDFS）或其他兼容存储系统中的大数据集。
Hudi（Apache Hudi）代表 "Hadoop Upserts Deletes and Incrementals"，是一个为 Hadoop 生态系统构建的数据存储层，用于支持高效的插入、更新和删除操作。Hudi 通过提供快速的增量数据处理和数据变更流功能，使得在大数据平台上进行更复杂的数据管道操作成为可能。
Hudi 的主要特点和优势包括：
支持近实时的数据插入、更新和删除：Hudi 允许对存储的数据集进行快速修改，这对于需要频繁更新数据的应用程序非常重要。
增量处理：Hudi 支持增量读取，这意味着可以仅查询自上次查询以来发生变化的数据，从而提高查询效率。
时间旅行：Hudi 提供了查看数据在任意时间点的能力，这是通过跟踪数据的变化历史来实现的。
事务支持：Hudi 提供了对多个写操作的原子性保证，这对确保数据的一致性至关重要。
最初，Hudi 被设计出来是为了解决 Uber 大数据平台上数据存储的问题，特别是在高吞吐量的数据流中快速更新大型数据集的需求。Uber 需要一种方式来有效地处理大量的数据插入、更新和删除操作，同时保持数据的一致性和查询效率。Hudi 就是为了解决这些挑战而创建的。
与 Hive 相比，Hudi 提供了更为高级的数据管理功能，特别是对于需要处理数据变更和更新的场景。而 Hive 更多地被用于静态数据的批量处理和分析。两者可以结合使用，在 Hudi 管理的数据上运行 Hive 查询，以充分利用 Hive 的 SQL 查询能力和 Hudi 的高效数据管理。
```
