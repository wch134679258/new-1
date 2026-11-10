// ============================================================
//  统一 HTTP 层：BASE 拼接 / token 注入 / 错误提取 / 401 处理
// ------------------------------------------------------------
//  所有 api/*.js 共用。约定：
//    成功      -> 直接返回响应体 JSON
//    失败      -> 提取后端 { message } 抛为 Error.message
//    401       -> 清除本地 token 并抛出「登录已过期，请重新登录」
// ============================================================

const BASE = (import.meta.env && import.meta.env.VITE_API_BASE) || '/api'
const TOKEN_KEY = 'aurora_token'
// 后端连不上时的统一文案：这个项目的报错基本都是「忘了开后端」，不是地址写错
const OFFLINE_MSG = '连不上后端服务，请确认后端已在 8081 端口启动（双击 启动项目.bat）'

// ---------- token 本地持久化 ----------
export function saveToken (token) {
  if (token) localStorage.setItem(TOKEN_KEY, token)
}
export function getToken () {
  return localStorage.getItem(TOKEN_KEY) || ''
}
export function clearToken () {
  localStorage.removeItem(TOKEN_KEY)
}

/**
 * 统一请求入口。
 * @param {string} path   以 / 开头的接口路径（相对 BASE）
 * @param {object} opts   { method, params, body }
 *   params 查询参数，值为 null / undefined / '' 的键会被丢弃
 *   body   请求体（JSON），仅 POST/PUT/DELETE 使用
 */
async function request (path, { method = 'GET', params = null, body = null } = {}) {
  const headers = { Accept: 'application/json' }
  const token = getToken()
  if (token) headers.Authorization = 'Bearer ' + token
  if (body != null) headers['Content-Type'] = 'application/json'

  let url = BASE + path
  if (params) {
    const qs = new URLSearchParams()
    Object.keys(params).forEach((k) => {
      const v = params[k]
      if (v === null || v === undefined || v === '') return
      qs.append(k, String(v))
    })
    const suffix = qs.toString()
    if (suffix) url += '?' + suffix
  }

  // 拿不到响应（后端进程没起 / 端口不通 / 断网）时 fetch 直接 reject，
  // 原生报错是英文 "Failed to fetch"，对用户毫无意义 → 换成人话
  let res
  try {
    res = await fetch(url, {
      method,
      headers,
      body: body == null ? undefined : JSON.stringify(body)
    })
  } catch (_) {
    throw new Error(OFFLINE_MSG)
  }

  if (res.status === 401) {
    clearToken()
    throw new Error('登录已过期，请重新登录')
  }
  if (!res.ok) {
    let message = '请求失败，请稍后再试'
    let isJson = false
    try {
      const data = await res.json()
      isJson = true
      if (data && data.message) message = data.message
    } catch (_) { /* 忽略解析错误 */ }
    // 后端有 GlobalExceptionHandler，出错也一定回 JSON；
    // 拿到非 JSON 的 5xx 说明请求根本没到后端（Vite 代理连不上 8081）
    if (!isJson && res.status >= 500) message = OFFLINE_MSG
    throw new Error(message)
  }
  // 204 / 空响应体兜底
  const text = await res.text()
  return text ? JSON.parse(text) : null
}

export const http = {
  get: (path, params) => request(path, { method: 'GET', params }),
  post: (path, body) => request(path, { method: 'POST', body: body || {} }),
  put: (path, body) => request(path, { method: 'PUT', body: body || {} }),
  del: (path) => request(path, { method: 'DELETE' })
}

export { BASE }
