package com.wiley.service;

import com.wiley.model.DynamicColumn;
import com.wiley.model.DynamicRow;
import com.wiley.model.ReconDetailResponse;
import org.springframework.stereotype.Service;

import java.sql.Timestamp;
import java.text.ParseException;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;

import static com.wiley.ApplicationConstants.SDF;
import static com.wiley.ApplicationConstants.SDF_YYYYMMDD;

/**
 * Created by sravuri on 6/7/17.
 */
@Service
public class UtilService {
    public ReconDetailResponse createResponse(List<String> columns, List<DynamicRow> rows,
                                              String startDate, String endDate, String interfaceName,
                                              String source, String target, String wricef){

        List<DynamicColumn> dynCols = new ArrayList<>();
        for(int i=0; i<columns.size();i++){
            dynCols.add(new DynamicColumn(columns.get(i),"field"+(i+1)));
        }

        ReconDetailResponse response = new ReconDetailResponse();
        response.setColumns(dynCols);
        response.setData(rows);
        response.setStartDate(startDate);
        response.setEndDate(endDate);
        response.setInterfaceName(interfaceName);
        response.setSource(source);
        response.setTarget(target);
        response.setWricef(wricef);

        return  response;
    }

    public Timestamp getEndofDay(String date) throws ParseException{
        //Fetching records till end of day.
        Calendar cal = Calendar.getInstance();
        cal.setTime(SDF_YYYYMMDD.parse(date));

        cal.set(Calendar.HOUR_OF_DAY, cal.getMaximum(Calendar.HOUR_OF_DAY));
        cal.set(Calendar.MINUTE, cal.getMaximum(Calendar.MINUTE));
        cal.set(Calendar.SECOND, cal.getMaximum(Calendar.SECOND));
        cal.set(Calendar.MILLISECOND, cal.getMaximum(Calendar.MILLISECOND));

        return new Timestamp(cal.getTimeInMillis());
    }

    public Timestamp getStartofDay(String date) throws ParseException{
        return  new Timestamp(SDF_YYYYMMDD.parse(date).getTime());
    }
}
