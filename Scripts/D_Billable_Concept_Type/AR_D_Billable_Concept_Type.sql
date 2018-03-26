--
-- SCRIPT D_Billable_Concept_Type, entity for URM
-- Engine: Teradata
-- Server: 10.167.37.107
-- DB: AR_PROD_ODS_DATA_VW
-- Owner: Big Data, Telefonica Argentina
--

SELECT 	'722-070' AS OPERATOR_ID,
CHARGE_TYPE_KEY AS	BILL_CONCEPT_TYPE_CD,
CHARGE_TYPE_DESC AS BILL_CONCEPT_TYPE_DES
FROM AR_PROD_ODS_DATA_VW.CHARGE_TYPE
group by 2,3
order by 2,3;