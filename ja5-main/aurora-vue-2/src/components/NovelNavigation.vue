<template>
  <section class="novel-nav" aria-labelledby="novel-nav-title">
    <!-- 局部樱花：与全局 PetalField 叠加，数量少、透明度低，保持干净 -->
    <span
      v-for="(petal, i) in petals"
      :key="i"
      class="novel-nav__petal"
      :style="petal"
      aria-hidden="true"
    ></span>

    <div class="novel-nav__head">
      <div>
        <p class="novel-nav__eyebrow">NOVEL ATLAS · 书页之外</p>
        <h2 id="novel-nav-title">小说阅读导航</h2>
        <p class="novel-nav__intro">循着花香走进四段故事，在另一个世界里小住片刻。</p>
      </div>
      <span class="novel-nav__count">4 部精选</span>
    </div>

    <div class="novel-nav__grid">
      <article
        v-for="(novel, index) in novels"
        :key="novel.key"
        class="novel-card"
        :style="{ '--accent': novel.accent, '--wash': novel.wash }"
      >
        <span class="novel-card__mark" aria-hidden="true">{{ novel.mark }}</span>

        <div class="novel-card__top">
          <span class="novel-card__genre">{{ novel.genre }}</span>
          <span class="novel-card__number">0{{ index + 1 }}</span>
        </div>

        <h3>{{ novel.title }}</h3>
        <p class="novel-card__desc">{{ novel.intro }}</p>

        <button
          class="novel-card__button"
          type="button"
          :aria-label="'前往阅读《' + novel.title + '》'"
          @click="openNovel(novel)"
        >
          前往阅读
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"
               stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <path d="M14 5h5v5M10 14l9-9M19 14v5H5V5h5" />
          </svg>
        </button>
      </article>
    </div>
  </section>
</template>

<script setup>
import { NOVEL_READING_LINKS } from '../config/novelLinks'
import { toast } from '../composables/useToast'

const novels = [
  {
    key: 'guZhenRen',
    title: '蛊真人',
    mark: '蛊',
    genre: '仙侠 · 谋略',
    intro: '以蛊入道，在残酷世界中步步为营，谱写一段冷峻而执着的逆命之旅。',
    url: NOVEL_READING_LINKS.guZhenRen,
    accent: '#df7fa8',
    wash: 'rgba(255, 239, 247, .88)'
  },
  {
    key: 'longZu',
    title: '龙族',
    mark: '龙',
    genre: '青春 · 幻想',
    intro: '平凡少年踏入龙族世界，在热血与孤独交织的冒险中，寻找自己的归宿。',
    url: NOVEL_READING_LINKS.longZu,
    accent: '#a68bd4',
    wash: 'rgba(246, 240, 255, .9)'
  },
  {
    key: 'fanRenXiuXianZhuan',
    title: '凡人修仙传',
    mark: '凡',
    genre: '仙侠 · 修真',
    intro: '一介凡人踏入仙途，凭谨慎与坚持穿越漫长岁月，逐梦长生大道。',
    url: NOVEL_READING_LINKS.fanRenXiuXianZhuan,
    accent: '#d792ae',
    wash: 'rgba(255, 244, 250, .9)'
  },
  {
    key: 'guiMiZhiZhu',
    title: '诡秘之主',
    mark: '诡',
    genre: '奇幻 · 蒸汽',
    intro: '蒸汽与神秘交织的时代，追随克莱恩拨开迷雾，踏上升阶与救赎之路。',
    url: NOVEL_READING_LINKS.guiMiZhiZhu,
    accent: '#9b91c9',
    wash: 'rgba(243, 241, 255, .9)'
  }
]

const petals = [
  { left: '7%', animationDelay: '-2s', animationDuration: '11s', '--drift': '36px' },
  { left: '29%', animationDelay: '-7s', animationDuration: '13s', '--drift': '-28px' },
  { left: '53%', animationDelay: '-4s', animationDuration: '12s', '--drift': '42px' },
  { left: '76%', animationDelay: '-9s', animationDuration: '14s', '--drift': '-34px' },
  { left: '93%', animationDelay: '-5s', animationDuration: '12.5s', '--drift': '24px' }
]

function openNovel (novel) {
  const url = (novel.url || '').trim()
  if (!url) {
    toast.info(`《${novel.title}》的阅读地址待配置`)
    return
  }
  if (!/^https?:\/\//i.test(url)) {
    toast.error('阅读地址需以 http:// 或 https:// 开头')
    return
  }
  window.open(url, '_blank', 'noopener,noreferrer')
}
</script>

<style scoped>
.novel-nav {
  position: relative;
  margin: 12px 0 42px;
  padding: 28px;
  overflow: hidden;
  border: 1px solid rgba(220, 184, 213, .42);
  border-radius: 28px;
  background:
    radial-gradient(circle at 92% 4%, rgba(204, 176, 232, .24), transparent 34%),
    linear-gradient(135deg, rgba(255, 255, 255, .82), rgba(252, 238, 249, .7));
  box-shadow: var(--gloss), 0 22px 54px -40px rgba(122, 76, 117, .58);
  backdrop-filter: blur(14px);
}

.novel-nav__head {
  position: relative;
  z-index: 1;
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 20px;
  margin-bottom: 22px;
}
.novel-nav__eyebrow {
  margin: 0 0 8px;
  color: var(--sakura-500);
  font-size: 10px;
  font-weight: 600;
  letter-spacing: .2em;
}
.novel-nav__head h2 {
  margin: 0;
  color: var(--ink);
  font-family: var(--font-serif);
  font-size: 25px;
  font-weight: 600;
  letter-spacing: .06em;
}
.novel-nav__intro {
  margin: 9px 0 0;
  color: var(--muted);
  font-size: 12.5px;
  line-height: 1.7;
}
.novel-nav__count {
  flex: none;
  padding: 7px 13px;
  border: 1px solid rgba(223, 127, 168, .2);
  border-radius: 999px;
  background: rgba(255, 255, 255, .56);
  color: var(--sakura-600);
  font-size: 11px;
  letter-spacing: .08em;
}

.novel-nav__grid {
  position: relative;
  z-index: 1;
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 14px;
}
.novel-card {
  position: relative;
  display: flex;
  flex-direction: column;
  min-width: 0;
  min-height: 248px;
  padding: 19px;
  overflow: hidden;
  border: 1px solid rgba(218, 187, 211, .4);
  border-radius: 21px;
  background: linear-gradient(155deg, rgba(255, 255, 255, .94), var(--wash));
  box-shadow: 0 12px 26px -24px rgba(116, 74, 111, .72);
  transition: transform .3s var(--ease), border-color .3s var(--ease), box-shadow .3s var(--ease);
}
.novel-card:hover {
  transform: translateY(-5px);
  border-color: var(--accent);
  box-shadow: 0 22px 36px -25px rgba(126, 79, 121, .56);
}
.novel-card__mark {
  position: absolute;
  right: 11px;
  bottom: 54px;
  color: var(--accent);
  font-family: var(--font-serif);
  font-size: 76px;
  font-weight: 600;
  line-height: 1;
  opacity: .065;
  pointer-events: none;
}
.novel-card__top {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
}
.novel-card__genre {
  padding: 5px 9px;
  border: 1px solid rgba(255, 255, 255, .8);
  border-radius: 999px;
  background: rgba(255, 255, 255, .5);
  color: var(--accent);
  font-size: 10px;
  letter-spacing: .08em;
}
.novel-card__number {
  color: var(--accent);
  font-family: var(--font-serif);
  font-size: 13px;
  font-style: italic;
  opacity: .6;
}
.novel-card h3 {
  position: relative;
  margin: 18px 0 9px;
  color: var(--ink);
  font-family: var(--font-serif);
  font-size: 22px;
  font-weight: 600;
  letter-spacing: .04em;
}
.novel-card__desc {
  position: relative;
  margin: 0 0 18px;
  color: var(--muted);
  font-size: 12px;
  line-height: 1.85;
}
.novel-card__button {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  width: 100%;
  min-height: 39px;
  margin-top: auto;
  padding: 0 13px;
  border: 0;
  border-radius: 12px;
  background: linear-gradient(125deg, var(--accent), var(--sakura-500));
  box-shadow: 0 9px 18px -14px var(--accent);
  color: #fff;
  font: inherit;
  font-size: 12px;
  letter-spacing: .06em;
  cursor: pointer;
  transition: transform .25s var(--ease), box-shadow .25s var(--ease), filter .25s var(--ease);
}
.novel-card__button:hover {
  transform: translateY(-1px);
  filter: saturate(1.08) brightness(1.03);
  box-shadow: 0 12px 22px -13px var(--accent);
}
.novel-card__button:active { transform: translateY(0); }
.novel-card__button:focus-visible { outline: 3px solid rgba(223, 127, 168, .25); outline-offset: 2px; }
.novel-card__button svg { width: 15px; height: 15px; }

.novel-nav__petal {
  position: absolute;
  z-index: 0;
  top: -18px;
  width: 10px;
  height: 7px;
  border-radius: 80% 20% 70% 30%;
  background: linear-gradient(135deg, rgba(255, 214, 231, .8), rgba(202, 164, 222, .52));
  opacity: 0;
  pointer-events: none;
  animation: novel-petal-fall 12s linear infinite;
}
@keyframes novel-petal-fall {
  0%   { transform: translate3d(0, -20px, 0) rotate(0deg); opacity: 0; }
  12%  { opacity: .52; }
  82%  { opacity: .3; }
  100% { transform: translate3d(var(--drift), 390px, 0) rotate(250deg); opacity: 0; }
}

@media (max-width: 1080px) {
  .novel-nav__grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
  .novel-card { min-height: 224px; }
}

@media (max-width: 720px) {
  .novel-nav { margin-bottom: 30px; padding: 21px 17px; border-radius: 23px; }
  .novel-nav__head { gap: 12px; margin-bottom: 18px; }
  .novel-nav__head h2 { font-size: 22px; }
  .novel-nav__intro { font-size: 12px; }
  .novel-nav__eyebrow { font-size: 9px; letter-spacing: .14em; }
  .novel-nav__count { padding: 6px 10px; font-size: 10px; }
  .novel-nav__grid { grid-template-columns: 1fr; }
  .novel-card { min-height: 218px; }
}

@media (prefers-reduced-motion: reduce) {
  .novel-nav__petal { display: none; }
  .novel-card, .novel-card__button { transition: none; }
}
</style>
