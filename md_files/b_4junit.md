## pom配置

```xml
<dependency>
    <groupId>junit</groupId>
    <artifactId>junit</artifactId>
    <version>4.12</version>
</dependency>
```



## 常用注释

test

不用main方法，不用创建对象也可以直接执行某个方法，这样每个方法能单独执行，不需要在main中来回更改

```java
public class A2_HdfsClientOperate {
    FileSystem  fs;

    @Before
    public  void init() throws URISyntaxException, IOException {
        Configuration configuration = new Configuration();
        URI uri = new URI("hdfs://project1:8020");
        fs = FileSystem.get(uri, configuration);
    }

    @Test
    public void mkdirs() throws URISyntaxException, IOException {
        fs.mkdirs(  new Path("/java-code-mkdir/aa") );
    }

    @After
    public void close() throws IOException {
        fs.close();
    }
}
```

before/after

before注解的方法会在test前执行,after会在后执行，如果不加before    方法利用到了fs对象，没有init初始话