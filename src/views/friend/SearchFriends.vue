<template>
  <div class="search-friends">
    <div class="content-wrapper">
      <!-- 未生成好友码状态 -->
      <div v-if="!friendCode" class="no-code-state">
        <img src="@/assets/friend_code_ungenerated.png" alt="未生成好友码" class="ungenerated-image" />
        <div class="icon">
          <span class="iconfont icon-add"></span>
        </div>
        <p class="title">还未生成好友码</p>
        <p class="description">生成好友码后，其他用户可以通过该码快速添加你为好友</p>
        <el-button 
          type="primary" 
          size="large"
          @click="generateFriendCode"
          :loading="generating"
        >
          生成好友码
        </el-button>
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
          <div class="code-display">
            <div class="code-text">{{ friendCode }}</div>
            <el-button 
              type="primary" 
              text
              @click="copyCode"
              class="copy-btn"
            >
              <span class="iconfont icon-copy"></span>
              复制
            </el-button>
          </div>
          <div class="code-footer">
            <p class="tip">分享此码给好友，他们可以快速添加你</p>
          </div>
        </div>

        <div class="action-buttons">
          <el-button 
            @click="regenerateFriendCode"
            :loading="generating"
          >
            重新生成
          </el-button>
        </div>
      </div>
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
}

// 状态
const friendCode = ref('')
const expiryTime = ref(60)
const generating = ref(false)

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
</script>

<style lang="scss" scoped>
.search-friends {
  padding: 20px;
  background-color: var(--bg-primary);

  .content-wrapper {
    max-width: 600px;
    margin: 0 auto;
  }

  // 未生成状态
  .no-code-state {
    text-align: center;
    padding: 40px 40px 60px;
    background-color: var(--component-bg);
    border-radius: 8px;
    border: 2px dashed var(--border-light);
    min-height: 500px;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;

    .ungenerated-image {
      width: 100%;
      max-width: 350px;
      height: 280px;
      object-fit: contain;
      margin-bottom: 30px;
    }

    .icon {
      font-size: 80px;
      color: #05a1f5;
      margin-bottom: 20px;
      
      .iconfont {
        display: inline-block;
      }
    }

    .title {
      font-size: 20px;
      font-weight: bold;
      color: var(--text-primary);
      margin-bottom: 10px;
    }

    .description {
      font-size: 14px;
      color: var(--text-secondary);
      margin-bottom: 30px;
      line-height: 1.6;
    }
  }

  // 已生成状态
  .code-state {
    .generated-image {
      width: 100%;
      max-width: 350px;
      height: 200px;
      object-fit: contain;
      margin-bottom: 30px;
    }

    .code-card {
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
          font-weight: 500;
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

          .iconfont {
            font-size: 16px;
          }
        }
      }

      .code-footer {
        .tip {
          font-size: 12px;
          color: var(--text-tertiary);
          margin: 0;
        }
      }
    }

    .action-buttons {
      display: flex;
      justify-content: center;
      gap: 10px;

      :deep(.el-button) {
        min-width: 150px;
      }
    }
  }
}

// 深色模式适配
:root.dark-mode {
  .search-friends {
    .no-code-state {
      border-color: var(--border-dark);
    }

    .code-state {
      .code-card {
        box-shadow: 0 2px 12px rgba(0, 0, 0, 0.3);
      }
    }
  }
}
</style>
