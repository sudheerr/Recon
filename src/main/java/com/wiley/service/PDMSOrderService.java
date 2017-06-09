package com.wiley.service;

import com.wiley.DynamicRow;
import com.wiley.ReconDetailResponse;
import oracle.jdbc.OracleTypes;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
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

import static com.wiley.ApplicationConstants.SDF;

/**
 * Created by sravuri on 6/8/2017.
 */
@Service
public class PDMSOrderService {
    private UtilService utilService;
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private PDMSOrderService(JdbcTemplate jdbcTemplate, UtilService utilService) {
        this.jdbcTemplate = jdbcTemplate;
        this.utilService = utilService;
    }

    public ReconDetailResponse getOrderDetails(Timestamp startDate, Timestamp endDate, String errorSrc){

        SimpleJdbcCall simpleJdbcCall = new SimpleJdbcCall(jdbcTemplate);
        simpleJdbcCall.withSchemaName("eisadmin").withCatalogName("recon_pdms_order_pkg").withProcedureName("recon_pdms_order_errors");

        simpleJdbcCall.declareParameters(new SqlParameter("startDate", OracleTypes.TIMESTAMP));
        simpleJdbcCall.declareParameters(new SqlParameter("endDate", OracleTypes.TIMESTAMP));
        simpleJdbcCall.declareParameters(new SqlParameter("errcode", OracleTypes.VARCHAR));

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
        in.addValue("startDate", startDate);
        in.addValue("endDate", endDate);
        in.addValue("errcode", errorSrc);

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