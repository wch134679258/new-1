<template>
  <div class="town-page">
    <SiteNav :user="user" active="town" @go="$emit('navigate', $event)" @logout="$emit('logout')" />

    <main class="town" :class="{ 'town--gust': gusting }">
      <!-- 天空、远山、小镇与樱花树全部由 SVG 绘制，离线也能完整显示 -->
      <svg class="town__art" viewBox="0 0 1440 860" preserveAspectRatio="xMidYMid slice" role="img"
           aria-label="粉紫色天空下，一棵巨大的樱花树坐落在木屋、街道和远山之间">
        <defs>
          <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" stop-color="#c5b4e1" />
            <stop offset=".42" stop-color="#efd0df" />
            <stop offset=".74" stop-color="#f9e5dc" />
            <stop offset="1" stop-color="#fff4e8" />
          </linearGradient>
          <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" stop-color="#cfc5d3" />
            <stop offset=".48" stop-color="#d9c8cc" />
            <stop offset="1" stop-color="#9d91a7" />
          </linearGradient>
          <linearGradient id="road" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" stop-color="#ead8d0" />
            <stop offset="1" stop-color="#f4e3dc" />
          </linearGradient>
          <linearGradient id="trunk" x1="0" y1="0" x2="1" y2="0">
            <stop offset="0" stop-color="#594153" />
            <stop offset=".35" stop-color="#7b5861" />
            <stop offset=".65" stop-color="#936b70" />
            <stop offset="1" stop-color="#4c374c" />
          </linearGradient>
          <radialGradient id="canopy" cx=".45" cy=".38" r=".72">
            <stop offset="0" stop-color="#ffe2ed" />
            <stop offset=".45" stop-color="#efabc9" />
            <stop offset=".78" stop-color="#d98bb8" />
            <stop offset="1" stop-color="#b66c9f" />
          </radialGradient>
          <radialGradient id="lampGlow">
            <stop offset="0" stop-color="#fff2c3" stop-opacity=".95" />
            <stop offset=".24" stop-color="#ffe6b2" stop-opacity=".52" />
            <stop offset="1" stop-color="#ffe6b2" stop-opacity="0" />
          </radialGradient>
          <filter id="softBlur"><feGaussianBlur stdDeviation="16" /></filter>
          <filter id="softGlow" x="-40%" y="-40%" width="180%" height="180%">
            <feGaussianBlur stdDeviation="8" result="blur" />
            <feMerge><feMergeNode in="blur" /><feMergeNode in="SourceGraphic" /></feMerge>
          </filter>

          <g id="house">
            <ellipse cx="90" cy="142" rx="94" ry="15" fill="#775870" opacity=".16" />
            <rect x="22" y="55" width="136" height="92" rx="5" fill="#f3e2d7" />
            <path d="M8 65 90 5l82 60Z" fill="#785b79" />
            <path d="M22 61 90 13l68 48-9 5-59-41-59 41Z" fill="#9d718e" />
            <path d="M31 63h119v10H31z" fill="#c89b9d" />
            <rect x="76" y="93" width="29" height="54" rx="4" fill="#8e6574" />
            <circle cx="99" cy="122" r="2.3" fill="#f9dca5" />
            <rect x="35" y="82" width="27" height="27" rx="4" fill="#ffe3a8" />
            <rect x="119" y="82" width="27" height="27" rx="4" fill="#ffe3a8" />
            <path d="M48.5 82v27M35 95.5h27M132.5 82v27M119 95.5h27" stroke="#a3737d" stroke-width="3" />
            <path d="M22 74h136M22 117h54M105 117h53" stroke="#b88891" stroke-width="4" opacity=".65" />
            <path d="M30 72v75M150 72v75M67 72v10M116 72v10" stroke="#9e717e" stroke-width="4" />
            <rect x="128" y="11" width="16" height="34" rx="2" fill="#856176" />
            <path d="M126 11h20" stroke="#68495f" stroke-width="5" />
            <path d="M43 145c9-20 20-20 29 0M123 145c9-22 21-22 30 0" fill="#9ca58d" />
          </g>

          <g id="lamp">
            <ellipse cx="0" cy="105" rx="17" ry="4" fill="#6e5068" opacity=".22" />
            <path d="M0 104V22" stroke="#61465d" stroke-width="6" stroke-linecap="round" />
            <path d="M0 26c0-17 14-18 22-18" fill="none" stroke="#61465d" stroke-width="4" />
            <circle cx="24" cy="16" r="54" fill="url(#lampGlow)" />
            <path d="m15 6 18 0-3 22H18Z" fill="#ffeab4" stroke="#72536a" stroke-width="2.5" />
            <path d="M14 6h20M19 0h10" stroke="#72536a" stroke-width="3" stroke-linecap="round" />
          </g>
        </defs>

        <!-- 天空 -->
        <rect width="1440" height="860" fill="url(#sky)" />
        <circle cx="1160" cy="132" r="90" fill="#fff0d4" opacity=".32" filter="url(#softBlur)" />
        <circle cx="1160" cy="132" r="43" fill="#fff4dc" opacity=".8" />

        <g class="cloud cloud--one" fill="#fff8f5" opacity=".6">
          <ellipse cx="200" cy="150" rx="110" ry="29" />
          <ellipse cx="156" cy="139" rx="56" ry="30" />
          <ellipse cx="224" cy="130" rx="62" ry="37" />
          <ellipse cx="280" cy="149" rx="65" ry="23" />
        </g>
        <g class="cloud cloud--two" fill="#fff5f3" opacity=".48">
          <ellipse cx="1040" cy="234" rx="110" ry="22" />
          <ellipse cx="1000" cy="221" rx="50" ry="26" />
          <ellipse cx="1075" cy="217" rx="62" ry="28" />
        </g>
        <g class="cloud cloud--three" fill="#fff8f4" opacity=".36">
          <ellipse cx="475" cy="106" rx="92" ry="19" />
          <ellipse cx="450" cy="94" rx="42" ry="23" />
          <ellipse cx="500" cy="91" rx="48" ry="25" />
        </g>

        <!-- 远山 -->
        <path d="M0 395 155 268l108 84 182-177 147 143 166-127 132 124 174-147 162 168 214-94v301H0Z"
              fill="#9d91b8" opacity=".42" />
        <path d="m345 279 100-104 62 60-49-21-29 26-20-19Z" fill="#f5e6ec" opacity=".72" />
        <path d="m787 309 58-53 62 58-38-18-25 17-22-15Z" fill="#f7e8ee" opacity=".62" />
        <path d="M0 420c161-55 286-58 422-4s264 58 412 9 345-45 606 19v219H0Z" fill="#b8a4bf" opacity=".52" />
        <path d="M0 474c168-49 296-35 452 14s289 43 435 0 349-45 553 13v205H0Z" fill="#c4b0c5" opacity=".7" />

        <!-- 远景小镇 -->
        <g opacity=".62">
          <use href="#house" transform="translate(120 393) scale(.44)" />
          <use href="#house" transform="translate(255 418) scale(.34)" />
          <use href="#house" transform="translate(1100 386) scale(.43)" />
          <use href="#house" transform="translate(1230 416) scale(.34)" />
        </g>

        <!-- 地面与蜿蜒街道 -->
        <path d="M0 570c232-52 423-37 611-6s421 33 829-26v322H0Z" fill="url(#ground)" />
        <path d="M620 860c21-128 108-152 125-204 17-53-19-88-5-123 32 21 94 26 125 1 9 52-19 89-6 128 14 46 92 99 140 198Z"
              fill="#b99ba9" opacity=".35" />
        <path d="M634 860c20-121 103-160 119-211 16-52-23-90-8-128 33 18 76 20 104-2 4 55-25 94-7 143 20 54 88 106 124 198Z"
              fill="url(#road)" />
        <path d="M744 551c-15 35 24 62 16 105M765 675c-14 35-42 57-53 95" fill="none"
              stroke="#fff2e8" stroke-width="4" stroke-dasharray="2 18" stroke-linecap="round" opacity=".6" />

        <!-- 小镇木屋 -->
        <use href="#house" transform="translate(54 490) scale(1.12)" />
        <use href="#house" transform="translate(244 563) scale(.74)" />
        <use href="#house" transform="translate(1170 476) scale(1.04)" />
        <use href="#house" transform="translate(1064 580) scale(.66)" />

        <!-- 木栅栏 -->
        <g stroke="#9b7784" stroke-width="5" stroke-linecap="round" opacity=".76">
          <path d="M0 695h285M0 722h285M1150 704h290M1150 731h290" />
          <path d="M25 680v70M85 680v70M145 680v70M205 680v70M265 680v70M1185 688v70M1245 688v70M1305 688v70M1365 688v70" />
        </g>

        <!-- 樱花树阴影 -->
        <ellipse cx="765" cy="748" rx="229" ry="40" fill="#745571" opacity=".18" filter="url(#softBlur)" />
        <ellipse cx="765" cy="738" rx="142" ry="20" fill="#61435e" opacity=".19" />

        <!-- 巨大的樱花树 -->
        <g class="tree-art">
          <!-- 树干与枝条 -->
          <path d="M689 754c22-69 34-128 30-186-4-63-42-99-100-150l29-31c47 39 86 65 112 107 5-75-3-130-42-198l42-18c34 67 48 133 44 198 48-60 104-94 173-126l27 38c-78 44-134 97-164 163-4 72 9 136 35 205-58 15-120 16-186-2Z"
                fill="url(#trunk)" />
          <path d="M735 610c-52-73-129-126-236-175M762 532c57-75 133-121 246-160M759 481c-12-82-31-128-71-184M785 488c43-71 86-111 133-151"
                fill="none" stroke="#795363" stroke-width="24" stroke-linecap="round" />
          <path d="M731 711c10-75 8-135-3-182M761 693c-8-67-2-123 15-175" fill="none"
                stroke="#bd8b8c" stroke-width="9" stroke-linecap="round" opacity=".55" />
          <path d="M688 752c-29 6-49 18-70 32M826 752c34 5 60 16 83 31M747 754c-3 15-3 28-1 42"
                fill="none" stroke="#6e4d60" stroke-width="17" stroke-linecap="round" />

          <!-- 树冠底色 -->
          <path d="M460 388c-54-54-25-125 42-151-7-67 57-120 120-101 39-76 133-83 185-24 74-42 157-6 172 64 78 0 126 69 105 132 68 30 86 109 36 159 24 74-40 129-110 119-41 57-125 63-176 18-62 51-153 32-179-33-78 34-159-7-164-78-73 6-121-54-99-113-38 5-68-1-88-14Z"
                fill="url(#canopy)" opacity=".86" />

          <!-- 细密花团，增加树冠层次 -->
          <g>
            <ellipse
              v-for="b in blossoms"
              :key="b.id"
              :cx="b.x" :cy="b.y" :rx="b.rx" :ry="b.ry"
              :fill="b.color" :opacity="b.opacity"
              :transform="`rotate(${b.rot} ${b.x} ${b.y})`"
            />
          </g>

          <!-- 枝间透出的深色枝干 -->
          <path d="M610 427c47 18 85 43 122 78M858 424c-35 21-61 47-83 82M701 297c24 42 39 80 43 119"
                fill="none" stroke="#93617d" stroke-width="7" stroke-linecap="round" opacity=".5" />

          <!-- 花冠高光 -->
          <g fill="#fff0f6" opacity=".72" filter="url(#softGlow)">
            <ellipse cx="616" cy="216" rx="11" ry="7" transform="rotate(-20 616 216)" />
            <ellipse cx="756" cy="155" rx="12" ry="8" transform="rotate(15 756 155)" />
            <ellipse cx="890" cy="225" rx="10" ry="6" transform="rotate(-18 890 225)" />
            <ellipse cx="506" cy="331" rx="9" ry="6" transform="rotate(26 506 331)" />
            <ellipse cx="1004" cy="352" rx="11" ry="7" transform="rotate(-24 1004 352)" />
          </g>
        </g>

        <!-- 路灯 -->
        <use href="#lamp" transform="translate(362 615) scale(.9)" />
        <use href="#lamp" transform="translate(1118 613) scale(.92)" />
        <use href="#lamp" transform="translate(486 525) scale(.48)" opacity=".7" />

        <!-- 前景花草 -->
        <path d="M0 811c179-36 319-25 443 16 156 50 323 45 481 2 169-45 337-44 516-7v38H0Z" fill="#8f829c" opacity=".54" />
        <g>
          <g v-for="f in flowers" :key="f.id" :transform="`translate(${f.x} ${f.y}) scale(${f.s})`">
            <path d="M0 20V0" stroke="#74816f" stroke-width="2" />
            <circle cx="-4" cy="-2" r="4" :fill="f.color" />
            <circle cx="4" cy="-2" r="4" :fill="f.color" />
            <circle cy="-6" r="4" :fill="f.color" />
            <circle cy="2" r="4" :fill="f.color" />
            <circle cy="-2" r="2.4" fill="#ffe7ad" />
          </g>
        </g>

      </svg>

      <!-- 真实花瓣动画层 -->
      <canvas ref="petalCanvas" class="town__petals" aria-hidden="true"></canvas>

      <!-- 点击热区：覆盖树冠与树干 -->
      <button class="tree-hit" type="button" aria-label="轻点樱花树，唤起一阵花雨" @click="burstPetals"></button>

      <!-- 首页文案 -->
      <section class="town__intro">
        <p class="town__eyebrow"><span></span>SAKURA TOWN · 樱花小镇</p>
        <h1>在花落的<br /><em>小镇里，慢慢生活。</em></h1>
        <p class="town__lede">远山很轻，街灯很暖。这里收着你的手记、故事和那些不急着完成的心情。</p>
        <div class="town__actions">
          <button class="town__primary" type="button" @click="$emit('navigate', 'home')">
            走进手记馆
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
              <path d="M5 12h14M13 6l6 6-6 6" />
            </svg>
          </button>
          <button class="town__secondary" type="button" @click="$emit('navigate', 'discover')">沿街漫游</button>
        </div>
        <p class="town__click-hint"><span>✦</span>轻点樱花树，让春风经过</p>
      </section>

      <p class="town__foot">SAKURA NOTE · A LITTLE TOWN FOR SLOW DAYS</p>
    </main>
  </div>
</template>

<script setup>
import { onBeforeUnmount, onMounted, ref } from 'vue'
import SiteNav from './SiteNav.vue'

defineProps({
  user: { type: Object, default: null }
})
defineEmits(['navigate', 'logout'])

// 使用固定随机种子，保证每次渲染的树冠都稳定
function seeded (seed) {
  return function () {
    seed |= 0
    seed = seed + 0x6D2B79F5 | 0
    let t = Math.imul(seed ^ seed >>> 15, 1 | seed)
    t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t
    return ((t ^ t >>> 14) >>> 0) / 4294967296
  }
}
const rand = seeded(20261111)

const clusters = [
  { x: 522, y: 314, rx: 98, ry: 104 },
  { x: 587, y: 218, rx: 112, ry: 102 },
  { x: 710, y: 175, rx: 124, ry: 104 },
  { x: 830, y: 184, rx: 130, ry: 108 },
  { x: 940, y: 252, rx: 126, ry: 110 },
  { x: 982, y: 378, rx: 102, ry: 101 },
  { x: 864, y: 456, rx: 131, ry: 96 },
  { x: 702, y: 463, rx: 143, ry: 99 },
  { x: 556, y: 414, rx: 100, ry: 90 },
  { x: 741, y: 316, rx: 183, ry: 143 }
]
const blossomColors = ['#ffd9e8', '#ffc3da', '#f3abc9', '#e998bf', '#dc89b4', '#f8c9de', '#ffe5ef']
const blossoms = []
clusters.forEach((c, ci) => {
  const count = ci === 9 ? 35 : 20
  for (let i = 0; i < count; i++) {
    const angle = rand() * Math.PI * 2
    const radius = Math.sqrt(rand())
    const x = c.x + Math.cos(angle) * c.rx * radius
    const y = c.y + Math.sin(angle) * c.ry * radius
    const size = 7 + rand() * 19
    blossoms.push({
      id: `${ci}-${i}`,
      x: Math.round(x * 10) / 10,
      y: Math.round(y * 10) / 10,
      rx: Math.round(size * 10) / 10,
      ry: Math.round(size * (.65 + rand() * .45) * 10) / 10,
      color: blossomColors[Math.floor(rand() * blossomColors.length)],
      opacity: .18 + rand() * .43,
      rot: Math.round(rand() * 80 - 40)
    })
  }
})

const flowerColors = ['#ffd4e5', '#e4c6f0', '#fff1db', '#d5e3cf']
const flowers = []
for (let i = 0; i < 42; i++) {
  const x = 20 + rand() * 1400
  // 避开中央街道
  if (x > 620 && x < 960) continue
  flowers.push({
    id: i,
    x: Math.round(x),
    y: Math.round(790 + rand() * 63),
    s: .55 + rand() * .7,
    color: flowerColors[Math.floor(rand() * flowerColors.length)]
  })
}

// ---------- Canvas 花瓣 ----------
const petalCanvas = ref(null)
const gusting = ref(false)
let canvasCtx = null
let sceneEl = null
let width = 0
let height = 0
let dpr = 1
let petals = []
let raf = null
let lastTime = 0
let resizeObserver = null
let gustTimer = null
let reduceMotion = false

function random (min, max) {
  return min + Math.random() * (max - min)
}

function makePetal (x, y, burst = false) {
  const depth = random(.35, 1.35)
  const ambient = !burst
  return {
    x,
    y,
    depth,
    size: random(4.2, 9.2) * depth,
    vx: ambient ? random(-5, 18) * depth : random(55, 245) * depth,
    vy: ambient ? random(10, 28) * depth : random(-62, 48) * depth,
    rot: random(0, Math.PI * 2),
    spin: random(-3.4, 3.4),
    phase: random(0, Math.PI * 2),
    wave: random(12, 44) * depth,
    scale: random(.75, 1.25),
    alpha: random(.36, .88) * Math.min(1, .58 + depth * .38),
    age: 0,
    ttl: burst ? random(2.8, 4.6) : Infinity,
    ambient,
    hue: Math.random() < .24 ? '#e5b7ee' : (Math.random() < .5 ? '#ffd0e2' : '#f4a7c8')
  }
}

function seedAmbient () {
  petals = []
  const count = reduceMotion ? 12 : 32
  for (let i = 0; i < count; i++) {
    petals.push(makePetal(random(0, width), random(-height * .2, height), false))
  }
}

function burstPetals () {
  if (!width || !height) return
  const count = reduceMotion ? 48 : 170
  for (let i = 0; i < count; i++) {
    const x = width * random(.39, .65)
    const y = height * random(.18, .55)
    petals.push(makePetal(x, y, true))
  }
  // 限制总数，连续点击也不会无限堆积
  if (petals.length > 460) petals = petals.slice(petals.length - 460)
  gusting.value = false
  requestAnimationFrame(() => { gusting.value = true })
  clearTimeout(gustTimer)
  gustTimer = setTimeout(() => { gusting.value = false }, 1500)
}

function resize () {
  const cvs = petalCanvas.value
  if (!cvs) return
  const rect = cvs.getBoundingClientRect()
  width = Math.max(1, rect.width)
  height = Math.max(1, rect.height)
  dpr = Math.min(window.devicePixelRatio || 1, 2)
  cvs.width = Math.round(width * dpr)
  cvs.height = Math.round(height * dpr)
  canvasCtx.setTransform(dpr, 0, 0, dpr, 0, 0)
  seedAmbient()
}

function drawPetal (p, time) {
  const flutter = 1 + Math.sin(time * 4 + p.phase) * .22
  const scale = p.scale * flutter
  canvasCtx.save()
  canvasCtx.translate(p.x, p.y)
  canvasCtx.rotate(p.rot)
  canvasCtx.scale(scale, scale)
  canvasCtx.globalAlpha = Math.max(0, p.alpha)
  if (p.depth < .6) canvasCtx.filter = 'blur(.55px)'
  canvasCtx.fillStyle = p.hue
  canvasCtx.beginPath()
  canvasCtx.moveTo(0, -p.size)
  canvasCtx.bezierCurveTo(p.size * .9, -p.size * .85, p.size * 1.08, p.size * .25, 0, p.size)
  canvasCtx.bezierCurveTo(-p.size * 1.08, p.size * .25, -p.size * .9, -p.size * .85, 0, -p.size)
  canvasCtx.fill()
  canvasCtx.globalAlpha *= .55
  canvasCtx.strokeStyle = '#fff4fa'
  canvasCtx.lineWidth = .65
  canvasCtx.beginPath()
  canvasCtx.moveTo(0, -p.size * .72)
  canvasCtx.lineTo(0, p.size * .65)
  canvasCtx.stroke()
  canvasCtx.restore()
}

function frame (time) {
  if (!lastTime) lastTime = time
  const dt = Math.min(.04, (time - lastTime) / 1000)
  lastTime = time
  canvasCtx.clearRect(0, 0, width, height)
  const seconds = time / 1000

  for (const p of petals) {
    p.age += dt
    const gust = gusting.value ? 26 : 6
    p.vx += gust * p.depth * dt
    p.vy += (p.ambient ? 2.2 : 17) * p.depth * dt
    p.x += (p.vx + Math.sin(seconds * 1.8 + p.phase) * p.wave) * dt
    p.y += p.vy * dt
    p.rot += p.spin * dt

    if (p.ambient) {
      if (p.y > height + 18 || p.x > width + 28 || p.x < -35) {
        Object.assign(p, makePetal(random(-40, width * .7), -18, false))
      }
    } else if (p.age > p.ttl - 1) {
      p.alpha = Math.max(0, p.alpha - dt * .72)
    }
    drawPetal(p, seconds)
  }

  petals = petals.filter((p) => p.ambient || (p.age < p.ttl && p.alpha > .015 && p.x < width + 180 && p.y < height + 100))
  raf = requestAnimationFrame(frame)
}

onMounted(() => {
  sceneEl = petalCanvas.value
  canvasCtx = sceneEl.getContext('2d')
  reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches
  resize()
  resizeObserver = new ResizeObserver(resize)
  resizeObserver.observe(sceneEl)
  raf = requestAnimationFrame(frame)
})

onBeforeUnmount(() => {
  if (raf) cancelAnimationFrame(raf)
  if (resizeObserver) resizeObserver.disconnect()
  clearTimeout(gustTimer)
})
</script>

<style scoped>
.town-page {
  position: relative;
  z-index: 2;
  width: 100%;
  min-height: 100vh;
  padding: 0 20px 24px;
}
.town {
  position: relative;
  width: min(1440px, 100%);
  height: calc(100svh - 128px);
  min-height: 660px;
  margin: 0 auto;
  overflow: hidden;
  border: 1px solid rgba(255, 255, 255, .7);
  border-radius: 30px;
  background: linear-gradient(180deg, #d8c3e5, #f6dce5);
  box-shadow: 0 34px 80px -42px rgba(102, 64, 100, .55), var(--gloss);
  isolation: isolate;
}
.town__art,
.town__petals {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
}
.town__art { z-index: 1; display: block; }
.town__petals { z-index: 3; pointer-events: none; }
.tree-art {
  transform-origin: 760px 720px;
  animation: tree-breathe 7s ease-in-out infinite;
}
.town--gust .tree-art { animation: tree-gust 1.2s var(--ease); }
@keyframes tree-breathe {
  0%, 100% { transform: rotate(-.12deg); }
  50% { transform: rotate(.16deg); }
}
@keyframes tree-gust {
  0%, 100% { transform: rotate(0); }
  30% { transform: rotate(.75deg); }
  58% { transform: rotate(-.35deg); }
  78% { transform: rotate(.18deg); }
}
.cloud { transform-box: fill-box; transform-origin: center; }
.cloud--one { animation: cloud-drift 34s ease-in-out infinite; }
.cloud--two { animation: cloud-drift 42s ease-in-out infinite reverse; }
.cloud--three { animation: cloud-drift 38s ease-in-out infinite; }
@keyframes cloud-drift {
  0%, 100% { transform: translateX(-10px); }
  50% { transform: translateX(28px); }
}

.tree-hit {
  position: absolute;
  z-index: 4;
  left: 34%;
  top: 12%;
  width: 40%;
  height: 61%;
  border: 0;
  border-radius: 48%;
  outline: 0;
  background: transparent;
  cursor: pointer;
}
.tree-hit:focus-visible {
  outline: 2px dashed rgba(255, 244, 251, .85);
  outline-offset: -18px;
  background: rgba(255, 223, 239, .035);
}

.town__intro {
  position: absolute;
  z-index: 5;
  top: 11%;
  left: 5.4%;
  width: min(430px, 36%);
  color: #503e5d;
  text-shadow: 0 1px 18px rgba(255, 247, 252, .45);
}
.town__eyebrow {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  margin: 0 0 18px;
  color: #825a85;
  font-size: 10px;
  font-weight: 600;
  letter-spacing: .2em;
}
.town__eyebrow span {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: #d67eac;
  box-shadow: 0 0 0 5px rgba(255, 223, 237, .34);
}
.town__intro h1 {
  margin: 0;
  font-family: var(--font-serif);
  font-size: clamp(34px, 3.3vw, 48px);
  font-weight: 500;
  line-height: 1.24;
  letter-spacing: .025em;
  color: #503b5e;
}
.town__intro h1 em {
  font-style: normal;
  color: #9c5d8a;
  background: linear-gradient(110deg, #77517c, #ba6f9a);
  -webkit-background-clip: text;
  background-clip: text;
  -webkit-text-fill-color: transparent;
}
.town__lede {
  margin: 20px 0 0;
  max-width: 340px;
  color: rgba(82, 61, 91, .76);
  font-size: 13px;
  line-height: 1.95;
}
.town__actions { display: flex; align-items: center; gap: 12px; margin-top: 26px; }
.town__primary,
.town__secondary {
  height: 43px;
  border-radius: 999px;
  font: inherit;
  font-size: 12px;
  cursor: pointer;
  transition: transform .25s var(--ease), box-shadow .25s, background .25s;
}
.town__primary {
  display: inline-flex;
  align-items: center;
  gap: 14px;
  padding: 0 21px;
  border: 0;
  background: linear-gradient(120deg, #d780ac, #9a78bd);
  color: #fff9fc;
  box-shadow: 0 14px 30px -18px rgba(141, 78, 126, .8);
}
.town__primary svg { width: 16px; height: 16px; transition: transform .25s; }
.town__primary:hover { transform: translateY(-2px); box-shadow: 0 18px 34px -18px rgba(141, 78, 126, .9); }
.town__primary:hover svg { transform: translateX(3px); }
.town__secondary {
  padding: 0 16px;
  border: 1px solid rgba(160, 107, 143, .25);
  background: rgba(255, 247, 251, .28);
  color: #815879;
  backdrop-filter: blur(8px);
}
.town__secondary:hover { transform: translateY(-2px); background: rgba(255, 249, 252, .62); }
.town__click-hint {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 22px 0 0;
  color: rgba(115, 78, 111, .58);
  font-size: 10.5px;
  letter-spacing: .08em;
}
.town__click-hint span { color: #c17ca5; animation: hint-pulse 2.8s ease-in-out infinite; }
@keyframes hint-pulse { 50% { transform: rotate(45deg) scale(1.15); opacity: .55; } }
.town__foot {
  position: absolute;
  z-index: 5;
  right: 26px;
  bottom: 18px;
  margin: 0;
  color: rgba(255, 238, 246, .58);
  font-size: 8px;
  letter-spacing: .2em;
  text-shadow: 0 1px 6px rgba(69, 43, 65, .4);
}

@media (max-width: 1100px) {
  .town__intro { left: 4.2%; width: 360px; }
  .town__intro h1 { font-size: 38px; }
  .town__lede { font-size: 12px; }
}
@media (max-width: 820px) {
  .town-page { padding: 0 12px 18px; }
  .town { min-height: 790px; height: calc(100svh - 116px); border-radius: 24px; }
  .town__intro {
    top: 6%;
    left: 50%;
    width: 92%;
    max-width: 460px;
    transform: translateX(-50%);
    text-align: center;
  }
  .town__eyebrow { margin-bottom: 12px; font-size: 9px; }
  .town__intro h1 { font-size: clamp(30px, 8vw, 43px); }
  .town__intro h1 br { display: none; }
  .town__lede { max-width: 390px; margin: 14px auto 0; font-size: 11.5px; }
  .town__actions { justify-content: center; margin-top: 18px; }
  .town__click-hint { justify-content: center; margin-top: 14px; }
  .tree-hit { left: 15%; top: 29%; width: 70%; height: 55%; }
  .town__foot { right: 50%; transform: translateX(50%); white-space: nowrap; font-size: 7px; }
}
@media (max-width: 480px) {
  .town { min-height: 730px; }
  .town__lede { display: none; }
  .town__intro { top: 5%; }
  .town__primary, .town__secondary { height: 39px; font-size: 11px; }
  .town__click-hint { font-size: 9.5px; }
}
@media (prefers-reduced-motion: reduce) {
  .tree-art, .cloud, .town__click-hint span { animation: none; }
  .town__primary, .town__secondary { transition: none; }
}
</style>
