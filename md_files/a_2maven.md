# 问题记录

#### 多个相同包加载机制

对有服务器bin有的jar包，若拷贝了多个版本，并且项目包已经打包了，加载顺序情况如何

以及多个依赖用到了相同的子依赖包的不同版本

#### 子依赖不同版本

依赖排除有个问题，就是b,c同时依赖不同版本的d，怎么去排除，并且是排除哪一个呢？

#### 项目jar包自动下载依赖

maven打包的项目，在META-INF的目录下是有pom文件的。

但是不知道怎么通过jar包下载依赖

# 问题已解决(需回顾)

#### 打包fat-jar

pom文件加入这个，这个会把所有依赖非provided和test包打包进去

```xml
<build>
    <plugins>
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-shade-plugin</artifactId>
            <version>3.2.4</version>
            <executions>
                <execution>
                    <phase>package</phase>
                    <goals>
                        <goal>shade</goal>
                    </goals>
                    <configuration>
                        <createDependencyReducedPom>false</createDependencyReducedPom>
                    </configuration>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>

```



#### pom文件导入卡在sync

```sql
#maven版本和idea版本不兼容
从git上拉的maven项目，pom文件无法构建，因为windows上把公共settings改成了用自己的maven，.idea 2018和maven3.6不兼容。改回原来的idea自带的maven3就行了

#本身有的项目构建时就慢
最长一次的构建时7分钟，只要不报错，就不是maven的问题

#报错Could not find artifact org.pentaho:pentaho-aggdesigner-algorithm:pom:5.1.5-jhyde in nexus-aliyun
在阿里云仓库找不到这个模版，建maven项目的时候指定模版指定错了。
```

#### http repository are blocked

```mysql
#idea完整报错
Since Maven 3.8.1 http repositories are blocked
原因引文maven 3.8以后的版本,因为协议安全问题开始使用https，不使用http了，所以要想正常用，降低maven配置到3.6版本
```



# 问题已理解(备份)

```sql
#### 运行报错找不到类
flink实时项目时，运行代码找不到类,不过自己手动能找到这个类，因为pom配置的是provided，运行时不会把依赖带进去
两种解决方式：1 把provided去掉
2 点进run=》点击edit configrations=>edit template=>applictions=>modify options=>add denpendency with provided
这个模版配置一次，以后就不用配置了.windows上的操作是run=>edit configrations=>application选中类名=> configuration=>勾选provided

#### 打包报错1.5不支持静态接口
maven打包时显示，1.5语法不支持静态接口的调用,project structure都改成8了，还是不行
最后是pom文件 添加制定maven编译器解决的。或者把java compiler里的版本改成1.8这种方法也行
<properties>
    <maven.compiler.source>1.8</maven.compiler.source>
    <maven.compiler.target>1.8</maven.compiler.target>
</properties>

#### 无法找到plugins
自己配置的阿里云源总是缺东西，以后默认用maven的conf配置文件
maven的jar管理和插件管理是2个不同的仓库，当初只更改配置了一个源，插件源没换。

#### idea源码下载失败
pom导入jar依赖没问题，不过点进去之后，用idea 下载soure源码一直失败，在目录下的terminal执行 mvn dependency:sources

#idea的maven3
会使用自己的settings.xml,虽然手动指定了配置文件和仓库，不过好像不使用

```





# idea对接maven

#### 替换maven源

idea读取maven仓库和配置，默认在/Users/timor/.m2 目录下的，repository是仓库，settings.xml是配置文件。

我已经把之前的名字改过一次了，如果找不到会默认新建2个新库和配置文件

```xml
<localRepository>/Users/timor/Desktop/coding_software/apache-maven-3.9.0/timor_maven_repository</localRepository>

    <mirror>
        <id>nexus-aliyun</id>
        <mirrorOf>central</mirrorOf>
        <name>Nexus aliyun</name>
        <url>http://maven.aliyun.com/nexus/content/groups/public</url>
    </mirror>
```

#### 创建maven项目

mac版

```sql
#最简单方式创建
创建普通项目时,选择maven就行


#模版方式创建
创建时，选择maven-archetype
创建时catalog是选择maven是自己的/idea的
arhcetype 选择样板，不同样板创建的项目结构不同，idea可以勾选很多种
网上推荐的有这3种:
cocoon-22-archetype-webapp   会有webapp的目录，并且有log4j.xml和web.xml等，pom文件还会导入一些依赖
maven-archetype-quickstart     第二个是快速创建，很干净
maven-archetype-webapp   第三种比第一个干净一点
```











#### 手动运行maven项目

pom配置如下，这段代码会让mvn install时，将依赖的jar放入到tartget/dependency目录下，

如果不加，在tartget目录下，/dependency目录

```xml
<build> 
<plugins> 
  <plugin> 
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-dependency-plugin</artifactId> 
    <version>3.1.2</version> 
    <executions> 
      <execution> 
        <id>copy-dependencies</id> 
        <phase>prepare-package</phase> 
        <goals> 
          <goal>copy-dependencies</goal>
        </goals> 
        <configuration>
			</execution> 
     </executions> 
     </plugin> 
   </plugins>
  </build>
```

然后执行项目主类，就可以找到jar了

```shell
java -cp target/classes:target/dependency/* com.example.Main
```



# maven依赖冲突解决

#### 案例1

```
在测flink反压的代码中，导入了flink-connector-kafka，这里下面引入了kafka-client 3.3.1版本
我自己为了造数据导入kafka-2.4.5版本，导致有一个方法找不到。应该是引入低版本了，flink用的是高版本方法。

通过idea的pom文件右键只能看到引入了哪些包，如果想要看引入包的版本，把移动到一个空的maven项目的pom下，执行mvn dependency:tree


```



#### 排查方法



1  classsnotfound，基本就是jar包没找，或者依赖冲突问题

```sql
解决依赖冲突的问题通常需要一些耐心和细心，尤其是在涉及复杂的项目或大量依赖的情况下。以下是一个详细的操作流程，可以帮助你定位和解决Flink lib库中的依赖冲突问题：

1. **确认错误信息**：
   - 首先，仔细阅读异常堆栈跟踪（stack trace），确保理解`ClassNotFoundException`的确切原因。通常，这个异常是因为JVM在classpath中找不到指定的类。

2. **检查Flink lib目录**：
   - 查看Flink的`lib`目录下已有的jar包。这些是Flink运行时默认加载的库。
   - 使用命令行工具，如`ls`（在Linux或Mac上）或`dir`（在Windows上），列出这些jar包。

3. **列出新加入的jar包**：
   - 同样地，列出你添加到`lib`目录中的所有jar包。

4. **分析依赖**：
   - 对于每个新添加的jar包，使用工具如`mvn dependency:tree`（如果是Maven项目）或`gradle dependencies`（如果是Gradle项目）来分析它们的依赖树。
   - 如果你没有使用构建工具或者这些jar包是独立下载的，你可以使用工具如`jdeps`（Java依赖分析工具）来检查jar包中包含的类和它们的依赖。

5. **定位冲突**：
   - 使用上一步的信息，对比Flink的lib目录中的jar包和你添加的jar包的依赖。
   - 查找任何相同的类名，特别是那些出现在异常中的类名。注意类的版本号，因为不同的版本可能会导致冲突。

6. **解决冲突**：
   - 一旦你找到了冲突的类，你需要决定哪个版本是你需要的。
   - 如果Flink的lib目录中的版本较旧，你可能需要将其替换为新版本（这需要谨慎，因为这可能影响Flink的稳定性）。
   - 如果新添加的jar包中的版本较旧，你可以尝试从这些jar包中删除冲突的类，或者寻找不包含这些冲突类的替代jar包。

7. **测试解决方案**：
   - 在做出任何更改后，重新启动Flink并运行你的应用程序，看看问题是否解决。
   - 如果问题仍然存在，可能需要回到分析阶段，看看是否有其他的冲突没有解决。

8. **使用隔离加载器**：
   - 如果问题复杂，考虑使用Flink的插件机制，它可以将特定的连接器和库与Flink的核心类加载器隔离开来。
   - 你可以将你的连接器jar包放在`/plugins`目录下，而不是`/lib`目录下，这样它们将由一个专门的类加载器加载，从而减少类冲突的可能性。

9. **文档记录**：
   - 解决问题后，记得记录下你的解决过程和决策，这对未来的你或其他同事解决类似问题会有很大帮助。

10. **寻求帮助**：
    - 如果你在解决冲突的过程中遇到困难，不要犹豫寻求来自社区的帮助，比如在Stack Overflow上发帖，或者在Flink的用户邮件列表上提问。

处理依赖冲突通常不是一个直接的过程，可能需要尝试多种方法。保持耐心，一步步来，通常都能找到解决问题的方法。
```





# maven项目部署到服务器

将依赖项会被打包并上传到本地Maven仓库中。

如果需要将依赖项上传到远程Maven仓库，可以在pom.xml文件中配置好远程仓库的地址和认证信息，然后执行以下命令：`mvn deploy`

然后服务器从远处仓库通过pom文件下载jar包然后运行。



# maven项目导入依赖包

#### provid依赖自动导出

手动管理这些依赖可能会很麻烦，尤其是当它们有很多时。一个解决方案是使用Maven来自动下载并管理这些依赖。你可以编写一个Maven脚本或使用Maven的`dependency:copy-dependencies`目标来复制所有`provided`范围的依赖到一个指定的目录。

```bash
mvn dependency:copy-dependencies -DoutputDirectory=./lib -DincludeScope=provided
```

这个命令会将所有标记为`provided`的依赖复制到Tomcat的共享库目录。

注意事项

- 确保你的Tomcat配置允许从`shared.loader`指定的路径加载类。
- 如果你的应用需要特定版本的库，确保不要与Tomcat服务器自带的库冲突。
- 始终检查你的应用是否正确地识别并使用了共享库中的依赖。

通过这种方式，你可以保持你的Spring Boot JAR包的大小在合理的范围内，同时也能够确保你的应用能够访问到它所需的所有库。

比如flink项目用到了kafka，那么我们pom只打包kafka然后将项目jar导出，然后复制里面的kafka用的的jar包

上面思路不行，打包的jar包都是文件，不是jar包格式的



#### 创建胖jar

自带的maven工具不会把依赖打包，必须要指定插件,来完成打包附带依赖功能

```xml
这个会把除了provided,test外的所以依赖直接打包的项目jar中
<build>
    <plugins>
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-shade-plugin</artifactId>
            <version>3.2.4</version>
            <executions>
                <execution>
                    <phase>package</phase>
                    <goals>
                        <goal>shade</goal>
                    </goals>
                    <configuration>
                        <createDependencyReducedPom>false</createDependencyReducedPom>
                    </configuration>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
```



#### 手动导入jar

由于你不打算将Kafka依赖打包进JAR，你需要在Tomcat服务器上管理这些依赖。通常，你可以将这些依赖放在Tomcat的`lib`目录中，但这可能会导致类加载问题，尤其是当你的应用需要一个不同版本的库时。

一个更好的方法是使用Tomcat的共享库功能，这样你可以为特定的应用配置路径来加载特定的库。你可以在`$CATALINA_HOME/conf/catalina.properties`文件中设置`shared.loader`属性，指定一个包含你的Kafka库的目录，例如：

```properties
shared.loader=${catalina.base}/shared/lib/*.jar
```

然后，将Kafka及其相关依赖的JAR文件复制到`${catalina.base}/shared/lib/`目录。

#### 手动指定jar包

查看kafka进程时 ,发现kafka执行的时候发现，

进程之所以那么长：因为 java -cp  /路径/a.jar:/路径/b.jar

手动指定了几十个jar包，这也是一种指定的方式，基本都是kafka的libs目录下的jar

# maven私服

几乎所有的公司都会有自己的maven私服，我觉得有以下几点原因：

1. 为了共享，管理，自己的包依赖，因为一般公司都会开发自己的服务，各个服务器都会相互依赖，这个时候就需要把jar依赖，上传到一个公共的地方，供各个项目使用。

1. 为了代码安全，自己公司开发的东西肯定不想让其他知道，如果你上传到公服（阿里云等）则会造成 代码泄漏的风险，且管控权也不在自己这边。

1. 公司没有外网，只能自己搭建maven私服。

# maven指令

#### mvn install

1. 清理：如果之前已经构建过项目，`mvn install` 会先清理之前构建生成的文件。
2. 编译：`mvn install` 会编译项目的源代码，将源代码编译成可执行的字节码文件。在target目录下
3. 测试：如果项目中包含单元测试，`mvn install` 会执行这些单元测试。如果单元测试失败，构建过程将会停止。
4. 打包：`mvn install` 会将项目打包成一个可分发的格式，如 JAR、WAR 或者其他 Maven 支持的格式。
5. 安装：最后，`mvn install` 会将打包生成的文件安装到本地 Maven 仓库中。本地 Maven 仓库是一个本地存储库，用于存放项目依赖的库文件。安装到本地仓库后，其他项目就可以引用这个库文件作为依赖。

mvn -f  path路径  clean  install       这个指定目录,clean 和 install是2个指令

#### mvn archetype

mvn archetype:gernerate  创建一个mvn工程，arrchetype是插件名字，调用插件，gernerate是目标

执行后，后面有个选择默认是 7，快速的archetype

网上推荐的有这3种

cocoon-22-archetype-webapp    会有webapp的目录，项目下有log4j.xml和web.xml等文件模版，pom文件还会导入一些依赖

maven-archetype-quickstart  快速创建，很干净

maven-archetype-webapp   比第一个干净一点



# maven篇

#### 项目jar包内容

注意：打成的项目jar包里没有pom文件,pom文件是用来mvn用的

打成jar包有2种方式:

​			1 创建胖jar，直接将依赖的的class放入项目jar中

​			2 下面的jar-with-dependencies ，也是直接将依赖的的class放入项目jar中

​			

#### 手动maven工程

 1   mvn archetype:generate  创建一个mvn工程，arrchetype是插件名字，调用插件，gernerate是目标

执行后，后面有个选择默认是 7，快速的archetype



2 用maven工程操作，必须在pom所在目录下，不然执行报错，可以多个指令一起写比入mvn clean  install 



mvn compile java文件编译，放到target中

mvn clean 清除target目录

mvn test  执行test下的所有@test注解方法

mvn package  打成jar包，并不会把test代码打包进去，好像只有test全通过了，才能打包

mvn install  将本项目的打包的jar包，存入本地仓库中





#### junit结构

 1   maven结构，一般在main中创建了一些代码，在test中有个对应的测试代码。这样后续查看测试代码的时候条理清晰，不然我们在main里自测，方法多了之后就很冗长



#### 依赖scope的作用范围

scope标签有几种 compile  ,test ,provided,system,runtime,import 



|          | main目录 | test目录 | 开发时 | 部署时 |
| -------- | -------- | -------- | ------ | ------ |
| test     | 不能     | 能用     | 能用   | 不能   |
| compile  | 能用     | 能用     | 能用   | 能用   |
| provided | 能用     | 能用     | 能用   | 不能   |

对有的有服务器有的jar包，用不打包进去，不然有时候可能出现版本对不上，jar包冲突。这种的用provided标签修饰。

一般从maven仓库下载的时候，scope都是帮你写好的，不要乱改就行



#### jar包冲突原因

版本问题
同一个jar引入了两个版本A和B, 构建时取了其中一个版本A, 这时候可能会冲突:

```
如果A是低版本, 代码里用了高版本B的代码, 调用时就会报上述的错
如果A是高版本, 但没有兼容B版本, 代码里调用了B版本独有的代码, 也会报错，
比如一个项目的多个mudule，引入了2次jar，a module 用的a包写的代码没报错， b module用的b包写的代码也没报错，
但是构建的时候，只会选用其中一个版本。
```



- 包命名问题
  两个不同的jar, 因为命名不规范定义了相同的全路径Class, 构建时没问题两个jar都被构建, 但调用时有可能会报错, 之所以说有可能还与具体的机器相关

```
如果机器先加载A包, 调用A包同路径Class的代码就不会报错
如果机器先加载A包, 调用B包同路径Class的代码就会报错
如果机器先加载A包, 调用B包同路径Class的代码, 但A包也有相同方法签名的方法, 此时不会报错, 但是调用逻辑可能是非预期但很难发现
```

#### 依赖传递性

a 依赖 b  ，b 依赖 c ，那么a 能不能直接调用c的方法。 如果b对c的依赖是copile范围，那么能传递，如果是test和provided那么不能传递给a

#### 依赖排除

a 依赖b ,a 依赖c，  b,c各自依赖 用不同版本的d 包，那么就在bc中选一个，排除掉一个d包

```
    <dependency>
      <groupId>junit</groupId>
      <artifactId>junit</artifactId>
      <version>4.12</version>
      <!-- 当前依赖的范围，也就是说junit这个包就是test用的  -->
      <scope>test</scope>
      
      <exclusions>
            <groupId>aaaa</groupId>
      			<artifactId>bbbb</artifactId>
      			      <version>4.12</version>
      <!--排除的不需要写版本-->
      </exclusion>
    </dependency>
```

#### 依赖继承

父工程的依赖，在子工程可以继承版本号。  子工程有些依赖可以不写版本号，如果这样，在父工程或者爷爷工程中一定要一个写版本号

这样方便版本管理，但是有个问题就是，不同工程单独拆下来编码测试的时候，需要自己写，然后再删除吗？



#### 创建父工程

 加入<packaging>pom</packaging>

```
  <groupId>com.cbk.timor</groupId>
  <artifactId>learning_maven_origin</artifactId>
  <version>1.0</version>
  
  <!--只有写了打包方式是pom的工程才能作为父工程-->
  <packaging>pom</packaging>
  
     <!--创建子工程之后，mvn会自动帮你加入moules-->
      <modules>
        <module>son1</module>
        <module>son2</module>
    </modules>
    
    
       <properties>
   		<!-- 构架过程中读取源码使用的字符集 -->
      <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    	</properties>
     <!--  父工程中，要加入dependencyManagement的标签 -->
    <dependencyManagement>
    <dependencies>

        <dependency>
            <groupId>junit</groupId>
            <artifactId>junit</artifactId>
            <version>4.12</version>
            <scope>test</scope>
        </dependency>

    </dependencies>

    </dependencyManagement>
```





#### 创建子工程

在父工程的根目录执行mvn archetype:gernerate  ，就可以创建子工程 ，子工程会出现下面的标签。

并且一般子工程和父工程的本项目的groupid和version都是一致的，所以子工程自己的version和grouplid不用谢，

这里是指com.cbk.timor。子工程还是需要写要哪些依赖，不过不用写版本。如果非要写版本，则覆盖父工程版本

```
   <parent>
        <artifactId>learning_maven_origin</artifactId>
        <groupId>com.cbk.timor</groupId>
        <version>1.0</version>
    </parent>
```



#### 版本号用变量代替

这样只改一个多处都能改,在propertites标签里，我们可以自定义属性

```
    
   <properties>
    	<project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    	<!--  自定义变量 -->
    	<timor.verson>4.1.2</timor.version>
  </properties>
    
    <dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>junit</groupId>
            <artifactId>junit</artifactId>
            <!-- 使用自定义变量 -->
            <version>${timor.version}</version>
        </dependency>
    </dependencies>

    </dependencyManagement>
```



#### 指定mainclass和打包带依赖

配置解读
第一个插件是maven-compiler-plugin，用于指定编译器的版本和源代码的目标版本。在这个例子中，source和target都被设置为1.8，表示使用Java 8的语法和功能。
第二个插件是maven-assembly-plugin，用于创建可执行的JAR文件，并将所有依赖的库打包到JAR中。
descriptorRefs指定了使用的描述符引用，这里使用了jar-with-dependencies，表示将所有依赖的库一起打包到JAR中。
archive部分用于配置JAR文件的清单（manifest），其中mainClass指定了主类的全限定名，这个类将作为可执行JAR的入口点。
executions部分定义了插件的执行配置。在这里，make-assembly是执行的ID，package是执行的阶段（phase），表示在Maven的打包阶段执行该插件。single是执行的目标（goal），表示只执行一次。
总结起来，这段代码的功能是配置Maven构建过程中的两个插件：编译插件和打包插件。编译插件指定了Java版本和编译选项，而打包插件用于创建包含依赖的可执行JAR文件，并指定了主类作为入口点。

```xml
<build>
		<plugins>
			<plugin>
				<artifactId>maven-compiler-plugin</artifactId>
				<version>2.3.2</version>
				<configuration>
					<source>1.8</source>
					<target>1.8</target>
				</configuration>
			</plugin>

			<plugin>
				<artifactId>maven-assembly-plugin </artifactId>

        <!--打包带依赖-->
				<configuration>
					<descriptorRefs>
						<descriptorRef>jar-with-dependencies</descriptorRef>
					</descriptorRefs>

            <!--配置主类-->
					<archive>
						<manifest>
							<mainClass>com.atguigu.mr.WordcountDriver</mainClass>
						</manifest>
					</archive>
					
				</configuration>

				<executions>
					<execution>
						<id>make-assembly</id>
						<phase>package</phase>
						<goals>
							<goal>single</goal>
						</goals>
					</execution>
				</executions>
			</plugin>
		</plugins>
	</build>

```



#### maven版本积累

就是一套架构，需要哪些依赖，有的依赖需要另外一个依赖多少版本以上，这种能试用的一套maven版本，都是不容易的，可以记录保存下来，以后直接用。



# 标签解读

#### properties

自定义声明一些变量

```xml
    <!-- 在properties里声明变量  -->
	<properties>
        <!--  写好flink版本，后续变更不需要每个都改，只改properties的属性    -->
        <flink.verson>1.13.0</flink.verson>
   </properties>

	
	<dependency>
    <groupId>org.apache.flink</groupId>
    <artifactId>flink-java</artifactId>
    <version>${flink.verson}</version>
    <scope>provided</scope>
	</dependency>


```

#### scope

用在依赖最下方，表明依赖作用范围，是否参与打包发布等等

```xml
<!--  -->
<dependency>
    <groupId>org.apache.flink</groupId>
    <artifactId>flink-java</artifactId>
    <version>${flink.verson}</version>
    <scope>provided</scope>
</dependency>

<!-- 
compile
默认的scope，表示 dependency 都可以在生命周期中使用。而且，这些dependencies 会传递到依赖的项目中。适用于所有阶段，会随着项目一起发布。
provided
跟compile相似，但是表明了dependency 由JDK或者容器提供，例如Servlet AP和一些Java EE APIs。这个scope 只能作用在编译和测试时，同时没有传递性。
runtime
表示dependency不作用在编译时，但会作用在运行和测试时，如JDBC驱动，适用运行和测试阶段。
test
表示dependency作用在测试时，不作用在运行时。 只在测试时使用，用于编译和运行测试代码。不会随项目发布。
-->

```

#### build





# 常用依赖pom

#### fastjson

```xml
        <dependency>
            <groupId>com.alibaba</groupId>
            <artifactId>fastjson</artifactId>
            <version>1.2.83</version>
        </dependency>
```



序列化json，将java转为json

```java
//将字符串转为json
String s="{\"address\":\"北京市\",\"age\":20,\"id\":1,\"name\":\"张三\"}";
JSONObject jsonObject = JSON.parseObject(s);
Integer age = jsonObject.getInteger("age");
Set<String> columns = jsonObject.keySet();
Collection<Object> values = jsonObject.values();

//json中插入数据
js.put("name","jack");

//将对象转为json
String jsonString = JSON.toJSONString(student);

 // 将json字符串 转为对象
String objectString="{\"address\":\"北京市\",\"age\":20,\"email\":\"zs@sina.com\",\"id\":1,\"name\":\"张三\"}";
Student student = JSON.parseObject(objectString, Student.class);

//将对象数组，转为json数组  
ArrayList<Student> students = new ArrayList<>(
String s = JSON.toJSONString(students);

//将map转为json
 HashMap<String, String> map = new HashMap<>();
 map.put("name","张三");
 String s1 = JSON.toJSONString(map);

 //json转map,不过类型是Object
 Map<String,Object> map=js.getInnerMap()
  
 // 将json字符串 转为对象
String objectString="{\"address\":\"北京市\",\"age\":20,\"email\":\"zs@sina.com\",\"id\":1,\"name\":\"张三\"}";
Student student = JSON.parseObject(objectString, Student.class);
```











#### hadoop

```xml
        <dependency>
            <groupId>org.apache.hadoop</groupId>
            <artifactId>hadoop-client</artifactId>
            <version>3.1.3</version>
        </dependency>

        <dependency>
            <groupId>org.apache.hadoop</groupId>
            <artifactId>hadoop-hdfs</artifactId>
            <version>3.1.3</version>
            <scope>test</scope>
        </dependency>
    </dependencies>
```



#### flink

```xml
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-java</artifactId>
            <version>1.13.0</version>
        </dependency>
        <!-- -->
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-streaming-java_2.12</artifactId>
            <version>1.13.0</version>
            <scope>provided</scope>
        </dependency>

       <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-clients_2.12</artifactId>
            <version>${flink.verson}</version>
        </dependency>
```

#### junit

```
<dependency>
    <groupId>junit</groupId>
    <artifactId>junit</artifactId>
    <version>4.12</version>
</dependency>
```

#### log4j-slfm

```

```

















