package com.wiley.model;

import com.fasterxml.jackson.annotation.JsonInclude;

/**
 * Created by sravuri on 5/26/17.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public class DynamicRow {

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

    /*
    Having multiple constructor makes the invoking code cleaner(without passing nulls)
    * */
    public DynamicRow(String field1, String field2, String field3, String field4, String field5) {
        this(field1,field2,field3,field4,field5,null,null);
    }

    public DynamicRow(String field1, String field2, String field3, String field4, String field5, String field6) {
        this(field1,field2,field3,field4,field5,field6,null);
    }

    public DynamicRow(String field1, String field2, String field3, String field4, String field5, String field6, String field7) {
        this.field1 = field1;
        this.field2 = field2;
        this.field3 = field3;
        this.field4 = field4;
        this.field5 = field5;
        this.field6 = field6;
        this.field7 = field7;
    }

    @Override
    public String toString() {
        return "DynamicRow{" +
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
