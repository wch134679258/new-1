package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.config.AuthSupport;
import com.fenglin.springboottest.dto.LoginRequest;
import com.fenglin.springboottest.dto.RegisterRequest;
import com.fenglin.springboottest.entity.User;
import com.fenglin.springboottest.exception.UnauthorizedException;
import com.fenglin.springboottest.mapper.UserMapper;
import com.fenglin.springboottest.service.AuthService;
import com.fenglin.springboottest.service.CaptchaService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 认证接口：对接 aurora-vue-2 注册/登录页（昵称 + 密码）
 * <pre>
 * GET  /api/auth/captcha   -> { captchaId, image(base64 png) }
 * POST /api/auth/register  { name, password, captchaId, captcha } -> { token, userId, permission }
 * POST /api/auth/login     { name, password, remember }           -> { token, userId, permission }
 * GET  /api/auth/me        Authorization: Bearer &lt;token&gt;          -> { id, name, permission }
 * POST /api/admin/login    { name, password, remember }           -> { token, userId, permission }（仅 permission=0）
 * </pre>
 */
@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;
    private final AuthSupport authSupport;
    private final UserMapper userMapper;
    private final CaptchaService captchaService;

    public AuthController(AuthService authService, AuthSupport authSupport, UserMapper userMapper,
                          CaptchaService captchaService) {
        this.authService = authService;
        this.authSupport = authSupport;
        this.userMapper = userMapper;
        this.captchaService = captchaService;
    }

    /** 图形验证码：返回图片与对应的 captchaId */
    @GetMapping("/captcha")
    public CaptchaService.Captcha captcha() {
        return captchaService.generate();
    }

    /** 注册：@Valid 先把明显不合法的入参拦成 400 {message} */
    @PostMapping("/register")
    public Map<String, Object> register(@Valid @RequestBody RegisterRequest req) {
        return authService.register(req);
    }

    /** 普通登录 */
    @PostMapping("/login")
    public Map<String, Object> login(@Valid @RequestBody LoginRequest req) {
        return authService.login(req);
    }

    /**
     * 受保护接口：返回当前登录用户信息。令牌非法/过期/缺失均返回 401。
     */
    @GetMapping("/me")
    public Map<String, Object> me(@RequestHeader(value = "Authorization", required = false) String auth) {
        Long uid = authSupport.requireUserId(auth);
        User user = userMapper.selectById(uid);
        if (user == null) {
            throw new UnauthorizedException("用户不存在或已被注销");
        }
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("id", user.getId());
        result.put("name", user.getName());
        result.put("permission", user.getPermission() == null ? 1 : user.getPermission());
        return result;
    }
}
