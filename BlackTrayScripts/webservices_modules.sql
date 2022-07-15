INSERT INTO "DBA"."st_track_module_mst" ("c_code","c_module_name","n_active","n_seq","c_menu_id","n_validate_user_right","d_date","t_time","d_ldate","t_ltime","n_hide","c_br_code") 
VALUES('M00133','ENABLE BLACK TRAY MODULE',0,133,NULL,0,TODAY(),NOW(),TODAY(),NOW(),1,uf_get_br_code('000'));

INSERT INTO "DBA"."st_track_module_mst" ("c_code","c_module_name","n_active","n_seq","c_menu_id","n_validate_user_right","d_date","t_time","d_ldate","t_ltime","n_hide","c_br_code") 
VALUES('M00134','BLACK TRAY SUPERVISOR MODULE',0,134,NULL,0,TODAY(),NOW(),TODAY(),NOW(),1,uf_get_br_code('000'));

if (select count() from syswebservice where service_name = 'ws_st_err_tracking') = 0 then
    CREATE SERVICE "ws_st_err_tracking" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>'
      from "DBA"."usp_st_err_tracking"(:url1,:url2,:url3,:url4,:url5,:url6,:url7,:url8,:url9,:url10);
end if ;
commit work;
go
