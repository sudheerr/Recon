package com.wiley.dao;

import com.wiley.model.UIColumn;
import com.wiley.model.UIRow;
import com.wiley.model.ReconDetailResponse;
import oracle.jdbc.OracleTypes;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.core.SqlOutParameter;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Service;

import java.sql.Date;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

import static com.wiley.ApplicationConstants.*;

/**
 * Created by ksrikanti on 5/30/17.
 */
@Service
public class FulfillmentDAO extends GenericDAO {

    private static final Logger LOGGER = LoggerFactory.getLogger(FulfillmentDAO.class);

    public ReconDetailResponse getFulfillmentDetails(Timestamp startDate, Timestamp endDate, final String errorSrc){

        LOGGER.info("parameters passed : startDate = [" + startDate + "], endDate = [" + endDate + "], errorSrc = [" + errorSrc + "]");

        final String temperrorSrc = errorSrc.equals("MW_MISS")?"SRC":errorSrc.equals("TGT_MISS")?"MW":errorSrc;


        SimpleJdbcCall simpleJdbcCall = new SimpleJdbcCall(getJdbcTemplate());
        simpleJdbcCall.withSchemaName(EISRECON).withCatalogName("RECON_FULFLMNT_PKG").withProcedureName("RECON_FULFLMNT_ERRORS");

        simpleJdbcCall.declareParameters(new SqlParameter(START_DATE, OracleTypes.TIMESTAMP));
        simpleJdbcCall.declareParameters(new SqlParameter(END_DATE, OracleTypes.TIMESTAMP));
        simpleJdbcCall.declareParameters(new SqlParameter(ERROR_CODE, OracleTypes.VARCHAR));

        simpleJdbcCall.declareParameters(new SqlOutParameter("c_results", OracleTypes.CURSOR, new RowMapper<UIRow>() {
            public UIRow mapRow(ResultSet rs, int i) throws SQLException {
                Date createDate = rs.getDate("SAP_CREATED_DATE");
                String createDateStr = createDate != null ? SDF.format(createDate) : "";

                return new UIRow(rs.getString("SRC_ORDNUM"),
                        rs.getString("SRC_STATUS"),
                        createDateStr,
                        rs.getString(temperrorSrc+"_STATUS_CODE"),
                        rs.getString(temperrorSrc+"_STATUS_MSG")
                );
            }
        }));



        MapSqlParameterSource in = new MapSqlParameterSource();
        in.addValue(START_DATE, startDate);
        in.addValue(END_DATE, endDate);
        in.addValue(ERROR_CODE, errorSrc);

        List<UIRow> rows = simpleJdbcCall.executeObject(List.class, in);

        List<UIColumn> columns = new ArrayList<>();
        columns.add(new UIColumn("Order Number","field1",""));
        columns.add(new UIColumn("Status","field2",""));
        columns.add(new UIColumn("Created Date","field3",""));
        columns.add(new UIColumn("Status Code","field4",""));
        columns.add(new UIColumn("Status Message","field5",""));

        // Needs changes below ***
        return  getUtilService().createResponse(columns, rows, SDF.format(startDate), SDF.format(endDate),
                        "UpdateProductMasterInbound", "JANIS", "SAP", "I0203.1");
    }

}