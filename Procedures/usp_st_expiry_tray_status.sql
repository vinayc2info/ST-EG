CREATE PROCEDURE "DBA"."usp_st_expiry_tray_status"( 
  in @devID char(200),
  in @cIndex char(30),
  in @gsBr char(6),
  in @GodownCode char(6),
  in @tray_code char(20) ) 
result( "is_xml_string" xml ) 
begin
  --common >>
  declare @BrCode char(6);
  declare @ColSep char(6);
  declare @RowSep char(6);
  declare @Pos integer;
  declare @ColPos integer;
  declare @RowPos integer;
  declare @ColMaxLen numeric(4);
  declare @RowMaxLen numeric(4);
  if @devID = '' or @devID is null then
    set @gsBr = "http_variable"('gsBr'); --1
    set @devID = "http_variable"('devID'); --2
    set @cIndex = "http_variable"('cIndex'); --3
    set @GodownCode = "http_variable"('GodownCode'); --4
    set @tray_code = "http_variable"('tray') --5
  end if;
  select "c_delim" into @ColSep from "ps_tab_delimiter" where "n_seq" = 0;
  select "c_delim" into @RowSep from "ps_tab_delimiter" where "n_seq" = 1;
  set @ColMaxLen = "Length"(@ColSep);
  set @RowMaxLen = "Length"(@RowSep);
  case @cIndex
  when 'get_tray_list' then
    select 'Inward' as "stage",
      "stin"."c_doc_no" as "c_doc_no",
      "count"("stin"."c_item_code") as "count",
      0 as "bounce",
      "sum"(if "stin"."n_complete" = 9 then 1 else 0 endif) as "completed",
      "sum"(if "stin"."n_complete" = 0 then 1 else 0 endif) as "inprocess",
      "isnull"("stin"."c_tray_code",'') as "c_tray_code",
      "isnull"("stin"."c_user",'') as "c_user",
      if "stin"."c_godown_code" = '-' then
        (select "c_rack" from "item_mst_br_info" where "item_mst_br_info"."c_br_code" = "left"("stin"."c_doc_no",3)
          and "item_mst_br_info"."c_code" = "stin"."c_item_code" and "item_mst_br_info"."c_br_code" = @gsBr)
      else
        (select "c_rack" from "item_mst_br_info_godown" where "item_mst_br_info_godown"."c_br_code" = "left"("stin"."c_doc_no",3)
          and "item_mst_br_info_godown"."c_code" = "stin"."c_item_code"
          and "item_mst_br_info_godown"."c_godown_code" = "stin"."c_godown_code"
          and "item_mst_br_info_godown"."c_br_code" = @gsBr)
      endif as "c_rk_code",
      (select "c_rack_grp_code" from "rack_mst" where "rack_mst"."c_code" = "c_rk_code"
        and "rack_mst"."c_br_code" = "left"("stin"."c_doc_no",3)
        and "rack_mst"."c_br_code" = @gsBr) as "Rack_grp",
      "left"("stin"."t_time",19) as "t_time",
      "isnull"("g"."c_ref_br_code","isnull"("p"."c_supp_code","isnull"("c"."c_cust_code",if "godown_tran_mst"."c_prefix" = '160' then 'Godown Transfer' else '' endif))) as "c_cust_code",
      "isnull"("a"."c_name",'Godown Transfer') as "c_name"
      from "st_track_in" as "stin"
        left outer join "grn_mst" as "g" --"g"."c_br_code"+'/'+"g"."c_year"+'/'+"g"."c_prefix"+'/'+"string"("g"."n_srno") = "stin"."c_doc_no"
        on "g"."c_br_code" = "left"(("stin"."c_doc_no"),"charindex"('/',("stin"."c_doc_no"))-1)
        and "g"."c_year" = "left"("substring"("left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))),"charindex"('/',"left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))),"charindex"('/',"left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))))+1))-1)
        and "g"."c_prefix" = "left"("substr"("substring"("left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))),"charindex"('/',"left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))),"charindex"('/',"left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))))+1))+1),"charindex"('/',"substr"("substring"("left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))),"charindex"('/',"left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))),"charindex"('/',"left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))))+1))+1))-1)
        and "g"."n_srno" = "reverse"("left"("reverse"("stin"."c_doc_no"),"charindex"('/',("reverse"("stin"."c_doc_no")))-1))
        left outer join "pur_mst" as "p" --"p"."c_br_code"+'/'+"p"."c_year"+'/'+"p"."c_prefix"+'/'+"string"("p"."n_srno") = "stin"."c_doc_no" 
        on "p"."c_br_code" = "left"(("stin"."c_doc_no"),"charindex"('/',("stin"."c_doc_no"))-1)
        and "p"."c_year" = "left"("substring"("left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))),"charindex"('/',"left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))),"charindex"('/',"left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))))+1))-1)
        and "p"."c_prefix" = "left"("substr"("substring"("left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))),"charindex"('/',"left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))),"charindex"('/',"left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))))+1))+1),"charindex"('/',"substr"("substring"("left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))),"charindex"('/',"left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))),"charindex"('/',"left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))))+1))+1))-1)
        and "p"."n_srno" = "reverse"("left"("reverse"("stin"."c_doc_no"),"charindex"('/',("reverse"("stin"."c_doc_no")))-1))
        and "p"."n_post" = 1
        left outer join "crnt_mst" as "c" --"c"."c_br_code"+'/'+"c"."c_year"+'/'+"c"."c_prefix"+'/'+"string"("c"."n_srno") = "stin"."c_doc_no"
        on "c"."c_br_code" = "left"(("stin"."c_doc_no"),"charindex"('/',("stin"."c_doc_no"))-1)
        and "c"."c_year" = "left"("substring"("left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))),"charindex"('/',"left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))),"charindex"('/',"left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))))+1))-1)
        and "c"."c_prefix" = "left"("substr"("substring"("left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))),"charindex"('/',"left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))),"charindex"('/',"left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))))+1))+1),"charindex"('/',"substr"("substring"("left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))),"charindex"('/',"left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))),"charindex"('/',"left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))))+1))+1))-1)
        and "c"."n_srno" = "reverse"("left"("reverse"("stin"."c_doc_no"),"charindex"('/',("reverse"("stin"."c_doc_no")))-1))
        -- left outer join dbnt_mst as d on d.c_br_code+'/'+d.c_year+'/'+d.c_prefix+'/'+string(d.n_srno) = stin.c_doc_no and d.n_approved = 1
        left outer join "godown_tran_mst" --"godown_tran_mst"."c_br_code"+'/'+"godown_tran_mst"."c_year"+'/'+"godown_tran_mst"."c_prefix"+'/'+"string"("godown_tran_mst"."n_srno") = "stin"."c_doc_no" ,
        on "godown_tran_mst"."c_br_code" = "left"(("stin"."c_doc_no"),"charindex"('/',("stin"."c_doc_no"))-1)
        and "godown_tran_mst"."c_year" = "left"("substring"("left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))),"charindex"('/',"left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))),"charindex"('/',"left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))))+1))-1)
        and "godown_tran_mst"."c_prefix" = "left"("substr"("substring"("left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))),"charindex"('/',"left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))),"charindex"('/',"left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))))+1))+1),"charindex"('/',"substr"("substring"("left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))),"charindex"('/',"left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))),"charindex"('/',"left"("stin"."c_doc_no",("length"("stin"."c_doc_no")-("charindex"('/',"reverse"("stin"."c_doc_no"))-1))))+1))+1))-1)
        and "godown_tran_mst"."n_srno" = "reverse"("left"("reverse"("stin"."c_doc_no"),"charindex"('/',("reverse"("stin"."c_doc_no")))-1))
        and "godown_tran_mst"."n_approved" = 1
        left outer join "act_mst" as "a" on "a"."c_code" = "c_cust_code"
      where "stin"."c_godown_code" = @GodownCode
      and "stin"."n_complete" <> 9 and "stin"."c_tray_code" is not null
      --and  stin.c_doc_no='503/16/G/16610'
      group by "c_doc_no","c_tray_code","stin"."c_user","stin"."t_time","Rack_grp","c_rk_code","stin"."c_godown_code","c_cust_code","c_name" union
    select 'Expiry Storein' as "Stage",
      "left"("st"."c_stin_ref_no","length"("st"."c_stin_ref_no")-"charindex"('/',"reverse"("st"."c_stin_ref_no"))) as "c_doc_no",
      "count"("st"."c_item_code") as "count",
      "sum"(if "st"."n_complete" = 2 then 1 else 0 endif) as "bounce",
      "sum"(if "st"."n_complete" = 8 then 1 else 0 endif) as "completed",
      "sum"(if "st"."n_complete" = 0 then 1 else 0 endif) as "inprocess",
      "isnull"("st"."c_tray_code",'') as "c_tray_code",
      "isnull"("st"."c_user",'') as "c_user",
      "st"."c_rack" as "c_rk_code",
      "st"."c_rack_grp_code" as "Rack_grp",
      "left"("now"(),19) as "t_time",
      "isnull"("g"."c_ref_br_code","isnull"("p"."c_supp_code","isnull"("c"."c_cust_code",if "godown_tran_mst"."c_prefix" = '160' then 'Godown Transfer' else '' endif))) as "c_cust_code",
      "isnull"("a"."c_name",'Godown Transfer') as "c_name"
      from "st_track_det" as "st" join "st_track_mst" on "st"."c_doc_no" = "st_track_mst"."c_doc_no"
        and "st"."n_inout" = "st_track_mst"."n_inout"
        left outer join "grn_mst" as "g" --"g"."c_br_code"+'/'+"g"."c_year"+'/'+"g"."c_prefix"+'/'+"string"("g"."n_srno") = "c_doc_no"
        on "g"."c_br_code" = "left"(("c_doc_no"),"charindex"('/',("c_doc_no"))-1)
        and "g"."c_year" = "left"("substring"("left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))),"charindex"('/',"left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))),"charindex"('/',"left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))))+1))-1)
        and "g"."c_prefix" = "left"("substr"("substring"("left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))),"charindex"('/',"left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))),"charindex"('/',"left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))))+1))+1),"charindex"('/',"substr"("substring"("left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))),"charindex"('/',"left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))),"charindex"('/',"left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))))+1))+1))-1)
        and "g"."n_srno" = "reverse"("left"("reverse"("c_doc_no"),"charindex"('/',("reverse"("c_doc_no")))-1))
        left outer join "pur_mst" as "p" --"p"."c_br_code"+'/'+"p"."c_year"+'/'+"p"."c_prefix"+'/'+"string"("p"."n_srno") = "c_doc_no" 
        on "p"."c_br_code" = "left"(("c_doc_no"),"charindex"('/',("c_doc_no"))-1)
        and "p"."c_year" = "left"("substring"("left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))),"charindex"('/',"left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))),"charindex"('/',"left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))))+1))-1)
        and "p"."c_prefix" = "left"("substr"("substring"("left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))),"charindex"('/',"left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))),"charindex"('/',"left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))))+1))+1),"charindex"('/',"substr"("substring"("left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))),"charindex"('/',"left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))),"charindex"('/',"left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))))+1))+1))-1)
        and "p"."n_srno" = "reverse"("left"("reverse"("c_doc_no"),"charindex"('/',("reverse"("c_doc_no")))-1))
        and "p"."n_post" = 1
        left outer join "crnt_mst" as "c" --"c"."c_br_code"+'/'+"c"."c_year"+'/'+"c"."c_prefix"+'/'+"string"("c"."n_srno") = "c_doc_no"
        on "c"."c_br_code" = "left"(("c_doc_no"),"charindex"('/',("c_doc_no"))-1)
        and "c"."c_year" = "left"("substring"("left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))),"charindex"('/',"left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))),"charindex"('/',"left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))))+1))-1)
        and "c"."c_prefix" = "left"("substr"("substring"("left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))),"charindex"('/',"left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))),"charindex"('/',"left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))))+1))+1),"charindex"('/',"substr"("substring"("left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))),"charindex"('/',"left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))),"charindex"('/',"left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))))+1))+1))-1)
        and "c"."n_srno" = "reverse"("left"("reverse"("c_doc_no"),"charindex"('/',("reverse"("c_doc_no")))-1))
        --left outer join dbnt_mst as d on d.c_br_code+'/'+d.c_year+'/'+d.c_prefix+'/'+string(d.n_srno) = c_doc_no and d.n_approved = 1
        left outer join "godown_tran_mst" --"godown_tran_mst"."c_br_code"+'/'+"godown_tran_mst"."c_year"+'/'+"godown_tran_mst"."c_prefix"+'/'+"string"("godown_tran_mst"."n_srno") = "c_doc_no" 
        on "godown_tran_mst"."c_br_code" = "left"(("c_doc_no"),"charindex"('/',("c_doc_no"))-1)
        and "godown_tran_mst"."c_year" = "left"("substring"("left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))),"charindex"('/',"left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))),"charindex"('/',"left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))))+1))-1)
        and "godown_tran_mst"."c_prefix" = "left"("substr"("substring"("left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))),"charindex"('/',"left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))),"charindex"('/',"left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))))+1))+1),"charindex"('/',"substr"("substring"("left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))),"charindex"('/',"left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))),"charindex"('/',"left"("c_doc_no",("length"("c_doc_no")-("charindex"('/',"reverse"("c_doc_no"))-1))))+1))+1))-1)
        and "godown_tran_mst"."n_srno" = "reverse"("left"("reverse"("c_doc_no"),"charindex"('/',("reverse"("c_doc_no")))-1))
        and "godown_tran_mst"."n_approved" = 1
        left outer join "act_mst" as "a" on "a"."c_code" = "c_cust_code"
      where "st"."c_godown_code" = @GodownCode and "st_track_mst"."n_complete" <> 9
      --and st.c_doc_no='612221111616'
      group by "c_doc_no","c_tray_code","st"."c_user","Rack_grp","c_rk_code","c_cust_code","c_name" for xml raw,elements
  when 'get_tray_items' then
    select "left"("st"."c_stin_ref_no","length"("st"."c_stin_ref_no")-"charindex"('/',"reverse"("st"."c_stin_ref_no"))) as "c_doc_no",
      "st"."c_item_code" as "c_item_code",
      "st"."c_batch_no",
      "i"."c_name" as "c_name",
      "st"."c_rack" as "c_rk_code",
      "st"."c_rack_grp_code" as "Rack_grp",
      "trim"("str"("truncnum"(("st"."n_qty"/"i"."n_qty_per_box"),3),10,0)) as "Pk_qty",
      "trim"("str"("truncnum"("st"."n_qty",3),10,0)) as "Ls_qty",
      "isnull"("st"."c_user",'') as "c_user",
      (if "st"."n_complete" = 0 then 'Inprocess' else if "st"."n_complete" = 2 then 'Not Found' else 'Completed' endif endif) as "stats"
      from "st_track_det" as "st" join "item_mst" as "i" on "st"."c_item_code" = "i"."c_code"
      --and st.c_doc_no='612221111616'
      where "st"."c_godown_code" = @GodownCode
      and "st"."c_tray_code" = @tray_code
      order by "stats" asc for xml raw,elements
  end case
end;