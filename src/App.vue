<template>
  <el-config-provider :locale="locale" :message="config">
    <router-view></router-view>
  </el-config-provider>
</template>

<script setup>
import { reactive, onMounted } from "vue";
import { useThemeStore } from '@/stores/useThemeStore'
import zhCn from 'element-plus/dist/locale/zh-cn.mjs'

const locale = zhCn;
const config = reactive({
  max: 1,
});

const themeStore = useThemeStore()

// 初始化主题
onMounted(() => {
  themeStore.initTheme()
})
</script>

<style scoped>
</style>
