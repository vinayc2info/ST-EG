insert into st_err_track_det 
select top 10
c_doc_no,n_inout,n_seq,n_org_seq,c_item_code,c_batch_no,n_qty,c_tray_code,item_mst_br_info.c_rack,rack_mst.c_rack_grp_code,ssd.c_stage_code,rack_group_mst.c_godown_code as c_godown_code,
c_reason_code,
'' as c_note,
0 as n_err_type,
'TEST' as c_err_mark_user,
now() as t_err_time,
null as c_contra_item,null as c_contra_batch,null as n_contra_qty,
c_out_tray_no as c_pack_tray_code,
n_carton_no,
99 as c_counter_table_code,
null as n_ref_srno,
null as c_ref_doc_no,
null as c_supervisor,
null as t_spvr_err_marked_time,
null as c_new_doc_no,
null as n_new_inout,
null as n_new_seq,
0 as n_complete,
0 as n_hold_flag,
now() as t_ltime,
'TEST1' as c_luser 
from st_pick_backup
join item_mst_br_info on st_pick_backup.c_item_code  = item_mst_br_info.c_code and item_mst_br_info.c_br_code = uf_get_br_code('000')
join rack_mst on rack_mst.c_code = item_mst_br_info.c_rack and item_mst_br_info.c_br_code = rack_mst.c_br_code
join rack_group_mst on rack_group_mst.c_code = rack_mst.c_rack_grp_code and rack_group_mst.c_br_code = rack_mst.c_br_code
join st_store_stage_det ssd on ssd.c_rack_grp_code = rack_group_mst.c_code and ssd.c_br_code = rack_group_mst.c_br_code 
join st_store_stage_mst ssm on ssm.c_code = ssd.c_stage_code and ssm.c_br_code = ssd.c_br_code
//where item_mst_br_info.c_code = '208294'
order by 4 asc

