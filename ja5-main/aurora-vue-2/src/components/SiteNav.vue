<template>
  <!-- ============ 顶部导航（全站共用） ============ -->
  <header class="nav" :class="{ 'nav--solid': scrolled }">
    <div class="nav__bar">
      <!-- 品牌：一枚樱花 + 站名 -->
      <a class="nav__brand" href="#" @click.prevent="$emit('go', 'home')">
        <span class="mark" aria-hidden="true">
          <svg viewBox="0 0 32 32">
            <g class="mark__petals">
              <ellipse v-for="i in 5" :key="i" cx="16" cy="8" rx="4.4" ry="6.6"
                       :transform="`rotate(${(i - 1) * 72} 16 16)`" />
            </g>
            <circle cx="16" cy="16" r="2.6" class="mark__core" />
          </svg>
        </span>
        <span class="nav__brand-txt">
          <b>樱见</b>
          <i>SAKURA NOTE</i>
        </span>
      </a>

      <!-- 导航菜单（>1080px 常驻） -->
      <nav class="nav__menu">
        <button
          v-for="item in visibleMenus"
          :key="item.key"
          class="nav__item"
          :class="{ on: active === item.key }"
          type="button"
          @click="$emit('go', item.key)"
        >
          <span>{{ item.label }}</span>
        </button>
      </nav>

      <!-- 用户区 -->
      <div class="nav__user">
        <button
          class="nav__avatar"
          type="button"
          :title="userName + ' · 个人中心'"
          aria-label="进入个人中心"
          @click="$emit('go', 'profile')"
        >{{ avatarText }}</button>
        <div class="nav__meta">
          <b>{{ userName }}</b>
          <span>{{ userSub }}</span>
        </div>
        <button class="nav__logout" type="button" @click="$emit('logout')">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"
               stroke-linecap="round" stroke-linejoin="round">
            <path d="M15 17l5-5-5-5" />
            <path d="M20 12H9" />
            <path d="M12 20H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h6" />
          </svg>
          <span>离开</span>
        </button>

        <!-- 汉堡按钮：≤1080px 出现 -->
        <button
          class="nav__burger"
          type="button"
          aria-label="打开导航菜单"
          aria-haspopup="dialog"
          :aria-expanded="open"
          @click="open = true"
        >
          <i></i><i></i><i></i>
        </button>
      </div>
    </div>
  </header>

  <!-- 移动端抽屉：Teleport 到 body，避开 backdrop-filter 造成的定位容器 -->
  <Teleport to="body">
    <Transition name="md">
      <div v-if="open" class="md" role="dialog" aria-modal="true" aria-label="导航菜单" @click.self="close">
        <div class="md__panel">
          <div class="md__head">
            <span class="md__head-title">花名册</span>
            <button class="md__close" type="button" aria-label="关闭菜单" @click="close">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9"
                   stroke-linecap="round">
                <path d="M6 6l12 12M18 6L6 18" />
              </svg>
            </button>
          </div>

          <div class="md__user">
            <span class="md__avatar">{{ avatarText }}</span>
            <div class="md__user-info">
              <b>{{ userName }}</b>
              <span>{{ userSub }}</span>
            </div>
          </div>

          <nav class="md__list">
            <button
              v-for="item in visibleMenus"
              :key="item.key"
              class="md__item"
              :class="{ on: active === item.key }"
              type="button"
              :aria-current="active === item.key ? 'page' : undefined"
              @click="pick(item.key)"
            >
              <span class="md__item-txt">{{ item.label }}</span>
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"
                   stroke-linecap="round" stroke-linejoin="round">
                <path d="M9 6l6 6-6 6" />
              </svg>
            </button>
          </nav>

          <button class="md__logout" type="button" @click="onLogout">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"
                 stroke-linecap="round" stroke-linejoin="round">
              <path d="M15 17l5-5-5-5" />
              <path d="M20 12H9" />
              <path d="M12 20H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h6" />
            </svg>
            退出登录
          </button>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'

const props = defineProps({
  user: { type: Object, default: null },
  /** 当前高亮的菜单 key */
  active: { type: String, default: 'town' }
})
const emit = defineEmits(['go', 'logout'])

const menus = [
  { key: 'town', label: '首页' },
  { key: 'home', label: '手记馆' },
  { key: 'discover', label: '漫游' },
  { key: 'game', label: '小游戏' },
  { key: 'favorites', label: '书签' },
  { key: 'profile', label: '我的' },
  { key: 'about', label: '关于' },
  { key: 'admin-login', label: '后台管理系统' }
]

// 只有 permission=0 的管理员才显示后台入口
const visibleMenus = computed(() => {
  const isAdmin = Boolean(props.user) && Number(props.user.permission) === 0
  return isAdmin ? menus : menus.filter((item) => item.key !== 'admin-login')
})

const userName = computed(() => (props.user && props.user.name) || '旅人')
const userSub = computed(() => {
  const id = props.user && props.user.id
  return id != null ? `ID · ${id}` : '已登录'
})
const avatarText = computed(() => {
  const n = userName.value
  return n ? n.slice(0, 1).toUpperCase() : '樱'
})

/* 滚动后导航加一点实底，避免和内容糊在一起 */
const scrolled = ref(false)
function onScroll () { scrolled.value = (window.scrollY || 0) > 12 }

/* ---------------- 移动端抽屉 ---------------- */
const open = ref(false)

let prevOverflow = ''
function lockScroll () {
  prevOverflow = document.body.style.overflow
  document.body.style.overflow = 'hidden'
}
function unlockScroll () {
  if (prevOverflow) document.body.style.overflow = prevOverflow
  else document.body.style.removeProperty('overflow')
}

function close () { open.value = false }
function pick (key) { close(); emit('go', key) }
function onLogout () { close(); emit('logout') }

function onKeydown (e) { if (e.key === 'Escape') close() }
function onResize () { if (window.innerWidth > 1080) close() }

watch(open, (v) => {
  if (v) {
    lockScroll()
    window.addEventListener('keydown', onKeydown)
    window.addEventListener('resize', onResize)
  } else {
    unlockScroll()
    window.removeEventListener('keydown', onKeydown)
    window.removeEventListener('resize', onResize)
  }
})

onMounted(() => {
  window.addEventListener('scroll', onScroll, { passive: true })
  onScroll()
})

onBeforeUnmount(() => {
  if (open.value) unlockScroll()
  window.removeEventListener('keydown', onKeydown)
  window.removeEventListener('resize', onResize)
  window.removeEventListener('scroll', onScroll)
})
</script>

<style scoped>
/* ============ 顶部导航：樱花玻璃胶囊 ============ */
.nav {
  position: sticky;
  top: 14px;
  z-index: 40;
}
.nav__bar {
  display: flex;
  align-items: center;
  gap: 18px;
  height: 68px;
  padding: 0 16px 0 18px;
  border-radius: 22px;
  background: rgba(255, 250, 252, .72);
  backdrop-filter: blur(24px) saturate(150%);
  -webkit-backdrop-filter: blur(24px) saturate(150%);
  border: 1px solid rgba(255, 255, 255, .9);
  box-shadow:
    0 20px 46px -30px rgba(147, 81, 108, .55),
    0 1px 0 rgba(255, 255, 255, .9) inset;
  transition: box-shadow .4s, background .4s, border-color .4s;
}
.nav--solid .nav__bar {
  background: rgba(255, 248, 251, .9);
  border-color: rgba(255, 214, 229, .9);
  box-shadow:
    0 26px 54px -30px rgba(147, 81, 108, .6),
    0 1px 0 rgba(255, 255, 255, .95) inset;
}

/* 品牌 */
.nav__brand {
  display: flex;
  align-items: center;
  gap: 10px;
  text-decoration: none;
  flex: none;
  cursor: pointer;
  transition: opacity .25s, transform .35s var(--ease);
}
.nav__brand:hover { transform: translateY(-1px); }
.mark {
  width: 34px;
  height: 34px;
  display: grid;
  place-items: center;
  border-radius: 12px;
  background: linear-gradient(150deg, #fff, var(--sakura-100));
  box-shadow: 0 6px 16px -10px rgba(232, 84, 127, .8), 0 0 0 1px rgba(255, 196, 217, .7) inset;
}
.mark svg { width: 24px; height: 24px; }
.mark__petals ellipse { fill: var(--sakura-400); }
.mark__petals ellipse:nth-child(2n) { fill: var(--sakura-500); }
.mark__core { fill: #fff8fb; }
.nav__brand:hover .mark svg { animation: bloom .8s var(--ease); }
@keyframes bloom {
  0% { transform: rotate(0) scale(1); }
  60% { transform: rotate(36deg) scale(1.14); }
  100% { transform: rotate(72deg) scale(1); }
}
.nav__brand-txt { display: flex; flex-direction: column; line-height: 1.15; }
.nav__brand-txt b {
  font-family: var(--font-serif);
  font-size: 16.5px;
  font-weight: 900;
  letter-spacing: .22em;
  color: var(--ink);
}
.nav__brand-txt i {
  font-style: normal;
  font-size: 8.5px;
  letter-spacing: .26em;
  color: var(--faint);
}

/* 菜单 */
.nav__menu {
  display: flex;
  align-items: center;
  gap: 2px;
  margin-left: 10px;
  padding-left: 12px;
  border-left: 1px solid var(--line-soft);
}
.nav__item {
  position: relative;
  border: 0;
  background: none;
  color: var(--muted);
  font: inherit;
  font-size: 13.5px;
  font-weight: 500;
  letter-spacing: .06em;
  padding: 10px 13px;
  border-radius: 13px;
  cursor: pointer;
  transition: color .3s, background .3s;
}
.nav__item span { position: relative; z-index: 1; }
.nav__item:hover { color: var(--sakura-700); background: rgba(255, 226, 238, .66); }
.nav__item.on { color: var(--sakura-700); }
.nav__item.on::after {
  content: "";
  position: absolute;
  left: 50%;
  bottom: 2px;
  width: 16px;
  height: 3px;
  border-radius: 3px;
  background: linear-gradient(90deg, var(--sakura-400), var(--sakura-600));
  transform: translateX(-50%);
  box-shadow: 0 2px 8px -2px rgba(232, 84, 127, .9);
}

/* 用户区 */
.nav__user {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-left: auto;
  flex: none;
}
.nav__avatar {
  width: 38px;
  height: 38px;
  flex: none;
  display: grid;
  place-items: center;
  border-radius: 50%;
  border: 2px solid #fff;
  font: inherit;
  font-size: 15px;
  font-weight: 700;
  color: #fff;
  cursor: pointer;
  background: linear-gradient(135deg, var(--sakura-400), var(--sakura-600));
  box-shadow: 0 8px 18px -10px rgba(232, 84, 127, .95);
  transition: transform .3s var(--ease), box-shadow .3s var(--ease);
}
.nav__avatar:hover { transform: translateY(-2px) scale(1.05); box-shadow: 0 12px 24px -10px rgba(232, 84, 127, 1); }
.nav__meta { display: flex; flex-direction: column; line-height: 1.35; min-width: 0; }
.nav__meta b {
  font-size: 13px;
  font-weight: 600;
  color: var(--ink);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 12ch;
}
.nav__meta span { font-size: 10.5px; color: var(--faint); letter-spacing: .08em; }
.nav__logout {
  display: flex;
  align-items: center;
  gap: 6px;
  height: 36px;
  padding: 0 13px;
  border-radius: 12px;
  cursor: pointer;
  font: inherit;
  font-size: 12.5px;
  font-weight: 500;
  color: var(--muted);
  background: rgba(255, 255, 255, .7);
  border: 1px solid var(--line);
  transition: color .25s, background .25s, border-color .25s, transform .25s var(--ease);
}
.nav__logout:hover {
  color: var(--sakura-700);
  background: var(--sakura-100);
  border-color: var(--sakura-300);
  transform: translateY(-1px);
}
.nav__logout svg { width: 15px; height: 15px; }

/* 汉堡 */
.nav__burger {
  display: none;
  flex-direction: column;
  justify-content: center;
  gap: 4px;
  width: 40px;
  height: 38px;
  padding: 0 10px;
  border-radius: 12px;
  cursor: pointer;
  background: rgba(255, 255, 255, .7);
  border: 1px solid var(--line);
  transition: background .25s, border-color .25s;
}
.nav__burger i {
  display: block;
  height: 1.7px;
  width: 100%;
  border-radius: 2px;
  background: var(--sakura-600);
  transition: opacity .2s;
}
.nav__burger i:nth-child(2) { width: 70%; }
.nav__burger:hover { background: var(--sakura-100); border-color: var(--sakura-300); }

/* ============ 移动端抽屉 ============ */
.md {
  position: fixed;
  inset: 0;
  z-index: 80;
  display: flex;
  justify-content: flex-end;
  background: rgba(80, 40, 60, .34);
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
}
.md__panel {
  width: min(320px, 84vw);
  height: 100%;
  display: flex;
  flex-direction: column;
  padding: 18px 16px calc(18px + env(safe-area-inset-bottom));
  background: linear-gradient(175deg, #fffafc, #fff1f6);
  border-left: 1px solid var(--line);
  box-shadow: -30px 0 70px -30px rgba(147, 81, 108, .45);
  overflow-y: auto;
  overscroll-behavior: contain;
}
.md__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 2px 2px 14px;
}
.md__head-title {
  font-family: var(--font-serif);
  font-size: 13px;
  font-weight: 700;
  letter-spacing: .3em;
  color: var(--sakura-700);
}
.md__close {
  width: 34px;
  height: 34px;
  display: grid;
  place-items: center;
  border-radius: 11px;
  cursor: pointer;
  color: var(--muted);
  background: #fff;
  border: 1px solid var(--line);
  transition: color .2s, background .2s;
}
.md__close:hover { color: var(--sakura-700); background: var(--sakura-100); }
.md__close svg { width: 16px; height: 16px; }

.md__user {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px;
  margin-bottom: 14px;
  border-radius: 18px;
  background: #fff;
  border: 1px solid var(--line-soft);
  box-shadow: var(--shadow-sm);
}
.md__avatar {
  width: 42px;
  height: 42px;
  flex: none;
  display: grid;
  place-items: center;
  border-radius: 50%;
  font-size: 16px;
  font-weight: 700;
  color: #fff;
  background: linear-gradient(135deg, var(--sakura-400), var(--sakura-600));
  box-shadow: 0 8px 18px -10px rgba(232, 84, 127, .95);
}
.md__user-info { display: flex; flex-direction: column; line-height: 1.4; min-width: 0; }
.md__user-info b {
  font-size: 14px;
  font-weight: 600;
  color: var(--ink);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.md__user-info span { font-size: 11.5px; color: var(--faint); letter-spacing: .06em; }

.md__list { display: flex; flex-direction: column; gap: 4px; }
.md__item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
  padding: 13px 14px;
  border-radius: 14px;
  border: 1px solid transparent;
  background: none;
  color: var(--ink-soft);
  font: inherit;
  font-size: 15px;
  font-weight: 500;
  text-align: left;
  cursor: pointer;
  transition: color .2s, background .2s, border-color .2s;
}
.md__item svg { width: 16px; height: 16px; opacity: .4; transition: opacity .2s, transform .2s var(--ease); }
.md__item:hover { color: var(--sakura-700); background: var(--sakura-100); }
.md__item:hover svg { opacity: 1; transform: translateX(2px); }
.md__item.on {
  color: var(--sakura-700);
  background: linear-gradient(120deg, #ffe6ef, #fff2f7);
  border-color: var(--sakura-300);
  font-weight: 600;
}
.md__item.on svg { opacity: .9; }

.md__logout {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 7px;
  margin-top: auto;
  padding: 13px;
  border-radius: 14px;
  cursor: pointer;
  font: inherit;
  font-size: 14px;
  font-weight: 500;
  color: var(--muted);
  background: #fff;
  border: 1px solid var(--line);
  transition: color .2s, background .2s, border-color .2s;
}
.md__logout:hover { color: var(--sakura-700); background: var(--sakura-100); border-color: var(--sakura-300); }
.md__logout svg { width: 15px; height: 15px; }

/* 进出场 */
.md-enter-active, .md-leave-active { transition: opacity .26s var(--ease); }
.md-enter-active .md__panel, .md-leave-active .md__panel { transition: transform .3s var(--ease); }
.md-enter-from, .md-leave-to { opacity: 0; }
.md-enter-from .md__panel, .md-leave-to .md__panel { transform: translateX(100%); }

/* 加入后台入口后，1080px 以下改用抽屉，避免菜单挤压或溢出 */
@media (max-width: 1080px) {
  .nav { top: 10px; }
  .nav__menu { display: none; }
  .nav__logout { display: none; }
  .nav__burger { display: flex; }
  .nav__bar { gap: 12px; }
}
@media (max-width: 640px) {
  .nav__brand-txt i { display: none; }
  .nav__meta { display: none; }
  .nav__bar {
    height: 60px;
    padding: 0 12px 0 12px;
    border-radius: 18px;
  }
  .nav__avatar { width: 34px; height: 34px; font-size: 14px; }
  .nav__burger { height: 34px; width: 36px; }
}
</style>
