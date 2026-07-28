package com.izonescraper.sunwayizonescraper.Scrape;

import lombok.Data;

import java.util.List;

@Data
public class TableHeader {
    String Header;
    List<TableData> tableDataList;


//public TableHeader() {
//    }
//    public TableHeader(String header, List<TableData> tableData) {
//        this.tableDataList = tableData;
//        Header = header;
//    }
//
//    public String getHeader() {
//        return Header;
//    }
//
//    public void setHeader(String header) {
//        Header = header;
//    }
//
//    public List<TableData> getTd() {
//        return tableDataList;
//    }
//
//    public void setTableDataList(List<TableData> tableData) {
//        this.tableDataList = tableData;
//    }
//
//
//    @Override
//    public String toString() {
//        return "TableRow {" +
//                "Header(Date)='" + Header + '\'' +
//                ", tableDataList=" + tableDataList +
//                '}';
//    }
}
