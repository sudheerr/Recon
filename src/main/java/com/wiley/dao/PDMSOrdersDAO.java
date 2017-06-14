package com.wiley.dao;

import com.wiley.model.DynamicRow;
import com.wiley.model.ReconDetailResponse;
import com.wiley.service.UtilService;
import oracle.jdbc.OracleTypes;
import org.springframework.beans.factory.annotation.Autowired;
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
 * Created by sravuri on 6/8/2017.
 */
@Service
public class PDMSOrdersDAO extends GenericDAO{
    private final UtilService utilService;

    @Autowired
    private PDMSOrdersDAO(UtilService utilService) {
        this.utilService = utilService;
    }

    public ReconDetailResponse getOrderDetails(Timestamp startDate, Timestamp endDate, String errorSrc){

        SimpleJdbcCall simpleJdbcCall = new SimpleJdbcCall(getJdbcTemplate());
        simpleJdbcCall.withSchemaName(EISADMIN).withCatalogName("recon_pdms_order_pkg").withProcedureName("recon_pdms_order_errors");

        simpleJdbcCall.declareParameters(new SqlParameter(START_DATE, OracleTypes.TIMESTAMP));
        simpleJdbcCall.declareParameters(new SqlParameter(END_DATE, OracleTypes.TIMESTAMP));
        simpleJdbcCall.declareParameters(new SqlParameter(ERROR_CODE, OracleTypes.VARCHAR));

        simpleJdbcCall.declareParameters(new SqlOutParameter("c_results", OracleTypes.CURSOR, new RowMapper<DynamicRow>() {
            public DynamicRow mapRow(ResultSet rs, int i) throws SQLException {
                    Date createDate = rs.getDate("CORE_REQUEST_DATE");
                String createDate_S = createDate != null ? SDF.format(createDate) : "";

                return new DynamicRow(rs.getString("SUB_ORD_REF_NUM"),
                        createDate_S,
                        rs.getString("ORDER_PRICE"),
                        rs.getString("STATUS_CODE"),
                        rs.getString("STATUS_MSG"),
                        null,
                        null
                );
            }
        }));

        MapSqlParameterSource in = new MapSqlParameterSource();
        in.addValue(START_DATE, startDate);
        in.addValue(END_DATE, endDate);
        in.addValue(ERROR_CODE, errorSrc);

        List<DynamicRow> rows = simpleJdbcCall.executeObject(List.class, in);
        List<String> columns = new ArrayList<>();

        columns.add("Sub Order Ref Number");
        //columns.add("Purchase Order Date");
        columns.add("Posted Date");
        columns.add("Total Order Price");
        columns.add("Error Code");
        columns.add("Error Message");

        return utilService.createResponse(columns, rows, SDF.format(startDate),
                SDF.format(endDate), "UpdateOrderFromPDMicroSites",
                "PD Microsites, CWS sites, Springboard sites, dotCMS", "SAP", "I0343");
    }
}