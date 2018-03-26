--
-- SCRIPT D_Line_Status, entity for URM
-- Engine: Teradata
-- Server: 10.167.37.107
-- DB: AR_PROD_ODS_DATA_VW
-- Owner: Big Data, Telefonica Argentina
-- El campo gbl_line_status_id se define de acuerdo a la definicion de la dimensional global gbl_line_status a la fecha:20180131, asi:
--'urm.d_gbl_line_status.gbl_line_status_id','urm.d_gbl_line_status.gbl_line_status_des'
--'-1','N/A'
--'1','Active'
--'2','Subscription Cancel'
--'3','Inactive'
--

SELECT
  '722-070' operator_id,
  subscriber_status_key as line_status_id,
  subscriber_status_desc as line_status_des,
case when subscriber_status_key in(1001,1006) then 1
when subscriber_status_key in (1000,1005,1007) then 2
when subscriber_status_key in (1002,1008,1004,1003) then 3
else -1 end as gbl_line_status_id
FROM
  ar_prod_ods_data_vw.subscriber_status
GROUP BY 2,3;
