package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.fenglin.springboottest.config.AuthSupport;
import com.fenglin.springboottest.dto.AdminArticleRequest;
import com.fenglin.springboottest.dto.AdminCategoryRequest;
import com.fenglin.springboottest.dto.AdminTagRequest;
import com.fenglin.springboottest.entity.Article;
import com.fenglin.springboottest.entity.Category;
import com.fenglin.springboottest.entity.Tag;
import com.fenglin.springboottest.entity.User;
import com.fenglin.springboottest.exception.BusinessException;
import com.fenglin.springboottest.exception.ForbiddenException;
import com.fenglin.springboottest.exception.UnauthorizedException;
import com.fenglin.springboottest.mapper.ArticleMapper;
import com.fenglin.springboottest.mapper.CategoryMapper;
import com.fenglin.springboottest.mapper.TagMapper;
import com.fenglin.springboottest.mapper.UserMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 后台管理业务：概览、文章 CRUD、用户权限。
 * 每个入口都会重新读取数据库中的 permission，管理员被降权后立即失效。
 */
@Service
public class AdminService {

    private static final int PERMISSION_ADMIN = 0;
    private static final int PERMISSION_USER = 1;
    private static final DateTimeFormatter TIME_FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");

    private final AuthSupport authSupport;
    private final UserMapper userMapper;
    private final ArticleMapper articleMapper;
    private final CategoryMapper categoryMapper;
    private final TagMapper tagMapper;
    private final SearchService searchService;
    private final JdbcTemplate jdbcTemplate;

    public AdminService(AuthSupport authSupport, UserMapper userMapper, ArticleMapper articleMapper,
                        CategoryMapper categoryMapper, TagMapper tagMapper,
                        SearchService searchService, JdbcTemplate jdbcTemplate) {
        this.authSupport = authSupport;
        this.userMapper = userMapper;
        this.articleMapper = articleMapper;
        this.categoryMapper = categoryMapper;
        this.tagMapper = tagMapper;
        this.searchService = searchService;
        this.jdbcTemplate = jdbcTemplate;
    }

    /** 每次调用管理接口都校验当前数据库中的权限 */
    public User requireAdmin(String authorization) {
        Long uid = authSupport.requireUserId(authorization);
        User user = userMapper.selectById(uid);
        if (user == null) {
            throw new UnauthorizedException("管理员账号不存在或已被注销");
        }
        if (!Integer.valueOf(PERMISSION_ADMIN).equals(user.getPermission())) {
            throw new ForbiddenException("该账号没有后台管理权限");
        }
        return user;
    }

    // ============================================================
    //  概览
    // ============================================================

    public Map<String, Object> stats(String authorization) {
        requireAdmin(authorization);
        long articles = articleMapper.countArticles();
        long totalViews = articleMapper.sumArticleViews();
        long users = userMapper.selectCount(null);
        long admins = userMapper.selectCount(new LambdaQueryWrapper<User>()
                .eq(User::getPermission, PERMISSION_ADMIN));
        long categories = categoryMapper.selectCount(null);
        long tags = tagMapper.selectCount(null);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("articles", articles);
        result.put("users", users);
        result.put("admins", admins);
        result.put("categories", categories);
        result.put("tags", tags);
        result.put("totalViews", totalViews);
        result.put("avgViews", articles == 0 ? 0 : Math.round((double) totalViews / articles));
        result.put("recentArticles", searchService.search("", null, null, "new", 1, 5).get("list"));
        return result;
    }

    // ============================================================
    //  文章管理
    // ============================================================

    public Map<String, Object> articles(String authorization, String keyword, Integer page, Integer size) {
        requireAdmin(authorization);
        return searchService.search(keyword, null, null, "new", page, size);
    }

    public Map<String, Object> articleDetail(String authorization, Long id) {
        requireAdmin(authorization);
        Article article = articleMapper.selectById(id);
        if (article == null) {
            throw new BusinessException("文章不存在或已被删除");
        }
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("id", article.getId());
        result.put("title", article.getTitle());
        result.put("summary", article.getSummary());
        result.put("content", article.getContent());
        result.put("author", article.getAuthor());
        result.put("categoryId", article.getCategoryId());
        result.put("category", article.getCategory());
        result.put("tags", article.getTags());
        result.put("views", article.getViews());
        result.put("createdAt", article.getCreatedAt() == null ? "" : article.getCreatedAt().format(TIME_FMT));
        result.put("updatedAt", article.getUpdatedAt() == null ? "" : article.getUpdatedAt().format(TIME_FMT));
        return result;
    }

    @Transactional
    public Map<String, Object> saveArticle(String authorization, Long id, AdminArticleRequest req) {
        requireAdmin(authorization);
        String title = clean(req.getTitle());
        if (title.length() < 2 || title.length() > 200) {
            throw new BusinessException("文章标题需在 2-200 个字符之间");
        }

        Article article;
        boolean creating = id == null;
        if (creating) {
            article = new Article();
            article.setViews(0);
        } else {
            article = articleMapper.selectById(id);
            if (article == null) {
                throw new BusinessException("文章不存在或已被删除");
            }
        }

        Category category = null;
        if (req.getCategoryId() != null) {
            category = categoryMapper.selectById(req.getCategoryId());
            if (category == null) {
                throw new BusinessException("所选分类不存在");
            }
        }

        String summary = clean(req.getSummary());
        String content = clean(req.getContent());
        if (summary.isEmpty()) {
            summary = content.length() > 120 ? content.substring(0, 120) : content;
        }
        if (summary.length() > 500) {
            throw new BusinessException("文章摘要不能超过 500 个字符");
        }
        String author = clean(req.getAuthor());
        String tags = normalizeTags(req.getTags());

        article.setTitle(title);
        article.setSummary(summary);
        article.setContent(content);
        article.setAuthor(author.isEmpty() ? "管理员" : author);
        article.setCategoryId(category == null ? null : category.getId());
        article.setCategory(category == null ? "未分类" : category.getName());
        article.setTags(tags);

        if (creating) {
            articleMapper.insert(article);
        } else {
            articleMapper.updateById(article);
        }
        syncArticleTags(article.getId(), tags);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("id", article.getId());
        result.put("message", creating ? "文章已创建" : "文章已更新");
        return result;
    }

    @Transactional
    public void deleteArticle(String authorization, Long id) {
        requireAdmin(authorization);
        if (articleMapper.selectById(id) == null) {
            throw new BusinessException("文章不存在或已被删除");
        }
        // 项目早期表没有外键，手动清理关联数据，避免残留收藏/历史/点赞
        for (String table : new String[]{"article_tag", "favorite", "read_history", "article_like"}) {
            try {
                jdbcTemplate.update("DELETE FROM " + table + " WHERE article_id = ?", id);
            } catch (Exception ignored) {
                // 某张关联表尚未创建时不影响文章删除
            }
        }
        articleMapper.deleteById(id);
    }

    // ============================================================
    //  分类 / 标签
    // ============================================================

    public List<Map<String, Object>> categories(String authorization) {
        requireAdmin(authorization);
        List<Category> categories = categoryMapper.selectList(
                new LambdaQueryWrapper<Category>().orderByAsc(Category::getSort).orderByAsc(Category::getId));
        List<Map<String, Object>> rows = new ArrayList<>();
        for (Category category : categories) {
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("id", category.getId());
            row.put("name", category.getName());
            row.put("slug", category.getSlug());
            row.put("sort", category.getSort());
            row.put("articleCount", articleMapper.selectCount(new LambdaQueryWrapper<Article>()
                    .eq(Article::getCategoryId, category.getId())));
            rows.add(row);
        }
        return rows;
    }

    @Transactional
    public Map<String, Object> saveCategory(String authorization, Long id, AdminCategoryRequest req) {
        requireAdmin(authorization);
        String name = clean(req.getName());
        String slug = clean(req.getSlug()).toLowerCase();
        if (name.length() < 1 || name.length() > 64) {
            throw new BusinessException("分类名需在 1-64 个字符之间");
        }
        if (!slug.matches("[a-z0-9-]{1,64}")) {
            throw new BusinessException("分类 slug 只能包含小写字母、数字和连字符");
        }
        long duplicate = categoryMapper.selectCount(new LambdaQueryWrapper<Category>()
                .and(w -> w.eq(Category::getName, name).or().eq(Category::getSlug, slug))
                .ne(id != null, Category::getId, id));
        if (duplicate > 0) {
            throw new BusinessException("分类名或 slug 已存在");
        }

        Category category = id == null ? new Category() : categoryMapper.selectById(id);
        if (category == null) {
            throw new BusinessException("分类不存在");
        }
        category.setName(name);
        category.setSlug(slug);
        category.setSort(req.getSort() == null ? 0 : req.getSort());
        if (id == null) categoryMapper.insert(category);
        else categoryMapper.updateById(category);

        return Map.of("id", category.getId(), "message", id == null ? "分类已创建" : "分类已更新");
    }

    @Transactional
    public void deleteCategory(String authorization, Long id) {
        requireAdmin(authorization);
        if (categoryMapper.selectById(id) == null) {
            throw new BusinessException("分类不存在");
        }
        long articles = articleMapper.selectCount(new LambdaQueryWrapper<Article>().eq(Article::getCategoryId, id));
        long tags = tagMapper.selectCount(new LambdaQueryWrapper<Tag>().eq(Tag::getCategoryId, id));
        if (articles > 0 || tags > 0) {
            throw new BusinessException("该分类下还有文章或标签，请先迁移后再删除");
        }
        categoryMapper.deleteById(id);
    }

    public List<Map<String, Object>> tags(String authorization) {
        requireAdmin(authorization);
        List<Category> categories = categoryMapper.selectList(null);
        Map<Long, String> categoryNames = new LinkedHashMap<>();
        for (Category category : categories) {
            categoryNames.put(category.getId(), category.getName());
        }
        List<Tag> tags = tagMapper.selectList(
                new LambdaQueryWrapper<Tag>().orderByAsc(Tag::getSort).orderByAsc(Tag::getId));
        List<Map<String, Object>> rows = new ArrayList<>();
        for (Tag tag : tags) {
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("id", tag.getId());
            row.put("name", tag.getName());
            row.put("slug", tag.getSlug());
            row.put("categoryId", tag.getCategoryId());
            row.put("categoryName", tag.getCategoryId() == null ? "未归类" : categoryNames.getOrDefault(tag.getCategoryId(), "未知分类"));
            row.put("sort", tag.getSort());
            rows.add(row);
        }
        return rows;
    }

    @Transactional
    public Map<String, Object> saveTag(String authorization, Long id, AdminTagRequest req) {
        requireAdmin(authorization);
        String name = clean(req.getName());
        String slug = clean(req.getSlug()).toLowerCase();
        if (name.length() < 1 || name.length() > 64) {
            throw new BusinessException("标签名需在 1-64 个字符之间");
        }
        if (!slug.matches("[a-z0-9-]{1,64}")) {
            throw new BusinessException("标签 slug 只能包含小写字母、数字和连字符");
        }
        if (req.getCategoryId() != null && categoryMapper.selectById(req.getCategoryId()) == null) {
            throw new BusinessException("所属分类不存在");
        }
        long duplicate = tagMapper.selectCount(new LambdaQueryWrapper<Tag>()
                .and(w -> w.eq(Tag::getName, name).or().eq(Tag::getSlug, slug))
                .ne(id != null, Tag::getId, id));
        if (duplicate > 0) {
            throw new BusinessException("标签名或 slug 已存在");
        }

        Tag tag = id == null ? new Tag() : tagMapper.selectById(id);
        if (tag == null) {
            throw new BusinessException("标签不存在");
        }
        tag.setName(name);
        tag.setSlug(slug);
        tag.setCategoryId(req.getCategoryId());
        tag.setSort(req.getSort() == null ? 0 : req.getSort());
        if (id == null) tagMapper.insert(tag);
        else tagMapper.updateById(tag);

        return Map.of("id", tag.getId(), "message", id == null ? "标签已创建" : "标签已更新");
    }

    @Transactional
    public void deleteTag(String authorization, Long id) {
        requireAdmin(authorization);
        if (tagMapper.selectById(id) == null) {
            throw new BusinessException("标签不存在");
        }
        jdbcTemplate.update("DELETE FROM article_tag WHERE tag_id = ?", id);
        tagMapper.deleteById(id);
    }

    // ============================================================
    //  用户权限
    // ============================================================

    public Map<String, Object> users(String authorization, String keyword, Integer page, Integer size) {
        requireAdmin(authorization);
        int p = page == null || page < 1 ? 1 : page;
        int s = size == null || size < 1 ? 10 : Math.min(size, 50);
        LambdaQueryWrapper<User> wrapper = new LambdaQueryWrapper<User>()
                .select(User::getId, User::getName, User::getPermission, User::getCreatedAt, User::getUpdatedAt)
                .like(keyword != null && !keyword.isBlank(), User::getName, clean(keyword))
                .orderByAsc(User::getPermission)
                .orderByDesc(User::getId);
        Page<User> result = userMapper.selectPage(new Page<>(p, s), wrapper);

        List<Map<String, Object>> rows = new ArrayList<>();
        for (User user : result.getRecords()) {
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("id", user.getId());
            row.put("name", user.getName());
            row.put("permission", user.getPermission() == null ? PERMISSION_USER : user.getPermission());
            row.put("createdAt", user.getCreatedAt() == null ? "" : user.getCreatedAt().format(TIME_FMT));
            rows.add(row);
        }
        Map<String, Object> response = new LinkedHashMap<>();
        response.put("page", result.getCurrent());
        response.put("size", result.getSize());
        response.put("total", result.getTotal());
        response.put("pages", result.getPages());
        response.put("list", rows);
        return response;
    }

    @Transactional
    public Map<String, Object> updatePermission(String authorization, Long targetId, Integer permission) {
        User current = requireAdmin(authorization);
        if (permission == null || (permission != PERMISSION_ADMIN && permission != PERMISSION_USER)) {
            throw new BusinessException("权限值只能是 0（管理员）或 1（默认用户）");
        }
        User target = userMapper.selectById(targetId);
        if (target == null) {
            throw new BusinessException("用户不存在");
        }
        if (current.getId().equals(targetId) && permission != PERMISSION_ADMIN) {
            throw new BusinessException("不能取消自己的管理员权限");
        }
        if (Integer.valueOf(PERMISSION_ADMIN).equals(target.getPermission()) && permission == PERMISSION_USER) {
            long adminCount = userMapper.selectCount(new LambdaQueryWrapper<User>()
                    .eq(User::getPermission, PERMISSION_ADMIN));
            if (adminCount <= 1) {
                throw new BusinessException("系统至少需要保留一名管理员");
            }
        }
        target.setPermission(permission);
        userMapper.updateById(target);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("id", target.getId());
        result.put("name", target.getName());
        result.put("permission", target.getPermission());
        result.put("message", permission == PERMISSION_ADMIN ? "已设为管理员" : "已设为默认用户");
        return result;
    }

    // ============================================================
    //  工具
    // ============================================================

    private String clean(String value) {
        return value == null ? "" : value.trim();
    }

    private String normalizeTags(String raw) {
        if (raw == null || raw.isBlank()) return "";
        StringBuilder out = new StringBuilder();
        for (String tag : raw.split(",")) {
            String value = tag.trim();
            if (value.isEmpty()) continue;
            if (out.length() > 0) out.append(',');
            out.append(value);
        }
        String result = out.toString();
        return result.length() > 255 ? result.substring(0, 255) : result;
    }

    private void syncArticleTags(Long articleId, String tags) {
        jdbcTemplate.update("DELETE FROM article_tag WHERE article_id = ?", articleId);
        if (tags.isEmpty()) return;
        for (String tag : tags.split(",")) {
            jdbcTemplate.update(
                    "INSERT IGNORE INTO article_tag(article_id, tag_id) " +
                            "SELECT ?, id FROM tag WHERE name = ? LIMIT 1",
                    articleId, tag.trim());
        }
    }
}
