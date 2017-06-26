package com.wiley.dao;

import com.wiley.model.DynamicColumn;
import com.wiley.model.DynamicRow;
import com.wiley.model.ReconDetailResponse;
import com.wiley.service.UtilService;
import oracle.jdbc.OracleTypes;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
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
 * Created by sravuri on 5/30/17.
 */
@Service
public class ProductsDAO extends GenericDAO {

    private static final Logger LOGGER = LoggerFactory.getLogger(ProductsDAO.class);

    public ReconDetailResponse getProductDetails(Timestamp startDate, Timestamp endDate, String errorSrc){

        LOGGER.info("parameters passed : startDate = [" + startDate + "], endDate = [" + endDate + "], errorSrc = [" + errorSrc + "]");

        SimpleJdbcCall simpleJdbcCall = new SimpleJdbcCall(getJdbcTemplate());
        simpleJdbcCall.withSchemaName(EISRECON).withCatalogName("recon_product_pkg").withProcedureName("recon_product_errors");

        simpleJdbcCall.declareParameters(new SqlParameter(START_DATE, OracleTypes.TIMESTAMP));
        simpleJdbcCall.declareParameters(new SqlParameter(END_DATE, OracleTypes.TIMESTAMP));
        simpleJdbcCall.declareParameters(new SqlParameter(ERROR_CODE, OracleTypes.VARCHAR));

        simpleJdbcCall.declareParameters(new SqlOutParameter("c_results", OracleTypes.CURSOR, new RowMapper<DynamicRow>() {
            public DynamicRow mapRow(ResultSet rs, int i) throws SQLException {
                Date createDate = rs.getDate("CORE_CREATE_DATE");
                String createDateStr = createDate != null ? SDF.format(createDate) : "";

                return new DynamicRow(rs.getString("CORE_MATNUM"),
                        rs.getString("PRODUCT_TYPE"),
                        createDateStr,
                        rs.getString("STATUS_CODE"),
                        rs.getString("STATUS_MSG")
                );
            }
        }));



        MapSqlParameterSource in = new MapSqlParameterSource();
        in.addValue(START_DATE, startDate);
        in.addValue(END_DATE, endDate);
        in.addValue(ERROR_CODE, errorSrc);

        List<DynamicRow> rows = simpleJdbcCall.executeObject(List.class, in);

        List<DynamicColumn> columns = new ArrayList<>();
        columns.add(new DynamicColumn("Material Number","field1",""));
        columns.add(new DynamicColumn("Product Type","field2",""));
        columns.add(new DynamicColumn("Posted Date","field3",""));
        columns.add(new DynamicColumn("Error Code","field4",""));
        columns.add(new DynamicColumn("Error Message","field5",""));


        return  getUtilService().createResponse(columns, rows, SDF.format(startDate), SDF.format(endDate),
                        "UpdateProductMasterInbound", "JANIS", "SAP", "I0203.1");
    }

}