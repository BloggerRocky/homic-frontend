<template>
  <div class="family-container">
    <FamilyManage />
  </div>
</template>

<script setup>
import FamilyManage from '@/views/family/FamilyManage.vue'
</script>

<style lang="scss" scoped>
.family-container {
  height: calc(100vh - 56px);
  overflow-y: auto;
  background-color: var(--bg-primary);
}
</style>
