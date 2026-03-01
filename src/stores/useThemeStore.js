import { defineStore } from 'pinia'
import { ref, watch } from 'vue'

export const useThemeStore = defineStore('theme', () => {
  // 主题模式：'light' 或 'dark'
  const isDark = ref(false)
  
  // 初始化主题
  const initTheme = () => {
    // 从localStorage读取保存的主题设置
    const savedTheme = localStorage.getItem('theme-mode')
    
    if (savedTheme) {
      isDark.value = savedTheme === 'dark'
    } else {
      // 默认为白天模式（light）
      isDark.value = false
    }
    
    applyTheme()
  }
  
  // 应用主题
  const applyTheme = () => {
    const html = document.documentElement
    
    if (isDark.value) {
      html.classList.add('dark-mode')
      html.style.colorScheme = 'dark'
      localStorage.setItem('theme-mode', 'dark')
    } else {
      html.classList.remove('dark-mode')
      html.style.colorScheme = 'light'
      localStorage.setItem('theme-mode', 'light')
    }
  }
  
  // 切换主题
  const toggleTheme = () => {
    isDark.value = !isDark.value
    applyTheme()
  }
  
  // 设置特定主题
  const setTheme = (theme) => {
    isDark.value = theme === 'dark'
    applyTheme()
  }
  
  return {
    isDark,
    initTheme,
    toggleTheme,
    setTheme,
    applyTheme
  }
})
