// ============================================================
//  认证后端接口（昵称 + 密码登录/注册）
// ------------------------------------------------------------
//  后端接口（BASE 默认 "/api"，由 .env 的 VITE_API_BASE 覆盖）：
//    GET  /api/auth/captcha   -> { captchaId, image(base64 png) }
//    POST /api/auth/register  { name, password, captchaId, captcha } -> { token, userId }
//    POST /api/auth/login     { name, password, remember }           -> { token, userId, permission }
//    POST /api/admin/login    { name, password, remember }           -> 仅 permission=0
//    GET  /api/auth/me        Authorization: Bearer <token>          -> { id, name, permission }
//
//  错误约定：HTTP 非 2xx 时，响应体 { message: "错误说明" } 会被提取为
//  Error.message，直接展示在表单错误横幅。
// ============================================================

import { http, saveToken, getToken, clearToken } from './http'

export { getToken, clearToken }

// 获取图形验证码：返回 { captchaId, image(data:image/png;base64,...) }
export async function getCaptcha () {
  return http.get('/auth/captcha')
}

// 注册（携带图形验证码），成功后自动持久化 token
export async function registerUser (payload) {
  const res = await http.post('/auth/register', payload)
  if (res && res.token) saveToken(res.token)
  return res
}

// 普通登录，成功后自动持久化 token
export async function loginUser (payload) {
  const res = await http.post('/auth/login', payload)
  if (res && res.token) saveToken(res.token)
  return res
}

// 后台登录：后端仅允许 permission=0 的账号通过
export async function adminLoginUser (payload) {
  const res = await http.post('/admin/login', payload)
  if (res && res.token) saveToken(res.token)
  return res
}

// 拉取当前登录用户信息（受保护接口，token 由 http 层自动注入）
export async function getMe () {
  return http.get('/auth/me')
}

// 退出登录：清除本地 token
export function logout () {
  clearToken()
}
