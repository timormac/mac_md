# mybatis简介

1，mybatis作用，把数据库中的一个表对应称一个实体类对象

2.优势，原本通过jdbc数据库操作，是java与sql耦合，如果有一个sql需要变动，只能改原码，mybatis可以优化这一个



mybatis是通过xml操作sql的，与java代码分开





# 接口直接调用

```java
public interface Inter1 {
    @Select("select sum(order_activity_reduce_amount)
            "from dws_trade_order_window\n" +
            "group by toYYYYMMDD(stt);")
    List<ActivityReduceStats> m1(@Param(value = "date")Integer date);
}

@Service
public class Activitympl  {

  	//这里没有声明对象，却能直接调用方法，因为@Autowired注解，进行自动装配。这意味着Spring框架会在运行时自动为该字段注入一个实例。
    @Autowired
    private Inter1 mapper;

    //没有去实现Inter接口直接就调用了
    public List<ActivityReduceStats> getActivityStats(Integer date) {
        return mapper.m1(date);
    }
}

在这段代码中，@Select注解指定了一个SQL查询语句，而m1方法则充当了这个查询语句的执行入口。当调用m1方法时，MyBatis会自动解析注解中的SQL语句，并执行该查询。

MyBatis框架会在运行时动态生成一个实现了Inter1接口的代理对象，该代理对象会根据注解中的信息执行相应的SQL查询，并将结果映射到指定的返回类型（在这里是List<ActivityReduceStats>）中。

因此，你可以直接调用inter方法来执行该查询，而无需手动编写实现类。这种方式使得数据库操作更加简洁和方便。


```

# 单一实现的service接口

为什么有的service接口只有一个实现类，还有单独提出来



1. **解耦合**：通过将接口和实现类分离，可以将业务逻辑与具体的实现解耦。接口定义了一组合同的方法，而实现类负责具体实现这些方法。这样的设计使得代码更加模块化和可维护，可以方便地对接口和实现类进行修改和扩展，而不会影响到其他部分的代码。
2. **多态性**：接口和实现类的分离为多态性提供了基础。通过面向接口编程，可以将不同的实现类对象当作同一个接口类型来使用，从而实现灵活的代码扩展和替换。
3. **依赖注入**：将接口作为依赖注入的类型，而不是具体的实现类，可以使代码更加灵活和可测试。通过依赖注入，可以在不修改代码的情况下替换实现类，实现不同的业务逻辑，或者在测试时使用模拟对象。
4. **代码复用**：通过接口和实现类的分离，可以在不同的场景下复用相同的接口。例如，可以为不同的数据库提供不同的实现类，而接口的调用方无需关心具体的实现细节。

虽然在某些情况下，一个接口只有一个实现类可能看起来有些多余，但这种设计方式提供了更好的灵活性和可扩展性，使得代码更易于维护和扩展。此外，这种设计符合面向对象的原则，如依赖倒置原则和单一职责原则，有助于提高代码的质量和可读性。



**依赖注入案例**

当使用接口作为依赖注入的类型时，可以在不修改代码的情况下替换实现类，从而实现不同的业务逻辑或在测试时使用模拟对象。以下是一个简单的示例：

假设我们有一个接口 `MessageSender` 和两个实现类 `EmailSender` 和 `SmsSender`，它们分别用于发送电子邮件和短信。

```java
public interface MessageSender {
    void sendMessage(String message);
}

public class EmailSender implements MessageSender {
    public void sendMessage(String message) {
        // 发送电子邮件的具体实现逻辑
        System.out.println("Sending email: " + message);
    }
}

public class SmsSender implements MessageSender {
    public void sendMessage(String message) {
        // 发送短信的具体实现逻辑
        System.out.println("Sending SMS: " + message);
    }
}
```

现在，我们有一个 `NotificationService` 类，它依赖于 `MessageSender` 接口来发送通知消息。

```java
public class NotificationService {
  
 public static void main(String[] args) {
    MessageSender emailSender = new EmailSender();
    NotificationService emailNotificationService = NotificationService(emailSender);
    emailNotificationService.sendNotification("Hello, this is an email notification.");

    MessageSender smsSender = new SmsSender();
    NotificationService smsNotificationService = NotificationService(smsSender);
    smsNotificationService.sendNotification("Hello, this is an SMS notification.");
}
  
    public static NotificationService(MessageSender messageSender) {
        this.messageSender = messageSender;
    }
  
}
```

在上面的示例中，我们可以轻松地替换 `MessageSender` 的实现类，例如从 `EmailSender` 切换到 `SmsSender`，而不需要修改 `NotificationService` 类的代码。这使得代码更加灵活，可以根据需要选择不同的实现类。

另外，在测试时，我们可以使用模拟对象来替代真正的实现类，以便更好地控制和验证测试的行为。

```java
public class MockMessageSender implements MessageSender {
    public void sendMessage(String message) {
        // 模拟发送消息的逻辑
        System.out.println("Mock message sender: " + message);
    }
}

public static void main(String[] args) {
    MessageSender mockSender = new MockMessageSender();
    NotificationService notificationService = new NotificationService(mockSender);
    notificationService.sendNotification("Hello, this is a mock notification.");
}
```

通过使用模拟对象，我们可以在测试过程中捕获发送的消息，并验证代码的行为是否符合预期，而无需实际发送消息到外部系统。这样可以使测试更加可控和可靠。

