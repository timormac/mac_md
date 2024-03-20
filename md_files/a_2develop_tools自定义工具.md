## mysql_tools

#### 常见问题

```mysql
#字符集不兼容
当创建一个表时,不指明字符集那么默认是：CHARSET=latin1，插入中文字符会报错
要手动指定字符集CHARSET=utf8

#插入数据id主键重复
目前mock数据的对象id都是默认值0,插入mysql的预编译sql是有id字段的。
目前都是0,所以建表时，id要指定AUTO_INCREMENT,要加上AUTO_INCREMENT=1000，自增，不然会报错id重复主键
create tb(
  `id` bigint(20) NOT NULL AUTO_INCREMENT
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1000 

```





## 血缘分析Calsite

#### 常见问题

```mysql
#可以手动指定数据库语法
oracle的sql，不手动指明，有时候会解析报错.因为oracle的表可以库."表名" 有""号


#解析血缘
目前解析的表，会把别名的临时表也解析出来，这样后续深入了解一下
```

