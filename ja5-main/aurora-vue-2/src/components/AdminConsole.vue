<template>
  <div class="admin">
    <header class="admin__top">
      <button class="admin__brand" type="button" @click="$emit('back')">
        <span class="admin__mark" aria-hidden="true"></span>
        <span class="admin__brand-text">
          <b>樱见 · 管理台</b>
          <i>SAKURA NOTE ADMIN</i>
        </span>
      </button>

      <div class="admin__top-actions">
        <span class="admin__who">
          <span class="admin__avatar">{{ avatarText }}</span>
          <span><b>{{ userName }}</b><i>管理员权限</i></span>
        </span>
        <button class="ghost-btn" type="button" @click="$emit('back')">返回首页</button>
        <button class="ghost-btn ghost-btn--danger" type="button" @click="$emit('logout')">退出登录</button>
      </div>
    </header>

    <div class="admin__layout">
      <aside class="admin__side">
        <div class="side-profile">
          <span class="side-profile__avatar">{{ avatarText }}</span>
          <div>
            <b>{{ userName }}</b>
            <span>后台管理员</span>
          </div>
        </div>

        <nav class="side-nav" aria-label="后台功能">
          <button
            v-for="item in tabs"
            :key="item.key"
            class="side-nav__item"
            :class="{ 'side-nav__item--on': tab === item.key }"
            type="button"
            @click="tab = item.key"
          >
            <span class="side-nav__glyph">{{ item.glyph }}</span>
            <span>{{ item.label }}</span>
            <i v-if="item.key === 'articles' && stats">{{ stats.articles }}</i>
          </button>
        </nav>

        <p class="side-note">所有管理操作都会校验数据库中的管理员权限。</p>
      </aside>

      <main class="admin__main">
        <!-- 概览 -->
        <section v-if="tab === 'overview'" class="panel-view">
          <div class="page-head">
            <div>
              <p class="eyebrow">OVERVIEW · 今日站务</p>
              <h1>后台概览</h1>
              <p>从这里查看文章、用户与内容分类的整体状态。</p>
            </div>
            <span class="page-head__date">{{ todayText }}</span>
          </div>

          <div v-if="statsLoading" class="stat-grid">
            <div v-for="n in 4" :key="n" class="stat-card stat-card--loading"></div>
          </div>
          <div v-else-if="stats" class="stat-grid">
            <article v-for="card in statCards" :key="card.label" class="stat-card">
              <span class="stat-card__label">{{ card.label }}</span>
              <b>{{ card.value }}</b>
              <span class="stat-card__hint">{{ card.hint }}</span>
            </article>
          </div>

          <div class="overview-grid">
            <section class="soft-card">
              <div class="card-head">
                <h2>最近更新</h2>
                <button type="button" @click="switchTab('articles')">全部文章 →</button>
              </div>
              <div v-if="stats && stats.recentArticles && stats.recentArticles.length" class="recent-list">
                <button
                  v-for="item in stats.recentArticles"
                  :key="item.id"
                  class="recent-row"
                  type="button"
                  @click="editArticle(item.id)"
                >
                  <span class="recent-row__main">
                    <b>{{ item.title }}</b>
                    <i>{{ item.category }} · {{ item.author }} · {{ item.createdAt }}</i>
                  </span>
                  <span class="recent-row__views">{{ item.views }} 阅读</span>
                </button>
              </div>
              <div v-else class="empty-mini">暂时还没有文章</div>
            </section>

            <section class="soft-card quick-card">
              <div class="card-head"><h2>快捷操作</h2></div>
              <button type="button" @click="openArticleModal()">
                <span>新建一篇手记</span><i>写完直接发布到首页</i>
              </button>
              <button type="button" @click="switchTab('users')">
                <span>管理用户权限</span><i>设置或取消管理员</i>
              </button>
              <button type="button" @click="switchTab('taxonomy')">
                <span>整理分类与标签</span><i>保持内容结构清晰</i>
              </button>
            </section>
          </div>
        </section>

        <!-- 文章 -->
        <section v-else-if="tab === 'articles'" class="panel-view">
          <div class="page-head">
            <div>
              <p class="eyebrow">CONTENT · 内容管理</p>
              <h1>文章管理</h1>
              <p>新增、编辑或删除首页文章。</p>
            </div>
            <button class="primary-btn" type="button" @click="openArticleModal()">新建文章</button>
          </div>

          <div class="toolbar">
            <form class="search-form" @submit.prevent="loadArticles(1)">
              <input v-model="articleKeyword" type="search" placeholder="搜索标题、作者或标签" />
              <button type="submit">搜索</button>
            </form>
            <span class="toolbar__count" v-if="!articlesLoading">共 {{ articleTotal }} 篇</span>
          </div>

          <div class="table-card">
            <div v-if="articlesLoading" class="loading-box">正在加载文章…</div>
            <div v-else-if="!articles.length" class="empty-box">
              <p>没有找到符合条件的文章</p>
              <button class="primary-btn" type="button" @click="openArticleModal()">写第一篇</button>
            </div>
            <div v-else class="table-scroll">
              <table>
                <thead><tr><th>标题</th><th>分类</th><th>作者</th><th>浏览</th><th>更新时间</th><th>操作</th></tr></thead>
                <tbody>
                  <tr v-for="item in articles" :key="item.id">
                    <td><b class="table-title">{{ item.title }}</b><small>{{ item.summary }}</small></td>
                    <td><span class="pill">{{ item.category || '未分类' }}</span></td>
                    <td>{{ item.author || '管理员' }}</td>
                    <td>{{ item.views }}</td>
                    <td class="muted">{{ item.createdAt }}</td>
                    <td>
                      <div class="row-actions">
                        <button type="button" @click="editArticle(item.id)">编辑</button>
                        <button class="danger-text" type="button" @click="removeArticle(item)">删除</button>
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
          <AdminPager :page="articlePage" :pages="articlePages" @change="loadArticles" />
        </section>

        <!-- 分类与标签 -->
        <section v-else-if="tab === 'taxonomy'" class="panel-view">
          <div class="page-head">
            <div>
              <p class="eyebrow">TAXONOMY · 内容结构</p>
              <h1>分类与标签</h1>
              <p>维护首页导航使用的两级分类体系。</p>
            </div>
          </div>

          <div class="taxonomy-grid">
            <section class="soft-card">
              <div class="card-head">
                <h2>一级分类</h2>
                <button type="button" @click="openTaxModal('category')">+ 新建分类</button>
              </div>
              <div v-if="!categories.length" class="empty-mini">暂无分类</div>
              <div v-else class="mini-list">
                <div v-for="c in categories" :key="c.id" class="mini-row">
                  <span><b>{{ c.name }}</b><i>/{{ c.slug }} · {{ c.articleCount }} 篇</i></span>
                  <div class="row-actions">
                    <button type="button" @click="openTaxModal('category', c)">编辑</button>
                    <button class="danger-text" type="button" @click="removeCategory(c)">删除</button>
                  </div>
                </div>
              </div>
            </section>

            <section class="soft-card">
              <div class="card-head">
                <h2>二级标签</h2>
                <button type="button" @click="openTaxModal('tag')">+ 新建标签</button>
              </div>
              <div v-if="!tags.length" class="empty-mini">暂无标签</div>
              <div v-else class="mini-list">
                <div v-for="t in tags" :key="t.id" class="mini-row">
                  <span><b>{{ t.name }}</b><i>{{ t.categoryName }} · /{{ t.slug }}</i></span>
                  <div class="row-actions">
                    <button type="button" @click="openTaxModal('tag', t)">编辑</button>
                    <button class="danger-text" type="button" @click="removeTag(t)">删除</button>
                  </div>
                </div>
              </div>
            </section>
          </div>
        </section>

        <!-- 用户 -->
        <section v-else class="panel-view">
          <div class="page-head">
            <div>
              <p class="eyebrow">MEMBERS · 用户权限</p>
              <h1>用户管理</h1>
              <p>只有管理员可以进入后台；系统始终保留至少一名管理员。</p>
            </div>
          </div>

          <div class="toolbar">
            <form class="search-form" @submit.prevent="loadUsers(1)">
              <input v-model="userKeyword" type="search" placeholder="搜索用户昵称" />
              <button type="submit">搜索</button>
            </form>
            <span class="toolbar__count" v-if="!usersLoading">共 {{ userTotal }} 位</span>
          </div>

          <div class="table-card">
            <div v-if="usersLoading" class="loading-box">正在加载用户…</div>
            <div v-else-if="!users.length" class="empty-box"><p>没有找到用户</p></div>
            <div v-else class="table-scroll">
              <table>
                <thead><tr><th>昵称</th><th>权限</th><th>注册时间</th><th>操作</th></tr></thead>
                <tbody>
                  <tr v-for="row in users" :key="row.id">
                    <td>
                      <b>{{ row.name }}</b>
                      <span v-if="row.id === user.id" class="self-pill">当前账号</span>
                    </td>
                    <td>
                      <span class="permission-pill" :class="{ 'permission-pill--admin': row.permission === 0 }">
                        {{ row.permission === 0 ? '管理员' : '默认用户' }}
                      </span>
                    </td>
                    <td class="muted">{{ row.createdAt }}</td>
                    <td>
                      <button
                        v-if="row.id !== user.id"
                        class="permission-btn"
                        type="button"
                        :disabled="row._saving"
                        @click="togglePermission(row)"
                      >
                        {{ row.permission === 0 ? '取消管理员' : '设为管理员' }}
                      </button>
                      <span v-else class="muted">不可修改自己</span>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
          <AdminPager :page="userPage" :pages="userPages" @change="loadUsers" />
        </section>
      </main>
    </div>

    <!-- 文章编辑弹层 -->
    <Transition name="fade">
      <div v-if="articleModal" class="modal-mask" @click.self="closeArticleModal">
        <section class="modal" role="dialog" aria-modal="true" aria-label="编辑文章">
          <header class="modal__head">
            <div><p class="eyebrow">EDITOR</p><h2>{{ articleId ? '编辑文章' : '新建文章' }}</h2></div>
            <button type="button" class="modal__close" @click="closeArticleModal">×</button>
          </header>
          <form class="modal__body" @submit.prevent="saveArticle">
            <label class="form-row form-row--full"><span>标题</span>
              <input v-model.trim="articleForm.title" maxlength="200" placeholder="文章标题" />
            </label>
            <div class="form-grid">
              <label class="form-row"><span>作者</span>
                <input v-model.trim="articleForm.author" maxlength="64" placeholder="管理员" />
              </label>
              <label class="form-row"><span>分类</span>
                <select v-model="articleForm.categoryId">
                  <option value="">未分类</option>
                  <option v-for="c in categories" :key="c.id" :value="String(c.id)">{{ c.name }}</option>
                </select>
              </label>
            </div>
            <label class="form-row form-row--full"><span>标签（逗号分隔）</span>
              <input v-model.trim="articleForm.tags" maxlength="255" placeholder="Vue,前端,随笔" />
            </label>
            <label class="form-row form-row--full"><span>摘要</span>
              <textarea v-model.trim="articleForm.summary" rows="3" maxlength="500" placeholder="不填则自动截取正文"></textarea>
            </label>
            <label class="form-row form-row--full"><span>正文</span>
              <textarea v-model="articleForm.content" rows="11" placeholder="写下正文内容…"></textarea>
            </label>
            <div class="modal__foot">
              <button class="ghost-btn" type="button" @click="closeArticleModal">取消</button>
              <button class="primary-btn" type="submit" :disabled="savingArticle">
                {{ savingArticle ? '保存中…' : '保存文章' }}
              </button>
            </div>
          </form>
        </section>
      </div>
    </Transition>

    <!-- 分类 / 标签编辑弹层 -->
    <Transition name="fade">
      <div v-if="taxModal" class="modal-mask" @click.self="closeTaxModal">
        <section class="modal modal--small" role="dialog" aria-modal="true">
          <header class="modal__head">
            <div>
              <p class="eyebrow">{{ taxType === 'category' ? 'CATEGORY' : 'TAG' }}</p>
              <h2>{{ taxId ? '编辑' : '新建' }}{{ taxType === 'category' ? '分类' : '标签' }}</h2>
            </div>
            <button type="button" class="modal__close" @click="closeTaxModal">×</button>
          </header>
          <form class="modal__body" @submit.prevent="saveTax">
            <label class="form-row form-row--full"><span>名称</span>
              <input v-model.trim="taxForm.name" maxlength="64" placeholder="展示名称" />
            </label>
            <label class="form-row form-row--full"><span>Slug</span>
              <input v-model.trim="taxForm.slug" maxlength="64" placeholder="例如 frontend" />
            </label>
            <label v-if="taxType === 'tag'" class="form-row form-row--full"><span>所属分类</span>
              <select v-model="taxForm.categoryId">
                <option value="">不归属分类</option>
                <option v-for="c in categories" :key="c.id" :value="String(c.id)">{{ c.name }}</option>
              </select>
            </label>
            <label class="form-row form-row--full"><span>排序</span>
              <input v-model.number="taxForm.sort" type="number" min="0" placeholder="0" />
            </label>
            <div class="modal__foot">
              <button class="ghost-btn" type="button" @click="closeTaxModal">取消</button>
              <button class="primary-btn" type="submit" :disabled="savingTax">{{ savingTax ? '保存中…' : '保存' }}</button>
            </div>
          </form>
        </section>
      </div>
    </Transition>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import {
  createAdminArticle,
  createAdminCategory,
  createAdminTag,
  deleteAdminArticle,
  deleteAdminCategory,
  deleteAdminTag,
  fetchAdminArticle,
  fetchAdminArticles,
  fetchAdminCategories,
  fetchAdminStats,
  fetchAdminTags,
  fetchAdminUsers,
  updateAdminArticle,
  updateAdminCategory,
  updateAdminTag,
  updateUserPermission
} from '../api/admin'
import { toast } from '../composables/useToast'
import AdminPager from './AdminPager.vue'

const props = defineProps({
  user: { type: Object, default: null }
})
const emit = defineEmits(['back', 'logout'])

const tabs = [
  { key: 'overview', label: '概览', glyph: '概' },
  { key: 'articles', label: '文章管理', glyph: '文' },
  { key: 'taxonomy', label: '分类与标签', glyph: '类' },
  { key: 'users', label: '用户管理', glyph: '户' }
]
const tab = ref('overview')

const userName = computed(() => (props.user && props.user.name) || '管理员')
const avatarText = computed(() => userName.value.slice(0, 1).toUpperCase())
const todayText = new Intl.DateTimeFormat('zh-CN', {
  year: 'numeric', month: 'long', day: 'numeric', weekday: 'long'
}).format(new Date())

// ---------- 概览 ----------
const stats = ref(null)
const statsLoading = ref(true)
const statCards = computed(() => {
  if (!stats.value) return []
  const fmt = (n) => Number(n || 0).toLocaleString('zh-CN')
  return [
    { label: '文章总数', value: fmt(stats.value.articles), hint: `篇均 ${fmt(stats.value.avgViews)} 次阅读` },
    { label: '注册用户', value: fmt(stats.value.users), hint: `${fmt(stats.value.admins)} 位管理员` },
    { label: '内容分类', value: fmt(stats.value.categories), hint: `${fmt(stats.value.tags)} 枚标签` },
    { label: '累计浏览', value: fmt(stats.value.totalViews), hint: '全站文章阅读量' }
  ]
})

async function loadStats () {
  statsLoading.value = true
  try {
    stats.value = await fetchAdminStats()
  } catch (e) {
    toast.error(e.message || '概览加载失败')
  } finally {
    statsLoading.value = false
  }
}

// ---------- 文章 ----------
const articles = ref([])
const articleKeyword = ref('')
const articlePage = ref(1)
const articlePages = ref(1)
const articleTotal = ref(0)
const articlesLoading = ref(false)
const articleModal = ref(false)
const articleId = ref(null)
const savingArticle = ref(false)
const articleForm = reactive({
  title: '', summary: '', content: '', author: '', categoryId: '', tags: ''
})

async function loadArticles (page = 1) {
  articlePage.value = page
  articlesLoading.value = true
  try {
    const res = await fetchAdminArticles({
      page, size: 10, keyword: articleKeyword.value.trim()
    })
    articles.value = res.list || []
    articleTotal.value = res.total || 0
    articlePages.value = res.pages || 1
  } catch (e) {
    toast.error(e.message || '文章加载失败')
  } finally {
    articlesLoading.value = false
  }
}

function openArticleModal () {
  articleId.value = null
  Object.assign(articleForm, {
    title: '', summary: '', content: '', author: userName.value, categoryId: '', tags: ''
  })
  articleModal.value = true
}

async function editArticle (id) {
  try {
    const data = await fetchAdminArticle(id)
    articleId.value = id
    Object.assign(articleForm, {
      title: data.title || '',
      summary: data.summary || '',
      content: data.content || '',
      author: data.author || '',
      categoryId: data.categoryId == null ? '' : String(data.categoryId),
      tags: data.tags || ''
    })
    articleModal.value = true
  } catch (e) {
    toast.error(e.message || '文章详情加载失败')
  }
}

function closeArticleModal () {
  if (!savingArticle.value) articleModal.value = false
}

async function saveArticle () {
  if (articleForm.title.trim().length < 2) {
    toast.error('文章标题至少需要 2 个字符')
    return
  }
  savingArticle.value = true
  const payload = {
    ...articleForm,
    categoryId: articleForm.categoryId ? Number(articleForm.categoryId) : null
  }
  try {
    if (articleId.value) await updateAdminArticle(articleId.value, payload)
    else await createAdminArticle(payload)
    toast.success(articleId.value ? '文章已更新' : '文章已创建')
    articleModal.value = false
    await Promise.all([loadArticles(articleId.value ? articlePage.value : 1), loadStats()])
  } catch (e) {
    toast.error(e.message || '保存失败')
  } finally {
    savingArticle.value = false
  }
}

async function removeArticle (item) {
  if (!window.confirm(`确定删除《${item.title}》吗？此操作不可撤销。`)) return
  try {
    await deleteAdminArticle(item.id)
    toast.success('文章已删除')
    await Promise.all([loadArticles(articlePage.value), loadStats()])
  } catch (e) {
    toast.error(e.message || '删除失败')
  }
}

// ---------- 分类 / 标签 ----------
const categories = ref([])
const tags = ref([])
const taxModal = ref(false)
const taxType = ref('category')
const taxId = ref(null)
const savingTax = ref(false)
const taxForm = reactive({ name: '', slug: '', categoryId: '', sort: 0 })

async function loadTaxonomy () {
  try {
    const [catList, tagList] = await Promise.all([fetchAdminCategories(), fetchAdminTags()])
    categories.value = catList || []
    tags.value = tagList || []
  } catch (e) {
    toast.error(e.message || '分类标签加载失败')
  }
}

function openTaxModal (type, row = null) {
  taxType.value = type
  taxId.value = row ? row.id : null
  Object.assign(taxForm, {
    name: row ? row.name : '',
    slug: row ? row.slug : '',
    categoryId: row && row.categoryId != null ? String(row.categoryId) : '',
    sort: row && row.sort != null ? row.sort : 0
  })
  taxModal.value = true
}

function closeTaxModal () {
  if (!savingTax.value) taxModal.value = false
}

async function saveTax () {
  if (!taxForm.name) {
    toast.error('请输入名称')
    return
  }
  if (!/^[a-z0-9-]+$/.test(taxForm.slug)) {
    toast.error('Slug 只能包含小写字母、数字和连字符')
    return
  }
  savingTax.value = true
  try {
    if (taxType.value === 'category') {
      const payload = { name: taxForm.name, slug: taxForm.slug, sort: Number(taxForm.sort) || 0 }
      if (taxId.value) await updateAdminCategory(taxId.value, payload)
      else await createAdminCategory(payload)
    } else {
      const payload = {
        name: taxForm.name,
        slug: taxForm.slug,
        sort: Number(taxForm.sort) || 0,
        categoryId: taxForm.categoryId ? Number(taxForm.categoryId) : null
      }
      if (taxId.value) await updateAdminTag(taxId.value, payload)
      else await createAdminTag(payload)
    }
    toast.success('保存成功')
    taxModal.value = false
    await Promise.all([loadTaxonomy(), loadStats()])
  } catch (e) {
    toast.error(e.message || '保存失败')
  } finally {
    savingTax.value = false
  }
}

async function removeCategory (row) {
  if (!window.confirm(`确定删除分类「${row.name}」吗？`)) return
  try {
    await deleteAdminCategory(row.id)
    toast.success('分类已删除')
    await Promise.all([loadTaxonomy(), loadStats()])
  } catch (e) {
    toast.error(e.message || '删除失败')
  }
}

async function removeTag (row) {
  if (!window.confirm(`确定删除标签「${row.name}」吗？`)) return
  try {
    await deleteAdminTag(row.id)
    toast.success('标签已删除')
    await Promise.all([loadTaxonomy(), loadStats()])
  } catch (e) {
    toast.error(e.message || '删除失败')
  }
}

// ---------- 用户 ----------
const users = ref([])
const userKeyword = ref('')
const userPage = ref(1)
const userPages = ref(1)
const userTotal = ref(0)
const usersLoading = ref(false)

async function loadUsers (page = 1) {
  userPage.value = page
  usersLoading.value = true
  try {
    const res = await fetchAdminUsers({ page, size: 10, keyword: userKeyword.value.trim() })
    users.value = (res.list || []).map((row) => ({ ...row, _saving: false }))
    userTotal.value = res.total || 0
    userPages.value = res.pages || 1
  } catch (e) {
    toast.error(e.message || '用户加载失败')
  } finally {
    usersLoading.value = false
  }
}

async function togglePermission (row) {
  const next = row.permission === 0 ? 1 : 0
  row._saving = true
  try {
    await updateUserPermission(row.id, next)
    toast.success(next === 0 ? '已设为管理员' : '已设为默认用户')
    await Promise.all([loadUsers(userPage.value), loadStats()])
  } catch (e) {
    toast.error(e.message || '权限修改失败')
  } finally {
    row._saving = false
  }
}

function switchTab (key) {
  tab.value = key
  if (key === 'articles' && !articles.value.length) loadArticles(1)
  if (key === 'users' && !users.value.length) loadUsers(1)
}

onMounted(async () => {
  await Promise.all([loadStats(), loadArticles(1), loadTaxonomy(), loadUsers(1)])
})
</script>

<style scoped>
.admin {
  position: relative;
  z-index: 2;
  min-height: 100vh;
  padding: 0 22px 40px;
  color: var(--ink);
}
.admin__top {
  position: sticky;
  top: 12px;
  z-index: 20;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
  max-width: 1280px;
  min-height: 66px;
  margin: 0 auto;
  padding: 10px 18px;
  border: 1px solid rgba(255, 255, 255, .9);
  border-radius: 21px;
  background: rgba(255, 250, 252, .82);
  box-shadow: 0 20px 44px -32px rgba(129, 75, 115, .5);
  backdrop-filter: blur(22px) saturate(150%);
}
.admin__brand {
  display: flex;
  align-items: center;
  gap: 11px;
  border: 0;
  background: transparent;
  color: inherit;
  cursor: pointer;
}
.admin__mark {
  width: 31px;
  height: 31px;
  border-radius: 50% 0 50% 50%;
  background: linear-gradient(140deg, #fff, var(--sakura-300));
  box-shadow: 0 0 20px rgba(249, 116, 159, .7);
  transform: rotate(45deg);
}
.admin__brand-text { display: flex; flex-direction: column; align-items: flex-start; line-height: 1.25; }
.admin__brand-text b { font-family: var(--font-serif); font-size: 16px; letter-spacing: .1em; }
.admin__brand-text i { font-style: normal; font-size: 8px; letter-spacing: .18em; color: var(--faint); }
.admin__top-actions { display: flex; align-items: center; gap: 9px; }
.admin__who { display: flex; align-items: center; gap: 9px; margin-right: 6px; }
.admin__avatar,
.side-profile__avatar {
  display: grid;
  place-items: center;
  width: 34px;
  height: 34px;
  flex: none;
  border-radius: 50%;
  background: linear-gradient(135deg, var(--sakura-400), var(--sakura-600));
  color: #fff;
  font-size: 14px;
  font-weight: 700;
}
.admin__who > span:last-child { display: flex; flex-direction: column; line-height: 1.35; }
.admin__who b { font-size: 12.5px; }
.admin__who i { font-style: normal; font-size: 9px; color: var(--sakura-500); letter-spacing: .08em; }

.admin__layout {
  display: grid;
  grid-template-columns: 210px minmax(0, 1fr);
  gap: 22px;
  max-width: 1280px;
  margin: 22px auto 0;
}
.admin__side {
  position: sticky;
  top: 98px;
  align-self: start;
  padding: 18px 14px;
  border: 1px solid rgba(255, 255, 255, .78);
  border-radius: 23px;
  background: linear-gradient(160deg, rgba(255, 255, 255, .8), rgba(254, 239, 247, .66));
  box-shadow: 0 18px 40px -34px rgba(117, 69, 105, .6);
  backdrop-filter: blur(16px);
}
.side-profile { display: flex; align-items: center; gap: 10px; padding: 4px 5px 16px; border-bottom: 1px solid var(--line-soft); }
.side-profile__avatar { width: 39px; height: 39px; }
.side-profile div { display: flex; flex-direction: column; min-width: 0; }
.side-profile b { font-size: 13px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.side-profile span { margin-top: 3px; font-size: 10px; color: var(--muted); }
.side-nav { display: flex; flex-direction: column; gap: 5px; margin-top: 14px; }
.side-nav__item {
  display: flex;
  align-items: center;
  gap: 10px;
  width: 100%;
  min-height: 41px;
  padding: 0 11px;
  border: 1px solid transparent;
  border-radius: 12px;
  background: transparent;
  color: var(--muted);
  font: inherit;
  font-size: 12.5px;
  text-align: left;
  cursor: pointer;
  transition: .25s var(--ease);
}
.side-nav__glyph {
  display: grid;
  place-items: center;
  width: 23px;
  height: 23px;
  border-radius: 7px;
  background: rgba(255, 255, 255, .65);
  color: var(--sakura-500);
  font-family: var(--font-serif);
  font-size: 11px;
}
.side-nav__item i {
  margin-left: auto;
  font-style: normal;
  font-size: 9px;
  color: var(--sakura-500);
}
.side-nav__item:hover { color: var(--sakura-700); background: rgba(255, 255, 255, .55); }
.side-nav__item--on {
  color: var(--sakura-700);
  border-color: rgba(236, 181, 207, .5);
  background: linear-gradient(110deg, rgba(255, 255, 255, .95), rgba(252, 226, 239, .74));
  box-shadow: 0 8px 18px -16px rgba(198, 69, 112, .75);
}
.side-note { margin: 16px 5px 0; color: var(--faint); font-size: 9.5px; line-height: 1.7; }

.admin__main { min-width: 0; }
.panel-view { animation: adminRise .35s var(--ease) both; }
@keyframes adminRise { from { opacity: 0; transform: translateY(8px); } to { opacity: 1; transform: none; } }
.page-head {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 18px;
  margin: 8px 2px 20px;
}
.eyebrow { margin: 0 0 7px; color: var(--sakura-500); font-size: 9.5px; font-weight: 600; letter-spacing: .18em; }
.page-head h1 { margin: 0; font-family: var(--font-serif); font-size: 28px; font-weight: 600; letter-spacing: .05em; color: var(--ink); }
.page-head p:not(.eyebrow) { margin: 7px 0 0; color: var(--muted); font-size: 12px; line-height: 1.65; }
.page-head__date { padding-bottom: 3px; color: var(--faint); font-size: 10.5px; letter-spacing: .06em; white-space: nowrap; }

.primary-btn, .ghost-btn, .search-form button {
  min-height: 36px;
  border-radius: 11px;
  font: inherit;
  font-size: 12px;
  cursor: pointer;
  transition: .22s var(--ease);
}
.primary-btn {
  padding: 0 15px;
  border: 0;
  background: linear-gradient(120deg, var(--sakura-500), var(--sakura-600));
  color: #fff;
  box-shadow: 0 9px 20px -14px rgba(221, 62, 112, .85);
}
.primary-btn:hover { transform: translateY(-1px); box-shadow: 0 13px 24px -14px rgba(221, 62, 112, .9); }
.primary-btn:disabled { opacity: .6; cursor: wait; transform: none; }
.ghost-btn {
  padding: 0 12px;
  border: 1px solid rgba(220, 184, 211, .55);
  background: rgba(255, 255, 255, .6);
  color: var(--muted);
}
.ghost-btn:hover { color: var(--sakura-700); border-color: var(--sakura-300); background: #fff; }
.ghost-btn--danger { color: #b45667; }

.stat-grid { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 13px; }
.stat-card {
  position: relative;
  display: flex;
  flex-direction: column;
  min-height: 128px;
  padding: 18px;
  overflow: hidden;
  border: 1px solid rgba(224, 190, 215, .4);
  border-radius: 19px;
  background: linear-gradient(150deg, rgba(255, 255, 255, .92), rgba(253, 239, 247, .78));
  box-shadow: 0 13px 26px -25px rgba(117, 69, 105, .65);
}
.stat-card::after {
  content: '';
  position: absolute;
  right: -20px;
  bottom: -28px;
  width: 82px;
  height: 82px;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(230, 154, 187, .2), transparent 68%);
}
.stat-card__label { color: var(--muted); font-size: 11px; letter-spacing: .06em; }
.stat-card b { margin: 9px 0 auto; color: var(--sakura-700); font-family: var(--font-serif); font-size: 31px; font-weight: 600; font-variant-numeric: tabular-nums; }
.stat-card__hint { color: var(--faint); font-size: 9.5px; }
.stat-card--loading { animation: statPulse 1.4s ease infinite; }
@keyframes statPulse { 50% { opacity: .45; } }

.overview-grid { display: grid; grid-template-columns: minmax(0, 1.5fr) minmax(220px, .8fr); gap: 14px; margin-top: 15px; }
.soft-card {
  min-width: 0;
  padding: 18px;
  border: 1px solid rgba(255, 255, 255, .82);
  border-radius: 20px;
  background: rgba(255, 255, 255, .66);
  box-shadow: 0 16px 34px -32px rgba(112, 68, 100, .55);
  backdrop-filter: blur(12px);
}
.card-head { display: flex; align-items: center; justify-content: space-between; gap: 12px; margin-bottom: 12px; }
.card-head h2 { margin: 0; font-family: var(--font-serif); font-size: 15px; font-weight: 600; color: var(--ink); }
.card-head button { border: 0; background: transparent; color: var(--sakura-600); font: inherit; font-size: 10.5px; cursor: pointer; }
.recent-list { display: flex; flex-direction: column; }
.recent-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 11px 5px;
  border: 0;
  border-top: 1px solid var(--line-soft);
  background: transparent;
  color: inherit;
  font: inherit;
  text-align: left;
  cursor: pointer;
}
.recent-row:hover b { color: var(--sakura-700); }
.recent-row__main { display: flex; flex-direction: column; min-width: 0; gap: 4px; }
.recent-row__main b { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: 12px; font-weight: 500; transition: color .2s; }
.recent-row__main i { color: var(--faint); font-size: 9.5px; font-style: normal; }
.recent-row__views { flex: none; color: var(--sakura-500); font-size: 9.5px; }
.quick-card { display: flex; flex-direction: column; gap: 8px; }
.quick-card .card-head { margin-bottom: 4px; }
.quick-card > button {
  display: flex;
  flex-direction: column;
  gap: 3px;
  padding: 11px 12px;
  border: 1px solid var(--line-soft);
  border-radius: 12px;
  background: rgba(255, 255, 255, .55);
  color: var(--ink);
  font: inherit;
  text-align: left;
  cursor: pointer;
  transition: .22s;
}
.quick-card > button:hover { transform: translateY(-2px); border-color: var(--sakura-200); background: #fff; }
.quick-card > button span { font-size: 11.5px; }
.quick-card > button i { color: var(--faint); font-size: 9.5px; font-style: normal; }

.toolbar { display: flex; align-items: center; justify-content: space-between; gap: 14px; margin-bottom: 12px; }
.search-form { display: flex; align-items: center; gap: 7px; width: min(430px, 100%); }
.search-form input {
  flex: 1;
  min-width: 0;
  height: 37px;
  padding: 0 13px;
  border: 1px solid rgba(219, 180, 205, .62);
  border-radius: 11px;
  outline: 0;
  background: rgba(255, 255, 255, .78);
  color: var(--ink);
  font: inherit;
  font-size: 12px;
}
.search-form input:focus { border-color: var(--sakura-400); box-shadow: 0 0 0 3px rgba(235, 157, 188, .16); }
.search-form button { padding: 0 14px; border: 1px solid rgba(220, 184, 211, .62); background: rgba(255, 255, 255, .7); color: var(--sakura-700); }
.toolbar__count { color: var(--faint); font-size: 10.5px; }

.table-card {
  overflow: hidden;
  border: 1px solid rgba(255, 255, 255, .82);
  border-radius: 20px;
  background: rgba(255, 255, 255, .7);
  box-shadow: 0 18px 38px -34px rgba(112, 68, 100, .56);
}
.table-scroll { overflow-x: auto; }
table { width: 100%; min-width: 720px; border-collapse: collapse; }
th {
  padding: 12px 15px;
  border-bottom: 1px solid var(--line-soft);
  background: rgba(252, 240, 247, .7);
  color: var(--muted);
  font-size: 10px;
  font-weight: 500;
  letter-spacing: .07em;
  text-align: left;
  white-space: nowrap;
}
td { padding: 13px 15px; border-bottom: 1px solid rgba(237, 221, 232, .6); font-size: 11.5px; vertical-align: middle; }
tbody tr:last-child td { border-bottom: 0; }
tbody tr:hover { background: rgba(255, 249, 252, .72); }
.table-title { display: block; max-width: 340px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: 12.5px; font-weight: 600; }
td small { display: block; max-width: 340px; margin-top: 4px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; color: var(--faint); font-size: 9.5px; }
.muted { color: var(--faint); font-size: 10.5px; white-space: nowrap; }
.pill { display: inline-block; padding: 4px 8px; border-radius: 999px; background: var(--sakura-50); color: var(--sakura-700); font-size: 9.5px; white-space: nowrap; }
.row-actions { display: flex; align-items: center; gap: 8px; white-space: nowrap; }
.row-actions button, .permission-btn { border: 0; background: transparent; color: var(--sakura-600); font: inherit; font-size: 10.5px; cursor: pointer; padding: 3px 0; }
.row-actions button:hover, .permission-btn:hover { color: var(--sakura-700); text-decoration: underline; }
.row-actions .danger-text { color: #b86778; }
.permission-btn { padding: 5px 9px; border: 1px solid rgba(218, 168, 196, .65); border-radius: 8px; background: rgba(255, 255, 255, .6); }
.permission-btn:disabled { opacity: .5; cursor: wait; }
.permission-pill { display: inline-block; padding: 4px 9px; border-radius: 999px; background: #f1eff7; color: #7d7499; font-size: 9.5px; }
.permission-pill--admin { background: linear-gradient(110deg, rgba(252, 217, 233, .8), rgba(235, 218, 255, .8)); color: var(--sakura-700); }
.self-pill { margin-left: 7px; padding: 2px 6px; border-radius: 5px; background: var(--sakura-100); color: var(--sakura-600); font-size: 8.5px; }
.loading-box, .empty-box { display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 12px; min-height: 200px; color: var(--faint); font-size: 12px; }

.pager { display: flex; align-items: center; justify-content: flex-end; gap: 10px; margin-top: 14px; color: var(--muted); font-size: 10.5px; }
.pager button { min-width: 58px; height: 31px; border: 1px solid rgba(218, 179, 203, .6); border-radius: 9px; background: rgba(255, 255, 255, .65); color: var(--muted); font: inherit; font-size: 10.5px; cursor: pointer; }
.pager button:hover:not(:disabled) { color: var(--sakura-700); border-color: var(--sakura-300); background: #fff; }
.pager button:disabled { opacity: .38; cursor: not-allowed; }

.taxonomy-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 14px; }
.mini-list { display: flex; flex-direction: column; }
.mini-row { display: flex; align-items: center; justify-content: space-between; gap: 12px; padding: 10px 4px; border-top: 1px solid var(--line-soft); }
.mini-row > span { display: flex; flex-direction: column; min-width: 0; gap: 3px; }
.mini-row b { font-size: 12px; font-weight: 500; }
.mini-row i { color: var(--faint); font-size: 9.5px; font-style: normal; }
.empty-mini { padding: 30px 8px; color: var(--faint); font-size: 11px; text-align: center; }

.modal-mask {
  position: fixed;
  inset: 0;
  z-index: 80;
  display: grid;
  place-items: center;
  padding: 24px;
  background: rgba(80, 48, 70, .24);
  backdrop-filter: blur(8px);
}
.modal {
  width: min(760px, 100%);
  max-height: calc(100vh - 48px);
  overflow: auto;
  border: 1px solid rgba(255, 255, 255, .9);
  border-radius: 24px;
  background: linear-gradient(155deg, #fffafd, #fdf1f7);
  box-shadow: 0 34px 80px -40px rgba(84, 48, 74, .6);
}
.modal--small { width: min(430px, 100%); }
.modal__head { display: flex; align-items: flex-start; justify-content: space-between; gap: 18px; padding: 22px 24px 14px; border-bottom: 1px solid var(--line-soft); }
.modal__head h2 { margin: 0; font-family: var(--font-serif); font-size: 21px; font-weight: 600; }
.modal__close { width: 31px; height: 31px; border: 1px solid var(--line-soft); border-radius: 50%; background: rgba(255, 255, 255, .64); color: var(--muted); font-size: 20px; line-height: 1; cursor: pointer; }
.modal__body { display: flex; flex-direction: column; gap: 13px; padding: 18px 24px 22px; }
.form-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 12px; }
.form-row { display: flex; flex-direction: column; gap: 6px; }
.form-row > span { color: var(--muted); font-size: 10px; font-weight: 500; letter-spacing: .04em; }
.form-row input, .form-row select, .form-row textarea {
  width: 100%;
  border: 1px solid rgba(218, 181, 204, .65);
  border-radius: 10px;
  outline: 0;
  background: rgba(255, 255, 255, .78);
  color: var(--ink);
  font: inherit;
  font-size: 12px;
}
.form-row input, .form-row select { height: 38px; padding: 0 11px; }
.form-row textarea { padding: 10px 11px; line-height: 1.75; resize: vertical; }
.form-row input:focus, .form-row select:focus, .form-row textarea:focus { border-color: var(--sakura-400); box-shadow: 0 0 0 3px rgba(234, 157, 188, .14); }
.modal__foot { display: flex; justify-content: flex-end; gap: 9px; margin-top: 3px; }
.fade-enter-active, .fade-leave-active { transition: opacity .22s; }
.fade-enter-active .modal, .fade-leave-active .modal { transition: transform .24s var(--ease); }
.fade-enter-from, .fade-leave-to { opacity: 0; }
.fade-enter-from .modal, .fade-leave-to .modal { transform: translateY(12px) scale(.98); }

@media (max-width: 1080px) {
  .stat-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
  .overview-grid { grid-template-columns: 1fr; }
}
@media (max-width: 900px) {
  .admin { padding: 0 12px 30px; }
  .admin__layout { grid-template-columns: 1fr; gap: 12px; }
  .admin__side { position: static; padding: 12px; border-radius: 18px; }
  .side-profile, .side-note { display: none; }
  .side-nav { flex-direction: row; flex-wrap: wrap; gap: 5px; margin: 0; }
  .side-nav__item { width: auto; flex: 1 1 120px; min-height: 37px; padding: 0 9px; }
  .side-nav__glyph { width: 21px; height: 21px; }
  .admin__who { display: none; }
  .taxonomy-grid { grid-template-columns: 1fr; }
}
@media (max-width: 640px) {
  .admin__top { top: 8px; min-height: 58px; padding: 8px 11px; }
  .admin__brand-text i { display: none; }
  .admin__top-actions .ghost-btn { padding: 0 9px; font-size: 10px; }
  .ghost-btn--danger { display: none; }
  .page-head { align-items: flex-start; flex-direction: column; gap: 10px; }
  .page-head__date { display: none; }
  .stat-grid { gap: 9px; }
  .stat-card { min-height: 108px; padding: 14px; }
  .stat-card b { font-size: 26px; }
  .toolbar { align-items: stretch; flex-direction: column; }
  .search-form { width: 100%; }
  .form-grid { grid-template-columns: 1fr; }
  .modal-mask { padding: 10px; }
  .modal { max-height: calc(100vh - 20px); border-radius: 19px; }
  .modal__head, .modal__body { padding-left: 17px; padding-right: 17px; }
  .pager { justify-content: center; }
}
</style>
