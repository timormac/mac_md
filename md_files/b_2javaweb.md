# 课程记录

到p124

# 问题待解决

1 怎么通过url地址，通过接口快速定位到代码在哪个位置？

# cbk代码

cbk的maven当时配置的是私服，仓库位置和配置文件都是单独配的。

windows的配置文件和仓库在C:\Users\lpc\.m2下面，需要手动配置maven文件才行

mac的配置文件和仓库在



# 后端维护功能

#### 接口使用情况

记录接口使用情况，执行时间，是否成功，存在服务器上，一个界面能展示，查看定位失败调用的问题，

接口也要记录当时的传参数等。

记录接口平均反应时长

#### 错误日志

因为和平时不同，平时idea自己运行tomcat，自己的不会try catch，当出问题时，直接就能看到报错。

或者服务器上的tomcat报错时,tomcat服务器就停了，这时候我们去看最后一条服务器日志就能找到问题。

但是线上都是try catch,不会中断服务器，所以必须记录错误日志，记录接口类，记录类型，不然之后想定位问题定位不到。



# javaweb

在cbk trade-web中的分层

biz是Business的缩写，实际上就是控制层，biz包下放的是逻辑控制

VO:value object值对象。 通常用于业务层之间的数据传递，和PO一样也是仅仅包含数据而已。但应是抽象出的业务对象 可以和表对应,也可以不,这根据业务的需要





### POJO,VO,DTO,Entity,Domain

https://blog.csdn.net/weixin_43783942/article/details/129137399

### dao理念

DAO (DataAccessobjects 数据存取对象) 是指位于业务逻辑和持久化数据之间实现对持久化数据的访问。通俗来讲，就是将数据库操作都封装起来。

DAO模式是一种结构模式，它允许我们使用抽象API将应用程序/业务层与持久层（通常是关系数据库，但它可以是任何其他持久性机制）隔离开来。

其实际为一个为数据库或其他持久化机制提供了抽象接口的对象，在不暴露底层持久化方案实现细节的前提下提供了各种数据访问操作。在实际的开发中，应该将所有对数据源的访问操作进行抽象化后封装在一个公共API中。用程序设计语言来说，就是建立一个接口，接口中定义了此应用程序中将会用到的所有事务方法。在这个应用程序中，当需要和数据源进行交互的时候则使用这个接口，并且编写一个单独的类来实现这个接口，在逻辑上该类对应一个特定的数据存储。

案例

```java
//接口
public interface userDao {
    // 查询所有用户
    List<User> findAllUsers() throws Exception;
}

//实现类
public class userDaoImpl 
    extends BaseDao 
    implements userDao {
    // 查询所有用户
    public List<User> findAllUsers() throws Exception {
        Connection conn=BaseDao.getConnection();
        String sql="select * from user";
        PreparedStatement stmt= conn.prepareStatement(sql);
        ResultSet rs = stmt.executeQuery();
        List<User> userList = new ArrayList<User>();
        while(rs.next()) {
            User user = new User(
                    rs.getInt("id"),
                    rs.getString("name"),
                    rs.getDate("birthday")
                    );
                userList.add(pet);
        }
        BaseDao.closeAll(conn, stmt, rs);
        return userList;
    }
}

实体类
public class User {
    private Integer id;
    private String name;
    private Date birthday;
    // 以下set和get方法就不写了
}
```

### dao案例

各表dao接口=>dao的imp=>业务实现service

###### dao

```java
//表的dao接口
public interface ProductDao {
    public boolean addProduct(Product product) throws Exception;
    public List<Product> findAll(String product_name) throws Exception;
    public  Product findByProductID(String product_id) throws  Exception;

}

//dao的实现

```



###### dao的impl

```java
public class ProductDaoImpl implements  ProductDao{
    private Connection conn = null;
    private PreparedStatement pstmt = null;

    public ProductDaoImpl(Connection conn) {
        this.conn = conn;
    }

    @Override
    public boolean addProduct(Product product) throws Exception {
        boolean flag = false;
        String sql = "insert  into product(idc,product_name,price,info) values(?,?,?,?)";
        this.pstmt = this.conn.prepareStatement(sql);
        this.pstmt.setString(1,product.getProduct_id());
        this.pstmt.setString(2,product.getProduct_name());
        this.pstmt.setDouble(3,product.getPrice());
        this.pstmt.setString(4,product.getInfo());
        int t = this.pstmt.executeUpdate();
        //System.out.println(t);
        if(t>0) {
            flag = true;
        }
        this.pstmt.close();
        return flag;
    }

    @Override
    public List<Product> findAll(String product_name) throws Exception {
        List<Product> list = new ArrayList<Product>();
        String sql = "select idc ,product_name,price,info from product";
        if(product_name != null &&!"".equals(product_name)) {
            sql ="select idc,product_name,price,info from product where product_name like ?";
            this.pstmt = this.conn.prepareStatement(sql);
            this.pstmt.setString(1,"%" +product_name+"%");
           
        }else {
            this.pstmt = this.conn.prepareStatement(sql);
        }
        ResultSet rs = this.pstmt.executeQuery();
        Product product = null;
        while(rs.next()) {
            product = new Product();
            product.setProduct_id(rs.getString(1));
            product.setProduct_name(rs.getString(2));
            product.setPrice(rs.getDouble(3));
            product.setInfo(rs.getString(4));
            list.add(product);
        }
        this.pstmt.close();
        return list;
    }

    @Override
    public Product findByProductID(String product_id) throws Exception {
        Product product = null;
        String sql = "select idc,product_name,price,info from product where idc = ?";
        this.pstmt = this.conn.prepareStatement(sql);
        this.pstmt.setString(1,product_id);
        ResultSet rs = this.pstmt.executeQuery();
        if(rs.next()) {
            product = new Product();
            product.setProduct_id(rs.getString(1));
            product.setProduct_name(rs.getString(2));
            product.setPrice(rs.getDouble(3));
            product.setInfo(rs.getString(4));
        }

        this.pstmt.close();
        return product;
    }
}

```



###### service

```java
public class ProductService implements  ProductDao{
    private  DBConnection dbconn = null;
    private  ProductDao dao = null;

    public ProductService() throws  Exception {
        this.dbconn = new DBConnection();
        this.dao = new ProductDaoImpl(this.dbconn.getConnection());
    }

    @Override
    public boolean addProduct(Product product) throws Exception {
        boolean flag = false;

        try{
            if(this.dao.findByProductID(product.getProduct_id()) == null) {
                //如果插入的产品编号不存在，那么就新增一条产品
                flag = this.dao.addProduct(product);
            }
        }catch (Exception ex) {
            ex.printStackTrace();
        }finally {
            this.dbconn.close();
        }

        return flag;
    }

    @Override
    public List<Product> findAll(String product_name) throws Exception {
        List<Product> all = null;
        try{
            all = this.dao.findAll(product_name);
        }catch (Exception ex) {
            ex.printStackTrace();
        }finally {
            this.dbconn.close();
        }
        return all;
    }

    @Override
    public Product findByProductID(String product_id) throws Exception {
        Product product = null;
        try{
            product = this.dao.findByProductID(product_id);
        }catch (Exception ex) {
            ex.printStackTrace();
        }finally {
            this.dbconn.close();
        }
        return product;
    }
}

```



### 数据存在枚举类

比如order订单表中,订单状态，会放在枚举类中

案例

```java
public enum SkuSoldStatusEnum {

    ON_SALE(1, "开团"),
    WAIT_SALE(2, "待开抢"),
    SOLD_OUT(3, "已抢光"),;

    private int code;
    private String desc;

    public static SkuSoldStatusEnum getByCode(int code) {
        return Stream.of(values()).filter(statusEnum -> statusEnum.getCode() == code).findFirst().orElse(null);
    }

}
```





### idea中创建web工程

课程里讲的那种右键的方式，我这边用不了。

先在原来的项目中，创建一个java的moudule,然后右键module ,add framework support ,

选中web application 4.0 之后工程就有web特殊目录了，然后在Web-INF下手动建立一个lib。



### idea中用tomcat运行项目

点击箭头，然后添加tomcat,然后点击平时的运行，就是运行tomcat了



# tomcat

目前主流tomcat版本是7.0和8.0版本，其中对应的sevlet和jdk

tomcat   servlet/jsp     jdk

5.5			2.5/2.1			5.0

7.0			3.0/2.2			6.0

8.0			3.1/2.3			7.0

sevlet2.5还是使用最多的版本使用xml配置 ,sevlet3.0之后使用的是注解配置

解Java Server Pages（JSP）的相关知识。JSP是一种用于创建动态Web内容的技术，它允许开发人员将Java代码嵌入HTML页面中，以便在服务器上动态生成Web页面。

JSP的一些主要特点包括：

- JSP页面可以包含任意数量的Java代码片段，这些代码片段可以用于执行各种任务，例如数据库查询、数据处理和业务逻辑。
- JSP页面可以使用标签库来简化页面开发。标签库是一组自定义标签，可以用于执行常见的Web任务，例如表单处理和URL重定向。
- JSP页面可以使用EL表达式（Expression Language）来访问JavaBean中的数据。EL表达式是一种简单的语法，用于从JavaBean中提取数据并将其显示在页面上





### 目录层级

bin可执行脚本   conf配置文件   lib运行jar包   logs日志目录   temp(运行时残生的临时数据)   webapps 用来存放部署的web工程

work目录     是tomcat工作时的目录，用来存放运行jsp翻译为servlet的源码

##### conf文件配置

在conf下的server.xml文件  ，有个<connector port="8080" 修改8080的默认端口号

##### bin下指令

./catalina  run 启动tomcat,这个是在前台运行tomcat	

./startup.sh  这个是后台运行tomcat

##### web部署

第一种学习的部署方式:在webapps建目录然后写html和css等，具体看官网自带的文件案例

第二种部署:在conf/catalina/localhost 下创建一个timor.xml ，里面写url路径,访问哪个html文件



### idea创建tomcat项目

配置tomcat ， 公共settings中，bulid/excution 下   application sever 中，点击加号指定tomcat路径

新建java ee项目，在新版叫做jakarta EE , template模版选择勾选web Application 默认是rest service,勾选web后会创建webapp目录

webapp目录是用来存放web工程的资源文件:html,css,js等

目录下的lib用来放第三方的jar包（idea的话需要自己配置导包）

web.xml文件是配置工程组件:servlet程序，filter过滤器，listener,session超时等



### idea集成tomcat

settings=>Bulid,excution=>Application Servers =>点击加号选中tomcat=>指定路径home

mac版本idea创建tomcat项目：

new project=>Jakarta EE(和网上的名字不同)=>Template选择Web Application=>Application Serve选择tomcat

=>点击下一步，把Jakarta EE 改为javaEE=>下方有个添加依赖的(默认勾选了servlet4.0)

windows版创建tomcat项目:

new project=>java Enterprise =>Application Serve选择tomcat =>勾选Web Application(4.0)



### 配置configration

配置tomcat的configration，里有个deployment下方的application context是url路径。➕号可以添加需要部署的web工程



### 问题记录

1 servlet访问404

mac最开始建立的javaweb项目，应该是没有勾选把Jakarta EE 改为javaEE=>下方有个添加依赖的(默认勾选了servlet4.0)

因为servlet的版本是5.0导致与tomcat8.5不匹配，导致访问是404，idea配置的自带servlet模版都是404。不过看不到报错信息



### 问题待解决



# servlet

servlet/filter/listener是框架的基层springboot

filter和listener是servelet底层，如何监听到访问然后回应访问的



servlet是运行在服务器是那个的小型java程序，用来接受和响应客户端请求。

servlet的创建，使用，销毁都由Servlet容器进行管理(如tomcat)，不需要main方法，在idea中写完Servlet接口，直接启动tomcat服务器即可

sevlet2.5还是使用最多的版本使用xml配置

sevlet3.0之后使用的是注解配置



### 实现Servlet接口

代码重写之后必须重新启动，静态资源不需要

第一种方法通过web.xml配置url和类的关系

```xml
    <servlet>
        <servlet-name>name1</servlet-name>
        <servlet-class>com.lpc.servlet.Servlet1</servlet-class>

    </servlet>
    <!--    -->
    <!-- 配置url   -->
    <servlet-mapping>
        <servlet-name>name1</servlet-name>
        <!-- 地址为http:localhost:8080/idea配置的context/url1  loclhost:8080/git_tomcat_servlet/url1      -->
        <url-pattern>/url1</url-pattern>
    </servlet-mapping>
```

第二种通过注解的方式配置url和类关系

```

```





### 问题记录

1   servlet接口没有

javax.[servlet](https://so.csdn.net/so/search?q=servlet&spm=1001.2101.3001.7020)不存在或未找到，程序包javax.servlet.http不存在或未定义等错误。原因是servlet和JSP均不是java平台javase（标准版）的一部分，而是JavaEE的一部分，因此必须告知编译器servlet的位置。

解决方法:从tomacat的lib中拷贝出servelet-api.jar ,在idea的project structure中的lib导入，这样代码就是导入了

2 同样的代码，用windows创建的tomcat没问题，mac创建的tomcat执行不了

servlet版本的问题，tomcat8.5，当时mac的servlet版本是5.0有问题

### 问题待解决

1 idea配置的tomcat可以直接运行，那么代码的servlet接口如果通过服务器部署呢？？具体操作

