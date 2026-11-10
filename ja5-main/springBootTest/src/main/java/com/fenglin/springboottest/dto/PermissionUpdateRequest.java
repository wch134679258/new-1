package com.fenglin.springboottest.dto;

/**
 * 后台修改用户权限请求：0=管理员，1=默认用户。
 */
public class PermissionUpdateRequest {

    private Integer permission;

    public Integer getPermission() {
        return permission;
    }

    public void setPermission(Integer permission) {
        this.permission = permission;
    }
}
