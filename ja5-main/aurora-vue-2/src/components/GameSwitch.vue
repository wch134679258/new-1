<template>
  <nav class="game-switch" aria-label="选择小游戏">
    <button
      v-for="game in games"
      :key="game.key"
      class="game-switch__item"
      :class="{ 'game-switch__item--on': active === game.key }"
      type="button"
      @click="$emit('select', game.key)"
    >
      <span class="game-switch__dot" :style="{ background: game.dot }"></span>
      <span>{{ game.label }}</span>
      <i>{{ game.tag }}</i>
    </button>
  </nav>
</template>

<script setup>
defineProps({
  active: { type: String, default: 'game' }
})
defineEmits(['select'])

const games = [
  { key: 'game', label: '花瓣贪吃蛇', tag: 'SNAKE', dot: 'linear-gradient(135deg, #9fe7d2, #d8a6dc)' },
  { key: 'tetris', label: '樱落方块', tag: 'TETRIS', dot: 'linear-gradient(135deg, #f4a6c2, #9e9be0)' },
  { key: 'fish', label: '樱海大鱼', tag: 'FISH', dot: 'linear-gradient(135deg, #9fd9ed, #e8abcf)' }
]
</script>

<style scoped>
.game-switch {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  margin: 0 0 24px;
  padding: 5px;
  border: 1px solid rgba(255, 255, 255, .8);
  border-radius: 15px;
  background: rgba(255, 250, 252, .58);
  box-shadow: 0 12px 28px -26px rgba(112, 68, 100, .6);
  backdrop-filter: blur(12px);
}
.game-switch__item {
  display: flex;
  align-items: center;
  gap: 7px;
  min-height: 35px;
  padding: 0 12px;
  border: 1px solid transparent;
  border-radius: 11px;
  background: transparent;
  color: var(--muted);
  font: inherit;
  font-size: 11.5px;
  cursor: pointer;
  transition: .24s var(--ease);
}
.game-switch__item i {
  color: var(--faint);
  font-size: 7.5px;
  font-style: normal;
  letter-spacing: .12em;
}
.game-switch__dot { width: 7px; height: 7px; border-radius: 50%; }
.game-switch__item:hover { color: var(--sakura-700); background: rgba(255, 255, 255, .55); }
.game-switch__item--on {
  color: var(--sakura-700);
  border-color: rgba(234, 175, 203, .55);
  background: linear-gradient(110deg, rgba(255, 255, 255, .94), rgba(252, 230, 241, .8));
  box-shadow: 0 7px 15px -14px rgba(197, 58, 100, .7);
}
.game-switch__item--on i { color: var(--sakura-400); }
@media (max-width: 480px) {
  .game-switch { width: 100%; }
  .game-switch__item { flex: 1; justify-content: center; padding: 0 8px; }
  .game-switch__item i { display: none; }
}
</style>
