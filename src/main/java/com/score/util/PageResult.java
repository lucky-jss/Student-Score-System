package com.score.util;

import java.util.List;

/**
 * 分页结果封装类。
 * 用于封装查询结果列表和分页信息，传递给 JSP 页面展示。
 *
 * @param <T> 列表元素类型
 */
public class PageResult<T> {

    /** 当前页数据列表 */
    private List<T> list;

    /** 总记录数 */
    private long totalRecords;

    /** 总页数 */
    private int totalPages;

    /** 当前页码（从1开始） */
    private int currentPage;

    /** 每页条数 */
    private int pageSize;

    public PageResult() {
    }

    public PageResult(List<T> list, long totalRecords, int totalPages, int currentPage, int pageSize) {
        this.list = list;
        this.totalRecords = totalRecords;
        this.totalPages = totalPages;
        this.currentPage = currentPage;
        this.pageSize = pageSize;
    }

    public List<T> getList() {
        return list;
    }

    public void setList(List<T> list) {
        this.list = list;
    }

    public long getTotalRecords() {
        return totalRecords;
    }

    public void setTotalRecords(long totalRecords) {
        this.totalRecords = totalRecords;
    }

    public int getTotalPages() {
        return totalPages;
    }

    public void setTotalPages(int totalPages) {
        this.totalPages = totalPages;
    }

    public int getCurrentPage() {
        return currentPage;
    }

    public void setCurrentPage(int currentPage) {
        this.currentPage = currentPage;
    }

    public int getPageSize() {
        return pageSize;
    }

    public void setPageSize(int pageSize) {
        this.pageSize = pageSize;
    }

    /**
     * 判断是否有上一页。
     */
    public boolean hasPrevious() {
        return currentPage > 1;
    }

    /**
     * 判断是否有下一页。
     */
    public boolean hasNext() {
        return currentPage < totalPages;
    }

    @Override
    public String toString() {
        return "PageResult{" +
                "listSize=" + (list != null ? list.size() : 0) +
                ", totalRecords=" + totalRecords +
                ", totalPages=" + totalPages +
                ", currentPage=" + currentPage +
                ", pageSize=" + pageSize +
                '}';
    }
}