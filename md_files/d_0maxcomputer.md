## 框架优化

#### skew join 

优化的数据倾斜采样,会对于热点数据，进行自定拆解任务

#### distributed mapjoin

大表关联中表，使用distributed mapjoin优化
Distributed MapJoin是MapJoin的升级版，适用于小表Join大表的场景，二者的核心目的都是为了减少大表侧的Shuffle和排序。

注意事项：

Join两侧的表数据量要求不同，大表侧数据在10 TB以上，小表侧数据在[1 GB, 100 GB]范围内。

小表侧的数据需要均匀分布，没有明显的长尾，否则单个分片会产生过多的数据，导致OOM（Out Of Memory）及RPC（Remote Procedure Call）超时问题。

SQL任务运行时间在20分钟以上，建议使用Distributed MapJoin进行优化。

由于在执行任务时，需要占用较多的资源，请避免在较小的Quota组运行。

