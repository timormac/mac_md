#### servlet

servlet是运行在服务器是那个的小型java程序，用来接受和响应客户端请求。

servlet的创建，使用，销毁都由Servlet容器进行管理(如tomcat)，不需要main方法，在idea中写完Servlet接口，直接启动tomcat服务器即可

#### idea集成tomcat

settings=>Bulid,excution=>Application Servers =>点击加号选中tomcat=>指定路径home

mac版本idea创建tomcat项目：

new project=>Jakarta EE(和网上的名字不同)=>Template选择Web Application=>Application Serve选择tomcat

=>点击下一步，把Jakarta EE 改为javaEE=>下方有个添加依赖的(默认勾选了servlet4.0)

windows版创建tomcat项目:

new project=>java Enterprise =>Application Serve选择tomcat =>勾选Web Application(4.0)



注意：

edit tomcat configration时，http://localhost:8080/servlet_learn_war_exploded 别乱动,servlet默认前置路径就是这个。





做了这些操作创建的tomcat项目实际的maven如下:

```xml
 <dependencies>
        <dependency>
            <groupId>javax.servlet</groupId>
            <artifactId>javax.servlet-api</artifactId>
            <version>4.0.1</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter-api</artifactId>
            <version>${junit.version}</version>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter-engine</artifactId>
            <version>${junit.version}</version>
            <scope>test</scope>
        </dependency>
    </dependencies>
    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-war-plugin</artifactId>
                <version>3.3.2</version>
            </plugin>
        </plugins>
    </build>
```

#### 实现Servlet接口





#### 问题记录

1   servlet接口没有

javax.[servlet](https://so.csdn.net/so/search?q=servlet&spm=1001.2101.3001.7020)不存在或未找到，程序包javax.servlet.http不存在或未定义等错误。原因是servlet和JSP均不是java平台javase（标准版）的一部分，而是JavaEE的一部分，因此必须告知编译器servlet的位置。

解决方法:从tomacat的lib中拷贝出servelet-api.jar ,在idea的project structure中的lib导入，这样代码就是导入了



#### 问题待解决

1 idea配置的tomcat可以直接运行，那么代码的servlet接口如果通过服务器部署呢？？具体操作

2 同样的代码，用wiodow创建的tomcat没问题，mac创建的tomcat执行不了