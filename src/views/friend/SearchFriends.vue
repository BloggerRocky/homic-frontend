<template>
  <div class="search-friends">
    <div class="content-wrapper">
      <!-- 未生成好友码状态 -->
      <div v-if="!friendCode" class="no-code-state">
        <img src="@/assets/friend_code_ungenerated.png" alt="未生成好友码" class="ungenerated-image" />
        <div class="code-card">
          <p class="code-header">您暂未生成好友码</p>
          <p class="tip">生成一个好友码，与您的家人与朋友共享文件~</p>
          <div class="button-group">
            <button 
              class="custom-btn btn-generate"
              @click="generateFriendCode"
              :disabled="generating"
            >
              {{ generating ? '生成中...' : '生成好友码' }}
            </button>
            <button 
              class="custom-btn btn-search"
              @click="openSearchDialog"
            >
              搜寻好友
            </button>
          </div>
        </div>
      </div>

      <!-- 已生成好友码状态 -->
      <div v-else class="code-state">
        <img src="@/assets/friend_code_generated.png" alt="好友码已生成" class="generated-image" />
        <div class="code-card">
          <div class="code-header">
            <span class="label">你的好友码</span>
            <span class="expiry-time">
              <span class="iconfont icon-time"></span>
              {{ expiryTime }}秒后失效
            </span>
          </div>
          <div class="expiry-progress">
            <el-progress 
              :percentage="(expiryTime / 60) * 100" 
              color="#67c23a"
              :show-text="false"
            />
          </div>
          <div class="code-display">
            <div class="code-text">{{ friendCode }}</div>
            <button 
              class="copy-btn"
              @click="copyCode"
            >
              <span class="iconfont icon-copy"></span>
              复制
            </button>
          </div>
          <div class="code-footer">
            <p class="tip">好友码是添加好友的唯一凭证，请妥善保管</p>
          </div>
          <div class="action-buttons">
            <button 
              class="custom-btn btn-generate"
              @click="regenerateFriendCode"
              :disabled="generating"
            >
              {{ generating ? '生成中...' : '重新生成' }}
            </button>
            <button 
              class="custom-btn btn-search"
              @click="openSearchDialog"
            >
              搜寻好友
            </button>
          </div>
        </div>
      </div>

      <!-- 搜寻好友对话框 -->
      <el-dialog 
        v-model="searchDialogVisible" 
        title="搜寻好友"
        width="400px"
        @close="resetSearchDialog"
      >
        <div class="search-dialog-content">
          <el-input 
            v-model="searchFriendCode"
            placeholder="请输入对方的好友码"
            clearable
            @keyup.enter="searchFriend"
          />
        </div>
        <template #footer>
          <div class="search-dialog-footer">
            <button 
              class="custom-btn btn-search"
              @click="searchFriend"
              :disabled="searching"
            >
              {{ searching ? '搜寻中...' : '搜寻' }}
            </button>
            <button 
              class="custom-btn btn-cancel-white"
              @click="searchDialogVisible = false"
            >
              取消
            </button>
          </div>
        </template>
      </el-dialog>

      <!-- 搜寻结果对话框 -->
      <el-dialog 
        v-model="resultDialogVisible" 
        title="用户信息"
        width="400px"
        @close="cancelSearch"
      >
        <div v-if="searchResult" class="result-dialog-content">
          <div class="user-card">
            <div class="user-header">
              <img :src="`${proxy.globalInfo.avatarUrl}${searchResult.userId}?${timestamp}`" :alt="searchResult.nickName" class="user-avatar" />
              <div class="user-info">
                <div class="user-id">ID: {{ searchResult.userId }}</div>
                <div class="user-nickname">{{ searchResult.nickName }}</div>
              </div>
            </div>
          </div>
        </div>
        <template #footer>
          <button 
            :class="['custom-btn', getButtonClass()]"
            @click="handleFriendAction"
            :disabled="actionLoading"
          >
            {{ actionLoading ? '处理中...' : getButtonText() }}
          </button>
          <button 
            class="custom-btn btn-cancel-white"
            @click="cancelSearch"
          >
            取消
          </button>
        </template>
      </el-dialog>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, getCurrentInstance, onMounted, onUnmounted } from 'vue'
import { ElMessage } from 'element-plus'

const { proxy } = getCurrentInstance()

const api = {
  generateFriendCode: '/friend/generateFriendCode',
  getMyFriendCode: '/friend/getMyFriendCode',
  getUserByFriendCode: '/friend/getUserByFriendCode',
  sendFriendRequest: '/friend/sendFriendRequest',
  getFriendRequestStatus: '/friend/getFriendRequestStatus',
}

// 状态
const friendCode = ref('')
const expiryTime = ref(60)
const generating = ref(false)

// 搜寻好友相关状态
const searchDialogVisible = ref(false)
const resultDialogVisible = ref(false)
const searchFriendCode = ref('')
const searching = ref(false)
const searchResult = ref(null)
const actionLoading = ref(false)
const friendRequestStatus = ref(null) // 0-未申请, 1-已申请, 2-已接受, 3-已拒绝
const timestamp = ref(0)

// 计时器
let expiryTimer = null

// 生成好友码
const generateFriendCode = async () => {
  generating.value = true
  try {
    const result = await proxy.Request({
      url: api.generateFriendCode,
    })
    if (result) {
      friendCode.value = result.data.code
      expiryTime.value = result.data.expiryTime
      
      // 启动失效倒计时
      startExpiryCountdown()
    }
  } finally {
    generating.value = false
  }
}

// 重新生成好友码
const regenerateFriendCode = async () => {
  await generateFriendCode()
}

// 复制好友码
const copyCode = async () => {
  try {
    // 使用 Clipboard API
    if (navigator.clipboard && navigator.clipboard.writeText) {
      await navigator.clipboard.writeText(friendCode.value)
      ElMessage.success('好友码已复制到剪贴板')
    } else {
      // 降级方案：使用 execCommand
      const textarea = document.createElement('textarea')
      textarea.value = friendCode.value
      textarea.style.position = 'fixed'
      textarea.style.opacity = '0'
      document.body.appendChild(textarea)
      textarea.select()
      document.execCommand('copy')
      document.body.removeChild(textarea)
      ElMessage.success('好友码已复制到剪贴板')
    }
  } catch (error) {
    console.error('复制失败:', error)
    ElMessage.error('复制失败，请手动复制')
  }
}

// 启动失效倒计时
const startExpiryCountdown = () => {
  if (expiryTimer) clearInterval(expiryTimer)
  
  expiryTimer = setInterval(() => {
    expiryTime.value--
    if (expiryTime.value <= 0) {
      clearInterval(expiryTimer)
      friendCode.value = ''
      expiryTime.value = 60
    }
  }, 1000)
}

// 查询自身好友码
const getMyFriendCode = async () => {
  try {
    const result = await proxy.Request({
      url: api.getMyFriendCode,
      showLoading: false,
    })
    if (result && result.data) {
      friendCode.value = result.data.code
      expiryTime.value = result.data.expiryTime
      startExpiryCountdown()
    }
  } catch (error) {
    console.error('获取好友码失败:', error)
  }
}

// 页面挂载时查询好友码
onMounted(() => {
  getMyFriendCode()
})

// 页面卸载时清理计时器
onUnmounted(() => {
  if (expiryTimer) clearInterval(expiryTimer)
})

// 打开搜寻好友对话框
const openSearchDialog = () => {
  searchDialogVisible.value = true
  searchFriendCode.value = ''
  searchResult.value = null
  friendRequestStatus.value = null
}

// 重置搜寻对话框
const resetSearchDialog = () => {
  searchFriendCode.value = ''
}

// 搜寻好友
const searchFriend = async () => {
  if (!searchFriendCode.value.trim()) {
    ElMessage.warning('请输入好友码')
    return
  }

  searching.value = true
  try {
    const result = await proxy.Request({
      url: api.getUserByFriendCode,
      params: {
        friendCode: searchFriendCode.value.trim()
      }
    })
    
    if (result && result.data) {
      searchResult.value = result.data
      // 更新时间戳以刷新头像
      timestamp.value = new Date().getTime()
      // 查询申请状态
      await checkFriendRequestStatus(result.data.userId)
      searchDialogVisible.value = false
      resultDialogVisible.value = true
    }
  } catch (error) {
    console.error('搜寻好友失败:', error)
  } finally {
    searching.value = false
  }
}

// 查询好友申请状态
const checkFriendRequestStatus = async (targetUserId) => {
  try {
    const result = await proxy.Request({
      url: api.getFriendRequestStatus,
      params: {
        friendId: targetUserId
      },
      showLoading: false
    })
    
    if (result && result.data !== undefined) {
      friendRequestStatus.value = result.data
    } else {
      friendRequestStatus.value = 0 // 未申请
    }
  } catch (error) {
    console.error('查询申请状态失败:', error)
    friendRequestStatus.value = 0
  }
}

// 获取按钮类名
const getButtonClass = () => {
  if (friendRequestStatus.value === 0) return 'btn-generate'
  if (friendRequestStatus.value === 1) return 'btn-warning'
  if (friendRequestStatus.value === 2) return 'btn-success'
  if (friendRequestStatus.value === 3) return 'btn-generate' // 已拒绝改为绿色，可以再次申请
  return 'btn-generate'
}

// 获取按钮文本
const getButtonText = () => {
  if (friendRequestStatus.value === 0) return '申请好友'
  if (friendRequestStatus.value === 1) return '待通过'
  if (friendRequestStatus.value === 2) return '已是好友'
  if (friendRequestStatus.value === 3) return '再次申请'
  return '申请好友'
}

// 处理好友操作
const handleFriendAction = async () => {
  if (friendRequestStatus.value === 0 || friendRequestStatus.value === 3) {
    // 发送好友申请（未申请或已拒绝都可以申请）
    await sendFriendRequest()
  } else if (friendRequestStatus.value === 1) {
    ElMessage.info('申请已发送，请等待对方处理')
  } else if (friendRequestStatus.value === 2) {
    ElMessage.info('你们已经是好友了')
  }
}

// 发送好友申请
const sendFriendRequest = async () => {
  if (!searchResult.value) return
  
  actionLoading.value = true
  try {
    const result = await proxy.Request({
      url: api.sendFriendRequest,
      params: {
        friendId: searchResult.value.userId
      }
    })
    
    if (result) {
      ElMessage.success('好友申请已发送')
      friendRequestStatus.value = 1
    }
  } catch (error) {
    console.error('发送好友申请失败:', error)
  } finally {
    actionLoading.value = false
  }
}

// 取消搜寻
const cancelSearch = () => {
  searchResult.value = null
  friendRequestStatus.value = null
  resultDialogVisible.value = false
}
</script>

<style lang="scss" scoped>
.search-friends {
  height: calc(100vh - 56px);
  overflow-y: auto;
  background-color: var(--bg-primary);
  padding: 20px;

  .content-wrapper {
    max-width: 600px;
    margin: 0 auto;
  }

  // 自定义按钮样式
  .custom-btn {
    min-width: 150px;
    padding: 10px 20px;
    border: 3px solid #d3d3d3;
    border-radius: 4px;
    font-size: 14px;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.3s ease;
    white-space: nowrap;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);

    &:disabled {
      opacity: 0.6;
      cursor: not-allowed;
    }

    &.btn-generate {
      background-color: #67c23a;
      color: white;

      &:hover:not(:disabled) {
        background-color: #85ce61;
      }

      &:active:not(:disabled) {
        background-color: #5daf34;
      }
    }

    &.btn-search {
      background-color: #409eff;
      color: white;

      &:hover:not(:disabled) {
        background-color: #66b1ff;
      }

      &:active:not(:disabled) {
        background-color: #0a66d6;
      }
    }

    &.btn-cancel {
      background-color: #f56c6c;
      color: white;

      &:hover:not(:disabled) {
        background-color: #f78989;
      }

      &:active:not(:disabled) {
        background-color: #dd001b;
      }
    }

    &.btn-warning {
      background-color: #e6a23c;
      color: white;

      &:hover:not(:disabled) {
        background-color: #ebb563;
      }

      &:active:not(:disabled) {
        background-color: #cf8409;
      }
    }

    &.btn-success {
      background-color: #67c23a;
      color: white;

      &:hover:not(:disabled) {
        background-color: #85ce61;
      }

      &:active:not(:disabled) {
        background-color: #5daf34;
      }
    }

    &.btn-danger {
      background-color: #f56c6c;
      color: white;

      &:hover:not(:disabled) {
        background-color: #f78989;
      }

      &:active:not(:disabled) {
        background-color: #dd001b;
      }
    }

    &.btn-cancel-white {
      background-color: white;
      color: #333;
      border-color: #d3d3d3;

      &:hover:not(:disabled) {
        background-color: #f56c6c;
        color: white;
        border-color: #f56c6c;
      }

      &:active:not(:disabled) {
        background-color: #dd001b;
        border-color: #dd001b;
      }
    }
  }

  // 未生成状态
  .no-code-state {
    display: flex;
    flex-direction: column;
    align-items: center;

    .ungenerated-image {
      width: 100%;
      max-width: 350px;
      height: 280px;
      object-fit: contain;
      margin-bottom: 10px;
    }

    .code-card {
      width: 100%;
      text-align: center;
      background-color: var(--component-bg);
      border-radius: 8px;
      padding: 30px;
      box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);

      .code-header {
        font-size: 18px;
        font-weight: 600;
        color: var(--text-primary);
        margin-bottom: 10px;
      }

      .tip {
        font-size: 14px;
        color: var(--text-secondary);
        margin-bottom: 30px;
        line-height: 1.6;
      }

      .button-group {
        display: flex;
        gap: 10px;
        justify-content: center;
      }
    }
  }

  // 已生成状态
  .code-state {
    display: flex;
    flex-direction: column;
    align-items: center;

    .generated-image {
      width: 100%;
      max-width: 350px;
      height: 200px;
      object-fit: contain;
      margin-bottom: 30px;
    }

    .code-card {
      width: 100%;
      background-color: var(--component-bg);
      border-radius: 8px;
      padding: 30px;
      margin-bottom: 20px;
      box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);

      .code-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 20px;

        .label {
          font-size: 14px;
          color: var(--text-secondary);
          font-weight: 600;
          letter-spacing: 0.5px;
        }

        .expiry-time {
          display: flex;
          align-items: center;
          gap: 5px;
          font-size: 13px;
          color: #e6a23c;
          background-color: rgba(230, 162, 60, 0.1);
          padding: 4px 12px;
          border-radius: 4px;

          .iconfont {
            font-size: 12px;
          }
        }
      }

      .expiry-progress {
        margin-bottom: 15px;
        
        :deep(.el-progress__bar) {
          background-color: #67c23a !important;
        }
      }

      .code-display {
        display: flex;
        justify-content: space-between;
        align-items: center;
        background-color: var(--bg-secondary);
        padding: 20px;
        border-radius: 6px;
        margin-bottom: 20px;

        .code-text {
          font-size: 28px;
          font-weight: bold;
          color: #05a1f5;
          letter-spacing: 2px;
          font-family: 'Courier New', monospace;
        }

        .copy-btn {
          display: flex;
          align-items: center;
          gap: 5px;
          font-size: 14px;
          background: none;
          border: none;
          color: #409eff;
          cursor: pointer;
          transition: color 0.3s ease;

          &:hover {
            color: #66b1ff;
          }

          .iconfont {
            font-size: 16px;
          }
        }
      }

      .code-footer {
        margin-bottom: 20px;

        .tip {
          font-size: 13px;
          color: var(--text-tertiary);
          margin: 0;
          font-weight: 500;
          letter-spacing: 0.3px;
        }
      }

      .action-buttons {
        display: flex;
        justify-content: center;
        gap: 10px;
      }
    }
  }

  // 搜寻对话框
  .search-dialog-content {
    padding: 20px 0;
  }

  .search-dialog-footer {
    display: flex;
    justify-content: space-between;
    gap: 20px;
  }

  :deep(.el-dialog__footer) {
    display: flex;
    gap: 20px;
    justify-content: center;
  }

  // 结果对话框
  .result-dialog-content {
    padding: 20px 0;
    display: flex;
    justify-content: center;

    .user-card {
      width: 100%;
      max-width: 300px;

      .user-header {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 15px;

        .user-avatar {
          width: 60px;
          height: 60px;
          border-radius: 50%;
          object-fit: cover;
          border: 2px solid var(--border-color);
        }

        .user-info {
          flex: 1;
          text-align: center;

          .user-id {
            font-size: 12px;
            color: var(--text-tertiary);
            margin-bottom: 5px;
          }

          .user-nickname {
            font-size: 16px;
            font-weight: 600;
            color: var(--text-primary);
          }
        }
      }
    }
  }

  @keyframes slideIn {
    from {
      opacity: 0;
      transform: translateY(-10px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }
}
</style>
