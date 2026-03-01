<template>
  <div class="friend-container">
    <el-tabs v-model="activeTab" class="friend-tabs">
      <el-tab-pane label="我的好友" name="myFriends">
        <MyFriends />
      </el-tab-pane>
      <el-tab-pane label="搜寻好友" name="searchFriends">
        <SearchFriends />
      </el-tab-pane>
    </el-tabs>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import MyFriends from '@/views/friend/MyFriends.vue'
import SearchFriends from '@/views/friend/SearchFriends.vue'

const activeTab = ref('searchFriends')
</script>

<style lang="scss" scoped>
.friend-container {
  padding: 20px;
  height: calc(100vh - 56px);
  overflow-y: auto;
  background-color: var(--bg-primary);

  .friend-tabs {
    :deep(.el-tabs__header) {
      margin-bottom: 20px;
    }
  }
}
</style>
