package com.fenglin.springboottest.exception;

import org.springframework.dao.DuplicateKeyException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.NoHandlerFoundException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import jakarta.validation.ConstraintViolationException;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 全局异常处理：把异常转成前端约定的 {@code {message:"..."}} 结构。
 *
 * <p>为什么需要这个类兜底：前端 {@code src/api/http.js} 拿到非 2xx 响应后，
 * 会去解析响应体里的 {@code message} 字段；没解析到就用默认文案
 * “请求失败，请稍后再试”。所以任何没被捕获的异常都会让用户看到一句没有信息量的糊话。</p>
 *
 * <p>原则：</p>
 * <ul>
 *   <li>业务异常（BusinessException）→ 400，message 直接给用户看</li>
 *   <li>参数 / 请求体问题 → 400，message 说明是哪个参数错了</li>
 *   <li>未捕获异常 → 500，只回一句“服务器内部错误”，堆栈只进日志，不泄露给客户端</li>
 * </ul>
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    /** 业务异常：400，文案本来就是给用户看的 */
    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<Map<String, String>> handleBusiness(BusinessException e) {
        return respond(HttpStatus.BAD_REQUEST, e.getMessage());
    }

    /** 未登录 / 令牌无效：401，前端据此清 token 并跳登录 */
    @ExceptionHandler(UnauthorizedException.class)
    public ResponseEntity<Map<String, String>> handleUnauthorized(UnauthorizedException e) {
        return respond(HttpStatus.UNAUTHORIZED, e.getMessage());
    }

    /** 已登录但没有管理员权限：403 */
    @ExceptionHandler(ForbiddenException.class)
    public ResponseEntity<Map<String, String>> handleForbidden(ForbiddenException e) {
        return respond(HttpStatus.FORBIDDEN, e.getMessage());
    }

    /** 请求体不是合法 JSON（比如前端传了字符串、或字段类型不匹配） */
    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<Map<String, String>> handleNotReadable(HttpMessageNotReadableException e) {
        return respond(HttpStatus.BAD_REQUEST, "请求体格式不正确，请检查后重试");
    }

    /** @Valid 校验失败：取第一个字段错误信息返回 */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, String>> handleValid(MethodArgumentNotValidException e) {
        String msg = e.getBindingResult().getFieldErrors().stream()
                .findFirst()
                .map(fe -> fe.getField() + " " + fe.getDefaultMessage())
                .orElse("请求参数校验失败");
        return respond(HttpStatus.BAD_REQUEST, msg);
    }

    /** @Validated 方法级校验失败 */
    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<Map<String, String>> handleConstraint(ConstraintViolationException e) {
        String msg = e.getConstraintViolations().stream()
                .findFirst()
                .map(v -> v.getPropertyPath() + " " + v.getMessage())
                .orElse("请求参数校验失败");
        return respond(HttpStatus.BAD_REQUEST, msg);
    }

    /** 缺少必需查询参数，例如 /api/search 没传 q 之外的必填项 */
    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<Map<String, String>> handleMissingParam(MissingServletRequestParameterException e) {
        return respond(HttpStatus.BAD_REQUEST, "缺少必需参数：" + e.getParameterName());
    }

    /** 参数类型不匹配，例如 /api/article/abc 把 id 传成了非数字 */
    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<Map<String, String>> handleTypeMismatch(MethodArgumentTypeMismatchException e) {
        return respond(HttpStatus.BAD_REQUEST, "参数格式不正确：" + e.getName());
    }

    /** 请求方法不支持，例如对 /api/search 发了 POST */
    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<Map<String, String>> handleMethodNotSupported(HttpRequestMethodNotSupportedException e) {
        return respond(HttpStatus.METHOD_NOT_ALLOWED, "不支持的请求方法：" + e.getMethod());
    }

    /** 路径不存在（静态资源 404，Spring 6.1+ 抛这个） */
    @ExceptionHandler({NoHandlerFoundException.class, NoResourceFoundException.class})
    public ResponseEntity<Map<String, String>> handleNotFound(Exception e) {
        return respond(HttpStatus.NOT_FOUND, "接口不存在");
    }

    /**
     * 唯一索引冲突：正常业务里已各自处理（昵称重复、重复收藏），
     * 这里只是兜底，防止并发竞态直接把异常抛到前端。
     */
    @ExceptionHandler(DuplicateKeyException.class)
    public ResponseEntity<Map<String, String>> handleDuplicateKey(DuplicateKeyException e) {
        return respond(HttpStatus.CONFLICT, "数据冲突，记录可能已存在");
    }

    /** 兜底：未预期的异常，500 + 通用文案，堆栈只写日志 */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, String>> handleUnexpected(Exception e) {
        org.slf4j.LoggerFactory.getLogger(GlobalExceptionHandler.class)
                .error("未预期的异常：{}", e.getMessage(), e);
        return respond(HttpStatus.INTERNAL_SERVER_ERROR, "服务器内部错误，请稍后再试");
    }

    private ResponseEntity<Map<String, String>> respond(HttpStatus status, String message) {
        Map<String, String> body = new LinkedHashMap<>();
        body.put("message", message);
        return ResponseEntity.status(status).body(body);
    }
}
