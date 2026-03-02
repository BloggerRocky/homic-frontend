<template>
  <el-dialog
    v-model="dialogVisible"
    title="选择好友"
    width="600px"
    :close-on-click-modal="false"
    @close="handleClose"
  >
    <div class="friend-select-content">
      <!-- 搜索框 -->
      <div class="search-bar">
        <el-input
          v-model="searchKeyword"
          placeholder="搜索好友昵称或备注"
          clearable
          @input="filterFriends"
        >
          <template #prefix>
            <i class="iconfont icon-search"></i>
          </template>
        </el-input>
      </div>

      <!-- 好友列表 -->
      <div class="friend-list">
        <div v-if="filteredFriendList.length === 0" class="empty-state">
          <el-empty description="暂无好友" />
        </div>
        <div v-else class="friend-items">
          <div
            v-for="friend in filteredFriendList"
            :key="friend.friendId"
            :class="['friend-item', { 
              selected: isSelected(friend.friendId),
              special: friend.isSpecial === 1
            }]"
            @click="toggleSelect(friend)"
          >
            <el-checkbox
              :model-value="isSelected(friend.friendId)"
              @change="toggleSelect(friend)"
              @click.stop
            />
            <div class="friend-avatar">
              <img :src="getAvatarUrl(friend.friendId)" :alt="friend.nickName" />
            </div>
            <div class="friend-info">
              <div class="friend-name">
                {{ friend.remark || friend.nickName }}
                <span v-if="friend.remark" class="nick-name">({{ friend.nickName }})</span>
              </div>
            </div>
            <div v-if="friend.isSpecial === 1" class="special-badge">
              <i class="iconfont icon-like"></i>
            </div>
          </div>
        </div>
      </div>
    </div>

    <template #footer>
      <div class="dialog-footer">
        <div class="selected-count">
          已选择 <span class="count">{{ selectedFriends.length }}</span> 位好友
        </div>
        <div class="actions">
          <el-button type="primary" @click="confirmSelect" :disabled="selectedFriends.length === 0">
            确定
          </el-button>
          <el-button @click="dialogVisible = false">取消</el-button>
        </div>
      </div>
    </template>
  </el-dialog>
</template>

<script setup>
import { ref, getCurrentInstance } from 'vue'
import { ElMessage } from 'element-plus'

const { proxy } = getCurrentInstance()

const emit = defineEmits(['confirm'])

const api = {
  loadFriendList: '/friend/getMyFriends',
}

const dialogVisible = ref(false)
const searchKeyword = ref('')
const friendList = ref([])
const filteredFriendList = ref([])
const selectedFriends = ref([])

// 获取头像URL
const getAvatarUrl = (userId) => {
  return `/api/getAvatar/${userId}`
}

// 打开对话框
const show = async () => {
  dialogVisible.value = true
  selectedFriends.value = []
  searchKeyword.value = ''
  await loadFriendList()
}

// 加载好友列表
const loadFriendList = async () => {
  try {
    const result = await proxy.Request({
      url: api.loadFriendList,
      showLoading: false
    })
    
    if (result && Array.isArray(result.data)) {
      // 按照特别关注排序：关注的好友在前
      const sortedList = result.data.sort((a, b) => {
        // isSpecial: 1 表示特别关注，0 表示普通好友
        if (a.isSpecial === b.isSpecial) {
          // 如果关注状态相同，按昵称或备注排序
          const nameA = (a.remark || a.nickName).toLowerCase()
          const nameB = (b.remark || b.nickName).toLowerCase()
          return nameA.localeCompare(nameB, 'zh-CN')
        }
        // 特别关注的排在前面
        return b.isSpecial - a.isSpecial
      })
      
      friendList.value = sortedList
      filteredFriendList.value = sortedList
    } else {
      friendList.value = []
      filteredFriendList.value = []
    }
  } catch (error) {
    console.error('加载好友列表失败:', error)
    friendList.value = []
    filteredFriendList.value = []
  }
}

// 过滤好友
const filterFriends = () => {
  if (!searchKeyword.value) {
    filteredFriendList.value = friendList.value
    return
  }
  
  const keyword = searchKeyword.value.toLowerCase()
  const filtered = friendList.value.filter(friend => {
    const nickName = (friend.nickName || '').toLowerCase()
    const remark = (friend.remark || '').toLowerCase()
    return nickName.includes(keyword) || remark.includes(keyword)
  })
  
  // 过滤后也保持排序：特别关注在前
  filteredFriendList.value = filtered.sort((a, b) => {
    if (a.isSpecial === b.isSpecial) {
      const nameA = (a.remark || a.nickName).toLowerCase()
      const nameB = (b.remark || b.nickName).toLowerCase()
      return nameA.localeCompare(nameB, 'zh-CN')
    }
    return b.isSpecial - a.isSpecial
  })
}

// 判断是否已选择
const isSelected = (friendId) => {
  return selectedFriends.value.some(f => f.friendId === friendId)
}

// 切换选择
const toggleSelect = (friend) => {
  const index = selectedFriends.value.findIndex(f => f.friendId === friend.friendId)
  if (index > -1) {
    selectedFriends.value.splice(index, 1)
  } else {
    selectedFriends.value.push(friend)
  }
}

// 确认选择
const confirmSelect = () => {
  if (selectedFriends.value.length === 0) {
    ElMessage.warning('请选择好友')
    return
  }
  
  emit('confirm', selectedFriends.value)
  dialogVisible.value = false
}

// 关闭对话框
const handleClose = () => {
  selectedFriends.value = []
  friendList.value = []
  filteredFriendList.value = []
}

defineExpose({
  show
})
</script>

<style lang="scss" scoped>
.friend-select-content {
  .search-bar {
    margin-bottom: 15px;

    .el-input {
      width: 100%;
    }

    .iconfont {
      color: #909399;
    }
  }

  .friend-list {
    max-height: 400px;
    overflow-y: auto;
    border: 1px solid #e4e7ed;
    border-radius: 4px;
    padding: 10px;

    &::-webkit-scrollbar {
      width: 6px;
    }

    &::-webkit-scrollbar-thumb {
      background-color: rgba(0, 0, 0, 0.2);
      border-radius: 3px;
    }

    .empty-state {
      padding: 40px 0;
      text-align: center;
    }

    .friend-items {
      display: flex;
      flex-direction: column;
      gap: 8px;

      .friend-item {
        display: flex;
        align-items: center;
        gap: 12px;
        padding: 12px;
        border-radius: 6px;
        cursor: pointer;
        transition: all 0.3s ease;
        border: 2px solid transparent;
        background-color: white;

        &:hover {
          background-color: #f5f7fa;
        }

        &.selected {
          background-color: #e3f2fd;
          border-color: #409eff;
        }
        
        &.special {
          background-color: #fce4ec;
          
          &:hover {
            background-color: #f8bbd0;
          }
          
          &.selected {
            background-color: #f48fb1;
            border-color: #ec407a;
          }
        }

        .friend-avatar {
          flex-shrink: 0;
          width: 40px;
          height: 40px;
          border-radius: 50%;
          overflow: hidden;
          border: 2px solid #e4e7ed;

          img {
            width: 100%;
            height: 100%;
            object-fit: cover;
          }
        }

        .friend-info {
          flex: 1;
          min-width: 0;

          .friend-name {
            font-size: 14px;
            font-weight: 500;
            color: #333;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;

            .nick-name {
              font-size: 12px;
              font-weight: 400;
              color: #909399;
              margin-left: 4px;
            }
          }
        }
        
        .special-badge {
          flex-shrink: 0;
          width: 28px;
          height: 28px;
          background: linear-gradient(135deg, #ec407a 0%, #f06292 100%);
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          box-shadow: 0 2px 6px rgba(236, 64, 122, 0.4);
          
          .iconfont {
            font-size: 14px;
            color: white;
          }
        }
      }
    }
  }
}

.dialog-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;

  .selected-count {
    font-size: 14px;
    color: #606266;

    .count {
      font-weight: 600;
      color: #409eff;
      font-size: 16px;
    }
  }

  .actions {
    display: flex;
    gap: 10px;
  }
}
</style>
