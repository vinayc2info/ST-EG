CREATE PROCEDURE "DBA"."usp_new_delivery_slip"()
result( "is_xml_string" xml ) 
begin
  /*
Author          :   Vinay Kumar  
Product         :   EcoGreen
Procedure       :   usp_new_delivery_slip
SERVICE         :   ws_new_delivery_slip
Date            :   22-09-2021 
API             :   1. http://172.16.18.20:19503/ws_new_delivery_slip?&cIndex=get_route&TrayCartonCode=0000003394&gsbr=503&devID=a3dcefdf75bc646d105092019064846055&UserId=s%20kamble
2. http://172.16.18.20:19503/ws_new_delivery_slip?&cIndex=check_route_pending_trays&regioncode=RT0001&gsbr=503&devID=a3dcefdf75bc646d105092019064846055&UserId=s kamble
4. http://172.16.18.20:19503/ws_new_delivery_slip?&cIndex=branchwise_doc_insert&regioncode=RT0001&DocList=503/19/N/156408^^503/19/N/156453^^503/19/N/156298^^503/19/N/156085^^503/19/N/156087^^503/19/N/156318^^503/19/N/156465^^503/19/N/156026^^503/19/N/156396^^503/19/N/156209^^&slipSrno=0&GodownCode=-&gsbr=503&devID=a3dcefdf75bc646d105092019064846055&sKEY=sKey&UserId=s kamble
3. http://172.16.18.20:19503/ws_new_delivery_slip?&cIndex=get_trays_in_route&regioncode=RT0001&gsbr=503&devID=a3dcefdf75bc646d105092019064846055&UserId=s kamble 
5s. http://172.16.18.20:19503/ws_new_delivery_slip?&cIndex=get_tray_list_for_confirmation&TrayCode=0000003393&GodownCode=-&gsbr=503&devID=a3dcefdf75bc646d105092019064846055&sKEY=sKey&UserId=s kamble
http://172.16.18.20:19503/ws_new_delivery_slip?&cIndex=get_tray_list_for_confirmation&TrayCode=00000034546&RackGrpCode=null&StageCode=null&GodownCode=&gsbr=503&devID=a3dcefdf75bczzaw646d105092019064846055&sKEY=sKey&UserId=myboss
6s. http://172.16.18.20:19503/ws_new_delivery_slip?&cIndex=branchwise_security_confirmation&regioncode=RT0008&DocList=503/19/N/156408^^503/19/N/156453^^503/19/N/156298^^503/19/N/156085^^503/19/N/156087^^503/19/N/156318^^&slipSrno=0&GodownCode=-&gsbr=503&devID=a3dcefdf75bc646d105092019064846055&sKEY=sKey&UserId=s kamble
8s. http://172.16.18.20:19503/ws_new_delivery_slip?&cIndex=document_post&DocNo=503/19/N/156465^^503/19/N/156465^^503/19/N/156465^^503/19/N/156026^^503/19/N/156396^^503/19/N/156209^^503/19/N/156209^^503/19/N/156209^^503/19/N/156209^^503/19/N/156453^^503/19/N/156453^^503/19/N/156087^^503/19/N/156408^^503/19/N/156318^^503/19/N/156298^^503/19/N/156085^^503/19/N/156453^^&TransportCode=TM0002&DriverName=vks&DriverPhno=9999999999&LRNumber=ka01ry2344&DmanCode=DM0702&GodownCode=-&gsbr=503&devID=a3dcefdf75bc646d105092019064846055&sKEY=sKey&UserId=s kamble
http://172.16.18.20:19503/ws_new_delivery_slip?&cIndex=register_device&gsbr=503&devID=a3dcefdf75bc646d105092019064846055&UserId=s kamble 
7. http://172.16.18.20:19503/ws_new_delivery_slip?&cIndex=document_insert&regioncode=RT0008&slipSrno=0&GodownCode=-&gsbr=503&devID=a3dcefdf75bc646d105092019064846055&sKEY=sKey&UserId=s%20kamble
9s. http://172.16.18.20:19503/ws_new_delivery_slip?&cIndex=check_pending_branches&regioncode=RT0001&gsbr=503&devID=a3dcefdf75bc646d105092019064846055&UserId=s kamble
10. http://172.16.18.20:19503/ws_new_delivery_slip?&cIndex=deli_slip_details&regioncode=RT0001&gsbr=503&devID=a3dcefdf75bc646d105092019064846055&UserId=s kamble
http://172.16.18.20:19503/ws_new_delivery_slip?&cIndex=get_route&TrayCartonCode=0000003394&SecurityConfirmation=1&gsbr=503&devID=a3dcefdf75bc646d105092019064846055&UserId=s%20kamble
--------------------------------------------------------------------------------------------------------------------------
Modified By     ModifiedDate                ticketNo    IndexName                           Purpose                                 
---------------------------------------------------------------------------------------------------------------------------
Vinay Kumar S   22-09-2021 13:00            B80473      get_route,check_route_pending_trays                                                
Vinay Kumar S   23-09-2021 09:00            B80473      branchwise_doc_insert
Vinay Kumar S   24-09-2021 10:10            B80473      get_trays_in_route
Pratheesh   p   17-11-2021 17:28                        deli_slip_details           Added new index deli_slip_details fetching data from delivery table
Pratheesh   p   29-11-2021 17:28                        deli_slip_details           error not showing data issue fixed
Pratheesh   p   30-11-2021 10:15                        deli_slip_details           tracycode replicate zero , remove completed
Pratheesh   P   06-12-2011  11:15            C16684      document_post               DMANCODE,LRNO,Mobileno not updating to slip_mst issue fixed
Pratheesh   P   06-12-2011  22:17                        document_insert             null value while inserting slip_det - commanded delivery_slip_det table seletion
Pratheesh   P   07-12-2011  12:03                        get_route                   document_insert             delivery slip no is not generating properly
Pratheesh   P   08-12-2011  09:38                        get_route                   SecurityConfirmation parameter added to api and checked in where clause
Pratheesh   P   16-12-2011  18:18                        get_route                   "HTTP_VARIABLE"('TrayCartonCode') ----> "HTTP_VARIABLE"('TrayCode_corton');
Pratheesh   P   20-12-2011  18:18                        get_trays_in_route          limited data within 2weeks...slowness issue
Pratheesh   P   21-12-2011  11:09                        get_trays_in_route          limited data within 2weeks...slowness issue
Pratheesh   P   28-01-2012  11:09                        get_trays_in_route          limited data within 2weeks...slowness issue
Pratheesh   P   28-01-2012  17:21                        get_trays_in_route          limited data within 2weeks...slowness issue
Pratheesh   P   31-01-2012  10:21                        get_trays_in_route          insert tmp table error fixed
Pratheesh   P   07-06-2022  11:15                        document_post               print issue respense missing fixed
---------------------------------------------------------------------------------------------------------------------------
*/
  declare @days_to_allow_new_deliveryslip char(3);
  declare @shelf_code char(6);
  declare @HdrData char(1000);
  declare @li_tray_cnt numeric(6);
  declare @li_doc_cnt numeric(6);
  declare @li_internal_tray_cnt numeric(6);
  declare @TrayCode char(12);
  declare @cIndex char(100);
  declare @TrayCode_corton char(100);
  declare @doc_no char(25);
  declare @carton_no numeric(9);
  declare @gsBr char(6);
  declare @c_slipPrefix char(4);
  declare @c_slipyear char(4);
  declare @n_slipSrno numeric(9);
  declare @n_slipseq numeric(9);
  declare @nPrefixCount numeric(6);
  declare @d_date date;
  declare @d_exptd_rtn_date date;
  declare @t_exptd_rtn_time time;
  declare @n_status numeric(1);
  declare @n_del_charge numeric(12,2);
  declare @n_del_act char(6);
  declare @c_dman_code char(6);
  declare @n_tender_amt numeric(12,2);
  declare @n_del_charge_rtn numeric(12,2);
  declare @n_tender_amt_rtn numeric(12,2);
  declare @c_tender_act char(6);
  declare @c_voucher1 char(15);
  declare @c_voucher2 char(15);
  declare @c_voucher3 char(15);
  declare @c_voucher4 char(15);
  declare @n_shift numeric(6);
  declare @n_return_shift numeric(6);
  declare @n_cash_session_id numeric(8);
  declare @n_return_cash_session_id numeric(8);
  declare @n_cancel_flag numeric(1);
  declare @c_user char(10);
  declare @d_completed_date date;
  declare @t_completed_time time;
  declare @c_sman_code char(6);
  declare @c_lr_no char(20);
  declare @c_transport char(6);
  declare @c_driver_name char(20);
  declare @c_driver_phno char(20);
  declare @c_modiuser char(10);
  declare @c_computer_name char(40);
  declare @c_sys_user char(30);
  declare @c_sys_ip char(30);
  declare @c_order_id char(100);
  declare @d_ldate date;
  declare @t_ltime "datetime";
  declare @c_cust_code char(6);
  declare @inv_tot numeric(12,2);
  declare @n_tender numeric(12,2);
  declare @n_tender_given numeric(12,2);
  declare @n_tender_rtn numeric(12,2);
  declare @n_flag numeric(1);
  declare @n_tender_type numeric(1);
  declare @c_crn_no char(15);
  declare @c_remark char(200);
  declare @d_reschedule_date date;
  declare @d_reschedule_time time;
  declare @c_reason_code char(6);
  declare @n_item_length numeric(9,4);
  declare @n_item_weight numeric(9,4);
  declare @n_item_height numeric(9,4);
  declare @n_item_breadth numeric(9,4);
  declare @c_dispatch_ref_no char(30);
  declare @l_new_doc numeric(1);
  declare @route_code char(30);
  declare @slip_doc_no char(30);
  declare @Cnt numeric(1);
  declare @ls_array_list char(500);
  declare @ls_array char(500);
  declare @crtn_Br char(6);
  declare @crtn_cYear char(2);
  declare @crtn_cPrefix char(4);
  declare @crtn_nSrno numeric(9);
  declare @tray_code char(12);
  declare @carton_code numeric(9);
  declare @ld_cancel_flag numeric(9);
  declare @ld_approved numeric(1);
  declare @d_dt date;
  declare @c_doc_list char(7000);
  declare @c_doc_no char(7000);
  declare @n_new_slip_no numeric(9);
  declare @cbrcode char(6);
  declare @cyear char(6);
  declare @cprefix char(6);
  declare @nsrno numeric(9);
  declare @ColSep char(6);
  declare @RowSep char(6);
  declare @Pos integer;
  declare @ColPos integer;
  declare @RowPos integer;
  declare @ColMaxLen numeric(4);
  declare @RowMaxLen numeric(4);
  declare @slip_doc_1 char(50);
  declare @slip_doc_2 char(50);
  declare @not_in_cnt integer;
  declare @not_in_val char(10000);
  declare @inv_cnt integer;
  declare @route_cnt integer;
  declare @PRINT_DELIVERY_SLIP_FROM_TAB numeric(4);
  declare @SecurityConfirmation numeric(1);
  declare @tmp_date date;
  declare @min integer = 1;
  declare @max integer = 0;
  declare @c_slip_br_code char(6);
  declare @c_slip_year char(6);
  declare @c_slip_prefix char(6);
  declare @n_slip_srno numeric(14);
  --  declare local temporary table "temp_carton_mst"(
  --    "c_br_code" char(6) not null,
  --    "c_year" char(2) not null,
  --    "c_prefix" char(4) not null,
  --    "n_srno" numeric(9) not null,
  --    "c_item_code" char(6) not null,
  --    "c_batch_no" char(15) not null,
  --    "c_tray_code" char(6) not null,
  --    "n_carton_no" numeric(9) not null default 0,
  --    "n_qty" numeric(10) not null default 0,
  --    "n_seq1" numeric(5) not null default 0,
  --    "n_lot" numeric(5) not null default 0,
  --    "n_month" numeric(2) not null default 0,
  --    "n_flag" numeric(1) not null default 0,
  --    "d_ldate" date null,
  --    "t_ltime" timestamp null default current timestamp,
  --    "c_dispatch_ref_no" char(30) null,
  --    primary key("c_br_code" asc,"c_year" asc,"c_prefix" asc,"n_srno" asc,"c_item_code" asc,"c_batch_no" asc,"c_tray_code" asc,"n_carton_no" asc),) on commit preserve rows;
  declare local temporary table "temp_carton_mst"(
    "c_br_code" char(6) not null,
    "c_year" char(2) not null,
    "c_prefix" char(4) not null,
    "n_srno" numeric(9) not null,
    "c_tray_code" char(6) not null,
    "n_carton_no" numeric(9) not null default 0,
    "c_item_code" char(6) not null,
    primary key("c_br_code" asc,"c_year" asc,"c_prefix" asc,"n_srno" asc,"c_tray_code" asc,"n_carton_no" asc),) on commit preserve rows;
  declare local temporary table "doc_tary_list"(
    "tray_carton_list" char(12) null,
    "c_cust_code" char(6) null,
    "c_name" char(40) null,
    "c_doc_no" char(25) null,
    "c_brcode" char(6) null,
    "c_top_item_code" char(6) null,
    "c_route_seq" char(6) null,
    ) on commit preserve rows;
  declare local temporary table "Slip_doc_list"(
    "id_temp" integer null default autoincrement,
    "c_slip_br_code" char(6) not null,
    "c_slip_year" char(6) not null,
    "c_slip_prefix" char(6) not null,
    "n_slip_srno" numeric(14) not null,
    primary key("c_slip_br_code" asc,"c_slip_year" asc,"c_slip_prefix" asc,"n_slip_srno" asc),
    ) on commit preserve rows;
  if @cIndex = '' or @cIndex is null then
    set @cIndex = "http_variable"('cIndex'); --1
    set @c_user = "upper"("HTTP_VARIABLE"('c_user'))
  end if;
  set @route_code = "HTTP_VARIABLE"('regioncode');
  --set @TrayCode_corton = "HTTP_VARIABLE"('TrayCartonCode');
  set @TrayCode_corton = "HTTP_VARIABLE"('TrayCode_corton');
  set @c_doc_list = "HTTP_VARIABLE"('DocList');
  set @c_doc_no = "HTTP_VARIABLE"('DocNo');
  set @n_new_slip_no = "HTTP_VARIABLE"('slipSrno');
  set @gsBr = "HTTP_VARIABLE"('gsbr');
  set @tray_code = "HTTP_VARIABLE"('traycode');
  set @c_transport = "HTTP_VARIABLE"('TransportCode');
  set @c_driver_name = "HTTP_VARIABLE"('DriverName');
  set @c_driver_phno = "HTTP_VARIABLE"('DriverPhno');
  set @c_lr_no = "HTTP_VARIABLE"('LRNumber');
  set @c_dman_code = "HTTP_VARIABLE"('DmanCode');
  set @c_user = "HTTP_VARIABLE"('UserId');
  set @SecurityConfirmation = "HTTP_VARIABLE"('SecurityConfirmation');
  set @slip_doc_1 = '';
  set @slip_doc_2 = '';
  select "c_delim" into @ColSep from "ps_tab_delimiter" where "n_seq" = 0;
  select "c_delim" into @RowSep from "ps_tab_delimiter" where "n_seq" = 1;
  if @ColSep is null or @ColSep = '' then
    select '--------------------\x0D\x0ASQL error: usp_delivery_slip No Delimiter Defined';
    return
  end if;
  set @ColMaxLen = "Length"(@ColSep);
  set @RowMaxLen = "Length"(@RowSep);
  set @c_slipPrefix = '7';
  select "right"("db_name"(),2) into @c_slipyear;
  set @d_date = "DBA"."uf_default_date"();
  --set @c_dman_code = '-';
  set @d_exptd_rtn_date = null;
  set @t_exptd_rtn_time = null;
  set @n_status = 0;
  set @n_del_charge = 0;
  set @n_del_act = null;
  set @n_tender_amt = 0;
  set @n_del_charge_rtn = 0;
  set @n_tender_amt_rtn = 0;
  set @c_tender_act = null;
  set @c_voucher1 = null;
  set @c_voucher2 = null;
  set @c_voucher3 = null;
  set @c_voucher4 = null;
  set @n_shift = 0;
  set @n_return_shift = 0;
  set @n_cash_session_id = 0;
  set @n_return_cash_session_id = 0;
  set @n_cancel_flag = 0;
  set @d_ldate = "uf_default_date"();
  set @t_ltime = "now"();
  set @d_completed_date = null;
  set @t_completed_time = null;
  set @c_sman_code = '-';
  --set @c_lr_no = null;
  --  set @c_transport = null;
  --  set @c_driver_name = null;
  --  set @c_driver_phno = null;
  set @c_modiuser = null;
  set @c_computer_name = null;
  set @c_sys_user = null;
  set @c_sys_ip = null;
  set @c_order_id = null;
  set @n_tender = 0;
  set @n_tender_given = 0;
  set @n_tender_rtn = 0;
  set @n_flag = 0;
  set @n_tender_type = 0;
  set @c_crn_no = null;
  set @c_remark = null;
  set @d_reschedule_date = null;
  set @d_reschedule_time = null;
  set @c_reason_code = '-';
  set @n_item_length = 0;
  set @n_item_weight = 0;
  set @n_item_height = 0;
  set @n_item_breadth = 0;
  set @c_dispatch_ref_no = null;
  set @SecurityConfirmation = "isnull"(@SecurityConfirmation,0);
  select "C_MENU_ID" into @days_to_allow_new_deliveryslip from "ST_TRACK_MODULE_MST" where "c_code" = 'M00123';
  if @days_to_allow_new_deliveryslip is null or @days_to_allow_new_deliveryslip = '' then
    set @days_to_allow_new_deliveryslip = 7
  end if;
  set @tmp_date = "uf_default_date"()-cast(@days_to_allow_new_deliveryslip as integer);
  case @cIndex
  when 'get_route' then
    if "len"(@TrayCode_corton) > 6 then
      if "left"(@TrayCode_corton,6) = '000000' then
        set @carton_no = "substring"(@TrayCode_corton,7);
        set @TrayCode = "trim"("left"(@TrayCode_corton,6))
      else
        set @carton_no = 0;
        set @TrayCode = "trim"("left"(@TrayCode_corton,6))
      end if
    else set @TrayCode = "trim"("left"(@TrayCode_corton,6));
      set @carton_no = 0
    end if;
    if @TrayCode <> '000000' then
      select "isnull"("COUNT"(),0) into @li_tray_cnt from "st_tray_mst" where "c_code" = @TrayCode;
      if @li_tray_cnt = 0 then
        select 'Warning! : Tray '+@TrayCode+' is not a Valid Tray !.' as "c_message" for xml raw,elements;
        return
      end if end if;
    --n_in_out_flag = 0 external tray
    --n_in_out_flag = 1 Internal Tray
    --n_in_out_flag = 3 Temp Tray 
    set @li_tray_cnt = 0;
    select "isnull"("COUNT"(),0) into @li_internal_tray_cnt from "st_tray_mst" where "c_code" = @TrayCode and "n_in_out_flag" = 1;
    if @li_internal_tray_cnt > 0 then
      select 'Warning! : Tray '+@TrayCode+' is an Internal Tray code.' as "c_message" for xml raw,elements;
      return
    end if;
    select distinct top 1 "carton_mst"."c_br_code","carton_mst"."c_year","carton_mst"."c_prefix","carton_mst"."n_srno","carton_mst"."d_ldate"
      into @gsBr,@cYear,@cPrefix,@nSrno,@d_dt
      from(select "c_br_code","c_year","c_prefix","n_srno","c_tray_code","n_carton_no","d_ldate" from "carton_mst" where "d_ldate" >= "uf_default_date"()-cast(@days_to_allow_new_deliveryslip as integer)) as "carton_mst"
        left outer join "slip_det"
        on "carton_mst"."c_br_code" = "slip_det"."c_inv_br"
        and "carton_mst"."c_year" = "slip_det"."c_inv_year"
        and "carton_mst"."c_prefix" = "slip_det"."c_inv_prefix"
        and "carton_mst"."n_srno" = "slip_det"."n_inv_no"
      where "isnull"("slip_det"."c_inv_br",0) = if @SecurityConfirmation = 1 then "isnull"("slip_det"."c_inv_br",0) else 0 endif
      and "carton_mst"."c_tray_code" = @TrayCode
      and "carton_mst"."n_carton_no" = @carton_no
      order by "carton_mst"."d_ldate" desc;
    set @doc_no = @gsBr+'/'+@cYear+'/'+@cPrefix+'/'+"string"(@nSrno);
    if @doc_no is null or "trim"(@doc_no) = '' or "trim"(@doc_no) = '///' then
      select 'Warning! : Tray '+@TrayCode_corton+' Have no Document Number !!.' as "c_message" for xml raw,elements;
      return
    end if;
    select "route_mst"."c_code",
      "route_mst"."c_name"
      from(select "inv_mst"."c_cust_code" as "c_cust_code","inv_mst"."n_total" as "n_total" from "inv_mst" where "inv_mst"."c_br_code" = @gsBr and "inv_mst"."c_year" = @cYear and "inv_mst"."c_prefix" = @cPrefix and "inv_mst"."n_srno" = @nSrno and "n_cancel_flag" = 0 and "n_approved" = 1 union
        select "gdn_mst"."c_ref_br_code" as "c_cust_code","gdn_mst"."n_total" as "n_total" from "gdn_mst" where "gdn_mst"."c_br_code" = @gsBr and "gdn_mst"."c_year" = @cYear and "gdn_mst"."c_prefix" = @cPrefix and "gdn_mst"."n_srno" = @nSrno and "n_cancel_flag" = 0 and "n_approved" = 1 union
        select "dc_inv_mst"."c_cust_code" as "c_cust_code","dc_inv_mst"."n_total" as "n_total" from "dc_inv_mst" where "dc_inv_mst"."c_br_code" = @gsBr and "dc_inv_mst"."c_year" = @cYear and "dc_inv_mst"."c_prefix" = @cPrefix and "dc_inv_mst"."n_srno" = @nSrno and "n_cancel_flag" = 0 and "n_approved" = 1) as "Tem"
        join "act_mst" on "Tem"."c_cust_code" = "act_mst"."c_code"
        left outer join "act_route" on "act_mst"."c_code" = "act_route"."c_br_code"
        left outer join "route_mst" on "act_route"."c_route_code" = "route_mst"."c_code" for xml raw,elements
  when 'get_trays_in_route' then
    insert into "temp_carton_mst"
      select "c_br_code","c_year","c_prefix","n_srno","c_tray_code","n_carton_no","max"("c_item_code")
        from "carton_mst" where "d_ldate" >= @tmp_date
        group by "c_br_code","c_year","c_prefix","n_srno","c_tray_code","n_carton_no";
    insert into "doc_tary_list"
      select "c_tray_code"+if "n_carton_no" = 0 then '' else "string"("n_carton_no") endif as "tray_carton_list",
        "inv_mst"."c_cust_code" as "c_cust_code",
        "act_mst_inv"."c_name" as "c_name",
        "carton_mst"."c_br_code"+'/'+"carton_mst"."c_year"+'/'+"carton_mst"."c_prefix"+'/'+"String"("carton_mst"."n_srno") as "c_doc_no",
        "carton_mst"."c_br_code",
        "max"("carton_mst"."c_item_code") as "top_item",
        "act_route"."c_route_seq" as "route_seq"
        from "temp_carton_mst" as "carton_mst"
          left outer join "slip_det" on "carton_mst"."c_br_code" = "slip_det"."c_inv_br"
          and "carton_mst"."c_year" = "slip_det"."c_inv_year"
          and "carton_mst"."c_prefix" = "slip_det"."c_inv_prefix"
          and "carton_mst"."n_srno" = "slip_det"."n_inv_no"
          left outer join "inv_mst" on "carton_mst"."c_br_code" = "inv_mst"."c_br_code"
          and "carton_mst"."c_year" = "inv_mst"."c_year"
          and "carton_mst"."c_prefix" = "inv_mst"."c_prefix"
          and "carton_mst"."n_srno" = "inv_mst"."n_srno"
          left outer join "act_mst" as "act_mst_inv" on "act_mst_inv"."c_code" = "inv_mst"."c_cust_code"
          left outer join "act_route" on "inv_mst"."c_cust_code" = "act_route"."c_br_code"
        where "slip_det"."c_inv_br" is null
        and("act_route"."c_route_code" = @route_code)
        and("inv_mst"."n_cancel_flag" = 0) and "inv_mst"."d_date" >= @tmp_date
        group by "tray_carton_list","c_cust_code","c_name","c_doc_no","carton_mst"."c_br_code","act_route"."c_route_seq" union all
      select "c_tray_code"+if "n_carton_no" = 0 then '' else "string"("n_carton_no") endif as "tray_carton_list",
        "gdn_mst"."c_ref_br_code" as "c_cust_code",
        "act_mst_gdn"."c_name" as "c_name",
        "carton_mst"."c_br_code"+'/'+"carton_mst"."c_year"+'/'+"carton_mst"."c_prefix"+'/'+"String"("carton_mst"."n_srno") as "c_doc_no",
        "carton_mst"."c_br_code",
        "max"("carton_mst"."c_item_code") as "top_item",
        "act_route"."c_route_seq" as "route_seq"
        from "temp_carton_mst" as "carton_mst"
          left outer join "slip_det" on "carton_mst"."c_br_code" = "slip_det"."c_inv_br"
          and "carton_mst"."c_year" = "slip_det"."c_inv_year"
          and "carton_mst"."c_prefix" = "slip_det"."c_inv_prefix"
          and "carton_mst"."n_srno" = "slip_det"."n_inv_no"
          left outer join "gdn_mst" on "carton_mst"."c_br_code" = "gdn_mst"."c_br_code"
          and "carton_mst"."c_year" = "gdn_mst"."c_year"
          and "carton_mst"."c_prefix" = "gdn_mst"."c_prefix"
          and "carton_mst"."n_srno" = "gdn_mst"."n_srno"
          left outer join "act_mst" as "act_mst_gdn" on "act_mst_gdn"."c_code" = "gdn_mst"."c_ref_br_code"
          left outer join "act_route" on "gdn_mst"."c_ref_br_code" = "act_route"."c_br_code"
        where "slip_det"."c_inv_br" is null
        and("act_route"."c_route_code" = @route_code)
        and("gdn_mst"."n_cancel_flag" = 0) and "gdn_mst"."d_date" >= @tmp_date
        group by "tray_carton_list","c_cust_code","c_name","c_doc_no","carton_mst"."c_br_code","act_route"."c_route_seq";
    select "tray_carton_list",
      "c_cust_code",
      "doc_tary_list"."c_name",
      "c_doc_no",
      cast("isnull"("c_route_seq",0) as integer) as "c_route_seq",
      (select "ISNULL"("max"("c_note"),
        (select "ISNULL"("max"("c_note"),'DEFAULT')
          from "win_meet_note"
          where "c_win_name" = 'w_tray_type_mst'
          and "c_note_type" = 'TBCLR'
          and "c_key" = "st_tray_type_mst"."c_code"))
        from "win_meet_note"
        where "c_win_name" = 'w_rack_grp_mst_det'
        and "c_note_type" = 'TBRTYP'
        and "c_key" = "rack_group_mst"."c_code") as "c_color",
      'SH0001' as "c_shelf_code"
      from "doc_tary_list"
        left outer join "item_mst_br_info" on "c_top_item_code" = "item_mst_br_info"."c_code" and "item_mst_br_info"."c_br_code" = "c_brcode"
        left outer join "rack_mst" on "rack_mst"."c_br_code" = "item_mst_br_info"."c_br_code" and "rack_mst"."c_code" = "item_mst_br_info"."c_rack"
        left outer join "rack_group_mst" on "rack_group_mst"."c_code" = "rack_mst"."c_rack_grp_code" and "rack_group_mst"."c_br_code" = "item_mst_br_info"."c_br_code"
        left outer join "st_tray_mst" on "st_tray_mst"."c_code" = "tray_carton_list"
        left outer join "st_tray_type_mst" on "st_tray_mst"."c_tray_type_code" = "st_tray_type_mst"."c_code"
      order by "c_route_seq" desc for xml raw,elements
  when 'check_route_pending_trays' then
    select "cust_code" as "customer_code",
      "act_mst"."c_name" as "customer_name",
      "sum"("pk_pnd_cnt") as "pick_pending_cnt",
      "sum"("pk_progress_cnt") as "pick_progress_cnt",
      "sum"("conv_pnd_cnt") as "conversion_pending_cnt"
      from(select "sm"."c_cust_code" as "cust_code",
          "count"(distinct "sd"."c_stage_code") as "pk_pnd_cnt",
          0 as "pk_progress_cnt",
          0 as "conv_pnd_cnt"
          from "st_track_det" as "sd"
            join "st_track_mst" as "sm"
            on "sm"."c_doc_no" = "sd"."c_doc_no"
            and "sm"."n_inout" = "sd"."n_inout"
            left outer join "act_route" as "ac_rt"
            on "sm"."c_cust_code" = "ac_rt"."c_br_code"
            and "sm"."c_br_code" = "ac_rt"."c_code"
          where "sd"."n_inout" = 0 and("sd"."n_complete" = 0 and "sd"."c_tray_code" is null) and "ac_rt"."c_route_code" = @route_code
          group by "cust_code" union all
        select "sm"."c_cust_code" as "cust_code",
          0 as "pk_pnd_cnt",
          "count"(distinct "sd"."c_stage_code") as "pk_progress_cnt",
          0 as "conv_pnd_cnt"
          from "st_track_det" as "sd"
            join "st_track_mst" as "sm"
            on "sm"."c_doc_no" = "sd"."c_doc_no"
            and "sm"."n_inout" = "sd"."n_inout"
            left outer join "act_route" as "ac_rt"
            on "sm"."c_cust_code" = "ac_rt"."c_br_code"
            and "sm"."c_br_code" = "ac_rt"."c_code"
          where "sd"."n_inout" = 0 and("sd"."n_complete" = 0 and "sd"."c_tray_code" is not null) and "ac_rt"."c_route_code" = @route_code
          group by "cust_code" union all
        select "sm"."c_cust_code" as "cust_code",
          0 as "pk_pnd_cnt",
          0 as "pk_progress_cnt",
          "count"(distinct "sp"."c_tray_code") as "conv_pnd_cnt"
          from "st_track_pick" as "sp"
            join "st_track_mst" as "sm"
            on "sm"."c_doc_no" = "sp"."c_doc_no"
            and "sm"."n_inout" = "sp"."n_inout"
            left outer join "act_route" as "ac_rt"
            on "sm"."c_cust_code" = "ac_rt"."c_br_code"
            and "sm"."c_br_code" = "ac_rt"."c_code"
          where "sp"."n_inout" = 0
          and cast("t_time" as date) >= "uf_default_date"()-cast(@days_to_allow_new_deliveryslip as integer)
          and("n_qty"-("n_confirm_qty"+"n_reject_qty")) > 0
          and "ac_rt"."c_route_code" = @route_code
          group by "cust_code") as "check_pending_cnt"
        join "act_mst" on "act_mst"."c_code" = "customer_code"
      group by "customer_code","customer_name" for xml raw,elements;
    print 'end_time_check_route_pending_trays';
    print "now"()
  when 'branchwise_doc_insert' then
    //http://172.16.18.20:19503/ws_new_delivery_slip?&cIndex=branchwise_doc_insert&regioncode=RT0001&DocList=503/19/N/156320^^503/19/N/156487^^503/19/N/156452^^&RackGrpCode=null&StageCode=null&GodownCode=&gsbr=503&devID=a3dcefdf75bczzaw646d105092019064846055&sKEY=sKey&UserId=myboss
    //http://172.16.18.20:19503/ws_new_delivery_slip?&cIndex=branchwise_doc_insert&regioncode=RT0001&DocList=503/19/N/156408^^503/19/N/156453^^503/19/N/156298^^503/19/N/156085^^503/19/N/156087^^503/19/N/156318^^503/19/N/156465^^503/19/N/156026^^503/19/N/156396^^503/19/N/156209^^&slipSrno=0&GodownCode=-&gsbr=503&devID=a3dcefdf75bc646d105092019064846055&sKEY=sKey&UserId=s kamble
    set @not_in_cnt = 0;
    while @c_doc_list <> '' loop
      select "Locate"(@c_doc_list,@ColSep) into @ColPos;
      set @doc_no = "Trim"("Left"(@c_doc_list,@ColPos-1));
      set @c_doc_list = "SubString"(@c_doc_list,@ColPos+@ColMaxLen);
      select "Locate"(@doc_no,'/') into @ColPos;
      set @gsBr = "Trim"("Left"(@doc_no,@ColPos-1));
      set @doc_no = "SubString"(@doc_no,@ColPos+1);
      select "Locate"(@doc_no,'/') into @ColPos;
      set @cYear = "Trim"("Left"(@doc_no,@ColPos-1));
      set @doc_no = "SubString"(@doc_no,@ColPos+1);
      select "Locate"(@doc_no,'/') into @ColPos;
      set @cPrefix = "Trim"("Left"(@doc_no,@ColPos-1));
      set @cPrefix = "Upper"(@cPrefix);
      set @nSrno = cast("SubString"(@doc_no,@ColPos+1) as numeric(9));
      select "count"("n_srno") as "rt_cnt","n_srno" into @route_cnt,@n_slipSrno from "delivery_slip_mst" where "c_route_code" = @route_code group by "n_srno";
      if @route_cnt is null or @route_cnt = '' then
        set @route_cnt = 0;
        set @n_slipSrno = 0
      end if;
      if @route_cnt = 0 then
        if @n_new_slip_no is null or @n_new_slip_no = '' then
          set @n_new_slip_no = 0
        end if;
        if @n_new_slip_no = 0 then
          select "isnull"("n_sr_number",0)
            into @n_slipSrno from "prefix_srno"
            where "c_trans" = 'DSLIP'
            and "c_year" = @c_slipyear
            and "c_br_code" = @gsBr;
          if @n_slipSrno is null or @n_slipSrno = 0 then
            set @n_slipSrno = 1
          end if;
          select "count"("c_trans")
            into @nPrefixCount
            from "prefix_srno" where "c_trans" = 'DSLIP' and "c_year" = @c_slipyear and "c_br_code" = @gsBr and "c_prefix" = @c_slipPrefix;
          if(@nPrefixCount) <= 0 then
            insert into "prefix_srno"
              select 'DSLIP',
                @gsBr,
                @c_slipyear,
                @c_slipPrefix,
                @n_slipSrno,
                null,
                0
          end if;
          update "prefix_srno" set "n_sr_number" = @n_slipSrno+1
            where "c_trans" = 'DSLIP'
            and "c_year" = @c_slipyear
            and "c_br_code" = @gsBr
            and "c_prefix" = @c_slipPrefix;
          set @n_new_slip_no = @n_slipSrno;
          insert into "delivery_slip_mst"
            ( "c_br_code","c_year","c_prefix","n_srno","d_date",
            "c_dman_code","d_exptd_rtn_date","t_exptd_rtn_time","n_status","n_del_charge",
            "n_del_act","n_tender_amt","n_del_charge_rtn","n_tender_amt_rtn","c_tender_act",
            "c_voucher1","c_voucher2","c_voucher3","c_voucher4","n_shift",
            "n_return_shift","n_cash_session_id","n_return_cash_session_id","n_cancel_flag","c_user",
            "d_ldate","t_ltime","d_completed_date","t_completed_time","c_sman_code",
            "c_lr_no","c_transport","c_driver_name","c_driver_phno","c_modiuser",
            "c_computer_name","c_sys_user","c_sys_ip",
            "c_order_id","c_route_code" ) values
            ( @gsBr,@c_slipyear,@c_slipPrefix,@n_slipSrno,@d_date,
            @c_dman_code,@d_exptd_rtn_date,@t_exptd_rtn_time,@n_status,@n_del_charge,
            @n_del_act,@n_tender_amt,@n_del_charge_rtn,@n_tender_amt_rtn,@c_tender_act,
            @c_voucher1,@c_voucher2,@c_voucher3,@c_voucher4,@n_shift,
            @n_return_shift,@n_cash_session_id,@n_return_cash_session_id,@n_cancel_flag,@c_user,
            @d_ldate,@t_ltime,@d_completed_date,@t_completed_time,@c_sman_code,
            "replace"(@c_lr_no,' ',''),@c_transport,@c_driver_name,@c_driver_phno,@c_modiuser,
            @c_computer_name,@c_sys_user,@c_sys_ip,@c_order_id,@route_code ) 
        else
          set @n_slipSrno = @n_new_slip_no
        end if end if;
      case @cPrefix
      when 'T' then
        select "n_total","c_cust_code" into @inv_tot,@c_cust_code from "inv_mst" where "inv_mst"."c_br_code" = @gsBr and "inv_mst"."c_year" = @cYear and "inv_mst"."c_prefix" = @cPrefix and "inv_mst"."n_srno" = @nSrno
      when 'N' then
        select "n_total","c_ref_br_code" into @inv_tot,@c_cust_code from "gdn_mst" where "gdn_mst"."c_br_code" = @gsBr and "gdn_mst"."c_year" = @cYear and "gdn_mst"."c_prefix" = @cPrefix and "gdn_mst"."n_srno" = @nSrno
      end case;
      select "count"("n_inv_no") into @inv_cnt from "delivery_slip_det" where "c_inv_br" = @gsBr and "c_inv_year" = @cYear and "c_inv_prefix" = @cPrefix and "n_inv_no" = @nSrno;
      if @inv_cnt > 0 then
        set @not_in_cnt = @not_in_cnt+1;
        set @not_in_val = @not_in_val+''+"str"("trim"(@nSrno))
      else
        select "isnull"("max"("n_seq"),0) as "n_slipseq"
          into @n_slipseq from "delivery_slip_det"
          where "c_br_code" = @gsBr
          and "c_year" = @c_slipyear
          and "c_prefix" = @c_slipPrefix
          and "n_srno" = @n_slipSrno;
        set @n_slipseq = @n_slipseq+1;
        //    select st_shelf_det.c_shelf_code into @shelf_code from st_shelf_det
        //    left outer join delivery_slip_det on delivery_slip_det.c_inv_br = st_shelf_det.c_br_code
        //        and delivery_slip_det.c_inv_year = st_shelf_det.c_year
        //        and delivery_slip_det.c_inv_prefix = st_shelf_det.c_prefix
        //        and delivery_slip_det.n_inv_no = st_shelf_det.n_srno
        //        and delivery_slip_det.c_shelf_code = st_shelf_det.c_shelf_code
        //    where st_shelf_det.c_br_code =  @gsBr
        //        and st_shelf_det.c_year = @cYear
        //        and st_shelf_det.c_prefix  = @cPrefix
        //        and st_shelf_det.n_srno = @nSrno;
        insert into "delivery_slip_det"
          ( "c_br_code","c_year","c_prefix","n_srno","n_seq",
          "c_cust_code","c_inv_br","c_inv_year","c_inv_prefix","n_inv_no",
          "n_total","n_tender","n_tender_given","n_tender_rtn","n_status",
          "n_flag","n_tender_type","c_crn_no","c_remark","n_cancel_flag",
          "n_shift","n_return_shift","n_cash_session_id","n_return_cash_session_id","c_user",
          "d_date","d_ldate","t_ltime","d_completed_date","t_completed_time",
          "d_reschedule_date","d_reschedule_time","c_reason_code","n_item_length",
          "n_item_height","n_item_breadth",
          "c_dispatch_ref_no" ) values
          ( @gsBr,@c_slipyear,@c_slipPrefix,@n_slipSrno,@n_slipseq,
          @c_cust_code,@gsBr,@cYear,@cPrefix,@nSrno,
          @inv_tot,@n_tender,@n_tender_given,@n_tender_rtn,@n_status,
          @n_flag,@n_tender_type,@c_crn_no,@c_remark,@n_cancel_flag,
          @n_shift,@n_return_shift,@n_cash_session_id,@n_return_cash_session_id,@c_user,
          @d_date,@d_ldate,@t_ltime,@d_completed_date,@t_completed_time,
          @d_reschedule_date,@d_reschedule_time,@c_reason_code,@n_item_length,
          @n_item_height,@n_item_breadth,@c_dispatch_ref_no ) 
      end if
    end loop;
    if sqlstate = '00000' or sqlstate = '02000' then
      select 1 as "n_status",'Success' as "c_message","str"("trim"(@not_in_cnt))+'- Invoices'+@not_in_val+' already completed in last transaction.' as "c_remarks",
        @gsBr+'/'+@c_slipyear+'/'+@c_slipPrefix+'/'+"string"(@n_slipSrno) as "slip_no" for xml raw,elements;
      commit work
    else
      select 0 as "n_status",'Error On Transaction Save!!' as "c_message" for xml raw,elements;
      rollback work
    end if when 'get_tray_list_for_confirmation' then
    if "left"(@tray_code,6) = '000000' then
      set @carton_code = cast("SubString"(@tray_code,7) as numeric(9));
      set @tray_code = "left"(@tray_code,6)
    else
      set @carton_code = 0;
      set @tray_code = "left"(@tray_code,6)
    end if;
    select top 1
      "c_br_code",
      "c_year",
      "c_prefix",
      "n_srno"
      into @crtn_Br,
      @crtn_cYear,
      @crtn_cPrefix,
      @crtn_nSrno from "carton_mst"
      where "carton_mst"."c_tray_code" = @tray_code and "n_carton_no" = @carton_code
      order by "t_ltime" desc;
    if @crtn_Br is null or @crtn_Br = '' then
      select 'TRAY NOT FOUND' as "c_message" for xml raw,elements;
      return
    end if;
    select top 1
      "c_br_code",
      "c_year",
      "c_prefix",
      "n_srno","c_cust_code"
      into @gsBr,
      @cYear,
      @cPrefix,
      @nSrno,@c_cust_code from "delivery_slip_det" where "c_inv_br" = @crtn_Br
      and "c_inv_year" = @crtn_cYear
      and "c_inv_prefix" = @crtn_cPrefix
      and "n_inv_no" = @crtn_nSrno;
    if @gsBr is null or @gsBr = '' then
      select 'TRAY NOT FOUND IN THIS SLIP' as "c_message" for xml raw,elements;
      return
    end if;
    if(select "count"() from "delivery_slip_det"
        where "c_inv_br" = @crtn_Br and "c_inv_year" = @crtn_cYear and "c_inv_prefix" = @crtn_cPrefix
        and "n_inv_no" = @crtn_nSrno and "n_complete_flag" = 0) > 0 then
      select distinct cast("isnull"("isnull"("act_route_inv"."c_route_seq",
        "act_route_gdn"."c_route_seq"),0) as numeric(4)) as "del_seq",
        ("isnull"("a"."c_code","b"."c_code")) as "c_cust_code",
        ("isnull"("a"."c_name","b"."c_name")) as "c_cust_name",
        "carton_mst"."c_tray_code"+if "carton_mst"."n_carton_no" <> 0 then "string"("carton_mst"."n_carton_no") endif as "c_tray_code",
        ("delivery_slip_det"."c_br_code"+'/'+"delivery_slip_det"."c_year"+'/'+"delivery_slip_det"."c_prefix"+'/'+"string"("delivery_slip_det"."n_srno")) as "slipno",
        ("delivery_slip_det"."c_inv_br"+'/'+"delivery_slip_det"."c_inv_year"+'/'+"delivery_slip_det"."c_inv_prefix"+'/'+"string"("delivery_slip_det"."n_inv_no")) as "c_doc_no",
        ("isnull"("route_mst_inv"."c_code","route_mst_gdn"."c_code")) as "c_route_code",
        ("isnull"("route_mst_inv"."c_name","route_mst_gdn"."c_name")) as "c_route_name"
        from "delivery_slip_mst" join "delivery_slip_det"
          on "delivery_slip_mst"."c_br_code" = "delivery_slip_det"."c_br_code"
          and "delivery_slip_mst"."c_year" = "delivery_slip_det"."c_year"
          and "delivery_slip_mst"."c_prefix" = "delivery_slip_det"."c_prefix"
          and "delivery_slip_mst"."n_srno" = "delivery_slip_det"."n_srno"
          left outer join "inv_mst" on "delivery_slip_det"."c_inv_br" = "inv_mst"."c_br_code"
          and "delivery_slip_det"."c_inv_year" = "inv_mst"."c_year"
          and "delivery_slip_det"."c_inv_prefix" = "inv_mst"."c_prefix"
          and "delivery_slip_det"."n_inv_no" = "inv_mst"."n_srno"
          left outer join "gdn_mst" on "delivery_slip_det"."c_inv_br" = "gdn_mst"."c_br_code"
          and "delivery_slip_det"."c_inv_year" = "gdn_mst"."c_year"
          and "delivery_slip_det"."c_inv_prefix" = "gdn_mst"."c_prefix"
          and "delivery_slip_det"."n_inv_no" = "gdn_mst"."n_srno"
          left outer join "act_route" as "act_route_inv"
          on "act_route_inv"."c_br_code" = "trim"("inv_mst"."c_cust_code")
          left outer join "act_route" as "act_route_gdn"
          on "act_route_gdn"."c_br_code" = "trim"("gdn_mst"."c_ref_br_code")
          left outer join "route_mst" as "route_mst_inv"
          on "act_route_inv"."c_route_code" = "route_mst_inv"."c_code"
          left outer join "route_mst" as "route_mst_gdn"
          on "act_route_gdn"."c_route_code" = "route_mst_gdn"."c_code"
          join "carton_mst" on "delivery_slip_det"."c_inv_br" = "carton_mst"."c_br_code"
          and "delivery_slip_det"."c_inv_year" = "carton_mst"."c_year"
          and "delivery_slip_det"."c_inv_prefix" = "carton_mst"."c_prefix"
          and "delivery_slip_det"."n_inv_no" = "carton_mst"."n_srno"
          left outer join "act_mst" as "a" on "a"."c_code" = "inv_mst"."c_cust_code"
          left outer join "act_mst" as "b" on "b"."c_code" = "gdn_mst"."c_ref_br_code"
        where "delivery_slip_mst"."c_route_code" = ("isnull"("route_mst_inv"."c_code","route_mst_gdn"."c_code"))
        and "delivery_slip_det"."n_complete_flag" = 0 and "delivery_slip_det"."c_cust_code" = @c_cust_code
        order by "del_seq" desc for xml raw,elements
    else
      select 0 as "n_status",
        'Security Confirmation is done for the tray(s).' as "c_message" for xml raw,elements
    end if when 'branchwise_security_confirmation' then
    while @c_doc_list <> '' loop
      select "Locate"(@c_doc_list,@ColSep) into @ColPos;
      set @doc_no = "Trim"("Left"(@c_doc_list,@ColPos-1));
      set @c_doc_list = "SubString"(@c_doc_list,@ColPos+@ColMaxLen);
      select "Locate"(@doc_no,'/') into @ColPos;
      set @gsBr = "Trim"("Left"(@doc_no,@ColPos-1));
      set @doc_no = "SubString"(@doc_no,@ColPos+1);
      select "Locate"(@doc_no,'/') into @ColPos;
      set @cYear = "Trim"("Left"(@doc_no,@ColPos-1));
      set @doc_no = "SubString"(@doc_no,@ColPos+1);
      select "Locate"(@doc_no,'/') into @ColPos;
      set @cPrefix = "Trim"("Left"(@doc_no,@ColPos-1));
      set @cPrefix = "Upper"(@cPrefix);
      set @nSrno = cast("SubString"(@doc_no,@ColPos+1) as numeric(9));
      -- to release the shelf_location after confirmation from delivery slip confirmation
      delete from "st_shelf_det" from "st_shelf_det"
        join "delivery_slip_det" on "delivery_slip_det"."c_inv_br" = "st_shelf_det"."c_br_code"
        and "delivery_slip_det"."c_inv_year" = "st_shelf_det"."c_year"
        and "delivery_slip_det"."c_inv_prefix" = "st_shelf_det"."c_prefix"
        and "delivery_slip_det"."n_inv_no" = "st_shelf_det"."n_srno"
        where "st_shelf_det"."c_br_code" = @gsBr
        and "st_shelf_det"."c_year" = @cYear
        and "st_shelf_det"."c_prefix" = @cPrefix
        and "st_shelf_det"."n_srno" = @nSrno;
      update "delivery_slip_det" set "delivery_slip_det"."n_complete_flag" = 1
        where "c_inv_br" = @gsBr
        and "c_inv_year" = @cYear
        and "c_inv_prefix" = @cPrefix
        and "n_inv_no" = @nSrno
    end loop;
    if sqlstate = '00000' or sqlstate = '02000' then
      select 1 as "n_status",'Success' as "c_message" for xml raw,elements;
      commit work
    else
      select 0 as "n_status",'Failure: Error on Updation!!' as "c_message" for xml raw,elements;
      rollback work
    end if when 'register_device' then
    update "st_device_mst" set "n_cancel_flag" = 0 where "n_cancel_flag" <> 0;
    select 1 as "n_status",'Success' as "c_message" for xml raw,elements
  when 'document_post' then
    while @c_doc_list <> '' loop
      select "Locate"(@c_doc_list,@ColSep) into @ColPos;
      set @doc_no = "Trim"("Left"(@c_doc_list,@ColPos-1));
      set @c_doc_list = "SubString"(@c_doc_list,@ColPos+@ColMaxLen);
      select "Locate"(@doc_no,'/') into @ColPos;
      set @gsBr = "Trim"("Left"(@doc_no,@ColPos-1));
      set @doc_no = "SubString"(@doc_no,@ColPos+1);
      select "Locate"(@doc_no,'/') into @ColPos;
      set @cYear = "Trim"("Left"(@doc_no,@ColPos-1));
      set @doc_no = "SubString"(@doc_no,@ColPos+1);
      select "Locate"(@doc_no,'/') into @ColPos;
      set @cPrefix = "Trim"("Left"(@doc_no,@ColPos-1));
      set @nSrno = cast("SubString"(@doc_no,@ColPos+1) as numeric(9));
      select top 1 "c_prefix","n_srno"
        into @c_slipPrefix,@n_slipSrno
        from "slip_det"
        where "slip_det"."c_inv_br" = @gsBr
        and "slip_det"."c_inv_year" = @cYear
        and "slip_det"."c_inv_prefix" = @cPrefix
        and "slip_det"."n_inv_no" = @nSrno order by "t_ltime" desc;
      update "slip_mst"
        set "c_transport" = @c_transport,
        "c_driver_name" = @c_driver_name,
        "c_driver_phno" = @c_driver_phno,
        "c_lr_no" = "replace"(@c_lr_no,' ',''),
        "c_dman_code" = @c_dman_code,
        "d_ldate" = @d_ldate,
        "t_ltime" = @t_ltime,
        "n_status" = 0
        where "slip_mst"."c_br_code" = @gsBr
        and "slip_mst"."c_year" = @cYear
        and "slip_mst"."c_prefix" = @c_slipPrefix
        and "slip_mst"."n_srno" = @n_slipSrno;
      update "slip_det"
        set "d_ldate" = @d_ldate,
        "t_ltime" = @t_ltime,
        "slip_det"."n_status" = 0
        where "slip_det"."c_br_code" = @gsBr
        and "slip_det"."c_year" = @cYear
        and "slip_det"."c_prefix" = @c_slipPrefix
        and "slip_det"."n_srno" = @n_slipSrno;
      commit work;
      update "carton_mst" set "carton_mst"."c_dispatch_ref_no" = @c_user from
        "slip_mst" join "slip_det" on "slip_mst"."c_br_code" = "slip_det"."c_br_code"
        and "slip_mst"."c_year" = "slip_det"."c_year"
        and "slip_mst"."c_prefix" = "slip_det"."c_prefix"
        and "slip_mst"."n_srno" = "slip_det"."n_srno"
        join "carton_mst" on "slip_det"."c_inv_br" = "carton_mst"."c_br_code"
        and "slip_det"."c_inv_year" = "carton_mst"."c_year"
        and "slip_det"."c_inv_prefix" = "carton_mst"."c_prefix"
        and "slip_det"."n_inv_no" = "carton_mst"."n_srno"
        where "slip_mst"."c_br_code" = @gsBr
        and "slip_mst"."c_year" = @cYear
        and "slip_mst"."c_prefix" = @c_slipPrefix
        and "slip_mst"."n_srno" = @n_slipSrno;
      commit work;
      set @slip_doc_2 = @gsBr+'/'+@cYear+'/'+@c_slipPrefix+'/'+"string"(@n_slipSrno);
      if @slip_doc_2 <> @slip_doc_1 then
        insert into "Slip_doc_list"
          ( "c_slip_br_code","c_slip_year","c_slip_prefix",
          "n_slip_srno" ) on existing skip values
          ( @gsBr,@cYear,@c_slipPrefix,@n_slipSrno ) 
      end if;
      set @slip_doc_1 = @slip_doc_2
    end loop;
    select "n_active" into @PRINT_DELIVERY_SLIP_FROM_TAB from "st_track_module_mst" where "c_code" = 'M00031';
    if @PRINT_DELIVERY_SLIP_FROM_TAB = 1 then
      --          for "c_code" as "Slip_print" dynamic scroll cursor for
      --            select "c_slip_br_code","c_slip_year","c_slip_prefix","n_slip_srno" from "Slip_doc_list"
      --          do
      --            call "DBA"."usp_slip_print_from_sp"("c_slip_br_code","c_slip_year","c_slip_prefix","n_slip_srno")
      --          end for 
      select "max"("id_temp") into @max from "Slip_doc_list";
      while @min <= @max loop
        select "c_slip_br_code","c_slip_year","c_slip_prefix","n_slip_srno" into @c_slip_br_code,@c_slip_year,@c_slip_prefix,@n_slip_srno from "Slip_doc_list" where "id_temp" = @min;
        call "DBA"."usp_slip_print_from_sp"(@c_slip_br_code,@c_slip_year,@c_slip_prefix,@n_slip_srno);
        set @min = @min+1
      end loop
    end if;
    select '' as "c_message" for xml raw,elements
  when 'document_insert' then
    //http://172.16.18.20:19503/ws_new_delivery_slip?&cIndex=document_insert&regioncode=RT0008&slipSrno=0&GodownCode=-&gsbr=503&devID=a3dcefdf75bc646d105092019064846055&sKEY=sKey&UserId=s%20kamble
    --    select "replace"("list"("delivery_slip_det"."c_inv_br"+'/'+"delivery_slip_det"."c_inv_year"+'/'+"delivery_slip_det"."c_inv_prefix"+'/'+"trim"("str"("delivery_slip_det"."n_inv_no")))+',',',','^^')
    --      into @c_doc_list from "delivery_slip_det"
    --        join "delivery_slip_mst" on "delivery_slip_mst"."c_br_code" = "delivery_slip_det"."c_br_code"
    --        and "delivery_slip_mst"."c_year" = "delivery_slip_det"."c_year"
    --        and "delivery_slip_mst"."c_prefix" = "delivery_slip_det"."c_prefix"
    --        and "delivery_slip_mst"."n_srno" = "delivery_slip_det"."n_srno"
    --        and "delivery_slip_mst"."c_route_code" = @route_code;
    //print @c_doc_list;
    while @c_doc_list <> '' loop
      select "Locate"(@c_doc_list,@ColSep) into @ColPos;
      set @doc_no = "Trim"("Left"(@c_doc_list,@ColPos-1));
      set @c_doc_list = "SubString"(@c_doc_list,@ColPos+@ColMaxLen);
      //      print @doc_no;
      select "Locate"(@doc_no,'/') into @ColPos;
      set @gsBr = "Trim"("Left"(@doc_no,@ColPos-1));
      set @doc_no = "SubString"(@doc_no,@ColPos+1);
      select "Locate"(@doc_no,'/') into @ColPos;
      set @cYear = "Trim"("Left"(@doc_no,@ColPos-1));
      set @doc_no = "SubString"(@doc_no,@ColPos+1);
      select "Locate"(@doc_no,'/') into @ColPos;
      set @cPrefix = "Trim"("Left"(@doc_no,@ColPos-1));
      set @cPrefix = "Upper"(@cPrefix);
      set @nSrno = cast("SubString"(@doc_no,@ColPos+1) as numeric(9));
      if @n_new_slip_no = 0 then
        select "isnull"("n_sr_number",0)
          into @n_slipSrno from "prefix_srno"
          where "c_trans" = 'SLIP'
          and "c_year" = @c_slipyear
          and "c_br_code" = @gsBr;
        if @n_slipSrno is null or @n_slipSrno = 0 then
          set @n_slipSrno = 1
        end if;
        select "count"("c_trans")
          into @nPrefixCount from "prefix_srno" where "c_trans" = 'SLIP' and "c_year" = @c_slipyear and "c_br_code" = @gsBr and "c_prefix" = @c_slipPrefix;
        if(@nPrefixCount) <= 0 then
          insert into "prefix_srno"
            select 'SLIP',
              @gsBr,
              @c_slipyear,
              @c_slipPrefix,
              @n_slipSrno,
              null,
              0
        end if;
        update "prefix_srno" set "n_sr_number" = @n_slipSrno+1
          where "c_trans" = 'SLIP'
          and "c_year" = @c_slipyear
          and "c_br_code" = @gsBr
          and "c_prefix" = @c_slipPrefix;
        set @n_new_slip_no = @n_slipSrno;
        insert into "slip_mst"
          ( "c_br_code","c_year","c_prefix","n_srno","d_date",
          "c_dman_code","d_exptd_rtn_date","t_exptd_rtn_time","n_status","n_del_charge",
          "n_del_act","n_tender_amt","n_del_charge_rtn","n_tender_amt_rtn","c_tender_act",
          "c_voucher1","c_voucher2","c_voucher3","c_voucher4","n_shift",
          "n_return_shift","n_cash_session_id","n_return_cash_session_id","n_cancel_flag","c_user",
          "d_ldate","t_ltime","d_completed_date","t_completed_time","c_sman_code",
          "c_lr_no","c_transport","c_driver_name","c_driver_phno","c_modiuser",
          "c_computer_name","c_sys_user","c_sys_ip",
          "c_order_id" ) values
          ( @gsBr,@c_slipyear,@c_slipPrefix,@n_slipSrno,@d_date,
          @c_dman_code,@d_exptd_rtn_date,@t_exptd_rtn_time,@n_status,@n_del_charge,
          @n_del_act,@n_tender_amt,@n_del_charge_rtn,@n_tender_amt_rtn,@c_tender_act,
          @c_voucher1,@c_voucher2,@c_voucher3,@c_voucher4,@n_shift,
          @n_return_shift,@n_cash_session_id,@n_return_cash_session_id,@n_cancel_flag,@c_user,
          @d_ldate,@t_ltime,@d_completed_date,@t_completed_time,@c_sman_code,
          "replace"(@c_lr_no,' ',''),@c_transport,@c_driver_name,@c_driver_phno,@c_modiuser,
          @c_computer_name,@c_sys_user,@c_sys_ip,@c_order_id ) 
      else
        ---print('sani');
        set @n_slipSrno = @n_new_slip_no
      end if;
      case @cPrefix
      when 'T' then
        select "n_total","c_cust_code" into @inv_tot,@c_cust_code from "inv_mst" where "inv_mst"."c_br_code" = @gsBr and "inv_mst"."c_year" = @cYear and "inv_mst"."c_prefix" = @cPrefix and "inv_mst"."n_srno" = @nSrno
      when 'N' then
        select "n_total","c_ref_br_code" into @inv_tot,@c_cust_code from "gdn_mst" where "gdn_mst"."c_br_code" = @gsBr and "gdn_mst"."c_year" = @cYear and "gdn_mst"."c_prefix" = @cPrefix and "gdn_mst"."n_srno" = @nSrno
      end case;
      select "isnull"("max"("n_seq"),0) as "n_slipseq"
        into @n_slipseq from "slip_det"
        where "c_br_code" = @gsBr
        and "c_year" = @c_slipyear
        and "c_prefix" = @c_slipPrefix
        and "n_srno" = @n_slipSrno;
      set @n_slipseq = @n_slipseq+1;
      insert into "slip_det"
        ( "c_br_code","c_year","c_prefix","n_srno","n_seq",
        "c_cust_code","c_inv_br","c_inv_year","c_inv_prefix","n_inv_no",
        "n_total","n_tender","n_tender_given","n_tender_rtn","n_status",
        "n_flag","n_tender_type","c_crn_no","c_remark","n_cancel_flag",
        "n_shift","n_return_shift","n_cash_session_id","n_return_cash_session_id","c_user",
        "d_date","d_ldate","t_ltime","d_completed_date","t_completed_time",
        "d_reschedule_date","d_reschedule_time","c_reason_code","n_item_length",
        "n_item_height","n_item_breadth",
        "c_dispatch_ref_no" ) values
        ( @gsBr,@c_slipyear,@c_slipPrefix,@n_slipSrno,@n_slipseq,
        @c_cust_code,@gsBr,@cYear,@cPrefix,@nSrno,
        @inv_tot,@n_tender,@n_tender_given,@n_tender_rtn,@n_status,
        @n_flag,@n_tender_type,@c_crn_no,@c_remark,@n_cancel_flag,
        @n_shift,@n_return_shift,@n_cash_session_id,@n_return_cash_session_id,@c_user,
        @d_date,@d_ldate,@t_ltime,@d_completed_date,@t_completed_time,
        @d_reschedule_date,@d_reschedule_time,@c_reason_code,@n_item_length,
        @n_item_height,@n_item_breadth,@c_dispatch_ref_no ) ;
      -- delete from delivery_slip_mst
      commit work;
      select "list"(distinct "c_cust_code")
        into @ls_array_list from "slip_det"
        where "slip_det"."c_br_code" = @gsBr
        and "slip_det"."c_year" = @c_slipyear
        and "slip_det"."c_prefix" = @c_slipPrefix
        and "slip_det"."n_srno" = @n_slipSrno;
      while @ls_array_list <> '' loop
        set @Pos = "Locate"(@ls_array_list,',');
        if @pos > 0 then
          set @ls_array = "left"(@ls_array_list,@pos-1);
          set @ls_array_list = "SubString"(@ls_array_list,@pos+1)
        else
          set @ls_array = @ls_array_list;
          set @ls_array_list = ''
        end if;
        insert into "br_pend_gdn_info"( "c_br_code","c_year","c_prefix","n_srno","n_no_of_items","d_plan_date","c_del_slipno","d_ldate","c_createuser","t_ltime" ) 
          select "br_pend_gdn_info"."c_br_code",
            "br_pend_gdn_info"."c_year",
            "br_pend_gdn_info"."c_prefix",
            "br_pend_gdn_info"."n_srno",
            "br_pend_gdn_info"."n_no_of_items",
            "br_pend_gdn_info"."d_plan_date",
            @gsBr+@c_slipyear+@c_slipPrefix+"string"(@n_slipSrno),
            @d_ldate,
            @c_user,
            @t_ltime
            from "br_pend_gdn_info"
            where("br_pend_gdn_info"."c_del_slipno" is null or "br_pend_gdn_info"."c_del_slipno" = @gsBr+@c_slipyear+@c_slipPrefix+"string"(@n_slipSrno))
            and "isnull"("br_pend_gdn_info"."d_plan_date","uf_default_date"()) <= @d_ldate
            and "br_pend_gdn_info"."c_br_code" = @ls_array
      end loop
    end loop;
    if sqlstate = '00000' or sqlstate = '02000' then
      select @gsBr+'/'+@c_slipyear+'/'+@c_slipPrefix+'/'+"string"(@n_slipSrno) as "slip_no" for xml raw,elements;
      commit work
    else -- 
      select 'Error On Transaction Save!!' as "c_message" for xml raw,elements;
      rollback work
    end if when 'check_pending_branches' then
    insert into "doc_tary_list"
      select distinct
        "c_tray_code"+if "n_carton_no" = 0 then '' else "string"("n_carton_no") endif as "tray_carton_list",
        "isnull"("inv_mst"."c_cust_code","gdn_mst"."c_ref_br_code") as "c_cust_code",
        "isnull"("act_mst_inv"."c_name","act_mst_gdn"."c_name") as "c_name",
        "carton_mst"."c_br_code"+'/'+"carton_mst"."c_year"+'/'+"carton_mst"."c_prefix"+'/'+"String"("carton_mst"."n_srno") as "c_doc_no",
        "carton_mst"."c_br_code",
        "max"("carton_mst"."c_item_code") as "top_item",
        "isnull"("act_route_gdn"."c_route_seq","act_route"."c_route_seq") as "route_seq"
        from "carton_mst"
          left outer join "slip_det" on "carton_mst"."c_br_code" = "slip_det"."c_inv_br"
          and "carton_mst"."c_year" = "slip_det"."c_inv_year"
          and "carton_mst"."c_prefix" = "slip_det"."c_inv_prefix"
          and "carton_mst"."n_srno" = "slip_det"."n_inv_no"
          left outer join "inv_mst" on "carton_mst"."c_br_code" = "inv_mst"."c_br_code"
          and "carton_mst"."c_year" = "inv_mst"."c_year"
          and "carton_mst"."c_prefix" = "inv_mst"."c_prefix"
          and "carton_mst"."n_srno" = "inv_mst"."n_srno"
          left outer join "act_mst" as "act_mst_inv" on "act_mst_inv"."c_code" = "inv_mst"."c_cust_code"
          left outer join "act_route" on "inv_mst"."c_cust_code" = "act_route"."c_br_code"
          left outer join "gdn_mst" on "carton_mst"."c_br_code" = "gdn_mst"."c_br_code"
          and "carton_mst"."c_year" = "gdn_mst"."c_year"
          and "carton_mst"."c_prefix" = "gdn_mst"."c_prefix"
          and "carton_mst"."n_srno" = "gdn_mst"."n_srno"
          left outer join "delivery_slip_det" on "carton_mst"."c_br_code" = "delivery_slip_det"."c_inv_br"
          and "carton_mst"."c_year" = "delivery_slip_det"."c_inv_year"
          and "carton_mst"."c_prefix" = "delivery_slip_det"."c_inv_prefix"
          and "carton_mst"."n_srno" = "delivery_slip_det"."n_inv_no"
          left outer join "act_mst" as "act_mst_gdn" on "act_mst_gdn"."c_code" = "gdn_mst"."c_ref_br_code"
          left outer join "act_route" as "act_route_gdn" on "gdn_mst"."c_ref_br_code" = "act_route_gdn"."c_br_code"
        where "slip_det"."c_inv_br" is null
        and(("act_route"."c_route_code" = @route_code) or("act_route_gdn"."c_route_code" = @route_code))
        and(("gdn_mst"."n_cancel_flag" = 0) or("inv_mst"."n_cancel_flag" = 0))
        group by "tray_carton_list","c_cust_code","c_name","c_doc_no","carton_mst"."c_br_code","act_route_gdn"."c_route_seq","act_route"."c_route_seq";
    select "count"(distinct "doc_tary_list"."c_cust_code") as "n_total_branches",
      "count"(distinct "delivery_slip_det"."c_cust_code") as "n_total_confirmation_completed"
      from "doc_tary_list"
        left outer join "delivery_slip_det"
        on "delivery_slip_det"."c_inv_br"+'/'+"delivery_slip_det"."c_inv_year"+'/'+"delivery_slip_det"."c_inv_prefix"+'/'+"trim"("str"("delivery_slip_det"."n_inv_no")) = "doc_tary_list"."c_doc_no"
        and "doc_tary_list"."c_cust_code" = "delivery_slip_det"."c_cust_code" for xml raw,elements
  when 'deli_slip_details' then
    select distinct "slip_det"."c_br_code"+'/'+"slip_det"."c_year"+'/'+"slip_det"."c_prefix"+'/'+"string"("slip_det"."n_srno") as "c_delivery_slip_no",
      "slip_det"."c_inv_br"+'/'+"slip_det"."c_inv_year"+'/'+"slip_det"."c_inv_prefix"+'/'+"string"("slip_det"."n_inv_no") as "c_inv_gdn_no",
      "cm"."c_tray_code"
      from(select "carton_mst"."c_br_code","carton_mst"."c_year","carton_mst"."c_prefix","carton_mst"."n_srno",
          "c_tray_code"+if "n_carton_no" = 0 then '' else "string"("n_carton_no") endif as "c_tray_code"
          from "carton_mst"
            join "slip_det" on "slip_det"."c_inv_br" = "carton_mst"."c_br_code" and "slip_det"."c_inv_year" = "carton_mst"."c_year"
            and "slip_det"."c_inv_prefix" = "carton_mst"."c_prefix" and "slip_det"."n_inv_no" = "carton_mst"."n_srno"
          where convert(date,"slip_det"."t_ltime") >= "dateadd"("dd",-14,"today"()) and "slip_det"."t_ltime" <= "now"()
          group by "carton_mst"."c_br_code","carton_mst"."c_year","carton_mst"."c_prefix","carton_mst"."n_srno","c_tray_code") as "cm"
        join "slip_det" on "slip_det"."c_inv_br" = "cm"."c_br_code" and "slip_det"."c_inv_year" = "cm"."c_year"
        and "slip_det"."c_inv_prefix" = "cm"."c_prefix" and "slip_det"."n_inv_no" = "cm"."n_srno"
        join "delivery_slip_det" on "slip_det"."c_inv_br" = "delivery_slip_det"."c_inv_br" and "slip_det"."c_inv_year" = "delivery_slip_det"."c_inv_year"
        and "slip_det"."c_inv_prefix" = "delivery_slip_det"."c_inv_prefix" and "slip_det"."n_inv_no" = "delivery_slip_det"."n_inv_no"
      where "delivery_slip_det"."n_complete_flag" = 0 for xml raw,elements
  end case
end;