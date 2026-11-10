<template>
  <div class="pager">
    <button type="button" :disabled="page <= 1" @click="$emit('change', page - 1)">上一页</button>
    <span>{{ page }} / {{ Math.max(1, pages) }}</span>
    <button type="button" :disabled="page >= pages" @click="$emit('change', page + 1)">下一页</button>
  </div>
</template>

<script setup>
defineProps({
  page: { type: Number, default: 1 },
  pages: { type: Number, default: 1 }
})
defineEmits(['change'])
</script>

<style scoped>
.pager {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 10px;
  margin-top: 14px;
  color: var(--muted);
  font-size: 10.5px;
}
.pager button {
  min-width: 58px;
  height: 31px;
  border: 1px solid rgba(218, 179, 203, .6);
  border-radius: 9px;
  background: rgba(255, 255, 255, .65);
  color: var(--muted);
  font: inherit;
  font-size: 10.5px;
  cursor: pointer;
}
.pager button:hover:not(:disabled) {
  color: var(--sakura-700);
  border-color: var(--sakura-300);
  background: #fff;
}
.pager button:disabled { opacity: .38; cursor: not-allowed; }
@media (max-width: 640px) {
  .pager { justify-content: center; }
}
</style>
