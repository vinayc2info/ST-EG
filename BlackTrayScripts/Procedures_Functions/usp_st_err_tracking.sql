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
Vinay Kumar S       19-07-22            supervisor_approve          Worked on DetData string and inserting into temp_table 
--------------------------------------------------------------------------------------------------------------------------------
*/
  --declaring the variables
  declare @BrCode char(6);
  declare @year char(6);
  declare @prefix char(6);
  declare @trans char(6);
  declare @trans_srno numeric(18,0);
  declare @ColSep char(6);
  declare @RowSep char(6);
  declare @Pos integer;
  declare @ColPos integer;
  declare @RowPos integer;
  declare @ColMaxLen numeric(4);
  declare @RowMaxLen numeric(4);
  declare @CustCode char(6);
  declare @InOutFlag numeric(4);
  declare @DocNo char(25);
  declare @Seq numeric(6);
  declare @OrgSeq numeric(6);
  declare @TrayCode char(6);
  declare @RackCode char(6);
  declare @Rack_Grp_Code char(6);
  declare @Stage_Code char(6);
  declare @Godown_Code char(6);
  declare @BlackTrayCode char(6);
  declare @ItemCode char(6);
  declare @BatchNo char(15);
  declare @ErrQty numeric(11);
  declare @ErrType numeric(2);
  declare @ErrMarkUser char(15);
  declare @ErrMarkTime char(25);
  declare @SupervisorName char(15);
  declare @SupervisorMarkTime char(25);
  declare @cust_cnt int;
  declare @doc_cnt int;
  declare @new_srno numeric(18,0);
  declare local temporary table temp_black_tray_det(
    n_inout integer,
    c_cust_code char(6),
    c_doc_no char(25),
    n_seq numeric(6),
    n_org_seq numeric(6),
    c_tray_code char(6),
    c_rack char(6),
    c_rack_grp_code char(6),
    c_stage_code char(6),
    c_godown_code char(6),
    black_tray_code char(6),
    item_code char(6),
    batch_no char(15),
    err_qty numeric(11),
    err_type integer,
    err_mark_user char(15),
    err_req_time datetime,
    spvr_name char(15),
    spvr_err_marked_time datetime,
  primary key(n_inout asc, c_doc_no asc, n_seq asc, n_org_seq asc, item_code asc, batch_no asc, err_type asc)
  ) on commit preserve rows;
  declare local temporary table temp_cust_seq_wise_black_tray_det(
    n_inout integer,
    n_cust_seq integer,
    n_doc_seq integer,
    n_item_seq integer,
    c_cust_code char(6),
    c_doc_no char(25),
    n_seq numeric(6),
    n_org_seq numeric(6),
    c_tray_code char(6),
    c_rack char(6),
    c_rack_grp_code char(6),
    c_stage_code char(6),
    c_godown_code char(6),
    black_tray_code char(6),
    item_code char(6),
    batch_no char(15),
    err_qty numeric(11),
    err_type integer,
    err_mark_user char(15),
    err_req_time datetime,
    spvr_name char(15),
    spvr_err_marked_time datetime,
  primary key(n_inout asc, c_doc_no asc, n_seq asc, n_org_seq asc, item_code asc, batch_no asc, err_type asc)
  ) on commit preserve rows;
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
  select "c_delim" into @ColSep from "ps_tab_delimiter" where "n_seq" = 0;
  select "c_delim" into @RowSep from "ps_tab_delimiter" where "n_seq" = 1;
  set @ColMaxLen = "Length"(@ColSep);
  set @RowMaxLen = "Length"(@RowSep);
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
    left join stock on stock.c_br_code = @BrCode and stock.c_item_code = st_err_track_det.c_item_code and stock.c_batch_no = st_err_track_det.c_batch_no
    left join (select c_br_code, c_item_code, c_batch_no, sum(stock_godown.n_qty - stock_godown.n_hold_qty) as godown_bal_qty 
                from stock_godown 
                group by  c_br_code, c_item_code, c_batch_no
              ) stk_godown 
              on stock.c_item_code = stk_godown.c_item_code 
              and stock.c_batch_no = stk_godown.c_batch_no
              and stock.c_br_code = stk_godown.c_br_code
    where st_err_track_det.n_complete = 0 for xml raw,elements
  when 'supervisor_approve' then
  --http://172.16.17.64:22503/ws_st_err_tracking?&cIndex=supervisor_approve&DetData=0^^325/22/O/16^^3^^1^^21417^^20073^^P20A^^P20^^-^^88888^^237835^^330858D7^^15.000^^0^^TEST^^2022-07-15 17:26:24.507^^DILEEP^^2022-07-15 17:28:38.476^^||0^^314/22/O/16^^3^^1^^21417^^20073^^P20A^^P20^^-^^88888^^237836^^330858D7^^15.000^^0^^TEST^^2022-07-15 17:26:24.507^^DILEEP^^2022-07-15 17:28:38.476^^||0^^325/22/O/16^^3^^1^^21417^^20073^^P20A^^P20^^-^^88888^^237837^^330858D8^^15.000^^2^^TEST^^2022-07-15 17:26:24.507^^DILEEP^^2022-07-15 17:28:38.476^^||0^^314/22/O/16^^3^^1^^21417^^20073^^P20A^^P20^^-^^88888^^237838^^330858D9^^15.000^^0^^TEST^^2022-07-15 17:26:24.507^^DILEEP^^2022-07-15 17:28:38.476^^||0^^325/22/O/16^^3^^1^^21417^^20073^^P20A^^P20^^-^^88888^^237837^^330858D8^^15.000^^3^^TEST^^2022-07-15 17:26:24.507^^DILEEP^^2022-07-15 17:28:38.476^^||&gsbr=503&devID=993f34b165f1780017062022030807379&sKEY=sKey&UserId=S KAMBLE
  while @DetData <> '' loop
  	--n_inout
  	select "Locate"(@DetData,@ColSep) into @ColPos;
  	set @InOutFlag = "Trim"("Left"(@DetData,@ColPos-1));
  	set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
  	--c_doc_no
  	select "Locate"(@DetData,@ColSep) into @ColPos;
  	set @DocNo = "Trim"("Left"(@DetData,@ColPos-1));
  	set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
  	--n_seq
  	select "Locate"(@DetData,@ColSep) into @ColPos;
  	set @Seq = "Trim"("Left"(@DetData,@ColPos-1));
  	set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
  	--n_org_seq
  	select "Locate"(@DetData,@ColSep) into @ColPos;
  	set @OrgSeq = "Trim"("Left"(@DetData,@ColPos-1));
  	set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
  	--c_tray_code
  	select "Locate"(@DetData,@ColSep) into @ColPos;
  	set @TrayCode = "Trim"("Left"(@DetData,@ColPos-1));
  	set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
  	--c_rack
  	select "Locate"(@DetData,@ColSep) into @ColPos;
  	set @RackCode = "Trim"("Left"(@DetData,@ColPos-1));
  	set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
  	--c_rack_grp_code
  	select "Locate"(@DetData,@ColSep) into @ColPos;
  	set @Rack_Grp_Code = "Trim"("Left"(@DetData,@ColPos-1));
  	set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
  	--c_stage_code
  	select "Locate"(@DetData,@ColSep) into @ColPos;
  	set @Stage_Code = "Trim"("Left"(@DetData,@ColPos-1));
  	set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
  	--c_godown_code
  	select "Locate"(@DetData,@ColSep) into @ColPos;
  	set @Godown_Code = "Trim"("Left"(@DetData,@ColPos-1));
  	set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
  	--black_tray_code
  	select "Locate"(@DetData,@ColSep) into @ColPos;
  	set @BlackTrayCode = "Trim"("Left"(@DetData,@ColPos-1));
  	set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
  	--item_code
  	select "Locate"(@DetData,@ColSep) into @ColPos;
  	set @ItemCode = "Trim"("Left"(@DetData,@ColPos-1));
  	set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
  	--batch_no
  	select "Locate"(@DetData,@ColSep) into @ColPos;
  	set @BatchNo = "Trim"("Left"(@DetData,@ColPos-1));
  	set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
  	--err_qty
  	select "Locate"(@DetData,@ColSep) into @ColPos;
  	set @ErrQty = "Trim"("Left"(@DetData,@ColPos-1));
  	set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
  	--err_type
  	select "Locate"(@DetData,@ColSep) into @ColPos;
  	set @ErrType = "Trim"("Left"(@DetData,@ColPos-1));
  	set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
  	--err_mark_user
  	select "Locate"(@DetData,@ColSep) into @ColPos;
  	set @ErrMarkUser = "Trim"("Left"(@DetData,@ColPos-1));
  	set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
  	--err_req_time
  	select "Locate"(@DetData,@ColSep) into @ColPos;
  	set @ErrMarkTime = "Trim"("Left"(@DetData,@ColPos-1));
  	set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
  	--spvr_name
  	select "Locate"(@DetData,@ColSep) into @ColPos;
  	set @SupervisorName = "Trim"("Left"(@DetData,@ColPos-1));
  	set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
  	--spvr_err_marked_time
  	select "Locate"(@DetData,@ColSep) into @ColPos;
  	set @SupervisorMarkTime = "Trim"("Left"(@DetData,@ColPos-1));
  	set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);   
      select c_cust_code into @CustCode from st_track_mst  where n_inout = @InOutFlag and c_doc_no = @DocNo;
      insert into temp_black_tray_det 
        (n_inout,c_cust_code,c_doc_no,n_seq ,n_org_seq ,c_tray_code ,c_rack,c_rack_grp_code ,c_stage_code ,c_godown_code,black_tray_code,item_code,batch_no,
        err_qty ,err_type,err_mark_user,err_req_time,spvr_name,spvr_err_marked_time) 
      on existing skip values 
        (@InOutFlag,isnull(@CustCode,'325'), @DocNo,@Seq,@OrgSeq ,@TrayCode ,@RackCode ,@RackGrpCode ,@StageCode ,@GodownCode ,@BlackTrayCode,@ItemCode ,@BatchNo ,
        @ErrQty ,@ErrType ,@ErrMarkUser ,@ErrMarkTime ,@SupervisorName ,@SupervisorMarkTime); 
      set @CustCode = null;   
  	select "Locate"(@DetData,@RowSep) into @RowPos;
  	set @DetData = "SubString"(@DetData,@RowPos+@RowMaxLen);   
  end loop;
  insert into temp_cust_seq_wise_black_tray_det 
    (n_inout,n_cust_seq,n_doc_seq,n_item_seq, c_cust_code,c_doc_no,n_seq ,n_org_seq ,c_tray_code ,c_rack,c_rack_grp_code ,c_stage_code ,c_godown_code,black_tray_code,item_code,batch_no,
    err_qty ,err_type,err_mark_user,err_req_time,spvr_name,spvr_err_marked_time) 
    (select n_inout,
        dense_rank() over (order by c_cust_code asc) n_cust_seq,
        dense_rank() over (order by err_type asc) n_doc_seq,
        row_number() over (partition by c_cust_code ,err_type order by c_doc_no asc) n_item_seq,
        c_cust_code,c_doc_no,n_seq ,n_org_seq ,c_tray_code ,
        c_rack,c_rack_grp_code ,c_stage_code ,c_godown_code,black_tray_code,item_code,batch_no,
        err_qty ,err_type,err_mark_user,err_req_time,spvr_name,spvr_err_marked_time
     from temp_black_tray_det);
    select count(distinct n_cust_seq) into @cust_cnt from temp_cust_seq_wise_black_tray_det;
    WHILE @cust_cnt > 0 loop
      select count(distinct n_doc_seq) into @doc_cnt 
      from temp_cust_seq_wise_black_tray_det where n_cust_seq = @cust_cnt;
        while @doc_cnt >0 loop
          select uf_get_new_tran(@trans,@prefix) into @new_srno;
          insert into black_tray_mst
          select distinct 
            @BrCode as c_br_code,
            @year as c_year,
            @prefix as c_prefix,
            @new_srno as n_srno,
            0 as n_inout,
            today() as d_date,
            c_cust_code,
            spvr_name as c_supervisor,
            2 as n_store_track,
            today() as d_ldate,
            now() as t_ltime
          from temp_cust_seq_wise_black_tray_det 
          where n_cust_seq = @cust_cnt
            and n_doc_seq = @doc_cnt
            and err_type in (0,2,3);
          insert into black_tray_det
          select 
            @BrCode as c_br_code,
            @year as c_year,
            @prefix as c_prefix,
            @new_srno as n_srno,
            0 as n_inout,
            n_item_seq as n_seq,
            today() as d_date,
            item_code as c_item_code,
            batch_no as c_batch_no,
            err_qty as n_qty,
            c_rack,
            c_rack_grp_code,
            c_stage_code,
            c_godown_code,
            black_tray_code as c_black_tray_code,
            err_type as n_err_type,
            c_doc_no as c_ref_doc_no,
            n_inout as n_ref_inout,
            n_seq as n_ref_pick_seq,
            n_org_seq as n_ref_org_seq,
            2 as n_store_track,
            today() as d_ldate,
            now() as t_ltime
          from temp_cust_seq_wise_black_tray_det 
          where n_cust_seq = @cust_cnt
            and n_doc_seq = @doc_cnt 
            and err_type in (0,2,3);
          // Reminder: Need to update st_track_err_det with ref_doc_no ,seq, n_inout , supervisor, supervisor_marked_time , n_complete
          SET @doc_cnt = @doc_cnt - 1;
        end loop;
      SET @cust_cnt = @cust_cnt - 1;
    end loop;
    if sqlstate = '00000' or sqlstate = '02000' then
      commit work;
      select 1 as "n_status",
      'Success' as "c_message" for xml raw,elements
    else
      rollback work;
      select 0 as "n_status",
      'Failure' as "c_message" for xml raw,elements
    end if;
//    CASE err_type
//        WHEN 0 THEN --'ITEM SHORT'
//        WHEN 1 THEN --'ITEM EXCESS'            
//        WHEN 2 THEN --'ITEM BREAKAGE/DAMAGED'      
//        WHEN 3 THEN --'WRONG ITEM'
//        WHEN 4 THEN --'BATCH MISMATCH'            
//        ELSE --'NO REASON'
//    END CASE;
  end case
end;
commit work;
go
