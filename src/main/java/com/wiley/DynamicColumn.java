package com.wiley;

/**
 * Created by ravuri on 5/26/17.
 */
public class DynamicColumn {
    private String title;
    private String data;
    private String defaultContent;

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

    public String getTitle() {
        return title;
    }
    public void setTitle(String title) {
        this.title = title;
    }
    public String getDefaultContent() {
        return defaultContent;
    }
    public void setDefaultContent(String defaultContent) {
        this.defaultContent = defaultContent;
    }
    public String getData() {
        return data;
    }
    public void setData(String data) {
        this.data = data;
    }
}
