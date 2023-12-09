## log4j/log4j2/logback/slf4j

log4j是最开始的java日志框架，在2012年就已经不维护了

logback 是改进后的log4j ,性能优于log4j

log4j2 也是改进后的log4j，性能优于logback

slf4j 是日志整合框架，统一由slf4j获取日志信息,然后转发给具体你想要的日志框架(比如logback)实现

所以你想用slf4j管理日志框架，需要导入slf4j和你需要的日志框架



## log4j(单独)

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



## log4j2(单独)

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



## logback配slf4j

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





## log4j2配slf4j

log4j2没有适配slf4j，需要使用log4j-slf4j-impl ,这个包是实现了sfl4j接口的，内部依赖了log4j-core,log4j-api,slf4j-api

和logback-classic一样，是一个实现slf4j接口的集合包

#### pom依赖

```xml
     <dependency>
            <groupId>org.apache.logging.log4j</groupId>
            <artifactId>log4j-slf4j-impl</artifactId>
            <version>2.12.0</version>
        </dependency>
```

#### 代码

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

#### 文件配置

log4j2配slf4j，只需要配置log4j2.xml文件即可以

chatgpt的写法

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





这个是网上的写法

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Configuration status="error" strict="true" name="XMLConfig">
    <Appenders>
        <!-- 类型名为Console，名称为必须属性 -->
        <Appender type="Console" name="STDOUT">
            <!-- 布局为PatternLayout的方式，
            输出样式为[INFO] [2018-01-22 17:34:01][org.test.Console]I'm here -->
            <Layout type="PatternLayout"
                    pattern="[%p] [%d{yyyy-MM-dd HH:mm:ss}][%c{10}]%m%n" />
        </Appender>

    </Appenders>

    <Loggers>
        <!-- 可加性为false -->
        <Logger name="test" level="info" additivity="false">
            <AppenderRef ref="STDOUT" />
        </Logger>

        <!-- root loggerConfig设置 -->
        <Root level="info">
            <AppenderRef ref="STDOUT" />
        </Root>
    </Loggers>

</Configuration>
```



 

## log4j配slf4j

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



## log4j2配置文件

log4j2的配置文件只需要log4j2.xml就可以

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!--Configuration后面的status，这个用于设置log4j2自身内部的信息输出，可以不设置，当设置成trace时，你会看到log4j2内部各种详细输出-->
<!--monitorInterval：Log4j能够自动检测修改配置 文件和重新配置本身，设置间隔秒数(最小是5秒钟)-->
<configuration monitorInterval="5" status="warn">
    <!--日志级别以及优先级排序: OFF > FATAL > ERROR > WARN > INFO > DEBUG > TRACE > ALL -->


    <!--变量配置-->
    <Properties>
        <!-- 格式化输出：%date表示日期(可缩写成%d，后同)，%thread表示线程名，%-5level：级别从左显示5个字符宽度 %msg：日志消息，%n是换行符-->
        <!-- %logger{36} 表示 Logger 名字最长36个字符 -->
        <property name="LOG_PATTERN" value="%d{yyyy-MM-dd HH:mm:ss,SSS} %highlight{%-5level} [%t] %highlight{%c{1.}.%M(%L)}: %msg%n" />
        <!-- 定义日志存储的路径 -->
        <property name="FILE_PATH" value="log" />
        <!--<property name="FILE_NAME" value="myProject" />-->
    </Properties>

    <!--此节点有三种常见的子节点：Console,RollingFile,File-->
    <appenders>

        <!--console节点用来定义输出到控制台的Appender-->
        <!--target:SYSTEM_OUT或SYSTEM_ERR,一般只设置默认:SYSTEM_OUT-->
        <console name="Console" target="SYSTEM_OUT">
            <!--输出日志的格式,默认为：%m%n,即只输出日志和换行-->
            <PatternLayout pattern="${LOG_PATTERN}"/>
            <!--阈值过滤器，控制台只输出level及其以上级别的信息（onMatch），其他的直接拒绝（onMismatch）-->
            <ThresholdFilter level="info" onMatch="ACCEPT" onMismatch="DENY"/>
        </console>

        <!--        &lt;!&ndash;文件会打印出所有信息，这个log每次运行程序会自动清空，由append属性决定，适合临时测试用&ndash;&gt;-->
        <!--        <File name="Filelog" fileName="${FILE_PATH}/test.log" append="false">-->
        <!--            <PatternLayout pattern="${LOG_PATTERN}"/>-->
        <!--        </File>-->


        <!-- 这个会打印出所有的debug及以下级别的信息，每次大小超过size，则这size大小的日志会自动存入按年份-月份建立的文件夹下面并进行压缩，作为存档-->
        <RollingFile name="RollingFileDebug" fileName="${FILE_PATH}/debug.log" filePattern="${FILE_PATH}/debug/DEBUG-%d{yyyy-MM-dd}_%i.log.gz">
            <!--阈值过滤器，控制台只输出level及其以上级别的信息（onMatch），其他的直接拒绝（onMismatch）-->
            <ThresholdFilter level="debug" onMatch="ACCEPT" onMismatch="DENY"/>
            <!--如果配置的是“%d{yyyy-MM}”，滚动时间单位就是月。“%d{yyyy-MM-dd}”，滚动时间单位就是天-->
            <PatternLayout pattern="${LOG_PATTERN}"/>
            <!--指定滚动日志的策略，就是指定新建日志文件的时机-->
            <Policies>
                <!--interval属性用来指定多久滚动一次，时间单位取决于<PatternLayout pattern>，modulate属性调整时间，true：0点为基准滚动，false：服务器启动时间开始滚动-->
                <TimeBasedTriggeringPolicy interval="1" modulate="true" />
                <SizeBasedTriggeringPolicy size="100MB"/>
            </Policies>
            <!-- DefaultRolloverStrategy属性如不设置，则默认为最多同一文件夹下7个文件开始覆盖-->
            <DefaultRolloverStrategy max="15">
                <!--删除15天之前的日志-->
                <Delete basePath="${FILE_PATH}" maxDepth="2">
                    <IfFileName glob="*/*.log.gz" />
                    <IfLastModified age="360H" />
                </Delete>
            </DefaultRolloverStrategy>
        </RollingFile>


        <!-- 这个会打印出所有的warn及以下级别的信息，每次大小超过size，则这size大小的日志会自动存入按年份-月份建立的文件夹下面并进行压缩，作为存档-->
        <RollingFile name="RollingFileInfo" fileName="${FILE_PATH}/info.log" filePattern="${FILE_PATH}/info/INFO-%d{yyyy-MM-dd}_%i.log.gz">
            <!--阈值过滤器，控制台只输出level及其以上级别的信息（onMatch），其他的直接拒绝（onMismatch）-->
            <ThresholdFilter level="info" onMatch="ACCEPT" onMismatch="DENY"/>
            <PatternLayout pattern="${LOG_PATTERN}"/>
            <Policies>
                <!--interval属性用来指定多久滚动一次，时间单位取决于<PatternLayout pattern>，modulate属性调整时间，true：0点为基准滚动，false：服务器启动时间开始滚动-->
                <TimeBasedTriggeringPolicy interval="1" modulate="true" />
                <SizeBasedTriggeringPolicy size="100MB"/>
            </Policies>
            <!-- DefaultRolloverStrategy属性如不设置，则默认为最多同一文件夹下7个文件开始覆盖-->
            <DefaultRolloverStrategy max="15"/>
        </RollingFile>


        <!-- 这个会打印出所有的error及以下级别的信息，每次大小超过size，则这size大小的日志会自动存入按年份-月份建立的文件夹下面并进行压缩，作为存档-->
        <RollingFile name="RollingFileError" fileName="${FILE_PATH}/error.log" filePattern="${FILE_PATH}/error/ERROR-%d{yyyy-MM-dd}_%i.log.gz">
            <!--阈值过滤器，控制台只输出level及其以上级别的信息（onMatch），其他的直接拒绝（onMismatch）-->
            <ThresholdFilter level="error" onMatch="ACCEPT" onMismatch="DENY"/>
            <PatternLayout pattern="${LOG_PATTERN}"/>
            <Policies>
                <!--interval属性用来指定多久滚动一次，时间单位取决于<PatternLayout pattern>，modulate属性调整时间，true：0点为基准滚动，false：服务器启动时间开始滚动-->
                <TimeBasedTriggeringPolicy interval="1" modulate="true" />
                <SizeBasedTriggeringPolicy size="100MB"/>
            </Policies>
            <!-- DefaultRolloverStrategy属性如不设置，则默认为最多同一文件夹下7个文件开始覆盖-->
            <DefaultRolloverStrategy max="15"/>
        </RollingFile>
        <!--启用异步日志，阻塞队列最大容量为20000，超出队列容量时是否等待日志输出，不等待将直接将日志丢弃-->
        <Async name="Async" bufferSize="20000" blocking="true">
            <AppenderRef ref="Console"/>
            <AppenderRef ref="RollingFileDebug"/>
            <AppenderRef ref="RollingFileInfo"/>
            <AppenderRef ref="RollingFileError"/>
        </Async>
    </appenders>


    <!--Logger节点用来单独指定日志的形式，比如要为指定包下的class指定不同的日志级别等。-->
    <!--然后定义loggers，只有定义了logger并引入的appender，appender才会生效-->
    <loggers>
        <!--过滤掉spring和mybatis的一些无用的DEBUG信息-->
        <logger name="org.mybatis" level="info" additivity="false">
            <AppenderRef ref="Async"/>
        </logger>
        <!--监控系统信息-->
        <!--若是additivity设为false，则 子Logger 只会在自己的appender里输出，而不会在 父Logger 的appender里输出。-->
        <Logger name="org.springframework" level="info" additivity="false">
            <AppenderRef ref="Async"/>
        </Logger>
        <!--root 节点用来指定项目的根日志，level:日志输出级别，共有8个级别，按照从低到高为：All < Trace < Debug < Info < Warn < Error < Fatal < OFF.-->
        <root level="debug">
            <AppenderRef ref="Async" />
        </root>
    </loggers>


</configuration>

```





## 问题记录

#### resource文件不生效

因为xml名字弄错了，应该是log4j2.xml ，我新建的是log4j.xml