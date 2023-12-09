## 学习顺序

1.Spring，springMVC，SpringSSM，Spring Boot，Spring Cloud分别是什么？

（1）Spring是一个轻量级的开源框架，通过它可以更加便捷地进行Java企业级应用程序的开发。Spring将开发中常用的功能模块，例如事务管理、数据访问、安全性等抽象的不同的模块、使得Java开发人员可以更加高效地完成开发工作

（2）SpringMVC是基于Spring框架地一个web框架。用于构建web应用程序，处理请求和响应，提供MVC模式的web应用程序开发，使得开发人员能够对web应用程序进行更好的控制，并且开发效率更高。

（3）Spring SSM是Spring+SpringMVC+Mybatis的框架的整合，能够快速搭建起易于维护的web程序。

（4）Spring Boot是在Spring框架上开发的微服务框架，通过自动配置来快速搭建独立的、生产级别的应用程序。

（5）Spring Cloud是基于Spring Boot的微服务框架，在微服务架构中解决复杂的分布式系统的问题，例如服务发现、配置管理和负载均衡等。通过使用Spirng Cloud可以更加轻松而高校地实现微服务开发。

2.Spring，springMVC，SpringSSM，Spring Boot，Spring Cloud各自的优缺点？

（1）Spring框架的优点：

        Spring可以简化Java企业级开发的流程，提高开发效率;Spring可以帮助Java开发人员实现依赖注入和控制反转来降低应用程序的耦合度；Spring提供了很多扩展模块，例如Spring AOP和Spring Security，可以方便地增强应用程序的功能性和安全性。
    
        Spring框架的缺点：
    
        Spring的学习曲线比较陡峭，初学者需要花费一定的时间来理解其复杂的概念和机制；Spring的配置文件可能会变得庞大且不易维护；在处理大量数据时，Spring框架的性能可能会受到影响。

（2）SpringMVC的优点：

        MVC模式的清晰分层，能够更好地解耦业务逻辑、数据访问等部分；可以方便HandlerMapping、HandlerAdapter,满足不同场景的需求；可以灵活使用拦截器进行预处理和后处理。
    
        SpringMVC的缺点：
    
        需要手动进行配置，配置文件较多，有些繁琐；对于复杂的请求分支，需要手动进行配置。

（3）SpringSSM的优点：

        整合了Spring、SpringMVC和Mybatis三大主流框架，使得开发人员能够快速搭建易于维护的web应用程序；提供了很多遍历的注解和标签，简化编码过程。
    
        SpringSSM的缺点：
    
        配置文件较多，维较为麻烦；在处理大量数据时，性能可能会受到影响。

（4）Spring Boot的优点：

        约定大于配置，基本上无需任何配置即可快速构建独立的，生产级别的应用程序；自动配置能力强，通过引入不同的starter可以快速集成相应的组件，提高开发效率；提供了可视化的调试界面Actuator.
    
        Spring Boot的缺点：
    
        因为自动配置的缘故，有些开发人员可能不了解底层原理；开发小规模应用时，可能因为过度集成而导致启动速度变慢。

（5）Spring Cloud的优点：

        提供了服务注册发现、客户端负载均衡、断路器等模块，方便构建分布式系统；可以与各种服务治理工具进行集成，具有较高的灵活性；提供了Feign、Ribbon、Zuul等组件，能够满足不同场景的需求。
    
        Spring Cloud的缺点：
    
        由于拥有多个组件，系统的复杂度会提高；由于需要使用网络通信，网络层面的问题可能会对系统产生影响。

3.Spring，springMVC，SpringSSM，Spring Boot它们之间的区别

（1）Spring和SpringMVC的区别：

        Spring是一个IOC容器和AOP框架，提供了依赖注入和控制反转等基本功能；而SpringMVC则是Spring框架的一个web框架，用于构建MVC模式的web应用程序，处理请求和响应；Spring框架主要用于后端应用程序的开发，二SpringMVC主要用于Web应用程序的开发；Spring具有更广泛的应用领域，包括web,企业和集成等多个方面，二SpringMVC主要用于构建web应用程序。

（2）SpringBoot和Spring Cloud的区别：

        Spring Boot是用于快速构建独立应用程序的框架，通过自动配置和约定大于配置的原则来减少配置量，提高开发效率，适用于单体应用；Spring Cloud则是基于Spring Boot的微服务框架，解决分布式系统中的问题，例如负载均衡、服务注册和配置管理等，适用于复杂的分布式系统。

（3）Spring和SpringSSM的区别：

        SpringSSM整合了Spring、SpringMVC和Mybatis等框架，是一个结合了web框架和ORM框架的开发框架，能够构建易于维护的web应用程序；Spring则是基础框架，提供了依赖注入、控制反转、AOP和JDBC等核心功能，主要用于后端应用程序开发，需要使用其他框架或者工具来进行web开发。
————————————————
版权声明：本文为CSDN博主「qq_48914330」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。
原文链接：https://blog.csdn.net/qq_48914330/article/details/130959254

## 前言

现在用Java开发网站可以不用框架吗?

论开发的话，不用框架照样可以，没框架的时候，用jsp+servlet+jdbc这套照样能搭建系统，甚至在没引入java前，用asp+access照样能搭建web网站。但是只要是用java开发web网站，一定会用框架，后端是 spring boot+JPA，前端是用freemarker等，原因是，用框架能降低开发和维护的难度，节省开发的成本。本文不想用上述单调和枯燥的原因来敷衍大家，**所以就干脆盘点下一些用过的Java web网站开发技术，讲讲技术和组件的演变过程。*从中大家就能知道为什么现在要用框架开发网站，以及为什么大多数公司会选spring boot框架。**一开始比较流行的web网站开发技术是asp，java层面的是jsp，这两者其实差别不大。**JSP不能理解成是框架，而是一种技术。JSP里很神奇，里面可以包含HTML页面代码和Java代码。也就说说，如果用jsp开发web页面的时候，前后端是不分离的，全在一个jsp文件里，所以当时只要会用jsp，那么一定能称得上“全栈开发工程师”。一般一个JSP文件会对应一个web页面，一个jsp文件会包含如下的内容。1 开头会用JS等脚本，判断该页面是否有请求到达，如果有，还得分，对不同页面挑过来的请求要做不同的处理，所以一个jsp文件的开头，包含很长一段if else语句来处理请求，这是常有的事。2 然后会用HTML代码来渲染页面，当然其中还会和css，div等元素打交道。3 页面里如果需要展示从数据库里得到的数据，那么就需要用java代码现连数据库并得到数据，所以一个jsp页面里出现大量JDBC对象也是正常的。4 同样道理，如果页面里需要展示其他业务数据，也需要加入java代码。所以一般一个jsp文件是个包含前端、js脚本和java语言的大杂烩，这样开发起来就不容易，如果遇到业务调整，要维护对应的jsp代码更难。**由于JSP里包含的要素实在太多，后面就改成了jsp+servlet+javabean的模式。**在这模式中，会把JSP页面里负责跳转的代码放入servlet，再把一些java通用性的代码，比如连数据库或业务方法，放入javabean，这其实已经引入了MVC模式。和单纯的JSP相比，这套模式仅仅是拆分了jsp文件，但具体的调转页面动作以及传输参数和请求传递等细节，依然需要程序员来编写。即程序员不仅要实现web项目里的业务，更需要实现页面间跳转和数据传输等底层细节，这对程序员的要求是比较高的。**后来在此基础上引入了Struts，这是一个比较成熟的web框架。**当时Struts框架展现出了如下的优势。1 封装了页面跳转等的web事件实现细节，比如在jsp里，程序员调用跳转方法，并传入参数以实现跳转，而跳转目标所对应的jsp还得去接收。但在Struts框架里，程序员只要指定向哪里跳转即可，具体的跳转动作Struts框架能自动实现。2 能用xml等配置文件，配置通用性参数。比如请求和对应页面的跳转规则，或者是数据库连接参数，都可以配到xml里。由于Struts能分担些页面跳转等web动作的实现过程，所以Struts也流行了一阵。**从中大家也能体会到框架的含义：用底层实现的方式封装了通用性的动作，这样程序员能通过使用api或编写配置等轻便的方式实现Web网站方面的功能。**但是Struts框架也有**“侵入性强”**的问题，比如要开发一个实现业务功能的模块，在模块里一定能看到Struts的痕迹，比如struts动作等。**用专业的话说：基于Struts框架的Web项目，业务和Struts耦合度太紧密。**比如要升级Struts的支持包，或者要更改原有业务的web跳转方式，那么一定得用额外的代码来维护Struts相关的模块。我们知道Spring框架的优势是依赖注入，即能降低模块间的耦合度，所以后来在单纯Struts框架上引入了SSH框架，用Struts框架里的web跳转动作和web实现细节，用Spring来管理模块，让模块间低耦合好维护，再用Hibernate来实现ORM映射。SSH框架和Struts框架的进步还在于引入了ORM。之前程序员在实现业务时需要自己关注数据库，比如用JDBC得到连接，再用sql语句去做增删改查，然后再自己得到结果，再展示数据库结果到页面上。也就是说，业务代码和数据库相关的代码关联性很强，这就要求程序员在开发时，需要了解数据库的表名和字段名等细节。为了进一步解开业务模块和数据库之间的关联，SSH框架里的Hibernate，可以用来把数据库里的表，映射成Java对象，这样程序员从数据库里得到的数据会被Hibernate，根据配置文件等定义，自动转换成List等类型的Java类，这样程序员就可以用操作Java对象的方式来操作数据库。这里姑且不论这种ORM映射做法的必要性，但这进一步降低了程序员开发Web项目的难度，程序员只需要懂java，就能开发web网站，而数据库相关细节和动作都能被Hibernate等ORM组件屏蔽。**由于Hibernate比较重，所以SSH框架后来被替换成SSM。M是Mybatis，现在SSM框架还在用。**SSM框架由于能很好地向程序员屏蔽页面跳转等动作，能让程序员很便捷地把业务数据映射到数据库里，所以能进一步降低程序员开发Web项目的难度，同时由于把业务、数据库和前端支持等模块拆分到不同的文件里，所以基于SSM框架的项目也比较好维护。但SSM（或SSH）框架有如下两个问题。1 配置文件太多太复杂。比如要连个数据库，得写xml，要实现个事务，也得用，要整合个dubbo，也得写。所以一个项目开发下来，xml配置文件会有很多，而且每个配置文件里有几百行代码，都算正常。2 SSM框架的代码，部署时需要打成war包，然后部署到tomcat等服务器里。当然之前的框架也是这样干的，不过Spring Boot框架在这方面能省事不少。**现在主流的Web框架是Spring Boot**，里面是通过注解替代了配置文件，所以哪怕在项目里整合了事务，dubbo或者其他组件，都可以用简单的注解来实现，而无需再写长长的配置文件。而且由于Spring boot框架内嵌tomcat服务器，所以发布时，只要把项目打成jar包，然后用java命令启动即可。此外，之前框架里封装的web底层实现细节，这个框架也有。讲到这里大家其实可以看到，用java开发网站，用框架其实能帮程序员省太多的事情。比如造房子，不用框架的建筑方式是，从一砖一瓦自己搭建，中间自己再铺设水电煤等管道。如果是用框架，就直接用现成的建筑模块单元组装成房子。**其实用框架还真是程序员，或者是软件公司自己的选择，客户方才不管。**只要他们提出的需求能实现，哪怕是用asp实现他们也没意见，但这样的话，软件公司就无法用框架提供的web和数据库基础设施等便利，什么都得从头开始，一方面进度会慢，导致成本高，一方面维护难，提升后期风险。说到Web框架，本人当年出的书里，还详细讲述了现在看上去的古董框架，比如jsp+servlet+javabean，以及struts框架。



由于框架已经帮程序员封装了太多的底层细节，所以大家能比较容易地达到“用框架开发增删改查业务“的水准，但这仅仅是Java初级开发干的活。

如果再要往上发展，绝不是去深挖框架的底层细节，这种技能应付面试也就算了，而应该去了解分布式组件或微服务框架，并能实现高并发的功能。如果再要向上发展，就要去积累通过框架+组件设计应对高并发场景的项目实施框架，同时再去积累解决这过程中常见问题的经验。如果把这块做好了，升级个Java架构问题都不大了，按现在的行情，年入60w应该都算毛毛雨了。

本文讲解了Web框架的发展历程，并在此基础上解释了框架对web开发的作用。本文全文原创，用时将近3小时，如果如果大家感觉可以，请多多点赞。



## spring6

#### 通过xml创建对象



在xml中

```xml
<bean id="user" class="com.cbk.timor.spring6.User"></bean> 
```

在代码中  可以通过xml，来自动创建对象

```java
//这里查了一下,ClassPathXmlApplicationContext继承了AbstractXmlApplicationContext，
//而AbstractXmlApplicationContext实现了ApplicationContext接口，也就是说这里换成本类也可以
				ApplicationContext  context = new ClassPathXmlApplicationContext("bean.xml");
        
        //返回的个object，因为反射创建出来的对象都是Object，所以要强转一下
        User  user = (User)context.getBean("user");
        
        System.out.println(user);
        
        user.add();
```



#### 大概解读

通过xml创建对象，肯定不是之前想的，根据文件额外生成一个new的代码，而是通过反射来创建的对象。



#### 问题待解决

理解spring的注解如何实现这些功能的，然后自定义类似的相关注解



## log4j



log4j导入是2个依赖

```
        
        <dependency>
            <groupId>org.apache.logging.log4j</groupId>
            <artifactId>log4j-core</artifactId>
            <version>2.17.1</version>
        </dependency>

        <dependency>
            <groupId>org.apache.logging.log4j</groupId>
            <artifactId>log4j-slf4j-impl</artifactId>
            <version>2.17.1</version>
        </dependency>
      
      
日志框架：slf4j
日志实现：log4j2
桥接包：log4j-slf4j-impl

桥接包log4j-slf4j-impl起到适配的作用，因为市面上的日志实现互不兼容，日志框架slf4j要想适用于日志实现log4j2，就需要使用桥接包

slf4j使用LoggerFactory创建Logger进行日志打印，底层实际上调用了log4j-slf4j-impl的StaticLoggerBinder类创建一个Log4jLoggerFactory，然后再由这个Log4jLoggerFactory创建一个Log4j2的Logger对象，这个Logger封装在log4j-slf4j-impl中的Log4jLogger里面，最后将Log4jLogger返回给slf4j，每次slf4j进行日志打印，实际上是log4j-slf4j-impl中的Log4jLogger调用log4j2进行日志打印
如果没有 log4j-slf4j-impl桥接包，slf4j将创建一个对象，里面都是空方法，所以不会打印出日志
        
```



配置文件

```

```



##### 日志等级

可以设置日志等级，如果设置warn等级，那么info和debug之前的等级都不会显示

trace

debug

info 信息，输出重要信息，试用较多

warn 警告，输出警告信息

error 错误，输出错误信息

fatal 严重错误



日志输出目的地，控制台还是文件

日志输出格式



##### 配置文件

必须交log4j2.xml ，试了一下叫log4j.xml不行，配置文件不生效







## 问题





