package com.fenglin.springboottest.dto;

/**
 * 后台分类新增 / 编辑请求。
 */
public class AdminCategoryRequest {

    private String name;
    private String slug;
    private Integer sort;

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getSlug() {
        return slug;
    }

    public void setSlug(String slug) {
        this.slug = slug;
    }

    public Integer getSort() {
        return sort;
    }

    public void setSort(Integer sort) {
        this.sort = sort;
    }
}
