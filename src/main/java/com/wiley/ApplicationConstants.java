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
    }};
}
