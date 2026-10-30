<script setup lang="ts">
import { computed, ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuditStore } from '@/stores/audit'
import { llmApi } from '@/api'
import type { LlmStatusResponse } from '@/types'
import NewTaskDialog from '@/components/dashboard/NewTaskDialog.vue'

const router = useRouter()
const auditStore = useAuditStore()

const showNewTaskDialog = ref(false)
const llmStatus = ref<LlmStatusResponse | null>(null)
const llmStatusLoading = ref(false)
const heroTilt = ref({ x: 0, y: 0 })

onMounted(() => {
  auditStore.fetchTasks()
  fetchLlmStatus()
})

async function fetchLlmStatus(probe = false) {
  llmStatusLoading.value = true
  try {
    const { data } = await llmApi.status(probe)
    llmStatus.value = data
  } catch {
    llmStatus.value = {
      configured: false,
      provider: 'unknown',
      model: '',
      base_url: '',
      api_key_configured: false,
      missing: ['LLM_STATUS_API'],
      temperature: 0,
      timeout_seconds: 0,
      reachable: false,
      message: '无法获取 LLM 接入状态',
    }
  } finally {
    llmStatusLoading.value = false
  }
}

function openTask(taskId: string) {
  router.push(`/audit/${taskId}`)
}

function formatDate(d?: string) {
  if (!d) return '--'
  return new Date(d).toLocaleString('zh-CN', { month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' })
}

function onHeroMove(e: MouseEvent) {
  const el = e.currentTarget as HTMLElement
  const r = el.getBoundingClientRect()
  heroTilt.value = {
    x: (e.clientX - r.left) / r.width - 0.5,
    y: (e.clientY - r.top) / r.height - 0.5,
  }
}

function resetTilt() {
  heroTilt.value = { x: 0, y: 0 }
}

const statusLabels: Record<string, string> = {
  created: '已创建',
  queued: '排队中',
  running: '检测中',
  cancelling: '取消中',
  succeeded: '已完成',
  failed: '失败',
  cancelled: '已取消',
  interrupted: '已中断',
}

const totalTasks = computed(() => auditStore.tasks.length)
const succeededCount = computed(() => auditStore.statusCounts?.succeeded ?? 0)
const activeCount = computed(() => (auditStore.statusCounts?.running ?? 0) + (auditStore.statusCounts?.queued ?? 0))
const failedCount = computed(() => (auditStore.statusCounts?.failed ?? 0) + (auditStore.statusCounts?.interrupted ?? 0))

const kpis = computed(() => [
  { label: '累计审计任务', value: totalTasks.value, hint: '全部提交', icon: 'M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z', color: '#0071e3', tint: 'rgba(0,113,227,0.10)' },
  { label: '已完成审计', value: succeededCount.value, hint: '报告已生成', icon: 'M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z', color: '#1d8a4e', tint: 'rgba(29,138,78,0.10)' },
  { label: '进行中任务', value: activeCount.value, hint: '排队 / 运行', icon: 'M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z', color: '#b25000', tint: 'rgba(178,80,0,0.10)' },
  { label: '异常任务', value: failedCount.value, hint: '失败 / 中断', icon: 'M12 9v4m0 4h.01M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z', color: '#d70015', tint: 'rgba(215,0,21,0.09)' },
])

const pipeline = [
  { title: '合约预处理', desc: 'Solidity 解析 · 特征抽取 · 字节码编译' },
  { title: '多模型检测', desc: 'LSTM · DeepSVDD · GCN · 静态规则' },
  { title: '证据汇聚评分', desc: '证据中心统一归集 · 七维风险加权' },
  { title: 'LLM 推理定位', desc: 'RAG 检索 · 成因推理 · 行级定位' },
  { title: '验证与报告', desc: 'Slither 校验 · JSON / Markdown 产物' },
]

const capabilities = [
  { title: '漏洞检测智能体', desc: '跨合约风险检测与梯度粗定位', color: '#0071e3', tint: 'rgba(0,113,227,0.10)', icon: 'M9 12.75L11.25 15 15 9.75m-3-7.036A11.959 11.959 0 013.598 6 11.99 11.99 0 003 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285z' },
  { title: '推理定位智能体', desc: '漏洞成因推理与代码精确定位', color: '#7d4bd1', tint: 'rgba(125,75,209,0.10)', icon: 'M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z' },
  { title: '结果验证智能体', desc: '代码上下文校验与风险分级', color: '#b25000', tint: 'rgba(178,80,0,0.09)', icon: 'M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z' },
  { title: '报告与修复智能体', desc: '结构化审计报告与多版本代码修复', color: '#1d8a4e', tint: 'rgba(29,138,78,0.10)', icon: 'M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z' },
]

const progressWidth = computed(() => {
  if (!totalTasks.value) return 8
  return Math.max(8, Math.round((succeededCount.value / totalTasks.value) * 100))
})
</script>

<template>
  <div class="relative mx-auto max-w-[1180px] px-8 pb-16">
    <!-- ================= Hero ================= -->
    <section class="pt-14 pb-10 text-center" @mousemove="onHeroMove" @mouseleave="resetTilt">
      <div v-reveal class="flex justify-center mb-6">
        <span class="eyebrow">
          <span class="w-1.5 h-1.5 rounded-full bg-[#0071e3]" />
          Multi-Agent Security Platform
        </span>
      </div>

      <h1 v-reveal="60" class="display text-[52px] md:text-[64px] mb-6">
        安全审计，<br />
        <span class="gradient-text">从此清晰可见。</span>
      </h1>

      <p v-reveal="120" class="mx-auto max-w-[620px] text-[19px] leading-relaxed text-[#6e6e73] mb-9">
        多模型联合推理与多智能体协同，把复杂的 Solidity 审计
        变成一条可追踪、可解释、可修复的清晰路径。
      </p>

      <div v-reveal="180" class="flex flex-wrap items-center justify-center gap-3 mb-4">
        <button class="btn-primary" @click="showNewTaskDialog = true">
          新建检测任务
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7l5 5m0 0l-5 5m5-5H6" />
          </svg>
        </button>
        <button class="btn-secondary" @click="router.push('/tasks')">查看历史任务</button>
      </div>

      <div v-reveal="240" class="flex items-center justify-center gap-2 text-[12px] text-[#86868b]">
        <span
          class="w-1.5 h-1.5 rounded-full"
          :class="llmStatusLoading ? 'bg-[#ff9f0a] animate-pulse' : llmStatus?.configured && llmStatus.reachable !== false ? 'bg-[#34c759]' : 'bg-[#ff3b30]'"
        />
        {{ llmStatusLoading ? '正在检测 LLM 连接…' : llmStatus?.configured ? `LLM 已接入 · ${llmStatus.model || llmStatus.provider}` : 'LLM 未配置' }}
        <span class="text-[#d2d2d7]">|</span>
        <button class="hover:text-[#0071e3] transition-colors" @click="fetchLlmStatus(true)">重新检测</button>
      </div>

      <!-- Floating glass product preview -->
      <div v-reveal="300" class="relative mt-14 flex justify-center">
        <div class="absolute -top-16 w-[520px] h-[300px] rounded-full bg-[radial-gradient(closest-side,rgba(0,113,227,0.18),rgba(175,82,222,0.10),transparent)] blur-2xl" />
        <div
          class="glass-card float-slow relative w-full max-w-[560px] p-6 text-left transition-transform duration-300 ease-out"
          :style="{ transform: `perspective(1200px) rotateX(${-heroTilt.y * 4}deg) rotateY(${heroTilt.x * 5}deg) translate3d(${heroTilt.x * 12}px, ${heroTilt.y * 10}px, 0)` }"
        >
          <div class="flex items-center justify-between mb-5">
            <div class="flex items-center gap-2">
              <span class="pulse-dot" />
              <span class="text-[12px] text-[#6e6e73]">实时审计概览</span>
            </div>
            <span class="text-[10px] tracking-[0.14em] text-[#0071e3] bg-[#0071e3]/[0.08] px-2 py-0.5 rounded-full">LIVE</span>
          </div>

          <div class="grid grid-cols-3 gap-3">
            <div class="rounded-2xl bg-[#f5f5f7] px-3 py-3">
              <div class="text-[26px] font-semibold tracking-tight text-[#1d1d1f]">{{ totalTasks }}</div>
              <div class="text-[10.5px] text-[#86868b] mt-0.5">累计任务</div>
            </div>
            <div class="rounded-2xl bg-[#f5f5f7] px-3 py-3">
              <div class="text-[26px] font-semibold tracking-tight text-[#1d8a4e]">{{ succeededCount }}</div>
              <div class="text-[10.5px] text-[#86868b] mt-0.5">已完成</div>
            </div>
            <div class="rounded-2xl bg-[#f5f5f7] px-3 py-3">
              <div class="text-[26px] font-semibold tracking-tight text-[#b25000]">{{ activeCount }}</div>
              <div class="text-[10.5px] text-[#86868b] mt-0.5">进行中</div>
            </div>
          </div>

          <div class="mt-5">
            <div class="flex items-center justify-between text-[11px] mb-2">
              <span class="text-[#6e6e73]">审计完成度</span>
              <span class="text-[#1d1d1f] font-medium">{{ progressWidth }}%</span>
            </div>
            <div class="h-1.5 rounded-full bg-black/[0.06] overflow-hidden">
              <div class="h-full rounded-full bg-gradient-to-r from-[#0071e3] to-[#af52de] transition-all duration-700" :style="{ width: `${progressWidth}%` }" />
            </div>
          </div>

          <div class="mt-5 flex items-center justify-between">
            <div class="flex -space-x-1.5">
              <span v-for="n in 4" :key="n" class="w-6 h-6 rounded-full border-2 border-white bg-gradient-to-br from-[#e8e8ed] to-[#d2d2d7]" />
            </div>
            <span class="text-[11px] text-[#86868b]">4 个智能体协同工作中</span>
          </div>
        </div>
      </div>
    </section>

    <!-- ================= KPI ================= -->
    <section class="grid grid-cols-2 xl:grid-cols-4 gap-4 mb-16">
      <div
        v-for="(kpi, i) in kpis"
        :key="kpi.label"
        v-reveal="i * 80"
        class="card card-lift p-6"
      >
        <div class="w-10 h-10 rounded-2xl flex items-center justify-center mb-5" :style="{ background: kpi.tint }">
          <svg class="w-5 h-5" :style="{ color: kpi.color }" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.7">
            <path stroke-linecap="round" stroke-linejoin="round" :d="kpi.icon" />
          </svg>
        </div>
        <div class="flex items-baseline gap-1.5">
          <span class="text-[38px] leading-none font-semibold tracking-tight text-[#1d1d1f]">{{ kpi.value }}</span>
          <span class="text-[12px] text-[#86868b]">项</span>
        </div>
        <div class="mt-2 text-[13px] text-[#1d1d1f]">{{ kpi.label }}</div>
        <div class="text-[11px] text-[#86868b] mt-0.5">{{ kpi.hint }}</div>
      </div>
    </section>

    <!-- ================= Tasks + Pipeline ================= -->
    <section class="grid grid-cols-1 xl:grid-cols-3 gap-5 mb-16">
      <div v-reveal class="xl:col-span-2 card p-7">
        <div class="flex items-end justify-between mb-6">
          <div>
            <h2 class="text-[24px] font-semibold tracking-tight text-[#1d1d1f]">最近任务</h2>
            <p class="text-[13px] text-[#86868b] mt-1">按创建时间倒序，展示最近 5 条审计记录</p>
          </div>
          <button class="text-[13px] text-[#0071e3] hover:underline flex items-center gap-1" @click="router.push('/tasks')">
            全部任务
            <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
            </svg>
          </button>
        </div>

        <div v-if="auditStore.loading" class="py-16 text-center">
          <div class="w-8 h-8 mx-auto mb-3 rounded-full border-2 border-[#0071e3]/20 border-t-[#0071e3] animate-spin" />
          <div class="text-[12px] text-[#86868b]">正在同步任务…</div>
        </div>

        <div v-else-if="!auditStore.tasks.length" class="py-16 text-center rounded-3xl bg-[#f5f5f7]">
          <div class="w-14 h-14 mx-auto mb-4 rounded-3xl bg-white flex items-center justify-center shadow-sm">
            <svg class="w-7 h-7 text-[#0071e3]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
          </div>
          <p class="text-[14px] text-[#6e6e73] mb-5">还没有审计记录</p>
          <button class="btn-primary" @click="showNewTaskDialog = true">创建第一个任务</button>
        </div>

        <div v-else class="space-y-1">
          <div
            v-for="task in auditStore.tasks.slice(0, 5)"
            :key="task.task_id"
            class="group flex items-center gap-4 px-4 py-4 rounded-2xl hover:bg-[#f5f5f7] transition-colors cursor-pointer"
            @click="openTask(task.task_id)"
          >
            <span class="w-2 h-2 rounded-full shrink-0"
              :class="{
                'bg-[#34c759]': task.status === 'succeeded',
                'bg-[#ff3b30]': task.status === 'failed',
                'bg-[#0071e3] animate-pulse': task.status === 'running',
                'bg-[#ff9f0a]': task.status === 'queued',
                'bg-[#c7c7cc]': !['succeeded', 'failed', 'running', 'queued'].includes(task.status),
              }"
            />
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2">
                <span class="text-[14px] font-medium text-[#1d1d1f] truncate">{{ task.contract_name || '未命名任务' }}</span>
                <span class="text-[10px] text-[#86868b] px-1.5 py-0.5 rounded-full bg-black/[0.04]">{{ statusLabels[task.status] || task.status }}</span>
              </div>
              <div class="text-[11px] text-[#86868b] font-mono mt-0.5 truncate">{{ task.task_id }}</div>
            </div>
            <div class="hidden sm:block w-28 shrink-0">
              <div v-if="task.status === 'running'" class="h-1 rounded-full bg-black/[0.06] overflow-hidden">
                <div class="h-full rounded-full bg-[#0071e3]" :style="{ width: `${task.progress}%` }" />
              </div>
              <div v-else class="text-[11px] text-[#86868b] text-right">{{ formatDate(task.created_at) }}</div>
            </div>
            <svg class="w-4 h-4 text-[#c7c7cc] group-hover:text-[#0071e3] group-hover:translate-x-0.5 transition-all" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
            </svg>
          </div>
        </div>
      </div>

      <div v-reveal="120" class="card p-7">
        <h2 class="text-[24px] font-semibold tracking-tight text-[#1d1d1f]">检测流程</h2>
        <p class="text-[13px] text-[#86868b] mt-1 mb-6">五阶段流水线，证据逐层收敛</p>
        <div class="relative">
          <div class="absolute left-[15px] top-3 bottom-3 w-px bg-black/[0.08]" />
          <div v-for="(step, i) in pipeline" :key="step.title" class="relative flex gap-4 pb-6 last:pb-0">
            <div class="relative z-10 w-8 h-8 shrink-0 rounded-full bg-white border border-black/[0.08] shadow-sm flex items-center justify-center text-[11px] font-semibold text-[#1d1d1f]">
              {{ i + 1 }}
            </div>
            <div class="pt-1">
              <div class="text-[13.5px] font-medium text-[#1d1d1f]">{{ step.title }}</div>
              <div class="text-[11.5px] text-[#86868b] mt-0.5 leading-relaxed">{{ step.desc }}</div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- ================= Capabilities ================= -->
    <section v-reveal class="mb-4">
      <div class="text-center mb-8">
        <h2 class="text-[34px] font-semibold tracking-tight text-[#1d1d1f]">四个智能体，一条完整链路。</h2>
        <p class="text-[15px] text-[#6e6e73] mt-2">检测、推理、验证、报告与修复，各司其职又彼此校准。</p>
      </div>
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div v-for="cap in capabilities" :key="cap.title" class="tile p-6">
          <div class="w-11 h-11 rounded-2xl flex items-center justify-center mb-4" :style="{ background: cap.tint }">
            <svg class="w-5 h-5" :style="{ color: cap.color }" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.7">
              <path stroke-linecap="round" stroke-linejoin="round" :d="cap.icon" />
            </svg>
          </div>
          <div class="text-[14px] font-medium text-[#1d1d1f] mb-1.5">{{ cap.title }}</div>
          <div class="text-[12px] leading-relaxed text-[#6e6e73]">{{ cap.desc }}</div>
        </div>
      </div>
    </section>

    <!-- Footer -->
    <footer class="pt-10 text-center">
      <div class="flex items-center justify-center gap-5 text-[12px] text-[#86868b] mb-2">
        <a href="#" class="hover:text-[#1d1d1f] transition-colors">使用文档</a>
        <a href="#" class="hover:text-[#1d1d1f] transition-colors">知识库更新日志</a>
        <a href="#" class="hover:text-[#1d1d1f] transition-colors">模型版本 v1.2.0</a>
      </div>
      <p class="text-[11px] text-[#aeaeb2]">© 2026 Reticle Security Platform · 检索增强与多智能体协同架构</p>
    </footer>

    <NewTaskDialog
      v-if="showNewTaskDialog"
      @close="showNewTaskDialog = false"
      @created="(taskId) => { showNewTaskDialog = false; openTask(taskId) }"
    />
  </div>
</template>
