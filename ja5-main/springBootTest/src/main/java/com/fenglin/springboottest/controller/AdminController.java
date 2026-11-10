package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.dto.AdminArticleRequest;
import com.fenglin.springboottest.dto.AdminCategoryRequest;
import com.fenglin.springboottest.dto.AdminTagRequest;
import com.fenglin.springboottest.dto.LoginRequest;
import com.fenglin.springboottest.dto.PermissionUpdateRequest;
import com.fenglin.springboottest.service.AdminService;
import com.fenglin.springboottest.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * 后台管理接口。
 * 除登录外，所有接口都要求 Bearer token 且数据库中的 permission=0。
 */
@RestController
@RequestMapping("/api/admin")
public class AdminController {

    private final AuthService authService;
    private final AdminService adminService;

    public AdminController(AuthService authService, AdminService adminService) {
        this.authService = authService;
        this.adminService = adminService;
    }

    @PostMapping("/login")
    public Map<String, Object> login(@Valid @RequestBody LoginRequest req) {
        return authService.adminLogin(req);
    }

    @GetMapping("/stats")
    public Map<String, Object> stats(
            @RequestHeader(value = "Authorization", required = false) String auth) {
        return adminService.stats(auth);
    }

    @GetMapping("/articles")
    public Map<String, Object> articles(
            @RequestHeader(value = "Authorization", required = false) String auth,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "10") Integer size) {
        return adminService.articles(auth, keyword, page, size);
    }

    @GetMapping("/articles/{id}")
    public Map<String, Object> articleDetail(
            @RequestHeader(value = "Authorization", required = false) String auth,
            @PathVariable Long id) {
        return adminService.articleDetail(auth, id);
    }

    @PostMapping("/articles")
    public Map<String, Object> createArticle(
            @RequestHeader(value = "Authorization", required = false) String auth,
            @RequestBody AdminArticleRequest req) {
        return adminService.saveArticle(auth, null, req);
    }

    @PutMapping("/articles/{id}")
    public Map<String, Object> updateArticle(
            @RequestHeader(value = "Authorization", required = false) String auth,
            @PathVariable Long id,
            @RequestBody AdminArticleRequest req) {
        return adminService.saveArticle(auth, id, req);
    }

    @DeleteMapping("/articles/{id}")
    public Map<String, Object> deleteArticle(
            @RequestHeader(value = "Authorization", required = false) String auth,
            @PathVariable Long id) {
        adminService.deleteArticle(auth, id);
        return Map.of("message", "文章已删除");
    }

    @GetMapping("/categories")
    public Object categories(
            @RequestHeader(value = "Authorization", required = false) String auth) {
        return adminService.categories(auth);
    }

    @PostMapping("/categories")
    public Map<String, Object> createCategory(
            @RequestHeader(value = "Authorization", required = false) String auth,
            @RequestBody AdminCategoryRequest req) {
        return adminService.saveCategory(auth, null, req);
    }

    @PutMapping("/categories/{id}")
    public Map<String, Object> updateCategory(
            @RequestHeader(value = "Authorization", required = false) String auth,
            @PathVariable Long id,
            @RequestBody AdminCategoryRequest req) {
        return adminService.saveCategory(auth, id, req);
    }

    @DeleteMapping("/categories/{id}")
    public Map<String, Object> deleteCategory(
            @RequestHeader(value = "Authorization", required = false) String auth,
            @PathVariable Long id) {
        adminService.deleteCategory(auth, id);
        return Map.of("message", "分类已删除");
    }

    @GetMapping("/tags")
    public Object tags(
            @RequestHeader(value = "Authorization", required = false) String auth) {
        return adminService.tags(auth);
    }

    @PostMapping("/tags")
    public Map<String, Object> createTag(
            @RequestHeader(value = "Authorization", required = false) String auth,
            @RequestBody AdminTagRequest req) {
        return adminService.saveTag(auth, null, req);
    }

    @PutMapping("/tags/{id}")
    public Map<String, Object> updateTag(
            @RequestHeader(value = "Authorization", required = false) String auth,
            @PathVariable Long id,
            @RequestBody AdminTagRequest req) {
        return adminService.saveTag(auth, id, req);
    }

    @DeleteMapping("/tags/{id}")
    public Map<String, Object> deleteTag(
            @RequestHeader(value = "Authorization", required = false) String auth,
            @PathVariable Long id) {
        adminService.deleteTag(auth, id);
        return Map.of("message", "标签已删除");
    }

    @GetMapping("/users")
    public Map<String, Object> users(
            @RequestHeader(value = "Authorization", required = false) String auth,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "10") Integer size) {
        return adminService.users(auth, keyword, page, size);
    }

    @PutMapping("/users/{id}/permission")
    public Map<String, Object> updatePermission(
            @RequestHeader(value = "Authorization", required = false) String auth,
            @PathVariable Long id,
            @RequestBody PermissionUpdateRequest req) {
        return adminService.updatePermission(auth, id, req.getPermission());
    }
}
