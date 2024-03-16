--全部渠道:cc
--中断步骤为视频见证 business_flag_last in ('22109', '22144', '22108', '22182', '22160')
insert into sink_stream_mot_e_event_flow_smot_cc_mid
select 
c3_v.event_id,
c3_v.event_name,
from(
      select 
      c2_v.branch_name,
      ROW_NUMBER() OVER(PARTITION BY c2_v.mobile_tel, c2_v.channel_code order by c2_v.done_time_d) rn
      from (
             select
             dim_blacklist.id_no as id_no,
             dim_basic_info.id_no as id_no2,
             a2_v.birthday as birthday,
             a2_v.request_no
             from (

                    SELECT 
                    mobile_tel,
                    user_id,
                    lastvalue(channel_code) as channel_code,
                    from source_stream_crhkh_crh_wskh_mid
                    group by SESSION(PROCTIME, INTERVAL '30' MINUTE),mobile_tel,user_id

                )a2_v
                left join dim_crhkh_crh_channeldefine dim_channel
                on a2_v.channel_code = dim_channel.channel_code

          ) c2_v
          group by c2_v.client_name,c2_v.channel_name,
) c3_v
where c3_v.rn = 1;