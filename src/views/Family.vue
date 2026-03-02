<template>
  <div class="family-container">
    <el-tabs v-model="activeTab" class="family-tabs">
      <el-tab-pane label="家庭管理" name="familyManage">
        <FamilyManage />
      </el-tab-pane>
    </el-tabs>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import FamilyManage from '@/views/family/FamilyManage.vue'

const activeTab = ref('familyManage')
</script>

<style lang="scss" scoped>
.family-container {
  padding: 20px;
  height: calc(100vh - 56px);
  overflow-y: auto;
  background-color: var(--bg-primary);

  .family-tabs {
    :deep(.el-tabs__header) {
      margin-bottom: 20px;
    }
  }
}
</style>
