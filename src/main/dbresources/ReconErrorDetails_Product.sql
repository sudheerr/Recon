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
        filterCondn:= ' WHERE STATUS_FOUND=''FoundInSAP'' and STATUS !=''SUCCESS''';
    ELSIF errcode = 'EIS' THEN
        filterCondn:= ' WHERE STATUS_FOUND=''MissingInSAP'' and SAP_EIS_MATNUM is not null';
    ELSIF errcode = 'SRC' THEN
        filterCondn:= ' WHERE STATUS_FOUND=''MissingInSAP'' and SAP_EIS_MATNUM is null';
    ELSE
        filterCondn:= ' WHERE 1!=1';
    END IF;

    OPEN c_results  FOR 'SELECT STATUS_FOUND, CORE_MATNUM, SAP_EIS_MATNUM, CORE_CREATE_DATE, PRODUCT_TYPE, EVENT, SENT_TO_TIBCO, STATUS, STATUS_CODE, STATUS_MSG FROM (
     SELECT ''FoundInSAP'' as STATUS_FOUND, CORE_PRODUCT.SAP_MATERIAL_NUMBER AS CORE_MATNUM, SAP_PRODUCT.SAP_MATERIAL_NUMBER AS SAP_EIS_MATNUM,
     CORE_PRODUCT.CORE_CREATE_DATE, CORE_PRODUCT.PRODUCT_TYPE, CORE_PRODUCT.EVENT,
     CORE_PRODUCT.SENT_TO_TIBCO, SAP_PRODUCT.STATUS, SAP_PRODUCT.STATUS_CODE,  SAP_PRODUCT.STATUS_MSG FROM (
     SELECT * FROM ( SELECT RECON_CORE_PRODUCT_TXN.*, RANK() OVER(PARTITION BY SAP_MATERIAL_NUMBER ORDER BY ID DESC ) AS RANK1
     FROM RECON_CORE_PRODUCT_TXN WHERE CORE_CREATE_DATE >= '''||startDate||''' and CORE_CREATE_DATE <= '''||endDate||''') WHERE   RANK1 =1) CORE_PRODUCT
     JOIN (
     SELECT * FROM (SELECT RECON_SAP_PRODUCT_TXN.*,  RANK() OVER(PARTITION BY SAP_MATERIAL_NUMBER ORDER BY ID DESC ) AS RANK2
     FROM RECON_SAP_PRODUCT_TXN WHERE SAP_CREATED_DATE >= '''||startDate||''' and SAP_CREATED_DATE <= '''||endDate||'''  ) WHERE RANK2=1) SAP_PRODUCT
     ON CORE_PRODUCT.SAP_MATERIAL_NUMBER = SAP_PRODUCT.SAP_MATERIAL_NUMBER
     UNION
     SELECT ''MissingInSAP'' as STATUS_FOUND, CORE_SAP_FINAL.CORE_MATNUM, EIS_PRODUCT.SAP_MATERIAL_NUMBER,
     CORE_SAP_FINAL.CORE_CREATE_DATE, CORE_SAP_FINAL.PRODUCT_TYPE, CORE_SAP_FINAL.EVENT,
     CORE_SAP_FINAL.SENT_TO_TIBCO, EIS_PRODUCT.STATUS,  EIS_PRODUCT.STATUS_CODE,  EIS_PRODUCT.STATUS_MSG FROM (
     SELECT CORE_MATNUM, CORE_CREATE_DATE, PRODUCT_TYPE, EVENT, SENT_TO_TIBCO FROM (
     SELECT CORE_PRODUCT.SAP_MATERIAL_NUMBER AS CORE_MATNUM, SAP_PRODUCT.SAP_MATERIAL_NUMBER AS SAP_EIS_MATNUM,
     CORE_PRODUCT.CORE_CREATE_DATE, CORE_PRODUCT.PRODUCT_TYPE, CORE_PRODUCT.EVENT,
     CORE_PRODUCT.SENT_TO_TIBCO, SAP_PRODUCT.STATUS_CODE,  SAP_PRODUCT.STATUS_MSG FROM (
     SELECT * FROM ( SELECT RECON_CORE_PRODUCT_TXN.*, RANK() OVER(PARTITION BY SAP_MATERIAL_NUMBER ORDER BY ID DESC ) AS RANK1
     FROM RECON_CORE_PRODUCT_TXN WHERE CORE_CREATE_DATE >= '''||startDate||''' and CORE_CREATE_DATE <= '''||endDate||''') WHERE   RANK1 =1) CORE_PRODUCT
     LEFT OUTER JOIN (
     SELECT * FROM (SELECT RECON_SAP_PRODUCT_TXN.*,  RANK() OVER(PARTITION BY SAP_MATERIAL_NUMBER ORDER BY ID DESC ) AS RANK2
     FROM RECON_SAP_PRODUCT_TXN WHERE SAP_CREATED_DATE >= '''||startDate||''' and SAP_CREATED_DATE <= '''||endDate||'''  ) WHERE RANK2=1) SAP_PRODUCT
     ON CORE_PRODUCT.SAP_MATERIAL_NUMBER = SAP_PRODUCT.SAP_MATERIAL_NUMBER) CORE_SAP  WHERE CORE_SAP.SAP_EIS_MATNUM is null) CORE_SAP_FINAL
     LEFT OUTER JOIN (
     SELECT * FROM (SELECT RECON_EIS_PRODUCT_TXN.*, RANK() OVER(PARTITION BY SAP_MATERIAL_NUMBER ORDER BY ID DESC ) AS RANK3
             FROM RECON_EIS_PRODUCT_TXN WHERE TIBCO_CREATE_DATE >= '''||startDate||''' and TIBCO_CREATE_DATE <= '''||endDate||''') WHERE RANK3=1
     ) EIS_PRODUCT ON EIS_PRODUCT.SAP_MATERIAL_NUMBER = CORE_SAP_FINAL.CORE_MATNUM )' || filterCondn;
    END recon_product_errors;
END recon_product_pkg;

--var results refcursor;
--exec recon_product_pkg.recon_product_errors( TO_TIMESTAMP ('2017/06/19 00:00:00', 'YYYY/MM/DD HH24:MI:SS'), TO_TIMESTAMP ('2017/06/25 23:59:59', 'YYYY/MM/DD HH24:MI:SS'), 'EIS', :results)
--print results