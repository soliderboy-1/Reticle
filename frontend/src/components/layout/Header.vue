<script setup lang="ts">
import { ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

const userMenuOpen = ref(false)

const breadcrumbs = [
  { label: '控制台', path: '/' },
  { label: '安全审计', path: '/' },
]

function handleLogout() {
  authStore.logout()
  router.push('/login')
}

function toggleUserMenu() {
  userMenuOpen.value = !userMenuOpen.value
}
</script>

<template>
  <header class="glass-nav relative z-10 h-16 shrink-0 flex items-center justify-between px-7">
    <!-- Breadcrumb -->
    <div class="flex items-center gap-2.5 text-[13px]">
      <template v-for="(crumb, i) in breadcrumbs" :key="crumb.label">
        <svg v-if="i > 0" class="w-3.5 h-3.5 text-[#c7c7cc]" fill="currentColor" viewBox="0 0 24 24">
          <path d="M10 6L8.59 7.41 13.17 12l-4.58 4.59L10 18l6-6-6-6z" />
        </svg>
        <router-link
          :to="crumb.path"
          :class="i === breadcrumbs.length - 1 ? 'text-[#1d1d1f] font-medium' : 'text-[#86868b] hover:text-[#1d1d1f]'"
          class="transition-colors"
        >
          {{ crumb.label }}
        </router-link>
      </template>
      <span
        v-if="route.params.taskId"
        class="ml-1 px-2 py-0.5 rounded-md text-[11px] font-mono text-[#0071e3] bg-[#0071e3]/[0.08]"
      >
        #{{ String(route.params.taskId).slice(0, 12) }}
      </span>
    </div>

    <!-- Right -->
    <div class="flex items-center gap-3">
      <div class="hidden md:flex items-center gap-2 px-3 py-1.5 rounded-full bg-[#34c759]/[0.08] border border-[#34c759]/[0.16]">
        <span class="pulse-dot" />
        <span class="text-[11px] text-[#1d7a3f] font-medium">模型状态正常</span>
      </div>

      <div class="hidden md:block w-px h-6 bg-black/[0.06]" />

      <div class="relative">
        <button
          @click="toggleUserMenu"
          class="group flex items-center gap-2.5 pl-1 pr-2 py-1 rounded-full hover:bg-black/[0.04] transition-colors"
        >
          <span class="relative w-8 h-8 rounded-full bg-gradient-to-br from-[#0071e3] to-[#8b5cf6] flex items-center justify-center text-white text-xs font-semibold shadow-[0_6px_16px_-6px_rgba(0,113,227,0.6)]">
            {{ authStore.displayName?.charAt(0)?.toUpperCase() }}
          </span>
          <span class="hidden sm:block text-[13px] text-[#1d1d1f]">{{ authStore.displayName }}</span>
          <svg class="w-3.5 h-3.5 text-[#86868b] transition-transform duration-300" :class="{ 'rotate-180': userMenuOpen }"
            fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
          </svg>
        </button>

        <Transition name="page">
          <div
            v-if="userMenuOpen"
            class="absolute right-0 mt-2 w-56 overflow-hidden rounded-2xl border border-black/[0.07] bg-white/90 backdrop-blur-2xl shadow-[0_24px_60px_-24px_rgba(0,0,0,0.28)] z-50"
          >
            <div class="px-4 py-3 border-b border-black/[0.05]">
              <div class="text-[13px] text-[#1d1d1f] font-medium">{{ authStore.user?.display_name || authStore.user?.username }}</div>
              <div class="text-[11px] text-[#86868b] font-mono mt-0.5">{{ authStore.user?.username }}</div>
            </div>
            <button
              @click="handleLogout"
              class="w-full text-left px-4 py-2.5 text-[13px] text-[#6e6e73] hover:bg-black/[0.04] hover:text-[#1d1d1f] transition-colors"
            >
              退出登录
            </button>
          </div>
        </Transition>
      </div>
    </div>
  </header>
</template>
