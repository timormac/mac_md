--问题汇总
1 sink_mid用在哪里了？以解决,soure和sink后面名字同的，就是用同一个表
2 group by + ROW_NUMBER()写法能执行，逻辑是什么，要干什么
3 很多字段groupby 过滤出来,然后过滤rk = 1 ,有冗余操作,913 行开始的sql
4 sink_stream_mot_e_event_flow_smot_mot_mid和sink_stream_mot_e_event_flow_smot_cc_mid执行2次，8分钟和30分钟
5 没必要弄那么多中间topic，用tempview就可以，内存去存。

"----------------------------------------------------------------------------------------------"
--逻辑整理
select  
event_id,
ROW_NUMBER() OVER(PARTITION BY mobile,occur_date order by occur_time) rn
from (

      select  
      mobile,
      occur_date,
      lastvalue(event_id) as event_id,
      --lastvalue获取全部字段
      from source_stream_mot_e_event_flow_smot_mot_mid
      group by mobile,occur_date
) t2

按手机号和occur_date分组,并且按occur_time排序，取第一条
每个手机号在不同日期的消息，只有最早时间的第一条数据rk是1，这个rk不会变,所以能保证每个手机每天只有一条数据


"----------------------------------------------------------------------------------------------"
sink_stream_crhkh_crh_wskh_mid   kafka中间表
--数据源是kafka源rt_crhkh_crh_wskh_userqueryextinfo
--按手机号和流程点，过滤只取一条
"----------------------------------------------------------------------------------------------"

sink_stream_mot_e_event_flow_smot_cc_mid     kafka中间表
--279行和59行是一个sql,执行了2次???? 一个30分钟,1个8分钟
--数据源是kafka源：source_stream_crhkh_crh_wskh_mid
--关联维度表等7个
--先会话窗口8分钟,按user_id和手机号groupby，其他的字段用lastValue()，每中断30分钟就会有一条数据。
--然后按8个字段groupby，并开窗口row_number,取rk=1,这样只有一条数据

"----------------------------------------------------------------------------------------------"
sink_stream_mot_e_event_flow_smot_cc
--517
--数据源是kafka源:source_stream_mot_e_event_flow_smot_cc_mid
--先按mobile,occur_date进行group by 
--然后PARTITION BY mobile,occur_date 按occur_time排序取第一条,
--如果是按进入时间，那么rk不会变化，mobile,occur_date相同的只输出一条
--这里的group by 没有必要了,被覆盖

"----------------------------------------------------------------------------------------------"
e_event_flow_stream
--578
--数据源是 kafka源表  source_mot_stream_account_break_ths_cc  
--做了一个拼接字段操作，无其他操作

"----------------------------------------------------------------------------------------------"
sink_stream_mot_e_event_flow_smot_mot_mid
--602行
--数据源kafka源：source_stream_crhkh_crh_wskh_mid
--关联维度表只有4个
--会话窗口30分钟,按user_id和mobile_tel进行groupby，其他的字段用lastValue()，每中断30分钟就会有一条数据。
----然后按8个字段groupby，并开窗口row_number,取rk=1,这样只有一条数据

"----------------------------------------------------------------------------------------------"
sink_stream_mot_e_event_flow_smot_mot_mid
--747行
--和602插入同一个表,一个30分钟一个8分钟
--数据源kafka表：source_stream_crhkh_crh_wskh_mid
--关联维度表只有4个
--会话窗口8分钟,按user_id和mobile_tel进行groupby，其他的字段用lastValue()，每中断8分钟就会有一条数据。
--然后按8个字段groupby，并开窗口row_number,取rk=1,这样只有一条数据


"----------------------------------------------------------------------------------------------"
sink_stream_mot_e_event_flow_smot
--913行
--数据源是kafka源source_stream_mot_e_event_flow_smot_mot_mid
--先group by mobile,occur_date 然后通过lastValue获取全部字段
--开窗ROW_NUMBER() 按mobile,occur_date分区(因为和groupby分组一样,感觉冗余了)按accur_time排序 取rk第一条
"----------------------------------------------------------------------------------------------"
e_event_flow_stream
--977行
--数据源 source_mot_stream_account_break_ths
--做个concat拼接，无过滤其他等操作


"----------------------------------------------------------------------------------------------"
--去重，一个用户一个断点多条记录，一天只发一次
 insert into sink_stream_crhkh_crh_wskh_mid
	SELECT
	*
	from (
	SELECT
		ROW_NUMBER() 
		OVER(PARTITION BY mobile_tel,business_flag_last,channel_code,to_date(last_update_detetime) 
			order by last_update_detetime) rn
	from rt_crhkh_crh_wskh_userqueryextinfo              
	) t 
	where t.rn = 1; 

"----------------------------------------------------------------------------------------------"
279 行
--全部渠道:cc
--中断步骤非视频见证 business_flag_last not in ('22109', '22144', '22108', '22182', '22160')  
insert into sink_stream_mot_e_event_flow_smot_cc_mid
  select c3.event_id,
         c3.event_name,
         c3.client_name,
    from (
            select 
            c2.client_name,
            c2.channel_name,
            c2.branch_name,
            --select 8个groupby字段
            ROW_NUMBER() OVER(PARTITION BY c2.mobile_tel, c2.channel_code order by c2.done_time_d) rn
            from (
                     select
                           dim_blacklist.id_no as id_no,
                           dim_basic_info.id_no as id_no2,
                           a2.birthday as birthday,
                           a2.request_no
                     from (
                              SELECT 
                                   mobile_tel,
                                   user_id,
                                   lastvalue(channel_code) as channel_code,
                              from source_stream_crhkh_crh_wskh_mid
                              group by SESSION(PROCTIME, INTERVAL '8' MINUTE),mobile_tel,user_id

                          ) a2
                          left join dim_crhkh_crh_channeldefine dim_channel  --关联4张维度表
                          on a2.channel_code = dim_channel.channel_code
               ) c2
               group by c2.client_name,c2.channel_name  --按需要的8个字段group by 
        ) c3
   where c3.rn = 1;

"----------------------------------------------------------------------------------------------"
517 行
--CC渠道去重
--先按mobile,occur_date进行group by 
--然后PARTITION BY mobile,occur_date 按occur_time排序取第一条,
--如果是按进入时间，那么rk不会变化，mobile,occur_date相同的只输出一条

insert into sink_stream_mot_e_event_flow_smot_cc
select  event_id,
from (
          select  
          event_id,
          mobile,
          occur_date,
          ROW_NUMBER() OVER(PARTITION BY mobile,occur_date order by occur_time) rn
          from (
                    --来一条输出一条
                    select  mobile,
                    occur_date,
                    lastvalue(event_id) as event_id,      
                    from source_stream_mot_e_event_flow_smot_cc_mid
                    group by mobile,occur_date
          ）t1 
)t1_cc
where t1_cc.rn = 1;

"----------------------------------------------------------------------------------------------"
602 行
--全部渠道:mot
--中断步骤为视频见证 business_flag_last in ('22109', '22144', '22108', '22182', '22160')
insert  into sink_stream_mot_e_event_flow_smot_mot_mid
select 
c3_mot_v.event_id,
--8个字段
from (
    select  
    c2_mot_v.client_name,
    --groupby后的8个字段
    ROW_NUMBER() OVER(PARTITION BY c2_mot_v.mobile_tel, c2_mot_v.channel_code order by c2_mot_v.done_time_d) rn
    from (
        select
        a2_mot_v.request_no  
        from(
            SELECT
            mobile_tel,
            user_id,
            lastvalue(request_no) as request_no
            from source_stream_crhkh_crh_wskh_mid              
            group by SESSION(PROCTIME,INTERVAL '30' MINUTE ), mobile_tel,user_id

        ) a2_mot_v 
        left join dim_crhkh_crh_channeldefine dim_channel
        on a2_mot_v.channel_code = dim_channel.channel_code

    ) c2_mot_v
    group by   c2_mot_v.request_no，--8个字段groupby

)c3_mot_v
where c3_mot_v.rn = 1;

"----------------------------------------------------------------------------------------------"
747 行
--全部渠道:mot
--中断步骤为非视频见证 business_flag_last not in ('22109', '22144', '22108', '22182', '22160')
insert  into sink_stream_mot_e_event_flow_smot_mot_mid
select 
c3_mot.event_id,
--过滤rk=1的字段
from (
        
        select 
        c2_mot.client_name,
        --select group by的8个字段
        ROW_NUMBER() OVER(PARTITION BY c2_mot.mobile_tel, c2_mot.channel_code order by c2_mot.done_time_d) rn
        from (

                    select
                    a2_mot.birthday  as birthday,
                    a2_mot.request_no  
                    from(

                            SELECT
                            mobile_tel,
                            user_id,
                            lastvalue(channel_code) as channel_code
                            from source_stream_crhkh_crh_wskh_mid 
                            group by SESSION(PROCTIME,INTERVAL '8' MINUTE ),mobile_tel,user_id

                    )a2_mot 
                    left join dim_crhkh_crh_channeldefine dim_channel
                    on a2_mot.channel_code = dim_channel.channel_code
                    where a2_mot.business_flag_last in ('12100','1111')

           ) c2_mot                  
           group by c2_mot.client_name, --groupby 8个字段
)c3_mot
where c3_mot.rn = 1;

"----------------------------------------------------------------------------------------------"
913 行
--全部渠道:mot去重
insert  into sink_stream_mot_e_event_flow_smot
select  
event_id,
--拿全部字段,过滤rk等于1
from (

      select  
      event_id,
      --拿全部字段,
      ROW_NUMBER() OVER(PARTITION BY mobile,occur_date order by occur_time) rn
      from (

              select  
              mobile,
              occur_date,
              lastvalue(event_id) as event_id,
              --lastvalue获取全部字段
              from source_stream_mot_e_event_flow_smot_mot_mid
              group by mobile,occur_date
      ) t2 

)t2_mot
where t2_mot.rn = 1;  

"----------------------------------------------------------------------------------------------"
977 行

