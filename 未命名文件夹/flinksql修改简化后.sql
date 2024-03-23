
--去重，一个用户一个断点多条记录，一天只发一次
 insert into sink_stream_crhkh_crh_wskh_mid
SELECT
mobile_tel,
business_flag_last,
channel_code,
last_update_detetime,
from (
    SELECT 
    ROW_NUMBER() OVER(PARTITION BY mobile_tel,business_flag_last,channel_code,to_date(last_update_detetime) order by last_update_detetime) rn
    from rt_crhkh_crh_wskh_userqueryextinfo              
    where
    request_status in ('0')                         --状态：0-申请中 
) t 
where t.rn = 1; 


----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------


--全部渠道:cc
--中断步骤为视频见证 business_flag_last in ('22109', '22144', '22108', '22182', '22160')
insert into sink_stream_mot_e_event_flow_smot_cc_mid
select 
c3_v.event_id,
c3_v.event_name,
c3_v.client_name,
c3_v.channel_name,
c3_v.branch_name,
c3_v.last_mobilenum,
c3_v.request_no,
c3_v.business_name,
c3_v.step_code,
c3_v.step_name,
c3_v.channel_type,
c3_v.mobile,
c3_v.branch_code,
c3_v.occur_date,
c3_v.occur_time,
c3_v.birthday
from (
       select  
      '019-1' as event_id,
      '开户流程中断30min转化-cc（视频见证）' as event_name,
      c2_v.client_name,
      c2_v.channel_name,
      c2_v.branch_name,
      last_mobilenum,
      c2_v.step_code,
      c2_v.step_name,
      channel_type  --根据channel_code做大映射,
      occur_date,  --截取done_time_d系统时间,改成yyyy-MM格式
      occur_time, --截取done_time_d系统时间,改成HH:mm:ss格式
      --这里是按done_time_d排序,应该是为了防止乱序情况
      ROW_NUMBER() OVER(PARTITION BY c2_v.mobile_tel, c2_v.channel_code order by c2_v.done_time_d) rn
      from (
           select
           a2_v.channel_code,
           a2_v.mobile_tel,
           a2_v.business_flag_last,
           a2_v.start_t,
           step_code,  --根据business_flag_last做范围映射(1-8)
           step_name,  --根据business_flag_last做范围映射(上传身份证,视频上传等)
           udf_time_sys(a2_v.mobile_tel, 'yyyyMMddHHmmss') as done_time_d  --获取系统时间,
           from (
                 SELECT 
                 mobile_tel,
                 user_id,
                 lastvalue(channel_code) as channel_code,
                 business_flag_last,
                 SESSION_START(PROCTIME, INTERVAL '20' second) as start_t
                 from source_stream_crhkh_crh_wskh_mid
                 group by SESSION(PROCTIME, INTERVAL '20' second),mobile_tel,user_id
             ) a2_v
            left join dim_crhkh_crh_channeldefine dim_channel
              on a2_v.channel_code = dim_channel.channel_code
            where a2_v.business_flag_last in ('22109', '22144', '22108', '22182', '22160')--过滤视频步骤
    ) c2_v
    group by c2_v.client_name,
        c2_v.channel_name,
        c2_v.branch_name,
        c2_v.mobile_tel,
        c2_v.business_name,
        c2_v.step_code,
        c2_v.step_name,
        c2_v.channel_code,
        c2_v.branch_no,
        c2_v.done_time_d,
        c2_v.birthday,
        c2_v.request_no
) c3_v
where c3_v.rn = 1;

----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------


--全部渠道:cc
--中断步骤非视频见证 business_flag_last not in ('22109', '22144', '22108', '22182', '22160')

--会话窗口多次关闭,会输出多条,但是PARTITION BY c2.mobile_tel, c2.channel_code order by c2.done_time_d
--会把输出多条之后,按照时间排序,rk =1 只返回一条


insert into sink_stream_mot_e_event_flow_smot_cc_mid
  select c3.event_id,
         c3.event_name,
         c3.client_name,
         c3.channel_name,
         c3.branch_name,
         c3.last_mobilenum,
         c3.request_no,
         c3.business_name,
         c3.step_code,
         c3.step_name,
         c3.channel_type,
         c3.mobile,
         c3.branch_code,
         c3.occur_date,
         c3.occur_time,
         c3.birthday
  
from (
      select DISTINCT
      '019-1' as event_id,  --这里后面更改成019b-1
      '开户流程中断8min转化-cc（非视频见证）' as event_name,,
      channel_type, --根据channel_code做聚合映射(cc,znwh,ths)
      occur_time,
      ROW_NUMBER() OVER(PARTITION BY c2.mobile_tel, c2.channel_code order by c2.done_time_d) rn
      from (
               select
               a2.channel_code,
               a2.mobile_tel,
               a2.business_flag_last,
               step_code,  --根据business_flag_last做范围映射(1-8)
               step_name,  --根据business_flag_last做范围映射(上传身份证,视频上传等)
               udf_time_sys(a2.mobile_tel, 'yyyyMMddHHmmss') as done_time_d,
               from (
                     SELECT 
                     mobile_tel,
                     user_id,
                     lastvalue(channel_code) as channel_code,
                     lastvalue(client_name) as client_name,
                     lastvalue(branch_no) as branch_no,
                     business_flag_last,
                     SESSION_START(PROCTIME, INTERVAL '10' second) as start_t
                     from source_stream_crhkh_crh_wskh_mid
                     group by SESSION(PROCTIME, INTERVAL '10' second), mobile_tel,user_id
                ) a2
                left join dim_crhkh_crh_channeldefine dim_channel
                on a2.channel_code = dim_channel.channel_code
                where a2.business_flag_last in (
                                                '12100','22146','22107','22135', --上传身份证
                                                '22145','22123','22106','22111', --个人信息修改
                                                '22106', '22123',  --选择市场
                                                '12104','33500','22112','22113','33232', --设置密码，三方存管风险评测
                                                '22110','22122','22128','22115', --问卷回访 
                                                '22224','22241' 不知道
                                                )
        ) c2
        where (c2.id_no is null or trim(c2.id_no) = '')
        and (c2.id_no2 is null or trim(c2.id_no2) = '')
        group by c2.client_name,
                c2.channel_name,
                c2.branch_name,
                c2.mobile_tel,
                c2.business_name,
                c2.step_code,
                c2.step_name,
                c2.channel_code,
                c2.branch_no,
                c2.done_time_d,
                c2.birthday,
                c2.request_no
) c3
where c3.rn = 1;


--CC渠道去重
insert into sink_stream_mot_e_event_flow_smot_cc
select  event_id,
          event_name,
          client_name,
          channel_name,
          branch_name,
          last_mobilenum,
          request_no,
          business_name,
          step_code,
          step_name,
          channel_type,
          mobile,
          branch_code,
          occur_date,
          occur_time,
          birthday
  from (
  select  event_id,
          event_name,
          client_name,
          channel_name,
          branch_name,
          last_mobilenum,
          request_no,
          business_name,
          step_code,
          step_name,
          channel_type,
          mobile,
          branch_code,
          occur_date,
          occur_time,
          birthday,
          ROW_NUMBER() OVER(PARTITION BY mobile,occur_date order by occur_time) rn
    from (
         select  mobile,
          occur_date,
          lastvalue(event_id) as event_id,
          lastvalue(event_name) as event_name,
          lastvalue(client_name) as client_name,
          lastvalue(channel_name) as channel_name,
          lastvalue(branch_name) as branch_name,
          lastvalue(last_mobilenum) as last_mobilenum,
          lastvalue(request_no) as request_no,
          lastvalue(business_name) as business_name,
          lastvalue(step_code) as step_code,
          lastvalue(step_name) as step_name,
          lastvalue(channel_type) as channel_type,         
          lastvalue(branch_code) as branch_code,       
          lastvalue(occur_time) as occur_time,
          lastvalue(birthday) as birthday          
    from
        source_stream_mot_e_event_flow_smot_cc_mid
        group by mobile,
                 occur_date
    ) t1 
  )t1_cc
    where t1_cc.rn = 1; 
    
-- 客户交易成功提醒事件流水记录_cc。
insert into e_event_flow_stream
     select event_id AS EVENT_ID,
            event_name     AS EVENT_NAME,
            ''   AS FUND_ACC_NO,
            mobile             AS MOBILE,
            occur_date as EVENT_DATE,
            occur_time   AS EVENT_TIME,
            concat('客户姓名=',client_name,';',
                   '开户渠道=',channel_name,';',
                   '营业部名称=',branch_name,';',
                   '手机尾号=',last_mobilenum,';',
                   '上一完成步骤=',business_name,';',
                   '中断步骤代码=',step_code,';',
                   '中断步骤=',step_name,';',
                   --'设备代码=',device_flag,';',
                   '渠道类型=',channel_type,';',
                   '手机号=',mobile,';',
                   '营业部=',branch_code,';',
                   '生日=',birthday,';',
                   '请求编号=',request_no
                   ) as APPEND_INFORMATION    
       from source_mot_stream_account_break_ths_cc ;      
--全部渠道:mot
--中断步骤为视频见证 business_flag_last in ('22109', '22144', '22108', '22182', '22160')
insert  
into
    sink_stream_mot_e_event_flow_smot_mot_mid
      select c3_mot_v.event_id,
c3_mot_v.event_name,
c3_mot_v.client_name,
c3_mot_v.channel_name,
c3_mot_v.branch_name,
c3_mot_v.last_mobilenum,
c3_mot_v.request_no,
c3_mot_v.business_name,
c3_mot_v.step_code,
c3_mot_v.step_name,
c3_mot_v.channel_type,
c3_mot_v.mobile,
c3_mot_v.branch_code,
c3_mot_v.occur_date,
c3_mot_v.occur_time,
c3_mot_v.birthday
  
    from (
    select  DISTINCT  
        '019-2' as event_id,
        '开户流程中断30min转化-mot(视频见证)' as event_name,
        c2_mot_v.client_name,
        c2_mot_v.channel_name,
        c2_mot_v.branch_name,
        SUBSTRING(c2_mot_v.mobile_tel, 8) as last_mobilenum,
        c2_mot_v.request_no,
        c2_mot_v.business_name,
        c2_mot_v.step_code,
        c2_mot_v.step_name,
        --c2_mot_v.device_flag,
        c2_mot_v.channel_type,
        c2_mot_v.mobile_tel as mobile,
        c2_mot_v.branch_no as branch_code,
        substring(c2_mot_v.done_time_d, 1, 8) as occur_date,
        concat(substring(c2_mot_v.done_time_d, 9, 2),
                               ':',
                       substring(c2_mot_v.done_time_d, 11, 2),
                               ':',
                       substring(c2_mot_v.done_time_d, 13, 2)) as occur_time,
        case when c2_mot_v.birthday is null then ''
              else c2_mot_v.birthday
          end as birthday,
          ROW_NUMBER() OVER(PARTITION BY c2_mot_v.mobile_tel, c2_mot_v.channel_code order by c2_mot_v.done_time_d) rn
            from 
        (select
            
            case when dim_channel.channel_name is null then 'APP应用市场' 
                 else dim_channel.channel_name
             end  as channel_name,
             case 
                when a2_mot_v.channel_code = '4981' then '1' --同花顺渠道
                when a2_mot_v.channel_code = '14792' then '3'--抖音渠道 
                else '2'
                end as channel_type,
            a2_mot_v.channel_code,
            a2_mot_v.mobile_tel,
            case 
                when a2_mot_v.client_name is null then ''
                else a2_mot_v.client_name end as client_name,
            cast(a2_mot_v.business_flag_last as varchar) business_flag_last,
            a2_mot_v.start_t,
            a2_mot_v.branch_no,
            case 
                when dim2.branch_name is null then ''
                else dim2.branch_name end as branch_name,
            b2.business_name,
            case 
                when  a2_mot_v.business_flag_last in ('12100','22146','22107','22135') then '1'          
                when  a2_mot_v.business_flag_last in ('22145','22111','22224','22241') then '2' 
                when  a2_mot_v.business_flag_last in ('22123','22106') and a2_mot_v.branch_no = '' then '2' 
                when  a2_mot_v.business_flag_last in ('22106','22123') and a2_mot_v.branch_no <> '' then '3'          
                when  a2_mot_v.business_flag_last in ('22109','22144','22108','22182','22160') then '4'          
                when  a2_mot_v.business_flag_last in ('12104','33500') then '5'          
                when  a2_mot_v.business_flag_last in ('22112') then '6'          
                when  a2_mot_v.business_flag_last in ('22113','33232','22110') then '7'          
                when  a2_mot_v.business_flag_last in ('22122','22128','22115') then '8'          
            end as step_code,
            case 
                when  a2_mot_v.business_flag_last in ('12100','22146','22107','22135') then '上传身份证'          
                when  a2_mot_v.business_flag_last in ('22145','22111','22224','22241') then '个人信息修改'  
                when  a2_mot_v.business_flag_last in ('22123','22106') and a2_mot_v.branch_no = '' then '个人信息修改'         
                when  a2_mot_v.business_flag_last in ('22123','22106') and a2_mot_v.branch_no <> ''  then '选择市场'          
                when  a2_mot_v.business_flag_last in ('22109','22144','22108','22182','22160') then '视频见证'          
                when  a2_mot_v.business_flag_last in ('12104','33500') then '设置密码'          
                when  a2_mot_v.business_flag_last in ('22112') then '三方存管'          
                when  a2_mot_v.business_flag_last in ('22113','33232','22110') then '风险评测'          
                when  a2_mot_v.business_flag_last in ('22122','22128','22115') then '问卷回访'          
            end as step_name,
            --d2.device_flag,
            --DATE_FORMAT(max(d2.create_date_time),'yyyyMMdd') as create_date_time,
            --DATE_FORMAT(max(d2.create_date_time),'yyyyMMddHHmmss') as done_time_d,
            udf_time_sys(a2_mot_v.mobile_tel, 'yyyyMMddHHmmss')  as done_time_d,
            a2_mot_v.birthday  as birthday,
            a2_mot_v.request_no  
        from
            (SELECT
                mobile_tel,
                user_id,
                lastvalue(channel_code) as channel_code,
                lastvalue(client_name) as client_name,
                lastvalue(branch_no) as branch_no,
                cast(lastvalue(business_flag_last) as INT) as business_flag_last,
                lastvalue(birthday) as birthday,
                lastvalue(request_no) as request_no,
                SESSION_START(PROCTIME,INTERVAL '20' second ) as start_t
            from
                source_stream_crhkh_crh_wskh_mid              
          -- where business_flag_last in ('22109', '22144', '22108', '22182', '22160')
            --     channel_code not in ('4981', '14792')         --14792-抖音渠道开户
            group by
                SESSION(PROCTIME,INTERVAL '20' second ),
                mobile_tel,
                user_id) a2_mot_v 
         left join dim_crhkh_crh_channeldefine dim_channel
          on a2_mot_v.channel_code = dim_channel.channel_code
        left join tb_dict_branch dim2
        on a2_mot_v.branch_no = dim2.branch_code
        left join
            dim_crhkh_crh_user_sysbusiness b2         
            on a2_mot_v.business_flag_last = b2.business_flag
        --left join dim_opentooljour d2
          --on a2_mot_v.user_id = d2.user_id 
            where a2_mot_v.business_flag_last in  ('22109', '22144', '22108', '22182', '22160')
           ) c2_mot_v                  
           group by 
           c2_mot_v.client_name,
           c2_mot_v.channel_name,
           c2_mot_v.branch_name,
           c2_mot_v.mobile_tel,
           c2_mot_v.channel_code,
           c2_mot_v.business_name,
           c2_mot_v.step_code,
           c2_mot_v.step_name,
           --c2_mot_v.device_flag,
           c2_mot_v.channel_type,
           c2_mot_v.branch_no,
           c2_mot_v.done_time_d,
           c2_mot_v.birthday,
           c2_mot_v.request_no)
           c3_mot_v
           where c3_mot_v.rn = 1;
--全部渠道:mot
--中断步骤为非视频见证 business_flag_last not in ('22109', '22144', '22108', '22182', '22160')
insert  
into
    sink_stream_mot_e_event_flow_smot_mot_mid
      select c3_mot.event_id,
c3_mot.event_name,
c3_mot.client_name,
c3_mot.channel_name,
c3_mot.branch_name,
c3_mot.last_mobilenum,
c3_mot.request_no,
c3_mot.business_name,
c3_mot.step_code,
c3_mot.step_name,
c3_mot.channel_type,
c3_mot.mobile,
c3_mot.branch_code,
c3_mot.occur_date,
c3_mot.occur_time,
c3_mot.birthday
  
    from (
    select  DISTINCT  
        '019-2' as event_id,
        '开户流程中断8min转化-mot（非视频见证）' as event_name,
        c2_mot.client_name,
        c2_mot.channel_name,
        c2_mot.branch_name,
        SUBSTRING(c2_mot.mobile_tel, 8) as last_mobilenum,
        c2_mot.request_no,
        c2_mot.business_name,
        c2_mot.step_code,
        c2_mot.step_name,
        --c2_mot.device_flag,
        c2_mot.channel_type,
        c2_mot.mobile_tel as mobile,
        c2_mot.branch_no as branch_code,
        substring(c2_mot.done_time_d, 1, 8) as occur_date,
        concat(substring(c2_mot.done_time_d, 9, 2),
                               ':',
                       substring(c2_mot.done_time_d, 11, 2),
                               ':',
                       substring(c2_mot.done_time_d, 13, 2)) as occur_time,
        case when c2_mot.birthday is null then ''
              else c2_mot.birthday
          end as birthday,
          ROW_NUMBER() OVER(PARTITION BY c2_mot.mobile_tel, c2_mot.channel_code order by c2_mot.done_time_d) rn
            from 
        (select
            
            case when dim_channel.channel_name is null then 'APP应用市场' 
                 else dim_channel.channel_name
             end  as channel_name,
             case 
                when a2_mot.channel_code = '4981' then '1' --同花顺渠道
                when a2_mot.channel_code = '14792' then '3'--抖音渠道 
                else '2'
                end as channel_type,
            a2_mot.channel_code,
            a2_mot.mobile_tel,
            case 
                when a2_mot.client_name is null then ''
                else a2_mot.client_name end as client_name,
            cast(a2_mot.business_flag_last as varchar) business_flag_last,
            a2_mot.start_t,
            a2_mot.branch_no,
            case 
                when dim2.branch_name is null then ''
                else dim2.branch_name end as branch_name,
            b2.business_name,
            case 
                when  a2_mot.business_flag_last in ('12100','22146','22107','22135') then '1'          
                when  a2_mot.business_flag_last in ('22145','22111','22224','22241') then '2' 
                when  a2_mot.business_flag_last in ('22123','22106') and a2_mot.branch_no = '' then '2' 
                when  a2_mot.business_flag_last in ('22106','22123') and a2_mot.branch_no <> '' then '3'          
                when  a2_mot.business_flag_last in ('22109','22144','22108','22182','22160') then '4'          
                when  a2_mot.business_flag_last in ('12104','33500') then '5'          
                when  a2_mot.business_flag_last in ('22112') then '6'          
                when  a2_mot.business_flag_last in ('22113','33232','22110') then '7'          
                when  a2_mot.business_flag_last in ('22122','22128','22115') then '8'          
            end as step_code,
            case 
                when  a2_mot.business_flag_last in ('12100','22146','22107','22135') then '上传身份证'          
                when  a2_mot.business_flag_last in ('22145','22111','22224','22241') then '个人信息修改'  
                when  a2_mot.business_flag_last in ('22123','22106') and a2_mot.branch_no = '' then '个人信息修改'         
                when  a2_mot.business_flag_last in ('22123','22106') and a2_mot.branch_no <> ''  then '选择市场'          
                when  a2_mot.business_flag_last in ('22109','22144','22108','22182','22160') then '视频见证'          
                when  a2_mot.business_flag_last in ('12104','33500') then '设置密码'          
                when  a2_mot.business_flag_last in ('22112') then '三方存管'          
                when  a2_mot.business_flag_last in ('22113','33232','22110') then '风险评测'          
                when  a2_mot.business_flag_last in ('22122','22128','22115') then '问卷回访'          
            end as step_name,
            --d2.device_flag,
            --DATE_FORMAT(max(d2.create_date_time),'yyyyMMdd') as create_date_time,
            --DATE_FORMAT(max(d2.create_date_time),'yyyyMMddHHmmss') as done_time_d,
            udf_time_sys(a2_mot.mobile_tel, 'yyyyMMddHHmmss')  as done_time_d,
            a2_mot.birthday  as birthday,
            a2_mot.request_no  
        from
            (SELECT
                mobile_tel,
                user_id,
                lastvalue(channel_code) as channel_code,
                lastvalue(client_name) as client_name,
                lastvalue(branch_no) as branch_no,
                cast(lastvalue(business_flag_last) as INT) as business_flag_last,
                lastvalue(birthday) as birthday,
                lastvalue(request_no) as request_no,
                SESSION_START(PROCTIME,INTERVAL '10' second ) as start_t
            from
                source_stream_crhkh_crh_wskh_mid              
           --where business_flag_last not in ('22109', '22144', '22108', '22182', '22160')
            --     channel_code not in ('4981', '14792')         --14792-抖音渠道开户
            group by
                SESSION(PROCTIME,INTERVAL '10' second ),
                mobile_tel,
                user_id) a2_mot 
         left join dim_crhkh_crh_channeldefine dim_channel
          on a2_mot.channel_code = dim_channel.channel_code
        left join tb_dict_branch dim2
        on a2_mot.branch_no = dim2.branch_code
        left join
            dim_crhkh_crh_user_sysbusiness b2         
            on a2_mot.business_flag_last = b2.business_flag
        --left join dim_opentooljour d2
          --on a2_mot.user_id = d2.user_id 
            where a2_mot.business_flag_last in ('12100',
                          '22146',
                          '22107',
                          '22135',
                          '22145',
                          '22123',
                          '22106',
                          '22111',
                          '22106',
                          '22123',
                          '12104',
                          '33500',
                          '22112',
                          '22113',
                          '33232',
                          '22110',
                          '22122',
                          '22128',
                          '22115',
                          '22224',
                          '22241')
           ) c2_mot                  
           group by 
           c2_mot.client_name,
           c2_mot.channel_name,
           c2_mot.branch_name,
           c2_mot.mobile_tel,
           c2_mot.channel_code,
           c2_mot.business_name,
           c2_mot.step_code,
           c2_mot.step_name,
           --c2_mot.device_flag,
           c2_mot.channel_type,
           c2_mot.branch_no,
           c2_mot.done_time_d,
           c2_mot.birthday,
           c2_mot.request_no)
           c3_mot
           where c3_mot.rn = 1;
--全部渠道:mot去重
insert  
into
    sink_stream_mot_e_event_flow_smot
    select  event_id,
          event_name,
          client_name,
          channel_name,
          branch_name,
          last_mobilenum,
          request_no,
          business_name,
          step_code,
          step_name,
          channel_type,
          mobile,
          branch_code,
          occur_date,
          occur_time,
          birthday
  from (
  select  event_id,
          event_name,
          client_name,
          channel_name,
          branch_name,
          last_mobilenum,
          request_no,
          business_name,
          step_code,
          step_name,
          channel_type,
          mobile,
          branch_code,
          occur_date,
          occur_time,
          birthday,
          ROW_NUMBER() OVER(PARTITION BY mobile,occur_date order by occur_time) rn
    from (
         select  mobile,
          occur_date,
          lastvalue(event_id) as event_id,
          lastvalue(event_name) as event_name,
          lastvalue(client_name) as client_name,
          lastvalue(channel_name) as channel_name,
          lastvalue(branch_name) as branch_name,
          lastvalue(last_mobilenum) as last_mobilenum,
          lastvalue(request_no) as request_no,
          lastvalue(business_name) as business_name,
          lastvalue(step_code) as step_code,
          lastvalue(step_name) as step_name,
          lastvalue(channel_type) as channel_type,         
          lastvalue(branch_code) as branch_code,       
          lastvalue(occur_time) as occur_time,
          lastvalue(birthday) as birthday          
    from
        source_stream_mot_e_event_flow_smot_mot_mid
        group by mobile,
                 occur_date
    ) t2 
  )t2_mot
    where t2_mot.rn = 1;  
      
      
-- 客户交易成功提醒事件流水记录_mot。
insert into e_event_flow_stream
     select event_id AS EVENT_ID,
            event_name     AS EVENT_NAME,
            ''   AS FUND_ACC_NO,
            mobile             AS MOBILE,
            occur_date as EVENT_DATE,
            occur_time   AS EVENT_TIME,
            concat('客户姓名=',client_name,';',
                   '开户渠道=',channel_name,';',
                   '营业部名称=',branch_name,';',
                   '手机尾号=',last_mobilenum,';',
                   '上一完成步骤=',business_name,';',
                   '中断步骤代码=',step_code,';',
                   '中断步骤=',step_name,';',
                   --'设备代码=',device_flag,';',
                   '渠道类型=',channel_type,';',
                   '手机号=',mobile,';',
                   '营业部=',branch_code,';',
                   '生日=',birthday,';',
                   '请求编号=',request_no) as APPEND_INFORMATION    
       from source_mot_stream_account_break_ths ;             
