--
-- SCRIPT D_Mobile_Tariff_Plan, entity for URM
-- Engine: Teradata (ODS)
-- Server: 10.167.37.107
-- DB: AR_PROD_ODS_DATA_VW
-- Owner: Big Data, Telefonica Argentina
--

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- OFFER_MOBILE: ASOCIA LA OFERTA CON SUS PLAN PRICE ASIGNADOS.
--  REL.PARENT_PRODUCT_KEY='491' , Indica los productos que son tipo plan
--  'Plan%Incl%'  : Filtra el plan incluidos de la lista de componentes de la oferta
 --   Plan%Ex%' : Filtra el plan excedente de la lista de componentes de la oferta
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE VOLATILE TABLE OFFER_MOBILE, NO LOG AS ( 
SELECT PROOT.PRODUCT_KEY,  PROOT.PRODUCT_DESC,MAX(PCHILDINC.PRODUCT_KEY) AS INCLU_PRODUCT_KEY, MAX(PCHILDEXE.PRODUCT_KEY) AS EXCE_PRODUCT_KEY, 
MAX(REL.PCVERSION_ID) AS VERSION, MAX(REL.BATCH_ID) AS BATCH
FROM  AR_PROD_ODS_DATA_VW.PRODUCT_CATALOG_REL REL 
INNER JOIN  AR_PROD_ODS_DATA_VW.PRODUCT PROOT ON REL.ROOT_PRODUCT_CATALOG_ID=PROOT.PRODUCT_KEY AND REL.END_DATE IS NULL  AND  REL.PARENT_PRODUCT_KEY='491' 
LEFT JOIN  AR_PROD_ODS_DATA_VW.PRODUCT PCHILDINC ON REL.CHILD_PRODUCT_KEY=PCHILDINC.PRODUCT_KEY AND PCHILDINC.PRODUCT_DESC LIKE 'Plan%Incl%'
LEFT JOIN  AR_PROD_ODS_DATA_VW.PRODUCT PCHILDEXE ON REL.CHILD_PRODUCT_KEY=PCHILDEXE.PRODUCT_KEY AND PCHILDEXE.PRODUCT_DESC LIKE 'Plan%Ex%'
GROUP BY 1,2
) WITH DATA
PRIMARY INDEX (PRODUCT_KEY)
ON COMMIT PRESERVE ROWS;

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PLANES_MOBILE: Muestra el detalle del producto del catalogo segun la oferta
--  REL.PARENT_PRODUCT_KEY='491' , Indica los productos que son tipo plan
--  'Plan%Incl%'  : Filtra el plan incluidos de la lista de componentes de la oferta
 --   Plan%Ex%' : Filtra el plan excedente de la lista de componentes de la oferta
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE VOLATILE TABLE PLANES_MOBILE, NO LOG AS ( 
SELECT  P.PRODUCT_KEY, 
P.PRODUCT_DESC,
OM.INCLU_PRODUCT_KEY AS INCLUIDOS,
OM.EXCE_PRODUCT_KEY AS EXCEDENTES,
PCT.PRODUCT_CATALOG_TYPE_DESC AS CATALOG_TYPE_DESC,
PC.PRODUCT_CATEGORY_DESC AS CATEGORY_DESC,
PLOB.PRODUCT_LINE_OF_BUSINESS_DESC AS LINE_OF_BUSINESS_DESC, 
P.PRODUCT_VALID_FROM_DATE,
P.PRODUCT_VALID_TO_DATE,
CASE WHEN INSTR(P.PRODUCT_DESC,'MB')>0 THEN  CAST(CASE WHEN REGEXP_SUBSTR(SUBSTR(P.PRODUCT_DESC,INSTR(P.PRODUCT_DESC,'MB')-5),  '[0-9]+[,]+[0-9]') IS NULL THEN REGEXP_SUBSTR(SUBSTR(P.PRODUCT_DESC,INSTR(P.PRODUCT_DESC,'MB')-5), '[0-9]+')  ELSE CAST( REGEXP_SUBSTR(SUBSTR(P.PRODUCT_DESC,INSTR(P.PRODUCT_DESC,'MB')-5),  '[0-9]+[,]+[0-9]') AS DECIMAL(10,3))/10 END AS DECIMAL(10,3))
WHEN INSTR(P.PRODUCT_DESC,'GB')>0 THEN  1024* CAST(CASE WHEN REGEXP_SUBSTR(SUBSTR(P.PRODUCT_DESC,INSTR(P.PRODUCT_DESC,'GB')-5),  '[0-9]+[,]+[0-9]') IS NULL THEN REGEXP_SUBSTR(SUBSTR(P.PRODUCT_DESC,INSTR(P.PRODUCT_DESC,'GB')-5), '[0-9]+')  ELSE CAST(REGEXP_SUBSTR(SUBSTR(P.PRODUCT_DESC,INSTR(P.PRODUCT_DESC,'GB')-5),  '[0-9]+[,]+[0-9]') AS DECIMAL(10,3))/10 END  AS DECIMAL(10,3))
ELSE 0
END AS DATA_MB,
CASE WHEN CURRENT_DATE>=P.PRODUCT_VALID_FROM_DATE AND CURRENT_DATE<=P.PRODUCT_VALID_TO_DATE THEN 1 ELSE 0 END AS VIGENTE,
10000*EXTRACT(YEAR FROM P.SOURCE_TIMESTAMP)+100*EXTRACT(MONTH FROM P.SOURCE_TIMESTAMP)+EXTRACT(DAY FROM P.SOURCE_TIMESTAMP) AS FECHA
FROM AR_PROD_ODS_DATA_VW.PRODUCT P 
INNER JOIN OFFER_MOBILE OM ON P.PRODUCT_KEY=OM.PRODUCT_KEY
LEFT JOIN AR_PROD_ODS_DATA_VW.PRODUCT_CATALOG_TYPE PCT ON PCT.PRODUCT_CATALOG_TYPE_KEY=P.PRODUCT_CATALOG_TYPE_KEY
LEFT JOIN AR_PROD_ODS_DATA_VW.PRODUCT_CATEGORY PC ON PC.PRODUCT_CATEGORY_KEY=P.PRODUCT_CATEGORY_KEY
LEFT JOIN AR_PROD_ODS_DATA_VW.PRODUCT_LINE_OF_BUSINESS PLOB ON PLOB.PRD_LINE_OF_BUSINESS_KEY=P.PRODUCT_LINE_OF_BUSINESS_KEY
) WITH DATA
PRIMARY INDEX (PRODUCT_KEY)
ON COMMIT PRESERVE ROWS;

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PLAN_OFFER_PARAMETERS: Muestra el detalle de los parametros asociados a una oferta BO
--  Solo se tuvieron en cuenta los siguientes parametros de acuerdo a su relevancia
--  'F12_INTERNET': Texto con la cantidad de datos incluidos y  los valores para excedentes de datos
-- 'NAVEGÁ': Descripción comercial de la oferta
-- 'CLASIFICACIÓN DEL EQUIPO': Codigo del tipo de equipo asociado a la oferta (movil, mec, im...)
-- 'F5_ABONO' : Texto con el valor  del Abono mensual de la oferta
-- 'PRODUCT': Tipo de producto de la oferta (postpago, prepago...)
-- 'F37_1ROS_30_SEG': Texto con el costo por segundo,para  los primeros 30 segundos por llamada, de excendentes de voz
-- 'F39_SEG_EXCEDENTE': Texto con el costo por segundo, despues de 30 segundos por llamada de excedentes de voz
-- 'F42_SMS_EXCEDENTE': Costo de cada sms excedente
 -- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


CREATE VOLATILE TABLE PLAN_OFFER_PARAMETERS, NO LOG AS (
SELECT  P.PRODUCT_KEY
, POP.PRODUCT_PARAMETER_NAME
,A.DEFAULT_VALUE 
FROM PLANES_MOBILE P
INNER  JOIN AR_PROD_ODS_DATA_VW.PRD_CAT_PARAM_REL      A ON A.PRODUCT_KEY=P.PRODUCT_KEY
INNER JOIN AR_PROD_ODS_DATA_VW.PRODUCT_PARAMETERS POP ON A.PRODUCT_PARAMETER_KEY=POP.PRODUCT_PARAMETER_KEY 
AND UPPER(POP.PRODUCT_PARAMETER_NAME) IN ('F12_INTERNET','NAVEGÁ','CLASIFICACIÓN DEL EQUIPO','F5_ABONO','PRODUCT','F37_1ROS_30_SEG','F39_SEG_EXCEDENTE','F42_SMS_EXCEDENTE')
WHERE  A.DEFAULT_VALUE IS NOT NULL
GROUP BY 1,2,3
) WITH DATA
PRIMARY INDEX (PRODUCT_KEY)
ON COMMIT PRESERVE ROWS;

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TABLAS POP_*: Sirven para obtener  los parametros obtenidos en PLAN_OFFER_PARAMETERS, normalizarlos
--  y  transponer la tabla para llegar a un solo registro por product_key
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE VOLATILE TABLE POP_CEQ, NO LOG AS (
SELECT   P.PRODUCT_KEY
, UPPER(P.DEFAULT_VALUE)   AS PRODUCT_TYPE
FROM PLAN_OFFER_PARAMETERS P
WHERE UPPER(P.PRODUCT_PARAMETER_NAME) IN ('CLASIFICACIÓN DEL EQUIPO')
) WITH DATA
PRIMARY INDEX (PRODUCT_KEY)
ON COMMIT PRESERVE ROWS;

CREATE VOLATILE TABLE POP_PRODUCT, NO LOG AS (
SELECT   P.PRODUCT_KEY
,CASE  WHEN TRIM(UPPER(P.DEFAULT_VALUE)) IN ('PORTEPAGADO','PRE','PREPAID') THEN 'P' 
 WHEN TRIM(UPPER(P.DEFAULT_VALUE)) IN ('CONTROL') THEN 'H' 
 WHEN TRIM(UPPER(P.DEFAULT_VALUE)) IN ('POSTPAGO') THEN 'C'
 ELSE NVL(P.DEFAULT_VALUE,'NI') END AS PREPOSTPAID_ID
FROM PLAN_OFFER_PARAMETERS P
WHERE UPPER(P.PRODUCT_PARAMETER_NAME) IN ('PRODUCT')
) WITH DATA
PRIMARY INDEX (PRODUCT_KEY)
ON COMMIT PRESERVE ROWS;

CREATE VOLATILE TABLE POP_ABONO, NO LOG AS (
SELECT   P.PRODUCT_KEY
,UPPER(P.DEFAULT_VALUE)   AS AMOUNT
FROM PLAN_OFFER_PARAMETERS P
WHERE UPPER(P.PRODUCT_PARAMETER_NAME) IN ('F5_ABONO')
) WITH DATA
PRIMARY INDEX (PRODUCT_KEY)
ON COMMIT PRESERVE ROWS;


CREATE VOLATILE TABLE POP_DATA, NO LOG AS (
SELECT   P.PRODUCT_KEY
,UPPER(P.DEFAULT_VALUE)   AS DATA_DESC
,CASE WHEN INSTR(UPPER(P.DEFAULT_VALUE),'GB')>0 THEN  1024* CAST(CASE WHEN REGEXP_SUBSTR(SUBSTR(P.DEFAULT_VALUE,INSTR(P.DEFAULT_VALUE,'GB')-5),  '[0-9]+[,]+[0-9]') IS NULL THEN REGEXP_SUBSTR(SUBSTR(P.DEFAULT_VALUE,INSTR(P.DEFAULT_VALUE,'GB')-5), '[0-9]+')  ELSE CAST(REGEXP_SUBSTR(SUBSTR(P.DEFAULT_VALUE,INSTR(P.DEFAULT_VALUE,'GB')-5),  '[0-9]+[,]+[0-9]') AS DECIMAL(10,3))/10 END  AS DECIMAL(10,3))
WHEN INSTR(UPPER(P.DEFAULT_VALUE),'MB')>0 THEN  CAST(CASE WHEN REGEXP_SUBSTR(SUBSTR(P.DEFAULT_VALUE,INSTR(P.DEFAULT_VALUE,'MB')-3),  '[0-9]+[,]+[0-9]') IS NULL THEN REGEXP_SUBSTR(SUBSTR(P.DEFAULT_VALUE,INSTR(P.DEFAULT_VALUE,'MB')-5), '[0-9]+')  ELSE CAST( REGEXP_SUBSTR(SUBSTR(P.DEFAULT_VALUE,INSTR(P.DEFAULT_VALUE,'MB')-5),  '[0-9]+[,]+[0-9]') AS DECIMAL(10,3))/10 END AS DECIMAL(10,3))
ELSE 0 END   AS DATA_MB
FROM PLAN_OFFER_PARAMETERS P
WHERE UPPER(P.PRODUCT_PARAMETER_NAME) IN ('F12_INTERNET')
) WITH DATA
PRIMARY INDEX (PRODUCT_KEY)
ON COMMIT PRESERVE ROWS;

CREATE VOLATILE TABLE POP_1ROS_30_SEG, NO LOG AS (
SELECT   P.PRODUCT_KEY
,UPPER(P.DEFAULT_VALUE)   AS VOICE_1ROS_30_SEG
FROM PLAN_OFFER_PARAMETERS P
WHERE UPPER(P.PRODUCT_PARAMETER_NAME) IN ('F37_1ROS_30_SEG')
) WITH DATA
PRIMARY INDEX (PRODUCT_KEY)
ON COMMIT PRESERVE ROWS;

--select * from PLAN_OFFER_PARAMETERS


CREATE VOLATILE TABLE POP_SEG_EXCEDENTE, NO LOG AS (
SELECT   P.PRODUCT_KEY
,UPPER(P.DEFAULT_VALUE)   AS VOICE_SEG_EXCEDENTE
FROM PLAN_OFFER_PARAMETERS P
WHERE UPPER(P.PRODUCT_PARAMETER_NAME) IN ('F39_SEG_EXCEDENTE')
) WITH DATA
PRIMARY INDEX (PRODUCT_KEY)
ON COMMIT PRESERVE ROWS;

CREATE VOLATILE TABLE POP_SMS_EXCEDENTE, NO LOG AS (
SELECT   P.PRODUCT_KEY
,UPPER(P.DEFAULT_VALUE)   AS SMS_EXCEDENTE
FROM PLAN_OFFER_PARAMETERS P
WHERE UPPER(P.PRODUCT_PARAMETER_NAME) IN ('F42_SMS_EXCEDENTE')
) WITH DATA
PRIMARY INDEX (PRODUCT_KEY)
ON COMMIT PRESERVE ROWS;

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- POP_PARAMETERS: Muestra PLAN_OFFER_PARAMETERS, transpuesta y normalizada
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


CREATE VOLATILE TABLE POP_PARAMETERS, NO LOG AS (
SELECT   CEQ.PRODUCT_KEY
,CEQ.PRODUCT_TYPE
,PR.PREPOSTPAID_ID
,AB.AMOUNT
,CASE WHEN  D.DATA_MB=9 THEN  0  ELSE  D.DATA_MB END AS DATA_MB
,D.DATA_DESC
,PTS.VOICE_1ROS_30_SEG
,SE.VOICE_SEG_EXCEDENTE
,SM.SMS_EXCEDENTE
FROM POP_CEQ CEQ
INNER JOIN POP_PRODUCT PR ON PR.PRODUCT_KEY=CEQ.PRODUCT_KEY
INNER JOIN POP_ABONO AB ON AB.PRODUCT_KEY=CEQ.PRODUCT_KEY
INNER JOIN POP_DATA D ON D.PRODUCT_KEY=CEQ.PRODUCT_KEY
INNER JOIN POP_1ROS_30_SEG PTS ON PTS.PRODUCT_KEY=CEQ.PRODUCT_KEY
INNER JOIN POP_SEG_EXCEDENTE SE ON SE.PRODUCT_KEY=CEQ.PRODUCT_KEY
INNER JOIN POP_SMS_EXCEDENTE SM ON SM.PRODUCT_KEY=CEQ.PRODUCT_KEY
) WITH DATA
PRIMARY INDEX (PRODUCT_KEY)
ON COMMIT PRESERVE ROWS;

--SEL product_key FROM POP_PARAMETERS group by product_key having count(1)>1;
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PLAN_INCLUDED_PARAMETERS: Muestra los parametros asociados al componente, plan de precios incluidos de la oferta
-- Se seleccionaron algunos parametros especificos:
--'ALTAMIRAINCLUDEDALLOWANCEDATA1': Tiene como valor el bono de datos o el bono reductor que desencadena el bono de datos final para una PO determinada
--ALTAMIRAINCLUDEDALLOWANCESMS1': Tiene como valor el bono de sms y su cantidad asociada para una PO determinada
--'ALTAMIRAINCLUDEDALLOWANCESMS2': Puede teener el bono de sms, o para los casos que el  ALTAMIRAINCLUDEDALLOWANCEDATA1 sea
--                                                                                 un reductor de datos, puede contener el bono de datos final
--'ALTAMIRAINCLUDEDALLOWANCEVOICE1': Tiene el bono de voz  onnet y su cantidad asociada para una PO determinada
--'ALTAMIRAINCLUDEDALLOWANCEVOICE2': Tiene el bono de voz  offnet y su cantidad asociada para una PO determinada
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE VOLATILE TABLE PLAN_INCLUDED_PARAMETERS, NO LOG AS (
SELECT   P.PRODUCT_KEY
,PI.PRODUCT_PARAMETER_NAME,
A.DEFAULT_VALUE 
FROM PLANES_MOBILE P
INNER  JOIN AR_PROD_ODS_DATA_VW.PRD_CAT_PARAM_REL      A ON A.PRODUCT_KEY=P.INCLUIDOS
INNER JOIN AR_PROD_ODS_DATA_VW.PRODUCT_PARAMETERS PI ON A.PRODUCT_PARAMETER_KEY=PI.PRODUCT_PARAMETER_KEY 
AND UPPER(PI.PRODUCT_PARAMETER_NAME) IN ('ALTAMIRAINCLUDEDALLOWANCEDATA1','ALTAMIRAINCLUDEDALLOWANCESMS1','ALTAMIRAINCLUDEDALLOWANCESMS2','ALTAMIRAINCLUDEDALLOWANCEVOICE1','ALTAMIRAINCLUDEDALLOWANCEVOICE2')
WHERE  A.DEFAULT_VALUE IS NOT NULL
) WITH DATA
PRIMARY INDEX (PRODUCT_KEY)
ON COMMIT PRESERVE ROWS;

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TABLAS PIP_*: Sirven para obtener  los parametros obtenidos en PLAN_INCLUDED_PARAMETERS, normalizarlos
--  y  transponer la tabla para llegar a un solo registro por product_key
-- En todos los casos se usa una expresion regular pra obtener los valores numericos asociadosa los bonos
-- En todos los casos se hace substr para obtener el nombre de los bonos
-- Para el caso de los SMS se filtran los bonos con caract. LIKE 'MPSA%' OR  'REDUCCW%', por tratarse de bonos de datos o reductores
-- Para el caso de voz se filtra por la substr  '%#OFF' o  '%#ON' para determinar si el bono refiere a voz on u off net
-- Para el caso de datos se filtran los bonos con caract.  'REDPSQ%' o 'RED%' o 'ROAM%' por tratarse de bonos reductores
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE VOLATILE TABLE PIP_SMS, NO LOG AS (
SELECT   P.PRODUCT_KEY, P.DEFAULT_VALUE
,CASE  WHEN INSTR(UPPER(P.DEFAULT_VALUE),'#')>0 THEN SUBSTR(P.DEFAULT_VALUE,1,INSTR(UPPER(P.DEFAULT_VALUE),'#')-1) ELSE 'NI' END   BONO_SMS  
,CASE WHEN P.DEFAULT_VALUE LIKE 'MPSA%' OR  P.DEFAULT_VALUE LIKE 'REDUCCW%' THEN 0 ELSE CAST(REGEXP_SUBSTR(P.DEFAULT_VALUE, '[0-9]+') AS BIGINT) END AS SMS_UND
FROM PLAN_INCLUDED_PARAMETERS P
WHERE UPPER(P.PRODUCT_PARAMETER_NAME) = 'ALTAMIRAINCLUDEDALLOWANCESMS1'
) WITH DATA
PRIMARY INDEX (PRODUCT_KEY)
ON COMMIT PRESERVE ROWS;

CREATE VOLATILE TABLE PIP_VOZ_ONNET, NO LOG AS (
SELECT   P.PRODUCT_KEY
,P.DEFAULT_VALUE 
,CASE  WHEN INSTR(UPPER(P.DEFAULT_VALUE),'#')>0 THEN SUBSTR(P.DEFAULT_VALUE,1,INSTR(UPPER(P.DEFAULT_VALUE),'#')-1) ELSE 'NI' END   BONO_VOICE_ONNET  
,CAST(REGEXP_SUBSTR(P.DEFAULT_VALUE, '[0-9]+') AS BIGINT) AS VOZ_ONNET_SEG
FROM PLAN_INCLUDED_PARAMETERS P
WHERE UPPER(P.PRODUCT_PARAMETER_NAME)  IN ('ALTAMIRAINCLUDEDALLOWANCEVOICE1','ALTAMIRAINCLUDEDALLOWANCEVOICE2')
AND P.DEFAULT_VALUE LIKE '%#ON'
) WITH DATA
PRIMARY INDEX (PRODUCT_KEY)
ON COMMIT PRESERVE ROWS;

CREATE VOLATILE TABLE PIP_VOZ_OFFNET, NO LOG AS (
SELECT   P.PRODUCT_KEY
,P.DEFAULT_VALUE 
,CASE  WHEN INSTR(UPPER(P.DEFAULT_VALUE),'#')>0 THEN SUBSTR(P.DEFAULT_VALUE,1,INSTR(UPPER(P.DEFAULT_VALUE),'#')-1) ELSE 'NI' END   BONO_VOICE_OFFNET  
,CAST(REGEXP_SUBSTR(P.DEFAULT_VALUE, '[0-9]+') AS BIGINT) AS VOZ_OFFNET_SEG
FROM PLAN_INCLUDED_PARAMETERS P
WHERE UPPER(P.PRODUCT_PARAMETER_NAME)  IN ('ALTAMIRAINCLUDEDALLOWANCEVOICE1','ALTAMIRAINCLUDEDALLOWANCEVOICE2')
AND P.DEFAULT_VALUE LIKE '%#OFF'
) WITH DATA
PRIMARY INDEX (PRODUCT_KEY)
ON COMMIT PRESERVE ROWS;


CREATE VOLATILE TABLE PIP_DATA0, NO LOG AS (
SELECT   P.PRODUCT_KEY
,P.DEFAULT_VALUE 
,CASE  WHEN INSTR(UPPER(P.DEFAULT_VALUE),'#')>0 THEN SUBSTR(P.DEFAULT_VALUE,1,INSTR(UPPER(P.DEFAULT_VALUE),'#')-1) ELSE 'NI' END   BONO_DATOS  
,CASE  WHEN INSTR(UPPER(P.DEFAULT_VALUE),'#Y#')>0 THEN CAST(REGEXP_SUBSTR(SUBSTR(P.DEFAULT_VALUE,INSTR(UPPER(P.DEFAULT_VALUE),'#Y#')+1) , '[0-9]+') AS BIGINT)  ELSE 0 END DATA_MB
FROM PLAN_INCLUDED_PARAMETERS P
WHERE UPPER(P.PRODUCT_PARAMETER_NAME)  IN ('ALTAMIRAINCLUDEDALLOWANCEDATA1','ALTAMIRAINCLUDEDALLOWANCESMS2')
AND P.DEFAULT_VALUE NOT LIKE 'REDPSQ%'
) WITH DATA
PRIMARY INDEX (PRODUCT_KEY)
ON COMMIT PRESERVE ROWS;

CREATE VOLATILE TABLE PIP_DATA2, NO LOG AS (
SELECT   P.PRODUCT_KEY
,P.DEFAULT_VALUE 
,CASE  WHEN INSTR(UPPER(P.DEFAULT_VALUE),'#')>0 THEN SUBSTR(P.DEFAULT_VALUE,1,INSTR(UPPER(P.DEFAULT_VALUE),'#')-1) ELSE 'NI' END   BONO_DATOS
,CASE  WHEN INSTR(UPPER(P.DEFAULT_VALUE),'#Y#')>0 THEN CAST(REGEXP_SUBSTR(SUBSTR(P.DEFAULT_VALUE,INSTR(UPPER(P.DEFAULT_VALUE),'#Y#')+1) , '[0-9]+') AS BIGINT)  ELSE 0 END DATA_MB
FROM PLAN_INCLUDED_PARAMETERS P
WHERE UPPER(P.PRODUCT_PARAMETER_NAME)  IN ('ALTAMIRAINCLUDEDALLOWANCESMS2')
) WITH DATA
PRIMARY INDEX (PRODUCT_KEY)
ON COMMIT PRESERVE ROWS;


CREATE VOLATILE TABLE PIP_DATA, NO LOG AS (
SELECT P0.PRODUCT_KEY
,NVL(P2. BONO_DATOS,'NI') AS BONO_SMS2
,CASE WHEN P0. BONO_DATOS LIKE 'RED%'  OR P0. BONO_DATOS LIKE 'ROAM%'   THEN P2. BONO_DATOS  ELSE  P0. BONO_DATOS END  AS  BONO_DATOS
,MAX(CASE WHEN (CASE WHEN P0. BONO_DATOS LIKE 'RED%'  OR P0. BONO_DATOS LIKE 'ROAM%'   THEN P2. DATA_MB  ELSE  P0. DATA_MB END) <1000000 THEN 0
 WHEN (CASE WHEN P0. BONO_DATOS LIKE 'RED%'  OR P0. BONO_DATOS LIKE 'ROAM%'   THEN P2. DATA_MB  ELSE  P0. DATA_MB END) IN(1000000,999999999) THEN 1024
ELSE (CASE WHEN P0. BONO_DATOS LIKE 'RED%'  OR P0. BONO_DATOS LIKE 'ROAM%'   THEN P2. DATA_MB  ELSE  P0. DATA_MB END)/1048576 END) AS  DATA_MB
FROM PIP_DATA0 P0
LEFT JOIN PIP_DATA2 P2 ON P2.PRODUCT_KEY= P0.PRODUCT_KEY 
group by 1,2,3
) WITH DATA
PRIMARY INDEX (PRODUCT_KEY)
ON COMMIT PRESERVE ROWS;

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PIP_PARAMETERS: Muestra PLAN_INCLUDED_PARAMETERS, transpuesta y normalizada
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE VOLATILE TABLE PIP_PARAMETERS, NO LOG AS (
SELECT P0.PRODUCT_KEY
,P0.BONO_SMS
,P0.SMS_UND
,P1.BONO_SMS2
,P1.BONO_DATOS
,P1.DATA_MB
,P2.BONO_VOICE_ONNET
,P2.VOZ_ONNET_SEG AS VOICE_ONNET_SEG
,P3.BONO_VOICE_OFFNET
,P3.VOZ_OFFNET_SEG AS VOICE_OFFNET_SEG
FROM  PIP_SMS P0
INNER JOIN PIP_DATA  P1 ON P1.PRODUCT_KEY= P0.PRODUCT_KEY
INNER JOIN PIP_VOZ_ONNET P2 ON P2.PRODUCT_KEY= P0.PRODUCT_KEY
INNER JOIN PIP_VOZ_OFFNET P3 ON P3.PRODUCT_KEY= P0.PRODUCT_KEY
) WITH DATA
PRIMARY INDEX (PRODUCT_KEY)
ON COMMIT PRESERVE ROWS;


-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PLAN_BILLING_PARAMETERS: Muestra los parametros facturables, o que se muestran en factura, de una oferta
-- Se filtraron algunos poarametros especificos:
-- rate: Se refiere al costo full del abono mensual
-- charge code: Indica el codigo del cargo que se asocia a la factura por el abono mensual, deberia coincidir con el PSA_CODE, 
--                          que deberia coincidir con el codigo de plan de altamira
-- currency code: Se refiere al  codigo del tipo de moneda usada en la factura.
-- frecuency: Es la frecuencia de la información
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE VOLATILE TABLE PLAN_BILLING_PARAMETERS, NO LOG AS (
SELECT PRODUCT_KEY,
lower(BILLING_ATTRIBUTE_NAME) AS BILLING_ATTRIBUTE_NAME, 
MAX(VERTICAL_VERSION_MAJOR) AS VERSION
FROM AR_PROD_ODS_DATA_VW.PRODUCT_BILLING_PARAMETERS
WHERE lower(BILLING_ATTRIBUTE_NAME) IN ('rate' ,'charge code' , 'currency code', 'frequency')
GROUP BY PRODUCT_KEY, BILLING_ATTRIBUTE_NAME
) WITH DATA
PRIMARY INDEX (PRODUCT_KEY)
ON COMMIT PRESERVE ROWS;


-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TABLAS PBR_*: Sirven para obtener  los parametros obtenidos en PLAN_BILLING_PARAMETERS, normalizarlos
--  y  transponer la tabla para llegar a un solo registro por product_key
-- En el caso de 'rate' se usa una expresion regular para obtener los valor full y el valor sin impuestos
-- En todos los casos se hace substr para obtener el nombre de los bonos
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE VOLATILE TABLE PBR_RATE, NO LOG AS (
SELECT PL.PRODUCT_KEY,
CASE WHEN NVL(CAST(REGEXP_SUBSTR(PR.BILLING_ATTRIBUTE_DEFAULT_VALU , '[0-9]+') AS BIGINT),0) =0 THEN 0  ELSE PR.BILLING_ATTRIBUTE_DEFAULT_VALU END  AS VALUE_WO_TAXES,
ROUND((NVL(CAST(REGEXP_SUBSTR(PR.BILLING_ATTRIBUTE_DEFAULT_VALU , '[0-9]+') AS BIGINT),0)/(1-(0.20107))),0) AS VALUE_FULL 
FROM AR_PROD_ODS_DATA_VW.PRODUCT_BILLING_PARAMETERS PR
INNER JOIN PLAN_BILLING_PARAMETERS PL ON PL.PRODUCT_KEY=PR.PRODUCT_KEY 
AND PL.BILLING_ATTRIBUTE_NAME= lower(PR.BILLING_ATTRIBUTE_NAME)
AND PL.VERSION=PR.VERTICAL_VERSION_MAJOR
WHERE PL.BILLING_ATTRIBUTE_NAME='rate'
) WITH DATA
PRIMARY INDEX (PRODUCT_KEY)
ON COMMIT PRESERVE ROWS;


CREATE VOLATILE TABLE PBR_FREQ, NO LOG AS (
SELECT PL.PRODUCT_KEY,
PR.BILLING_ATTRIBUTE_DEFAULT_VALU  AS FREQUENCY 
FROM AR_PROD_ODS_DATA_VW.PRODUCT_BILLING_PARAMETERS PR
INNER JOIN PLAN_BILLING_PARAMETERS PL ON PL.PRODUCT_KEY=PR.PRODUCT_KEY 
AND PL.BILLING_ATTRIBUTE_NAME= lower(PR.BILLING_ATTRIBUTE_NAME)
AND PL.VERSION=PR.VERTICAL_VERSION_MAJOR
WHERE PL.BILLING_ATTRIBUTE_NAME='frecuency'
) WITH DATA
PRIMARY INDEX (PRODUCT_KEY)
ON COMMIT PRESERVE ROWS;

CREATE VOLATILE TABLE PBR_CHARGE, NO LOG AS (
SELECT PL.PRODUCT_KEY,
TRIM(PR.BILLING_ATTRIBUTE_DEFAULT_VALU) AS VCHARGE_CODE
FROM AR_PROD_ODS_DATA_VW.PRODUCT_BILLING_PARAMETERS PR
INNER JOIN PLAN_BILLING_PARAMETERS PL ON PL.PRODUCT_KEY=PR.PRODUCT_KEY 
AND PL.BILLING_ATTRIBUTE_NAME= lower(PR.BILLING_ATTRIBUTE_NAME)
AND PL.VERSION=PR.VERTICAL_VERSION_MAJOR
WHERE PL.BILLING_ATTRIBUTE_NAME='charge code'
) WITH DATA
PRIMARY INDEX (PRODUCT_KEY)
ON COMMIT PRESERVE ROWS;

CREATE VOLATILE TABLE PBR_CURR, NO LOG AS (
SELECT PL.PRODUCT_KEY,
PR.BILLING_ATTRIBUTE_DEFAULT_VALU AS CURRENCY_CODE
FROM AR_PROD_ODS_DATA_VW.PRODUCT_BILLING_PARAMETERS PR
INNER JOIN PLAN_BILLING_PARAMETERS PL ON PL.PRODUCT_KEY=PR.PRODUCT_KEY 
AND PL.BILLING_ATTRIBUTE_NAME= lower(PR.BILLING_ATTRIBUTE_NAME)
AND PL.VERSION=PR.VERTICAL_VERSION_MAJOR
WHERE PL.BILLING_ATTRIBUTE_NAME='currency code'
) WITH DATA
PRIMARY INDEX (PRODUCT_KEY)
ON COMMIT PRESERVE ROWS;

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PBR_PARAMETERS: Muestra PLAN_BILLING_PARAMETERS, transpuesta y normalizada
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE VOLATILE TABLE PBR_PARAMETERS, NO LOG AS (
SELECT P.PRODUCT_KEY
,COALESCE(PR.VALUE_WO_TAXES,0)  AS AMMOUNT_WO_TAXES
,COALESCE(PR.VALUE_FULL,0)  AS AMMOUNT_FULL
,COALESCE(PF.FREQUENCY,'NI') AS FREQUENCY
,COALESCE(PCH.VCHARGE_CODE,'NI') AS CHARGE_CODE
,COALESCE(PCU.CURRENCY_CODE,'ARS') AS CURRENCY_CODE
FROM PLANES_MOBILE P
LEFT JOIN PBR_RATE PR ON PR.PRODUCT_KEY=P.INCLUIDOS 
LEFT JOIN PBR_FREQ PF ON PF.PRODUCT_KEY=P.INCLUIDOS 
LEFT JOIN PBR_CHARGE PCH ON PCH.PRODUCT_KEY=P.INCLUIDOS 
LEFT JOIN PBR_CURR PCU ON PCU.PRODUCT_KEY=P.INCLUIDOS 
) WITH DATA
PRIMARY INDEX (PRODUCT_KEY)
ON COMMIT PRESERVE ROWS;

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Esta es la query final que nos da la salida necesaria para el URM, con alugunos campos adicionales
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--create  table sbx_proc_cierre.urm_d_mobile_tariff_plan as (
select 
'722-07' as operator_id
,100*extract(year from current_date)+extract(month from current_date) as mobile_tariff_plan_dt
,p.product_key as tariff_plan_id
,p.product_desc as tariff_plan_des
,case when (case when nvl(pip.data_mb,0)=0 then case when nvl(pop.data_mb,0)=0 then p.data_mb else  pop.data_mb end else pip.data_mb end  )>0 then 1  else 0 end  as data_tariff_ind
,'4g' as mobile_tech_cd
,p.vigente as current_plan_ind
,nvl(round(cast(pbr.ammount_wo_taxes as decimal(12,3)),3),0) as price_plan_amt
,case when nvl(pip.data_mb,0)=0 then case when nvl(pop.data_mb,0)=0 then p.data_mb else  pop.data_mb end else pip.data_mb end  as data_bundled_qt
,0 as sdata_bundled_qt
,round((pip.voice_onnet_seg+pip.voice_offnet_seg)/60,0) as voice_bundled_qt
,pip.sms_und as sms_bundled_num
,0 as mms_bundled_num
,case when pip.voice_onnet_seg>0  then 1 else 0 end as voice_plan_ind
,0 as mbw_plan_ind
,0 as mm_plan_ind
,case when (case when nvl(pip.data_mb,0)=0 then case when nvl(pop.data_mb,0)=0 then p.data_mb else  pop.data_mb end else pip.data_mb end  )>0 then 1  else 0 end  as mb_plan_ind
,p.product_desc as mobile_service_commercial_name
,round(nvl(pbr.ammount_full,0),3)  as price_plan_full_amt
,nvl(round(pbr.ammount_full-pbr.ammount_wo_taxes,3),0)  as taxes_amt
,round(nvl(pip.voice_onnet_seg/60,0),0) as voice_bundled_onnet_qt 
,round(nvl(pip.voice_offnet_seg/60,0),0) as voice_bundled_offnet_qt  
,p.vigente as active
,pop.product_type
,pop.prepostpaid_id
,pop.amount
,pop.data_desc
,pop.voice_1ros_30_seg
,pop.voice_seg_excedente
,pop.sms_excedente
,p.fecha as update_date 
from planes_mobile p
inner join pop_parameters pop 	on pop.product_key=p.product_key
inner join pip_parameters pip 		on pip.product_key=p.product_key
inner join pbr_parameters pbr 	on pbr.product_key=p.product_key
where lower(p.catalog_type_desc)= 'offer'
order by  p.product_desc;
--) WITH DATA PRIMARY INDEX (mobile_tariff_plan_dt,tariff_plan_id);

