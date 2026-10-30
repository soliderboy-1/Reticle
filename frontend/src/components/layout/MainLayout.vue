<script setup lang="ts">
import { RouterView } from 'vue-router'
import Sidebar from './Sidebar.vue'
import Header from './Header.vue'
</script>

<template>
  <div class="relative flex h-screen overflow-hidden">
    <!-- Ambient light mesh -->
    <div class="mesh-bg">
      <div class="mesh-blob mesh-1" />
      <div class="mesh-blob mesh-2" />
      <div class="mesh-blob mesh-3" />
    </div>

    <Sidebar />
    <div class="relative z-10 flex-1 flex flex-col overflow-hidden">
      <Header />
      <main class="flex-1 overflow-y-auto">
        <RouterView v-slot="{ Component }">
          <Transition name="page" mode="out-in">
            <component :is="Component" />
          </Transition>
        </RouterView>
      </main>
    </div>
  </div>
</template>
