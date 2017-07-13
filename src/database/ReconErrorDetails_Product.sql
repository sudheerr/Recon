create or replace PACKAGE recon_product_pkg  AS
  PROCEDURE recon_product_errors (
  startDate IN  Timestamp,
  endDate IN Timestamp,
  errcode IN Varchar2,
  c_results OUT SYS_REFCURSOR
  ); 
END recon_product_pkg;


create or replace PACKAGE BODY recon_product_pkg AS
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

  IF errcode = 'SRC' THEN
      filterCondn:= ' WHERE SRC_STATUS !=''SUCCESS''';
  ELSIF errcode = 'MW' THEN
      filterCondn:= ' WHERE MW_MATNUM is not null and MW_STATUS !=''SUCCESS''';
  ELSIF errcode = 'TGT' THEN
      filterCondn:= ' WHERE TGT_MATNUM is not null and TGT_STATUS !=''SUCCESS''';
  ELSIF errcode = 'MW_MISS' THEN
      filterCondn:= ' WHERE SRC_STATUS = ''SUCCESS'' and MW_MATNUM is null';
  ELSIF errcode = 'TGT_MISS' THEN
      filterCondn:= ' WHERE MW_MATNUM is not null and TGT_MATNUM is NULL and MW_STATUS = ''SUCCESS''';
  ELSE
      filterCondn:= ' WHERE 1!=1';
  END IF;

  OPEN c_results  FOR 'SELECT * FROM (
      SELECT * FROM (
      SELECT * FROM (SELECT SAP_MATERIAL_NUMBER AS SRC_MATNUM, EVENT, PRODUCT_TYPE, CORE_DATE_LOAD, CORE_CREATED_DATE,
      STATUS AS SRC_STATUS, STATUS_CODE AS SRC_STATUS_CODE, STATUS_MSG AS SRC_STATUS_MSG,
      RANK() OVER(PARTITION BY SAP_MATERIAL_NUMBER ORDER BY CREATED_TS DESC, CORE_CREATED_DATE DESC ) AS RANK1 FROM RECON_CORE_PRODUCT_TXN
      WHERE CORE_CREATED_DATE >=  '''||startDate||''' and CORE_CREATED_DATE <= '''||endDate||''') WHERE  RANK1 =1) CORE_PRODUCT
      LEFT OUTER JOIN (
      SELECT * FROM (SELECT SAP_MATERIAL_NUMBER AS MW_MATNUM, STATUS AS MW_STATUS, STATUS_MSG AS MW_STATUS_MSG, STATUS_CODE AS MW_STATUS_CODE,
      RANK() OVER(PARTITION BY SAP_MATERIAL_NUMBER ORDER BY CREATED_TS DESC, TIBCO_CREATED_DATE DESC ) AS RANK2 FROM RECON_EIS_PRODUCT_TXN
      WHERE TIBCO_CREATED_DATE >= '''||startDate||''' and TIBCO_CREATED_DATE <= '''||endDate||''') WHERE RANK2=1) EIS_PRODUCT
      ON EIS_PRODUCT.MW_MATNUM = CORE_PRODUCT.SRC_MATNUM) CORE_EIS
      LEFT OUTER JOIN (
      SELECT * FROM (SELECT SAP_MATERIAL_NUMBER AS TGT_MATNUM, STATUS AS TGT_STATUS, STATUS_MSG AS TGT_STATUS_MSG, STATUS_CODE AS TGT_STATUS_CODE,
      RANK() OVER(PARTITION BY SAP_MATERIAL_NUMBER ORDER BY CREATED_TS DESC, SAP_CREATED_DATE DESC ) AS RANK3 FROM RECON_SAP_PRODUCT_TXN
      WHERE SAP_CREATED_DATE >= '''||startDate||''' and SAP_CREATED_DATE <= '''||endDate||''') WHERE RANK3=1) SAP_PRODUCT
      ON CORE_EIS.SRC_MATNUM = SAP_PRODUCT.TGT_MATNUM' || filterCondn;
  END recon_product_errors;
END recon_product_pkg;