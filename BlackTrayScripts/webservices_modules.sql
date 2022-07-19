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
result( is_xml_string xml ) 
begin
  --declaring the variables
  declare @BrCode char(6);
  declare @c_year char(6);
  declare @c_prefix char(6);
  declare @n_srno numeric(18,0);
  declare @c_trans char(6);
  --setting the variables
  if @devID = '' or @devID is null then
    set @gsBr = http_variable('gsBr'); 
    set @devID = http_variable('devID'); 
    set @sKey = http_variable('sKey');
    set @UserId = http_variable('UserId');
    set @RackGrpCode = http_variable('RackGrpCode'); 
    set @StageCode = http_variable('StageCode'); 
    set @cIndex = http_variable('cIndex'); 
    set @HdrData = http_variable('HdrData'); 
    set @DetData = http_variable('DetData'); 
    set @GodownCode = http_variable('GodownCode') 		
  end if;
  set @BrCode = uf_get_br_code(@gsBr);
  select right(db_name(),2) into @c_year;
  set @c_prefix = '500';
  set @c_trans = 'BTD';

  case @cIndex
  when 'supervisor_dashboard' then
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
        t_spvr_err_marked_time as spvr_err_marked_time
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
  when 'supervisor_approved' then
    CASE err_type
      WHEN 0 THEN --'ITEM SHORT'
        select n_sr_number into @n_srno from prefix_serial_no where c_br_code = @BrCode and c_year = @c_year  and c_prefix = @c_prefix and c_trans= @c_trans;
        update prefix_serial_no set n_sr_number = n_sr_number+1 where c_br_code = @BrCode and c_year = @year and c_prefix = @ire_prefix and C_TRANS = @c_trans;               
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