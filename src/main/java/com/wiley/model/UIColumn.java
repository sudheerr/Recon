package com.wiley.model;

import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Created by sravuri on 5/26/17.
 */
public class UIColumn {
    public final String colTitle;
    public final String data;
    public final String defaultContent ="";

    @JsonProperty("class")
    public final String className;
    public ColumnType columnType;

    public UIColumn(String colTitle, String data, String className) {
        this.colTitle = colTitle;
        this.data = data;
        this.className = className;
    }

    public UIColumn(String title, String data, String className, ColumnType columnType) {
        this(title, data, className);
        this.columnType= columnType;
    }

    @Override
    public String toString() {
        return "UIColumn{" +
                "title='" + colTitle + '\'' +
                ", data='" + data + '\'' +
                ", className='" + className + '\'' +
                ", columnType='" + columnType + '\'' +
                '}';
    }
}