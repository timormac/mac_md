# 问题记录

### 源码方法调用位置

 看一些源码的时候，有时候需要传入一个借口，实现某个方法，比如flink的自定义map方法，有个问题，就是我现在想知道，这个传入的map方法，到底是谁在哪一步开始调用的，现在一直没头绪

### optional使用场景

感觉和is null判断代码量差不多，什么场景用optinal,多次调用对象的方法时,就有没问题

好像说时链式调用,

比如User里有很多数据需要校验，校验id，名字，商家,需要调用多次User.get方法，不然每次都要用null校验



# 问题已解决

### jar指定lib库目录

2  maven打成的jar包，用java -cp 执行时，服务器找不到fastjson的依赖,而且把fastjson的jar包放到jdk的lib库还是找不到‘

java执行的时候，指定加载lib库路径，然后把用到的相关jar包放到库中。java -Djava.ext.dirs=/opt/lib  -cp  a.jar Test  



# java历史版本特性

以下是一些 Java 的重要版本和其引入的主要特性的概述：

1. Java 5 (J2SE 5.0):
   - 引入了泛型（Generics），提供类型安全和更好的代码重用。
   - 引入了自动装箱和拆箱（Autoboxing and Unboxing），简化了基本类型和对应包装类型之间的转换。
   - 引入了增强的 for 循环（Enhanced for loop），简化了遍历数组和集合的操作。
   - 引入了注解（Annotations），用于提供元数据和编译时检查。
   - 引入了枚举（Enums），提供了定义和使用枚举类型的支持。
2. Java 6 (Java SE 6):
   - 引入了脚本语言支持（Scripting API），允许在 Java 程序中执行脚本语言。
   - 引入了编译时注解处理器（Annotation Processing），用于在编译时生成额外的源代码。
   - 引入了并发编程增强，如线程安全的集合类和并发工具类。
3. Java 7 (Java SE 7):
   - 引入了钻石操作符（Diamond Operator），简化了泛型的使用。
   - 引入了字符串在 switch 语句中的支持。
   - 引入了 try-with-resources 语句，简化了资源的管理和释放。
   - 引入了新的文件系统 API（NIO.2），提供了更强大和灵活的文件操作功能。
4. Java 8 (Java SE 8):
   - 引入了函数式接口和 Lambda 表达式，支持函数式编程风格。
   - 引入了流式操作（Stream API），提供了一种更便捷的集合数据处理方式。
   - 引入了默认方法（Default Methods），允许在接口中定义具体的方法实现。
   - 引入了新的日期和时间 API（java.time 包），提供了更好的日期和时间处理功能。
5. Java 9 (Java SE 9):
   - 引入了模块化系统（Java Platform Module System，JPMS），提供了更好的代码组织和可重用性。
   - 引入了 JShell，一个交互式的 Java 编程工具。
   - 引入了改进的 Stream API，提供了更多的操作和性能优化。
6. Java 10 (Java SE 10):
   - 引入了局部变量类型推断（Local Variable Type Inference），允许使用 var 关键字来声明局部变量。
7. Java 11 (Java SE 11):
   - 引入了长期支持（LTS）版本的概念。
   - 移除了一些过时的 API，如 Applet、Java Web Start 等。
8. Java 12-17:
   - 引入了一些小的改进和增强，如新的字符串方法、Switch 表达式、垃圾回收器的改进、新的嵌套类型支持等。

这只是一些主要版本的特性摘要，每个版本都有更多的改进和增强功能。如果您需要详细了解每个版本的特性和改进，请参阅 Java 官方文档和发布说明。



# 功能代码

### 类名创建对象 

```java
// 步骤1：定义类的全限定名
String className = "com.example.MyClass";
// 步骤2：加载类
Class<?> clazz = Class.forName(className);
// 步骤3：创建对象
Object object = clazz.newInstance();

//获取类中的所有属性列表
Field[] fields = clazz.getDeclaredFields();
//遍历属性列表打印名字
for (Field Field:Fields) {
   field.getName();
}
//获取属性类型
fields[1].getType();

//设置对象属性,obj是instance创建的对象,1是值。注意参数2可以传递obj类型，object里面有个属性是class<?> 保存了真实类型
fields[1].set(obj,1)

```



### java脚本指令

java 指令具体能传什么参数，去百度：Java启动参数、调优及分析。

可以将依赖jar包放到 JAVA_HOME/ jre/lib/ext下面去，这样执行java -jar也能找到相关主类

```
java -cp  a.jar:b.jar   Test  加载a,b jar包的所有class类，并找到Test类执行 
java -Djava.ext.dirs=/opt/lib  -cp  a.jar Test  指定加载lib库,执行jar 
java -cp a.jar  -jar b.jar  加载a.jar包，然后执行b.jar的主类
java -jar  a.jar   执行jar包，需要提前配置Main主类
```

-Djava.ext.dirs是通过设置系统属性的方式也加载jar包的，这个级别就有点高了，和-classpath的区别在于-Djava.ext.dirs会覆盖Java本身的ext设置，java默认配置加载JAVA_HOME/lib/ext目录下的所有jar文件，如果手动指定了-Djava.ext.dirs 

并且忘记把  JAVA_HOME/ jre/lib/ext路径给加上，则会失去一些功能。

后台运行java   :nohup java YourClass > output.log &



### jar包指定MainClass

目前还是有问题，加入配置后，还是无法找到主类

maven项目打包时在pom中添加

```
  <build>
  			<!--  指定打包后jar包的名字    -->
        <finalName>JarPackageFileName</finalName>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-shade-plugin</artifactId>
                <version>3.2.1</version>
                <executions>
                    <execution>
                        <phase>package</phase>
                        <goals>
                            <goal>shade</goal>
                        </goals>
                        <configuration>
                            <transformers>
                                <transformer implementation="org.apache.maven.plugins.shade.resource.ManifestResourceTransformer">
                                    <!--这里写你的main函数所在的类的路径名，也就是Class.forName的那个字符串-->
                                    <mainClass>com.demo.xxx</mainClass>
                                </transformer>
                            </transformers>
                        </configuration>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>

```



### 修改源码并打包



```sql
#下载-source源码包
flink-1.17-source.jar 带source的，里面都是java原文件，而不是.class字节码文件
```







# java效率开发

### guava工具包

连接：https://www.kancloud.cn/wizardforcel/java-opensource-doc/112614

```sql
Guava（Google Guava）是一个由 Google 提供的开源Java库，它提供了许多实用的工具和函数，用于简化Java编程。Guava库包含了很多模块，每个模块都提供了不同的功能。其中一个最常用的模块是 guava 模块，它包含了 Guava 库的核心功能。
#集合工具：
Guava 提供了丰富的集合工具类，用于操作和处理集合数据结构，例如列表、集合、映射等。这些工具类提供了更便捷和强大的操作方法，使集合的处理更加简单和高效。
#字符串处理：
Guava 提供了一些字符串处理的工具类，例如拆分、连接、替换、格式化等操作。这些工具类可以简化字符串处理的代码，并提供了更多的功能和选项。
#缓存：
Guava 提供了一个强大的缓存框架，用于在应用程序中管理和使用缓存。它支持不同的缓存策略和过期机制，并提供了高性能和可配置的缓存实现。
#函数式编程：
Guava 提供了一些函数式编程的支持，例如函数接口、函数组合、断言和预条件等。这些功能可以帮助简化函数式编程的代码，并提供了更多的函数式编程工具。
#其他模块
除了 guava 模块，Guava 还包含其他模块，如 guava-collections、guava-concurrency、guava-strings 等，每个模块都提供了特定的功能和工具。
#pom依赖
<dependency>
    <groupId>com.google.guava</groupId>
    <artifactId>guava</artifactId>
    <version>30.1-jre</version>
</dependency>
```



### stream流

```java
//集合的遍历,可能要做多次操作，像迭代式的，这时候用stream，里面的返回的还是list

//stream流:过滤a开头，然后全部大写,再将stream转成list
arr.stream().filter( s->s.startsWith("a") ).map( String::toUpperCase).collect(Collectors.toList());

//stream流:按首字母分组,stream提供了collect(Collectors.groupingBy() )
Map<Character, List<String>> collect = arr.stream().collect(Collectors.groupingBy(s -> s.toCharArray()[0]));
```



### lamda使用场景

```java
ArrayList<String> arr = new ArrayList<>();
//遍历集合 .forEach(lamda表达式)
arr.forEach ( str -> System.out.println(str) );
//lamda写法2:参数只用一次,传给方法体时省略参数, ::然后不加()。含义：把for的变量传给，arr2的add方法里
arr.forEach( arr2::add);
//lamda写法3:调用参数本身的方法时，写法: 参数类型::方法
arr.stream().map( String::length );
```



### optional代替null判断

对于迭代式的，或者对一个对象的多个属性进行校验时，每次校验都会少写一行代码非空判断

```

```



# java习惯养成

### java常用类库

目录：日期库   json库  Math库  String库

日期库

```java
//日期库
import org.apache.commons.lang3.time.DateFormatUtils;
<dependency>
    <groupId>org.apache.commons</groupId>
    <artifactId>commons-lang3</artifactId>
    <version>3.12.0</version>
</dependency>
  
//获得本地时间戳
long stamp = System.currentTimeMillis();
  
//格式化时间戳  
DateFormatUtils.format(ms,"yyyy-MM-dd HH:mm:ss.SSS")


  
  
//通过calendar日历获取当前时间  
Calendar calendar = Calendar.getInstance();
int year = calendar.get(Calendar.YEAR);
int month = calendar.get(Calendar.MONTH);
int date = calendar.get(Calendar.DATE);
int hour = calendar.get(Calendar.HOUR_OF_DAY);
int minute = calendar.get(Calendar.MINUTE);
int second = calendar.get(Calendar.SECOND);
```

json库

```java
//将字符串转为json
String s="{\"address\":\"北京市\",\"age\":20,\"id\":1,\"name\":\"张三\"}";
JSONObject jsonObject = JSON.parseObject(s);
String address = jsonObject.getString("address");
Integer age = jsonObject.getInteger("age");
Set<String> columns = jsonObject.keySet();
Collection<Object> values = jsonObject.values();


//将对象转为json
String jsonString = JSON.toJSONString(student);

//将对象数组，转为json数组  
ArrayList<Student> students = new ArrayList<>(
String s = JSON.toJSONString(students);

//将map转为json
 HashMap<String, String> map = new HashMap<>();
 map.put("name","张三");
 String s1 = JSON.toJSONString(map);
  
 // 将json字符串 转为对象
String objectString="{\"address\":\"北京市\",\"age\":20,\"email\":\"zs@sina.com\",\"id\":1,\"name\":\"张三\"}";
Student student = JSON.parseObject(objectString, Student.class);
```

Math库

```java
Math.max（a,b）
```

String库

```java
	//字符串格式化
	int a1 = 10;
	String  str = String.format("aa%d",a1)

	//获取字符串长度
  "abc".length()
  
  //字符串分割
  "a,b".split(",")
    
  //占位符
    String sql = "select %s  from %s";
		String format = String.format(sql,"name","table")
  
```



### 源码解读习惯

1 有一些代码,做一些判断之类的，但是并没有返回值什么的，比如说对于一个传入的集合不能为空,然后才能进行后续操作，

源码里后续操作并不是通过if判断是否为空来执行的，而是做一个判空操作，若为空直接throw异常，这样后续不会执行

例子:一些操作没有返回值，发挥作用是用throw异常

```java
    public <OUT> DataStreamSource<OUT> fromCollection(
            Collection<OUT> data, TypeInformation<OUT> typeInfo) {
      	
        //这个操作是用来判断集合为空的，点进去看是做判断和throw异常
        Preconditions.checkNotNull(data, "Collection must not be null");

        //这个操作是判断元素为同类型，并且没有null元素，点进去看是做判断和throw异常
        FromElementsFunction.checkCollection(data, typeInfo.getTypeClass());

        SourceFunction<OUT> function = new FromElementsFunction<>(data);
        return addSource(function, "Collection Source", typeInfo, Boundedness.BOUNDED)
                .setParallelism(1);
    }
```

2 有一些源码abstract抽象类中，还会定义抽象类，而且这种内部抽象类也也可以在别的代码中实现

例子：flink的KeyedProcessFunction抽象类中，定义了一个public abstract class Context{},通过control+H查找，

看到在KeyedProcessOperator中，定义了个私有类实现了内部抽象类class Context

```java
 private class ContextImpl extends KeyedProcessFunction<K, IN, OUT>.Context {}
```

 

### 快速适应框架API

1  例如flink中通过DataStream创建窗口,ds.window()

winodow()的参数需要WindowAssigner对象，通过control H查看实现类有:

ProcessingTimeSessionWindows,SlidingProcessingTimeWindows,TumblingProcessingTimeWindows等
然后发现ProcessingTimeSessionWindows的构造器是私有的,看到of方法会调用构造器生成对象,

idea中点开Structure，可以看到各个方法的返回值，直接找返回值是ProcessingTimeSessionWindows的方法即可。

```java
//最后执行的代码
keyBy.window(TumblingProcessingTimeWindows.of(Time.seconds(10)))
```



# 类/修饰符

### 包的命名

包的命名 一般都是com.caibeike.项目名称.模块名称

这样命名的原因好像是，这样不同项目的jar包，最后能在同一个目录下,在mvn中artifact是项目名字，groupid是公司名字，

当你创建mvn项目的时候根据grouid，默认创建的包层级就是groupid，这样当把项目打成jar包的时候，在仓库里也是一个目录下的

```xml
  <groupId>com.cbk.timor</groupId>
  <artifactId>learning_maven_origin</artifactId>
  <version>1.0</version>
```



### 父类设置无参构造器

测试过，如果父类没有无参构造器，那么子类继承的时候，必须自己创建一个构造器，不然报错显示父类没有默认构造器。

所以为什么代码里总有一个无参构造器多此一举，或者子类手动显式写一个和父类一样的构造器，调super(a,b)。

### getter和setter用途

在 Java 中给属性设置 getter 和 setter 方法的设计有以下几个主要目的和意义：

1. 封装数据访问：使用 getter 和 setter 方法可以将属性的访问限制在类的内部，通过方法来控制对属性的读取和修改。这样可以隐藏属性的具体实现细节，提供统一的访问接口，增加了代码的封装性和安全性。
2. 访问控制和数据验证：通过 getter 和 setter 方法，可以在设置属性时进行访问控制和数据验证。你可以在 setter 方法中添加逻辑，例如检查属性值的合法性、范围限制、数据格式验证等。这样可以确保属性的有效性和一致性。
3. 可以添加额外逻辑：通过 getter 和 setter 方法，你可以在访问属性时添加额外的逻辑。例如，在 getter 方法中可以实现延迟加载，只有在需要时才获取属性值；在 setter 方法中可以触发其他操作，例如通知其他对象属性的变化。
4. 对象状态管理：通过 getter 和 setter 方法，可以更好地管理对象的状态。你可以在 setter 方法中记录属性的修改历史，或者在 getter 方法中返回属性的计算值。这样可以提供更灵活和可控的对象状态管理机制。
5. 兼容框架和工具：许多 Java 框架和工具都依赖于 getter 和 setter 方法来访问和操作对象的属性。例如，ORM（对象关系映射）框架需要通过 getter 和 setter 方法来映射数据库表和对象的字段。如果没有这些方法，这些框架和工具将无法正常工作。

总之，给属性设置 getter 和 setter 方法可以提供更好的封装性、访问控制和数据验证，同时也提供了扩展性和兼容性。这种设计模式使得代码更易于维护、重用和扩展，并且符合面向对象编程的封装原则。



### 修饰符private

场景1，有些属性 设置为private属性，这样这些属性赋值的时候需要使用getter和setter方法，因为有的赋值可能满足类型范围，但是不满足需求范围，可以在getter和setter中做条件处理

private修饰的属性和方法只能在本类中使用，在子类用调用不了父类的private修饰的方法。

### 修饰符final

final修饰的类不能被继承，修饰的方法不能被重写。 被修饰的变量一旦被赋值不能改变

# 基础语法

### 代码原则

详情请看csdn收藏的代码优化6大原则

对有代码，要有拓展性，如果需要添加新的功能，不能具体到去用到的代码每一处去修改，这种要提取出来，弄合适的设计模式

比如获取一个解析器，有json解析器，xml解析器，需要if,else来判断文件格式来获取解析器，这样代码看上去不简洁，并且如果要是有新的解析类型那么，需要在所有这段代码里都要添加一个新的if-else，不符合对拓展开放的原则。

### 泛型

应用场景，范型类，范型接口，范型方法，集合中用范型, 范型不是真正的限制类型，而是编译的时候检查

集合中使用范型

```java
//集合中不使用范型，默认是Object类型，用范型可以限制集合中类型
List<String>  list = new ArrayList<String>()
```

类范型, 范型方法,范型多态

```java
public class ClassMethodGenericType<T> {
  //范型修饰属性
    T  t;
  //范型修饰参数
    void add(T t){}
  //范型修饰返回值
    T get(){ return null;}
  
  //范型多态：传入的范型类必须是T类或者T的子类
   void func( List<? extends T> list ) {} 
  
   //范型多态：传入的范型类必须是T类或者T的父类
   void fun2( List<? super T> list ) {} 
  
   //方法范型，第一个<M>表示调用方法时要传一个范型， Man<M>表示返回值的Man范型的M, 调用时写法 obj.<String>getMan() 
    <M> Man<M> getMan(){ return new Man(); }
 
    public static void main(String[] args) {
        obj = new ClassMethodGenericType<Integer>();
        //范型在方法前面写
         obj.<String>getMan();
    }
}
```





### 接口interface

个人理解，在一些初始代码中，代码执行的范型 就是接口，然后后续不管后面新建了什么class，都会转为接口然后调用对应方法。

因为是父子关系所以不用转，直接就能调用方法。

对有多实现的接口，这样互相不影响，各自用自己的方法。

3.为什么看不懂代码，因为看到的代码都是调用接口的方法，而没有找到对应的实现类，找不到真正的执行原码。



### 接口(新特性)

接口和抽象类的主要区别就是，1 接口可以多继承，类不行   2接口只有抽象方法，抽象类可有实现方法

接口多继承例子，fly接口，usb接口 如果你新的类要具有飞行和连接usb，必须实现上面2个借口



新特性：

接口只能extends 多个其他接口，但是不能implements其他接口

接口可以继承接口，可以继承多个接口，并且接口中可以有实现方法和静态方法

接口不能直接new对象，不过在看一些源码中,有的接口里有一些静态方法可以获得接口的实现对象

例如在flink中的WatermarkStrategy接口，继承了extends TimestampAssignerSupplier, WatermarkGeneratorSupplier

并且很多静态方法中的，返回值就是WatermarkStrategy的实现对象 



### 函数式接口

在 Java 中，函数式接口（Functional Interface）是指只包含一个抽象方法的接口。函数式接口是支持函数式编程的基础，它可以用作 Lambda 表达式的目标类型。

函数式接口具有以下特点：

- 只包含一个抽象方法。
- 可以包含默认方法和静态方法。
- 可以使用 `@FunctionalInterface` 注解进行标记（可选）。

函数式接口的存在使得开发者可以使用 Lambda 表达式来创建简洁、灵活的代码，尤其在处理函数式编程的场景下非常有用。

以下是一个函数式接口的示例：

```java
@FunctionalInterface
interface Calculator {
    int calculate(int a, int b);
}
```

在上述示例中，`Calculator` 是一个函数式接口，它定义了一个抽象方法 `calculate`，该方法接受两个整数参数并返回一个整数结果。

可以使用 Lambda 表达式来实现该函数式接口，例如：

```java
Calculator addition = (a, b) -> a + b;
int result = addition.calculate(2, 3);
System.out.println(result);  // 输出：5
```

在上述代码中，使用 Lambda 表达式实现了 `Calculator` 接口，并将其赋值给 `addition` 变量。Lambda 表达式 `(a, b) -> a + b` 定义了计算两个整数相加的逻辑。通过调用 `calculate` 方法，可以使用 Lambda 表达式进行计算并得到结果。

函数式接口的使用可以使代码更加简洁、易读，并且能够更好地支持函数式编程的思想。



### 抽象类abstract

java的接口可以多实现，但是每次都要重新实现多个接口就很麻烦

抽象类的作用是，实现了多个必要功能的接口，可以理解成模版。

用户再实现abstrcat类，添加自己需要的额外功能等

```java
abstract Class Template implements Inter1,Inter2 {
    void inter1Method(){ println("111")  }
}

//继承 同时实现接口
class Demo extends Template  implements Inter3
```

### 多态

主要应用就是一些方法中定义数据类型是父类,可以接受子类

### enum枚举类场景

状态码

这样看枚举直接能看到不同状态码对应的错误信息，，不然你找不到哪些码对应哪些信息，如果不用枚举，你只能写注释或者文档。

```java
public class EnumTest {
    public static void main(String[] args) {
        ErrorCodeEnum errorCode = ErrorCodeEnum.SUCCESS;
        System.out.println("状态码：" + errorCode.code() + 
                           " 状态信息：" + errorCode.msg());
    }
}
enum ErrorCodeEnum {
    SUCCESS(1000, "success"),
    PARAM_ERROR(1001, "parameter error"),
    SYS_ERROR(1003, "system error"),
    NAMESPACE_NOT_FOUND(2001, "namespace not found"),
    NODE_NOT_EXIST(3002, "node not exist"),
    NODE_ALREADY_EXIST(3003, "node already exist"),
    UNKNOWN_ERROR(9999, "unknown error");
 
    private int code;
    private String msg;
 
    ErrorCodeEnum(int code, String msg) {
        this.code = code;
        this.msg = msg;
    }
 
    public int code() {
        return code;
    }
 
    public String msg() {
        return msg;
    }
 
  	//ErrorCodeEnum.values() 获取枚举类中所有枚举实例
    public static ErrorCodeEnum getErrorCode(int code) {
        for (ErrorCodeEnum it : ErrorCodeEnum.values()) {
            if (it.code() == code) {
                return it;
            }
        }
        return UNKNOWN_ERROR;
    }
}
```

代码可变化性

这里代码写死了，使用"BLUE"去做判断条件，但是如果后续有改动把COLOR_BLUE枚举类的值改成别的了，那么后续产生的数据，传给color，这里代码就过不了，这里应该用枚举来做判断条件。

对于有的判断条件，比如产品说消费多少评价为高等会员，给一个优惠，这种值要用枚举，不能固定写死。如果多处代码都用到这个值，你只能去找出来一个个改。

```java
public class EnumTest {
    public static final String COLOR_RED = "RED";
    public static final String COLOR_BLUE = "BLUE";
    public static final String COLOR_GREEN = "GREEN";
    public static void main(String[] args) {
        String color = "BLUE";
        if ("BLUE".equals(color)) {
            System.out.println("蓝色");
        }
    }

```

枚举实现单例

因为枚举只会在类加载时装载一次，所以它是线程安全的，这也是《Effective Java》作者极力推荐使用枚举来实现单例的主要原因

```java
public class Singleton {
    // 枚举类型是线程安全的，并且只会装载一次
    private enum SingletonEnum {
        INSTANCE;
        // 声明单例对象
        private final Singleton instance;
        // 实例化
        SingletonEnum() {
            instance = new Singleton();
        }
        private Singleton getInstance() {
            return instance;
        }
    }
    // 获取实例（单例对象）
    public static Singleton getInstance() {
        return SingletonEnum.INSTANCE.getInstance();
    }
    private Singleton() {
    }
    // 类方法
    public void sayHi() {
        System.out.println("Hi,Java.");
    }
}
class SingletonTest {
    public static void main(String[] args) {
        Singleton singleton = Singleton.getInstance();
        singleton.sayHi();
    }
}
```





### 异常捕获的使用场景

1. 数据库操作：在进行数据库操作时，可能会出现连接超时、SQL语句错误等异常情况，需要进行异常捕获和处理。
2. 网络通信：在进行网络通信时，可能会出现连接超时、网络中断等异常情况，需要进行异常捕获和处理。
3. 文件操作：在进行文件读写操作时，可能会出现文件不存在、文件格式错误等异常情况，需要进行异常捕获和处理。
4. 外部接口调用：在进行外部接口调用时，可能会出现接口返回数据格式错误、接口连接超时等异常情况，需要进行异常捕获和处理。
5. 系统运行时：在系统运行时，可能会出现内存溢出、线程死锁等异常情况，需要进行异常捕获和处理。
6. 其他需要保证程序稳定性的地方：例如定时任务、消息队列等。

代码中总有数据库中读取的数据，然后你转化为array的，当你去读取然后取执行方法时，可能array中是空的，所以这时候应该执行try,catch 出现了空指针异常，执行处理，而不是让程序终止。

常见的类似需要try catch的，空指针，文件读取不存在，数据角标越界

抓到异常后，用log把异常写入错误日志，不影响后续任务





### 泛型擦除

```java
List arrayList = new ArrayList();
arrayList.add("abc");
arrayList.add(12);

for(int i = 0; i< arrayList.size();i++){
	String item = (String)arrayList.get(i);
	System.out.println(item);
}

```

会报错：Exception in thread "main" java.lang.ClassCastException: java.lang.Integer cannot be cast to java.lang.String

之前版本没有范型容易出这种问题

```java
List<String> arrayList = new ArrayList<String>();
//arrayList.add(100); 在编译阶段，编译器提示错误

```

有了范型之后，在编译时就能发现错误

```java
List<String> stringArrayList = new ArrayList<String>();
List<Integer> integerArrayList = new ArrayList<Integer>();

Class classStringArrayList = stringArrayList.getClass();
Class classIntegerArrayList = integerArrayList.getClass();

 //结果为true表明实际上范型对于真正运行没有影响只有，编译用
System.out.println(classStringArrayList==classIntegerArrayList);
```

通过上面的例子可以证明，在编译之后程序会采取去泛型化的措施。也就是说Java中的泛型，只在编译阶段有效。

在编译过程中，正确检验泛型结果后，在运行时会将泛型的相关信息擦出，编译器只会在对象进入JVM和离开JVM的边界处添加类型检查和转换的方法，泛型的信息不会进入到运行时阶段，这就是所谓的Java类型擦除。
它们也分别俗称“假”泛型和“真”泛型。导致程序在运行时对泛型类型没有感知，所以上述例子一的代码反编译后只剩下了List，实际上都是Class<? extends ArrayList>的比较，导致例2输出的true。

为什么Java要采用Code sharing机制进行类型擦除呢？有两点原因：一是Java泛型是到1.5版本才出现的特性，在此之前JVM已经在无泛型的条件下经历了较长时间的发展，如果采用Code specialization，就得对JVM的类型系统做伤筋动骨的改动，并且无法保证向前兼容性。二是Code specialization对每个泛型类型都生成不同的目标代码，如果有10个不同泛型的List，就要生成10份字节码，造成代码膨胀。



```java
StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

DataStream<String> dataStream = env.fromCollection(Arrays.asList("hello", "world", "flink", "hello", "flink"));
DataStream<Tuple2<String, Integer>> mapDataStream = dataStream.map(word -> new Tuple2<>(word, 1));
mapDataStream.print();
env.execute();
```

报错lamda范型无法识别

为什么使用lambda表达式，JVM就无法自动检测出Tuple2中的参数类型，而匿名内部类却可以？

Tuple2中是有两个泛型的，使用匿名内部类时，会被真正编译为class文件，在对象进入JVM和离开JVM的边界处进行类型的检查和转换，从而保证Tuple2的参数类型能够正确的被检测出来。这种方式其实是静态语言的特性。

而Lambda表达式是在运行时调用invokedynamic指令，用以支持动态语言的方法调用。具体来说，它将调用点（CallSite）抽象成一个 Java 类，并且将原本由 Java 虚拟机控制的方法调用以及方法链接暴露给了应用程序。在运行过程中，每一条 invokedynamic 指令将捆绑一个调用点，并且会调用该调用点所链接的方法句柄。在第一次执行 invokedynamic 指令时，Java 虚拟机会调用该指令所对应的启动方法（BootStrap Method），来生成前面提到的调用点，并且将之绑定至该 invokedynamic 指令中。在之后的运行过程中，Java 虚拟机则会直接调用绑定的调用点所链接的方法句柄。亦即在第一次执行其逻辑时才会确定。但是，对象进入JVM后，就会进行类型擦除，导致没有足够的信息检测出Tuple2中两个泛型的具体类型。



为了克服类型擦除带来的问题，Flink类型系统中提供了类型暗示（type hint）机制。在map之后调用returns方法，就可以指定返回类型了。







### java8新特性Optional

视频：https://www.bilibili.com/video/BV1dc411X7nW

在部分场景代替null判断

感觉和is null判断代码量差不多，什么场景用optinal,多次调用对象的方法时,就有没问题

好像说时链式调用,

比如User里有很多数据需要校验，校验id，名字，商家,需要调用多次User.get方法，不然每次都要用null校验

### 设计模式应用场景

**单例模式    工厂模式   观察者模式 **

饿汉

适用于项目中频繁获取对象的场景，例如：获取缓存对象、获取一些工具类对象等等，由于这些对象使用频率较高，所以在获取对象时，我们使用单例模式指定获取一个对象，不然每次使用就new 1次

```java

public class SignletonHungry {
 
    //1. 私有的静态的最终的对象
    private static final SignletonHungry singl=new SignletonHungry();
 
    //2. 私有的无参构造函数
    private SignletonHungry(){
 
    }
 
    //3. 公共的静态的实例方法
    public static SignletonHungry getInstance(){
        return singl;
    }
 
    //测试方法
    public static void main(String[] args) {
        //利用for循环 模拟多线程环境调用
        for (int i = 0; i < 100; i++) {
            new Thread(()->{
                //看每次获取对象的hashcode是否一致 判断是否获取了同一个对象
                System.out.println("获取的hashCode是： "+SignletonHungry.getInstance().hashCode());
            }).start();
        }
    }
}
```

**优点：**这种写法比较简单，就是在类装载的时候就完成实例化，避免了线程同步问题。

**缺点：**但是因为在指定对象时就进行初始化，在类比较大的时候，也会造成一定的资源消耗。

懒汉

比饿汉节省空间，只有用到了才会创建，但是有线程安全问题，

懒汉模式在多线程并发获取单例类时，存在现场安全的问题，那么既然存在线程安全问题，我们怎么去改善这个问题呢？请看[线程锁](https://so.csdn.net/so/search?q=线程锁&spm=1001.2101.3001.7020)模式。

```java
public class SignletonFull {
 
    //1. 私有的静态的对象 先不new 默认为null值
    private static SignletonFull signletonFull;
 
    //2. 私有的无参构造器
    private SignletonFull(){}
 
    //3. 公共的静态的方法
    public static SignletonFull getInstance() throws InterruptedException {
        if(signletonFull==null){
            Thread.sleep(1000);
            signletonFull=new SignletonFull();
        }
        return signletonFull;
    }
 
}
```

其他模式

还有线程锁模式，双重判断模式，静态内部类模式，先不学

**工厂模式**

应用场景：有时候创建一个对象需要很多逻辑判断，比如获取一个解析器，有json解析器，xml解析器，需要if,else来判断文件格式来获取解析器，这样代码看上去不简洁，并且如果要是有新的解析类型那么，需要在所有这段代码里都要添加一个新的if-else，不符合对拓展开放的原则，这时候可以用工厂模式

```java
//获取解析器接口
public interface ITypeParser {
    void parse(String text);
}

//json解析器
public class JsonTypeParser implements ITypeParser {
    @Override
    public void parse(String text) {
        System.out.println("jsonParser");
    }
}

//xml解析器
public class XmlTypeParser implements ITypeParser {
    @Override
    public void parse(String text) {
        System.out.println("xmlParser");
    }
}


//如果不用工厂模式，获取解析器需要这样
public void test1(){
    String fileExtension = "json"
    ITypeParser parser = null;
    if("json".equalsIgnoreCase(fileExtension)){
        parser = new JsonTypeParser();
    }else if("xml".equalsIgnoreCase(fileExtension)){
        parser = new XmlTypeParser();
    }
}

//工厂模式 获取解析器的在执行代码上更简洁，并且增加新的解析，只需要修改工厂的代码，不需要修改执行代码
public class TypeParserFactory {
    private static final Map<String, ITypeParser> cacheParsers = new HashMap<>();

    static {
        cacheParsers.put("json",new JsonTypeParser());
        cacheParsers.put("xml",new XmlTypeParser());
    }

    public static ITypeParser getTypeParser(String fileExtension){
        return cacheParsers.get(fileExtension);
    }
}

```

**观察者模式**

　　观察者模式，又叫做通知模式，是一种一对多的模式，因此观察者模式也叫做发布订阅模式。

　　在软件开发中，比如我们的产品有这样一个功能，用户下单支付成功之后，就会发送一条短信通知用户，如果之后希望不仅发送短信，还需要发送邮件，还需要语音通知，在这样的情况下，我们就可以采用观察者模式，我们将支付成功信息放入到消息队列中，至于发短信还是发邮件，由各个业务模块订阅消息队列自己处理。这样在订单模块里面，就不需要一个个通知短信模块，邮件模块了。

# java高级

### int与Integer

```sql
#案例
java中int 和Inteter声明的变量有什么区别？为什么int a = 12345678; int b =12345678; a==b返回的是true ,
而Integer c ,Integer d ,当c与d相同且小于100时为true，c与d相同且大于1000时，返回false

"原因如下:"
#基本数据类型int
对于基本数据类型int，在Java中并不会创建对象，也不存在计算机底层存储变量值的地址。基本数据类型是直接存储在内存中的，它们的值直接存储在变量所分配的内存空间中。
当你声明一个int类型的变量，例如int a = 123456;，Java会在内存中为变量a分配足够的空间来存储整数值123456。这个空间的大小是固定的，通常是4个字节（32位），用于存储整数值的二进制表示,基本数据类型的==比较的是值

#引用数据类型Integer
而对于Integer对象，使用==运算符比较的是对象的引用（内存地址），而不是对象的值。当两个Integer对象通过自动装箱或new关键字创建时，它们可能会引用不同的内存地址，即使它们的值相同。在Java中，对于小于等于127和大于等于-128的整数，会使用对象池（object pool）来缓存Integer对象，以提高性能。因此，当比较小于等于127的整数时，Integer c和Integer d可能引用相同的对象，所以c == d返回true。但是，对于大于127的整数，不会使用对象池，每次创建都会生成新的对象，所以c == d返回false。

#结论
基本数据类型的==比较的是值,  而对象比较的是地址
```



**注意"9".equals(9)是不等的**

一般用于同类型比较，如果String和int标记是不同的



### 注解/自定义@value

##### 注解分类

在Java中，有以下几种类型的注解：

1. **元注解（Meta-Annotations）**：元注解是用来注解其他注解的注解。Java提供了几种元注解，用于对自定义注解进行定义和限制。例如：
   - `@Retention`：指定注解的保留策略，包括`RetentionPolicy.SOURCE`、`RetentionPolicy.CLASS`和`RetentionPolicy.RUNTIME`。
   - `@Target`：指定注解可以应用的目标元素类型，包括`ElementType.TYPE`、`ElementType.FIELD`、`ElementType.METHOD`等。
   - `@Documented`：指定注解是否会包含在Java文档中。
   - `@Inherited`：指定注解是否可以被继承。
2. **标准注解（Standard Annotations）**：这些注解是Java提供的一些预定义注解，用于特定的用途。例如：
   - `@Override`：用于标识方法覆盖父类中的方法。
   - `@Deprecated`：用于标识已过时的方法或类。
   - `@SuppressWarnings`：用于抑制编译器警告。
3. **自定义注解（Custom Annotations）**：自定义注解是开发者根据需求自定义的注解。通过使用`@interface`关键字来定义注解。自定义注解可以用于各种用途，例如：
   - 标记注解：用于标记特定的类、方法或字段。
   - 配置注解：用于配置某个类或方法的行为。
   - 运行时处理注解：用于在运行时通过反射获取注解信息并进行相应的处理。

自定义注解可以通过反射机制获取注解信息，并根据注解信息进行相应的处理。例如，可以使用自定义注解来实现以下功能：

- 在代码中标记某个类或方法，以便其他程序或工具可以根据注解信息进行处理。
- 在运行时通过反射获取注解信息，并根据注解信息执行特定的逻辑。
- 通过自定义注解配置某个类或方法的行为，例如指定某个方法的执行顺序、超时时间等。
- 自动生成文档或代码，根据注解信息生成相关的文档或代码。

需要注意的是，注解本身并不会改变程序的逻辑，而是提供了一种机制来在代码中添加元数据，以便其他程序或工具可以根据注解信息进行处理。



类注解、方法注解和属性注解都是自定义注解的应用场景，它们可以用来实现不同的功能。

1. **类注解（Class Annotations）**：类注解是应用于类上的注解，可以用来对整个类进行标记、配置或运行时处理。一些常见的用途包括：
   - 标记注解：用于标记特定类型的类，以便其他程序或工具可以根据注解信息进行处理。
   - 配置注解：用于配置整个类的行为，例如指定类的访问权限、作用域等。
   - 运行时处理注解：用于在运行时通过反射获取类注解信息，并执行相应的逻辑，例如根据注解信息生成相关的代码或执行特定的操作。

2. **方法注解（Method Annotations）**：方法注解是应用于方法上的注解，可以用来对方法进行标记、配置或运行时处理。一些常见的用途包括：
   - 标记注解：用于标记特定的方法，以便其他程序或工具可以根据注解信息进行处理。
   - 配置注解：用于配置方法的行为，例如指定方法的访问权限、异常处理等。
   - 运行时处理注解：用于在运行时通过反射获取方法注解信息，并执行相应的逻辑，例如根据注解信息生成相关的代码或执行特定的操作。

3. **属性注解（Field Annotations）**：属性注解是应用于类的字段（属性）上的注解，可以用来对字段进行标记、配置或运行时处理。一些常见的用途包括：
   - 标记注解：用于标记特定的字段，以便其他程序或工具可以根据注解信息进行处理。
   - 配置注解：用于配置字段的行为，例如指定字段的访问权限、默认值等。
   - 运行时处理注解：用于在运行时通过反射获取字段注解信息，并执行相应的逻辑，例如根据注解信息生成相关的代码或执行特定的操作。

需要注意的是，注解本身并不会改变程序的逻辑，而是提供了一种机制来在代码中添加元数据，以便其他程序或工具可以根据注解信息进行处理。具体的功能和用途取决于开发者根据需求自定义注解的定义和处理逻辑。

##### 类注解

```
啊啊啊
```



##### 变量注解

idea中注解被哪些方法调用了,要点击useage查看，control+H看不到

注解案例

```java
//注解分为几种功能,编译时，运行时。想spring中的@value就是运行时，读取配置文件赋值给变量
//注意@Value注解只能赋给类属性,不能在方法里使用
class A {
  //只能是属性，不用用在方法中给变量
   @Value("url")
   String path ;
}
```



注解用途

```sql
#@override注解
如果子类方法没有覆盖超类的方法，那么编译的时候能检验出来。

#@Deprecated
用于表示被标记的数据已经过时，不建议使用。
可以用于修饰 属性、方法、构造、类、包、局部变量、参数。
它会被编译器程序读取。

在 Java 里注解有许多用途，可以归纳为三类：
#编译检查：
通过代码里标识的元数据让编译器能实现基本的编译检查，编译器可以使用注解来检测错误或抑制警告。
#编译时和部署时的处理：
程序可以处理注解信息以生成代码，XML 文件等。
#运行时处理：
可以在运行时检查某些注解并处理。

程序员多多少少都曾经历过被各种配置文件（xml、properties）支配的恐惧。过多的配置文件会使得项目难以维护。使用注解可以减少配置文件或代码，是注解最大的用处，现在 Spring 家族的 SpringBoot 就是靠注解维护各种 Bean 组件的，让开发中者不再用XML指定各种Java Bean 的路径、名称等属性，减少了不少项目配置的步骤，从而让Java项目的开发提速了不少
```



自定义@Value,代码注释在项目里

##### 方法注解

自定义注解修饰方法可以为方法添加各种功能，具体功能取决于你在注解的定义和处理逻辑中实现的内容。以下是一些常见的功能示例：
验证和校验：你可以使用注解来验证方法的参数或返回值是否符合特定的规则或约束条件。例如，你可以定义一个注解来标记需要进行参数校验的方法，并在方法执行前进行参数的合法性检查。
日志记录：通过注解，你可以在方法的执行前、执行后或异常发生时记录日志信息。这样可以方便地在不同的方法中添加日志记录功能，而无需在每个方法中手动编写日志代码。
性能监控：你可以使用注解来衡量方法的执行时间、资源消耗等指标，以便进行性能监控和优化。通过在方法执行前后记录时间戳，你可以计算方法的执行时间，并在需要时进行性能分析。
事务管理：使用注解可以简化方法的事务管理。你可以定义一个注解来标记需要在事务中执行的方法，并在注解处理逻辑中实现事务的开启、提交或回滚操作。
缓存管理：通过注解，你可以为方法添加缓存管理功能。你可以定义一个注解来标记需要进行缓存的方法，并在注解处理逻辑中实现缓存的读取和更新逻辑，从而提高方法的执行效率。
这些只是一些示例，你可以根据自己的需求和场景来定义和实现注解的功能。注解的灵活性和扩展性使得它可以成为方法增加各种功能的有力工具。



##### 全局异常注解

在Java中，可以使用@ControllerAdvice和@ExceptionHandler注解来处理全局异常，从而避免因为某个接口代码逻辑问题导致整个服务器停止的情况。
首先，你可以创建一个类，并使用@ControllerAdvice注解标记该类，表示它是一个全局异常处理类。然后，在该类中，你可以定义一个或多个方法，并使用@ExceptionHandler注解来指定处理特定异常的方法。
下面是一个简单的示例：
@ControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(Exception.class)
    public ResponseEntity<String> handleException(Exception e) {
        // 处理异常的逻辑
        // 返回适当的响应，可以是自定义的错误信息或其他处理方式
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Internal Server Error");
    }
}
在上述示例中，handleException方法使用@ExceptionHandler注解来处理Exception类型的异常。当某个接口代码逻辑出现异常时，该方法会被调用，并返回一个适当的响应。
通过使用@ControllerAdvice和@ExceptionHandler注解，你可以在全局范围内统一处理异常，而不需要在每个接口的代码中编写繁琐的try-catch块。这样即使某个接口发生异常，也不会导致整个服务器停止。









### 多线程

执行java程序会有多个线程，main是其中1个，注意多核之间可以共享内存，多线程可以被多核执行

```sql
#Attach Listener
Attach Listener 线程的主要工作是串流程，流程步骤包括：接收客户端命令、解析命令、查找命令执行器、执行命令等。
#Signal Dispatcher
Signal Dispatcher线程负责将Attach Listener 线程接收的命令分发到各个不同的模块处理，并且返回处理结果。
#Finalizer
Finalizer线程主要处理JVM垃圾回收。
#Reference Handler
ReferenceHandler线程的主要功能是处理pending链表中的引用对象，也是协助JVM进行gc操作。
#main
主线程，也就是负责执行main方法中的代码
可以看出，除了main线程之外，其他线程都是jvm创建的守护线程，保证了java程序的正确运行。
```

##### 多线程效率原因

```sql
1 单核变多核
2 利用了io或者网络通讯的等待时间做别的
```

```java
如果您希望完全自己编写一个类似于Spring Boot中的@Value注解的功能，而不依赖于Spring框架或其他第三方库，可以按照以下步骤进行操作：
创建一个自定义注解，比如@CustomValue：
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

@Target({ElementType.FIELD, ElementType.METHOD, ElementType.PARAMETER})
@Retention(RetentionPolicy.RUNTIME)
public @interface CustomValue {
    String value();
}

---------------------------------------------------------------------------
  
  创建一个配置类，用于加载配置文件并提供获取属性值的方法：
import java.io.FileInputStream;
import java.io.IOException;
import java.util.Properties;

public class CustomProperties {
    private Properties properties;

    public CustomProperties(String filePath) {
        properties = new Properties();
        try {
            FileInputStream fis = new FileInputStream(filePath);
            properties.load(fis);
            fis.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
    public String getProperty(String key) {
        return properties.getProperty(key);
    }
}
---------------------------------------------------------------------------
在上述代码中，我们使用Properties类加载配置文件，并提供了一个getProperty方法用于获取属性值。
创建一个注解处理器，用于解析注解并读取配置文件中的值：
import java.lang.reflect.Field;

public class CustomValueProcessor {
    private CustomProperties customProperties;

    public CustomValueProcessor(String filePath) {
        customProperties = new CustomProperties(filePath);
    }

    public void process(Object obj) {
        Class<?> clazz = obj.getClass();
        for (Field field : clazz.getDeclaredFields()) {
            CustomValue customValueAnnotation = field.getAnnotation(CustomValue.class);
            if (customValueAnnotation != null) {
                String propertyName = customValueAnnotation.value();
                String propertyValue = customProperties.getProperty(propertyName);
                if (propertyValue != null) {
                    field.setAccessible(true);
                    try {
                        field.set(obj, propertyValue);
                    } catch (IllegalAccessException e) {
                        e.printStackTrace();

---------------------------------------------------------------------------
在上述代码中，我们使用反射来获取字段，并通过自定义的CustomProperties类获取配置文件中的属性值，然后将其设置到相应的字段中。
在您的应用程序中使用自定义注解：
public class MyApp {
    @CustomValue("custom.property.key")
    private String customPropertyValue;

    public void init() {
        CustomValueProcessor processor = new CustomValueProcessor("custom.properties");
        processor.process(this);

        System.out.println(customPropertyValue);
    }

    // ...
}
在上述代码中，我们创建了一个MyApp类，并在字段上使用了自定义的@CustomValue注解。然后在init方法中，我们创建了一个CustomValueProcessor对象，并调用process方法来处理注解并读取配置文件中的属性值。
需要注意的
```



##### 使用场景

```sql
#计算密集型：(原本只有main线程，现在变成多个核同时执行)
当任务需要大量的计算和处理，而不涉及太多的IO操作时，多线程可以充分利用多核处理器的计算能力，将任务分解为多个子任务并并行执行，从而加快整体执行速度。图像处理、视频编码、科学计算等都可以通过多线程实现并行计算
#IO密集型任务
当任务涉及大量的IO操作（如文件读写、网络通信等）时，使用多线程可以充分利用CPU的空闲时间，提高任务的执行效率。例如，网络爬虫、文件下载、数据导入导出等任务可以通过多线程实现高效的IO操作。
#服务器应用程序
在服务器应用程序中，多线程可以处理多个并发请求，提高系统的吞吐量和响应速度。每个请求可以由一个独立的线程处理，避免阻塞主线程。例如，Web服务器、数据库服务器等都可以使用多线程来处理客户端请求。
#异步编程：
多线程可以用于实现异步编程模型，提高系统的并发性和响应性。通过使用多线程，可以在等待某个操作完成的同时，继续执行其他任务，从而提高系统的效率。例如，在Java中，可以使用CompletableFuture、ExecutorService等来实现异步编程。
#需要注意的是
在使用多线程时，需要注意线程安全性、资源竞争、线程间的通信等问题。合理地设计和管理多线程，使用合适的同步机制和线程池
```

##### 案例

```sql
#多线程使用具体看瓶颈在哪
如果是网络借口调用上响应时间慢，那么可以开多线程。
比如读取一个文件10w条数据，每50条数据调一次网络接口发送过去,每次接口响应时间是100ms，这里明显是文件读取速度远大于，网络接口调用的。可以开多线程来弄，不过要确保:多线程读取的文件系统数据不会丢或者重复的问题。

原型是读取文件，文件要加载到内存用一个数组存起来。问题本质就是多线程对集合读取问题。
```

### 定位oom

连接: https://www.bilibili.com/video/BV1Wu4y1c7N5/?spm_id_from=333.1007.tianma.1-1-1.click&vd_source=dc2f0659a9d317ea4b839219ee320ab7

```sql
"oom出现原因"

#1.申请对象太多
比如去mysql申请了全部数据，放入list中。

#2.忘记释放的对象
connecttion忘记close，每次查询都去创建了个connection。最好用连接池技术，这样不会出现这个问题，满了就会堵塞

#3.本身分配的堆内存不合理
内存分少了,jmap -heap查看堆内存分配情况

#4.堆外内存oom怎么处理呢？？？？？？

"定位OOM代码位置" 

#挂了的定位
提前设置 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath = 
含义，当出现堆溢出时，将溢出报错放到指定目录.但是这个很占磁盘空间，记录每一个对象创建，生成的文件很大

#没挂了的定位

# ？？问：分布式系统这种怎没定位呢
```









# 

