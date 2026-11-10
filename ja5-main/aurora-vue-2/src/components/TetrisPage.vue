<template>
  <div class="page">
    <SiteNav :user="user" active="game" @go="$emit('navigate', $event)" @logout="$emit('logout')" />

    <main class="subpage main">
      <header class="subhead">
        <span class="subhead__tag">Game</span>
        <h1>樱落方块</h1>
        <p>让花瓣凝成的方块落满春夜，消除一行，就有一阵樱花掠过棋盘。</p>
      </header>

      <GameSwitch active="tetris" @select="$emit('navigate', $event)" />

      <section class="stage">
        <div class="hud">
          <div class="hud__stats">
            <div class="stat"><b>{{ score }}</b><span>得分</span></div>
            <div class="stat"><b>{{ best }}</b><span>最高分</span></div>
            <div class="stat"><b>{{ lines }}</b><span>消除行</span></div>
            <div class="stat"><b>Lv.{{ level }}</b><span>落下速度</span></div>
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

        <div class="arena">
          <div class="board-column">
            <div class="board" ref="boardWrap">
              <canvas ref="canvas"></canvas>

              <div v-if="phase === 'ready'" class="overlay">
                <div class="ov">
                  <span class="ov__badge">SAKURA TETRIS</span>
                  <h2 class="ov__title">花瓣待落</h2>
                  <p class="ov__text">旋转、移动、落下<br />把春夜凝成的方块拼成完整的一行</p>
                  <button class="gbtn gbtn--big" type="button" @click="start">开始游戏</button>
                  <p class="ov__hint">方向键移动 · ↑ / X 旋转 · 空格直落 · P 暂停</p>
                </div>
              </div>

              <div v-else-if="phase === 'paused'" class="overlay">
                <div class="ov">
                  <span class="ov__badge">PAUSED</span>
                  <h2 class="ov__title">花枝停在半空</h2>
                  <button class="gbtn gbtn--big" type="button" @click="togglePause">继续落下</button>
                  <p class="ov__hint">按 P 或空格也可以继续</p>
                </div>
              </div>

              <div v-else-if="phase === 'over'" class="overlay">
                <div class="ov">
                  <span class="ov__badge" :class="{ 'ov__badge--gold': isNewRecord }">
                    {{ isNewRecord ? 'NEW RECORD' : 'GAME OVER' }}
                  </span>
                  <h2 class="ov__title">{{ isNewRecord ? '新的花冠！' : '花瓣落满了' }}</h2>
                  <div class="ov__score">{{ score }}</div>
                  <p class="ov__text">消除 {{ lines }} 行 · 抵达 Lv.{{ level }} · 最高分 {{ best }}</p>
                  <button class="gbtn gbtn--big" type="button" @click="restart">再来一局</button>
                  <p class="ov__hint">按回车快速重开</p>
                </div>
              </div>
            </div>

            <div class="touch-pad" aria-label="触屏操作">
              <button type="button" aria-label="左移" @click="move(-1)">←</button>
              <button type="button" aria-label="旋转" @click="rotate">↻</button>
              <button type="button" aria-label="右移" @click="move(1)">→</button>
              <button type="button" aria-label="下落一格" @click="dropOne">↓</button>
              <button class="touch-pad__wide" type="button" aria-label="直接落下" @click="hardDrop">直落</button>
            </div>
          </div>

          <aside class="side">
            <div class="mini-card next-card">
              <div class="mini-card__head">
                <span>下一块</span>
                <i>NEXT</i>
              </div>
              <canvas ref="nextCanvas" class="next-canvas"></canvas>
            </div>

            <div class="mini-card progress-card">
              <div class="mini-card__head">
                <span>春日进度</span>
                <i>LEVEL {{ level }}</i>
              </div>
              <div class="level-track"><span :style="{ width: levelProgress + '%' }"></span></div>
              <p>再消除 <b>{{ linesToNext }}</b> 行进入下一等级</p>
            </div>

            <div class="mini-card rules-card">
              <div class="mini-card__head"><span>玩法</span><i>HOW TO</i></div>
              <ul>
                <li>← → 移动，↑ / X 旋转</li>
                <li>↓ 加速下落，空格直接落底</li>
                <li>一次消 4 行获得最高额外分</li>
                <li>方块堆到顶端时本局结束</li>
              </ul>
            </div>
          </aside>
        </div>
      </section>

      <footer class="foot">
        <span>樱见 · 樱落方块</span>
        <span class="foot__dot"></span>
        <span>最高分保存在本地浏览器</span>
      </footer>
    </main>
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import SiteNav from './SiteNav.vue'
import GameSwitch from './GameSwitch.vue'

defineProps({
  user: { type: Object, default: null }
})
defineEmits(['navigate', 'logout'])

const COLS = 10
const ROWS = 20
const BEST_KEY = 'aurora_tetris_best'

const SHAPES = {
  I: [[1, 1, 1, 1]],
  O: [[1, 1], [1, 1]],
  T: [[0, 1, 0], [1, 1, 1]],
  S: [[0, 1, 1], [1, 1, 0]],
  Z: [[1, 1, 0], [0, 1, 1]],
  J: [[1, 0, 0], [1, 1, 1]],
  L: [[0, 0, 1], [1, 1, 1]]
}

const COLORS = {
  I: { a: '#9bdcf0', b: '#5baecb', glow: 'rgba(120, 205, 234, .46)' },
  O: { a: '#f6d7a1', b: '#cca15d', glow: 'rgba(241, 198, 128, .44)' },
  T: { a: '#d4b7eb', b: '#9a77c1', glow: 'rgba(189, 154, 224, .44)' },
  S: { a: '#a9dec8', b: '#69ae94', glow: 'rgba(142, 211, 184, .42)' },
  Z: { a: '#efadbf', b: '#c66f8b', glow: 'rgba(233, 141, 168, .44)' },
  J: { a: '#b9c3ef', b: '#7c88c5', glow: 'rgba(152, 165, 229, .44)' },
  L: { a: '#f0b49e', b: '#c68066', glow: 'rgba(235, 167, 141, .44)' }
}

const phase = ref('ready')
const score = ref(0)
const best = ref(Number(localStorage.getItem(BEST_KEY)) || 0)
const lines = ref(0)
const level = ref(1)
const nextType = ref('T')
const isNewRecord = ref(false)
const fullscreen = ref(false)

const canvas = ref(null)
const boardWrap = ref(null)
const nextCanvas = ref(null)
let ctx = null
let nextCtx = null
let W = 0
let H = 0
let CELL = 0
let offsetX = 0
let offsetY = 0
let raf = null
let lastTime = 0
let acc = 0
let board = []
let piece = null
let bag = []
let dropInterval = 760
let particles = []
let stars = []
let ro = null
let bestAtStart = 0

const levelProgress = computed(() => (lines.value % 10) / 10 * 100)
const linesToNext = computed(() => 10 - (lines.value % 10))

function emptyBoard () {
  return Array.from({ length: ROWS }, () => Array(COLS).fill(''))
}

function shuffle (list) {
  const out = list.slice()
  for (let i = out.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [out[i], out[j]] = [out[j], out[i]]
  }
  return out
}

function takeType () {
  if (!bag.length) bag = shuffle(Object.keys(SHAPES))
  return bag.pop()
}

function cloneMatrix (matrix) {
  return matrix.map((row) => row.slice())
}

function spawn () {
  const type = nextType.value
  nextType.value = takeType()
  const matrix = cloneMatrix(SHAPES[type])
  piece = {
    type,
    matrix,
    x: Math.floor((COLS - matrix[0].length) / 2),
    y: 0
  }
  drawNext()
  if (collides(piece, 0, 0)) gameOver()
}

function collides (target, dx, dy, matrixOverride = null) {
  const matrix = matrixOverride || target.matrix
  for (let y = 0; y < matrix.length; y++) {
    for (let x = 0; x < matrix[y].length; x++) {
      if (!matrix[y][x]) continue
      const nx = target.x + x + dx
      const ny = target.y + y + dy
      if (nx < 0 || nx >= COLS || ny >= ROWS) return true
      if (ny >= 0 && board[ny][nx]) return true
    }
  }
  return false
}

function rotateMatrix (matrix) {
  return matrix[0].map((_, i) => matrix.map((row) => row[i]).reverse())
}

function move (dx, dy = 0) {
  if (phase.value !== 'running' || !piece) return false
  if (!collides(piece, dx, dy)) {
    piece.x += dx
    piece.y += dy
    return true
  }
  return false
}

function rotate () {
  if (phase.value !== 'running' || !piece) return
  const rotated = rotateMatrix(piece.matrix)
  for (const kick of [0, -1, 1, -2, 2]) {
    if (!collides(piece, kick, 0, rotated)) {
      piece.matrix = rotated
      piece.x += kick
      return
    }
  }
}

function dropOne (manual = true) {
  if (phase.value !== 'running' || !piece) return
  if (move(0, 1)) {
    if (manual) score.value += 1
  } else {
    lockPiece()
  }
}

function hardDrop () {
  if (phase.value !== 'running' || !piece) return
  let distance = 0
  while (!collides(piece, 0, 1)) {
    piece.y += 1
    distance += 1
  }
  score.value += distance * 2
  lockPiece()
}

function lockPiece () {
  piece.matrix.forEach((row, y) => {
    row.forEach((value, x) => {
      if (!value) return
      const by = piece.y + y
      const bx = piece.x + x
      if (by >= 0 && by < ROWS && bx >= 0 && bx < COLS) board[by][bx] = piece.type
    })
  })
  clearLines()
  spawn()
}

function clearLines () {
  const remaining = board.filter((row) => row.some((cell) => !cell))
  const cleared = ROWS - remaining.length
  if (!cleared) return
  while (remaining.length < ROWS) remaining.unshift(Array(COLS).fill(''))
  board = remaining

  const rewards = [0, 100, 300, 520, 800]
  score.value += rewards[cleared] * level.value
  lines.value += cleared
  level.value = Math.floor(lines.value / 10) + 1
  dropInterval = Math.max(120, 760 - (level.value - 1) * 62)
  burstParticles(cleared)
  if (best.value < score.value) {
    best.value = score.value
    localStorage.setItem(BEST_KEY, String(best.value))
  }
}

function burstParticles (count) {
  for (let i = 0; i < count * 12; i++) {
    particles.push({
      x: Math.random() * COLS,
      y: ROWS - 1 - Math.random() * count,
      vx: (Math.random() - 0.5) * 0.05,
      vy: -0.01 - Math.random() * 0.03,
      life: 1,
      size: 1 + Math.random() * 2.4
    })
  }
}

function gameOver () {
  phase.value = 'over'
  isNewRecord.value = score.value > 0 && score.value > bestAtStart
  if (score.value > best.value) {
    best.value = score.value
    localStorage.setItem(BEST_KEY, String(best.value))
  }
  piece = null
}

function start () {
  board = emptyBoard()
  bag = shuffle(Object.keys(SHAPES))
  nextType.value = takeType()
  bestAtStart = best.value
  score.value = 0
  lines.value = 0
  level.value = 1
  dropInterval = 760
  acc = 0
  lastTime = 0
  particles = []
  isNewRecord.value = false
  phase.value = 'running'
  spawn()
  buildStars()
}

function restart () {
  start()
}

function togglePause () {
  if (phase.value === 'running') phase.value = 'paused'
  else if (phase.value === 'paused') phase.value = 'running'
}

function buildStars () {
  stars = Array.from({ length: 46 }, () => ({
    x: Math.random(),
    y: Math.random(),
    r: 0.4 + Math.random() * 1.3,
    a: 0.12 + Math.random() * 0.4,
    tw: Math.random() * Math.PI * 2
  }))
}

function resize () {
  const wrap = boardWrap.value
  const cvs = canvas.value
  if (!wrap || !cvs) return
  const rect = wrap.getBoundingClientRect()
  const dpr = Math.min(window.devicePixelRatio || 1, 2)
  W = Math.max(180, rect.width)
  H = Math.max(360, rect.height)
  cvs.width = Math.round(W * dpr)
  cvs.height = Math.round(H * dpr)
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
  CELL = Math.min(W / COLS, H / ROWS)
  offsetX = (W - CELL * COLS) / 2
  offsetY = (H - CELL * ROWS) / 2
  buildStars()
  drawNext()
}

function roundRect (context, x, y, w, h, r) {
  const radius = Math.min(r, w / 2, h / 2)
  context.beginPath()
  context.moveTo(x + radius, y)
  context.arcTo(x + w, y, x + w, y + h, radius)
  context.arcTo(x + w, y + h, x, y + h, radius)
  context.arcTo(x, y + h, x, y, radius)
  context.arcTo(x, y, x + w, y, radius)
  context.closePath()
}

function drawBlock (context, bx, by, type, alpha = 1, ghost = false) {
  const color = COLORS[type]
  if (!color) return
  const x = offsetX + bx * CELL + 1.2
  const y = offsetY + by * CELL + 1.2
  const size = CELL - 2.4
  context.save()
  context.globalAlpha = alpha
  if (ghost) {
    context.strokeStyle = color.a
    context.lineWidth = 1.4
    roundRect(context, x, y, size, size, CELL * .18)
    context.stroke()
    context.restore()
    return
  }
  const gradient = context.createLinearGradient(x, y, x + size, y + size)
  gradient.addColorStop(0, color.a)
  gradient.addColorStop(1, color.b)
  context.fillStyle = gradient
  context.shadowColor = color.glow
  context.shadowBlur = CELL * .4
  roundRect(context, x, y, size, size, CELL * .18)
  context.fill()
  context.shadowBlur = 0
  context.strokeStyle = 'rgba(255,255,255,.28)'
  context.lineWidth = 1
  roundRect(context, x + 1, y + 1, size - 2, size - 2, CELL * .14)
  context.stroke()
  context.fillStyle = 'rgba(255,255,255,.26)'
  roundRect(context, x + size * .16, y + size * .14, size * .42, size * .09, size * .045)
  context.fill()
  context.restore()
}

function draw () {
  if (!ctx) return
  const now = performance.now() / 1000
  ctx.clearRect(0, 0, W, H)
  const bg = ctx.createLinearGradient(0, 0, W, H)
  bg.addColorStop(0, '#160e1b')
  bg.addColorStop(.55, '#201126')
  bg.addColorStop(1, '#2a1224')
  ctx.fillStyle = bg
  ctx.fillRect(0, 0, W, H)

  for (const star of stars) {
    const pulse = 0.5 + 0.5 * Math.sin(now * 1.2 + star.tw)
    ctx.globalAlpha = star.a * (0.55 + pulse * 0.45)
    ctx.fillStyle = '#ffe8f2'
    ctx.beginPath()
    ctx.arc(star.x * W, star.y * H, star.r, 0, Math.PI * 2)
    ctx.fill()
  }
  ctx.globalAlpha = 1

  const boardW = CELL * COLS
  const boardH = CELL * ROWS
  ctx.fillStyle = 'rgba(18, 10, 23, .58)'
  roundRect(ctx, offsetX, offsetY, boardW, boardH, CELL * .22)
  ctx.fill()

  ctx.strokeStyle = 'rgba(255, 209, 228, .07)'
  ctx.lineWidth = 1
  for (let x = 1; x < COLS; x++) {
    ctx.beginPath()
    ctx.moveTo(offsetX + x * CELL, offsetY)
    ctx.lineTo(offsetX + x * CELL, offsetY + boardH)
    ctx.stroke()
  }
  for (let y = 1; y < ROWS; y++) {
    ctx.beginPath()
    ctx.moveTo(offsetX, offsetY + y * CELL)
    ctx.lineTo(offsetX + boardW, offsetY + y * CELL)
    ctx.stroke()
  }

  for (let y = 0; y < ROWS; y++) {
    for (let x = 0; x < COLS; x++) {
      if (board[y][x]) drawBlock(ctx, x, y, board[y][x])
    }
  }

  if (piece && phase.value !== 'over') {
    const ghost = { ...piece, y: piece.y }
    while (!collides(ghost, 0, 1)) ghost.y += 1
    ghost.matrix.forEach((row, y) => row.forEach((value, x) => {
      if (value && ghost.y + y >= 0) drawBlock(ctx, ghost.x + x, ghost.y + y, piece.type, .22, true)
    }))
    piece.matrix.forEach((row, y) => row.forEach((value, x) => {
      if (value && piece.y + y >= 0) drawBlock(ctx, piece.x + x, piece.y + y, piece.type)
    }))
  }

  for (const p of particles) {
    p.x += p.vx
    p.y += p.vy
    p.life -= 0.012
    if (p.life <= 0) continue
    ctx.globalAlpha = p.life * .75
    ctx.fillStyle = '#f7b6cf'
    ctx.beginPath()
    ctx.ellipse(offsetX + p.x * CELL, offsetY + p.y * CELL, p.size * 2.2, p.size, .6, 0, Math.PI * 2)
    ctx.fill()
  }
  particles = particles.filter((p) => p.life > 0)
  ctx.globalAlpha = 1
}

function drawNext () {
  const cvs = nextCanvas.value
  if (!cvs) return
  if (!nextCtx) nextCtx = cvs.getContext('2d')
  const dpr = Math.min(window.devicePixelRatio || 1, 2)
  const size = 112
  cvs.width = size * dpr
  cvs.height = size * dpr
  nextCtx.setTransform(dpr, 0, 0, dpr, 0, 0)
  nextCtx.clearRect(0, 0, size, size)

  const matrix = SHAPES[nextType.value] || SHAPES.T
  const cell = 20
  const startX = (size - matrix[0].length * cell) / 2
  const startY = (size - matrix.length * cell) / 2
  const color = COLORS[nextType.value] || COLORS.T

  matrix.forEach((row, y) => row.forEach((value, x) => {
    if (!value) return
    const bx = startX + x * cell
    const by = startY + y * cell
    const gradient = nextCtx.createLinearGradient(bx, by, bx + cell, by + cell)
    gradient.addColorStop(0, color.a)
    gradient.addColorStop(1, color.b)
    nextCtx.fillStyle = gradient
    roundRect(nextCtx, bx + 1, by + 1, cell - 2, cell - 2, 4)
    nextCtx.fill()
  }))
}

function loop (time) {
  if (!lastTime) lastTime = time
  const dt = Math.min(80, time - lastTime)
  lastTime = time
  if (phase.value === 'running') {
    acc += dt
    if (acc >= dropInterval) {
      acc = 0
      dropOne(false)
    }
  }
  draw()
  raf = requestAnimationFrame(loop)
}

function onKeyDown (event) {
  const keys = ['ArrowLeft', 'ArrowRight', 'ArrowDown', 'ArrowUp', ' ']
  if (keys.includes(event.key)) event.preventDefault()

  if (event.key === 'Enter' && (phase.value === 'ready' || phase.value === 'over')) {
    start()
    return
  }
  if (event.key === 'p' || event.key === 'P') {
    togglePause()
    return
  }
  if (event.key === ' ' && phase.value === 'paused') {
    togglePause()
    return
  }
  if (phase.value !== 'running') return

  if (event.key === 'ArrowLeft') move(-1)
  else if (event.key === 'ArrowRight') move(1)
  else if (event.key === 'ArrowDown') dropOne(true)
  else if (event.key === 'ArrowUp') rotate()
  else if (event.key === 'x' || event.key === 'X') rotate()
  else if (event.key === ' ' && !event.repeat) hardDrop()
  else if (event.key === 'r' || event.key === 'R') restart()
}

function toggleFullscreen () {
  const target = boardWrap.value
  if (!target) return
  if (document.fullscreenElement) document.exitFullscreen()
  else target.requestFullscreen?.()
}

function onFullscreenChange () {
  fullscreen.value = Boolean(document.fullscreenElement)
  setTimeout(resize, 80)
}

function onResize () {
  resize()
}

onMounted(() => {
  ctx = canvas.value.getContext('2d')
  board = emptyBoard()
  buildStars()
  resize()
  drawNext()
  raf = requestAnimationFrame(loop)
  window.addEventListener('keydown', onKeyDown)
  window.addEventListener('resize', onResize)
  document.addEventListener('fullscreenchange', onFullscreenChange)
  if (typeof ResizeObserver !== 'undefined') {
    ro = new ResizeObserver(() => resize())
    if (boardWrap.value) ro.observe(boardWrap.value)
  }
})

onBeforeUnmount(() => {
  if (raf) cancelAnimationFrame(raf)
  window.removeEventListener('keydown', onKeyDown)
  window.removeEventListener('resize', onResize)
  document.removeEventListener('fullscreenchange', onFullscreenChange)
  if (ro) ro.disconnect()
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
  width: 100%;
  max-width: 760px;
  margin: 0 auto;
  border-radius: 18px;
  background: var(--porcelain-flat);
  border: 1px solid var(--porcelain-line);
  box-shadow: var(--gloss), var(--lift);
  overflow: hidden;
}
.hud__stats {
  display: grid;
  grid-template-columns: repeat(4, minmax(68px, auto));
  flex: 1;
  min-width: 0;
}
.hud__stats .stat { padding: 12px 18px; border-left: 1px solid var(--line-soft); min-width: 0; }
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
.stat span { display: block; margin-top: 2px; font-size: 10.5px; color: var(--faint); letter-spacing: .1em; white-space: nowrap; }
.hud__btns {
  display: flex;
  align-items: center;
  gap: 7px;
  padding: 10px 14px;
  border-left: 1px solid var(--line-soft);
  background: rgba(255, 244, 247, .55);
}
.gbtn {
  height: 36px;
  padding: 0 16px;
  border: 0;
  border-radius: 999px;
  cursor: pointer;
  font: inherit;
  font-size: 12.5px;
  font-weight: 600;
  color: #fff;
  background: linear-gradient(120deg, var(--sakura-500), var(--sakura-600));
  box-shadow: 0 12px 24px -16px rgba(232, 84, 127, .95);
  transition: transform .3s var(--ease), opacity .25s, box-shadow .3s;
}
.gbtn:hover:not(:disabled) { transform: translateY(-2px); }
.gbtn:disabled { cursor: not-allowed; opacity: .5; }
.gbtn--ghost { background: #fff; border: 1px solid var(--sakura-200); box-shadow: none; color: var(--sakura-600); }
.gbtn--ghost:hover:not(:disabled) { background: var(--sakura-50); }
.gbtn--big { height: 46px; padding: 0 32px; font-size: 15px; margin-top: 4px; }

.arena {
  display: grid;
  grid-template-columns: minmax(0, 340px) 206px;
  justify-content: center;
  align-items: start;
  gap: 18px;
}
.board-column { min-width: 0; display: flex; flex-direction: column; gap: 12px; }
.board {
  position: relative;
  width: 100%;
  aspect-ratio: 1 / 2;
  overflow: hidden;
  border-radius: 22px;
  border: 1px solid rgba(249, 159, 193, .6);
  background: #160e1b;
  box-shadow:
    0 34px 70px -40px rgba(60, 20, 40, .9),
    0 0 0 8px rgba(255, 255, 255, .55),
    0 0 90px -46px rgba(249, 116, 159, .8);
}
.board canvas { display: block; width: 100%; height: 100%; touch-action: none; }
.board:fullscreen {
  width: auto;
  height: 100vh;
  max-height: 100vh;
  aspect-ratio: 1 / 2;
  border-radius: 0;
  border: 0;
  box-shadow: none;
}
.overlay {
  position: absolute;
  inset: 0;
  z-index: 3;
  display: grid;
  place-items: center;
  padding: 18px;
  text-align: center;
  background: rgba(28, 14, 24, .8);
  backdrop-filter: blur(10px);
  animation: fade .35s var(--ease);
}
@keyframes fade { from { opacity: 0 } to { opacity: 1 } }
.ov { display: flex; flex-direction: column; align-items: center; gap: 12px; max-width: 400px; }
.ov__badge {
  padding: 3px 14px;
  border: 1px solid rgba(255, 196, 217, .42);
  border-radius: 999px;
  color: #ffd0df;
  font-size: 9.5px;
  letter-spacing: .22em;
}
.ov__badge--gold { color: #ffe6a8; border-color: rgba(252, 211, 77, .55); box-shadow: 0 0 26px -6px rgba(252, 211, 77, .6); }
.ov__title {
  margin: 0;
  font-family: var(--font-serif);
  font-size: clamp(23px, 3vw, 30px);
  font-weight: 600;
  letter-spacing: .04em;
  background: linear-gradient(100deg, #ffd6e4, #fff 45%, #ffb3cd);
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}
.ov__score { color: #fff; font-family: var(--font-serif); font-size: 54px; line-height: 1; text-shadow: 0 0 34px rgba(249, 116, 159, .75); }
.ov__text { margin: 0; color: rgba(255, 232, 242, .8); font-size: 12.5px; line-height: 1.85; }
.ov__hint { margin: 0; color: rgba(255, 220, 232, .52); font-size: 10.5px; }

.side { display: flex; flex-direction: column; gap: 12px; }
.mini-card {
  padding: 15px;
  border: 1px solid var(--porcelain-line);
  border-radius: 18px;
  background: var(--porcelain-flat);
  box-shadow: var(--gloss), 0 16px 34px -30px rgba(112, 68, 100, .55);
}
.mini-card__head { display: flex; align-items: baseline; justify-content: space-between; gap: 10px; margin-bottom: 9px; }
.mini-card__head span { font-family: var(--font-serif); font-size: 13px; font-weight: 600; color: var(--ink); }
.mini-card__head i { color: var(--faint); font-size: 8px; font-style: normal; letter-spacing: .14em; }
.next-card { text-align: center; }
.next-canvas { display: block; width: 112px; height: 112px; margin: 0 auto; }
.level-track { height: 7px; overflow: hidden; border-radius: 999px; background: var(--sakura-100); }
.level-track span { display: block; height: 100%; border-radius: inherit; background: linear-gradient(90deg, var(--sakura-400), #bca4e6); transition: width .3s var(--ease); }
.progress-card p { margin: 9px 0 0; color: var(--faint); font-size: 9.5px; line-height: 1.6; }
.progress-card p b { color: var(--sakura-600); }
.rules-card ul { margin: 0; padding: 0; list-style: none; display: flex; flex-direction: column; gap: 7px; }
.rules-card li { position: relative; padding-left: 11px; color: var(--muted); font-size: 10px; line-height: 1.55; }
.rules-card li::before { content: ''; position: absolute; left: 0; top: .55em; width: 4px; height: 4px; border-radius: 50%; background: var(--sakura-300); }
.touch-pad { display: none; grid-template-columns: repeat(4, 1fr); gap: 7px; width: 100%; max-width: 340px; margin: 0 auto; }
.touch-pad button {
  height: 38px;
  border: 1px solid var(--sakura-200);
  border-radius: 11px;
  background: rgba(255, 255, 255, .74);
  color: var(--sakura-700);
  font: inherit;
  font-size: 15px;
  cursor: pointer;
}
.touch-pad__wide { grid-column: span 4; font-size: 12px !important; letter-spacing: .08em; }
.foot {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  padding: 8px 0 20px;
  color: var(--faint);
  font-size: 10.5px;
  letter-spacing: .08em;
}
.foot__dot { width: 3px; height: 3px; border-radius: 50%; background: var(--sakura-300); }

@media (max-width: 760px) {
  .main { padding-left: 16px; padding-right: 16px; }
  .hud { max-width: 100%; }
  .hud__stats { grid-template-columns: repeat(2, 1fr); }
  .hud__stats .stat:nth-child(3) { border-left: 0; border-top: 1px solid var(--line-soft); }
  .hud__stats .stat:nth-child(4) { border-top: 1px solid var(--line-soft); }
  .hud__btns { width: 100%; justify-content: flex-end; border-left: 0; border-top: 1px solid var(--line-soft); }
  .arena { grid-template-columns: minmax(0, 340px); }
  .side { display: grid; grid-template-columns: 1fr 1fr; }
  .rules-card { grid-column: 1 / -1; }
  .touch-pad { display: grid; }
}
@media (max-width: 460px) {
  .board { width: min(300px, 88vw); margin: 0 auto; }
  .hud__btns { justify-content: center; flex-wrap: wrap; }
  .side { grid-template-columns: 1fr; }
  .rules-card { grid-column: auto; }
  .foot { flex-wrap: wrap; gap: 7px; }
}
</style>
