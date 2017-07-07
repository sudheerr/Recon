package com.wiley.model;

import com.fasterxml.jackson.annotation.JsonInclude;

/**
 * Created by sravuri on 5/26/17.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public class UIRow {

    /*
    Marking the fields public lets them serializable without getters.
    Marking the fields final, makes them unmodifiable after getting assigned.
    */
    public final String field1;
    public final String field2;
    public final String field3;
    public final String field4;
    public final String field5;
    public final String field6;
    public final String field7;

    /* This field particularly holds the currency type, if any for that row.
    This field can't be at column level, as the currency will be different for each record.
     */
    public final String currency;

    /*
    Having multiple constructor makes the invoking code cleaner(without passing nulls)
    * */
    public UIRow(String field1, String field2, String field3, String field4, String field5) {
        this(field1,field2,field3,field4,field5,null,null, null);
    }

    public UIRow(String field1, String field2, String field3, String field4, String field5, String field6) {
        this(field1,field2,field3,field4,field5,field6,null, null);
    }

    public UIRow(String field1, String field2, String field3, String field4, String field5, String field6, String field7, String currency) {
        this.field1 = field1;
        this.field2 = field2;
        this.field3 = field3;
        this.field4 = field4;
        this.field5 = field5;
        this.field6 = field6;
        this.field7 = field7;
        this.currency = currency;
    }

    @Override
    public String toString() {
        return "UIRow{" +
                "field1='" + field1 + '\'' +
                ", field2='" + field2 + '\'' +
                ", field3='" + field3 + '\'' +
                ", field4='" + field4 + '\'' +
                ", field5='" + field5 + '\'' +
                ", field6='" + field6 + '\'' +
                ", field7='" + field7 + '\'' +
                '}';
    }
}
