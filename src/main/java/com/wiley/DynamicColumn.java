package com.wiley;

/**
 * Created by sravuri on 5/26/17.
 */
public class DynamicColumn {
    public final String title;
    public final String data;
    public final String defaultContent;

    public DynamicColumn(String title, String data) {
        this.title = title;
        this.data = data;
        this.defaultContent="";
    }

    @Override
    public String toString() {
        return "DynamicColumn{" +
                "title='" + title + '\'' +
                ", data='" + data + '\'' +
                '}';
    }
}
