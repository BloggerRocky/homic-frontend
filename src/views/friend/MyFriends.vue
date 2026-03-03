<template>
  <div class="my-friends">
    <el-tabs v-model="activeTab" class="friends-tabs">
      <el-tab-pane label="全部好友" name="all">
        <div class="friends-list">
          <div v-if="allFriends.length === 0" class="empty-state">
            <el-empty description="暂无好友" />
          </div>
          <div v-else class="friend-items">
            <div 
              v-for="friend in allFriends" 
              :key="friend.friendId"
              class="friend-item"
              @contextmenu.prevent="handleContextMenu($event, friend)"
            >
              <div class="friend-info">
                <img 
                  :src="`${proxy.globalInfo.avatarUrl}${friend.friendId}?${timestamp}`" 
                  :alt="friend.nickName" 
                  class="friend-avatar" 
                />
                <div class="friend-details">
                  <div class="friend-name">
                    {{ friend.remark || friend.nickName }}
                    <span v-if="friend.remark" class="original-name">({{ friend.nickName }})</span>
                  </div>
                  <div class="friend-id">ID: {{ friend.friendId }}</div>
                  <div class="friend-time">结交时间: {{ friend.createTime }}</div>
                </div>
              </div>
              <div class="friend-actions">
                <button class="action-btn" @click="shareFriend(friend)" title="分享">
                  <img src="@/assets/button-image/share.png" alt="分享" class="action-icon" />
                </button>
                <button class="action-btn" @click="editRemark(friend)" title="备注">
                  <img src="@/assets/button-image/remark.png" alt="备注" class="action-icon" />
                </button>
                <button class="action-btn" @click="toggleSpecial(friend)" :title="friend.isSpecial === 1 ? '取消关注' : '特别关注'">
                  <img 
                    :src="friend.isSpecial === 1 ? followFillIcon : followIcon" 
                    alt="关注" 
                    class="action-icon" 
                  />
                </button>
                <button class="action-btn" @click="confirmDelete(friend)" title="删除">
                  <img src="@/assets/button-image/delete.png" alt="删除" class="action-icon" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </el-tab-pane>
      
      <el-tab-pane label="特别关注" name="special">
        <div class="friends-list">
          <div v-if="specialFriends.length === 0" class="empty-state">
            <el-empty description="暂无特别关注的好友" />
          </div>
          <div v-else class="friend-items">
            <div 
              v-for="friend in specialFriends" 
              :key="friend.friendId"
              class="friend-item"
              @contextmenu.prevent="handleContextMenu($event, friend)"
            >
              <div class="friend-info">
                <img 
                  :src="`${proxy.globalInfo.avatarUrl}${friend.friendId}?${timestamp}`" 
                  :alt="friend.nickName" 
                  class="friend-avatar" 
                />
                <div class="friend-details">
                  <div class="friend-name">
                    {{ friend.remark || friend.nickName }}
                    <span v-if="friend.remark" class="original-name">({{ friend.nickName }})</span>
                  </div>
                  <div class="friend-id">ID: {{ friend.friendId }}</div>
                  <div class="friend-time">结交时间: {{ friend.createTime }}</div>
                </div>
              </div>
              <div class="friend-actions">
                <button class="action-btn" @click="shareFriend(friend)" title="分享">
                  <img src="@/assets/button-image/share.png" alt="分享" class="action-icon" />
                </button>
                <button class="action-btn" @click="editRemark(friend)" title="备注">
                  <img src="@/assets/button-image/remark.png" alt="备注" class="action-icon" />
                </button>
                <button class="action-btn" @click="toggleSpecial(friend)" title="取消关注">
                  <img :src="followFillIcon" alt="取消关注" class="action-icon" />
                </button>
                <button class="action-btn" @click="confirmDelete(friend)" title="删除">
                  <img src="@/assets/button-image/delete.png" alt="删除" class="action-icon" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </el-tab-pane>
    </el-tabs>

    <!-- 备注对话框 -->
    <el-dialog 
      v-model="remarkDialogVisible" 
      title="修改备注"
      width="400px"
    >
      <el-input 
        v-model="remarkInput"
        placeholder="请输入备注名"
        maxlength="50"
        show-word-limit
        clearable
      />
      <template #footer>
        <button class="dialog-btn btn-primary" @click="saveRemark">确定</button>
        <button class="dialog-btn btn-default" @click="remarkDialogVisible = false">取消</button>
      </template>
    </el-dialog>

    <!-- 好友分享对话框 -->
    <FriendShareDialog ref="shareDialogRef" />
    
    <!-- 右键菜单 -->
    <div 
      v-if="contextMenuVisible" 
      class="context-menu"
      :style="{ top: contextMenuPosition.y + 'px', left: contextMenuPosition.x + 'px' }"
      @click.stop
    >
      <div class="context-menu-item" @click="contextMenuShare">
        <img src="@/assets/button-image/share.png" alt="分享" class="menu-icon" />
        <span>分享</span>
      </div>
      <div class="context-menu-item" @click="contextMenuRemark">
        <img src="@/assets/button-image/remark.png" alt="备注" class="menu-icon" />
        <span>备注</span>
      </div>
      <div class="context-menu-item" @click="contextMenuToggleSpecial">
        <img 
          :src="contextMenuFriend?.isSpecial === 1 ? followFillIcon : followIcon" 
          alt="关注" 
          class="menu-icon" 
        />
        <span>{{ contextMenuFriend?.isSpecial === 1 ? '取消关注' : '特别关注' }}</span>
      </div>
      <div class="context-menu-divider"></div>
      <div class="context-menu-item danger" @click="contextMenuDelete">
        <img src="@/assets/button-image/delete.png" alt="删除" class="menu-icon" />
        <span>删除</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, getCurrentInstance, onMounted, watch } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import FriendShareDialog from './FriendShareDialog.vue'

// 导入图片
import followIcon from '@/assets/button-image/follow.png'
import followFillIcon from '@/assets/button-image/follow-fill.png'

const { proxy } = getCurrentInstance()

const shareDialogRef = ref(null)

const api = {
  getMyFriends: '/friend/getMyFriends',
  getSpecialFriends: '/friend/getSpecialFriends',
  updateFriendRemark: '/friend/updateFriendRemark',
  toggleSpecialAttention: '/friend/toggleSpecialAttention',
  deleteFriend: '/friend/deleteFriend',
}

const activeTab = ref('all')
const allFriends = ref([])
const specialFriends = ref([])
const timestamp = ref(Date.now())

// 备注相关
const remarkDialogVisible = ref(false)
const remarkInput = ref('')
const currentFriend = ref(null)

// 右键菜单相关
const contextMenuVisible = ref(false)
const contextMenuPosition = ref({ x: 0, y: 0 })
const contextMenuFriend = ref(null)

// 处理右键菜单
const handleContextMenu = (event, friend) => {
  event.preventDefault()
  
  contextMenuFriend.value = friend
  contextMenuPosition.value = { x: event.clientX, y: event.clientY }
  contextMenuVisible.value = true
  
  // 点击其他地方关闭菜单
  const closeMenu = () => {
    contextMenuVisible.value = false
    document.removeEventListener('click', closeMenu)
  }
  
  setTimeout(() => {
    document.addEventListener('click', closeMenu)
  }, 0)
}

// 右键菜单 - 分享
const contextMenuShare = () => {
  contextMenuVisible.value = false
  if (contextMenuFriend.value) {
    shareFriend(contextMenuFriend.value)
  }
}

// 右键菜单 - 备注
const contextMenuRemark = () => {
  contextMenuVisible.value = false
  if (contextMenuFriend.value) {
    editRemark(contextMenuFriend.value)
  }
}

// 右键菜单 - 切换关注
const contextMenuToggleSpecial = () => {
  contextMenuVisible.value = false
  if (contextMenuFriend.value) {
    toggleSpecial(contextMenuFriend.value)
  }
}

// 右键菜单 - 删除
const contextMenuDelete = () => {
  contextMenuVisible.value = false
  if (contextMenuFriend.value) {
    confirmDelete(contextMenuFriend.value)
  }
}

// 获取所有好友
const getAllFriends = async () => {
  try {
    const result = await proxy.Request({
      url: api.getMyFriends,
      showLoading: false,
    })
    
    if (result && Array.isArray(result.data)) {
      allFriends.value = result.data
    } else {
      allFriends.value = []
    }
  } catch (error) {
    console.error('获取好友列表失败:', error)
    allFriends.value = []
  }
}

// 获取特别关注的好友
const getSpecialFriends = async () => {
  try {
    const result = await proxy.Request({
      url: api.getSpecialFriends,
      showLoading: false,
    })
    if (result) {
      specialFriends.value = Array.isArray(result.data) ? result.data : []
    }
  } catch (error) {
    console.error('获取特别关注列表失败:', error)
  }
}

// 分享好友
const shareFriend = (friend) => {
  shareDialogRef.value.show(friend)
}

// 编辑备注
const editRemark = (friend) => {
  currentFriend.value = friend
  remarkInput.value = friend.remark || ''
  remarkDialogVisible.value = true
}

// 保存备注
const saveRemark = async () => {
  if (!currentFriend.value) return
  
  try {
    const result = await proxy.Request({
      url: api.updateFriendRemark,
      params: {
        friendId: currentFriend.value.friendId,
        remark: remarkInput.value
      }
    })
    
    if (result) {
      ElMessage.success('备注修改成功')
      currentFriend.value.remark = remarkInput.value
      remarkDialogVisible.value = false
      // 刷新列表
      await getAllFriends()
      if (activeTab.value === 'special') {
        await getSpecialFriends()
      }
    }
  } catch (error) {
    console.error('修改备注失败:', error)
  }
}

// 切换特别关注
const toggleSpecial = async (friend) => {
  const isSpecial = friend.isSpecial === 1
  
  try {
    const result = await proxy.Request({
      url: api.toggleSpecialAttention,
      params: {
        friendId: friend.friendId,
        isSpecial: !isSpecial
      }
    })
    
    if (result) {
      ElMessage.success(isSpecial ? '已取消特别关注' : '已添加特别关注')
      friend.isSpecial = isSpecial ? 0 : 1
      // 刷新列表
      await getAllFriends()
      await getSpecialFriends()
    }
  } catch (error) {
    console.error('切换特别关注失败:', error)
  }
}

// 确认删除
const confirmDelete = (friend) => {
  ElMessageBox.confirm(
    `确定要删除好友【${friend.remark || friend.nickName}】吗？删除后将无法恢复。`,
    '删除好友',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    }
  ).then(() => {
    deleteFriend(friend)
  }).catch(() => {
    // 取消删除
  })
}

// 删除好友
const deleteFriend = async (friend) => {
  try {
    const result = await proxy.Request({
      url: api.deleteFriend,
      params: {
        friendId: friend.friendId
      }
    })
    
    if (result) {
      ElMessage.success('好友已删除')
      // 刷新列表
      await getAllFriends()
      await getSpecialFriends()
    }
  } catch (error) {
    console.error('删除好友失败:', error)
  }
}

// 监听标签切换
watch(activeTab, (newTab) => {
  if (newTab === 'all') {
    getAllFriends()
  } else {
    getSpecialFriends()
  }
})

// 页面加载时获取数据
onMounted(() => {
  getAllFriends()
})
</script>

<style lang="scss" scoped>
.my-friends {
  height: calc(100vh - 56px);
  overflow-y: auto;
  background-color: var(--bg-primary);

  .friends-tabs {
    padding: 20px;
    
    :deep(.el-tabs__header) {
      margin-bottom: 20px;
    }
  }

  .friends-list {
    .empty-state {
      padding: 60px 20px;
      text-align: center;
    }

    .friend-items {
      display: flex;
      flex-direction: column;
      gap: 15px;

      .friend-item {
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

        .friend-info {
          display: flex;
          align-items: center;
          gap: 15px;
          flex: 1;

          .friend-avatar {
            width: 60px;
            height: 60px;
            border-radius: 50%;
            object-fit: cover;
            border: 2px solid var(--border-color);
          }

          .friend-details {
            display: flex;
            flex-direction: column;
            gap: 5px;

            .friend-name {
              font-size: 16px;
              font-weight: 600;
              color: var(--text-primary);

              .original-name {
                font-size: 13px;
                font-weight: 400;
                color: var(--text-tertiary);
                margin-left: 5px;
              }
            }

            .friend-id {
              font-size: 13px;
              color: var(--text-tertiary);
            }

            .friend-time {
              font-size: 12px;
              color: var(--text-tertiary);
            }
          }
        }

        .friend-actions {
          display: flex;
          gap: 10px;
          align-items: center;

          .action-btn {
            width: 40px;
            height: 40px;
            padding: 8px;
            border: none;
            border-radius: 50%;
            cursor: pointer;
            transition: all 0.3s ease;
            display: flex;
            align-items: center;
            justify-content: center;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);

            &:active {
              transform: scale(0.95);
            }

            .action-icon {
              width: 20px;
              height: 20px;
              object-fit: contain;
              filter: brightness(0) invert(1);
            }

            // 分享按钮 - 深蓝色
            &:nth-child(1) {
              background-color: #2563eb;

              &:hover {
                background-color: #1d4ed8;
                transform: scale(1.15);
                box-shadow: 0 4px 12px rgba(37, 99, 235, 0.4);
              }
            }

            // 备注按钮 - 褐色
            &:nth-child(2) {
              background-color: #92400e;

              &:hover {
                background-color: #78350f;
                transform: scale(1.15);
                box-shadow: 0 4px 12px rgba(146, 64, 14, 0.4);
              }
            }

            // 关注按钮 - 粉色
            &:nth-child(3) {
              background-color: #ec4899;

              &:hover {
                background-color: #db2777;
                transform: scale(1.15);
                box-shadow: 0 4px 12px rgba(236, 72, 153, 0.4);
              }
            }

            // 删除按钮 - 红色
            &:nth-child(4) {
              background-color: #dc2626;

              &:hover {
                background-color: #b91c1c;
                transform: scale(1.15);
                box-shadow: 0 4px 12px rgba(220, 38, 38, 0.4);
              }
            }
          }
        }
      }
    }
  }

  .dialog-btn {
    min-width: 80px;
    padding: 8px 16px;
    border: none;
    border-radius: 4px;
    font-size: 14px;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.3s ease;

    &.btn-primary {
      background-color: #409eff;
      color: white;

      &:hover {
        background-color: #66b1ff;
      }

      &:active {
        background-color: #0a66d6;
      }
    }

    &.btn-default {
      background-color: white;
      color: #333;
      border: 1px solid #dcdfe6;

      &:hover {
        background-color: #f56c6c;
        color: white;
        border-color: #f56c6c;
      }

      &:active {
        background-color: #dd001b;
        border-color: #dd001b;
      }
    }
  }

  :deep(.el-dialog__footer) {
    display: flex;
    gap: 10px;
    justify-content: center;
  }
  
  .context-menu {
    position: fixed;
    background: white;
    border: 1px solid #e4e7ed;
    border-radius: 8px;
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);
    z-index: 9999;
    min-width: 160px;
    padding: 8px 0;
    
    .context-menu-item {
      padding: 10px 20px;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 12px;
      font-size: 14px;
      color: #606266;
      transition: all 0.3s;
      
      .menu-icon {
        width: 18px;
        height: 18px;
        object-fit: contain;
        opacity: 0.7;
      }
      
      &:hover {
        background-color: #f5f7fa;
        color: #409eff;
        
        .menu-icon {
          opacity: 1;
        }
      }
      
      &.danger {
        color: #f56c6c;
        
        &:hover {
          background-color: #fef0f0;
          color: #f56c6c;
        }
      }
    }
    
    .context-menu-divider {
      height: 1px;
      background-color: #e4e7ed;
      margin: 5px 0;
    }
  }
}
</style>
