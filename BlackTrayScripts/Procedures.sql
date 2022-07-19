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
declare @carton_no char(6);
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
            print 'ITEM SHORT';
        WHEN 1 THEN --'ITEM EXCESS'
            print 'ITEM EXCESS';
        WHEN 2 THEN --'ITEM BREAKAGE/DAMAGED'
            print 'ITEM BREAKAGE/DAMAGED';
        WHEN 3 THEN --'WRONG ITEM'
            print 'WRONG ITEM';
        WHEN 4 THEN --'BATCH MISMATCH'
            print 'BATCH MISMATCH'
        ELSE --'NO REASON'
            print 'NO REASON';
    END CASE;
  end case
end;
commit work;
go