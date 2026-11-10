<template>
  <div class="page">
    <SiteNav :user="user" active="game" @go="$emit('navigate', $event)" @logout="$emit('logout')" />

    <main class="subpage main">
      <header class="subhead">
        <span class="subhead__tag">Game</span>
        <h1>樱海大鱼</h1>
        <p>游进落满花瓣的夜海，吃掉比自己小的鱼慢慢长大，也要记得躲开比你更大的影子。</p>
      </header>

      <GameSwitch active="fish" @select="$emit('navigate', $event)" />

      <section class="stage">
        <div class="hud">
          <div class="hud__stats">
            <div class="stat"><b>{{ score }}</b><span>得分</span></div>
            <div class="stat"><b>{{ best }}</b><span>最高分</span></div>
            <div class="stat"><b>{{ Math.round(playerSize) }}</b><span>体型</span></div>
            <div class="stat"><b>{{ lives }}</b><span>生命</span></div>
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
          <canvas
            ref="canvas"
            @pointermove="onPointerMove"
            @pointerdown="onPointerMove"
            @pointerleave="onPointerLeave"
          ></canvas>

          <div v-if="phase === 'ready'" class="overlay">
            <div class="ov">
              <span class="ov__badge">SAKURA OCEAN</span>
              <h2 class="ov__title">潮汐初起</h2>
              <p class="ov__text">鼠标移动，或用方向键 / WASD 游动<br />吃小鱼成长，躲开更大的鱼</p>
              <button class="gbtn gbtn--big" type="button" @click="start">潜入樱海</button>
              <p class="ov__hint">吃小鱼变大 · 被大鱼碰到会失去一颗生命</p>
            </div>
          </div>

          <div v-else-if="phase === 'paused'" class="overlay">
            <div class="ov">
              <span class="ov__badge">PAUSED</span>
              <h2 class="ov__title">潮水停在半空</h2>
              <button class="gbtn gbtn--big" type="button" @click="togglePause">继续游动</button>
              <p class="ov__hint">按 P 也可以继续</p>
            </div>
          </div>

          <div v-else-if="phase === 'over'" class="overlay">
            <div class="ov">
              <span class="ov__badge" :class="{ 'ov__badge--gold': isNewRecord }">
                {{ isNewRecord ? 'NEW RECORD' : 'GAME OVER' }}
              </span>
              <h2 class="ov__title">{{ isNewRecord ? '这次游得很远' : '潮水退去了' }}</h2>
              <div class="ov__score">{{ score }}</div>
              <p class="ov__text">吃掉 {{ eaten }} 条鱼 · 最大体型 {{ Math.round(maxSize) }} · 抵达 Lv.{{ level }}</p>
              <button class="gbtn gbtn--big" type="button" @click="restart">再游一局</button>
              <p class="ov__hint">按回车快速重开</p>
            </div>
          </div>

          <div class="board__hint" aria-hidden="true">
            <span>{{ phase === 'running' ? '移动鼠标 / 方向键游动' : 'SAKURA OCEAN' }}</span>
          </div>
        </div>

        <div class="panels">
          <section class="card">
            <h2 class="card__title">本局成长</h2>
            <div class="growth">
              <div class="stat stat--lg"><b>{{ eaten }}</b><span>吃掉小鱼</span></div>
              <div class="stat stat--lg"><b>{{ Math.round(maxSize) }}</b><span>最大体型</span></div>
              <div class="stat stat--lg"><b>Lv.{{ level }}</b><span>潮汐等级</span></div>
            </div>
            <div class="growth-track"><span :style="{ width: growthProgress + '%' }"></span></div>
            <p class="hint">每吃 8 条鱼，鱼群会变得更快，也会出现更大的影子。</p>
          </section>

          <section class="card">
            <h2 class="card__title">玩法</h2>
            <ul class="rules">
              <li>只有比自己小的鱼才能吃，靠近就会自动吞下</li>
              <li>碰到比自己大的鱼会失去一颗生命并缩小</li>
              <li>受伤后有一小段无敌时间，鱼身会发光</li>
              <li>生命耗尽时本局结束，最高分会保存在本地</li>
            </ul>
          </section>

          <section class="card card--sea">
            <h2 class="card__title">樱海鱼群</h2>
            <div class="fish-legend">
              <span v-for="c in legendColors" :key="c" :style="{ background: c }"></span>
            </div>
            <p class="hint">越明亮的鱼通常越小；深色的影子往往意味着危险。</p>
          </section>
        </div>
      </section>

      <footer class="foot">
        <span>樱见 · 樱海大鱼</span>
        <span class="foot__dot"></span>
        <span>鼠标 / 触屏 / 键盘均可游玩</span>
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

const VW = 960
const VH = 600
const BEST_KEY = 'aurora_fish_best'

const COLORS = [
  { a: '#ffc0d8', b: '#e578a4', glow: 'rgba(245, 150, 184, .42)' },
  { a: '#c2b5f0', b: '#8873c4', glow: 'rgba(162, 144, 220, .4)' },
  { a: '#a9e0ed', b: '#5ca9c4', glow: 'rgba(121, 196, 219, .4)' },
  { a: '#f6d3a2', b: '#cb9b59', glow: 'rgba(235, 194, 126, .38)' },
  { a: '#b4e3c8', b: '#6caf8f', glow: 'rgba(142, 208, 175, .38)' }
]
const legendColors = COLORS.map((c) => `linear-gradient(135deg, ${c.a}, ${c.b})`)

const phase = ref('ready')
const score = ref(0)
const best = ref(Number(localStorage.getItem(BEST_KEY)) || 0)
const playerSize = ref(26)
const lives = ref(3)
const eaten = ref(0)
const maxSize = ref(26)
const level = ref(1)
const isNewRecord = ref(false)
const fullscreen = ref(false)

const canvas = ref(null)
const boardWrap = ref(null)
let ctx = null
let W = 0
let H = 0
let raf = null
let lastTime = 0
let bestAtStart = 0
let ro = null
let invincible = 0
let shake = 0
let flash = 0
const view = { scale: 1, ox: 0, oy: 0, cssScale: 1, cssOx: 0, cssOy: 0 }

const player = { x: VW / 2, y: VH / 2, r: 26, dir: 1, speed: 315 }
let target = { x: VW / 2, y: VH / 2 }
let pointerInside = false
const keys = new Set()
let fishes = []
let bubbles = []
let petals = []
let pops = []

const levelProgress = computed(() => (eaten.value % 8) / 8 * 100)
const growthProgress = levelProgress

function random (min, max) {
  return min + Math.random() * (max - min)
}

function clamp (value, min, max) {
  return Math.max(min, Math.min(max, value))
}

function buildAmbient () {
  bubbles = Array.from({ length: 38 }, () => ({
    x: random(0, VW),
    y: random(0, VH),
    r: random(1.2, 4.2),
    vy: random(8, 28),
    alpha: random(.12, .42)
  }))
  petals = Array.from({ length: 20 }, () => ({
    x: random(0, VW),
    y: random(0, VH),
    size: random(4, 11),
    vy: random(7, 18),
    vx: random(-7, 7),
    rot: random(0, Math.PI * 2),
    spin: random(-.6, .6),
    alpha: random(.16, .5)
  }))
}

function makeFish (initial = false, index = 0) {
  const side = Math.random() < .5 ? -1 : 1
  const ratio = initial && index < 9
    ? random(.3, .7)
    : random(.24, 1.55)
  const size = clamp(player.r * ratio, 8, 74)
  const palette = COLORS[Math.floor(Math.random() * COLORS.length)]
  return {
    x: side < 0 ? -size * 2.5 : VW + size * 2.5,
    y: random(size * 1.7, VH - size * 1.7),
    baseY: 0,
    size,
    dir: side < 0 ? 1 : -1,
    speed: random(32, 60) + Math.max(0, 26 - size) * .8 + level.value * 2,
    phase: random(0, Math.PI * 2),
    amp: random(5, 17),
    palette
  }
}

function resetFishes () {
  fishes = []
  for (let i = 0; i < 17; i++) {
    let fish = makeFish(true, i)
    fish.baseY = fish.y
    // 开局不要直接贴脸生成
    let guard = 0
    while (Math.hypot(fish.x - player.x, fish.y - player.y) < 130 && guard++ < 8) {
      fish = makeFish(true, i)
      fish.baseY = fish.y
    }
    fishes.push(fish)
  }
}

function respawnFish (fish) {
  const fresh = makeFish(false)
  Object.assign(fish, fresh)
  fish.baseY = fish.y
}

function start () {
  player.x = VW / 2
  player.y = VH / 2
  player.r = 26
  player.dir = 1
  player.speed = 315
  target = { x: VW / 2, y: VH / 2 }
  score.value = 0
  playerSize.value = 26
  lives.value = 3
  eaten.value = 0
  maxSize.value = 26
  level.value = 1
  isNewRecord.value = false
  invincible = 0
  shake = 0
  flash = 0
  bestAtStart = best.value
  pops = []
  keys.clear()
  buildAmbient()
  resetFishes()
  phase.value = 'running'
  lastTime = 0
}

function restart () {
  start()
}

function togglePause () {
  if (phase.value === 'running') phase.value = 'paused'
  else if (phase.value === 'paused') phase.value = 'running'
}

function gameOver () {
  phase.value = 'over'
  isNewRecord.value = score.value > 0 && score.value > bestAtStart
  if (score.value > best.value) {
    best.value = score.value
    localStorage.setItem(BEST_KEY, String(best.value))
  }
}

function eatFish (fish) {
  const gain = Math.max(6, Math.round(fish.size * 1.35))
  score.value += gain
  eaten.value += 1
  const grow = Math.max(.55, fish.size * .052)
  player.r = Math.min(58, player.r + grow)
  playerSize.value = player.r
  maxSize.value = Math.max(maxSize.value, player.r)
  level.value = 1 + Math.floor(eaten.value / 8)
  player.speed = 315 + (level.value - 1) * 13
  if (score.value > best.value) {
    best.value = score.value
    localStorage.setItem(BEST_KEY, String(best.value))
  }
  pops.push({ x: fish.x, y: fish.y, r: fish.size, life: 1, text: '+' + gain })
  respawnFish(fish)
}

function hitByFish (fish) {
  lives.value -= 1
  invincible = 1.7
  shake = .35
  flash = .55
  player.r = Math.max(22, player.r * .91)
  playerSize.value = player.r
  score.value = Math.max(0, score.value - 25)
  pops.push({ x: player.x, y: player.y, r: player.r, life: 1, text: '-1' })
  respawnFish(fish)
  if (lives.value <= 0) gameOver()
}

function movePlayer (dt) {
  let mx = 0
  let my = 0
  if (keys.has('ArrowLeft') || keys.has('a') || keys.has('A')) mx -= 1
  if (keys.has('ArrowRight') || keys.has('d') || keys.has('D')) mx += 1
  if (keys.has('ArrowUp') || keys.has('w') || keys.has('W')) my -= 1
  if (keys.has('ArrowDown') || keys.has('s') || keys.has('S')) my += 1

  if (mx || my) {
    const len = Math.hypot(mx, my) || 1
    const step = player.speed * dt
    player.x += mx / len * step
    player.y += my / len * step
    if (mx) player.dir = mx > 0 ? 1 : -1
  } else if (pointerInside) {
    const dx = target.x - player.x
    const dy = target.y - player.y
    const distance = Math.hypot(dx, dy)
    if (distance > 2) {
      const step = Math.min(distance, player.speed * 1.05 * dt)
      player.x += dx / distance * step
      player.y += dy / distance * step
      if (Math.abs(dx) > 2) player.dir = dx > 0 ? 1 : -1
    }
  }

  const margin = player.r + 8
  player.x = clamp(player.x, margin, VW - margin)
  player.y = clamp(player.y, margin, VH - margin)
}

function update (dt, time) {
  movePlayer(dt)
  if (invincible > 0) invincible = Math.max(0, invincible - dt)
  if (shake > 0) shake = Math.max(0, shake - dt * 1.8)
  if (flash > 0) flash = Math.max(0, flash - dt * 2.2)

  for (const fish of fishes) {
    fish.x += fish.dir * fish.speed * dt
    fish.baseY += Math.sin(time * 1.2 + fish.phase) * 4 * dt
    fish.y = clamp(fish.baseY + Math.sin(time * 1.4 + fish.phase) * fish.amp, fish.size, VH - fish.size)

    if (fish.x < -fish.size * 3.5 || fish.x > VW + fish.size * 3.5) {
      respawnFish(fish)
      continue
    }

    const distance = Math.hypot(fish.x - player.x, fish.y - player.y)
    const touch = distance < fish.size * .82 + player.r * .72
    if (!touch) continue

    if (fish.size < player.r * .93) {
      eatFish(fish)
    } else if (fish.size > player.r * 1.08 && invincible <= 0) {
      hitByFish(fish)
    }
  }

  for (const bubble of bubbles) {
    bubble.y -= bubble.vy * dt
    bubble.x += Math.sin(time * 1.7 + bubble.y * .02) * 3 * dt
    if (bubble.y < -8) {
      bubble.y = VH + 8
      bubble.x = random(0, VW)
    }
  }
  for (const petal of petals) {
    petal.x += petal.vx * dt
    petal.y += petal.vy * dt
    petal.rot += petal.spin * dt
    if (petal.y > VH + 12) {
      petal.y = -12
      petal.x = random(0, VW)
    }
    if (petal.x < -12) petal.x = VW + 12
    if (petal.x > VW + 12) petal.x = -12
  }
  for (const pop of pops) {
    pop.y -= 22 * dt
    pop.life -= dt * .8
  }
  pops = pops.filter((p) => p.life > 0)
}

function drawFishShape (fish, time, isPlayer = false) {
  const r = fish.size
  const palette = fish.palette
  ctx.save()
  ctx.translate(fish.x, fish.y)
  ctx.scale(fish.dir, 1)

  if (isPlayer) {
    ctx.shadowColor = 'rgba(255, 137, 181, .72)'
    ctx.shadowBlur = 24
  }

  // 尾鳍
  const tailWave = Math.sin(time * 5 + fish.phase) * r * .18
  ctx.beginPath()
  ctx.moveTo(-r * .78, 0)
  ctx.bezierCurveTo(-r * 1.35, -r * .7 + tailWave, -r * 1.6, -r * .35 + tailWave, -r * 1.38, 0)
  ctx.bezierCurveTo(-r * 1.6, r * .35 + tailWave, -r * 1.35, r * .7 + tailWave, -r * .78, 0)
  const tailGradient = ctx.createLinearGradient(-r * 1.5, 0, -r * .7, 0)
  tailGradient.addColorStop(0, palette.b)
  tailGradient.addColorStop(1, palette.a)
  ctx.fillStyle = tailGradient
  ctx.fill()

  // 背鳍
  ctx.beginPath()
  ctx.moveTo(-r * .15, -r * .62)
  ctx.quadraticCurveTo(r * .2, -r * 1.05, r * .6, -r * .5)
  ctx.fillStyle = palette.a
  ctx.globalAlpha = .82
  ctx.fill()
  ctx.globalAlpha = 1

  // 身体
  const bodyGradient = ctx.createLinearGradient(-r, -r * .6, r, r * .6)
  bodyGradient.addColorStop(0, palette.a)
  bodyGradient.addColorStop(.65, palette.a)
  bodyGradient.addColorStop(1, palette.b)
  ctx.beginPath()
  ctx.ellipse(0, 0, r * 1.18, r * .72, 0, 0, Math.PI * 2)
  ctx.fillStyle = bodyGradient
  ctx.fill()

  // 腹部高光
  ctx.beginPath()
  ctx.ellipse(r * .08, r * .2, r * .78, r * .29, 0, 0, Math.PI * 2)
  ctx.fillStyle = 'rgba(255, 255, 255, .18)'
  ctx.fill()

  // 侧鳍
  ctx.beginPath()
  ctx.moveTo(-r * .1, r * .25)
  ctx.quadraticCurveTo(r * .1, r * .9, r * .52, r * .42)
  ctx.fillStyle = palette.b
  ctx.globalAlpha = .55
  ctx.fill()
  ctx.globalAlpha = 1

  // 眼睛
  ctx.beginPath()
  ctx.arc(r * .68, -r * .18, r * .14, 0, Math.PI * 2)
  ctx.fillStyle = '#fffafc'
  ctx.fill()
  ctx.beginPath()
  ctx.arc(r * .72, -r * .18, r * .065, 0, Math.PI * 2)
  ctx.fillStyle = '#3c2638'
  ctx.fill()

  if (isPlayer) {
    ctx.beginPath()
    ctx.arc(r * .88, r * .08, r * .11, -.8, .8)
    ctx.strokeStyle = 'rgba(255, 255, 255, .42)'
    ctx.lineWidth = 1.4
    ctx.stroke()
  }
  ctx.restore()
}

function drawPetal (x, y, size, rot, alpha) {
  ctx.save()
  ctx.translate(x, y)
  ctx.rotate(rot)
  ctx.globalAlpha = alpha
  ctx.beginPath()
  ctx.ellipse(0, 0, size, size * .48, 0, 0, Math.PI * 2)
  ctx.fillStyle = '#ffc3da'
  ctx.fill()
  ctx.restore()
}

function draw () {
  if (!ctx) return
  ctx.save()
  ctx.setTransform(1, 0, 0, 1, 0, 0)
  ctx.clearRect(0, 0, canvas.value.width, canvas.value.height)
  ctx.fillStyle = '#22152b'
  ctx.fillRect(0, 0, canvas.value.width, canvas.value.height)
  // 等比缩放并居中留边，避免窄屏时鱼被纵向拉长
  ctx.setTransform(view.scale, 0, 0, view.scale, view.ox, view.oy)

  const time = performance.now() / 1000
  const jitterX = shake > 0 ? random(-1, 1) * shake * 14 : 0
  const jitterY = shake > 0 ? random(-1, 1) * shake * 10 : 0
  ctx.translate(jitterX, jitterY)

  const bg = ctx.createLinearGradient(0, 0, 0, VH)
  bg.addColorStop(0, '#251635')
  bg.addColorStop(.45, '#25152c')
  bg.addColorStop(1, '#39172b')
  ctx.fillStyle = bg
  ctx.fillRect(-30, -30, VW + 60, VH + 60)

  // 水面光柱
  ctx.save()
  ctx.globalAlpha = .11
  for (let i = 0; i < 5; i++) {
    const x = 100 + i * 210 + Math.sin(time * .18 + i) * 28
    const ray = ctx.createLinearGradient(x, 0, x + 170, VH)
    ray.addColorStop(0, 'rgba(255, 214, 232, .72)')
    ray.addColorStop(1, 'rgba(255, 214, 232, 0)')
    ctx.fillStyle = ray
    ctx.beginPath()
    ctx.moveTo(x, -10)
    ctx.lineTo(x + 72, -10)
    ctx.lineTo(x + 260, VH)
    ctx.lineTo(x + 70, VH)
    ctx.closePath()
    ctx.fill()
  }
  ctx.restore()

  // 海底樱色雾
  const haze = ctx.createRadialGradient(VW * .52, VH * .9, 10, VW * .52, VH * .9, VW * .7)
  haze.addColorStop(0, 'rgba(212, 99, 145, .15)')
  haze.addColorStop(1, 'rgba(212, 99, 145, 0)')
  ctx.fillStyle = haze
  ctx.fillRect(0, 0, VW, VH)

  for (const bubble of bubbles) {
    ctx.globalAlpha = bubble.alpha
    ctx.beginPath()
    ctx.arc(bubble.x, bubble.y, bubble.r, 0, Math.PI * 2)
    ctx.strokeStyle = 'rgba(255, 218, 233, .75)'
    ctx.lineWidth = 1
    ctx.stroke()
  }
  ctx.globalAlpha = 1

  for (const petal of petals) {
    drawPetal(petal.x, petal.y, petal.size, petal.rot, petal.alpha)
  }

  const ordered = fishes.slice().sort((a, b) => a.size - b.size)
  for (const fish of ordered) drawFishShape(fish, time)

  if (phase.value !== 'over') {
    if (invincible > 0 && Math.floor(invincible * 9) % 2 === 0) {
      ctx.globalAlpha = .24
    }
    if (invincible > 0) {
      ctx.beginPath()
      ctx.arc(player.x, player.y, player.r * 1.65, 0, Math.PI * 2)
      ctx.strokeStyle = 'rgba(255, 183, 209, .75)'
      ctx.lineWidth = 2
      ctx.stroke()
    }
    drawFishShape({
      x: player.x,
      y: player.y,
      size: player.r,
      dir: player.dir,
      phase: 0,
      palette: { a: '#ffc0d9', b: '#df6f9d', glow: 'rgba(255, 130, 177, .6)' }
    }, time, true)
    ctx.globalAlpha = 1
  }

  for (const pop of pops) {
    ctx.globalAlpha = Math.max(0, pop.life)
    ctx.fillStyle = pop.text.startsWith('-') ? '#ff9db3' : '#ffe4a8'
    ctx.font = '600 18px "PingFang SC", "Microsoft YaHei", sans-serif'
    ctx.textAlign = 'center'
    ctx.fillText(pop.text, pop.x, pop.y - 20)
  }
  ctx.globalAlpha = 1

  if (flash > 0) {
    ctx.fillStyle = `rgba(255, 125, 161, ${flash * .2})`
    ctx.fillRect(-30, -30, VW + 60, VH + 60)
  }
  ctx.restore()
}

function resize () {
  const wrap = boardWrap.value
  const cvs = canvas.value
  if (!wrap || !cvs) return
  const rect = wrap.getBoundingClientRect()
  const dpr = Math.min(window.devicePixelRatio || 1, 2)
  W = Math.max(300, rect.width)
  H = Math.max(188, rect.height)
  cvs.width = Math.round(W * dpr)
  cvs.height = Math.round(H * dpr)
  view.cssScale = Math.min(W / VW, H / VH)
  view.cssOx = (W - VW * view.cssScale) / 2
  view.cssOy = (H - VH * view.cssScale) / 2
  view.scale = view.cssScale * dpr
  view.ox = view.cssOx * dpr
  view.oy = view.cssOy * dpr
}

function loop (time) {
  if (!lastTime) lastTime = time
  const dt = Math.min(.032, (time - lastTime) / 1000)
  lastTime = time
  const seconds = time / 1000
  if (phase.value === 'running') update(dt, seconds)
  draw()
  raf = requestAnimationFrame(loop)
}

function onPointerMove (event) {
  const rect = canvas.value.getBoundingClientRect()
  const px = event.clientX - rect.left
  const py = event.clientY - rect.top
  target = {
    x: clamp((px - view.cssOx) / view.cssScale, 0, VW),
    y: clamp((py - view.cssOy) / view.cssScale, 0, VH)
  }
  pointerInside = true
}

function onPointerLeave () {
  pointerInside = false
}

function onKeyDown (event) {
  const gameKeys = ['ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown', ' ', 'w', 'a', 's', 'd', 'W', 'A', 'S', 'D']
  if (gameKeys.includes(event.key)) event.preventDefault()

  if (event.key === 'Enter' && (phase.value === 'ready' || phase.value === 'over')) {
    start()
    return
  }
  if (event.key === 'p' || event.key === 'P') {
    togglePause()
    return
  }
  if (event.key === 'r' || event.key === 'R') {
    restart()
    return
  }
  if (phase.value !== 'running') return
  keys.add(event.key)
  if (['ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown', 'w', 'a', 's', 'd', 'W', 'A', 'S', 'D'].includes(event.key)) {
    pointerInside = false
  }
}

function onKeyUp (event) {
  keys.delete(event.key)
}

function toggleFullscreen () {
  const targetEl = boardWrap.value
  if (!targetEl) return
  if (document.fullscreenElement) document.exitFullscreen()
  else targetEl.requestFullscreen?.()
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
  buildAmbient()
  for (let i = 0; i < 14; i++) {
    const fish = makeFish(true, i)
    fish.baseY = fish.y
    fishes.push(fish)
  }
  resize()
  raf = requestAnimationFrame(loop)
  window.addEventListener('keydown', onKeyDown)
  window.addEventListener('keyup', onKeyUp)
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
  window.removeEventListener('keyup', onKeyUp)
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
.main { max-width: 960px; display: flex; flex-direction: column; gap: 22px; }
.stage { display: flex; flex-direction: column; gap: 14px; animation: rise .55s var(--ease) both; }
.hud {
  display: flex;
  align-items: stretch;
  justify-content: space-between;
  gap: 0;
  flex-wrap: wrap;
  width: 100%;
  max-width: 780px;
  margin: 0 auto;
  border-radius: 18px;
  background: var(--porcelain-flat);
  border: 1px solid var(--porcelain-line);
  box-shadow: var(--gloss), var(--lift);
  overflow: hidden;
}
.hud__stats { display: grid; grid-template-columns: repeat(4, minmax(68px, auto)); flex: 1; min-width: 0; }
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
.stat--lg b { font-size: 23px; }
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

.board {
  position: relative;
  width: 100%;
  max-width: 780px;
  margin: 0 auto;
  aspect-ratio: 16 / 10;
  overflow: hidden;
  border-radius: 22px;
  border: 1px solid rgba(232, 162, 198, .66);
  background: #22152b;
  box-shadow:
    0 34px 70px -40px rgba(54, 18, 40, .9),
    0 0 0 8px rgba(255, 255, 255, .52),
    0 0 90px -46px rgba(231, 113, 162, .8);
}
.board canvas { display: block; width: 100%; height: 100%; touch-action: none; cursor: crosshair; }
.board:fullscreen {
  max-width: none;
  width: auto;
  height: 100vh;
  aspect-ratio: 16 / 10;
  border-radius: 0;
  border: 0;
  box-shadow: none;
}
.board__hint {
  position: absolute;
  left: 50%;
  bottom: 12px;
  z-index: 2;
  transform: translateX(-50%);
  color: rgba(255, 224, 237, .45);
  font-size: 9px;
  letter-spacing: .16em;
  white-space: nowrap;
  pointer-events: none;
}
.overlay {
  position: absolute;
  inset: 0;
  z-index: 3;
  display: grid;
  place-items: center;
  padding: 20px;
  text-align: center;
  background: rgba(28, 14, 24, .73);
  backdrop-filter: blur(10px);
  animation: fade .35s var(--ease);
}
@keyframes fade { from { opacity: 0 } to { opacity: 1 } }
.ov { display: flex; flex-direction: column; align-items: center; gap: 12px; max-width: 420px; }
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
  font-size: clamp(24px, 3vw, 31px);
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

.panels { display: grid; grid-template-columns: 1.15fr 1fr .85fr; gap: 14px; max-width: 960px; width: 100%; margin: 0 auto; }
.card {
  padding: 18px;
  border: 1px solid var(--porcelain-line);
  border-radius: 19px;
  background: var(--porcelain-flat);
  box-shadow: var(--gloss), 0 16px 34px -30px rgba(112, 68, 100, .55);
}
.card__title { margin: 0 0 13px; font-family: var(--font-serif); font-size: 15px; font-weight: 600; color: var(--ink); }
.growth { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; }
.growth .stat { padding: 7px 9px; border-left: 1px solid var(--line-soft); }
.growth .stat:first-child { border-left: 0; padding-left: 0; }
.growth-track { height: 6px; margin: 13px 0 9px; overflow: hidden; border-radius: 999px; background: var(--sakura-100); }
.growth-track span { display: block; height: 100%; border-radius: inherit; background: linear-gradient(90deg, var(--sakura-400), #b9a2e2); transition: width .3s var(--ease); }
.hint { margin: 0; color: var(--faint); font-size: 10px; line-height: 1.7; }
.rules { margin: 0; padding: 0; list-style: none; display: flex; flex-direction: column; gap: 7px; }
.rules li { position: relative; padding-left: 11px; color: var(--muted); font-size: 10px; line-height: 1.55; }
.rules li::before { content: ''; position: absolute; left: 0; top: .55em; width: 4px; height: 4px; border-radius: 50%; background: var(--sakura-300); }
.fish-legend { display: flex; gap: 8px; margin: 18px 0; }
.fish-legend span { width: 24px; height: 24px; border-radius: 50% 40% 40% 50%; box-shadow: inset 0 1px 3px rgba(255,255,255,.5), 0 6px 12px -8px rgba(106,64,98,.65); }
.card--sea { background: linear-gradient(155deg, rgba(255,255,255,.86), rgba(239,235,255,.74)); }
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

@media (max-width: 900px) {
  .panels { grid-template-columns: 1fr 1fr; }
  .card--sea { grid-column: 1 / -1; }
  .fish-legend { margin: 10px 0; }
}
@media (max-width: 760px) {
  .main { padding-left: 16px; padding-right: 16px; }
  .hud { max-width: 100%; }
  .hud__stats { grid-template-columns: repeat(2, 1fr); }
  .hud__stats .stat:nth-child(3) { border-left: 0; border-top: 1px solid var(--line-soft); }
  .hud__stats .stat:nth-child(4) { border-top: 1px solid var(--line-soft); }
  .hud__btns { width: 100%; justify-content: flex-end; border-left: 0; border-top: 1px solid var(--line-soft); }
  .board { aspect-ratio: 4 / 3; min-height: 300px; }
  .panels { grid-template-columns: 1fr; }
  .card--sea { grid-column: auto; }
}
@media (max-width: 460px) {
  .hud__btns { justify-content: center; flex-wrap: wrap; }
  .board { min-height: 270px; aspect-ratio: 1 / 1; }
  .ov { gap: 9px; }
  .ov__text { font-size: 11.5px; }
  .foot { flex-wrap: wrap; gap: 7px; }
}
</style>
