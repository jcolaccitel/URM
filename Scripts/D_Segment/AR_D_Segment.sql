--
-- SCRIPT D_Segment, entity for URM
-- Engine: Teradata
-- Server: 10.167.37.107
-- DB: AR_PROD_ODS_DATA_VW
-- Owner: Big Data, Telefonica Argentina
-- El campo gbl_line_status_id se define de acuerdo a la definicion de la dimensional global d_gbl_segment a la fecha:20180131, asi:
--'gbl_segment_id','gbl_line_status_des'
---1|NA
--1|Consumer
--2|Freelances
--3|Corporate
--4|Small Business
--5|Medium Business
--6|Distributors/ wholesalers
--7|Other
--

SELECT	'722-070'	AS	OPERATOR_ID	,
CUSTOMER_SUB_TYPE_KEY	AS	SEGMENT_ID	,
CUSTOMER_TYPE_DESC	AS	SEGMENT_DES	,
CUSTOMER_SUB_TYPE_DESC	AS	SUBSEGMENT_DES	,
CASE WHEN 	CUSTOMER_TYPE_ID ='I' THEN 1
WHEN 	CUSTOMER_TYPE_ID ='I' THEN 1
WHEN 	CUSTOMER_TYPE_ID ='M' THEN 5
WHEN 	CUSTOMER_TYPE_ID ='U' THEN 7
ELSE 7 END 	AS	GLOBAL_SEGMENT_ID	
FROM 	AR_PROD_ODS_DATA_VW.CUSTOMER_SUB_TYPE			
GROUP BY 1,2,3,4,5;


