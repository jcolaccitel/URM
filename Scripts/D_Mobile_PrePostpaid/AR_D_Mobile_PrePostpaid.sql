--
-- SCRIPT D_Mobile_PrePostpaid, entity for URM
-- Engine: Teradata
-- Server: 10.167.37.107
-- DB: AR_PROD_ODS_DATA_VW
-- Owner: Big Data, Telefonica Argentina
-- El campo gbl_line_status_id se define de acuerdo a la definicion de la dimensional global gbl_Mobile_PrePostpaid a la fecha:20180131, asi:
--'d_gbl_Mobile_PrePostpaid_id','gbl_Mobile_PrePostpaid_des'
-- -1  N/A
-- 1  Postpaid
-- 2 Prepaid
-- 3 Hybrid
--

SELECT '722-07' AS OPERATOR_ID,
CASE  WHEN S.OFFER_TYPE_KEY =1003 THEN 'C' 
WHEN S.OFFER_TYPE_KEY =1001 THEN 'H' 
ELSE 'P' END AS PRE_POSTPAID_ID,
CASE WHEN S.OFFER_TYPE_KEY IN(1003) THEN UPPER(OFFER_TYPE_ID) 
WHEN S.OFFER_TYPE_KEY =1001 THEN 'HIBRIDO' 
ELSE 'PREPAGO' END  AS PRE_POSTPAID_DES,
CASE
  WHEN s.offer_type_key=1003
  THEN 1
  WHEN s.offer_type_key=1001
  THEN 3
  ELSE 2
  END AS GBL_PRE_POSTPAID_ID
 FROM AR_PROD_ODS_DATA_VW.OFFER_TYPE S
 GROUP BY 2,3,4
 ORDER BY 2,3,4;
 



