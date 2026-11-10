<template>
  <div class="page">
    <SiteNav :user="user" active="game" @go="$emit('navigate', $event)" @logout="$emit('logout')" />

    <main class="subpage main">
      <header class="subhead">
        <span class="subhead__tag">Game</span>
        <h1>花瓣贪吃蛇</h1>
        <p>在夜樱色的花田里追着飘落的花瓣跑 —— 撞上边栏或自己的尾巴，这一场春风就停了。</p>
      </header>

      <GameSwitch active="game" @select="$emit('navigate', $event)" />

      <!-- ============ 游戏区 ============ -->
      <section class="stage">
        <div class="hud">
          <div class="hud__stats">
            <div class="stat"><b>{{ score }}</b><span>得分</span></div>
            <div class="stat"><b>{{ best }}</b><span>最高分</span></div>
            <div class="stat"><b>{{ planets }}</b><span>吃到花瓣</span></div>
            <div class="stat"><b>{{ speedLabel }}</b><span>速度</span></div>
          </div>
          <div class="hud__btns">
            <button class="gbtn gbtn--ghost" type="button" :disabled="phase === 'ready' || phase === 'over'"
                    @click="togglePause">{{ phase === 'paused' ? '继续' : '暂停' }}</button>
            <button class="gbtn gbtn--ghost" type="button" @click="restart">重开</button>
            <button class="gbtn gbtn--ghost" type="button" @click="toggleFullscreen">
              {{ fullscreen ? '退出全屏' : '全屏' }}
            </button>
          </div>
        </div>

        <div class="board" ref="boardWrap">
          <canvas ref="canvas"
                  @pointerdown="onPointerDown"
                  @pointerup="onPointerUp"
                  @pointercancel="onPointerUp"></canvas>

          <!-- 虚拟方向键（触屏 / 窄屏显示） -->
          <div class="dpad">
            <button class="dpad__btn dpad__up"    type="button" aria-label="上" @click="setDir(0, -1)">▲</button>
            <button class="dpad__btn dpad__left"  type="button" aria-label="左" @click="setDir(-1, 0)">◀</button>
            <button class="dpad__btn dpad__right" type="button" aria-label="右" @click="setDir(1, 0)">▶</button>
            <button class="dpad__btn dpad__down"  type="button" aria-label="下" @click="setDir(0, 1)">▼</button>
          </div>

          <!-- 开始遮罩 -->
          <div v-if="phase === 'ready'" class="overlay">
            <div class="ov">
              <span class="ov__badge">SAKURA SNAKE</span>
              <h2 class="ov__title">风起了</h2>
              <p class="ov__text">追着花瓣，让自己越跑越长<br />淡粉花瓣 <i class="c-cyan">+10</i> · 金色花瓣 <i class="c-gold">+50</i></p>
              <button class="gbtn gbtn--big" type="button" @click="start">开始游戏</button>
              <p class="ov__hint">方向键 / WASD 移动 · 空格暂停 · 触屏可滑动或使用方向键</p>
            </div>
          </div>

          <!-- 暂停遮罩 -->
          <div v-else-if="phase === 'paused'" class="overlay">
            <div class="ov">
              <span class="ov__badge">PAUSED</span>
              <h2 class="ov__title">风停在半空</h2>
              <button class="gbtn gbtn--big" type="button" @click="togglePause">继续奔跑</button>
              <p class="ov__hint">按空格也可以继续</p>
            </div>
          </div>

          <!-- 结算遮罩 -->
          <div v-else-if="phase === 'over'" class="overlay">
            <div class="ov">
              <span class="ov__badge" :class="{ 'ov__badge--gold': isNewRecord }">{{ isNewRecord ? 'NEW RECORD' : 'GAME OVER' }}</span>
              <h2 class="ov__title">{{ isNewRecord ? '新的花冠！' : '花落一地' }}</h2>
              <div class="ov__score">{{ score }}</div>
              <p class="ov__text">接住 {{ planets }} 片花瓣 · 时长 {{ timeLabel }} · 速度 {{ speedLabel }}</p>

              <div class="ov__submit">
                <button v-if="user && score > 0 && submitState !== 'done'"
                        class="gbtn" type="button" :disabled="submitState === 'submitting'"
                        @click="doSubmit">
                  {{ submitState === 'submitting' ? '上传中…' : '提交成绩上榜' }}
                </button>
                <p v-if="submitMsg" class="ov__msg" :class="{ 'ov__msg--err': submitState === 'error' }">{{ submitMsg }}</p>
                <p v-else-if="user && score === 0" class="ov__msg">至少接住一片花瓣才能上榜</p>
                <p v-else-if="!user" class="ov__msg">登录后即可上传成绩参与排名</p>
              </div>

              <button class="gbtn gbtn--big" type="button" @click="restart">再来一局</button>
              <p class="ov__hint">按回车快速重开</p>
            </div>
          </div>
        </div>
      </section>

      <!-- ============ 排行榜 / 战绩 / 玩法 ============ -->
      <section class="panels">
        <div class="card">
          <div class="card__head">
            <h2 class="card__title">花榜 TOP 10</h2>
            <button class="link" type="button" @click="loadLeaderboard">刷新</button>
          </div>
          <div v-if="lbLoading" class="hint">正在翻阅花名册…</div>
          <div v-else-if="lbError" class="hint hint--err">{{ lbError }}</div>
          <div v-else-if="!leaderboard.length" class="hint">还没有人上榜，快来写下第一个名字</div>
          <ol v-else class="rank">
            <li v-for="(it, i) in leaderboard" :key="i" class="rank__row"
                :class="{ 'rank__row--me': !!user && it.nickname === user.name }">
              <span class="rank__no" :class="i < 3 ? 'rank__no--top' : ''">{{ i + 1 }}</span>
              <span class="rank__name" :title="it.nickname">{{ it.nickname }}</span>
              <span class="rank__score">{{ it.score }}</span>
              <span class="rank__meta">{{ it.length }}节 · {{ fmtDur(it.duration) }}</span>
            </li>
          </ol>
        </div>

        <div class="card">
          <h2 class="card__title">我的战绩</h2>
          <div v-if="user" class="mystats">
            <div class="stat stat--lg"><b>{{ myBest.best || 0 }}</b><span>最高分</span></div>
            <div class="stat stat--lg"><b>{{ myBest.rank ? 'No.' + myBest.rank : '—' }}</b><span>排名</span></div>
            <div class="stat stat--lg"><b>{{ myBest.playCount || 0 }}</b><span>总局数</span></div>
          </div>
          <p v-else class="hint">登录后可上传成绩并参与全站排名</p>
          <p class="hint" v-if="user">结算界面点击「提交成绩上榜」，就能把这一局写进花榜</p>
        </div>

        <div class="card card--tip">
          <h2 class="card__title">玩法</h2>
          <ul class="rules">
            <li>方向键 / WASD 改变方向，不能直接掉头</li>
            <li>淡粉花瓣 <i class="c-cyan">+10</i> 分，金色花瓣 <i class="c-gold">+50</i> 分且更罕见</li>
            <li>每接住一片花瓣速度就会变快，越到后面越刺激</li>
            <li>撞上边栏或自己的尾巴即结束本局</li>
          </ul>
        </div>
      </section>

      <footer class="foot">
        <span>樱见 · 花瓣贪吃蛇</span>
        <span class="foot__dot"></span>
        <span>成绩通过 /api/game 接口入库</span>
      </footer>
    </main>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue'
import SiteNav from './SiteNav.vue'
import GameSwitch from './GameSwitch.vue'
import { submitScore, fetchLeaderboard, fetchMyBest } from '../api/game'

const props = defineProps({
  user: { type: Object, default: null }
})
defineEmits(['navigate', 'logout'])

/* ============ 常量 ============ */
const COLS = 21
const ROWS = 21
const BASE_INTERVAL = 150   // 初始每步毫秒数
const MIN_INTERVAL = 68     // 最快每步毫秒数
const SPEEDUP = 4           // 每吃一颗星球加快的毫秒数
const PTS_NORMAL = 10
const PTS_GOLDEN = 50
const GOLDEN_RATE = 0.12
const BEST_KEY = 'aurora_snake_best'

const PLANETS = [
  { a: '#67e8f9', b: '#0e7490' },
  { a: '#a78bfa', b: '#5b21b6' },
  { a: '#f9a8d4', b: '#be185d' },
  { a: '#93c5fd', b: '#1d4ed8' },
  { a: '#fcd34d', b: '#b45309' }
]
const GOLD = { a: '#fef3c7', b: '#d97706' }

/* ============ 响应式状态（驱动 HUD / 遮罩 / 榜单） ============ */
const phase = ref('ready')        // ready | running | paused | over
const score = ref(0)
const planets = ref(0)
const best = ref(Number(localStorage.getItem(BEST_KEY)) || 0)
const speedLabel = ref('×1.0')
const isNewRecord = ref(false)
const timeLabel = ref('00:00')
const fullscreen = ref(false)

const leaderboard = ref([])
const lbLoading = ref(true)
const lbError = ref('')
const myBest = ref({ best: 0, rank: 0, playCount: 0 })
const submitState = ref('idle')   // idle | submitting | done | error
const submitMsg = ref('')

/* ============ 非响应式游戏状态 ============ */
const G = {
  snake: [], prev: [],
  dir: { x: 1, y: 0 }, nextDir: { x: 1, y: 0 },
  food: null,
  acc: 0, last: 0, elapsedMs: 0,
  interval: BASE_INTERVAL,
  particles: [], pops: [], stars: [],
  flash: 0, shake: 0,
  raf: null
}

/* ============ canvas ============ */
const canvas = ref(null)
const boardWrap = ref(null)
let ctx = null
let W = 0, H = 0, cell = 0
let ro = null

function buildStars () {
  const n = Math.max(60, Math.min(170, Math.round((W * H) / 8000)))
  G.stars = Array.from({ length: n }, () => {
    const near = Math.random() < 0.35
    return {
      x: Math.random() * W,
      y: Math.random() * H,
      r: near ? 1 + Math.random() * 0.9 : 0.4 + Math.random() * 0.6,
      a: near ? 0.5 + Math.random() * 0.4 : 0.25 + Math.random() * 0.35,
      v: near ? 0.016 : 0.006,
      tw: Math.random() * 6.28
    }
  })
}

function resize () {
  const wrap = boardWrap.value
  const cvs = canvas.value
  if (!wrap || !cvs) return
  const rect = wrap.getBoundingClientRect()
  const size = Math.max(240, Math.min(rect.width, rect.height || rect.width))
  const dpr = Math.min(window.devicePixelRatio || 1, 2)
  cvs.width = Math.round(size * dpr)
  cvs.height = Math.round(size * dpr)
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
  W = size
  H = size
  cell = size / COLS
  buildStars()
}

/* ============ 游戏流程 ============ */
function reset () {
  const cy = Math.floor(ROWS / 2)
  const cx = Math.floor(COLS / 2)
  G.snake = [{ x: cx, y: cy }, { x: cx - 1, y: cy }, { x: cx - 2, y: cy }]
  G.prev = G.snake.map(s => ({ ...s }))
  G.dir = { x: 1, y: 0 }
  G.nextDir = { x: 1, y: 0 }
  G.acc = 0
  G.elapsedMs = 0
  G.interval = BASE_INTERVAL
  G.particles = []
  G.pops = []
  G.flash = 0
  G.shake = 0
  spawnFood()
  score.value = 0
  planets.value = 0
  speedLabel.value = '×1.0'
  timeLabel.value = '00:00'
  isNewRecord.value = false
  submitState.value = 'idle'
  submitMsg.value = ''
}

function start () {
  reset()
  phase.value = 'running'
  G.last = 0
}

function restart () {
  start()
}

function togglePause () {
  if (phase.value === 'running') {
    phase.value = 'paused'
  } else if (phase.value === 'paused') {
    phase.value = 'running'
    G.last = 0
  }
}

function spawnFood () {
  const empty = []
  for (let y = 0; y < ROWS; y++) {
    for (let x = 0; x < COLS; x++) {
      if (!G.snake.some(s => s.x === x && s.y === y)) empty.push({ x, y })
    }
  }
  if (!empty.length) { G.food = null; return win() }
  const spot = empty[Math.floor(Math.random() * empty.length)]
  const golden = Math.random() < GOLDEN_RATE
  G.food = {
    ...spot,
    golden,
    palette: golden ? GOLD : PLANETS[Math.floor(Math.random() * PLANETS.length)],
    ring: !golden && Math.random() < 0.45,
    ringAngle: Math.random() * Math.PI,
    phase: Math.random() * 6.28
  }
}

function win () {
  phase.value = 'over'
  G.flash = 1
}

function die (headPx) {
  phase.value = 'over'
  G.flash = 1
  G.shake = 9
  burst(headPx.x, headPx.y, '#ff5fa2', 22)
  const prevBest = best.value
  if (score.value > prevBest) {
    best.value = score.value
    isNewRecord.value = true
    localStorage.setItem(BEST_KEY, String(score.value))
  }
}

function step () {
  G.prev = G.snake.map(s => ({ ...s }))
  // 不允许 180° 掉头
  if (G.nextDir.x !== -G.dir.x || G.nextDir.y !== -G.dir.y) {
    G.dir = { ...G.nextDir }
  }
  const head = { x: G.snake[0].x + G.dir.x, y: G.snake[0].y + G.dir.y }

  if (head.x < 0 || head.y < 0 || head.x >= COLS || head.y >= ROWS) {
    return die({ x: (G.snake[0].x + 0.5) * cell, y: (G.snake[0].y + 0.5) * cell })
  }
  const willGrow = !!G.food && head.x === G.food.x && head.y === G.food.y
  // 不生长时尾巴会让出一格，允许尾巴格进入（经典规则）
  const body = willGrow ? G.snake : G.snake.slice(0, -1)
  if (body.some(s => s.x === head.x && s.y === head.y)) {
    return die({ x: (head.x + 0.5) * cell, y: (head.y + 0.5) * cell })
  }

  G.snake.unshift(head)
  if (willGrow) {
    const golden = G.food.golden
    const pts = golden ? PTS_GOLDEN : PTS_NORMAL
    score.value += pts
    planets.value += 1
    G.interval = Math.max(MIN_INTERVAL, BASE_INTERVAL - planets.value * SPEEDUP)
    speedLabel.value = '×' + (BASE_INTERVAL / G.interval).toFixed(1)
    burst((head.x + 0.5) * cell, (head.y + 0.5) * cell, G.food.palette.a, golden ? 20 : 12)
    G.pops.push({
      x: (head.x + 0.5) * cell, y: (head.y + 0.5) * cell,
      text: '+' + pts, life: 900, max: 900,
      color: golden ? '#fcd34d' : '#67e8f9'
    })
    spawnFood()
  } else {
    G.snake.pop()
  }
}

/* ============ 特效 ============ */
function burst (x, y, color, n) {
  for (let i = 0; i < n; i++) {
    const ang = Math.random() * Math.PI * 2
    const sp = 0.04 + Math.random() * 0.14
    G.particles.push({
      x, y,
      vx: Math.cos(ang) * sp, vy: Math.sin(ang) * sp,
      life: 420 + Math.random() * 380, max: 800,
      r: 1 + Math.random() * 2.4,
      color
    })
  }
}

/* ============ 主循环 ============ */
function loop (ts) {
  const dt = G.last ? Math.min(ts - G.last, 100) : 16
  G.last = ts

  if (phase.value === 'running') {
    G.elapsedMs += dt
    const total = Math.floor(G.elapsedMs / 1000)
    const label = String(Math.floor(total / 60)).padStart(2, '0') + ':' + String(total % 60).padStart(2, '0')
    if (label !== timeLabel.value) timeLabel.value = label

    G.acc += dt
    let guard = 0
    while (G.acc >= G.interval && phase.value === 'running' && guard++ < 4) {
      G.acc -= G.interval
      step()
    }
    if (phase.value !== 'running') G.acc = 0
  }

  // 粒子 / 浮字
  for (const p of G.particles) {
    p.x += p.vx * dt
    p.y += p.vy * dt
    p.life -= dt
  }
  G.particles = G.particles.filter(p => p.life > 0)
  for (const p of G.pops) {
    p.y -= dt * 0.03
    p.life -= dt
  }
  G.pops = G.pops.filter(p => p.life > 0)
  if (G.flash > 0) G.flash = Math.max(0, G.flash - dt * 0.002)
  if (G.shake > 0) G.shake = Math.max(0, G.shake - dt * 0.03)

  render(ts)
  G.raf = requestAnimationFrame(loop)
}

/* ============ 渲染 ============ */
function render (ts) {
  if (!ctx) return
  const t = ts || 0

  ctx.save()
  if (G.shake > 0.4) {
    ctx.translate((Math.random() - 0.5) * G.shake, (Math.random() - 0.5) * G.shake)
  }

  // 深空底
  const bg = ctx.createLinearGradient(0, 0, W, H)
  bg.addColorStop(0, '#1a1020')
  bg.addColorStop(0.5, '#120a18')
  bg.addColorStop(1, '#1d0f1c')
  ctx.fillStyle = bg
  ctx.fillRect(-20, -20, W + 40, H + 40)

  // 星云（低透明度极光斑，呼应 AuroraBackground）
  ctx.globalCompositeOperation = 'lighter'
  const m = Math.min(W, H)
  const blobs = [
    { x: 0.2, y: 0.24, r: 0.6, c: '249,116,159', s: 0.0002, p: 0 },
    { x: 0.82, y: 0.2, r: 0.5, c: '90,169,221', s: 0.00016, p: 2.1 },
    { x: 0.74, y: 0.82, r: 0.55, c: '232,84,127', s: 0.00013, p: 4.2 }
  ]
  for (const b of blobs) {
    const bx = (b.x + Math.sin(t * b.s + b.p) * 0.1) * W
    const by = (b.y + Math.cos(t * b.s * 1.27 + b.p) * 0.09) * H
    const br = b.r * m * (0.85 + Math.sin(t * b.s * 1.9 + b.p) * 0.15)
    const g = ctx.createRadialGradient(bx, by, 0, bx, by, br)
    g.addColorStop(0, `rgba(${b.c},.13)`)
    g.addColorStop(0.45, `rgba(${b.c},.04)`)
    g.addColorStop(1, `rgba(${b.c},0)`)
    ctx.fillStyle = g
    ctx.beginPath()
    ctx.arc(bx, by, br, 0, 6.2832)
    ctx.fill()
  }

  // 星星（两层视差 + 闪烁）
  for (const s of G.stars) {
    s.x += s.v * 16
    if (s.x > W + 2) s.x = -2
    const tw = 0.72 + 0.28 * Math.sin(t * 0.002 + s.tw)
    ctx.fillStyle = `rgba(255,232,242,${s.a * tw})`
    ctx.beginPath()
    ctx.arc(s.x, s.y, s.r, 0, 6.2832)
    ctx.fill()
  }
  ctx.globalCompositeOperation = 'source-over'

  // 网格
  ctx.strokeStyle = 'rgba(255,196,217,.06)'
  ctx.lineWidth = 1
  ctx.beginPath()
  for (let i = 1; i < COLS; i++) {
    ctx.moveTo(i * cell + 0.5, 0)
    ctx.lineTo(i * cell + 0.5, H)
    ctx.moveTo(0, i * cell + 0.5)
    ctx.lineTo(W, i * cell + 0.5)
  }
  ctx.stroke()

  // 星球食物
  if (G.food) drawPlanet(t)

  // 光蛇
  drawSnake()

  // 粒子
  ctx.globalCompositeOperation = 'lighter'
  for (const p of G.particles) {
    ctx.globalAlpha = Math.max(p.life / p.max, 0)
    ctx.fillStyle = p.color
    ctx.beginPath()
    ctx.arc(p.x, p.y, p.r, 0, 6.2832)
    ctx.fill()
  }
  ctx.globalAlpha = 1
  ctx.globalCompositeOperation = 'source-over'

  // 浮字
  ctx.textAlign = 'center'
  ctx.font = `600 ${Math.round(cell * 0.62)}px "Outfit","Noto Sans SC",sans-serif`
  for (const p of G.pops) {
    ctx.globalAlpha = Math.max(p.life / p.max, 0)
    ctx.fillStyle = p.color
    ctx.fillText(p.text, p.x, p.y)
  }
  ctx.globalAlpha = 1

  // 边框
  ctx.strokeStyle = 'rgba(124,92,255,.28)'
  ctx.lineWidth = 2
  ctx.strokeRect(1, 1, W - 2, H - 2)

  // 画布内 HUD（全屏时也能看到成绩）
  ctx.textAlign = 'left'
  ctx.font = `500 ${Math.round(cell * 0.5)}px "Outfit","Noto Sans SC",sans-serif`
  ctx.fillStyle = 'rgba(238,242,255,.82)'
  ctx.fillText('SCORE ' + score.value, cell * 0.55, cell * 0.95)
  ctx.textAlign = 'right'
  ctx.fillStyle = 'rgba(141,151,189,.75)'
  ctx.fillText('BEST ' + best.value, W - cell * 0.55, cell * 0.95)

  // 死亡红闪
  if (G.flash > 0) {
    ctx.fillStyle = `rgba(255,95,120,${0.22 * G.flash})`
    ctx.fillRect(0, 0, W, H)
  }

  ctx.restore()
}

function drawPlanet (t) {
  const f = G.food
  const cx = (f.x + 0.5) * cell
  const cy = (f.y + 0.5) * cell
  const pulse = 1 + Math.sin(t * 0.004 + f.phase) * 0.07
  const r = cell * (f.golden ? 0.46 : 0.4) * pulse
  const pal = f.palette

  // 光晕
  ctx.globalCompositeOperation = 'lighter'
  const halo = ctx.createRadialGradient(cx, cy, 0, cx, cy, r * 2.6)
  halo.addColorStop(0, hexA(pal.a, f.golden ? 0.5 : 0.32))
  halo.addColorStop(1, hexA(pal.a, 0))
  ctx.fillStyle = halo
  ctx.beginPath()
  ctx.arc(cx, cy, r * 2.6, 0, 6.2832)
  ctx.fill()
  ctx.globalCompositeOperation = 'source-over'

  // 环（后半）
  if (f.ring) drawRing(cx, cy, r, f.ringAngle, 0.35, 'back')

  // 球体
  const g = ctx.createRadialGradient(cx - r * 0.38, cy - r * 0.42, r * 0.1, cx, cy, r)
  g.addColorStop(0, pal.a)
  g.addColorStop(0.55, pal.b)
  g.addColorStop(1, shade(pal.b, -0.35))
  ctx.fillStyle = g
  ctx.beginPath()
  ctx.arc(cx, cy, r, 0, 6.2832)
  ctx.fill()

  // 高光
  ctx.fillStyle = 'rgba(255,255,255,.5)'
  ctx.beginPath()
  ctx.ellipse(cx - r * 0.34, cy - r * 0.42, r * 0.22, r * 0.13, -0.6, 0, 6.2832)
  ctx.fill()

  // 环（前半）
  if (f.ring) drawRing(cx, cy, r, f.ringAngle, 0.85, 'front')

  // 金色星球：十字星芒
  if (f.golden) {
    ctx.globalCompositeOperation = 'lighter'
    const spark = 0.55 + 0.45 * Math.sin(t * 0.006 + f.phase)
    ctx.strokeStyle = hexA('#fde68a', 0.8 * spark)
    ctx.lineWidth = Math.max(1, r * 0.12)
    ctx.beginPath()
    ctx.moveTo(cx - r * 1.9, cy)
    ctx.lineTo(cx + r * 1.9, cy)
    ctx.moveTo(cx, cy - r * 1.9)
    ctx.lineTo(cx, cy + r * 1.9)
    ctx.stroke()
    ctx.globalCompositeOperation = 'source-over'
  }
}

function drawRing (cx, cy, r, angle, alpha, half) {
  ctx.save()
  ctx.translate(cx, cy)
  ctx.rotate(angle)
  ctx.strokeStyle = `rgba(226,232,255,${alpha})`
  ctx.lineWidth = Math.max(1.2, r * 0.16)
  ctx.beginPath()
  if (half === 'back') {
    ctx.ellipse(0, 0, r * 1.65, r * 0.52, 0, Math.PI, 0)
  } else {
    ctx.ellipse(0, 0, r * 1.65, r * 0.52, 0, 0, Math.PI)
  }
  ctx.stroke()
  ctx.restore()
}

function drawSnake () {
  const p = phase.value === 'running' ? Math.min(G.acc / G.interval, 1) : 1
  const len = G.snake.length

  // 光晕 pass
  ctx.globalCompositeOperation = 'lighter'
  for (let i = 0; i < len; i++) {
    const cur = G.snake[i]
    const from = G.prev[i] || cur
    const x = (from.x + (cur.x - from.x) * p + 0.5) * cell
    const y = (from.y + (cur.y - from.y) * p + 0.5) * cell
    const hue = 190 + (268 - 190) * (i / Math.max(len - 1, 1))
    ctx.fillStyle = `hsla(${hue},90%,62%,.13)`
    ctx.beginPath()
    ctx.arc(x, y, cell * 0.62, 0, 6.2832)
    ctx.fill()
  }
  ctx.globalCompositeOperation = 'source-over'

  // 蛇身 pass
  for (let i = len - 1; i >= 0; i--) {
    const cur = G.snake[i]
    const from = G.prev[i] || cur
    const x = (from.x + (cur.x - from.x) * p + 0.5) * cell
    const y = (from.y + (cur.y - from.y) * p + 0.5) * cell
    const hue = 190 + (268 - 190) * (i / Math.max(len - 1, 1))
    const isHead = i === 0
    const r = cell * (isHead ? 0.47 : 0.4 + 0.05 * (1 - i / len))

    const g = ctx.createRadialGradient(x - r * 0.3, y - r * 0.35, r * 0.1, x, y, r)
    g.addColorStop(0, `hsl(${hue},95%,72%)`)
    g.addColorStop(1, `hsl(${hue},85%,${isHead ? 52 : 44}%)`)
    ctx.fillStyle = g
    ctx.beginPath()
    ctx.arc(x, y, r, 0, 6.2832)
    ctx.fill()

    if (isHead) {
      // 眼睛（朝向垂直移动方向时左右分开）
      const d = G.dir
      const px = d.y !== 0 ? 1 : 0
      const py = d.x !== 0 ? 1 : 0
      const ex = x + d.x * r * 0.34
      const ey = y + d.y * r * 0.34
      ctx.fillStyle = '#fff'
      for (const s of [-1, 1]) {
        ctx.beginPath()
        ctx.arc(ex + px * s * r * 0.34, ey + py * s * r * 0.34, r * 0.13, 0, 6.2832)
        ctx.fill()
      }
    }
  }
}

/* ============ 颜色工具 ============ */
function hexA (hex, a) {
  const n = parseInt(hex.slice(1), 16)
  return `rgba(${(n >> 16) & 255},${(n >> 8) & 255},${n & 255},${a})`
}
function shade (hex, amt) {
  const n = parseInt(hex.slice(1), 16)
  const f = (v) => Math.max(0, Math.min(255, Math.round(v + 255 * amt)))
  return `rgb(${f((n >> 16) & 255)},${f((n >> 8) & 255)},${f(n & 255)})`
}

/* ============ 输入 ============ */
function setDir (x, y) {
  if (phase.value === 'ready') start()
  if (phase.value !== 'running') return
  // 与当前方向相反则忽略（180° 掉头）
  if (x === -G.dir.x && y === -G.dir.y) return
  G.nextDir = { x, y }
}

const KEYMAP = {
  ArrowUp: [0, -1], ArrowDown: [0, 1], ArrowLeft: [-1, 0], ArrowRight: [1, 0],
  w: [0, -1], s: [0, 1], a: [-1, 0], d: [1, 0],
  W: [0, -1], S: [0, 1], A: [-1, 0], D: [1, 0]
}

function onKey (e) {
  const tag = (e.target && e.target.tagName) || ''
  if (tag === 'INPUT' || tag === 'TEXTAREA') return
  const dir = KEYMAP[e.key]
  if (dir) {
    e.preventDefault()
    setDir(dir[0], dir[1])
    return
  }
  if (e.key === ' ' || e.key === 'Spacebar') {
    e.preventDefault()
    if (phase.value === 'ready' || phase.value === 'over') start()
    else togglePause()
  } else if (e.key === 'Enter') {
    e.preventDefault()
    if (phase.value === 'ready' || phase.value === 'over') start()
    else if (phase.value === 'paused') togglePause()
  }
}

// 触屏滑动
let touchStart = null
function onPointerDown (e) {
  touchStart = { x: e.clientX, y: e.clientY }
}
function onPointerUp (e) {
  if (!touchStart) return
  const dx = e.clientX - touchStart.x
  const dy = e.clientY - touchStart.y
  touchStart = null
  if (Math.max(Math.abs(dx), Math.abs(dy)) < 24) return
  if (Math.abs(dx) > Math.abs(dy)) setDir(dx > 0 ? 1 : -1, 0)
  else setDir(0, dy > 0 ? 1 : -1)
}

// 切窗口自动暂停
function onBlur () {
  if (phase.value === 'running') togglePause()
}

/* ============ 全屏 ============ */
function toggleFullscreen () {
  const el = boardWrap.value
  if (!el) return
  if (!document.fullscreenElement) {
    const req = el.requestFullscreen || el.webkitRequestFullscreen
    if (req) req.call(el)
  } else {
    const exit = document.exitFullscreen || document.webkitExitFullscreen
    if (exit) exit.call(document)
  }
}
function onFsChange () {
  fullscreen.value = !!document.fullscreenElement
  requestAnimationFrame(resize)
}

/* ============ 数据 ============ */
async function loadLeaderboard () {
  lbLoading.value = true
  lbError.value = ''
  try {
    leaderboard.value = await fetchLeaderboard(10)
  } catch (e) {
    lbError.value = (e && e.message) || '排行榜加载失败'
  } finally {
    lbLoading.value = false
  }
}

async function loadMyBest () {
  if (!props.user) return
  try {
    myBest.value = await fetchMyBest()
  } catch (_) { /* 后端未启动时静默，保留默认值 */ }
}

async function doSubmit () {
  if (submitState.value === 'submitting') return
  submitState.value = 'submitting'
  submitMsg.value = ''
  try {
    const res = await submitScore({
      score: score.value,
      length: G.snake.length,
      duration: Math.round(G.elapsedMs / 1000)
    })
    submitState.value = 'done'
    submitMsg.value = res.isNewBest
      ? `新纪录！当前排名 No.${res.rank}`
      : `成绩已上传，本局排名 No.${res.rank}`
    myBest.value = { best: res.best, rank: res.rank, playCount: res.playCount }
    if (res.leaderboard) leaderboard.value = res.leaderboard
  } catch (e) {
    submitState.value = 'error'
    submitMsg.value = (e && e.message) || '上传失败，请稍后再试'
  }
}

function fmtDur (sec) {
  const s = Math.max(0, Number(sec) || 0)
  return String(Math.floor(s / 60)).padStart(2, '0') + ':' + String(s % 60).padStart(2, '0')
}

/* ============ 生命周期 ============ */
onMounted(() => {
  ctx = canvas.value.getContext('2d')
  resize()
  if (typeof ResizeObserver !== 'undefined') {
    ro = new ResizeObserver(() => resize())
    ro.observe(boardWrap.value)
  }
  window.addEventListener('resize', resize)
  window.addEventListener('keydown', onKey)
  window.addEventListener('blur', onBlur)
  document.addEventListener('fullscreenchange', onFsChange)
  document.addEventListener('webkitfullscreenchange', onFsChange)
  loadLeaderboard()
  loadMyBest()
  G.raf = requestAnimationFrame(loop)

  // 仅开发环境暴露的调试钩子（import.meta.env.DEV 在生产构建中为 false，
  // 整个代码块会被 tree-shaking 剔除）：供 E2E 读取游戏状态、精确导航
  if (import.meta.env && import.meta.env.DEV) {
    window.__snakeDebug = {
      get food () { return G.food },
      get head () { return G.snake[0] },
      get dir () { return G.dir },
      get phase () { return phase.value },
      get score () { return score.value }
    }
  }
})

onBeforeUnmount(() => {
  if (G.raf) cancelAnimationFrame(G.raf)
  if (ro) ro.disconnect()
  window.removeEventListener('resize', resize)
  window.removeEventListener('keydown', onKey)
  window.removeEventListener('blur', onBlur)
  document.removeEventListener('fullscreenchange', onFsChange)
  document.removeEventListener('webkitfullscreenchange', onFsChange)
})
</script>

<style scoped>
.page {
  position: relative;
  z-index: 2;
  width: 100%;
  min-height: 100vh;
}
.main {
  max-width: 960px;
  display: flex;
  flex-direction: column;
  gap: 22px;
}

/* ============ HUD ============ */
.stage {
  display: flex;
  flex-direction: column;
  gap: 14px;
  animation: rise .55s var(--ease) both;
}
.hud {
  display: flex;
  align-items: stretch;
  justify-content: space-between;
  gap: 0;
  flex-wrap: wrap;
  /* 与游戏面板同宽居中，视觉上成一整块 */
  width: 100%;
  max-width: 560px;
  margin: 0 auto;
  padding: 0;
  border-radius: 18px;
  background: var(--porcelain-flat);
  border: 1px solid var(--porcelain-line);
  box-shadow: var(--gloss), var(--lift);
  overflow: hidden;
}
/* 四格数据用发丝线分隔，右侧按钮组单独占一格 */
.hud__stats {
  display: grid;
  grid-template-columns: repeat(4, minmax(62px, auto));
  flex: 1;
  min-width: 0;
}
.hud__stats .stat {
  padding: 12px 18px;
  border-left: 1px solid var(--line-soft);
  min-width: 0;
}
.hud__stats .stat:first-child { border-left: 0; }
.stat b {
  display: block;
  font-family: var(--font-serif);
  font-size: 20px;
  font-weight: 600;
  line-height: 1.15;
  color: var(--ink);
  font-variant-numeric: tabular-nums;
}
.stat span {
  display: block;
  margin-top: 2px;
  font-size: 10.5px;
  color: var(--faint);
  letter-spacing: .1em;
  white-space: nowrap;
}
.stat--lg b { font-size: 24px; }
.hud__btns {
  display: flex;
  align-items: center;
  gap: 7px;
  padding: 10px 14px;
  border-left: 1px solid var(--line-soft);
  background: rgba(255, 244, 247, .55);
}

/* 通用游戏按钮 */
.gbtn {
  height: 36px;
  padding: 0 17px;
  border: 0;
  border-radius: 999px;
  cursor: pointer;
  font: inherit;
  font-size: 13px;
  font-weight: 600;
  color: #fff;
  background: linear-gradient(120deg, var(--sakura-500), var(--sakura-600));
  box-shadow: 0 12px 24px -16px rgba(232, 84, 127, .95);
  transition: transform .3s var(--ease), opacity .25s, box-shadow .3s;
}
.gbtn:hover:not(:disabled) { transform: translateY(-2px); }
.gbtn:disabled { cursor: not-allowed; opacity: .5; }
.gbtn--ghost {
  background: #fff;
  border: 1px solid var(--sakura-200);
  box-shadow: none;
  color: var(--sakura-600);
}
.gbtn--ghost:hover:not(:disabled) { background: var(--sakura-50); }
.gbtn--big {
  height: 46px;
  padding: 0 32px;
  font-size: 15px;
  margin-top: 4px;
}

/* ============ 棋盘 ============ */
.board {
  position: relative;
  width: 100%;
  max-width: 560px;
  margin: 0 auto;
  aspect-ratio: 1 / 1;
  border-radius: 22px;
  overflow: hidden;
  border: 1px solid var(--sakura-200);
  background: #150c1a;
  box-shadow:
    0 34px 70px -40px rgba(60, 20, 40, .9),
    0 0 0 8px rgba(255, 255, 255, .55),
    0 0 90px -46px rgba(249, 116, 159, .8);
}
.board canvas {
  display: block;
  width: 100%;
  height: 100%;
  touch-action: none;
  cursor: crosshair;
}
.board:fullscreen {
  max-width: none;
  width: auto;
  height: 100vh;
  aspect-ratio: 1 / 1;
  border-radius: 0;
  border: 0;
  box-shadow: none;
}

/* 遮罩 */
.overlay {
  position: absolute;
  inset: 0;
  z-index: 3;
  display: grid;
  place-items: center;
  text-align: center;
  padding: 22px;
  background: rgba(28, 14, 24, .78);
  backdrop-filter: blur(10px);
  animation: fade .35s var(--ease);
}
@keyframes fade { from { opacity: 0 } to { opacity: 1 } }
.ov {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  max-width: 420px;
}
.ov__badge {
  font-size: 10.5px;
  letter-spacing: .26em;
  color: #ffd0df;
  border: 1px solid rgba(255, 196, 217, .42);
  border-radius: 999px;
  padding: 3px 14px;
}
.ov__badge--gold {
  color: #ffe6a8;
  border-color: rgba(252, 211, 77, .55);
  box-shadow: 0 0 26px -6px rgba(252, 211, 77, .6);
}
.ov__title {
  margin: 0;
  font-family: var(--font-serif);
  font-size: clamp(24px, 3vw, 31px);
  font-weight: 600;
  letter-spacing: .04em;
  background: linear-gradient(100deg, #ffd6e4, #fff 45%, #ffb3cd);
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}
.ov__score {
  font-family: var(--font-serif);
  font-size: 54px;
  font-weight: 600;
  color: #fff;
  font-variant-numeric: tabular-nums;
  line-height: 1;
  text-shadow: 0 0 34px rgba(249, 116, 159, .75);
}
.ov__text {
  margin: 0;
  font-size: 13.5px;
  color: rgba(255, 232, 242, .8);
  line-height: 1.85;
}
.ov__hint {
  margin: 0;
  font-size: 11.5px;
  color: rgba(255, 220, 232, .5);
}
.ov__submit {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  min-height: 20px;
}
.ov__msg {
  margin: 0;
  font-size: 12.5px;
  color: #ffc4d9;
}
.ov__msg--err { color: #ff9db1; }
.c-cyan { font-style: normal; color: #8ecdf2; font-weight: 600; }
.c-gold { font-style: normal; color: #ffe6a8; font-weight: 600; }

/* 虚拟方向键 */
.dpad {
  position: absolute;
  right: 14px;
  bottom: 14px;
  z-index: 2;
  display: none;
  grid-template-columns: repeat(3, 46px);
  grid-template-rows: repeat(3, 40px);
  gap: 5px;
}
.dpad__btn {
  border: 1px solid rgba(255, 196, 217, .3);
  background: rgba(40, 20, 32, .6);
  backdrop-filter: blur(8px);
  color: #ffe4ee;
  border-radius: 10px;
  font-size: 13px;
  cursor: pointer;
  -webkit-user-select: none;
  user-select: none;
}
.dpad__btn:active { background: rgba(249, 116, 159, .45); }
.dpad__up { grid-column: 2; grid-row: 1; }
.dpad__left { grid-column: 1; grid-row: 2; }
.dpad__right { grid-column: 3; grid-row: 2; }
.dpad__down { grid-column: 2; grid-row: 3; }
@media (hover: none), (max-width: 640px) {
  .dpad { display: grid; }
}

/* ============ 榜单 / 战绩 / 玩法 ============ */
.panels {
  display: grid;
  grid-template-columns: 1.2fr 1fr;
  gap: 14px;
  align-items: start;
}
.panels .card--tip { grid-column: 1 / -1; }
.card {
  padding: 22px 26px;
  border-radius: 20px;
  background: rgba(255, 255, 255, .76);
  border: 1px solid var(--line-soft);
  box-shadow: 0 18px 38px -36px rgba(120, 60, 84, .9);
  animation: rise .55s var(--ease) both;
}
.card--tip {
  border-color: var(--sakura-200);
  background: linear-gradient(150deg, #fff, var(--sakura-50));
}
.card__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 14px;
}
.card__title {
  position: relative;
  margin: 0 0 14px;
  padding-left: 14px;
  font-family: var(--font-serif);
  font-size: 16px;
  font-weight: 600;
  letter-spacing: .04em;
  color: var(--ink);
}
.card__head .card__title { margin-bottom: 0; }
.card__title::before {
  content: '';
  position: absolute;
  left: 0;
  top: 50%;
  transform: translateY(-50%);
  width: 4px;
  height: 14px;
  border-radius: 3px;
  background: linear-gradient(180deg, var(--sakura-400), var(--sakura-600));
}
.link {
  background: none;
  border: 0;
  color: var(--sakura-500);
  font: inherit;
  font-size: 12.5px;
  cursor: pointer;
  padding: 0;
  transition: color .25s;
}
.link:hover { color: var(--sakura-700); }

.hint {
  margin: 0;
  font-size: 13px;
  color: var(--muted);
  line-height: 1.8;
}
.hint--err { color: var(--sakura-700); }

/* 排行榜 */
.rank {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
}
.rank__row {
  display: grid;
  grid-template-columns: 32px 1fr auto auto;
  align-items: center;
  gap: 12px;
  padding: 9px 6px;
  border-bottom: 1px solid var(--line-soft);
  font-size: 13.5px;
}
.rank__row:last-child { border-bottom: 0; }
.rank__row--me {
  background: linear-gradient(90deg, var(--sakura-50), transparent 80%);
  border-radius: 10px;
}
.rank__no {
  font-size: 12.5px;
  font-weight: 600;
  color: var(--faint);
  text-align: center;
  font-variant-numeric: tabular-nums;
}
.rank__no--top { color: var(--sakura-600); }
.rank__name {
  color: var(--ink);
  font-weight: 500;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.rank__score {
  font-weight: 700;
  color: var(--sakura-600);
  font-variant-numeric: tabular-nums;
}
.rank__meta {
  font-size: 11.5px;
  color: var(--faint);
  font-variant-numeric: tabular-nums;
  min-width: 84px;
  text-align: right;
}

/* 我的战绩 */
.mystats {
  display: flex;
  gap: 26px;
  flex-wrap: wrap;
  margin-bottom: 10px;
}

/* 玩法 */
.rules {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 9px;
  font-size: 13px;
  color: var(--ink-soft);
  line-height: 1.7;
}
.rules li {
  padding-left: 18px;
  position: relative;
}
.rules li::before {
  content: '';
  position: absolute;
  left: 0;
  top: .66em;
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--sakura-400);
}

/* 页脚 */
.foot {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 10px 0 2px;
  font-size: 12px;
  color: var(--faint);
  letter-spacing: .04em;
}
.foot__dot {
  width: 3px;
  height: 3px;
  border-radius: 50%;
  background: var(--sakura-300);
}

@keyframes rise {
  from { opacity: 0; transform: translateY(12px); }
  to { opacity: 1; transform: none; }
}

@media (max-width: 720px) {
  .panels { grid-template-columns: 1fr; }
}
@media (max-width: 640px) {
  /* 窄屏：数据四格换行到上排，按钮组独占下排 */
  .hud { flex-direction: column; }
  .hud__stats { grid-template-columns: repeat(4, minmax(0, 1fr)); }
  .hud__stats .stat { padding: 11px 10px; text-align: center; }
  .stat b { font-size: 17px; }
  .hud__btns { border-left: 0; border-top: 1px solid var(--line-soft); justify-content: center; }
  .board { max-width: 100%; }
  .card { padding: 18px; }
}
</style>
