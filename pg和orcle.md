

# dbeaver

```mysql
#表下钻
schema.tbName  control+鼠标左键
```



# mysql

#### 注意细节

```mysql
#like
%任意字符
_ 单一字符
like 后必须是'' 不能是""
like 'a_' a开头的2位长度
```



#### 字符串处理函数

```mysql
lower( name ) like '%lpc%'
upper( name ) 
```







# oracle(11r)

#### 细节

```mysql
#库.表
oracle中默认表名都是大些,如果sql中写的表名有小写，要加双引号  l

#字符串用 ''
字符串用'',不用双引号
```



#### 内置语法/函数

```mysql
#快速查询表
select * from ALL_ALL_TABLES where TABLE_NAME like '%TKH%'
然后下钻表

#字符串处理
模糊查询  like '%a%'
字符串拼接   'a' || 'b'

#数学函数


#日期函数

#流程控制

		-- case when
    CASE WHEN condition1 THEN result1
				WHEN condition2 THEN result2
        ELSE result_default
    END AS result







```



#### 存储过程demo

```mysql
在 Oracle 数据库中，存储过程是一组预编译的 SQL 语句，类似于函数，可以接受参数、执行 SQL 查询并返回结果。下面是一个简单的 Oracle 存储过程的格式示例：

CREATE OR REPLACE PROCEDURE prod_1 (p1 IN NUMBER, 
                                            p2 IN varchar(50):='默认值'  --有默认值，这个参数可以不传
                                            p3 OUT number,
                                            p4 out varchar(10)
                                           )
AUTHID CURRENT_USER IS  --以当前用户的权限运行
    -- 声明变量
    v_1 date;
    v_2 varchar(10) := '开始'; --初始化
    v_3 date :=sysdate; --初始化,通过调用系统函数来初始化
    V_4 NUMBER(8) := TO_DATE(parameter2, 'yyyymm'); --调用参数来初始化

BEGIN
    SELECT column_name INTO v_2   -- 查询结果写入v_2,如果返回多行数据，那么将会抛出一个异常。
    FROM t1 WHERE id = p1    
    EXCEPTION WHEN OTHERS THEN p3 := 0; --如果出现异常了,把p3赋值为0
   
   
   -- 将parameter3/4赋值,这个就是最后输出
    parameter3 := 0;
    parameter4 := '正常结束'
    
    
    COMMIT;  --提交事务，确保所有的更新被永久保存到数据库中


END prod_1;  --存储过程名字


在这个示例中：

- `CREATE OR REPLACE PROCEDURE` 用于创建或替换存储过程。
- `procedure_name` 是存储过程的名称。
- `(parameter1 IN datatype1, parameter2 OUT datatype2)` 定义了存储过程的输入和输出参数。
- `IS` 标志着存储过程的主体部分的开始。
- 在 `BEGIN` 和 `END` 之间是存储过程的主体，包括变量声明、SQL 查询和其他逻辑。
- `SELECT column_name INTO variable_name` 用于执行 SQL 查询并将结果存储在变量中。
- 存储过程可以包含更复杂的逻辑和多个 SQL 查询。
- `parameter2 := variable_name;` 用于将查询结果赋给输出参数。

请注意，这只是一个简单的示例。实际的存储过程可以更复杂，包括循环、条件语句等。存储过程的语法和功能在不同的数据库管理系统中可能会有所不同。
```

#### 模块解析

```mysql
UPDATE CRMII.TKHCBCS A
SET CBYE = CBYE + (  -- B表过滤月份并关联A表,sum(CBJE) 若没数据，用nvl判空，然后累加到CBYE
  									 -- 这个更新是针对每条数据的CBYE 满足条件的单独累加的
                    SELECT NVL( SUM(CBJE), 0) FROM CRM_XC.TKHCBLS B  
                    WHERE A.ID = B.CBID
                    AND B.MON >= I_MON
                  )
                  
WHERE EXISTS ( -- 这是一个条件，用于限制只有在子查询中存在至少一条记录时，外层的UPDATE操作才会执行。
               -- 这意味着如果没有任何TKHCBLS表中的记录满足条件B.MON >= I_MON，则不会更新任何TKHCBCS表中的记录。
              SELECT 1
              FROM CRM_XC.TKHCBLS B
              WHERE A.ID = B.CBID
              AND B.MON >= I_MON
);
```





# PostgreSQL

#### 问题待解决

```
1 在dm层,为什么一个月份一个表,不是单表然后多月份字段
2 pg查询pg_tables，查询的schema和dbeaver展示的不同呢
```



#### 注意细节

```mysql

```



#### 内置语法/函数

```mysql
#库表相关
以使用information_schema.tables视图或者pg_catalog.pg_tables系统表来执行查询
select * from pg_catalog.pg_tables where upper(tablename) like '%%'
--注意oracle的名字是大写,在pg中的名字是小谢

#分区表
在pg中也有分区表,一个总表，会自动建一些分区表
```



#### 存储过程

````mysql
PostgreSQL的存储过程（也称为函数）是一种强大的工具，可以用来执行各种数据库操作。以下是一个示例，展示了PostgreSQL存储过程的常见语法和关键字。请注意，并不是所有的关键字都会在每个存储过程中使用，因为它们依赖于你想要实现的具体功能。

```sql
CREATE OR REPLACE FUNCTION my_function(
    param1 INT,
    param2 TEXT DEFAULT 'default value'
)
RETURNS TABLE(column1 INT, column2 TEXT) -- 或者可以使用 RETURNS VOID, RETURNS INT 等
LANGUAGE plpgsql  -- 指定了使用的语言，通常是 PL/pgSQL
AS $$
DECLARE
    -- 声明局部变量
    variable1 INT;
    variable2 TEXT := 'initial value';
BEGIN
    -- 这里是存储过程的主体，可以包含复杂的 SQL 语句和逻辑控制

    -- 条件控制
    IF param1 > 100 THEN
        RAISE NOTICE 'param1 is greater than 100';
    ELSIF param1 > 50 THEN
        RAISE WARNING 'param1 is greater than 50 but not greater than 100';
    ELSE
        RAISE EXCEPTION 'param1 is not valid';
    END IF;

    -- 循环控制
    FOR variable1 IN 1..param1 LOOP
        -- 执行一些操作
        variable2 := variable2 || ' ' || param2;
    END LOOP;

    -- 使用查询结果
    FOR record IN SELECT * FROM some_table WHERE some_column = param2 LOOP
        -- 对每条记录进行处理
        -- ...
    END LOOP;

    -- 插入数据
    INSERT INTO another_table (column1, column2) VALUES (variable1, variable2);

    -- 更新数据
    UPDATE another_table SET column1 = variable1 WHERE column2 = param2;

    -- 删除数据
    DELETE FROM another_table WHERE column1 = variable1;

    -- 返回结果集
    RETURN QUERY SELECT variable1, variable2;

    -- 返回单个值
    -- RETURN variable1;

    -- 存储过程结束
    EXCEPTION
        WHEN OTHERS THEN
            -- 异常处理
            RAISE NOTICE 'An error occurred: %', SQLERRM;
            -- 可以选择是否退出
            -- RETURN;
END;
$$;

-- 调用存储过程
SELECT * FROM my_function(10, 'test');
```

这个存储过程包含了以下关键字和概念：

- `CREATE OR REPLACE FUNCTION`: 创建或替换一个函数。
- `RETURNS TABLE`: 指定函数返回一个表，也可以指定其他类型。
- `LANGUAGE plpgsql`: 指定使用的编程语言为PL/pgSQL。
- `DECLARE`: 声明局部变量。
- `BEGIN ... END;`: 定义函数的开始和结束。
- `IF ... THEN ... ELSIF ... THEN ... ELSE ... END IF;`: 条件语句。
- `LOOP ... END LOOP;`: 循环控制。
- `FOR record IN SELECT ... LOOP ... END LOOP;`: 遍历查询结果的循环。
- `INSERT INTO ... VALUES ...;`: 插入数据。
- `UPDATE ... SET ... WHERE ...;`: 更新数据。
- `DELETE FROM ... WHERE ...;`: 删除数据。
- `RETURN QUERY ...;`: 返回查询结果。
- `EXCEPTION WHEN OTHERS THEN`: 异常处理。

请记住，这只是一个示例，实际的存储过程将根据你的需求进行调整。在编写存储过程时，你需要根据实际的业务逻辑和数据库设计来决定使用哪些关键字和结构。

````

