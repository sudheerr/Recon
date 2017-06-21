package com.wiley;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.List;

/**
 * Created by sravuri on 5/30/17.
 */
public class ApplicationConstants {

    private ApplicationConstants(){}

    public static final SimpleDateFormat SDF = new SimpleDateFormat("yyyy-MM-dd");

    public static final SimpleDateFormat SDF_YYYYMMDD = new SimpleDateFormat("yyyyMMdd");

    public static final List<String> ORDER_WRICEFS = new ArrayList<String>(){{
        add("I0230.6");
        add("I0230.7");
        add("I0230.8");
        add("I0343");
    }};

    public static final String USER_DTO ="USER_DTO";

    public static final String EISADMIN = "eisadmin";
    public static final String START_DATE = "startDate";
    public static final String END_DATE = "endDate";
    public static final String ERROR_CODE = "errcode";
}
