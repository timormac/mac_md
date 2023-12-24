

# 问题记录

### resource文件不生效

因为xml名字弄错了，应该是log4j2.xml ，我新建的是log4j.xml



# 平时使用

### 异常日志捕获

出现异常导致logger.error()`这一步处理方式如下

```sql
#监控日志程序报警
**监控和告警系统**：在生产环境中，通常会有专门的监控系统，比如ELK（Elasticsearch, Logstash, Kibana），Prometheus加Grafana，或者其他商业监控工具，它们可以监控应用程序的健康状况，并在出现异常时发送告警。

#手动try-catc
在自己能想到的地方执行try catch处理，以便遇到单个异常数据,程序能正常运行。
例如：对于一个异常的订单号,try caatch后，返回一个404。如果用下面的全局处理。只能记录日志错误，但是程序还是挂了

#全局异常处理器
可以设置一个全局的未捕获异常处理器（UncaughtExceptionHandler），它会捕获线程中未被捕获的异常。可以在这个处理器中记录日志。
Thread.setDefaultUncaughtExceptionHandler(new Thread.UncaughtExceptionHandler() {
    public void uncaughtException(Thread t, Throwable e) {
        logger.error("线程 " + t + " 发生未捕获的异常：", e);
    }
})

#框架的AOP处理
**AOP（面向切面编程）**：如果你使用的是Spring框架或者其他支持AOP的框架，可以通过AOP来统一处理异常。通过在方法执行前后添加切面，可以捕获并记录异常，即便这个异常没有在方法内部被捕获
    @AfterThrowing(pointcut = "execution(* com.yourpackage..*(..))", throwing = "e")
    public void logAfterThrowingAllMethods(Exception e) throws Throwable {
        logger.error("异常：", e);
}
```



全局异常抓取返回默认

```
在Java的后端开发中，可以使用`@ExceptionHandler`注解来处理全局异常。这个注解可以用于方法上，用于捕获在方法内任意地方发生的异常，并提供一个默认的返回值或者进行其他处理，从而避免整个服务器因为一个异常而崩溃。

要使用`@ExceptionHandler`注解，你需要在你的后端框架中进行配置。下面是一个使用Spring Boot框架的示例：
@ControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(Exception.class)
    @ResponseBody
    public ResponseEntity<String> handleException(Exception e) {
        // 处理异常的逻辑，可以返回默认的返回值或者进行其他处理
        String errorMessage = "发生异常：" + e.getMessage();
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorMessage);
    }
}

在上面的例子中，`@ControllerAdvice`注解表示这是一个全局异常处理器，`@ExceptionHandler(Exception.class)`表示处理所有类型的异常。你可以根据需要选择处理特定的异常类型。`@ResponseBody`注解表示返回的是一个响应体，`ResponseEntity`用于封装响应的状态码和内容。

通过编写类似上面的全局异常处理器，你可以在方法内任意地方发生异常时进行捕获，并返回一个默认的响应，从而保证整个服务器不会因为一个异常而崩溃。
```



### log4j2+slf4j

平时使用就是用log4j2加sfl4j就行，这个只用引入一个依赖，配置文件只有一个

##### 代码

```java
public class Log4j2Demo {
 //这里注册类名，打印时日志里会打印类名和调用的方法名字,便于排查
private static final Logger logger = LogManager.getLogger(Log4j2Demo.class);
public static void main(String[] args) {
    logger.trace("Trace level message");
    logger.debug("Debug level message");
    logger.info("Info level message");
    logger.warn("Warn level message");
    logger.error("Error level message");
    logger.fatal("Fatal level message");
}

```

##### 日志样式

```sql
#日期   调用方法	日志等级	类名	具体日志信息
2023-12-08 15:11:00 [main] INFO  com.lpc.realtime.warehouse.Log4j2Demo -  message
```

##### pom依赖

```xml
     <dependency>
            <groupId>org.apache.logging.log4j</groupId>
            <artifactId>log4j-slf4j-impl</artifactId>
            <version>2.12.0</version>
        </dependency>
```

##### 文件配置

log4j2配slf4j，只需要配置log4j2.xml文件即可以

```xml
在log4j2配置文件中，你可以使用`<Logger>`元素来指定不同级别的日志输出路径。下面是一个示例配置文件，展示了如何指定info级别和error级别的日志输出路径：

<?xml version="1.0" encoding="UTF-8"?>
<Configuration status="INFO">
    <Properties>
        <Property name="logPath">/path/to/logs</Property>
    </Properties>
    <Appenders>
        <RollingFile name="infoAppender" fileName="${logPath}/info.log"
                     filePattern="${logPath}/info-%d{MM-dd-yyyy}.log.gz">
            <ThresholdFilter level="info" onMatch="ACCEPT" onMismatch="DENY"/>
            <PatternLayout>
                <Pattern>%d{yyyy-MM-dd HH:mm:ss} [%t] %-5level %logger{36} - %msg%n</Pattern>
            </PatternLayout>
            <Policies>
                <TimeBasedTriggeringPolicy interval="1" modulate="true"/>
            </Policies>
        </RollingFile>
        
        <RollingFile name="errorAppender" fileName="${logPath}/error.log"
                     filePattern="${logPath}/error-%d{MM-dd-yyyy}.log.gz">
            <ThresholdFilter level="error" onMatch="ACCEPT" onMismatch="DENY"/>
            <PatternLayout>
                <Pattern>%d{yyyy-MM-dd HH:mm:ss} [%t] %-5level %logger{36} - %msg%n</Pattern>
            </PatternLayout>
            <Policies>
                <TimeBasedTriggeringPolicy interval="1" modulate="true"/>
            </Policies>
        </RollingFile>
    </Appenders>
    <Loggers>
        <Root level="info">
            <AppenderRef ref="infoAppender"/>
            <AppenderRef ref="errorAppender"/>
        </Root>
    </Loggers>
</Configuration>


在上面的配置文件中，定义了两个Appender：`infoAppender`和`errorAppender`，分别用于处理info级别和error级别的日志。

在每个Appender中，使用`<ThresholdFilter>`元素来指定日志级别。`level`属性设置了过滤的级别，这里分别是`info`和`error`。`onMatch`属性设置了匹配级别的处理方式，这里是`ACCEPT`，表示接受该级别的日志。`onMismatch`属性设置了不匹配级别的处理方式，这里是`DENY`，表示拒绝该级别的日志。

同时，每个Appender的`fileName`和`filePattern`属性指定了日志的输出路径和格式。你可以根据需要进行调整。

在`<Root>`元素中，通过`<AppenderRef>`将对应级别的日志输出到相应的Appender中。

请注意，这只是一个简单的示例配置文件，你可以根据实际需求进行更多的配置和调整。同时，确保在项目中正确引入log4j2和slf4j的相关依赖，并将配置文件放
```









# log4j版本迭代

### log4j/log4j2/logback/slf4j

log4j是最开始的java日志框架，在2012年就已经不维护了

logback 是改进后的log4j ,性能优于log4j

log4j2 也是改进后的log4j，性能优于logback

slf4j 是日志整合框架，统一由slf4j获取日志信息,然后转发给具体你想要的日志框架(比如logback)实现

所以你想用slf4j管理日志框架，需要导入slf4j和你需要的日志框架



### log4j(单独)

log4j没有实现slf4j统一接口，所以log4j的jar包只有自己

pom

```xml
<dependencies>
        <dependency>
            <groupId>log4j</groupId>
            <artifactId>log4j</artifactId>
            <version>1.2.17</version>
        </dependency>
</dependencies>
```

代码

```java
import org.apache.log4j.Logger;

public class Log4jDemo {
    // 这里的Logger的类是引用的是: org.apache.log4j.Logger. 也就是具体的log实现框架.
    private static final Logger logger = Logger.getLogger(Log4jDemo.class);

    public static void main(String[] args) {

        logger.trace("Trace message.");
        logger.debug("Debug message.");
        logger.info("Info message.");
        logger.warn("Warn message.");
        logger.error("Error message.");
        logger.fatal("Fatal message.");
    }
}
```



### log4j2(单独)

log4j2的groupId和log4j不同，不过名字都叫log4j不带2 ，log4j2没有实现slf4j的统一接口，所以maven包只有自己

pom

```xml
<dependencies>
    <dependency>
        <groupId>org.apache.logging.log4j</groupId>
        <artifactId>log4j-api</artifactId>
        <version>2.14.0</version>
    </dependency>
    <dependency>
        <groupId>org.apache.logging.log4j</groupId>
        <artifactId>log4j-core</artifactId>
        <version>2.14.0</version>
    </dependency>
</dependencies>
```

代码

```java
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class Log4j2Demo {
// ERROR StatusLogger Log4j2 could not find a logging implementation. Please add log4j-core to the classpath. Using SimpleLogger to log to the console...
// 注意这里的Logger是引用的是 log4j-api中定义的api接口.
// 此时如果没有同时引入实现包: log4j-core , 就会报这里第一行注释说明的问题. 
private static final Logger logger = LogManager.getLogger(Log4j2Demo.class);
  public static void main(String[] args) {
      logger.trace("Trace level message");
      logger.debug("Debug level message");
      logger.info("Info level message");
      logger.warn("Warn level message----");
      logger.error("Error level message----");
      logger.fatal("Fatal level message---");
  }
}

```



### logback配slf4j

logback-classic是一个实现slf4j接口的集合包，所以导入的maven依赖logback-classic，会引入其他2个jar包：logback-core ，slf4j-api

pom

```xml
<dependencies>
        <!-- Logback Classic模块，包含logback-core模块 -->
        <dependency>
            <groupId>ch.qos.logback</groupId>
            <artifactId>logback-classic</artifactId>
            <version>1.2.3</version>
        </dependency>
    </dependencies>
```

代码

```java
import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.LoggerContext;
import org.slf4j.LoggerFactory;

public class LogbackSingleDemo {
    public static void main(String[] args) {

    // 这个 demo 中使用了 Logback 自带的 Logger 对象，可以通过 LoggerContext 来获取它。
    // 然后，通过 Level 对象设置日志级别，
    // 使用 Logger.debug()、Logger.info()、Logger.warn()、Logger.error() 等方法来输出日志。
    LoggerContext loggerContext = (LoggerContext) LoggerFactory.getILoggerFactory();
    Logger logger = loggerContext.getLogger(LogbackSingleDemo.class);

    logger.setLevel(Level.INFO);

    logger.debug("Debug message");
    logger.info("Info message");
    logger.warn("Warn message");
    logger.error("Error message");
}
}
```



### log4j2配slf4j

log4j2没有适配slf4j，需要使用log4j-slf4j-impl ,这个包是实现了sfl4j接口的，内部依赖了log4j-core,log4j-api,slf4j-api

和logback-classic一样，是一个实现slf4j接口的集合包

pom依赖

```xml
     <dependency>
            <groupId>org.apache.logging.log4j</groupId>
            <artifactId>log4j-slf4j-impl</artifactId>
            <version>2.12.0</version>
        </dependency>
```

代码

```java
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class Log4j2Demo {
private static final Logger logger = LogManager.getLogger(Log4j2Demo.class);
public static void main(String[] args) {
    logger.trace("Trace level message");
    logger.debug("Debug level message");
    logger.info("Info level message");
    logger.warn("Warn level message");
    logger.error("Error level message");
    logger.fatal("Fatal level message");
}
}

```

文件配置

log4j2配slf4j，只需要配置log4j2.xml文件即可以

```xml
在log4j2配置文件中，你可以使用`<Logger>`元素来指定不同级别的日志输出路径。下面是一个示例配置文件，展示了如何指定info级别和error级别的日志输出路径：

<?xml version="1.0" encoding="UTF-8"?>
<Configuration status="INFO">
    <Properties>
        <Property name="logPath">/path/to/logs</Property>
    </Properties>
    <Appenders>
        <RollingFile name="infoAppender" fileName="${logPath}/info.log"
                     filePattern="${logPath}/info-%d{MM-dd-yyyy}.log.gz">
            <ThresholdFilter level="info" onMatch="ACCEPT" onMismatch="DENY"/>
            <PatternLayout>
                <Pattern>%d{yyyy-MM-dd HH:mm:ss} [%t] %-5level %logger{36} - %msg%n</Pattern>
            </PatternLayout>
            <Policies>
                <TimeBasedTriggeringPolicy interval="1" modulate="true"/>
            </Policies>
        </RollingFile>
        
        <RollingFile name="errorAppender" fileName="${logPath}/error.log"
                     filePattern="${logPath}/error-%d{MM-dd-yyyy}.log.gz">
            <ThresholdFilter level="error" onMatch="ACCEPT" onMismatch="DENY"/>
            <PatternLayout>
                <Pattern>%d{yyyy-MM-dd HH:mm:ss} [%t] %-5level %logger{36} - %msg%n</Pattern>
            </PatternLayout>
            <Policies>
                <TimeBasedTriggeringPolicy interval="1" modulate="true"/>
            </Policies>
        </RollingFile>
    </Appenders>
    <Loggers>
        <Root level="info">
            <AppenderRef ref="infoAppender"/>
            <AppenderRef ref="errorAppender"/>
        </Root>
    </Loggers>
</Configuration>


在上面的配置文件中，定义了两个Appender：`infoAppender`和`errorAppender`，分别用于处理info级别和error级别的日志。

在每个Appender中，使用`<ThresholdFilter>`元素来指定日志级别。`level`属性设置了过滤的级别，这里分别是`info`和`error`。`onMatch`属性设置了匹配级别的处理方式，这里是`ACCEPT`，表示接受该级别的日志。`onMismatch`属性设置了不匹配级别的处理方式，这里是`DENY`，表示拒绝该级别的日志。

同时，每个Appender的`fileName`和`filePattern`属性指定了日志的输出路径和格式。你可以根据需要进行调整。

在`<Root>`元素中，通过`<AppenderRef>`将对应级别的日志输出到相应的Appender中。

请注意，这只是一个简单的示例配置文件，你可以根据实际需求进行更多的配置和调整。同时，确保在项目中正确引入log4j2和slf4j的相关依赖，并将配置文件放
```



 

 

### log4j配slf4j

pom 

```xml
<dependencies>
        <!-- 声明一个 slf4j的 API包        -->
        <dependency>
            <groupId>org.slf4j</groupId>
            <artifactId>slf4j-api</artifactId>
            <version>1.7.25</version>
        </dependency>

        <!--   把 slf4j 适配到 log4j的实现   -->
        <dependency>
            <groupId>org.slf4j</groupId>
            <artifactId>slf4j-log4j12</artifactId>
            <version>1.7.30</version>
        </dependency>

        <!--  底层实现使用 log4j 引擎 -->
        <dependency>
            <groupId>log4j</groupId>
            <artifactId>log4j</artifactId>
            <version>1.2.17</version>
        </dependency>
 </dependencies>
```






