<template>
  <el-dialog
    v-model="dialogVisible"
    :title="getDialogTitle()"
    width="975px"
    top="8vh"
    :close-on-click-modal="false"
    @close="handleClose"
  >
    <div class="share-dialog-content">
      <!-- 分享历史记录 - 聊天气泡样式 -->
      <div class="share-history" ref="shareHistoryRef">
        <div v-if="shareList.length === 0" class="empty-state">
          <el-empty description="暂无分享记录" />
        </div>
        <div v-else class="chat-list">
          <div
            v-for="share in shareList"
            :key="share.shareId"
            :class="['chat-message', share.isSender ? 'sent' : 'received']"
          >
            <!-- 头像 -->
            <div class="avatar">
              <img 
                :src="getAvatarUrl(share)" 
                :alt="share.isSender ? '我' : friendInfo.nickName"
              />
            </div>

            <!-- 消息气泡 -->
            <div class="message-bubble">
              <!-- 文件信息卡片 -->
              <div class="file-card">
                <div class="file-icon">
                  <Icon :fileType="share.fileType" :cover="share.fileCover" :width="48" />
                </div>
                <div class="file-info">
                  <div class="file-name" :title="share.fileName">{{ share.fileName }}</div>
                  <div class="file-meta">
                    <span class="file-size" v-if="share.fileSize">
                      {{ formatSize(share.fileSize) }}
                    </span>
                    <span :class="['status-badge', getStatusClass(share)]">
                      {{ getStatusText(share) }}
                    </span>
                  </div>
                </div>
              </div>

              <!-- 对方发送的消息：操作按钮在文件信息下方 -->
              <div class="action-buttons-horizontal" v-if="!share.isSender && share.status === 1">
                <button
                  v-if="share.folderType === 0"
                  class="custom-btn preview-btn"
                  @click="previewFile(share)"
                  title="预览"
                >
                  <img :src="previewIcon" alt="预览" class="btn-icon" />
                  <span>预览</span>
                </button>
                <button
                  class="custom-btn save-btn"
                  @click="openFolderSelector(share)"
                  title="保存"
                >
                  <img :src="saveIcon" alt="保存" class="btn-icon" />
                  <span>保存</span>
                </button>
                <button
                  v-if="share.folderType === 0"
                  class="custom-btn download-btn"
                  @click="downloadFile(share)"
                  title="下载"
                >
                  <img :src="downloadIcon" alt="下载" class="btn-icon" />
                  <span>下载</span>
                </button>
              </div>

              <!-- 我发送的消息：操作按钮在底部 -->
              <div class="action-buttons" v-if="share.isSender">
                <button
                  v-if="share.folderType === 0 && share.status === 1"
                  class="custom-btn preview-btn"
                  @click="previewFile(share)"
                  title="预览"
                >
                  <img :src="previewIcon" alt="预览" class="btn-icon" />
                  <span>预览</span>
                </button>
                <button
                  v-if="share.folderType === 0 && share.status === 1"
                  class="custom-btn download-btn"
                  @click="downloadFile(share)"
                  title="下载"
                >
                  <img :src="downloadIcon" alt="下载" class="btn-icon" />
                  <span>下载</span>
                </button>
                <button
                  v-if="share.status === 1"
                  class="custom-btn rollback-btn"
                  @click="cancelShare(share.shareId)"
                  title="撤回"
                >
                  <img :src="rollbackIcon" alt="撤回" class="btn-icon" />
                  <span>撤回</span>
                </button>
              </div>

              <!-- 时间戳 -->
              <div class="timestamp">{{ formatTime(share.shareTime) }}</div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <template #footer>
      <div class="dialog-footer">
        <el-button type="primary" @click="openFileSelector">
          <span class="iconfont icon-upload"></span>
          选择文件
        </el-button>
        <el-button @click="dialogVisible = false">关闭</el-button>
      </div>
    </template>

    <!-- 文件选择对话框 -->
    <FileSelectDialog
      ref="fileSelectDialogRef"
      @confirm="handleFileSelect"
    />

    <!-- 文件夹选择对话框 -->
    <FolderSelectDialog
      ref="folderSelectDialogRef"
      @folderSelect="handleFolderSelect"
    />
  </el-dialog>

  <!-- 预览组件 -->
  <Preview ref="previewRef" />
</template>

<script setup>
import { ref, getCurrentInstance } from 'vue'
import { ElMessage } from 'element-plus'
import Icon from '@/components/Icon.vue'
import FileSelectDialog from './FileSelectDialog.vue'
import FolderSelectDialog from '@/components/FolderSelect.vue'
import Preview from '@/components/preview/Preview.vue'

// 导入图标
import previewIcon from '@/assets/icon-image/friends/share/preview.png'
import saveIcon from '@/assets/icon-image/friends/share/save.png'
import downloadIcon from '@/assets/icon-image/friends/share/download.png'
import rollbackIcon from '@/assets/icon-image/friends/share/rollback.png'

const { proxy } = getCurrentInstance()

const api = {
  getShareHistory: '/friendShare/getHistory',
  shareFilesToFriend: '/friendShare/shareFiles',
  cancelFriendShare: '/friendShare/cancel',
  saveFriendSharedFile: '/friendShare/save',
  downloadFriendSharedFile: '/friendShare/getDownloadUrl',
}

const dialogVisible = ref(false)
const friendInfo = ref({})
const shareList = ref([])
const fileSelectDialogRef = ref(null)
const folderSelectDialogRef = ref(null)
const currentSaveShare = ref(null)
const previewRef = ref(null)
const shareHistoryRef = ref(null)

// 获取当前用户ID
const getCurrentUserId = () => {
  const userInfo = proxy.VueCookies.get("userInfo")
  return userInfo ? userInfo.userId : null
}

// 获取头像URL - 直接使用用户ID
const getAvatarUrl = (share) => {
  // 如果是我发送的，使用当前用户ID；否则使用好友ID
  const userId = share.isSender ? getCurrentUserId() : friendInfo.value.friendId
  return `/api/getAvatar/${userId}`
}

// 获取对话框标题
const getDialogTitle = () => {
  if (!friendInfo.value) return '分享'
  
  const remark = friendInfo.value.remark
  const nickName = friendInfo.value.nickName
  
  if (remark && remark !== nickName) {
    return `与 ${remark}（${nickName}）的分享`
  }
  return `与 ${nickName} 的分享`
}

// 打开对话框
const show = async (friend) => {
  friendInfo.value = friend
  dialogVisible.value = true
  await loadShareHistory()
}

// 加载分享历史
const loadShareHistory = async () => {
  try {
    const result = await proxy.Request({
      url: api.getShareHistory,
      params: {
        friendId: friendInfo.value.friendId
      },
      showLoading: false
    })
    
    if (result && result.data) {
      shareList.value = result.data
      // 滚动到底部显示最新消息
      setTimeout(() => {
        scrollToBottom()
      }, 100)
    }
  } catch (error) {
    console.error('加载分享历史失败:', error)
  }
}

// 滚动到底部
const scrollToBottom = () => {
  if (shareHistoryRef.value) {
    shareHistoryRef.value.scrollTop = shareHistoryRef.value.scrollHeight
  }
}

// 打开文件选择器
const openFileSelector = () => {
  fileSelectDialogRef.value.show()
}

// 处理文件选择
const handleFileSelect = async (selectedFiles, validType) => {
  if (selectedFiles.length === 0) {
    ElMessage.warning('请选择要分享的文件')
    return
  }

  const fileIds = selectedFiles.map(f => f.fileId).join(',')
  
  try {
    const result = await proxy.Request({
      url: api.shareFilesToFriend,
      params: {
        friendId: friendInfo.value.friendId,
        fileIds: fileIds,
        validType: validType
      }
    })
    
    if (result) {
      ElMessage.success('文件分享成功')
      await loadShareHistory()
    }
  } catch (error) {
    console.error('分享文件失败:', error)
  }
}

// 取消分享
const cancelShare = async (shareId) => {
  try {
    const result = await proxy.Request({
      url: api.cancelFriendShare,
      params: {
        shareIds: String(shareId)
      }
    })
    
    if (result) {
      ElMessage.success('已取消分享')
      await loadShareHistory()
    }
  } catch (error) {
    console.error('取消分享失败:', error)
  }
}

// 打开文件夹选择器
const openFolderSelector = (share) => {
  currentSaveShare.value = share
  folderSelectDialogRef.value.showFolderDialog()
}

// 处理文件夹选择
const handleFolderSelect = async (folderId) => {
  if (!currentSaveShare.value) return
  
  await saveFile(currentSaveShare.value, folderId)
  folderSelectDialogRef.value.close()
}

// 保存文件
const saveFile = async (share, targetFolderId = '0') => {
  try {
    const result = await proxy.Request({
      url: api.saveFriendSharedFile,
      params: {
        shareId: share.shareId,
        targetFolderId: targetFolderId
      }
    })
    
    if (result) {
      ElMessage.success('文件保存成功')
      // 刷新分享历史
      await loadShareHistory()
    }
  } catch (error) {
    console.error('保存文件失败:', error)
    ElMessage.error(error.message || '保存文件失败')
  }
}

// 下载文件
const download = async (row) => {
  let result = await proxy.Request({
    url: '/file/createDownloadUrl/' + row.fileId,
  })
  if (!result) {
    return
  }
  window.location.href = '/api/file/download/' + result.data
}

// 下载好友分享的文件
const downloadFile = async (share) => {
  try {
    const result = await proxy.Request({
      url: api.downloadFriendSharedFile,
      params: {
        shareId: share.shareId
      }
    })
    
    if (result && result.data) {
      // 使用下载码下载文件
      window.location.href = '/api/friendShare/download/' + result.data
      ElMessage.success('开始下载')
    }
  } catch (error) {
    console.error('下载文件失败:', error)
    ElMessage.error(error.message || '下载文件失败')
  }
}

// 预览好友分享的文件
const previewFile = (share) => {
  if (share.folderType === 1) {
    ElMessage.warning('文件夹不支持预览')
    return
  }

  if (share.status !== 1) {
    ElMessage.warning('文件分享已失效，无法预览')
    return
  }

  // 构造预览数据，使用showPart=3表示好友分享预览
  const previewData = {
    fileId: share.fileId,
    shareId: share.shareId,
    fileName: share.fileName,
    fileType: share.fileType,
    fileCategory: share.fileCategory,
    fileCover: share.fileCover,
    fileSize: share.fileSize,
    folderType: share.folderType,
    status: 2  // 假设文件已转码完成
  }

  // 调用预览组件，showPart=3表示好友分享预览模式
  previewRef.value.showPreview(previewData, 3)
}

// 格式化文件大小
const formatSize = (size) => {
  return proxy.Utils.size2Str(size)
}

// 格式化时间
const formatTime = (time) => {
  const date = new Date(time)
  const now = new Date()
  const diff = now - date
  
  if (diff < 60000) return '刚刚'
  if (diff < 3600000) return Math.floor(diff / 60000) + '分钟前'
  if (diff < 86400000) return Math.floor(diff / 3600000) + '小时前'
  if (diff < 604800000) return Math.floor(diff / 86400000) + '天前'
  
  return date.toLocaleDateString()
}

// 获取状态文本
const getStatusText = (share) => {
  if (share.status === 0) return '已取消'
  if (share.status === 2) return '已过期'
  if (share.validType === 0) return '永久有效'
  
  const validDays = share.validType === 1 ? 1 : share.validType === 2 ? 7 : 30
  return `${validDays}天有效`
}

// 获取状态样式类
const getStatusClass = (share) => {
  if (share.status === 0) return 'cancelled'
  if (share.status === 2) return 'expired'
  return 'valid'
}

// 关闭对话框
const handleClose = () => {
  shareList.value = []
}

defineExpose({
  show
})
</script>

<style lang="scss" scoped>
.share-dialog-content {
  height: 450px;
  display: flex;
  flex-direction: column;

  .share-history {
    flex: 1;
    overflow-y: auto;
    padding: 10px;
    background: var(--chat-bg);
    transition: background-color 0.3s ease;
    border-radius: 8px;

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

    .chat-list {
      display: flex;
      flex-direction: column;
      gap: 20px;
      padding: 10px 0;

      .chat-message {
        display: flex;
        gap: 12px;
        animation: slideIn 0.3s ease-out;

        &.sent {
          flex-direction: row-reverse;

          .message-bubble {
            background: linear-gradient(135deg, #e8eaf6 0%, #c5cae9 100%);
            color: #333;
            border-radius: 18px 2px 18px 18px;

            .file-card {
              background: rgba(255, 255, 255, 0.5);

              .file-name {
                color: #333;
              }

              .file-meta {
                color: #666;
              }
            }

            .timestamp {
              color: #666;
            }
          }
        }

        &.received {
          flex-direction: row;

          .message-bubble {
            background: linear-gradient(135deg, #e8f5e9 0%, #c8e6c9 100%);
            border-radius: 2px 18px 18px 18px;

            .file-card {
              background: rgba(255, 255, 255, 0.5);
            }
          }
        }

        .avatar {
          flex-shrink: 0;
          width: 45px;
          height: 45px;
          border-radius: 50%;
          overflow: hidden;
          border: 2px solid var(--avatar-border);
          box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2), 0 2px 4px rgba(0, 0, 0, 0.15);
          transition: all 0.3s ease;

          img {
            width: 100%;
            height: 100%;
            object-fit: cover;
          }

          &:hover {
            box-shadow: 0 6px 16px rgba(0, 0, 0, 0.25), 0 3px 6px rgba(0, 0, 0, 0.2);
            transform: scale(1.05);
          }
        }

        .message-bubble {
          max-width: 65%;
          padding: 12px 16px;
          transition: all 0.3s ease;
          box-shadow: 0 3px 10px rgba(0, 0, 0, 0.12), 0 1px 3px rgba(0, 0, 0, 0.08);

          &:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(0, 0, 0, 0.18), 0 3px 6px rgba(0, 0, 0, 0.12);
          }

          .file-card {
            display: flex;
            gap: 12px;
            padding: 12px;
            border-radius: 12px;
            margin-bottom: 10px;
            align-items: center;

            .file-icon {
              flex-shrink: 0;
              display: flex;
              align-items: center;
              justify-content: center;
            }

            .file-info {
              flex: 1;
              min-width: 0;

              .file-name {
                font-size: 14px;
                font-weight: 600;
                margin-bottom: 6px;
                overflow: hidden;
                text-overflow: ellipsis;
                white-space: nowrap;
                line-height: 1.4;
                color: #333;
              }

              .file-meta {
                display: flex;
                align-items: center;
                gap: 8px;
                font-size: 12px;

                .file-size {
                  color: #666;
                }

                .status-badge {
                  padding: 2px 8px;
                  border-radius: 10px;
                  font-size: 11px;
                  font-weight: 500;

                  &.valid {
                    background-color: #d4edda;
                    color: #155724;
                  }

                  &.cancelled {
                    background-color: #f8d7da;
                    color: #721c24;
                  }

                  &.expired {
                    background-color: #fff3cd;
                    color: #856404;
                  }
                }
              }
            }
          }

          .action-buttons-horizontal {
            display: flex;
            gap: 8px;
            margin-bottom: 8px;
            justify-content: flex-start;

            .custom-btn {
              display: flex;
              align-items: center;
              gap: 6px;
              padding: 6px 12px;
              border: 2px solid #d0d0d0;
              border-radius: 6px;
              background: white;
              color: #333;
              font-size: 13px;
              font-weight: 500;
              cursor: pointer;
              transition: all 0.3s ease;

              .btn-icon {
                width: 18px;
                height: 18px;
                object-fit: contain;
              }

              &:hover {
                transform: translateY(-2px);
                box-shadow: 0 4px 8px rgba(0, 0, 0, 0.15);
              }

              &:active {
                transform: translateY(0);
              }

              &.preview-btn:hover {
                border-color: #9b59b6;
                background: #f3e5f5;
              }

              &.save-btn:hover {
                border-color: #27ae60;
                background: #e8f5e9;
              }

              &.download-btn:hover {
                border-color: #3498db;
                background: #e3f2fd;
              }
            }
          }

          .action-buttons {
            display: flex;
            gap: 8px;
            margin-bottom: 8px;
            justify-content: flex-end;

            .custom-btn {
              display: flex;
              align-items: center;
              gap: 6px;
              padding: 6px 12px;
              border: 2px solid #d0d0d0;
              border-radius: 6px;
              background: white;
              color: #333;
              font-size: 13px;
              font-weight: 500;
              cursor: pointer;
              transition: all 0.3s ease;

              .btn-icon {
                width: 18px;
                height: 18px;
                object-fit: contain;
              }

              &:hover {
                transform: translateY(-2px);
                box-shadow: 0 4px 8px rgba(0, 0, 0, 0.15);
              }

              &:active {
                transform: translateY(0);
              }

              &.preview-btn:hover {
                border-color: #9b59b6;
                background: #f3e5f5;
              }

              &.download-btn:hover {
                border-color: #3498db;
                background: #e3f2fd;
              }

              &.rollback-btn:hover {
                border-color: #999;
                background: #f5f5f5;
              }
            }
          }

          .timestamp {
            font-size: 11px;
            color: #999;
            text-align: right;
            margin-top: 4px;
          }
        }
      }
    }
  }
}

.dialog-footer {
  display: flex;
  justify-content: center;
  gap: 10px;
  padding-top: 10px;
  border-top: 1px solid var(--border-color);
  transition: border-color 0.3s ease;
}

@keyframes slideIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* 夜间模式支持 */
:root {
  --chat-bg: linear-gradient(to bottom, #f8f9fa 0%, #ffffff 100%);
  --avatar-border: #e0e0e0;
  --border-color: #e0e0e0;
}

html.dark {
  --chat-bg: linear-gradient(to bottom, #1a1a1a 0%, #2d2d2d 100%);
  --avatar-border: #444;
  --border-color: #444;
}

/* 夜间模式下的气泡样式调整 */
html.dark {
  .chat-message {
    &.sent .message-bubble {
      background: linear-gradient(135deg, #424242 0%, #616161 100%);
      color: #e0e0e0;

      .file-card {
        background: rgba(255, 255, 255, 0.1);

        .file-name {
          color: #e0e0e0;
        }

        .file-meta {
          color: #bbb;

          .file-size {
            color: #bbb;
          }
        }
      }

      .timestamp {
        color: #bbb;
      }
    }

    &.received .message-bubble {
      background: linear-gradient(135deg, #2e7d32 0%, #388e3c 100%);
      color: #e0e0e0;

      .file-card {
        background: rgba(255, 255, 255, 0.1);

        .file-name {
          color: #e0e0e0;
        }

        .file-meta {
          color: #bbb;

          .file-size {
            color: #bbb;
          }
        }
      }

      .timestamp {
        color: #bbb;
      }
    }
  }
}
</style>
