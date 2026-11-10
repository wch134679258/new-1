// ============================================================
//  管理端接口（全部要求管理员；token 由 http 层自动注入）
// ------------------------------------------------------------
//  后端接口：
//    GET    /api/admin/stats                 概览统计
//    GET    /api/admin/articles?page=&size=&keyword=
//      -> { page, size, total, pages, list: [AdminArticleItem] }
//    GET    /api/admin/articles/{id}         编辑用详情（多返回 tagIds）
//    POST   /api/admin/articles              新建 -> { id, message }
//    PUT    /api/admin/articles/{id}         更新 -> { message }
//    DELETE /api/admin/articles/{id}         删除（级联清理）
//      -> { id, removedFavorites, removedLikes, removedHistory, removedTagLinks }
//    GET    /api/admin/categories            分类列表
//    POST / PUT / DELETE /api/admin/categories[/{id}]
//    GET    /api/admin/tags                  标签列表
//    POST / PUT / DELETE /api/admin/tags[/{id}]
//
//  权限：没带令牌 -> 401（http 层会清 token）；普通用户 -> 403「需要管理员权限」
// ============================================================

import { http } from './http'

/** 站点概览统计 */
export async function fetchAdminStats () {
  return http.get('/admin/stats')
}

/** 管理端文章列表 */
export async function fetchAdminArticles (opts = {}) {
  const { page = 1, size = 10, keyword = '' } = opts
  return http.get('/admin/articles', { page, size, keyword })
}

/** 编辑用单篇详情 */
export async function fetchAdminArticle (id) {
  return http.get('/admin/articles/' + encodeURIComponent(id))
}

/** 新建文章 */
export async function createAdminArticle (payload) {
  return http.post('/admin/articles', payload)
}

/** 更新文章 */
export async function updateAdminArticle (id, payload) {
  return http.put('/admin/articles/' + encodeURIComponent(id), payload)
}

/** 删除文章（返回级联清理的数量） */
export async function deleteAdminArticle (id) {
  return http.del('/admin/articles/' + encodeURIComponent(id))
}

// ---------- 分类 ----------

export async function fetchAdminCategories () {
  return http.get('/admin/categories')
}

export async function createAdminCategory (payload) {
  return http.post('/admin/categories', payload)
}

export async function updateAdminCategory (id, payload) {
  return http.put('/admin/categories/' + encodeURIComponent(id), payload)
}

export async function deleteAdminCategory (id) {
  return http.del('/admin/categories/' + encodeURIComponent(id))
}

// ---------- 标签 ----------

export async function fetchAdminTags () {
  return http.get('/admin/tags')
}

export async function createAdminTag (payload) {
  return http.post('/admin/tags', payload)
}

export async function updateAdminTag (id, payload) {
  return http.put('/admin/tags/' + encodeURIComponent(id), payload)
}

export async function deleteAdminTag (id) {
  return http.del('/admin/tags/' + encodeURIComponent(id))
}

// ---------- 用户权限 ----------

/** 用户列表（不返回密码字段） */
export async function fetchAdminUsers (opts = {}) {
  const { page = 1, size = 10, keyword = '' } = opts
  return http.get('/admin/users', { page, size, keyword })
}

/** 修改权限：0=管理员，1=默认用户 */
export async function updateUserPermission (id, permission) {
  return http.put('/admin/users/' + encodeURIComponent(id) + '/permission', { permission })
}
