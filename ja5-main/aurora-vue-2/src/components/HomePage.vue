<template>
  <div class="home">
    <!-- ============ 顶部导航 ============ -->
    <SiteNav :user="user" active="home" @go="$emit('navigate', $event)" @logout="$emit('logout')" />

    <main class="page">
      <div class="masthead" aria-hidden="true">
        <span>SAKURA NOTE</span>
        <span>春日手记 · 技术与生活</span>
        <span>VOL. 01 / 2026</span>
      </div>

      <!-- 首屏：文字 + 今日头条 -->
      <section class="hero">
        <div class="hero__copy">
          <p class="hero__eyebrow">
            <i class="hero__pulse" aria-hidden="true"></i>
            {{ todayText }} · {{ greeting.text }}，{{ userName }}
          </p>

          <h1 class="hero__title">
            把灵感，<br><span class="hero__accent">夹进樱瓣里。</span>
          </h1>

          <p class="hero__lede">
            <template v-if="overview">
              这里收藏着 <b>{{ fmtNum(overview.articles) }}</b> 篇手记，
              用 <b>{{ fmtNum(overview.tags) }}</b> 枚标签牵起彼此<template v-if="overview.totalViews">，
              已经被读过 <b>{{ fmtNum(overview.totalViews) }}</b> 次</template>。
            </template>
            <template v-else>在这里，找到值得安静读完的文字与灵感。</template>
            不追赶信息的洪流，只在花落时读一点真正有用的东西。
          </p>

          <div class="hero__search">
            <SearchBar
              v-model="keyword"
              placeholder="搜索标题、标签、正文…"
              @search="onSearch"
              @clear="onClear"
              @pick="onPick"
            />
          </div>

          <div class="hero__actions">
            <button class="hero__primary" type="button" @click="scrollToFeed">
              开始阅读
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
                <path d="M5 12h14M13 6l6 6-6 6" />
              </svg>
            </button>
            <button class="hero__random" type="button" :disabled="!pool.length" @click="goRandom">
              <span aria-hidden="true">✿</span>随风飘一篇
            </button>
          </div>

          <p class="hero__hint" aria-hidden="true"><span></span>移动指针，邀一阵春风<span></span></p>
        </div>

        <!-- 今日头条：封面铺满整卡，文字压在底部渐变上 -->
        <article
          v-if="leadArticle"
          class="lead"
          tabindex="0"
          role="button"
          :aria-label="'阅读头条：' + leadArticle.title"
          @click="$emit('open-article', leadArticle.id)"
          @keydown.enter="$emit('open-article', leadArticle.id)"
        >
          <div class="lead__cover" :style="{ backgroundImage: 'url(' + coverAt(0) + ')' }">
            <span class="lead__scrim"></span>
            <span class="lead__badge">
              <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                <path d="M12 3.2c1.2 2.4 2.6 3.9 4.2 6.1 1.6 2.2 1.9 4.6.4 6.4-1.4 1.6-3.6 2-5.4 1.4-2.6-.9-3.9-3.3-3.2-5.9.6-2.3 2.6-3.9 3.1-6 .2-.9.4-1.5.9-2z" />
              </svg>
              今日头条
            </span>

            <div class="lead__body">
              <button
                v-if="leadArticle.category"
                class="lead__cat"
                type="button"
                @click.stop="onOpenCategory(leadArticle.categoryId)"
              >{{ leadArticle.category }}</button>
              <h2 class="lead__title">{{ leadArticle.title }}</h2>
              <p class="lead__sum">{{ leadArticle.summary }}</p>
              <div class="lead__foot">
                <span class="lead__meta">
                  <template v-if="leadArticle.author">{{ leadArticle.author }}</template>
                  <template v-if="leadArticle.minutes"> · 约 {{ leadArticle.minutes }} 分钟</template>
                  · {{ leadArticle.views }} 次浏览
                </span>
                <span class="lead__go">阅读全文
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
                       stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                    <path d="M5 12h13M13 6l6 6-6 6" />
                  </svg>
                </span>
              </div>
            </div>

            <button
              v-if="showFavBtn"
              class="lead__fav"
              :class="{ 'lead__fav--on': favIds.has(leadArticle.id) }"
              type="button"
              :title="favIds.has(leadArticle.id) ? '取消收藏' : '收藏'"
              :aria-label="favIds.has(leadArticle.id) ? '取消收藏' : '收藏'"
              @click.stop="toggleFavorite(leadArticle)"
            >
              <svg viewBox="0 0 24 24" :fill="favIds.has(leadArticle.id) ? 'currentColor' : 'none'"
                   stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
                <path d="M12 3.5l2.6 5.4 5.9.8-4.3 4.1 1 5.8-5.2-2.8-5.2 2.8 1-5.8L3.5 9.7l5.9-.8z" />
              </svg>
            </button>
          </div>
        </article>
      </section>

      <!-- 小说阅读导航：四部精选小说，外链集中在 config/novelLinks.js 配置 -->
      <NovelNavigation />

      <!-- ============================================================
           吸顶筛选条：分类 / 排序 / 计数，滚到哪儿都能换条件
           ============================================================ -->
      <div ref="filterSentinel" class="stick-sentinel" aria-hidden="true"></div>

      <div class="filter" :class="{ 'filter--stuck': stuck }">
        <nav class="filter__cats" aria-label="分类导航">
          <button
            class="cat"
            :class="{ 'cat--on': !categoryId && !tagId }"
            type="button"
            @click="selectCategory(null)"
          >
            全部<i>{{ grandTotal }}</i>
          </button>
          <button
            v-for="c in categories"
            :key="c.id"
            class="cat"
            :class="{ 'cat--on': categoryId === c.id }"
            type="button"
            @click="selectCategory(c)"
          >
            {{ c.name }}<i>{{ c.articleCount }}</i>
          </button>
        </nav>

        <div class="filter__right">
          <span v-if="!loading && !error" class="filter__count">{{ total }} 条</span>
          <div class="seg" role="group" aria-label="排序方式">
            <button
              class="seg__btn"
              :class="{ 'seg__btn--on': sort === 'hot' }"
              type="button"
              @click="changeSort('hot')"
            >热度</button>
            <button
              class="seg__btn"
              :class="{ 'seg__btn--on': sort === 'new' }"
              type="button"
              @click="changeSort('new')"
            >最新</button>
          </div>
        </div>
      </div>

      <!-- 二级标签：选中分类后才展开 -->
      <div v-if="currentCategory && currentCategory.tags.length" class="subtags">
        <button
          class="subtag"
          :class="{ 'subtag--on': !tagId }"
          type="button"
          @click="selectTag(null)"
        >不限</button>
        <button
          v-for="t in currentCategory.tags"
          :key="t.id"
          class="subtag"
          :class="{ 'subtag--on': tagId === t.id }"
          type="button"
          @click="selectTag(t)"
        >{{ t.name }}</button>
      </div>

      <!-- ============================================================
           主体：内容流 + 侧栏
           ============================================================ -->
      <div class="board">
        <div class="board__main">
          <!-- ---------- 继续阅读（仅登录且读过文章） ---------- -->
          <section v-if="recent.length" class="block">
            <div class="block__head">
              <h2>继续阅读</h2>
              <span class="block__sub">最近读过 · 花签还夹在原处</span>
            </div>
            <div class="recent">
              <button
                v-for="r in recent"
                :key="r.id"
                class="recent__item"
                type="button"
                @click="$emit('open-article', r.id)"
              >
                <span class="recent__top">
                  <span class="recent__time">{{ relTime(r.viewedAt) }}</span>
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9"
                       stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                    <path d="M5 12h13M13 6l6 6-6 6" />
                  </svg>
                </span>
                <span class="recent__title">{{ r.title }}</span>
              </button>
            </div>
          </section>

          <!-- ---------- 编辑精选：2 张封面卡 + 一张「浏览全部」入口 ---------- -->
          <section v-if="showPicks" class="block">
            <div class="block__head">
              <h2>落樱精选</h2>
              <span class="block__sub">CURATED STORIES · 按热度挑选</span>
            </div>
            <div class="picks">
              <PickCard
                v-for="(a, i) in picks"
                :key="a.id"
                :article="a"
                :cover-src="coverAt(i + 1)"
                :favorited="favIds.has(a.id)"
                :show-fav="showFavBtn"
                @open="$emit('open-article', $event)"
                @open-category="onOpenCategory"
                @toggle-fav="toggleFavorite"
              />
              <button class="picks__more" type="button" @click="scrollToFeed">
                <span class="picks__more-num">{{ restCount }}</span>
                <span class="picks__more-txt">篇待读<br>沿着花径往下走</span>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"
                     stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                  <path d="M12 5v14M6 13l6 6 6-6" />
                </svg>
              </button>
            </div>
          </section>

          <!-- ---------- 内容流 ---------- -->
          <section class="block block--feed" :class="{ 'block--feed-filtered': hasFilter }">
            <div class="block__head">
              <h2>{{ resultsTitle }}</h2>
              <span class="block__sub">{{ sort === 'hot' ? '按热度' : '按时间' }}</span>
            </div>

            <!-- 当前生效的筛选条件 -->
            <div v-if="hasFilter" class="crt">
              <span class="crt__label">筛选</span>
              <span v-if="query" class="crt__chip">
                “{{ query }}”
                <button type="button" aria-label="移除关键词" @click="removeKeyword">×</button>
              </span>
              <span v-if="currentCategory" class="crt__chip">
                {{ currentCategory.name }}
                <button type="button" aria-label="移除分类" @click="selectCategory(null)">×</button>
              </span>
              <span v-if="currentTag" class="crt__chip crt__chip--tag">
                {{ currentTag.name }}
                <button type="button" aria-label="移除标签" @click="selectTag(null)">×</button>
              </span>
              <button class="crt__clear" type="button" @click="resetAll">清空</button>
            </div>

            <!-- 骨架 -->
            <div v-if="loading && !list.length" class="skeleton">
              <div v-for="n in 4" :key="n" class="sk-row">
                <span class="sk-thumb"></span>
                <div class="sk-body">
                  <div class="sk-line sk-line--title"></div>
                  <div class="sk-line sk-line--sub"></div>
                  <div class="sk-line sk-line--meta"></div>
                </div>
              </div>
            </div>

            <!-- 首屏失败 -->
            <div v-else-if="error && !list.length" class="state state--error">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"
                   stroke-linecap="round" aria-hidden="true">
                <circle cx="12" cy="12" r="9" />
                <path d="M12 8v4.5M12 16h.01" />
              </svg>
              <p>{{ error }}</p>
              <button class="state__btn" type="button" @click="runSearch(1)">重试</button>
            </div>

            <!-- 空结果：给几个能点的出口，而不是只写「暂无内容」 -->
            <div v-else-if="!list.length" class="state">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"
                   stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                <circle cx="11" cy="11" r="7" />
                <path d="m20 20-3.6-3.6" />
                <path d="M8 11h6" />
              </svg>
              <p>没有找到符合条件的内容，像被风吹散的花瓣</p>
              <div v-if="hotTags.length" class="state__tips">
                <span>换个方向试试</span>
                <button
                  v-for="t in hotTags.slice(0, 4)"
                  :key="t.id"
                  class="chip"
                  type="button"
                  @click="selectTag(t)"
                >{{ t.name }}</button>
              </div>
              <button class="state__btn" type="button" @click="resetAll">查看全部内容</button>
            </div>

            <!-- 列表 -->
            <div v-else class="feed">
              <ArticleRow
                v-for="(a, i) in rows"
                :key="a.id"
                :article="a"
                :index="i + 1"
                :favorited="favIds.has(a.id)"
                :show-fav="showFavBtn"
                @open="$emit('open-article', $event)"
                @open-category="onOpenCategory"
                @open-tag="selectTagByName"
                @toggle-fav="toggleFavorite"
              />
            </div>

            <!-- 无限滚动哨兵 -->
            <div v-if="!loading && !error && list.length" ref="sentinelEl" class="feed-sentinel" aria-hidden="true"></div>

            <div v-if="!loading && error && list.length" class="feed-more feed-more--err">
              加载失败：<button type="button" class="feed-more__retry" @click="runSearch(page + 1, true)">重试</button>
            </div>

            <div v-if="error === '' && list.length && loading" class="feed-more">
              <span class="feed-more__spin"></span>正在加载更多…
            </div>

            <div v-else-if="!loading && !error && list.length && !hasMore" class="feed-more feed-more--end">
              <span class="feed-more__line"></span><span class="feed-more__petal" aria-hidden="true">✿</span>已经到底啦<span class="feed-more__line"></span>
            </div>
          </section>
        </div>

        <!-- ---------- 侧栏 ---------- -->
        <aside class="board__side" aria-label="站点侧栏">
          <section v-if="hotTags.length" class="side">
            <h3 class="side__title">标签花笺<span>{{ hotTags.length }} 枚</span></h3>
            <div class="feng">
              <button
                v-for="t in hotTags.slice(0, 10)"
                :key="t.id"
                class="feng__item"
                :class="{ 'feng__item--on': tagId === t.id }"
                type="button"
                :title="t.categoryName ? t.categoryName + ' · ' + t.articleCount + ' 篇' : t.articleCount + ' 篇'"
                @click="selectTag(t)"
              >
                <span class="feng__name">{{ t.name }}</span>
                <span class="feng__num">{{ t.articleCount || 0 }}</span>
              </button>
            </div>
            <button class="side__link" type="button" @click="$emit('navigate', 'discover')">
              去漫游页看看全部分类 →
            </button>
          </section>

          <section v-if="categories.length" class="side">
            <h3 class="side__title">分类分布<span>{{ categories.length }} 类</span></h3>
            <div class="dist">
              <button
                v-for="c in categories"
                :key="c.id"
                class="dist__row"
                :class="{ 'dist__row--on': categoryId === c.id }"
                type="button"
                @click="selectCategory(c)"
              >
                <span class="dist__name">{{ c.name }}</span>
                <span class="dist__bar"><i :style="{ width: distWidth(c.articleCount) }"></i></span>
                <span class="dist__num">{{ c.articleCount }}</span>
              </button>
            </div>
          </section>

          <section class="side">
            <h3 class="side__title">继续探索</h3>
            <div class="quick">
              <button
                v-for="q in quickLinks"
                :key="q.key"
                class="quick__item"
                type="button"
                @click="$emit('navigate', q.key)"
              >
                <span class="quick__dot" :style="{ background: q.color }"></span>
                {{ q.name }}
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"
                     stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                  <path d="M9 6l6 6-6 6" />
                </svg>
              </button>
            </div>
            <button class="dice" type="button" :disabled="!pool.length" @click="goRandom">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"
                   stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                <path d="M4 17h3.5l8-10H19" />
                <path d="m16.5 4 3 3-3 3" />
                <path d="M4 7h3.5l2.6 3.2" />
              </svg>
              随便逛逛
            </button>
          </section>

          <p class="side__foot">樱见 · SAKURA NOTE<br>把读过的文字，夹在春风翻动的书页里</p>
        </aside>
      </div>
    </main>

    <!-- 回到顶部 -->
    <Transition name="totop">
      <button v-if="showTop" class="totop" type="button" aria-label="回到顶部" @click="toTop">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9"
             stroke-linecap="round" stroke-linejoin="round">
          <path d="M12 19V5M6 11l6-6 6 6" />
        </svg>
      </button>
    </Transition>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted, onBeforeUnmount } from 'vue'
import SearchBar from './SearchBar.vue'
import SiteNav from './SiteNav.vue'
import PickCard from './PickCard.vue'
import NovelNavigation from './NovelNavigation.vue'
import ArticleRow from './ArticleRow.vue'
import TagCloud from './TagCloud.vue'
import { searchArticles, fetchCategories, fetchHotTags } from '../api/search'
import { fetchFavoriteIds, addFavorite, removeFavorite } from '../api/favorites'
import { fetchOverview } from '../api/stats'
import { fetchHistory } from '../api/history'
import { coverAt } from '../utils/cover'
import { toast } from '../composables/useToast'

const props = defineProps({
  user: { type: Object, default: null },
  /** 从其它页面跳转回来时携带的初始筛选条件（App 每次传入新对象触发更新） */
  initialFilter: { type: Object, default: null }
})
const emit = defineEmits(['navigate', 'open-article', 'logout', 'need-login'])

/* ---------- 用户信息 ---------- */
const userName = computed(() => (props.user && props.user.name) || '赏樱人')
const showFavBtn = computed(() => Boolean(props.user))

/* ---------- 检索状态 ---------- */
const PAGE_SIZE = 10

const keyword = ref('')      // 输入框当前内容（v-model）
const query = ref('')        // 已提交的关键词
const categoryId = ref(null) // 一级分类 id
const tagId = ref(null)      // 二级标签 id
const sort = ref('hot')      // hot | new

const list = ref([])
const total = ref(0)
const pages = ref(0)
const page = ref(1)
const loading = ref(false)
const error = ref('')

/* ---------- 分级分类数据 ---------- */
const categories = ref([])    // 分类树
const hotTags = ref([])       // 热门标签
const favIds = ref(new Set()) // 当前用户已收藏的文章 id 集合

/* ---------- 站点概览 & 侧栏 ---------- */
const overview = ref(null)  // { articles, categories, tags, totalViews, avgViews }
const pool = ref([])        // 全站文章池（最多 50 条，供头条与「随便逛逛」使用）
const recent = ref([])      // 最近阅读（登录用户）

/** 分布条基准：取分类里的最大文章数，最小保留 8% 让零散分类也看得见 */
const maxCategoryCount = computed(
  () => categories.value.reduce((m, c) => Math.max(m, c.articleCount || 0), 0) || 1
)
function distWidth (count) {
  return Math.max(8, Math.round(((count || 0) / maxCategoryCount.value) * 100)) + '%'
}

/** 问候语：按本地时间切换，badge 用英文单词保持原有的设计语言 */
const greeting = computed(() => {
  const h = new Date().getHours()
  if (h < 5) return { text: '夜深了', badge: 'NIGHT' }
  if (h < 9) return { text: '早上好', badge: 'MORNING' }
  if (h < 12) return { text: '上午好', badge: 'FORENOON' }
  if (h < 14) return { text: '中午好', badge: 'NOON' }
  if (h < 18) return { text: '下午好', badge: 'AFTERNOON' }
  return { text: '晚上好', badge: 'EVENING' }
})

/** 今天几号：手写中文格式，避免 toLocaleDateString 各环境输出不一致 */
const todayText = computed(() => {
  const d = new Date()
  const week = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'][d.getDay()]
  return `${d.getMonth() + 1} 月 ${d.getDate()} 日 · ${week}`
})

/** 数字缩写：一万以上用「万」，让数据在窄容器里也能放得下 */
function fmtNum (n) {
  const v = Number(n) || 0
  if (v < 10000) return String(v)
  return (v / 10000).toFixed(v >= 100000 ? 0 : 1) + ' 万'
}

/** 「x 分钟前 / x 小时前 / x 天前 / 日期」 */
function relTime (v) {
  if (!v) return ''
  const t = new Date(String(v).replace(' ', 'T')).getTime()
  if (Number.isNaN(t)) return String(v).slice(0, 10)
  const diff = Date.now() - t
  if (diff < 0) return '刚刚'
  const min = Math.floor(diff / 60000)
  if (min < 1) return '刚刚'
  if (min < 60) return `${min} 分钟前`
  const h = Math.floor(min / 60)
  if (h < 24) return `${h} 小时前`
  const d = Math.floor(h / 24)
  if (d < 30) return `${d} 天前`
  return String(v).slice(0, 10)
}

/** 随便逛逛：从全站文章池里随机打开一篇 */
function goRandom () {
  if (!pool.value.length) return
  const pick = pool.value[Math.floor(Math.random() * pool.value.length)]
  if (pick) emit('open-article', pick.id)
}

/** 侧栏快捷入口：key 与 SiteNav 的导航键保持一致 */
const quickLinks = [
  { key: 'discover', name: '漫游', color: 'var(--sakura-400)' },
  { key: 'game', name: '花瓣贪吃蛇', color: 'var(--sky-500)' },
  { key: 'favorites', name: '我的书签', color: 'var(--leaf-500)' },
  { key: 'profile', name: '个人中心', color: 'var(--gold-500)' }
]

/* ---------- 派生状态 ---------- */
const currentCategory = computed(() => categories.value.find((c) => c.id === categoryId.value) || null)

/** 当前选中的二级标签对象（先从当前分类里找，再退到热门标签） */
const currentTag = computed(() => {
  const inCat = currentCategory.value && currentCategory.value.tags.find((t) => t.id === tagId.value)
  if (inCat) return inCat
  return hotTags.value.find((t) => t.id === tagId.value) || null
})

/** 全部文章总数（各分类文章数之和，用于「全部」标签的计数） */
const grandTotal = computed(() => categories.value.reduce((s, c) => s + (c.articleCount || 0), 0))

const hasFilter = computed(() => Boolean(query.value || categoryId.value || tagId.value))

/**
 * 首屏头条：优先用全站最热的一篇（pool 已按热度倒序），
 * 文章池还没回来时退到当前列表第一条，保证首屏右侧不空着。
 */
const leadArticle = computed(() => pool.value[0] || list.value[0] || null)

/**
 * 是否拆成「精选 + 列表」。
 * 只在默认推荐视图且内容够多时拆：搜索/筛选结果每条命中项地位相同，
 * 单独拎几条出来当精选会误导用户。
 */
const showPicks = computed(() => !hasFilter.value && list.value.length > 4)

/**
 * 精选卡：从列表里排除已上头条的那篇，取前 2。
 * 之前头条与精选第一条取的是同一批数据，首屏会出现两遍同一篇文章。
 */
const picks = computed(() => {
  if (!showPicks.value) return []
  const leadId = leadArticle.value && leadArticle.value.id
  return list.value.filter((a) => a.id !== leadId).slice(0, 2)
})

/** 列表：默认视图去掉「头条 + 精选」已经在首屏出现过的条目，避免重复 */
const rows = computed(() => {
  if (!showPicks.value) return list.value
  const shown = new Set(picks.value.map((a) => a.id))
  const leadId = leadArticle.value && leadArticle.value.id
  if (leadId != null) shown.add(leadId)
  return list.value.filter((a) => !shown.has(a.id))
})

/** 「还有 N 篇」用的剩余数量 */
const restCount = computed(() => Math.max((total.value || list.value.length) - 1 - picks.value.length, 0))

/** 结果区标题 */
const resultsTitle = computed(() => {
  if (query.value) return `“${query.value}” 的结果`
  if (activeFilterText.value) return activeFilterText.value
  return sort.value === 'new' ? '最新发布' : '全部内容'
})

/** 没有关键词但有筛选条件时，用文字描述当前条件 */
const activeFilterText = computed(() => {
  if (currentTag.value) {
    return currentCategory.value
      ? `${currentCategory.value.name} · ${currentTag.value.name}`
      : currentTag.value.name
  }
  if (currentCategory.value) return currentCategory.value.name
  return ''
})

/* ---------- 主流程 ---------- */

/** 发起请求。p 为目标页码；append=true 时把结果追加到已有列表（无限滚动），否则整体替换 */
async function runSearch (p = 1, append = false) {
  loading.value = true
  error.value = ''

  try {
    const res = await searchArticles(query.value, {
      categoryId: categoryId.value,
      tagId: tagId.value,
      sort: sort.value,
      page: p,
      size: PAGE_SIZE
    })
    const items = (res && res.list) || []
    // 追加模式下去重，防止并发触发导致同一条文章出现两次
    list.value = append
      ? list.value.concat(items.filter((it) => !list.value.some((x) => x.id === it.id)))
      : items
    total.value = (res && res.total) || 0
    pages.value = (res && res.pages) || 0
    page.value = (res && res.page) || p
  } catch (e) {
    if (!append) {
      list.value = []
      total.value = 0
      pages.value = 0
    }
    error.value = (e && e.message) || '搜索失败，请稍后再试'
  } finally {
    loading.value = false
  }
}

/* ---------- 无限滚动（视频网站式下拉浏览） ---------- */
const sentinelEl = ref(null)   // 列表末尾的哨兵元素
let observer = null

/** 是否还有更多内容可加载 */
const hasMore = computed(() => pages.value > 0 && page.value < pages.value)

/** 滚到底附近时自动加载下一页 */
function loadMore () {
  if (loading.value || !hasMore.value || error.value) return
  runSearch(page.value + 1, true)
}

/** 建立滚动哨兵监听（列表结构变化时重建） */
function setupObserver () {
  if (observer) { observer.disconnect(); observer = null }
  if (!sentinelEl.value || typeof IntersectionObserver === 'undefined') return
  observer = new IntersectionObserver((entries) => {
    if (entries.some((e) => e.isIntersecting)) loadMore()
  }, { rootMargin: '320px 0px' })
  observer.observe(sentinelEl.value)
}

watch(sentinelEl, (el) => { if (el) setupObserver() })

/* ---------- 吸顶筛选条 & 回到顶部 ---------- */
const filterSentinel = ref(null)
const stuck = ref(false)
const showTop = ref(false)
let stickObserver = null

/** 页面滚动位置：这站的滚动容器被 body 的 overflow 传播到了视口，三种取值兜底 */
function scrollTop () {
  return window.scrollY || document.documentElement.scrollTop || document.body.scrollTop || 0
}

function onScroll () {
  showTop.value = scrollTop() > 620
}

function toTop () {
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

/** 「还有 N 篇」：滚到内容流起点（预留吸顶条高度） */
function scrollToFeed () {
  const el = document.querySelector('.block--feed')
  if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' })
}

/* ---------- 交互 ---------- */

/** 搜索框提交 */
function onSearch (kw) {
  const k = (kw || '').trim()
  keyword.value = k
  query.value = k
  runSearch(1)
  scrollToFeed()
}

/** 搜索建议选中：标签 -> 按标签筛选；文章标题 -> 按关键词搜索 */
function onPick (item) {
  if (item && item.type === 'tag') {
    selectTagByName(item.text)
  } else {
    onSearch(item && item.text)
  }
}

/** 清空搜索框 -> 保留分类筛选，仅去掉关键词 */
function onClear () {
  keyword.value = ''
  query.value = ''
  runSearch(1)
}

/** 选择一级分类：切换分类时清掉二级标签（避免标签不属于该分类） */
function selectCategory (c) {
  const next = c ? c.id : null
  if (categoryId.value !== next) tagId.value = null
  categoryId.value = next
  runSearch(1)
}

/** 卡片上的分类按钮：直接按该分类筛选 */
function onOpenCategory (categoryIdVal) {
  const c = categories.value.find((x) => x.id === categoryIdVal)
  if (c) selectCategory(c)
}

/** 选择二级标签：标签自带所属分类时，同步切到该分类下 */
function selectTag (t) {
  if (!t) {
    tagId.value = null
    runSearch(1)
    return
  }
  const nextTag = tagId.value === t.id ? null : t.id
  tagId.value = nextTag

  // 从热门标签 / 标签云点进来时，若该标签属于某个分类而当前未选中它，自动补上分类，
  // 这样二级导航会展开到正确的位置，用户能看清自己在哪一层。
  if (nextTag && t.categoryId && categoryId.value !== t.categoryId) {
    categoryId.value = t.categoryId
  }
  runSearch(1)
}

/** 按标签名选中（点击结果卡片上的标签 / 搜索建议里的标签时用） */
function selectTagByName (name) {
  let t = null
  for (const c of categories.value) {
    const hit = c.tags.find((x) => x.name === name)
    if (hit) { t = hit; break }
  }
  if (!t) t = hotTags.value.find((x) => x.name === name)
  if (t) selectTag(t)
  else onSearch(name)   // 兜底：没匹配到标签，就当关键词搜
}

/** 切换排序 */
function changeSort (s) {
  if (sort.value === s) return
  sort.value = s
  runSearch(1)
}

/** 移除关键词筛选 */
function removeKeyword () {
  keyword.value = ''
  query.value = ''
  runSearch(1)
}

/** 回到初始状态：无关键词、无分类、无标签、热度排序 */
function resetAll () {
  keyword.value = ''
  query.value = ''
  categoryId.value = null
  tagId.value = null
  sort.value = 'hot'
  runSearch(1)
}

/* ---------- 收藏 ---------- */

/** 加载当前用户收藏 id 集合（未登录跳过） */
async function loadFavIds () {
  if (!props.user) {
    favIds.value = new Set()
    return
  }
  try {
    const ids = await fetchFavoriteIds()
    favIds.value = new Set(ids)
  } catch (_) {
    favIds.value = new Set()
  }
}

/** 卡片收藏 / 取消收藏（未登录由 App 引导去登录） */
async function toggleFavorite (article) {
  if (!props.user) return
  const on = favIds.value.has(article.id)
  const next = new Set(favIds.value)
  if (on) next.delete(article.id)
  else next.add(article.id)
  favIds.value = next
  try {
    if (on) await removeFavorite(article.id)
    else await addFavorite(article.id)
    toast.success(on ? '已取消收藏' : '已收进书签')
  } catch (e) {
    const rollback = new Set(favIds.value)
    if (on) rollback.add(article.id)
    else rollback.delete(article.id)
    favIds.value = rollback
    toast.error((e && e.message) || '操作失败，请稍后再试')
  }
}

/* ---------- 最近阅读 ---------- */
async function loadRecent () {
  if (!props.user) {
    recent.value = []
    return
  }
  try {
    const res = await fetchHistory({ page: 1, size: 3 })
    recent.value = (res && res.list) || []
  } catch (_) {
    recent.value = []
  }
}

/* ---------- 跨页面初始筛选 ---------- */
watch(() => props.initialFilter, (f) => {
  if (!f) return
  keyword.value = ''
  query.value = ''
  categoryId.value = f.categoryId || null
  if (f.tagName) {
    const t = findTagByName(f.tagName)
    tagId.value = t ? t.id : null
  } else {
    tagId.value = f.tagId || null
  }
  sort.value = f.sort || 'hot'
  runSearch(1)
})

function findTagByName (name) {
  for (const c of categories.value) {
    const hit = c.tags.find((x) => x.name === name)
    if (hit) return hit
  }
  return hotTags.value.find((x) => x.name === name) || null
}

/* ---------- 初始化 ---------- */
onMounted(async () => {
  // 分类树 / 热门标签用于渲染导航，失败不阻塞内容列表
  try {
    const [cats, tags] = await Promise.all([fetchCategories(), fetchHotTags()])
    categories.value = cats || []
    hotTags.value = tags || []
  } catch (e) {
    categories.value = []
    hotTags.value = []
  }
  await loadFavIds()
  loadRecent()

  // 概览与文章池：与主列表并行拉取，失败时静默降级（页面其余部分照常可用）
  fetchOverview()
    .then((o) => { overview.value = o })
    .catch(() => { overview.value = null })
  searchArticles('', { sort: 'hot', page: 1, size: 50 })
    .then((res) => { pool.value = (res && res.list) || [] })
    .catch(() => { pool.value = [] })

  runSearch(1)

  window.addEventListener('scroll', onScroll, { passive: true })
  onScroll()

  // 筛选条离开原位（被吸住）时加底色，否则它会和后面的内容糊在一起
  if (filterSentinel.value && typeof IntersectionObserver !== 'undefined') {
    stickObserver = new IntersectionObserver(([e]) => {
      stuck.value = e.boundingClientRect.top < 92
    }, { threshold: [0, 1] })
    stickObserver.observe(filterSentinel.value)
  }
})

onBeforeUnmount(() => {
  if (observer) observer.disconnect()
  if (stickObserver) stickObserver.disconnect()
  window.removeEventListener('scroll', onScroll)
})
</script>

<style scoped>
/* ============================================================
   首页版式：樱花纸感 + 春日留白
   - 结构靠留白、樱粉发丝线与柔和投影，不堆叠玻璃卡片
   - 强调色只出现在「当前状态」与行动点
   ============================================================ */
.home {
  position: relative;
  z-index: 2;
  width: 100%;
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 24px 96px;
}

/* ============ 刊头 ============ */
.masthead {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 26px 2px 18px;
  border-bottom: 1px solid var(--line-soft);
  font-size: 10.5px;
  letter-spacing: .26em;
  text-transform: uppercase;
  color: var(--faint);
}
.masthead span:nth-child(2) {
  letter-spacing: .14em;
  color: var(--sakura-500);
  opacity: .85;
}

/* ============ 首屏 ============ */
.hero {
  position: relative;
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  grid-template-rows: minmax(430px, 1fr) auto;
  gap: 26px;
  align-items: center;
  min-height: calc(100svh - 140px);
  padding: 28px 0 34px;
}
.hero__copy {
  position: relative;
  align-self: center;
  width: min(780px, 100%);
  margin: 0 auto;
  padding: 34px 20px;
  text-align: center;
  background: radial-gradient(ellipse at center, rgba(155, 113, 162, .3), rgba(196, 157, 196, .18) 44%, transparent 72%);
}

.hero__eyebrow {
  display: inline-flex;
  align-items: center;
  gap: 9px;
  height: 30px;
  padding: 0 15px 0 12px;
  border-radius: 999px;
  background: rgba(255, 255, 255, .82);
  box-shadow: var(--gloss), inset 0 0 0 1px var(--sakura-100),
              0 6px 18px -14px rgba(197, 58, 100, .5);
  font-size: 12.5px;
  letter-spacing: .02em;
  color: var(--ink-soft);
  backdrop-filter: blur(8px);
}
.hero__pulse {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: var(--sakura-500);
  box-shadow: 0 0 0 0 rgba(249, 116, 159, .55);
  animation: pulse 2.6s ease-out infinite;
}
@keyframes pulse {
  0%   { box-shadow: 0 0 0 0 rgba(249, 116, 159, .5); }
  70%  { box-shadow: 0 0 0 9px rgba(249, 116, 159, 0); }
  100% { box-shadow: 0 0 0 0 rgba(249, 116, 159, 0); }
}

.hero__title {
  margin: 24px 0 0;
  font-family: "M PLUS Rounded 1c", "Hiragino Maru Gothic ProN", "Yu Gothic UI", "Noto Sans SC", sans-serif;
  font-size: clamp(44px, 5.2vw, 70px);
  font-weight: 300;
  line-height: 1.22;
  letter-spacing: .08em;
  color: rgba(255, 253, 255, .97);
  -webkit-text-stroke: .35px rgba(130, 94, 132, .16);
  text-shadow: 0 2px 3px rgba(105, 72, 108, .16), 0 0 24px rgba(255, 255, 255, .9), 0 8px 36px rgba(145, 101, 143, .18);
}
.hero__accent {
  position: relative;
  display: inline-block;
  color: rgba(255, 250, 253, .98);
}
/* 标题下的一道花瓣笔画 */
.hero__accent::after {
  content: '';
  position: absolute;
  left: 2px;
  right: 6px;
  bottom: -2px;
  height: 9px;
  background: radial-gradient(closest-side at 50% 100%, rgba(249, 116, 159, .34), transparent 72%);
  border-radius: 50%;
  z-index: -1;
}

.hero__lede {
  margin: 20px auto 0;
  max-width: 38em;
  font-size: 14px;
  line-height: 1.9;
  letter-spacing: .035em;
  color: var(--ink-soft);
}
.hero__lede b {
  color: var(--sakura-600);
  font-weight: 600;
}

.hero__search {
  margin: 28px auto 0;
  max-width: 560px;
}

.hero__actions {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: center;
  gap: 12px;
  margin-top: 20px;
}
.hero__hint {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  margin-top: 26px;
  color: var(--muted);
  font-size: 10px;
  letter-spacing: .22em;
  opacity: .72;
}
.hero__hint span {
  width: 36px;
  height: 1px;
  background: linear-gradient(90deg, transparent, var(--sakura-300));
}
.hero__hint span:last-child { transform: rotate(180deg); }

.hero__primary {
  display: inline-flex;
  align-items: center;
  gap: 9px;
  height: 46px;
  padding: 0 24px;
  border: 0;
  border-radius: 999px;
  cursor: pointer;
  font: inherit;
  font-size: 14px;
  font-weight: 600;
  letter-spacing: .04em;
  color: #fff;
  background: linear-gradient(120deg, var(--sakura-500), var(--sakura-600));
  box-shadow: var(--shadow-sakura), inset 0 1px 0 rgba(255, 255, 255, .35);
  transition: transform .3s cubic-bezier(.2, .8, .3, 1.2), box-shadow .3s, filter .3s;
}
.hero__primary svg { width: 17px; height: 17px; transition: transform .3s; }
.hero__primary:hover {
  transform: translateY(-2px);
  filter: saturate(1.05);
  box-shadow: 0 26px 46px -22px rgba(232, 84, 127, .62), inset 0 1px 0 rgba(255, 255, 255, .4);
}
.hero__primary:hover svg { transform: translateX(3px); }
.hero__primary:active { transform: translateY(0) scale(.985); }

.hero__random {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  height: 46px;
  padding: 0 20px;
  border-radius: 999px;
  border: 1px solid var(--sakura-200);
  background: rgba(255, 255, 255, .8);
  color: var(--sakura-600);
  font: inherit;
  font-size: 13.5px;
  cursor: pointer;
  transition: background .25s, box-shadow .25s, transform .25s, color .25s;
}
.hero__random span { font-size: 11px; opacity: .8; }
.hero__random:hover:not(:disabled) {
  background: #fff;
  transform: translateY(-2px);
  box-shadow: 0 14px 26px -20px rgba(197, 58, 100, .8);
  color: var(--sakura-700);
}
.hero__random:disabled { opacity: .5; cursor: not-allowed; }

.hero__hot {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 26px;
}
.hero__hot-label {
  font-size: 11.5px;
  letter-spacing: .18em;
  color: var(--faint);
  margin-right: 2px;
}
.hero__hot .chip {
  height: 28px;
  padding: 0 13px;
  border-radius: 999px;
  border: 1px solid var(--line-soft);
  background: rgba(255, 255, 255, .6);
  color: var(--ink-soft);
  font: inherit;
  font-size: 12.5px;
  cursor: pointer;
  transition: all .22s;
}
.hero__hot .chip:hover {
  border-color: var(--sakura-300);
  color: var(--sakura-600);
  background: #fff;
}
.hero__hot .chip--on {
  border-color: transparent;
  background: linear-gradient(120deg, var(--sakura-500), var(--sakura-600));
  color: #fff;
  box-shadow: 0 10px 20px -14px rgba(232, 84, 127, .9);
}

.hero__stats {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 0;
  margin: 34px 0 0;
  padding: 20px 0 0;
  border-top: 1px solid var(--line-soft);
  list-style: none;
}
.hero__stats li {
  display: flex;
  flex-direction: column;
  gap: 5px;
  padding-left: 16px;
  border-left: 1px solid var(--line-soft);
}
.hero__stats li:first-child {
  padding-left: 0;
  border-left: 0;
}
.hero__stats b {
  font-family: var(--font-serif);
  font-size: 25px;
  font-weight: 600;
  line-height: 1;
  letter-spacing: -.01em;
  color: var(--ink);
  font-variant-numeric: tabular-nums;
}
.hero__stats span {
  font-size: 11px;
  letter-spacing: .14em;
  color: var(--faint);
}

/* ---------- 今日头条 ---------- */
.lead {
  position: relative;
  width: min(960px, 100%);
  margin: 0 auto;
  border-radius: 24px;
  cursor: pointer;
  outline: none;
  transition: transform .45s cubic-bezier(.2, .8, .3, 1), box-shadow .45s;
  box-shadow: 0 30px 60px -34px rgba(120, 60, 84, .55), 0 2px 0 0 rgba(255, 255, 255, .6) inset;
}
.lead:hover { transform: translateY(-6px); }
.lead:focus-visible { box-shadow: 0 0 0 3px var(--sakura-200), 0 30px 60px -34px rgba(120, 60, 84, .55); }

.lead__cover {
  position: relative;
  height: 210px;
  border-radius: 24px;
  overflow: hidden;
  background-size: cover;
  background-position: center;
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  isolation: isolate;
}
.lead__cover::after {
  content: '';
  position: absolute;
  inset: 0;
  border-radius: inherit;
  box-shadow: inset 0 0 0 1px rgba(255, 255, 255, .28);
  pointer-events: none;
  z-index: 3;
}
.lead__scrim {
  position: absolute;
  inset: 0;
  z-index: 1;
  background:
    linear-gradient(0deg, rgba(45, 18, 32, .9) 0%, rgba(45, 18, 32, .62) 32%, rgba(45, 18, 32, .12) 62%, rgba(45, 18, 32, .18) 100%);
  transition: opacity .5s;
}
.lead:hover .lead__scrim { opacity: .92; }

.lead__badge {
  position: absolute;
  z-index: 2;
  top: 18px;
  left: 18px;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 29px;
  padding: 0 13px 0 10px;
  border-radius: 999px;
  font-size: 11.5px;
  letter-spacing: .1em;
  color: #fff;
  background: rgba(255, 255, 255, .16);
  border: 1px solid rgba(255, 255, 255, .38);
  backdrop-filter: blur(10px);
}
.lead__badge svg { width: 12px; height: 12px; color: #ffd9e5; }

.lead__body {
  position: relative;
  z-index: 2;
  padding: 0 26px 24px;
  color: #fff;
}
.lead__cat {
  display: inline-block;
  height: 24px;
  padding: 0 11px;
  margin-bottom: 12px;
  border: 0;
  border-radius: 999px;
  background: rgba(249, 116, 159, .92);
  color: #fff;
  font: inherit;
  font-size: 11.5px;
  letter-spacing: .08em;
  cursor: pointer;
  transition: background .25s, transform .25s;
}
.lead__cat:hover { background: var(--sakura-500); transform: translateY(-1px); }

.lead__title {
  margin: 0;
  font-family: var(--font-serif);
  font-size: 27px;
  font-weight: 600;
  line-height: 1.42;
  letter-spacing: .005em;
  text-shadow: 0 2px 18px rgba(30, 10, 20, .4);
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
.lead__sum {
  margin: 10px 0 0;
  font-size: 13.5px;
  line-height: 1.75;
  color: rgba(255, 255, 255, .8);
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
.lead__foot {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-top: 16px;
  padding-top: 14px;
  border-top: 1px solid rgba(255, 255, 255, .18);
  font-size: 12px;
  color: rgba(255, 255, 255, .68);
}
.lead__go {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-weight: 600;
  color: #ffd9e5;
  white-space: nowrap;
  transition: gap .25s;
}
.lead__go svg { width: 15px; height: 15px; }
.lead:hover .lead__go { gap: 10px; }

.lead__fav {
  position: absolute;
  z-index: 3;
  top: 16px;
  right: 16px;
  width: 38px;
  height: 38px;
  display: grid;
  place-items: center;
  border-radius: 50%;
  border: 1px solid rgba(255, 255, 255, .34);
  background: rgba(255, 255, 255, .16);
  color: #fff;
  cursor: pointer;
  backdrop-filter: blur(10px);
  transition: background .25s, color .25s, transform .3s;
}
.lead__fav svg { width: 17px; height: 17px; }
.lead__fav:hover { background: rgba(255, 255, 255, .3); transform: scale(1.06); }
.lead__fav--on { color: var(--sakura-500); background: #fff; border-color: #fff; }

/* ============ 吸顶筛选条 ============ */
.stick-sentinel { height: 1px; }

/**
 * 关键：sticky 的 top 必须大于导航栏底边（SiteNav: top 14 + height 68 = 82px），
 * 否则筛选条会「吸在半空中」，下方内容直接从它背后滚过去造成穿模。
 * 吸住时用近乎不透明的暖白釉面 + 上下发丝线，视觉上明确切一刀。
 */
.filter {
  position: sticky;
  top: 88px;
  z-index: 30;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 8px 12px 8px 10px;
  /* 上方 26px 留白：和首屏统计区拉开距离，别贴着 */
  margin: 18px -12px 4px;
  border-radius: 999px;
  background: rgba(255, 255, 255, .42);
  border: 1px solid var(--line-soft);
  scroll-margin-top: 160px;
  transition: background .34s var(--ease), box-shadow .34s var(--ease),
              border-color .34s var(--ease), backdrop-filter .34s var(--ease);
}
.filter--stuck {
  background: linear-gradient(180deg, rgba(253, 251, 250, .985), rgba(251, 246, 245, .97));
  border-color: var(--porcelain-line);
  box-shadow: var(--gloss), 0 1px 0 rgba(255, 255, 255, .9),
              0 18px 30px -26px rgba(96, 62, 78, .7);
  backdrop-filter: blur(20px) saturate(1.3);
  -webkit-backdrop-filter: blur(20px) saturate(1.3);
}
/* 吸顶条与导航之间 6px 的缝：用同色伪元素往上补满，避免内容从缝里透出来 */
.filter--stuck::before {
  content: '';
  position: absolute;
  left: 0;
  right: 0;
  bottom: 100%;
  height: 10px;
  background: rgba(253, 251, 250, .985);
  pointer-events: none;
}

.filter__cats {
  display: flex;
  align-items: center;
  gap: 2px;
  overflow-x: auto;
  scrollbar-width: none;
  flex: 1;
  min-width: 0;
}
.filter__cats::-webkit-scrollbar { display: none; }

.cat {
  position: relative;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 34px;
  padding: 0 14px;
  border: 0;
  border-radius: 999px;
  background: none;
  color: var(--ink-soft);
  font: inherit;
  font-size: 13.5px;
  white-space: nowrap;
  cursor: pointer;
  transition: color .22s, background .22s;
}
.cat i {
  font-style: normal;
  font-size: 11px;
  color: var(--faint);
  transition: color .22s;
}
.cat:hover { color: var(--sakura-600); background: var(--sakura-50); }
.cat--on {
  color: var(--sakura-600);
  font-weight: 600;
  background: #fff;
  box-shadow: inset 0 0 0 1px var(--sakura-200), 0 8px 18px -16px rgba(197, 58, 100, .8);
}
.cat--on i { color: var(--sakura-400); }

.filter__right {
  display: flex;
  align-items: center;
  gap: 12px;
  flex: none;
}
.filter__count {
  font-size: 12px;
  letter-spacing: .06em;
  color: var(--faint);
  font-variant-numeric: tabular-nums;
}

.seg {
  display: inline-flex;
  padding: 3px;
  border-radius: 999px;
  background: rgba(255, 255, 255, .7);
  box-shadow: inset 0 0 0 1px var(--line-soft);
}
.seg__btn {
  height: 28px;
  padding: 0 14px;
  border: 0;
  border-radius: 999px;
  background: none;
  color: var(--muted);
  font: inherit;
  font-size: 12.5px;
  cursor: pointer;
  transition: all .22s;
}
.seg__btn:hover { color: var(--sakura-600); }
.seg__btn--on {
  background: linear-gradient(120deg, var(--sakura-500), var(--sakura-600));
  color: #fff;
  font-weight: 600;
  box-shadow: 0 8px 16px -12px rgba(232, 84, 127, .9);
}

/* 二级标签 */
.subtags {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  padding: 14px 2px 4px;
  animation: fadeDown .4s ease both;
}
@keyframes fadeDown {
  from { opacity: 0; transform: translateY(-6px); }
  to   { opacity: 1; transform: none; }
}
.subtag {
  height: 28px;
  padding: 0 12px;
  border-radius: 999px;
  border: 1px dashed var(--sakura-200);
  background: transparent;
  color: var(--muted);
  font: inherit;
  font-size: 12.5px;
  cursor: pointer;
  transition: all .22s;
}
.subtag:hover { border-color: var(--sakura-400); color: var(--sakura-600); }
.subtag--on {
  border-style: solid;
  border-color: transparent;
  background: var(--sakura-100);
  color: var(--sakura-700);
  font-weight: 600;
}

/* ============ 主体两栏 ============ */
.board {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 288px;
  gap: 44px;
  padding-top: 34px;
  /* 首屏与筛选条之间再留一段，避免侧栏卡片顶到吸顶条下面 */
  scroll-margin-top: 160px;
}

/* 锚点跳转要避开 导航(82) + 筛选条(56)，否则标题会被压在吸顶条下面 */
.block {
  margin-bottom: 46px;
  scroll-margin-top: 158px;
}

.block__head {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 14px;
  margin-bottom: 18px;
  padding-bottom: 12px;
  border-bottom: 1px solid var(--line-soft);
}
.block__head h2 {
  position: relative;
  margin: 0;
  padding-left: 14px;
  font-family: var(--font-serif);
  font-size: 19px;
  font-weight: 600;
  letter-spacing: .04em;
  color: var(--ink);
}
.block__head h2::before {
  content: '';
  position: absolute;
  left: 0;
  top: 50%;
  transform: translateY(-50%);
  width: 4px;
  height: 15px;
  border-radius: 3px;
  background: linear-gradient(180deg, var(--sakura-400), var(--sakura-600));
}
.block__sub {
  font-size: 10.5px;
  letter-spacing: .18em;
  text-transform: uppercase;
  color: var(--faint);
  white-space: nowrap;
}

/* ---------- 继续阅读 ---------- */
.recent {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 12px;
}
.recent__item {
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding: 15px 16px;
  border: 1px solid var(--line-soft);
  border-radius: 18px;
  background: rgba(255, 255, 255, .68);
  font: inherit;
  text-align: left;
  cursor: pointer;
  transition: transform .3s, border-color .3s, background .3s, box-shadow .3s;
}
.recent__item:hover {
  transform: translateY(-3px);
  background: #fff;
  border-color: var(--sakura-200);
  box-shadow: 0 18px 34px -26px rgba(120, 60, 84, .8);
}
.recent__top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  color: var(--sakura-400);
}
.recent__top svg { width: 14px; height: 14px; transition: transform .25s; }
.recent__item:hover .recent__top svg { transform: translateX(3px); }
.recent__time {
  font-size: 11px;
  letter-spacing: .06em;
  color: var(--faint);
}
.recent__title {
  font-size: 13.5px;
  line-height: 1.6;
  color: var(--ink);
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* ---------- 精选 ---------- */
/* 两张精选卡 + 一张「待读」卡：前两张各占 1 份，第三张窄一点当收尾，
   三张同一行，避免第三张被挤到下一行后左侧留一个空洞。 */
.picks {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(0, 1fr) 220px;
  gap: 16px;
  align-items: stretch;
}
.picks__more {
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 22px 16px;
  border: 1px solid var(--porcelain-line);
  border-radius: 20px;
  /* 素纸卡：比封面卡轻一档，不抢视觉重心 */
  background: linear-gradient(168deg, rgba(255, 255, 255, .9), rgba(252, 243, 245, .82));
  box-shadow: var(--gloss), 0 10px 24px -22px rgba(96, 62, 78, .5);
  color: var(--muted);
  font: inherit;
  cursor: pointer;
  overflow: hidden;
  transition: border-color .32s var(--ease), background .32s var(--ease),
              transform .32s var(--ease), box-shadow .32s var(--ease);
}
.picks__more::before {
  content: '';
  position: absolute;
  inset: auto 0 0;
  height: 2px;
  background: linear-gradient(90deg, transparent, var(--sakura-300), transparent);
  opacity: 0;
  transition: opacity .32s var(--ease);
}
.picks__more:hover {
  border-color: var(--sakura-300);
  background: #fff;
  transform: translateY(-4px);
  box-shadow: var(--gloss), var(--lift-hover);
}
.picks__more:hover::before { opacity: 1; }
.picks__more-num {
  font-family: var(--font-serif);
  font-size: 46px;
  font-weight: 600;
  line-height: .9;
  color: var(--sakura-600);
  font-variant-numeric: tabular-nums;
}
.picks__more-txt {
  font-size: 12px;
  line-height: 1.75;
  text-align: center;
  letter-spacing: .04em;
  color: var(--muted);
}
.picks__more svg { width: 18px; height: 18px; color: var(--sakura-400); animation: nudge 2.4s ease-in-out infinite; }
@keyframes nudge {
  0%, 100% { transform: translateY(0); }
  50%      { transform: translateY(4px); }
}

/* ---------- 筛选条件 ---------- */
.crt {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
  margin-bottom: 16px;
}
.crt__label {
  font-size: 11px;
  letter-spacing: .16em;
  color: var(--faint);
}
.crt__chip {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 27px;
  padding: 0 6px 0 12px;
  border-radius: 999px;
  background: var(--sakura-50);
  border: 1px solid var(--sakura-200);
  color: var(--sakura-700);
  font-size: 12.5px;
}
.crt__chip button {
  display: grid;
  place-items: center;
  width: 18px;
  height: 18px;
  border: 0;
  border-radius: 50%;
  background: rgba(249, 116, 159, .14);
  color: var(--sakura-600);
  font-size: 13px;
  line-height: 1;
  cursor: pointer;
  transition: background .2s;
}
.crt__chip button:hover { background: rgba(249, 116, 159, .28); }
.crt__chip--tag { background: #f2f9fd; border-color: #cfe8f7; color: var(--sky-600); }
.crt__chip--tag button { background: rgba(90, 169, 221, .16); color: var(--sky-600); }
.crt__clear {
  border: 0;
  background: none;
  font: inherit;
  font-size: 12.5px;
  color: var(--muted);
  text-decoration: underline;
  text-underline-offset: 3px;
  cursor: pointer;
}
.crt__clear:hover { color: var(--sakura-600); }

/* ---------- 骨架 ---------- */
.skeleton { display: grid; gap: 10px; }
.sk-row {
  display: grid;
  grid-template-columns: 116px 1fr;
  gap: 16px;
  padding: 16px 0;
  border-bottom: 1px solid var(--line-soft);
}
.sk-thumb {
  height: 76px;
  border-radius: 14px;
  background: linear-gradient(100deg, var(--sakura-50) 20%, var(--sakura-100) 40%, var(--sakura-50) 60%);
  background-size: 220% 100%;
  animation: shimmer 1.5s linear infinite;
}
.sk-body { display: flex; flex-direction: column; gap: 9px; justify-content: center; }
.sk-line {
  height: 11px;
  border-radius: 6px;
  background: linear-gradient(100deg, var(--sakura-50) 20%, var(--sakura-100) 40%, var(--sakura-50) 60%);
  background-size: 220% 100%;
  animation: shimmer 1.5s linear infinite;
}
.sk-line--title { width: 62%; height: 15px; }
.sk-line--sub { width: 86%; }
.sk-line--meta { width: 34%; }
@keyframes shimmer {
  from { background-position: 120% 0; }
  to   { background-position: -120% 0; }
}

/* ---------- 空 / 错误态 ---------- */
.state {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  padding: 62px 20px;
  border: 1px dashed var(--sakura-200);
  border-radius: 22px;
  background: rgba(255, 255, 255, .5);
  text-align: center;
}
.state > svg {
  width: 34px;
  height: 34px;
  color: var(--sakura-300);
}
.state p {
  margin: 0;
  font-size: 14px;
  color: var(--ink-soft);
}
.state--error > svg { color: var(--sakura-400); }
.state__tips {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: center;
  gap: 8px;
  font-size: 12px;
  color: var(--faint);
}
.state__tips .chip {
  height: 26px;
  padding: 0 12px;
  border-radius: 999px;
  border: 1px solid var(--sakura-200);
  background: #fff;
  color: var(--sakura-600);
  font: inherit;
  font-size: 12px;
  cursor: pointer;
}
.state__tips .chip:hover { background: var(--sakura-50); }
.state__btn {
  height: 36px;
  padding: 0 20px;
  border: 0;
  border-radius: 999px;
  background: linear-gradient(120deg, var(--sakura-500), var(--sakura-600));
  color: #fff;
  font: inherit;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  box-shadow: 0 12px 24px -18px rgba(232, 84, 127, .9);
  transition: transform .25s;
}
.state__btn:hover { transform: translateY(-2px); }

/* ---------- 内容流 ---------- */
.feed { display: flex; flex-direction: column; }
.feed-sentinel { height: 1px; }

.feed-more {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 9px;
  padding: 26px 0 6px;
  font-size: 12.5px;
  color: var(--faint);
}
.feed-more--end { letter-spacing: .08em; }
.feed-more__line {
  width: 54px;
  height: 1px;
  background: linear-gradient(90deg, transparent, var(--sakura-200), transparent);
}
.feed-more__petal { color: var(--sakura-300); font-size: 11px; }
.feed-more--err { color: var(--sakura-600); }
.feed-more__retry {
  border: 0;
  background: none;
  font: inherit;
  font-size: 12.5px;
  color: var(--sakura-600);
  text-decoration: underline;
  cursor: pointer;
}
.feed-more__spin {
  width: 13px;
  height: 13px;
  border-radius: 50%;
  border: 2px solid var(--sakura-200);
  border-top-color: var(--sakura-500);
  animation: spin .8s linear infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }

/* ============ 侧栏 ============ */
/**
 * 侧栏：整列吸附在筛选条下方（不是只吸第一张卡），
 * 这样滚动时它始终从 152px 开始，不会被吸顶条压住，也不会出现卡片相互重叠。
 */
.board__side {
  position: sticky;
  top: 152px;
  align-self: start;
  display: flex;
  flex-direction: column;
  gap: 18px;
  padding-top: 0;
  max-height: calc(100vh - 172px);
  overflow-y: auto;
  overscroll-behavior: contain;
  scrollbar-width: none;
}
.board__side::-webkit-scrollbar { display: none; }

.side {
  min-width: 0;
  padding: 18px 16px;
  border-radius: 18px;
  background: var(--porcelain-flat);
  border: 1px solid var(--porcelain-line);
  box-shadow: var(--gloss), var(--lift);
  backdrop-filter: blur(10px);
}
.side__title {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 10px;
  margin: 0 0 14px;
  font-family: var(--font-serif);
  font-size: 14px;
  font-weight: 600;
  letter-spacing: .06em;
  color: var(--ink);
}
.side__title span {
  font-family: var(--font-sans);
  font-size: 10.5px;
  font-weight: 400;
  letter-spacing: .1em;
  color: var(--faint);
}

/* ---------- 标签花笺：两列药丸，右边带篇数 ---------- */
.feng {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 6px;
}
.feng__item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 6px;
  min-width: 0;
  height: 32px;
  padding: 0 9px 0 10px;
  border: 1px solid transparent;
  border-radius: 10px;
  background: rgba(255, 255, 255, .6);
  box-shadow: inset 0 0 0 1px var(--line-soft);
  font: inherit;
  cursor: pointer;
  transition: color .24s var(--ease), background .24s var(--ease),
              box-shadow .24s var(--ease), transform .24s var(--ease);
}
.feng__name {
  font-size: 12px;
  line-height: 1.2;
  color: var(--ink-soft);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.feng__num {
  flex: none;
  font-size: 10px;
  color: var(--faint);
  font-variant-numeric: tabular-nums;
}
.feng__item:hover {
  background: #fff;
  box-shadow: inset 0 0 0 1px var(--sakura-200), 0 6px 14px -12px rgba(197, 58, 100, .8);
  transform: translateY(-1px);
}
.feng__item:hover .feng__name { color: var(--sakura-700); }
.feng__item--on {
  background: linear-gradient(120deg, var(--sakura-500), var(--sakura-600));
  box-shadow: inset 0 0 0 1px transparent, 0 8px 16px -12px rgba(232, 84, 127, .95);
}
.feng__item--on .feng__name { color: #fff; font-weight: 600; }
.feng__item--on .feng__num { color: rgba(255, 255, 255, .72); }

.side__link {
  margin-top: 14px;
  border: 0;
  background: none;
  padding: 0;
  font: inherit;
  font-size: 12px;
  color: var(--sakura-500);
  cursor: pointer;
  transition: color .22s, gap .22s;
}
.side__link:hover { color: var(--sakura-700); }

/* 分类分布 */
.dist { display: flex; flex-direction: column; gap: 4px; }
.dist__row {
  display: grid;
  grid-template-columns: 68px 1fr 22px;
  align-items: center;
  gap: 10px;
  padding: 6px 6px;
  border: 0;
  border-radius: 10px;
  background: none;
  font: inherit;
  cursor: pointer;
  transition: background .22s;
}
.dist__row:hover { background: var(--sakura-50); }
.dist__name {
  font-size: 12.5px;
  color: var(--ink-soft);
  text-align: left;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.dist__bar {
  height: 5px;
  border-radius: 3px;
  background: var(--paper-3);
  overflow: hidden;
}
.dist__bar i {
  display: block;
  height: 100%;
  border-radius: 3px;
  background: linear-gradient(90deg, var(--sakura-300), var(--sakura-500));
  transition: width .6s cubic-bezier(.2, .8, .3, 1);
}
.dist__num {
  font-size: 11.5px;
  color: var(--faint);
  text-align: right;
  font-variant-numeric: tabular-nums;
}
.dist__row--on .dist__name { color: var(--sakura-600); font-weight: 600; }
.dist__row--on .dist__bar i { background: linear-gradient(90deg, var(--sakura-500), var(--sakura-600)); }

/* 快捷入口 */
.quick { display: flex; flex-direction: column; gap: 2px; }
.quick__item {
  display: flex;
  align-items: center;
  gap: 9px;
  height: 36px;
  padding: 0 9px;
  border: 0;
  border-radius: 10px;
  background: none;
  color: var(--ink-soft);
  font: inherit;
  font-size: 13px;
  text-align: left;
  cursor: pointer;
  transition: background .22s, color .22s;
}
.quick__item:hover { background: var(--sakura-50); color: var(--sakura-700); }
.quick__dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  flex: none;
}
.quick__item svg {
  width: 13px;
  height: 13px;
  margin-left: auto;
  color: var(--faint);
  transition: transform .22s;
}
.quick__item:hover svg { transform: translateX(3px); color: var(--sakura-400); }

.dice {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 7px;
  width: 100%;
  height: 38px;
  margin-top: 12px;
  border: 1px solid var(--sakura-200);
  border-radius: 12px;
  background: linear-gradient(120deg, #fff, var(--sakura-50));
  color: var(--sakura-600);
  font: inherit;
  font-size: 12.5px;
  letter-spacing: .04em;
  cursor: pointer;
  transition: transform .25s, box-shadow .25s, border-color .25s;
}
.dice svg { width: 15px; height: 15px; }
.dice:hover:not(:disabled) {
  transform: translateY(-2px);
  border-color: var(--sakura-400);
  box-shadow: 0 14px 24px -20px rgba(197, 58, 100, .9);
}
.dice:disabled { opacity: .5; cursor: not-allowed; }

.side__foot {
  margin: 0;
  padding: 0 4px;
  font-family: var(--font-serif);
  font-size: 11.5px;
  line-height: 2;
  letter-spacing: .06em;
  color: var(--faint);
}

/* ============ 回到顶部 ============ */
.totop {
  position: fixed;
  right: 26px;
  bottom: 30px;
  z-index: 30;
  width: 46px;
  height: 46px;
  display: grid;
  place-items: center;
  border: 1px solid var(--sakura-200);
  border-radius: 50%;
  background: rgba(255, 255, 255, .9);
  color: var(--sakura-600);
  cursor: pointer;
  box-shadow: 0 18px 34px -22px rgba(120, 60, 84, .8);
  backdrop-filter: blur(10px);
  transition: transform .3s, box-shadow .3s, background .3s;
}
.totop svg { width: 18px; height: 18px; }
.totop:hover {
  transform: translateY(-3px);
  background: #fff;
  box-shadow: var(--shadow-sakura);
}
.totop-enter-active, .totop-leave-active { transition: opacity .28s, transform .28s; }
.totop-enter-from, .totop-leave-to { opacity: 0; transform: translateY(10px) scale(.92); }

/* ============ 响应式 ============ */
@media (max-width: 1080px) {
  .picks { grid-template-columns: minmax(0, 1fr) minmax(0, 1fr); }
  .picks__more { grid-column: 1 / -1; flex-direction: row; gap: 14px; padding: 18px; }
  .hero { grid-template-columns: 1fr; gap: 30px; padding: 40px 0 34px; }
  .lead__cover { height: 230px; }
  .board { grid-template-columns: 1fr; gap: 0; }
  .board__side {
    position: static;
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
    gap: 16px;
    margin-top: 10px;
  }
}

@media (max-width: 720px) {
  .home { padding: 0 16px 72px; }
  .masthead { padding: 18px 0 14px; font-size: 9.5px; letter-spacing: .16em; }
  .masthead span:nth-child(2) { display: none; }
  .hero { padding: 24px 0 26px; grid-template-rows: minmax(420px, 1fr) auto; }
  .hero__copy { padding: 24px 0; }
  .hero__title { font-size: clamp(32px, 9vw, 42px); letter-spacing: .045em; }
  .hero__lede { font-size: 13px; }
  .hero__hint { margin-top: 22px; font-size: 9px; letter-spacing: .14em; }
  /* 移动端统计区：2×2 但用发丝线分隔，避免散成四块 */
  .hero__stats {
    grid-template-columns: repeat(2, 1fr);
    gap: 0;
    margin-top: 26px;
    padding-top: 18px;
  }
  .hero__stats li { padding: 10px 14px; border-left: 1px solid var(--line-soft); }
  .hero__stats li:nth-child(odd) { padding-left: 0; border-left: 0; }
  .hero__stats li:nth-child(n + 3) { padding-top: 14px; border-top: 1px solid var(--line-soft); }
  .hero__stats b { font-size: 21px; }
  .lead__cover { height: 200px; }
  .lead__body { padding: 0 18px 18px; }
  .lead__title { font-size: 21px; }
  .lead__sum { display: none; }
  /* 移动端导航 top 10 + 高 60 = 70，筛选条要吸在它下方 */
  .filter { top: 74px; border-radius: 16px; padding: 8px 4px; }
  .filter--stuck::before { height: 8px; }
  .recent { grid-template-columns: 1fr; }
  .picks { grid-template-columns: 1fr; }
  .picks__more { flex-direction: row; padding: 16px; }
  .picks__more-num { font-size: 26px; }
  .picks__more-txt { text-align: left; }
  .picks__more-txt br { display: none; }
  .totop { right: 16px; bottom: 20px; width: 42px; height: 42px; }
}
</style>
