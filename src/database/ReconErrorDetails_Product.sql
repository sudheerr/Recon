CREATE OR REPLACE PACKAGE recon_product_pkg  AS 
  PROCEDURE recon_product_errors (
  startDate IN  Timestamp,
  endDate IN Timestamp,
  errcode IN Varchar2,
  c_results OUT SYS_REFCURSOR
  ); 
END recon_product_pkg;

CREATE OR REPLACE PACKAGE BODY recon_product_pkg AS
  PROCEDURE recon_product_errors (
      startDate IN  Timestamp,
      endDate IN Timestamp,
      errcode IN Varchar2,
      c_results OUT SYS_REFCURSOR
      )
  AS
    log varchar2(1000);
    user_name varchar2(20);
    filterCondn varchar2(100);

    BEGIN

    user_name := 'Admin';
    log := 'Begin Product Fetch errors ' || startDate || ' ' || endDate || ' ' || errcode;
    INSERT INTO svc_logs( APPLICATION,LOG_LEVEL, LOG_LINE, log_text, create_user, create_date) VALUES ('recon_product_errors', 'INFO', '1.1', log, user_name, sysdate);

    IF errcode = 'SAP' THEN
          filterCondn:= ' WHERE STATUS=''FoundInSAP'' and STATUS_CODE !=53';
    ELSIF errcode = 'EIS' THEN
        filterCondn:= ' WHERE STATUS=''MissingInSAP'' and SAP_EIS_MATNUM is not null';
    ELSIF errcode = 'SRC' THEN
        filterCondn:= ' WHERE STATUS=''MissingInSAP'' and SAP_EIS_MATNUM is null';
    ELSE
        filterCondn:= ' WHERE 1!=1';
    END IF;

    OPEN c_results  FOR 'SELECT STATUS, CORE_MATNUM, SAP_EIS_MATNUM, EVENT, STATUS_CODE, STATUS_MSG, CORE_CREATE_DATE, PRODUCT_TYPE, EIS_ERROR_CODE FROM(
    SELECT ''FoundInSAP'' as STATUS, CORE_PRODUCT.SAP_MATERIAL_NUMBER AS CORE_MATNUM, SAP_PRODUCT.SAP_MATERIAL_NUMBER AS SAP_EIS_MATNUM, CORE_PRODUCT.EVENT
    AS EVENT, SAP_PRODUCT.STATUS_CODE AS STATUS_CODE, SAP_PRODUCT.STATUS_MSG AS STATUS_MSG, CORE_PRODUCT.SENT_TO_TIBCO, CORE_CREATE_DATE, PRODUCT_TYPE, null as EIS_ERROR_CODE FROM (
    SELECT * FROM (SELECT  ID, SAP_MATERIAL_NUMBER, EVENT, CORE_DATE_LOAD, ERROR_CODE, SENT_TO_TIBCO, CORE_CREATE_DATE,PRODUCT_TYPE,
        RANK() OVER(PARTITION BY SAP_MATERIAL_NUMBER ORDER BY ID DESC ) AS RANK2
    FROM RECON_CORE_PRODUCT_TXN WHERE CORE_CREATE_DATE >= '''||startDate||''' and CORE_CREATE_DATE <= '''||endDate||''') WHERE  RANK2 =1) CORE_PRODUCT
    JOIN (
    SELECT * FROM (SELECT ID, SAP_MATERIAL_NUMBER, EVENT, STATUS_CODE, STATUS_MSG, SAP_CREATE_DATE,
    RANK() OVER(PARTITION BY SAP_MATERIAL_NUMBER ORDER BY ID DESC ) AS RANK3 FROM RECON_SAP_PRODUCT_TXN
    WHERE SAP_CREATE_DATE >= '''||startDate||''' and SAP_CREATE_DATE <= '''||endDate||'''  ) WHERE RANK3=1) SAP_PRODUCT
    ON CORE_PRODUCT.SAP_MATERIAL_NUMBER = SAP_PRODUCT.SAP_MATERIAL_NUMBER
    UNION
    SELECT ''MissingInSAP'' as STATUS, CORE_SAP_FINAL.SAP_MATERIAL_NUMBER AS CORE_MATNUM, EIS_PRODUCT.SAP_MATERIAL_NUMBER AS SAP_EIS_MATNUM,CORE_SAP_FINAL.EVENT,
    CORE_SAP_FINAL.STATUS_CODE, EIS_PRODUCT.ERROR_DESCRIPTION, CORE_SAP_FINAL.SENT_TO_TIBCO, CORE_CREATE_DATE, PRODUCT_TYPE,  EIS_PRODUCT.ERROR_CODE FROM (
    SELECT * FROM (
    SELECT CORE_PRODUCT.SAP_MATERIAL_NUMBER,SAP_PRODUCT.SAP_MATERIAL_NUMBER AS SAP_MAT_NUM, CORE_PRODUCT.EVENT, SAP_PRODUCT.STATUS_CODE, CORE_PRODUCT.SENT_TO_TIBCO, CORE_CREATE_DATE, PRODUCT_TYPE FROM (
    SELECT * FROM (SELECT  ID, SAP_MATERIAL_NUMBER, EVENT, CORE_DATE_LOAD, ERROR_CODE, SENT_TO_TIBCO, CORE_CREATE_DATE, PRODUCT_TYPE,
        RANK() OVER(PARTITION BY SAP_MATERIAL_NUMBER ORDER BY ID DESC ) AS RANK2
    FROM RECON_CORE_PRODUCT_TXN WHERE CORE_CREATE_DATE >=  '''||startDate||''' and CORE_CREATE_DATE <=  '''||endDate||''') WHERE  RANK2 =1) CORE_PRODUCT
    LEFT OUTER JOIN (
    SELECT * FROM (SELECT ID, SAP_MATERIAL_NUMBER, EVENT, STATUS_CODE,
    RANK() OVER(PARTITION BY SAP_MATERIAL_NUMBER ORDER BY ID DESC ) AS RANK3 FROM RECON_SAP_PRODUCT_TXN
    WHERE SAP_CREATE_DATE >= '''||startDate||''' and SAP_CREATE_DATE <=  '''||endDate||''') WHERE RANK3=1) SAP_PRODUCT
    ON CORE_PRODUCT.SAP_MATERIAL_NUMBER = SAP_PRODUCT.SAP_MATERIAL_NUMBER) CORE_SAP WHERE CORE_SAP.SAP_MAT_NUM is null) CORE_SAP_FINAL
    LEFT OUTER JOIN (
    SELECT * FROM (SELECT ID, SAP_MATERIAL_NUMBER, EVENT, ERROR_CODE, ERROR_DESCRIPTION,
    RANK() OVER(PARTITION BY SAP_MATERIAL_NUMBER ORDER BY ID DESC ) AS RANK3 FROM RECON_EIS_PRODUCT_TXN
    WHERE TIBCO_CREATE_DATE >= '''||startDate||''' and TIBCO_CREATE_DATE <=  '''||endDate||''') WHERE RANK3=1) EIS_PRODUCT
    ON EIS_PRODUCT.SAP_MATERIAL_NUMBER = CORE_SAP_FINAL.SAP_MATERIAL_NUMBER)' || filterCondn;
    END recon_product_errors;
END recon_product_pkg;

--select * from svc_logs order by log_id desc;
--var results refcursor;
--exec recon_product_pkg.recon_product_errors( TO_TIMESTAMP ('2017/05/19 00:00:00', 'YYYY/MM/DD HH24:MI:SS'), TO_TIMESTAMP ('2017/05/22 23:59:59', 'YYYY/MM/DD HH24:MI:SS'), 'EIS', :results)
--print results