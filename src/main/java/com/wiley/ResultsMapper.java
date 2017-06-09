package com.wiley;

import org.springframework.jdbc.core.RowMapper;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.text.SimpleDateFormat;

/**
 * Created by ravuri on 5/15/17.
 */
public class ResultsMapper implements RowMapper {

    SimpleDateFormat simpleDateFormat = new SimpleDateFormat("yyyyMMdd");

    @Override
    public Object mapRow(ResultSet rs, int i) throws SQLException {
        ReconResult result = new ReconResult();
        result.setId(rs.getInt(1));
        result.setWricef(rs.getString(2));
        result.setSource(rs.getString(3));
        result.setTarget(rs.getString(4));
        result.setStartDate(simpleDateFormat.format(rs.getDate(5)));
        result.setEndDate(simpleDateFormat.format(rs.getDate(6)));
        result.setServiceName(rs.getString(7));
        result.setInterfaceName(rs.getString(8));
        result.setSrcTotal(rs.getInt(9));
        result.setSrcSuccess(rs.getInt(10));
        result.setSrcFailure(rs.getInt(11));
        result.setEisTotal(rs.getInt(12));
        result.setEisSuccess(rs.getInt(13));
        result.setEisFailure(rs.getInt(14));
        result.setSapTotal(rs.getInt(15));
        result.setSapSuccess(rs.getInt(16));
        result.setSapFailure(rs.getInt(17));
        result.setFlowDirection(rs.getString(18));

        return result;
    }
}