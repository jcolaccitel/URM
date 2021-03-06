--
-- SCRIPT D_Vendor, entity for URM
-- Engine: Teradata
-- Server: 10.167.37.107
-- DB: AR_PROD_ODS_DATA_VW
-- Owner: Big Data, Telefonica Argentina
--
SELECT  '722-070' AS OPERATOR_ID
, 100*EXTRACT(YEAR FROM CURRENT_DATE)+EXTRACT(MONTH FROM CURRENT_DATE) MONTH_ID
, NVL(CASE WHEN SALES_CODE IN('N/A','N','N/ A','NA','Retail','N/S','N S','null') OR NVL(SALES_CODE,'N')='N' THEN DEALER_CODE ELSE SALES_CODE END,'-1')  AS VENDOR_ID
, NVL(CASE WHEN  DEALER_CODE IN('N/A','N','N/ A','NA','Retail','N/S','N S','null')  OR NVL(DEALER_CODE,'N')='N'   THEN  SALES_CODE ELSE DEALER_CODE  END,'-1')  AS VENDOR_DES
FROM AR_PROD_ODS_DATA_VW.AGENT
GROUP BY 1,2,3,4
ORDER BY 4,3