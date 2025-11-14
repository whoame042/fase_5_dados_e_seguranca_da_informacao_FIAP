package com.vehicleresale.api.dto;

import java.util.List;

public class PageDTO<T> {

    public List<T> content;
    public int pageNumber;
    public int pageSize;
    public long totalElements;
    public int totalPages;
    public boolean first;
    public boolean last;

    public PageDTO() {
    }

    public PageDTO(List<T> content, int pageNumber, int pageSize, long totalElements) {
        this.content = content;
        this.pageNumber = pageNumber;
        this.pageSize = pageSize;
        this.totalElements = totalElements;
        this.totalPages = (int) Math.ceil((double) totalElements / pageSize);
        this.first = pageNumber == 0;
        this.last = pageNumber >= (totalPages - 1);
    }
}

