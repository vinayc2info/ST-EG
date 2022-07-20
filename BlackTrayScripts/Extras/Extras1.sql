begin
  declare @ColSep char(6);
  declare @RowSep char(6);
  declare @Pos integer;
  declare @ColPos integer;
  declare @RowPos integer;
  declare @ColMaxLen numeric(4);
  declare @RowMaxLen numeric(4);
  declare @DetData char(30000);
  declare @CustCode char(6);

  declare @InOutFlag numeric(4);
  declare @DocNo char(25);
  declare @Seq numeric(6);
  declare @OrgSeq numeric(6);
  declare @TrayCode char(6);
  declare @RackCode char(6);
  declare @RackGrpCode char(6);
  declare @StageCode char(6);
  declare @GodownCode char(6);
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

  set @DetData = '0^^325/22/O/16^^3^^1^^21417^^20073^^P20A^^P20^^-^^88888^^237835^^330858D7^^15.000^^0^^TEST^^2022-07-15 17:26:24.507^^DILEEP^^2022-07-15 17:28:38.476^^||0^^314/22/O/16^^3^^1^^21417^^20073^^P20A^^P20^^-^^88888^^237836^^330858D7^^15.000^^0^^TEST^^2022-07-15 17:26:24.507^^DILEEP^^2022-07-15 17:28:38.476^^||
                  0^^325/22/O/16^^3^^1^^21417^^20073^^P20A^^P20^^-^^88888^^237837^^330858D8^^15.000^^0^^TEST^^2022-07-15 17:26:24.507^^DILEEP^^2022-07-15 17:28:38.476^^||0^^314/22/O/16^^3^^1^^21417^^20073^^P20A^^P20^^-^^88888^^237838^^330858D9^^15.000^^0^^TEST^^2022-07-15 17:26:24.507^^DILEEP^^2022-07-15 17:28:38.476^^||';
  select "c_delim" into @ColSep from "ps_tab_delimiter" where "n_seq" = 0;
  select "c_delim" into @RowSep from "ps_tab_delimiter" where "n_seq" = 1;
  set @ColMaxLen = "Length"(@ColSep);
  set @RowMaxLen = "Length"(@RowSep);

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
  	set @RackGrpCode = "Trim"("Left"(@DetData,@ColPos-1));
  	set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
  	--c_stage_code
  	select "Locate"(@DetData,@ColSep) into @ColPos;
  	set @StageCode = "Trim"("Left"(@DetData,@ColPos-1));
  	set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
  	--c_godown_code
  	select "Locate"(@DetData,@ColSep) into @ColPos;
  	set @GodownCode = "Trim"("Left"(@DetData,@ColPos-1));
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
    (n_inout,n_doc_seq,n_item_seq, c_cust_code,c_doc_no,n_seq ,n_org_seq ,c_tray_code ,c_rack,c_rack_grp_code ,c_stage_code ,c_godown_code,black_tray_code,item_code,batch_no,
    err_qty ,err_type,err_mark_user,err_req_time,spvr_name,spvr_err_marked_time) 
    (select 
        dense_rank() over (order by c_cust_code asc) n_doc_seq,
        row_number() over (partition by c_cust_code order by c_doc_no asc) n_item_seq,n_inout,c_cust_code,c_doc_no,n_seq ,n_org_seq ,c_tray_code ,
        c_rack,c_rack_grp_code ,c_stage_code ,c_godown_code,black_tray_code,item_code,batch_no,
        err_qty ,err_type,err_mark_user,err_req_time,spvr_name,spvr_err_marked_time
     from temp_black_tray_det);
    select count(distinct c_cust_code) into @cust_cnt from temp_cust_seq_wise_black_tray_det;
    select * from temp_cust_seq_wise_black_tray_det;

    

  --select @cust_cnt; return;
//  WHILE @cust_cnt > 0 loop
//    --begin 
//    --message @cust_cnt to client;

//    SET @cust_cnt = @cust_cnt - 1;
//  end loop;

//    select 
//      uf_get_br_code('000') as c_br_code,
//      right(db_name(),2) as c_year,
//      'Z' as c_prefix,
//      uf_get_new_tran('BTD',c_prefix) as n_srno,
//      0 as n_inout,
//      today() as d_date,
//      c_cust_code,
//      spvr_name as c_supervisor,
//      2 as n_store_track,
//      today() as d_ldate,
//      now() as t_ltime
//    from temp_black_tray_det;

//    select 
//      uf_get_br_code('000') as c_br_code,
//      right(db_name(),2) as c_year,
//      'Z' as c_prefix,
//      uf_get_new_tran('BTD',c_prefix) as n_srno,
//      0 as n_inout,
//      number(*) as n_seq,today() as d_date,
//      item_code as c_item_code,batch_no as c_batch_no,err_qty as n_qty,c_rack,c_rack_grp_code,c_stage_code,c_godown_code,
//      black_tray_code as c_black_tray_code,err_type as n_err_type,c_doc_no as c_ref_doc_no,n_inout as n_ref_inout,n_seq as n_ref_pick_seq,n_org_seq as n_ref_org_seq,
//      2 as n_store_track,today() as d_ldate,now() as t_ltime
//    from temp_black_tray_det;
end

//select * from black_tray_mst
//select * from black_tray_det
 


