package com.wiley.model.mapper;

import com.wiley.model.ReconResult;
import org.springframework.jdbc.core.RowMapper;

import java.sql.ResultSet;
import java.sql.SQLException;
import static com.wiley.ApplicationConstants.SDF_YYYYMMDD;

/**
 * Created by ravuri on 5/15/17.
 */
public class ReconResultMapper implements RowMapper<ReconResult> {

    @Override
    public ReconResult mapRow(ResultSet rs, int i) throws SQLException {
        ReconResult result = new ReconResult();
        result.setId(rs.getInt(1));
        result.setWricef(rs.getString(2));
        result.setSource(rs.getString(3));
        result.setTarget(rs.getString(4));
        result.setStartDate(SDF_YYYYMMDD.format(rs.getDate(5)));
        result.setEndDate(SDF_YYYYMMDD.format(rs.getDate(6)));
        result.setServiceName(rs.getString(7));
        result.setInterfaceName(rs.getString(8));
        result.setSrcTotal(rs.getInt(9));
        result.setSrcSuccess(rs.getInt(10));
        result.setSrcFailure(rs.getInt(11));
        result.setEisTotal(rs.getInt(12));
        result.setEisSuccess(rs.getInt(13));
        result.setEisFailure(rs.getInt(14));
        result.setTgtTotal(rs.getInt(15));
        result.setTgtSuccess(rs.getInt(16));
        result.setTgtFailure(rs.getInt(17));
        result.setCurrency(rs.getString(18));
        result.setSrcCount(rs.getInt(19));
        result.setEisMissing(rs.getInt(21));
        result.setTgtMissing(rs.getInt(22));
       // result.setFlowDirection(rs.getString(18));

        return result;
    }
}