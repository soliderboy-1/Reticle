<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const username = ref('')
const password = ref('')
const error = ref('')
const loading = ref(false)

async function handleSubmit() {
  error.value = ''
  if (!username.value || !password.value) {
    error.value = '请填写用户名和密码'
    return
  }
  loading.value = true
  const ok = await authStore.login({ username: username.value, password: password.value })
  loading.value = false
  if (ok) {
    router.push('/')
  } else {
    error.value = '登录失败，请检查用户名和密码'
  }
}
</script>

<template>
  <div class="relative min-h-screen overflow-hidden">
    <div class="mesh-bg">
      <div class="mesh-blob mesh-1" />
      <div class="mesh-blob mesh-2" />
      <div class="mesh-blob mesh-3" />
    </div>

    <div class="relative z-10 min-h-screen flex flex-col items-center justify-center px-6 py-14">
      <!-- Brand -->
      <div class="text-center mb-9 fade-in">
        <div class="relative w-16 h-16 mx-auto mb-5 rounded-[20px] bg-[#1d1d1f] flex items-center justify-center shadow-[0_18px_40px_-18px_rgba(0,0,0,0.5)]">
          <svg class="w-8 h-8 text-white" fill="none" viewBox="0 0 64 64">
            <g stroke="#FFFFFF" stroke-width="4.5" stroke-linecap="round" stroke-linejoin="round">
              <path d="M17 26v-6a3 3 0 0 1 3-3h6" />
              <path d="M47 26v-6a3 3 0 0 0-3-3h-6" />
              <path d="M17 38v6a3 3 0 0 0 3 3h6" />
              <path d="M47 38v6a3 3 0 0 1-3 3h-6" />
            </g>
            <rect x="27" y="27" width="10" height="10" rx="2.5" fill="#FFFFFF" />
          </svg>
        </div>
        <h1 class="text-[32px] font-semibold tracking-tight text-[#1d1d1f]">Reticle</h1>
        <p class="text-[15px] text-[#6e6e73] mt-2">多智能体协同的智能合约审计与修复平台</p>
        <p class="text-[10.5px] tracking-[0.18em] text-[#aeaeb2] mt-2 uppercase">Multi-Agent Smart Contract Audit</p>
      </div>

      <!-- Form card -->
      <div class="w-full max-w-[420px] glass-card p-8 fade-in" style="animation-delay: 80ms">
        <div class="mb-7">
          <h2 class="text-[24px] font-semibold tracking-tight text-[#1d1d1f]">登录</h2>
          <p class="text-[13px] text-[#86868b] mt-1">使用你的 Reticle 账号继续</p>
        </div>

        <form @submit.prevent="handleSubmit" class="space-y-4">
          <div>
            <label class="block text-[12px] font-medium text-[#6e6e73] mb-1.5">用户名</label>
            <input
              v-model="username"
              type="text"
              class="w-full px-4 py-3 bg-[#f5f5f7] border border-transparent rounded-xl text-[14px] text-[#1d1d1f] placeholder-[#aeaeb2] transition-all"
              placeholder="请输入用户名"
              autocomplete="username"
            />
          </div>

          <div>
            <label class="block text-[12px] font-medium text-[#6e6e73] mb-1.5">密码</label>
            <input
              v-model="password"
              type="password"
              class="w-full px-4 py-3 bg-[#f5f5f7] border border-transparent rounded-xl text-[14px] text-[#1d1d1f] placeholder-[#aeaeb2] transition-all"
              placeholder="请输入密码"
              autocomplete="current-password"
            />
          </div>

          <Transition name="page">
            <div v-if="error" class="text-[12.5px] text-[#d70015] bg-[#ff3b30]/[0.07] border border-[#ff3b30]/15 px-3.5 py-2.5 rounded-xl">
              {{ error }}
            </div>
          </Transition>

          <button type="submit" :disabled="loading" class="btn-primary w-full mt-2">
            <svg v-if="loading" class="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
            </svg>
            {{ loading ? '登录中…' : '继续' }}
          </button>
        </form>

        <div class="flex items-center gap-3 my-6">
          <div class="flex-1 h-px bg-black/[0.06]" />
          <span class="text-[11px] text-[#aeaeb2]">或</span>
          <div class="flex-1 h-px bg-black/[0.06]" />
        </div>

        <router-link
          to="/register"
          class="block w-full text-center py-3 rounded-xl text-[14px] text-[#0071e3] bg-[#0071e3]/[0.06] hover:bg-[#0071e3]/[0.1] transition-colors"
        >
          创建新账号
        </router-link>

        <p class="mt-6 text-center text-[11.5px] text-[#86868b]">
          演示账号
          <span class="font-mono text-[#1d1d1f] ml-1">demo_auditor / demo-pass-123</span>
        </p>
      </div>

      <p class="mt-8 text-[11px] text-[#aeaeb2] fade-in" style="animation-delay: 160ms">
        © 2026 Reticle · 检索增强与多智能体协同架构
      </p>
    </div>
  </div>
</template>
