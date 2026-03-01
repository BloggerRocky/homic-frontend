<template>
  <div class="theme-toggle">
    <el-tooltip :content="isDark ? '切换为浅色模式' : '切换为深色模式'" placement="bottom">
      <el-button
        :icon="isDark ? Sunny : Moon"
        circle
        @click="toggleTheme"
        class="theme-btn"
      />
    </el-tooltip>
  </div>
</template>

<script setup>
import { useThemeStore } from '@/stores/useThemeStore'
import { Moon, Sunny } from '@element-plus/icons-vue'
import { storeToRefs } from 'pinia'

const themeStore = useThemeStore()
const { isDark } = storeToRefs(themeStore)

const toggleTheme = () => {
  themeStore.toggleTheme()
}
</script>

<style scoped>
.theme-toggle {
  display: flex;
  align-items: center;
  justify-content: center;
}

.theme-btn {
  background-color: var(--component-bg);
  border-color: var(--border-color);
  color: var(--text-primary);
  transition: all 0.3s ease;
}

.theme-btn:hover {
  background-color: var(--component-hover-bg);
  border-color: var(--text-secondary);
}

.theme-btn:active {
  background-color: var(--component-active-bg);
}
</style>
