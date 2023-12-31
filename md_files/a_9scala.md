# 学习进度

视频代码看到chapter6的04到第二个高阶函数

# 问题待解决

#### case object使用场景

类中有参和无参，当类有参数的时候，用case class，当类没有参数的时候用case object

无参的时候，我们创建一个无参case class，然后new一个object不是一样吗，非弄一个case object

#### class如何定义多参构造器

#### 隐式转换问题

隐式函数的作用域2.max(1),在什么地方能用

隐式参数没看懂

#### 修改抽象类中非抽象属性

//这里有个问题就是重写非抽象属性,用var 声明的name 下面改写不了

看代码里A4_AbstractClass

#### Array没看懂

//源码没看懂，懂为什么能动态传参数,只有一个apply构造器,参数是Array(_length)是什么意思

#### 范型没看懂

逆变，协变什么的，上下文限定



#### 用Array接String[]

scala中的String.spilit方法，类型推断是Array[String] ,实际返回的是String[] ,奇怪



#### 传名参数没看懂

```scala
//withScope方法  
private[spark] def withScope[U](body: => U): U = RDDOperationScope.withScope[U](sc)(body)

//private[spark]修饰符意味着这个withScope方法是私有的，但在spark包及其子包中是可见的。这是Spark内部API的一部分，不应该在Spark外部的应用程序代码中使用。




//map方法，方法体是调用withScope{...}格式
def map[U: ClassTag](f: T => U): RDD[U] = withScope {
    val cleanF = sc.clean(f)
    new MapPartitionsRDD[U, T](this, (_, _, iter) => iter.map(cleanF))
  }

在Scala中，可以使用花括号 {} 来定义一个代码块，这个代码块可以作为一个参数传递给方法。在你提供的代码中，withScope 方法接受一个名为 body 的参数，类型为 => U，表示这是一个传名参数（by-name parameter）。

传名参数是一种特殊的参数，它不会立即被求值，而是在方法内部使用时才会被求值。这种延迟求值的特性使得 withScope 方法可以接受一个代码块作为参数，而不需要立即执行它。
```



# 问题记录(待回顾)

#### java实现柯里化失败

开始的时候接口用的是object类，以为Obj可以接住所有类型。

但是实现接口方法时发现,参数类型为Integer时，是重载而不是实现，参数类型Object才实现接口

解决方法方法的返回值和参数都是范型来定义

#### 错误理解参数函数

```scala
//在spark的mapPatitionWithIndex方法中
  def mapPartitionsWithIndex[U: ClassTag](f: (Int, Iterator[T]) => Iterator[U]) : RDD[U] = withScope { }

这里的参数类型是个函数，函数是2个参数,一个int，一个迭代器, 参数函数的返回值是迭代器

而我调用方法时,把这个参数的函数类型，当作了一个元组类型，所以调用_._1没有提示。
```





# 问题已记住(备份)

```mysql
#### .var不自动声明返回值
.var时勾选specify type ,或者配置自动勾选
```





# scala与java对比

#### scala快速编程

```sql
#元组
tuple = ("aa",1,2)

#函数使用
java中想弄个函数模块, 要定义内部类，编写方法，创建对象，调用。
scala直接定义即可

#参数默认值，指定传参数
scala设置函数默认值，建设有4个参数，均有默认值。调用函数时指定传值使用
而java想实现这种，需要重载很多方法
```

#### 简洁对比

下面都是scala底层做了很多操作，和python很像都是函数式编程

def局部函数,可以不用写内部类，再去创建对象

函数的参数默认值，指定参数传参数,可以不用写方法重载

函数的参数可以是函数，省了建类建方法的过程

函数的返回值可以是函数，装饰器功能简洁

```scala
//装饰器功能
def funcReturnFunc( f:Int=>Int ) = {
  //将f函数功能又做了操作
  def newFunc( i:Int, fc:Int=>Int ) = fc(i)*10
  newFunc _
}
```

优势：def局部函数  , 元组("a",1,3,4)  ,lamda表达式更简介全面



#### 语法对比

lamda表达式



# scala源码解读

#### 官网学习scala步骤

官网=>reference=>scala2 language specification里面就是语法

#### 范型

```mysql
#类范型
class RDD[T: ClassTag]{}

#方法范型
def map[U: ClassTag](f: T => U): RDD[U] = {}

#这个方法范型看不懂
def map[B, That](f: A => B)(implicit bf: CanBuildFrom[Repr, B, That]): That = {}

map是一个泛型方法，它有两个类型参数：B和That。
f: A => B是一个函数参数，它接受一个类型为A的元素并返回一个类型为B的结果。
(implicit bf: CanBuildFrom[Repr, B, That])是一个隐式参数，它指定了如何构建返回的新集合。
That表示返回的新集合的类型，Repr表示原始集合的类型。
方法体为空，需要根据具体的集合类型和返回类型来实现具体的转换逻辑
```

#### spark中map方法

```scala
//withScope方法  
private[spark] def withScope[U](body: => U): U = RDDOperationScope.withScope[U](sc)(body)

//private[spark]修饰符意味着这个withScope方法是私有的，但在spark包及其子包中是可见的。这是Spark内部API的一部分，不应该在Spark外部的应用程序代码中使用。




//map方法，方法体是调用withScope{...}格式
def map[U: ClassTag](f: T => U): RDD[U] = withScope {
    val cleanF = sc.clean(f)
    new MapPartitionsRDD[U, T](this, (_, _, iter) => iter.map(cleanF))
  }

在Scala中，可以使用花括号 {} 来定义一个代码块，这个代码块可以作为一个参数传递给方法。在你提供的代码中，withScope 方法接受一个名为 body 的参数，类型为 => U，表示这是一个传名参数（by-name parameter）。

传名参数是一种特殊的参数，它不会立即被求值，而是在方法内部使用时才会被求值。这种延迟求值的特性使得 withScope 方法可以接受一个代码块作为参数，而不需要立即执行它。
```





# ——————编码————————

# 学习scala步骤

### scala特点

```
Scala 语言适合并发和分布式编程的原因有几个方面：

1. **函数式编程特性**：Scala 是一种结合了面向对象和函数式编程的语言。函数式编程特性，如不可变性（immutability）和高阶函数，使得并发编程更加安全和简洁，因为它们减少了共享状态和副作用，这是并发编程中常见的问题源。

2. **Actor 模型**：Scala 通过 Akka 框架提供了 Actor 模型的实现。Actor 模型是一种并发模型，其中每个 actor 是一个并发实体，它们通过消息传递来通信，避免了共享状态。这种模型非常适合分布式系统，因为它可以很自然地扩展到多机环境。

3. **类型安全**：Scala 的强类型系统可以在编译时捕获许多并发和分布式编程中可能出现的错误，这有助于开发者编写更加健壮的代码。

4. **兼容性**：Scala 完全兼容 Java，可以无缝地使用所有的 Java 类库和工具。这意味着可以在 Scala 项目中利用已经存在的 Java 生态系统，包括用于并发和分布式的库和框架。

关于 Apache Flink 部分模块使用 Scala 而不是 Java 的原因，可能有以下几点：

1. **简洁性**：Scala 代码往往比 Java 更加简洁，特别是在处理复杂的数据处理流水线时。Flink 的 API 设计可以通过 Scala 的语法糖和函数式编程特性来实现更加简洁和表达性强的代码。

2. **类型推断**：Scala 的类型推断机制可以让开发者在编写 Flink 应用时写出类型安全而又不啰嗦的代码，提高开发效率。

3. **模式匹配**：Scala 的模式匹配对于处理复杂的数据结构和算法非常有用，这在流处理和复杂事件处理中尤其常见。

4. **集合操作**：Scala 提供了丰富的集合操作，这些操作在流处理中非常有用。Flink 中的许多数据转换可以直接利用 Scala 的集合 API 来实现，这使得代码更加直观和高效。

5. **社区偏好**：Flink 社区可能有很多 Scala 用户，他们偏好使用 Scala 来扩展和改进 Flink。社区的贡献和偏好通常会影响开源项目的发展方向。

总的来说，Scala 提供了许多适合并发和分布式编程的特性，这些特性也使得它成为开发复杂的 Flink 应用的一个很好的选择。然而，这并不意味着 Java 不再被使用；实际上，Flink 仍然支持使用 Java 进行开发，并且许多 Flink 应用仍然是用 Java 编写的。选择 Scala 或 Java 通常取决于项目需求、开发团队的技能和偏好。
```

### 学习scala步骤

```mysql
Scala确实在某些方面比Java更复杂，尤其是因为它结合了面向对象编程和函数式编程的特性。Scala的语法也更加灵活和简洁，这可能会让习惯了Java那种更加冗长和直接的代码风格的开发者感到困惑。不过，理解Scala的几个关键概念可以帮助你更好地阅读和理解Scala代码。

1. **Object和Class**：
   Scala中的`object`是一个单例对象的声明，它相当于Java中的静态成员的集合体。当你声明一个`object`时，Scala会自动为你创建一个类型和一个该类型的唯一实例。而`class`则和Java中的类相似，用来创建多个不同的实例。

2. **伴生对象和伴生类**：
   在Scala中，`class`和同名的`object`可以互为伴生，即一个`class`和一个`object`可以拥有相同的名字，它们必须定义在同一个文件中。`class`是类型的定义，而`object`通常包含静态成员和静态方法，类似于Java中的静态方法。伴生对象可以访问伴生类的私有成员，反之亦然。

3. **apply方法**：
   `apply`方法在Scala中非常特殊，它让你可以像调用函数一样调用对象。当你使用`ObjectName()`时，实际上是在调用这个对象的`apply`方法。这个特性常常用于伴生对象，以提供一种简洁的创建类实例的方式，而无需使用`new`关键字。

为了更好地理解Scala代码，以下是一些建议：

- **逐步学习Scala的语法**：花时间逐步学习Scala的基础语法，从简单的概念开始，逐渐过渡到更复杂的特性，比如隐式转换、模式匹配、特质（Traits）等。

- **实践编程**：尝试写一些Scala程序，从简单的开始，比如"Hello, World!"，然后逐步增加复杂性。编程实践是理解语言的最佳方式之一。

- **阅读和分析现有的Scala代码**：找一些开源的Scala项目，阅读和尝试理解它们的代码。开始时，你可以从简单的代码片段开始，逐渐过渡到整个项目。

- **使用IDE**：使用集成开发环境（IDE）如IntelliJ IDEA的Scala插件。这些工具通常提供代码高亮、自动完成、快速查看定义等功能，可以帮助你更好地理解代码。

- **参考文档和书籍**：阅读Scala的官方文档以及其他高质量的Scala书籍。《Programming in Scala》是一本不错的入门书籍。

- **加入社区**：参与Scala社区，比如论坛、Stack Overflow、Reddit等，可以让你在遇到问题时寻求帮助，同时也能让你了解到更多的最佳实践。

- **有耐心**：任何新技能的学习都需要时间和耐心，尤其是对于一门具有相当深度的编程语言，如Scala。不要期望一蹴而就，给自己一些时间去适应。

记住，每个人学习新事物的速度都不一样。保持耐心，持续实践，随着时间的推移，你会发现Scala代码变得越来越容易理解。
```



# 环境准备

安装scala

scala安装包解压，然后配置环境变量  vim ~/.bash_profile    export PATH=$PATH:scala/bin



idea配置scala

settings=>plugins=>搜索scala下载=>project structure =>Global libarys=>点击加号添加scala依赖 

直接右键项目目录，选择add framwork support 添加scala既可以



常用关键字

•  trait, extends, with, type, for

•  private, protected, abstract, sealed, final, implicit, lazy, override

•  try, catch, finally, throw 

•  if, else, match, case, do, while, for, return, yield

•  def, val, var 

•  this, super

•  new

•  true, false, null



# 方法参数类型

```mysql
在Scala中，方法参数可以采取多种形式，包括：

#1. **普通参数**：
   def add(a: Int, b: Int): Int = a + b

#2. **函数参数**：
   def operateOnNumbers(operation: (Int, Int) => Int): Int = operation(1, 2)

#3. **可变参数**：
   def printAll(strings: String*): Unit = strings.foreach(println)
   
#4. **使用方法时,按参数名赋值，不按顺序**
   def printName(first: String, last: String): Unit = {}
   printName(first = "Jane", last = "Doe")

#5. **参数默认值**：
   def greet(name: String = "World"): Unit = println("Hello, " + name + "!")

#6. **隐式参数**：方法可以有一个隐式参数列表，这些参数由编译器自动填充。
   def doSomethingWithImplicit(implicit ctx: Context): Unit = ...

#7. **按名参数（by-name parameters）**：方法参数可以是按名传递，而不是按值传递。这意味着参数表达式在方法内部每次被引用时才会被计算。

   def myMethod(param: => Int): Unit = {
     // param在这里每次使用时都会被重新计算
   }

```



# 闭包和柯里化

闭包

代码实现有问题，后续再解决

```java
//因为def实现是创建一个内部类，然后实现函数方法。
//在函数内创建变量，相当于再内部类声明一个属性
//函数内创建函数，相当于又声明一个内部类。所以内部类能掉上层类的属性很正常，这就是闭包

//闭包代码
    def lamda1(a:Int): Int=>Int  = {
      def lamda2(b:Int) = a + b
      lamda2 _
    }
//实现代码如下：
class  innerLamdaA{
  //传进来的参数
  Interger  a ;
  //实现lamda1方法,返回值是int
  InnerLamdaB lamadaMethod_a(Interger args){
    	//方法内部再建内部类
    	class InnerLamdaB{ 
     		int b ;
        //实现lamdaB方法,返回值是InnerLamdaB类型
      	Interger lamadaMethod_b(Interger args){
            return a+b ;
        }
     }
    //返回函数对应对象
     return  new InnerLamdaB() ;
  } 
}
```



柯里化

```java
//返回类型如果把括号省略就很像迭代式，不过不便于阅读 Int => Int => Int
//实际上第一个参数的返回值是 （Int） => (Int => Int) 这种便于阅读
def add_three(x: Int) = (y: Int) => (z: Int) => x + y + z
val adda: Int => (Int => Int) = add_three(1)
val addb: Int => Int = adda(2)
val res: Int = addb(3)

//闭包代码
    def lamda1(a:Int): Int=>Int  = {
      def lamda2(b:Int) = a + b
      lamda2 _
    }


//闭包实现

interface  LamdaFace<R,In>{
    R lamdaMethod( In obj);
}

public class LamdaRealize {
    public static void main(String[] args) {
        //内部类
        class  innerLamdaA implements LamdaFace< LamdaFace<Integer,Integer> , Integer > {
            //传进来的参数
            Integer  a ;
            //重写接口方法
            @Override
            public LamdaFace<Integer,Integer> lamdaMethod(Integer obj) {
                a = obj;
                //方法内部再建内部类
                class InnerLamdaB implements LamdaFace<Integer,Integer> {
                    Integer b ;
                    public Integer lamdaMethod(Integer obj) {
                        b = obj;
                        return a + b ;
                    }
                }
                //返回一个对象
                return  new InnerLamdaB() ;
            }
        }
        innerLamdaA FuncClass = new innerLamdaA();
        LamdaFace<Integer,Integer> func1 = FuncClass.lamdaMethod(1);
        Integer integer = func1.lamdaMethod(2);
        System.out.println( integer);
    }
}
```

# 隐式转换

隐式转换的前提就是不能有二义性，就是同一个需要转变的，有多个方法都满足

### 隐式函数

隐式函数有切只有一个参数

```scala
  //隐式函数有切只有一个参数，当没有隐身式f1函数时,下面编译会报错
  implicit  def f1(d:Double):Int = d.toInt
  //scala会自己找，有没有把double变int的函数，然后找到f1了
  val num :Int = 3.5
  //结果是3
  println(num)

  注意如果当前环境，声明了多个隐式函数，都瞒住doule转Int，那么报错

//另一种写法,implicit变量去接lamda表达式
implicit val intToDouble: Int => Double = _.toDouble
```

隐式转换的注意事项和细节
隐式转换函数的函数名可以是任意的，隐式转换与函数名称无关，只与函数签名（函数参数类型和返回值类型）有关。

隐式函数可以有多个(即：隐式函数列表)，但是需要保证在当前环境下，只有一个隐式函数能被识别



### 隐式转换丰富类库功能

```scala
class MySQL{
  def insert(): Unit = {println("insert")
}
class DB {
  def delete(): Unit = println("delete")
}
implicit def addDelete(mysql:MySQL): DB = {
     new DB 
}
val mysql = new MySQL
mysql.delete()

```

如果需要为一个类增加一个方法，可以通过隐式转换来实现。（动态增加功能）比如想为MySQL类增加一个delete方法

在当前程序中，如果想要给MySQL类增加功能是非常简单的，但是在实际项目中，如果想要增加新的功能就会需要改变源代码，这是很难接受的。而且违背了软件开发的OCP开发原则 (开闭原则 open close priceple)

在这种情况下，可以通过隐式转换函数给类动态添加功能

### 隐式参数

当一个变量声明为implicit，并且 函数的参数声明为implict并且他俩类型符合，调用方法时，可以省略参数直接参数

注意当前环境下只能有一个变量满足，若声明2个会报错

```scala
object ImplicitVal02 {
  def main(args: Array[String]): Unit = {
      implicit val name1: String = "Scala"
    //会报错
   	// implicit val name2: String = "Scala"
      def hello(implicit content: String = "jack"): Unit = {
        println("Hello " + content)
      }
    //这里不用加参数，虽然hello是个有参函数
      hello
    }
}
```

这样在函数调用时可以省略参数列表。这在需要在多个函数之间共享上下文或配置信息时非常有用。例如，可以定义一个隐式值作为数据库连接，然后在多个函数中使用该连接，而无需显式传递它作为参数。

### 隐式类

隐式类使用有如下几个特点：

1 其所带的构造参数有且只能有一个
2 隐式类必须被定义在“类”或“伴生对象”或“包对象”里，即隐式类不能是 顶级的(top-level objects)。
 3 隐式类不能是case class（case class在后续介绍 样例类）
4 作用域内不有与之相同名称的标识符

```scala
class MySQL1 {}

//DB1会对应生成隐式类
implicit class DB1(val m: MySQL1) {
  def addSuffix(): Unit = print(1)
}
val mysql1 = new MySQL
//可以调用DB1的全部方法
mysql1.addSuffix()
```



# 语法

### 数据类型

```sql
基层类:  Any   AnVal  AnyRef  Null   Nothing

Any 是最上级父类，是AnVal  AnyRef 的父类

#注意Unit也是AnyVal子类
基本类型:Unit, Short,Char,Boolean, 都是AnyVal的子类

引用类型:集合类, Java中所有类,自定义Class,都是AnyRef的子类

Null 是所有引用数据类型的子类,对于自定义Class 我们可以传Null进去

Nothing 是所有类型子类，也包含Null

#注意java的基本类型 int,char ,boolean 等不是真正意义的对象,也看不到源码
```



### 返回值类型

Unit   表示无值,等同与void,只有一个实例 写成()

Null  空值，只有一个实例null

Nothing  是任何类型的子类可以接任何

### 函数/方法

函数和方法的区别：在类中的是方法，方法可以重载。在方法或者函数中定义的叫函数,函数不能重载会报错

注意scala中的函数能直接调用，底层其实是创建了内部类，然后创建一个类对象，再调用的方法

所有def出来的函数，我们是可以用变量去接的，需要用func _，func()接到的是返回值



### trait

java中没有多继承，只能单继承，不过可以接口多实现。

scala中没有接口这东西,也只能单继承。通过with 特质 在继承时，添加功能

trait和接口很像，不过写法不同

```

```









# Class/Obj/Case

object/class

scala 为了表明完全面对对象，删除了static方法,类可以有直接调用的方法不合理,必须创建object对象才能调用

伴生对象object的设计理念就是，使static方法和类分开，类不应能直接调用方法，,obj其实是类的单例实现。

当只有object没有同名class时,scala底层会创建一个类

当有Class的名称和Object时，obj是class的伴生对象 ,注意伴生对象和伴生类只能在一个文件中

```scala
object Demo{
}
```

（1）单例对象不能带参数，类可以

（2）对象和类名一样时，object被称为伴生对象，class被称为伴生类

（3）类和伴生对象可以相互访问其私有属性，但是它们必须在一个源文件中

（4）类只会被编译，不会被执行；要执行，必须在object中,main方法在obj中写



case class

  加入case字段后，scala会对我们创建的Class 进行如下封装操作

（1）构造器中的参数如果不被声明为var的话，它默认是val类型的，但一般不推荐在构造器中的参数声明为var

（2）自动创建伴生对象，同时在里面实现子apply方法，使得在使用的时候可以不直接显示地new对象

（3）伴生对象中同样会实现unapply方法，从而可以将case class应用于模式匹配

（4）实现自己的toString、hashCode、copy、equals方法



class 与case class区别

（1）case class初始化的时候可以不用new，也可以加上，但是class必须加new

（2）默认实现了equals、hashCode方法

（3）默认是可以序列化的，实现了Serializalbe

（4）自动从scala.Product中继承一些函数

（5）case class构造函数参数是public的，可以直接访问

（6）case class默认情况下不能修改属性值

（7）case class最重要的功能，支持模式配置，这也是定义case class的重要原因



case object

类中有参和无参，当类有参数的时候，用case class，当类没有参数的时候用case object





















### 







