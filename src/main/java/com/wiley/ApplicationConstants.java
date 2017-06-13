package com.wiley;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.List;

/**
 * Created by sravuri on 5/30/17.
 */
public interface ApplicationConstants {

    SimpleDateFormat SDF = new SimpleDateFormat("yyyy-MM-dd");

    SimpleDateFormat SDF_YYYYMMDD = new SimpleDateFormat("yyyyMMdd");

    List<String> ORDER_WRICEFS = new ArrayList<String>(){{
        add("I0230.6");
        add("I0230.7");
        add("I0230.8");
    }};

    String USER_DTO ="USER_DTO";

    String EISADMIN = "eisadmin";
    String START_DATE = "startDate";
    String END_DATE = "endDate";
    String ERROR_CODE = "errcode";
}
