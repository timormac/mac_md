#### JDK与jre

当谈到Java开发环境时，我们通常会提到JDK（Java Development Kit）和JRE（Java Runtime Environment）。下面是对它们的详细解释：

JDK（Java Development Kit）是Java开发工具包，它提供了用于开发、编译和调试Java应用程序的工具和资源。JDK包含以下主要组件：

1. 编译器（javac）：JDK中包含的Java编译器将Java源代码（以.java文件形式）编译成Java字节码（以.class文件形式），这是Java程序的中间形式。

2. 运行时环境（JRE）：JDK中包含了完整的JRE，因此可以直接运行Java程序。

3. 调试器（jdb）：JDK提供了一个命令行调试器，可以帮助开发人员在开发过程中诊断和调试Java程序。

4. 开发工具：JDK还包含了一些开发工具，如JavaDoc（用于生成API文档）、Java源代码管理工具（如javap、javah等）等。

总结来说，JDK是Java开发人员必备的工具包，它包含了编译器、运行时环境和其他开发工具，用于开发、编译和调试Java应用程序。

JRE（Java Runtime Environment）是Java运行时环境，它是在计算机上运行Java应用程序所必需的。JRE包含了Java虚拟机（JVM）和Java类库，它提供了运行Java程序所需的基本功能。

JRE的主要组件包括：

1. Java虚拟机（JVM）：JVM是Java程序执行的核心组件，它解释和执行Java字节码，并提供了内存管理、垃圾回收等功能。

2. Java类库：JRE包含了一系列的Java类库，提供了丰富的API（应用程序接口），用于开发各种类型的Java应用程序。

简而言之，JRE是用于运行Java应用程序的环境，它包含了Java虚拟机和Java类库。如果你只想运行Java程序而不进行开发，那么只需要安装JRE即可。而如果你希望进行Java应用程序的开发，那么需要安装JDK，因为JDK包含了JRE以及用于开发的其他工具和资源。



#### 无效的引用对象

什么是无用的引用对象，例如当你创建个ArrayList 你添加了10个元素导致扩容了，那么原先的底层数组就无人引用了，如果没有垃圾回收,会浪费内存。