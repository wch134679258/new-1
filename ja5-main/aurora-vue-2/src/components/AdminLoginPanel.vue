<template>
  <div class="panel mode-login admin-panel">
    <template v-if="!loggedIn">
      <div class="admin-panel__badge">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"
             stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
          <rect x="5" y="10" width="14" height="10" rx="2.5" />
          <path d="M8 10V7a4 4 0 0 1 8 0v3M12 14v2" />
        </svg>
        ADMIN CONSOLE
      </div>

      <div class="head">
        <h2>后台管理系统</h2>
        <p>验证管理员身份，继续管理樱花小站</p>
      </div>

      <form id="form" novalidate @submit.prevent="submitLogin">
        <div id="fields" class="admin-panel__fields">
          <FormField
            id="admin-name"
            kind="user"
            label="管理员账号"
            for-modes="login"
            error="请输入至少 2 个字符"
            v-model="form.name"
            :invalid="invalid.name"
            autocomplete="username"
            @update:modelValue="clearField('name')"
          />

          <PasswordField
            id="admin-pass"
            label="登录密码"
            for-modes="login"
            error="请输入至少 6 位密码"
            v-model="form.password"
            :show="showPassword"
            :invalid="invalid.password"
            autocomplete="current-password"
            @toggle="showPassword = !showPassword"
            @update:modelValue="clearField('password')"
          />
        </div>

        <p class="form-error" v-if="formError">{{ formError }}</p>

        <button class="submit" type="submit" :data-state="submitState !== 'idle' ? submitState : null">
          <span class="txt">{{ submitState === 'loading' ? '正在验证' : '登录后台' }}</span>
          <span class="spin"></span>
        </button>
      </form>

      <div class="admin-panel__foot">
        <span>仅提供登录 · 不开放注册</span>
        <button type="button" @click="$emit('back')">返回首页</button>
      </div>
    </template>

    <div v-else class="admin-success">
      <span class="admin-success__icon" aria-hidden="true">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"
             stroke-linecap="round" stroke-linejoin="round">
          <path d="m5 12 4 4L19 6" />
        </svg>
      </span>
      <p class="admin-success__eyebrow">ADMIN CONSOLE</p>
      <h2>登录成功</h2>
      <p class="admin-success__text">欢迎回来，{{ adminName }}。<br>后台管理功能将在后续接入。</p>
      <button class="submit" type="button" @click="$emit('back')">
        <span class="txt">返回首页</span>
      </button>
    </div>
  </div>
</template>

<script setup>
import { reactive, ref } from 'vue'
import FormField from './FormField.vue'
import PasswordField from './PasswordField.vue'
import { adminLoginUser, getMe } from '../api/auth'

const emit = defineEmits(['success', 'back'])

const form = reactive({ name: '', password: '' })
const invalid = reactive({ name: false, password: false })
const showPassword = ref(false)
const submitState = ref('idle')
const formError = ref('')
const loggedIn = ref(false)
const adminName = ref('')

function clearField (field) {
  invalid[field] = false
  formError.value = ''
}

async function submitLogin () {
  formError.value = ''
  invalid.name = form.name.trim().length < 2
  invalid.password = form.password.length < 6
  if (invalid.name || invalid.password) return

  submitState.value = 'loading'
  try {
    await adminLoginUser({
      name: form.name.trim(),
      password: form.password,
      remember: true
    })
    const me = await getMe()
    if (!me || Number(me.permission) !== 0) {
      throw new Error('该账号没有后台管理权限')
    }
    adminName.value = me.name || form.name.trim()
    submitState.value = 'done'
    emit('success', me)
    window.setTimeout(() => { loggedIn.value = true }, 360)
  } catch (e) {
    submitState.value = 'idle'
    formError.value = (e && e.message) || '登录失败，请检查账号和密码'
  }
}
</script>

<style scoped>
.admin-panel__badge {
  display: inline-flex;
  align-items: center;
  align-self: flex-start;
  gap: 7px;
  margin-bottom: 18px;
  padding: 7px 11px;
  border: 1px solid var(--sakura-100);
  border-radius: 999px;
  background: linear-gradient(120deg, rgba(255, 255, 255, .78), rgba(250, 234, 247, .68));
  color: var(--sakura-600);
  font-size: 9px;
  font-weight: 600;
  letter-spacing: .16em;
}
.admin-panel__badge svg { width: 14px; height: 14px; }
.admin-panel__fields { min-height: 174px; }

.admin-panel__foot {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-top: 18px;
  color: var(--faint);
  font-size: 11px;
}
.admin-panel__foot button {
  padding: 4px 0;
  border: 0;
  background: transparent;
  color: var(--sakura-600);
  font: inherit;
  cursor: pointer;
}
.admin-panel__foot button:hover { color: var(--sakura-700); }

.admin-success {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 390px;
  text-align: center;
}
.admin-success__icon {
  display: grid;
  place-items: center;
  width: 66px;
  height: 66px;
  margin-bottom: 22px;
  border: 1px solid rgba(224, 139, 177, .28);
  border-radius: 50%;
  background: linear-gradient(140deg, #fff, var(--sakura-100));
  box-shadow: 0 16px 32px -22px rgba(197, 58, 100, .7);
  color: var(--sakura-600);
}
.admin-success__icon svg { width: 30px; height: 30px; }
.admin-success__eyebrow {
  margin: 0 0 10px;
  color: var(--sakura-500);
  font-size: 10px;
  letter-spacing: .22em;
}
.admin-success h2 {
  margin: 0;
  color: var(--ink);
  font-family: var(--font-serif);
  font-size: 28px;
}
.admin-success__text {
  margin: 14px 0 28px;
  color: var(--muted);
  font-size: 13px;
  line-height: 1.9;
}
.admin-success .submit { width: min(240px, 100%); }

@media (max-width: 520px) {
  .admin-panel__fields { min-height: 166px; }
  .admin-panel__foot { align-items: flex-start; font-size: 10px; }
  .admin-success { min-height: 330px; }
}
</style>
