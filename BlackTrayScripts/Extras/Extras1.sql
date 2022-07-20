begin
  declare @ColSep char(6);
  declare @RowSep char(6);
  declare @Pos integer;
  declare @ColPos integer;
  declare @RowPos integer;
  declare @ColMaxLen numeric(4);
  declare @RowMaxLen numeric(4);
  declare @DetData char(30000);

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

  set @DetData = '0^^314/22/O/16^^3^^1^^21417^^20073^^P20A^^P20^^-^^88888^^237835^^330858D7^^15.000^^0^^TEST^^2022-07-15 17:26:24.507^^DILEEP^^2022-07-15 17:28:38.476^^||0^^314/22/O/16^^3^^1^^21417^^20073^^P20A^^P20^^-^^88888^^237835^^330858D7^^15.000^^0^^TEST^^2022-07-15 17:26:24.507^^DILEEP^^2022-07-15 17:28:38.476^^||';
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
 
  	select "Locate"(@DetData,@RowSep) into @RowPos;
  	set @DetData = "SubString"(@DetData,@RowPos+@RowMaxLen);      
  end loop;
end 
