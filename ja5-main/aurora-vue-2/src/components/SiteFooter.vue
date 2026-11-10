<template>
  <footer class="foot">
    <div class="foot__inner">
      <div class="foot__brand">
        <span class="logo__mark" aria-hidden="true">
          <svg viewBox="0 0 24 24">
            <g fill="currentColor">
              <ellipse cx="12" cy="5.2" rx="3.1" ry="4.6" />
              <ellipse cx="12" cy="5.2" rx="3.1" ry="4.6" transform="rotate(72 12 12)" />
              <ellipse cx="12" cy="5.2" rx="3.1" ry="4.6" transform="rotate(144 12 12)" />
              <ellipse cx="12" cy="5.2" rx="3.1" ry="4.6" transform="rotate(216 12 12)" />
              <ellipse cx="12" cy="5.2" rx="3.1" ry="4.6" transform="rotate(288 12 12)" />
            </g>
            <circle cx="12" cy="12" r="1.5" fill="#fff3f7" />
          </svg>
        </span>
        <div>
          <p class="foot__name">樱见<i>SAKURA NOTE</i></p>
          <p class="foot__slogan">春风穿过鸟居，樱瓣落在书页上。</p>
        </div>
      </div>

      <nav class="foot__links">
        <button v-for="l in links" :key="l.key" class="foot__link" type="button" @click="$emit('go', l.key)">
          {{ l.label }}
        </button>
      </nav>

      <div class="foot__meta">
        <span>© {{ year }} 樱见 SAKURA NOTE · 演示项目</span>
        <span class="foot__dot">·</span>
        <span>Vue 3 + Vite + Spring Boot 3</span>
        <span class="foot__dot">·</span>
        <span>数据仅用于本地演示</span>
      </div>
    </div>
  </footer>
</template>

<script setup>
defineProps({
  /** 是否显示快捷链接（登录页不需要） */
  showLinks: { type: Boolean, default: true }
})
defineEmits(['go'])

const links = [
  { key: 'town', label: '首页' },
  { key: 'home', label: '手记馆' },
  { key: 'discover', label: '漫游' },
  { key: 'favorites', label: '书签' },
  { key: 'profile', label: '我的' },
  { key: 'about', label: '关于' }
]

const year = new Date().getFullYear()
</script>

<style scoped>
.foot {
  margin-top: 56px;
  padding: 0 4px 14px;
}

.foot__inner {
  position: relative;
  border-top: 1px solid var(--line, #f0dfe6);
  padding-top: 24px;
  display: grid;
  gap: 16px;
}
/* 顶部一道樱粉渐隐线 */
.foot__inner::before {
  content: '';
  position: absolute;
  top: -1px;
  left: 0;
  width: 220px;
  height: 1px;
  background: linear-gradient(90deg, var(--sakura-400, #f791b4), transparent);
}

.foot__brand {
  display: flex;
  align-items: center;
  gap: 12px;
}

.logo__mark {
  width: 34px;
  height: 34px;
  display: grid;
  place-items: center;
  flex: none;
  border-radius: 12px;
  color: var(--sakura-500, #f9749f);
  background: linear-gradient(150deg, #fff 0%, var(--sakura-50, #fff7fa) 100%);
  box-shadow: 0 6px 16px -10px rgba(197, 58, 100, .55), inset 0 0 0 1px var(--sakura-100, #ffe4ec);
  transition: transform .5s cubic-bezier(.2, .8, .3, 1.2), color .3s;
}
.logo__mark svg {
  width: 20px;
  height: 20px;
  display: block;
}
.foot__brand:hover .logo__mark {
  transform: rotate(72deg) scale(1.06);
  color: var(--sakura-600, #e8547f);
}

.foot__name {
  display: flex;
  align-items: baseline;
  gap: 8px;
  font-family: var(--font-serif, "Noto Serif SC", serif);
  font-size: 15px;
  font-weight: 600;
  letter-spacing: 0.06em;
  color: var(--ink, #3b2f36);
}
.foot__name i {
  font-style: normal;
  font-family: var(--font-sans, inherit);
  font-size: 9.5px;
  font-weight: 600;
  letter-spacing: 0.24em;
  color: var(--sakura-400, #f791b4);
}
.foot__slogan {
  font-size: 12.5px;
  color: var(--muted, #8b7680);
  margin-top: 3px;
}

.foot__links {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}
.foot__link {
  border: 0;
  background: none;
  font: inherit;
  font-size: 13px;
  color: var(--muted, #8b7680);
  padding: 6px 13px;
  border-radius: 999px;
  cursor: pointer;
  transition: color .25s, background .25s, box-shadow .25s;
}
.foot__link:hover {
  color: var(--sakura-600, #e8547f);
  background: var(--sakura-50, #fff7fa);
  box-shadow: inset 0 0 0 1px var(--sakura-100, #ffe4ec);
}

.foot__meta {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
  font-size: 12px;
  color: var(--muted, #8b7680);
  opacity: .85;
}
.foot__dot {
  opacity: .45;
  color: var(--sakura-400, #f791b4);
}
</style>
