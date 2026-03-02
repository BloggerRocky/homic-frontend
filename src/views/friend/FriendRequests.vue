<template>
  <div class="friend-requests">
    <el-tabs v-model="activeRequestTab" class="request-tabs">
      <el-tab-pane label="我发出的" name="sent">
        <div class="request-list">
          <div v-if="sentRequests.length === 0" class="empty-state">
            <el-empty description="暂无发出的好友申请" />
          </div>
          <div v-else class="request-items">
            <div 
              v-for="request in sentRequests" 
              :key="request.id"
              class="request-item"
            >
              <div class="user-info-section">
                <img 
                  :src="`${proxy.globalInfo.avatarUrl}${request.receiverId}?${timestamp}`" 
                  :alt="request.receiverNickName" 
                  class="user-avatar" 
                />
                <div class="user-details">
                  <div class="user-nickname">{{ request.receiverNickName }}</div>
                  <div class="user-id">ID: {{ request.receiverId }}</div>
                  <div class="request-time">申请时间: {{ formatTime(request.createTime) }}</div>
                </div>
              </div>
              <div class="status-section">
                <el-tag 
                  :type="getStatusType(request.status)"
                  size="large"
                >
                  {{ getStatusText(request.status) }}
                </el-tag>
              </div>
            </div>
          </div>
        </div>
      </el-tab-pane>
      
      <el-tab-pane label="我收到的" name="received">
        <div class="request-list">
          <div v-if="receivedRequests.length === 0" class="empty-state">
            <el-empty description="暂无收到的好友申请" />
          </div>
          <div v-else class="request-items">
            <div 
              v-for="request in receivedRequests" 
              :key="request.id"
              class="request-item"
            >
              <div class="user-info-section">
                <img 
                  :src="`${proxy.globalInfo.avatarUrl}${request.senderId}?${timestamp}`" 
                  :alt="request.senderNickName" 
                  class="user-avatar" 
                />
                <div class="user-details">
                  <div class="user-nickname">{{ request.senderNickName }}</div>
                  <div class="user-id">ID: {{ request.senderId }}</div>
                  <div class="request-time">申请时间: {{ formatTime(request.createTime) }}</div>
                </div>
              </div>
              <div class="action-section">
                <template v-if="request.status === 0">
                  <button 
                    class="action-btn btn-accept"
                    @click="handleRequest(request.id, 1)"
                    :disabled="processing"
                  >
                    接受
                  </button>
                  <button 
                    class="action-btn btn-reject"
                    @click="handleRequest(request.id, 2)"
                    :disabled="processing"
                  >
                    拒绝
                  </button>
                </template>
                <el-tag 
                  v-else
                  :type="getStatusType(request.status)"
                  size="large"
                >
                  {{ getStatusText(request.status) }}
                </el-tag>
              </div>
            </div>
          </div>
        </div>
      </el-tab-pane>
    </el-tabs>
  </div>
</template>

<script setup>
import { ref, getCurrentInstance, onMounted, watch } from 'vue'
import { ElMessage } from 'element-plus'

const { proxy } = getCurrentInstance()

const api = {
  getSentRequests: '/friend/getSentRequests',
  getReceivedRequests: '/friend/getReceivedRequests',
  handleFriendRequest: '/friend/handleFriendRequest',
}

const activeRequestTab = ref('sent')
const sentRequests = ref([])
const receivedRequests = ref([])
const processing = ref(false)
const timestamp = ref(Date.now())

// 获取我发出的申请
const getSentRequests = async () => {
  try {
    const result = await proxy.Request({
      url: api.getSentRequests,
      showLoading: false,
    })
    if (result && result.data) {
      sentRequests.value = result.data
    }
  } catch (error) {
    console.error('获取发出的申请失败:', error)
  }
}

// 获取我收到的申请
const getReceivedRequests = async () => {
  try {
    const result = await proxy.Request({
      url: api.getReceivedRequests,
      showLoading: false,
    })
    if (result && result.data) {
      receivedRequests.value = result.data
    }
  } catch (error) {
    console.error('获取收到的申请失败:', error)
  }
}

// 处理好友申请
const handleRequest = async (requestId, action) => {
  processing.value = true
  try {
    const result = await proxy.Request({
      url: api.handleFriendRequest,
      params: {
        requestId,
        action, // 1-接受, 2-拒绝
      }
    })
    if (result) {
      ElMessage.success(action === 1 ? '已接受好友申请' : '已拒绝好友申请')
      await getReceivedRequests()
    }
  } catch (error) {
    console.error('处理好友申请失败:', error)
  } finally {
    processing.value = false
  }
}

// 格式化时间
const formatTime = (timeStr) => {
  if (!timeStr) return ''
  const date = new Date(timeStr)
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  const hours = String(date.getHours()).padStart(2, '0')
  const minutes = String(date.getMinutes()).padStart(2, '0')
  return `${year}-${month}-${day} ${hours}:${minutes}`
}

// 获取状态文本
const getStatusText = (status) => {
  const statusMap = {
    0: '待处理',
    1: '已接受',
    2: '已拒绝',
  }
  return statusMap[status] || '未知'
}

// 获取状态类型
const getStatusType = (status) => {
  const typeMap = {
    0: 'warning',
    1: 'success',
    2: 'danger',
  }
  return typeMap[status] || 'info'
}

// 监听标签切换
watch(activeRequestTab, (newTab) => {
  if (newTab === 'sent') {
    getSentRequests()
  } else {
    getReceivedRequests()
  }
})

// 页面加载时获取数据
onMounted(() => {
  getSentRequests()
})
</script>

<style lang="scss" scoped>
.friend-requests {
  height: calc(100vh - 56px);
  overflow-y: auto;
  background-color: var(--bg-primary);

  .request-tabs {
    padding: 20px;
    
    :deep(.el-tabs__header) {
      margin-bottom: 20px;
    }
  }

  .request-list {
    .empty-state {
      padding: 60px 20px;
      text-align: center;
    }

    .request-items {
      display: flex;
      flex-direction: column;
      gap: 15px;

      .request-item {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 20px;
        background-color: var(--component-bg);
        border-radius: 8px;
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
        transition: all 0.3s ease;

        &:hover {
          box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
          transform: translateY(-2px);
        }

        .user-info-section {
          display: flex;
          align-items: center;
          gap: 15px;
          flex: 1;

          .user-avatar {
            width: 60px;
            height: 60px;
            border-radius: 50%;
            object-fit: cover;
            border: 2px solid var(--border-color);
          }

          .user-details {
            display: flex;
            flex-direction: column;
            gap: 5px;

            .user-nickname {
              font-size: 16px;
              font-weight: 600;
              color: var(--text-primary);
            }

            .user-id {
              font-size: 13px;
              color: var(--text-tertiary);
            }

            .request-time {
              font-size: 12px;
              color: var(--text-tertiary);
            }
          }
        }

        .status-section {
          display: flex;
          align-items: center;
        }

        .action-section {
          display: flex;
          gap: 10px;
          align-items: center;

          .action-btn {
            min-width: 80px;
            padding: 8px 16px;
            border: none;
            border-radius: 4px;
            font-size: 14px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.3s ease;

            &:disabled {
              opacity: 0.6;
              cursor: not-allowed;
            }

            &.btn-accept {
              background-color: #67c23a;
              color: white;

              &:hover:not(:disabled) {
                background-color: #85ce61;
              }

              &:active:not(:disabled) {
                background-color: #5daf34;
              }
            }

            &.btn-reject {
              background-color: #f56c6c;
              color: white;

              &:hover:not(:disabled) {
                background-color: #f78989;
              }

              &:active:not(:disabled) {
                background-color: #dd001b;
              }
            }
          }
        }
      }
    }
  }
}
</style>
