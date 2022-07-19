CREATE OR REPLACE FUNCTION uf_get_new_tran( in as_tran_code char(5), in as_prefix char(6)) 
returns numeric(18)
begin
  declare d_sr_no numeric(18);
  declare d_sr_no_b4 numeric(18);
  declare as_br char(3);
  declare as_year char(2);
  declare @sql_code numeric(20);
  set as_br = uf_get_br_code('000');
  set as_year = RIGHT(db_name(),2);
  select prefix_serial_no.n_sr_number
    into d_sr_no_b4 from prefix_serial_no
    where prefix_serial_no.c_br_code = as_br
    and prefix_serial_no.c_year = as_year
    and prefix_serial_no.c_prefix = as_prefix
    and prefix_serial_no.c_trans = as_tran_code;
  //generate new transaction number
  update prefix_serial_no
    set n_sr_number = n_sr_number+1
    where  prefix_serial_no.c_br_code = as_br
    and prefix_serial_no.c_year = as_year
    and prefix_serial_no.c_prefix = as_prefix
    and prefix_serial_no.c_trans = as_tran_code;
  select prefix_serial_no.n_sr_number
    into d_sr_no from prefix_serial_no
    where  prefix_serial_no.c_br_code = as_br
    and prefix_serial_no.c_year = as_year
    and prefix_serial_no.c_prefix = as_prefix
    and prefix_serial_no.c_trans = as_tran_code;
  if d_sr_no = d_sr_no_b4 then
    set d_sr_no = 0
  end if;
  return d_sr_no
exception
  when others then
    set @sql_code = sqlcode;
    if errormsg(@sql_code) is not null then
      set d_sr_no = 999999999
    end if;
    return d_sr_no
end;
COMMIT WORK;
GO 


create or replace procedure usp_st_err_tracking(  
  in @gsBr char(6),
  in @devID char(200),
  in @sKey char(20),
  in @UserId char(20),
  in @StageCode char(6),
  in @RackGrpCode char(300),
  in @cIndex char(30),
  in @HdrData char(7000),
  in @DetData char(32767),
  in @GodownCode char(6)) 
result( "is_xml_string" xml ) 
begin
/*
Author 		:  Vinay Kumar S
Procedure	: usp_st_err_tracking
SERVICE		: ws_st_err_tracking
Date 		  : 14-07-2022
--------------------------------------------------------------------------------------------------------------------------------
Modified By         Ldate               Index                       Changes
--------------------------------------------------------------------------------------------------------------------------------
Vinay Kumar S       19-07-22            supervisor_approve          Worked on the uf_get_new_tran function 
--------------------------------------------------------------------------------------------------------------------------------
*/
  --declaring the variables
  declare @BrCode char(6);
  declare @year char(6);
  declare @prefix char(6);
  declare @trans char(6);
  declare @trans_srno numeric(18,0);
  --setting the variables
  if @devID = '' or @devID is null then
    set @gsBr = "http_variable"('gsBr'); 
    set @devID = "http_variable"('devID'); 
    set @sKey = "http_variable"('sKey');
    set @UserId = "http_variable"('UserId');
    set @RackGrpCode = "http_variable"('RackGrpCode'); 
    set @StageCode = "http_variable"('StageCode'); 
    set @cIndex = "http_variable"('cIndex'); 
    set @HdrData = "http_variable"('HdrData'); 
    set @DetData = "http_variable"('DetData'); 
    set @GodownCode = "http_variable"('GodownCode') 		
  end if;
  set @BrCode = uf_get_br_code(@gsBr);
  set @year = right(db_name(),2);
  set @prefix ='Z';
  set @trans ='BTD';
  case @cIndex
  when 'supervisor_dashboard' then
  --http://192.168.0.102:22503/ws_st_err_tracking?&cIndex=supervisor_dashboard&gsbr=503&devID=993f34b165f1780017062022030807379&sKEY=sKey&UserId=S%20KAMBLE
    select 
        c_err_mark_user as conversion_user,
        st_err_track_det.c_black_tray_code as black_tray_code,
        st_err_track_det.c_item_code as item_code,
        item_mst.c_name as item_name,
        st_err_track_det.c_batch_no as batch_no,
        st_err_track_det.n_qty as err_qty,
        isnull(stock.n_bal_qty, 0) - isnull(stock.n_hold_qty, 0) - isnull(stk_godown.godown_bal_qty,0) as stk_bal_qty,
        n_err_type as err_type,
        CASE err_type
            WHEN 0 THEN 'ITEM SHORT'
            WHEN 1 THEN 'ITEM EXCESS'
            WHEN 2 THEN 'ITEM BREAKAGE/DAMAGED'
            WHEN 3 THEN 'WRONG ITEM'
            WHEN 4 THEN 'BATCH MISMATCH'
            ELSE 'NO REASON'
        END CASE as err_type_name,
        c_err_mark_user as err_mark_user,
        t_err_time as err_req_time,
        c_supervisor as spvr_name,
        t_spvr_err_marked_time as spvr_err_marked_time,
        st_err_track_det.c_doc_no,
        st_err_track_det.n_inout,
        st_err_track_det.n_seq,
        st_err_track_det.n_org_seq,
        st_err_track_det.c_tray_code,
        st_err_track_det.c_rack,
        st_err_track_det.c_rack_grp_code,
        st_err_track_det.c_stage_code,
        st_err_track_det.c_godown_code
    from st_err_track_det
    join item_mst on item_mst.c_code = st_err_track_det.c_item_code
    left join stock on stock.c_br_code = uf_get_br_code('000') and stock.c_item_code = st_err_track_det.c_item_code and stock.c_batch_no = st_err_track_det.c_batch_no
    left join (select c_br_code, c_item_code, c_batch_no, sum(stock_godown.n_qty - stock_godown.n_hold_qty) as godown_bal_qty 
                from stock_godown 
                group by  c_br_code, c_item_code, c_batch_no
              ) stk_godown 
              on stock.c_item_code = stk_godown.c_item_code 
              and stock.c_batch_no = stk_godown.c_batch_no
              and stock.c_br_code = stk_godown.c_br_code
    where st_err_track_det.n_complete = 0 for xml raw,elements
  when 'supervisor_approve' then
    CASE err_type
        WHEN 0 THEN --'ITEM SHORT'
            select uf_get_new_tran(@trans,@prefix) into @tran_srno;
        WHEN 1 THEN --'ITEM EXCESS'
            print 'ITEM EXCESS';
        WHEN 2 THEN --'ITEM BREAKAGE/DAMAGED'
            select uf_get_new_tran(@trans,@prefix) into @tran_srno;            
        WHEN 3 THEN --'WRONG ITEM'
            select uf_get_new_tran(@trans,@prefix) into @tran_srno;
        WHEN 4 THEN --'BATCH MISMATCH'
            print 'BATCH MISMATCH'
        ELSE --'NO REASON'
            print 'NO REASON';
    END CASE;
  end case
end;
commit work;
go
