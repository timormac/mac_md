-- name 019mot_stream_account_break_SD_110_new
-- type FlinkSQL
-- author admin@dtstack.com
-- create time 2024-03-13 15:11:43
-- desc 开户流程中断30min转化MOT
-- 源表：   stream_in.rt_crhkh_crh_wskh_userqueryextinfo     类型：Kafka
-- 维表：   dim_crhkh_crh_user_sysbusiness                   类型：Mysql    获取业务步骤名称
-- 结果表：result_table_jzjy                   类型：kafka
--        
-- 说明:
-- 开户流程中断13min转化-同花顺MOT
-- channel_code = '4981'为同花顺渠道 <>'4981'非同花顺渠道 14792-抖音渠道开户
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
-- 修改历史
-- +------+---------+--------------------------------------------------------+
-- |修改人  |修改时间  |                        内容                           |
-- |尚白冰  |2021/12/09|                       创建                            |  
-- |尚白冰  |2022/11/08|                       新增个人信息修改步骤、营业部和渠道 |  
-- +------+---------+--------------------------------------------------------+
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--去重，一个用户一个断点多条记录，一天只发一次
 insert into sink_stream_crhkh_crh_wskh_mid
    SELECT
        client_name,
        mobile_tel,
        branch_no,
        business_flag_last,
        case when channel_code = ' ' then '14083'
             else channel_code
         end as channel_code,
        last_update_detetime,
        user_id,
        id_no,
        birthday,
        request_no
    from (
    SELECT
        client_name,
        mobile_tel,
        branch_no,
        business_flag_last,
        channel_code,
        last_update_detetime,
        user_id,
        id_no,
        birthday,
        request_no,
        ROW_NUMBER() OVER(PARTITION BY mobile_tel,business_flag_last,channel_code,to_date(last_update_detetime) order by last_update_detetime) rn
        --ROW_NUMBER() OVER(PARTITION BY mobile_tel order by last_update_detetime) rn
    from
        rt_crhkh_crh_wskh_userqueryextinfo              
    where
        request_status in ('0')                         --状态：0-申请中 
    ) t 
    where t.rn = 1; 
   
--全部渠道:cc
--中断步骤为视频见证 business_flag_last in ('22109', '22144', '22108', '22182', '22160')
insert into sink_stream_mot_e_event_flow_smot_cc_mid
  select c3_v.event_id,
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
  
    from (select DISTINCT '019-1' as event_id,
                          '开户流程中断30min转化-cc（视频见证）' as event_name,
                          c2_v.client_name,
                          c2_v.channel_name,
                          c2_v.branch_name,
                          SUBSTRING(c2_v.mobile_tel, 8) as last_mobilenum,
                          c2_v.request_no,
                          c2_v.business_name,
                          c2_v.step_code,
                          c2_v.step_name,
                          --c2_v.device_flag,
                          -- c2_v.channel_type,
                          c2_v.mobile_tel as mobile,
                          c2_v.branch_no as branch_code,
                          case
                            when c2_v.channel_code = '4981' then
                             'ths'
                            when c2_v.channel_code in
                                 ('13994',
                                  '13797',
                                  '13777',
                                  '8345',
                                  '13348',
                                  '12791',
                                  '8496',
                                  '5522',
                                  --'4981',
                                  '4977',
                                  '14773',
                                  '14083',
                                  '14800',
                                  '14701',
                                  '14763',
                                  '14088',
                                  '14089') then
                             'cc'
                            when c2_v.branch_no = '493' then
                             'cc'
                            else
                             'znwh'
                          end as channel_type,
                          substring(c2_v.done_time_d, 1, 8) as occur_date,
                          concat(substring(c2_v.done_time_d, 9, 2),
                                 ':',
                                 substring(c2_v.done_time_d, 11, 2),
                                 ':',
                                 substring(c2_v.done_time_d, 13, 2)) as occur_time,
                          case
                            when c2_v.birthday is null then
                             ''
                            else
                             c2_v.birthday
                          end as birthday,
                          ROW_NUMBER() OVER(PARTITION BY c2_v.mobile_tel, c2_v.channel_code order by c2_v.done_time_d) rn
            from (select
                  
                   case
                     when dim_channel.channel_name is null then
                      'APP应用市场'
                     else
                      dim_channel.channel_name
                   end as channel_name,
                   a2_v.channel_code,
                   --  case 
                   --     when a2_v.channel_code = '4981' then '1' --同花顺渠道
                   --     when a2_v.channel_code = '14792' then '3'--抖音渠道 
                   --     else '2'
                   --     end as channel_type, --1 CC人工外呼  2 智能外呼            
                   a2_v.mobile_tel,
                   case
                     when a2_v.client_name is null then
                      ''
                     else
                      a2_v.client_name
                   end as client_name,
                   cast(a2_v.business_flag_last as varchar) business_flag_last,
                   a2_v.start_t,
                   a2_v.branch_no,
                   case
                     when dim2.branch_name is null then
                      ''
                     else
                      dim2.branch_name
                   end as branch_name,
                   b2.business_name,
                   case
                     when a2_v.business_flag_last in
                          ('12100', '22146', '22107', '22135') then
                      '1'
                     when a2_v.business_flag_last in
                          ('22145', '22111', '22224', '22241') then
                      '2'
                     when a2_v.business_flag_last in ('22123', '22106') and
                          a2_v.branch_no = '' then
                      '2'
                     when a2_v.business_flag_last in ('22106', '22123') and
                          a2_v.branch_no <> '' then
                      '3'
                     when a2_v.business_flag_last in
                          ('22109', '22144', '22108', '22182', '22160') then
                      '4'
                     when a2_v.business_flag_last in ('12104', '33500') then
                      '5'
                     when a2_v.business_flag_last in ('22112') then
                      '6'
                     when a2_v.business_flag_last in ('22113', '33232', '22110') then
                      '7'
                     when a2_v.business_flag_last in ('22122', '22128', '22115') then
                      '8'
                   end as step_code,
                   case
                     when a2_v.business_flag_last in
                          ('12100', '22146', '22107', '22135') then
                      '上传身份证'
                     when a2_v.business_flag_last in
                          ('22145', '22111', '22224', '22241') then
                      '个人信息修改'
                     when a2_v.business_flag_last in ('22123', '22106') and
                          a2_v.branch_no = '' then
                      '个人信息修改'
                     when a2_v.business_flag_last in ('22123', '22106') and
                          a2_v.branch_no <> '' then
                      '选择市场'
                     when a2_v.business_flag_last in
                          ('22109', '22144', '22108', '22182', '22160') then
                      '视频见证'
                     when a2_v.business_flag_last in ('12104', '33500') then
                      '设置密码'
                     when a2_v.business_flag_last in ('22112') then
                      '三方存管'
                     when a2_v.business_flag_last in ('22113', '33232', '22110') then
                      '风险评测'
                     when a2_v.business_flag_last in ('22122', '22128', '22115') then
                      '问卷回访'
                   end as step_name,
                   --d2.device_flag,
                   --DATE_FORMAT(max(d2.create_date_time),'yyyyMMdd') as create_date_time,
                   --DATE_FORMAT(max(d2.create_date_time),'yyyyMMddHHmmss') as done_time_d,
                   udf_time_sys(a2_v.mobile_tel, 'yyyyMMddHHmmss') as done_time_d,
                   dim_blacklist.id_no as id_no,
                   dim_basic_info.id_no as id_no2,
                   a2_v.birthday as birthday,
                   a2_v.request_no
                    from (SELECT mobile_tel,
                                 user_id,
                                 lastvalue(channel_code) as channel_code,
                                 lastvalue(client_name) as client_name,
                                 lastvalue(branch_no) as branch_no,
                                 cast(lastvalue(business_flag_last) as INT) as business_flag_last,
                                 lastvalue(id_no) as id_no,
                                 lastvalue(birthday) as birthday,
                                 lastvalue(request_no) as request_no,
                                 SESSION_START(PROCTIME, INTERVAL '30' MINUTE) as start_t
                            from source_stream_crhkh_crh_wskh_mid
                           -- where business_flag_last in ('22109', '22144', '22108', '22182', '22160')
                          --     channel_code not in ('4981', '14792')         --14792-抖音渠道开户
						      
                           group by SESSION(PROCTIME, INTERVAL '30' MINUTE),
                                    mobile_tel,
                                    user_id) a2_v
                    left join dim_crhkh_crh_channeldefine dim_channel
                      on a2_v.channel_code = dim_channel.channel_code
                    left join tb_dict_branch dim2
                      on a2_v.branch_no = dim2.branch_code
                    left join dim_crhkh_crh_user_sysbusiness b2
                      on a2_v.business_flag_last = b2.business_flag
                  --left join dim_opentooljour d2
                  --on a2_v.user_id = d2.user_id 
                    left join dim_user_blacklist dim_blacklist
                      on a2_v.id_no = dim_blacklist.id_no
                  -- and dim_blacklist.id_no <> ' '
                  --and dim_blacklist.id_no is not null
                    left join dim_acc_fundacc_basic_info dim_basic_info
                      on a2_v.id_no = dim_basic_info.id_no
                     and dim_basic_info.client_type = '0'
                     and dim_basic_info.fund_acc_status = '0'
                     and dim_basic_info.fund_acc_attr = '0'
                  --and dim_basic_info.id_no is not null
                  --  and dim_basic_info.id_no <> ' '
                   where a2_v.business_flag_last in
                         ('22109', '22144', '22108', '22182', '22160')
                  --and  dim_basic_info.id_no is not null
                  ) c2_v
           where (c2_v.id_no is null or trim(c2_v.id_no) = '')
             and (c2_v.id_no2 is null or trim(c2_v.id_no2) = '')
           group by c2_v.client_name,
                    c2_v.channel_name,
                    c2_v.branch_name,
                    c2_v.mobile_tel,
                    c2_v.business_name,
                    c2_v.step_code,
                    c2_v.step_name,
                    --c2_v.device_flag,
                    c2_v.channel_code,
                    c2_v.branch_no,
                    c2_v.done_time_d,
                    c2_v.birthday,
                    c2_v.request_no) c3_v
   where c3_v.rn = 1;
   
--全部渠道:cc
--中断步骤非视频见证 business_flag_last not in ('22109', '22144', '22108', '22182', '22160')  
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
  
    from (select DISTINCT '019-1' as event_id,
                          '开户流程中断8min转化-cc（非视频见证）' as event_name,
                          c2.client_name,
                          c2.channel_name,
                          c2.branch_name,
                          SUBSTRING(c2.mobile_tel, 8) as last_mobilenum,
                          c2.request_no,
                          c2.business_name,
                          c2.step_code,
                          c2.step_name,
                          --c2.device_flag,
                          -- c2.channel_type,
                          c2.mobile_tel as mobile,
                          c2.branch_no as branch_code,
                          case
                            when c2.channel_code = '4981' then
                             'ths'
                            when c2.channel_code in
                                 ('13994',
                                  '13797',
                                  '13777',
                                  '8345',
                                  '13348',
                                  '12791',
                                  '8496',
                                  '5522',
                                  --'4981',
                                  '4977',
                                  '14773',
                                  '14083',
                                  '14800',
                                  '14701',
                                  '14763',
                                  '14088',
                                  '14089') then
                             'cc'
                            when c2.branch_no = '493' then
                             'cc'
                            else
                             'znwh'
                          end as channel_type,
                          substring(c2.done_time_d, 1, 8) as occur_date,
                          concat(substring(c2.done_time_d, 9, 2),
                                 ':',
                                 substring(c2.done_time_d, 11, 2),
                                 ':',
                                 substring(c2.done_time_d, 13, 2)) as occur_time,
                          case
                            when c2.birthday is null then
                             ''
                            else
                             c2.birthday
                          end as birthday,
                          ROW_NUMBER() OVER(PARTITION BY c2.mobile_tel, c2.channel_code order by c2.done_time_d) rn
            from (select
                  
                   case
                     when dim_channel.channel_name is null then
                      'APP应用市场'
                     else
                      dim_channel.channel_name
                   end as channel_name,
                   a2.channel_code,
                   --  case 
                   --     when a2.channel_code = '4981' then '1' --同花顺渠道
                   --     when a2.channel_code = '14792' then '3'--抖音渠道 
                   --     else '2'
                   --     end as channel_type, --1 CC人工外呼  2 智能外呼            
                   a2.mobile_tel,
                   case
                     when a2.client_name is null then
                      ''
                     else
                      a2.client_name
                   end as client_name,
                   cast(a2.business_flag_last as varchar) business_flag_last,
                   a2.start_t,
                   a2.branch_no,
                   case
                     when dim2.branch_name is null then
                      ''
                     else
                      dim2.branch_name
                   end as branch_name,
                   b2.business_name,
                   case
                     when a2.business_flag_last in
                          ('12100', '22146', '22107', '22135') then
                      '1'
                     when a2.business_flag_last in
                          ('22145', '22111', '22224', '22241') then
                      '2'
                     when a2.business_flag_last in ('22123', '22106') and
                          a2.branch_no = '' then
                      '2'
                     when a2.business_flag_last in ('22106', '22123') and
                          a2.branch_no <> '' then
                      '3'
                     when a2.business_flag_last in
                          ('22109', '22144', '22108', '22182', '22160') then
                      '4'
                     when a2.business_flag_last in ('12104', '33500') then
                      '5'
                     when a2.business_flag_last in ('22112') then
                      '6'
                     when a2.business_flag_last in ('22113', '33232', '22110') then
                      '7'
                     when a2.business_flag_last in ('22122', '22128', '22115') then
                      '8'
                   end as step_code,
                   case
                     when a2.business_flag_last in
                          ('12100', '22146', '22107', '22135') then
                      '上传身份证'
                     when a2.business_flag_last in
                          ('22145', '22111', '22224', '22241') then
                      '个人信息修改'
                     when a2.business_flag_last in ('22123', '22106') and
                          a2.branch_no = '' then
                      '个人信息修改'
                     when a2.business_flag_last in ('22123', '22106') and
                          a2.branch_no <> '' then
                      '选择市场'
                     when a2.business_flag_last in
                          ('22109', '22144', '22108', '22182', '22160') then
                      '视频见证'
                     when a2.business_flag_last in ('12104', '33500') then
                      '设置密码'
                     when a2.business_flag_last in ('22112') then
                      '三方存管'
                     when a2.business_flag_last in ('22113', '33232', '22110') then
                      '风险评测'
                     when a2.business_flag_last in ('22122', '22128', '22115') then
                      '问卷回访'
                   end as step_name,
                   --d2.device_flag,
                   --DATE_FORMAT(max(d2.create_date_time),'yyyyMMdd') as create_date_time,
                   --DATE_FORMAT(max(d2.create_date_time),'yyyyMMddHHmmss') as done_time_d,
                   udf_time_sys(a2.mobile_tel, 'yyyyMMddHHmmss') as done_time_d,
                   dim_blacklist.id_no as id_no,
                   dim_basic_info.id_no as id_no2,
                   a2.birthday as birthday,
                   a2.request_no
                    from (SELECT mobile_tel,
                                 user_id,
                                 lastvalue(channel_code) as channel_code,
                                 lastvalue(client_name) as client_name,
                                 lastvalue(branch_no) as branch_no,
                                 cast(lastvalue(business_flag_last) as INT) as business_flag_last,
                                 lastvalue(id_no) as id_no,
                                 lastvalue(birthday) as birthday,
                                 lastvalue(request_no) as request_no,
                                 SESSION_START(PROCTIME, INTERVAL '8' MINUTE) as start_t
                            from source_stream_crhkh_crh_wskh_mid
                           --where business_flag_last not in ('22109', '22144', '22108', '22182', '22160')
                          --     channel_code not in ('4981', '14792')         --14792-抖音渠道开户
						      
                           group by SESSION(PROCTIME, INTERVAL '8' MINUTE),
                                    mobile_tel,
                                    user_id) a2
                    left join dim_crhkh_crh_channeldefine dim_channel
                      on a2.channel_code = dim_channel.channel_code
                    left join tb_dict_branch dim2
                      on a2.branch_no = dim2.branch_code
                    left join dim_crhkh_crh_user_sysbusiness b2
                      on a2.business_flag_last = b2.business_flag
                  --left join dim_opentooljour d2
                  --on a2.user_id = d2.user_id 
                    left join dim_user_blacklist dim_blacklist
                      on a2.id_no = dim_blacklist.id_no
                  -- and dim_blacklist.id_no <> ' '
                  --and dim_blacklist.id_no is not null
                    left join dim_acc_fundacc_basic_info dim_basic_info
                      on a2.id_no = dim_basic_info.id_no
                     and dim_basic_info.client_type = '0'
                     and dim_basic_info.fund_acc_status = '0'
                     and dim_basic_info.fund_acc_attr = '0'
                  --and dim_basic_info.id_no is not null
                  --  and dim_basic_info.id_no <> ' '
                   where a2.business_flag_last in
                         ('12100',
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
                  --and  dim_basic_info.id_no is not null
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
                    --c2.device_flag,
                    c2.channel_code,
                    c2.branch_no,
                    c2.done_time_d,
                    c2.birthday,
                    c2.request_no) c3
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
                SESSION_START(PROCTIME,INTERVAL '30' MINUTE ) as start_t
            from
                source_stream_crhkh_crh_wskh_mid              
          -- where business_flag_last in ('22109', '22144', '22108', '22182', '22160')
            --     channel_code not in ('4981', '14792')         --14792-抖音渠道开户
            group by
                SESSION(PROCTIME,INTERVAL '30' MINUTE ),
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
                SESSION_START(PROCTIME,INTERVAL '8' MINUTE ) as start_t
            from
                source_stream_crhkh_crh_wskh_mid              
           --where business_flag_last not in ('22109', '22144', '22108', '22182', '22160')
            --     channel_code not in ('4981', '14792')         --14792-抖音渠道开户
            group by
                SESSION(PROCTIME,INTERVAL '8' MINUTE ),
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
