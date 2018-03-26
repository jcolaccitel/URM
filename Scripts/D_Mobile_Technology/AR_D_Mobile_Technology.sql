--
-- SCRIPT D_Mobile_Technology, entity for URM
-- Engine: Teradata
-- Server: 10.167.37.107
-- DB: AR_PROD_ODS_DATA_VW
-- Owner: Big Data, Telefonica Argentina
--
SELECT 
'722-070'  AS  OPERATOR_ID,
red AS MOBILE_TECH_CD,
trim(red)||'-'||trim(negocio) AS MOBILE_TECH_DES
FROM SBX_PROC_CIERRE.RN_MARCAMODELO_VW
WHERE lower(grupo)='celular'
group by 2,3;    

