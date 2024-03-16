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

# oracle

#### 细节

```mysql
库.表
oracle中默认表名都是大些,如果sql中写的表名有小写，要加双引号  l
```



# gp

#### 注意细节

```mysql

```

#### 视图

```mysql
#声明变量
declare
    v_job_nm character varying := 'dm.sp_jxkh_nor_crd_trade_m'; --作业名
    v_row_cnt numeric(28); --记录数据插入量
    
      --4.逻辑主体×××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××--

#逻辑主体  
  begin
  --变量赋值
    v_start_dt := coalesce(cast($1 as date),current_date-1);
    v_return_code := 0
    select min(cal_date) 
      into v_first_monthday
    from dwd.dim_calendar t
    where month_date = rec.trade_day;
    
#异常捕获

```

