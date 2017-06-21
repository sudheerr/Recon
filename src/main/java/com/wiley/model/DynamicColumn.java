package com.wiley.model;

import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Created by sravuri on 5/26/17.
 */
public class DynamicColumn {
    public final String title;
    public final String data;
    public final String defaultContent ="";

    @JsonProperty("class")
    public final String className;
    public String format;

    public DynamicColumn(String title, String data, String className) {
        this.title = title;
        this.data = data;
        this.className = className;
    }

    public DynamicColumn(String title, String data, String className, String format) {
        this(title, data, className);
        this.format= format;
    }

    @Override
    public String toString() {
        return "DynamicColumn{" +
                "title='" + title + '\'' +
                ", data='" + data + '\'' +
                ", className='" + className + '\'' +
                ", format='" + format + '\'' +
                '}';
    }
}