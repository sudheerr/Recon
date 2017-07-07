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
        add("I0212.17");
        add("I0230.6");
        add("I0230.7");
        add("I0230.8");
        add("I0343");
    }};

    public static final String EISRECON = "eisrecon";
    public static final String START_DATE = "startDate";
    public static final String END_DATE = "endDate";
    public static final String ERROR_CODE = "errcode";

    public static final String USER_MAIL="user_mail";
    public static final String USER_DTO="USER_DTO";
    //public static final String WEB_PROPS = "WEB_PROPS";
    //public static final String GLOBAL_CONFIG_VO="GLOBAL_CONFIG_VO";
    //public static final String USER_DN="user_dn";
}
