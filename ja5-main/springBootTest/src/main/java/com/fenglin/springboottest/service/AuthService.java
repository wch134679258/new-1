package com.fenglin.springboottest.service;

import com.fenglin.springboottest.dto.LoginRequest;
import com.fenglin.springboottest.dto.RegisterRequest;
import com.fenglin.springboottest.entity.User;
import com.fenglin.springboottest.exception.BusinessException;
import com.fenglin.springboottest.exception.ForbiddenException;
import com.fenglin.springboottest.mapper.UserMapper;
import com.fenglin.springboottest.config.JwtUtil;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 注册 / 登录 业务（昵称 + 密码）
 *
 * <p>安全要点：</p>
 * <ul>
 *   <li>BCryptPasswordEncoder 由 Spring 注入（无状态、可共享），不再每个实例 new 一个</li>
 *   <li>登录失败限流：同一昵称连续失败 {@value #MAX_FAILS} 次锁定 {@value #LOCK_MS/1000} 秒，
 *       配合 BCrypt 本身的耗时，堵住无验证码登录接口的爆破</li>
 *   <li>注册昵称唯一靠「先查后插 + 唯一索引兜底」：并发下先查可能查不到，
 *       插入时靠 uk_name 抛 DuplicateKeyException，转成友好提示而不是 500</li>
 *   <li>密码上限 64 位：BCrypt 只处理前 72 字节，超长部分会被静默丢弃，
 *       提前拦掉比让用户以为长密码更安全要好</li>
 * </ul>
 */
@Service
public class AuthService {

    /** 昵称长度限制 */
    private static final int NAME_MIN = 2;
    private static final int NAME_MAX = 32;

    /** 密码长度限制（上限 64：见类注释） */
    private static final int PWD_MIN = 8;
    private static final int PWD_MAX = 64;

    /** 登录失败锁定策略 */
    private static final int MAX_FAILS = 5;
    private static final long LOCK_MS = 60_000L;

    /** 权限值：1=默认用户，0=管理员 */
    private static final int PERMISSION_USER = 1;
    private static final int PERMISSION_ADMIN = 0;

    private final UserMapper userMapper;
    private final JwtUtil jwtUtil;
    private final CaptchaService captchaService;
    private final BCryptPasswordEncoder encoder;

    /** 登录失败记录：昵称 -> 连续失败次数（锁定期间清零） */
    private final Map<String, Fail> fails = new ConcurrentHashMap<>();

    public AuthService(UserMapper userMapper, JwtUtil jwtUtil, CaptchaService captchaService,
                       BCryptPasswordEncoder encoder) {
        this.userMapper = userMapper;
        this.jwtUtil = jwtUtil;
        this.captchaService = captchaService;
        this.encoder = encoder;
    }

    /**
     * 注册：校验图形验证码 -> 校验昵称唯一 -> BCrypt 加密 -> 落库 -> 返回 JWT
     */
    @Transactional
    public Map<String, Object> register(RegisterRequest req) {
        String name = req.getName() == null ? "" : req.getName().trim();
        String password = req.getPassword() == null ? "" : req.getPassword();

        // 参数校验在 Controller 层用 @Valid 做过一遍，这里再兜底：
        // Service 可能被内部其它入口调用，不能假设入参一定合法。
        if (name.length() < NAME_MIN || name.length() > NAME_MAX) {
            throw new BusinessException("昵称长度需在 " + NAME_MIN + "-" + NAME_MAX + " 个字符之间");
        }
        if (password.length() < PWD_MIN || password.length() > PWD_MAX) {
            throw new BusinessException("密码长度需在 " + PWD_MIN + "-" + PWD_MAX + " 位之间");
        }
        if (!password.matches(".*[A-Za-z].*") || !password.matches(".*\\d.*")) {
            throw new BusinessException("密码需同时包含字母和数字");
        }

        // 图形验证码校验（一次性，校验后作废）
        captchaService.validate(req.getCaptchaId(), req.getCaptcha());

        if (userMapper.findByName(name).isPresent()) {
            throw new BusinessException("该昵称已被使用，请换一个");
        }

        User user = new User(name, encoder.encode(password));
        user.setPermission(PERMISSION_USER);   // 注册用户一律是默认权限，不能自助成为管理员
        try {
            userMapper.insert(user);
        } catch (DuplicateKeyException e) {
            // 并发注册同名：唯一索引兜底，转成友好提示
            throw new BusinessException("该昵称已被使用，请换一个");
        }

        return tokenResult(user.getId(), name, user.getPermission());
    }

    /**
     * 普通登录：校验昵称 + 密码 -> 返回 JWT
     */
    @Transactional(readOnly = true)
    public Map<String, Object> login(LoginRequest req) {
        User user = authenticate(req);
        return tokenResult(user.getId(), user.getName(), user.getPermission());
    }

    /**
     * 后台登录：密码验证通过后还必须是管理员（permission=0）。
     */
    @Transactional(readOnly = true)
    public Map<String, Object> adminLogin(LoginRequest req) {
        User user = authenticate(req);
        if (!Integer.valueOf(PERMISSION_ADMIN).equals(user.getPermission())) {
            throw new ForbiddenException("该账号没有后台管理权限");
        }
        return tokenResult(user.getId(), user.getName(), user.getPermission());
    }

    /** 公共账号密码校验与失败限流 */
    private User authenticate(LoginRequest req) {
        String name = req.getName() == null ? "" : req.getName().trim();
        String password = req.getPassword() == null ? "" : req.getPassword();

        // 失败限流检查（按昵称计数，避免暴力破解）
        long waitMs = lockRemaining(name);
        if (waitMs > 0) {
            throw new BusinessException("尝试次数过多，请 " + (waitMs / 1000 + 1) + " 秒后再试");
        }

        User user = userMapper.findByName(name)
                .orElseThrow(() -> {
                    recordFail(name);
                    return new BusinessException("昵称或密码错误");
                });
        if (!encoder.matches(password, user.getPassword())) {
            recordFail(name);
            throw new BusinessException("昵称或密码错误");
        }

        fails.remove(name);
        return user;
    }

    /** 该昵称还需锁定多少毫秒；0 表示未锁定 */
    private long lockRemaining(String name) {
        Fail f = fails.get(name);
        if (f == null || f.lockUntil == 0) return 0;
        long remain = f.lockUntil - System.currentTimeMillis();
        if (remain <= 0) {
            fails.remove(name, f);   // 锁定期已过，清掉重新计数
            return 0;
        }
        return remain;
    }

    /** 记录一次登录失败，连续达到 MAX_FAILS 次则锁定 LOCK_MS 毫秒 */
    private void recordFail(String name) {
        long now = System.currentTimeMillis();
        fails.compute(name, (k, old) -> {
            // 首次失败，或上一轮锁定已结束：从 1 开始重新累计
            if (old == null || (old.lockUntil > 0 && now >= old.lockUntil)) {
                return new Fail(1, 0);
            }
            int count = old.count + 1;
            if (count >= MAX_FAILS) {
                return new Fail(0, now + LOCK_MS);   // 计数清零并上锁
            }
            return new Fail(count, 0);
        });
    }

    /** 签发 JWT 令牌并返回 userId、permission */
    private Map<String, Object> tokenResult(Long userId, String name, Integer permission) {
        Map<String, Object> result = new HashMap<>();
        result.put("token", jwtUtil.createToken(userId, name));
        result.put("userId", String.valueOf(userId));
        result.put("permission", permission == null ? PERMISSION_USER : permission);
        return result;
    }

    /** 登录失败计数（内存态，重启即清零——演示项目够用） */
    private static final class Fail {
        final int count;
        final long lockUntil;

        Fail(int count, long lockUntil) {
            this.count = count;
            this.lockUntil = lockUntil;
        }
    }
}
