package com.fenglin.springboottest.exception;

/**
 * 已认证但无权限：统一以 HTTP 403 + {message:"..."} 返回
 */
public class ForbiddenException extends RuntimeException {
    public ForbiddenException(String message) {
        super(message);
    }
}
