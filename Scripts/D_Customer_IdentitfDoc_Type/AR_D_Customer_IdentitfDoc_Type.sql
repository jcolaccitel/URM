SELECT	'722-070	' AS	OPERATOR_ID	,
	100*EXTRACT(YEAR FROM CURRENT_DATE)+EXTRACT(MONTH FROM CURRENT_DATE)	AS	CUST_IDENTIFDOC_TYPE_DT	,
	DOCUMENT_TYPE_ID	AS	CUST_IDENTIFDOC_TYPE_ID	,
	DOCUMENT_TYPE_DESC	AS	CUST_IDENTIFDOC_TYPE_DES	
FROM	AR_PROD_ODS_DATA_VW.DOCUMENT_TYPE		
GROUP BY 2,3,4
ORDER BY 2,3,4;	
