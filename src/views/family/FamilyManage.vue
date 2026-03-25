<template>
  <div class="family-manage">
    <!-- 未加入家庭状态 -->
    <div v-if="!hasFamily" class="content-wrapper">
      <div class="welcome-section">
        <img src="@/assets/friend_code_ungenerated.png" alt="家庭管理" class="welcome-image" />
        <div class="info-card">
          <p class="title">暂未加入家庭</p>
          <p class="description">创建或加入家庭，与家人共享文件和空间</p>
          <div class="button-group">
            <button class="custom-btn btn-generate" @click="showCreateDialog = true">
              创建家庭
            </button>
            <button class="custom-btn btn-search" @click="showSearchDialog = true">
              搜寻家庭
            </button>
            <button class="custom-btn btn-invite" @click="showInviteDialog = true">
              家庭邀请
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- 已加入家庭状态 -->
    <div v-else class="family-content">
      <!-- 顶部切换按钮 -->
      <div class="tab-buttons">
        <button 
          :class="['tab-btn', { active: activeTab === 'info' }]" 
          @click="activeTab = 'info'"
        >
          家庭信息
        </button>
        <button 
          v-if="isCreator"
          :class="['tab-btn', { active: activeTab === 'apply' }]" 
          @click="activeTab = 'apply'"
        >
          加入申请
          <span v-if="applyCount > 0" class="badge">{{ applyCount }}</span>
        </button>
        <button 
          :class="['tab-btn', { active: activeTab === 'manage' }]" 
          @click="activeTab = 'manage'"
        >
          家庭管理
        </button>
      </div>

      <!-- 家庭信息页 -->
      <div v-show="activeTab === 'info'" class="family-info-page">
        <div class="family-header">
          <div class="family-avatar-section">
            <Avatar
              type="family"
              :userId="familyInfo.familyId"
              :avatar="familyInfo.familyAvatar"
              :width="120"
              :timestamp="avatarTimestamp"
            />
            <el-button size="small" @click="updateFamilyAvatar">修改头像</el-button>
          </div>
          <div class="family-details">
            <div class="family-title-row">
              <h2>{{ familyInfo.familyName }}</h2>
            </div>
            <p class="family-desc">{{ familyInfo.familyDesc || '暂无描述' }}</p>
            <div class="family-stats">
              <span>创建时间: {{ familyInfo.createTime }}</span>
              <span>成员数量: {{ familyMembers.length }}</span>
            </div>
            <div class="family-actions-links">
              <a v-if="isCreator || isAdmin" class="action-link" @click="openEditDialog">编辑家庭信息</a>
              <a class="action-link" @click="openRemarkDialog">我的昵称</a>
            </div>
          </div>
        </div>

        <div class="family-members">
          <h3>家庭成员</h3>
          <div class="members-list">
            <div v-for="member in familyMembers" :key="member.userId" class="member-item">
              <Avatar
                :userId="member.userId"
                :avatar="member.avatar"
                :width="48"
              />
              <div class="member-info">
                <div class="member-name">
                  <template v-if="member.remark">
                    {{ member.remark }}({{ member.nickName }})
                  </template>
                  <template v-else>
                    {{ member.nickName }}
                  </template>
                </div>
                <div class="member-role">{{ getRoleText(member.role) }}</div>
              </div>
              <!-- 关怀账号显示禁止图标 -->
              <div v-if="member.isDummy" class="forbidden-icon" title="关怀账号不支持添加好友">
                <span class="icon">🚫</span>
              </div>
              <!-- 普通用户显示添加好友按钮 -->
              <div v-else-if="!member.isFriend && member.userId !== currentUserId && !userInfo.isDummy" class="add-friend-btn" @click="showAddFriendConfirm(member)">
                <span class="add-icon">+</span>
              </div>
            </div>
          </div>
        </div>

        <div class="family-actions" v-if="!userInfo.isDummy">
          <button class="custom-btn btn-generate" @click="generateFamilyCode">生成家庭码</button>
          <button class="custom-btn btn-invite" @click="showInviteFriendDialog = true">邀请好友</button>
          <button class="custom-btn btn-leave" @click="leaveFamily">离开家庭</button>
        </div>
      </div>

      <!-- 加入申请页（仅创建者可见） -->
      <div v-show="activeTab === 'apply'" class="family-apply-page">
        <div v-if="applyList.length === 0" class="empty-state">
          <el-empty description="暂无加入申请" />
        </div>
        <div v-else class="apply-list">
          <div v-for="apply in applyList" :key="apply.applyId" class="apply-item">
            <Avatar
              :userId="apply.userId"
              :avatar="apply.avatar"
              :width="48"
            />
            <div class="apply-info">
              <div class="apply-name">{{ apply.nickName }}</div>
              <div class="apply-time">申请时间: {{ apply.createTime }}</div>
            </div>
            <div class="apply-actions">
              <template v-if="apply.status === 0">
                <el-button type="success" size="small" @click="acceptApply(apply)">同意</el-button>
                <el-button type="danger" size="small" @click="rejectApply(apply)">拒绝</el-button>
              </template>
              <template v-else>
                <el-tag :type="apply.status === 1 ? 'success' : 'danger'" size="large">
                  {{ apply.status === 1 ? '已同意' : '已拒绝' }}
                </el-tag>
              </template>
            </div>
          </div>
        </div>
      </div>

      <!-- 家庭管理页 -->
      <div v-show="activeTab === 'manage'" class="family-manage-page">
        <div class="manage-members-list">
          <div v-for="member in familyMembers" :key="member.userId" class="manage-member-item">
            <div class="member-main-info">
              <Avatar
                :userId="member.userId"
                :avatar="member.avatar"
                :width="56"
              />
              <div class="member-details">
                <div class="member-name-row">
                  <span class="member-name">
                    <template v-if="member.remark">
                      {{ member.remark }}({{ member.nickName }})
                    </template>
                    <template v-else>
                      {{ member.nickName }}
                    </template>
                  </span>
                  <span class="member-role-tag" :class="getRoleClass(member.role)">
                    {{ getRoleText(member.role) }}
                  </span>
                  <span v-if="member.isDummy" class="care-badge">关怀账号</span>
                </div>
                <div class="member-meta">
                  <span>用户ID: {{ member.userId }}</span>
                  <span>加入时间: {{ member.joinTime }}</span>
                </div>
              </div>
            </div>
            <div class="member-actions">
              <img 
                v-if="canManageMember(member)"
                src="@/assets/icon-image/famliy/lock.png" 
                class="action-icon" 
                title="权限管理"
                @click="openPermissionDialog(member)"
              />
              <img 
                v-if="canManageMember(member)"
                src="@/assets/icon-image/famliy/remark.png" 
                class="action-icon" 
                title="修改备注"
                @click="openMemberRemarkDialog(member)"
              />
              <img 
                v-if="canRemoveMember(member)"
                src="@/assets/icon-image/famliy/remove.png" 
                class="action-icon" 
                title="移出家庭"
                @click="removeMember(member)"
              />
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 创建家庭对话框 -->
    <el-dialog v-model="showCreateDialog" title="创建家庭" width="500px">
      <el-form :model="createForm" label-width="80px">
        <el-form-item label="家庭名称">
          <el-input v-model="createForm.familyName" placeholder="请输入家庭名称" maxlength="20" />
        </el-form-item>
        <el-form-item label="家庭描述">
          <el-input
            v-model="createForm.familyDesc"
            type="textarea"
            placeholder="请输入家庭描述"
            maxlength="100"
            :rows="3"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showCreateDialog = false">取消</el-button>
        <el-button type="primary" @click="createFamily">创建</el-button>
      </template>
    </el-dialog>

    <!-- 搜寻家庭对话框 -->
    <el-dialog v-model="showSearchDialog" title="搜寻家庭" width="500px">
      <div class="search-section">
        <el-input
          v-model="searchCode"
          placeholder="请输入家庭码"
          maxlength="10"
        >
          <template #append>
            <el-button @click="searchFamily">搜索</el-button>
          </template>
        </el-input>
      </div>
      <div v-if="searchResult" class="search-result">
        <div class="family-card">
          <Avatar
            type="family"
            :userId="searchResult.familyId"
            :avatar="searchResult.familyAvatar"
            :width="60"
          />
          <div class="family-info">
            <h4>{{ searchResult.familyName }}</h4>
            <p>{{ searchResult.familyDesc }}</p>
            <p class="member-count">成员: {{ searchResult.memberCount }}人</p>
          </div>
          <el-button type="primary" @click="applyJoinFamily">申请加入</el-button>
        </div>
      </div>
    </el-dialog>

    <!-- 家庭邀请对话框 -->
    <el-dialog v-model="showInviteDialog" title="家庭邀请" width="600px" @open="handleInviteDialogOpen">
      <div v-if="inviteList.length === 0" class="empty-state">
        <el-empty description="暂无家庭邀请" />
      </div>
      <div v-else class="invite-list">
        <div v-for="invite in inviteList" :key="invite.inviteId" class="invite-item">
          <Avatar
            :userId="invite.fromUserId"
            :avatar="invite.fromUserAvatar"
            :width="48"
          />
          <div class="invite-info">
            <div class="invite-text">
              <strong>{{ invite.fromUserName }}</strong> 邀请你加入家庭
              <strong>{{ invite.familyName }}</strong>
            </div>
            <div class="invite-time">{{ invite.createTime }}</div>
          </div>
          <div class="invite-actions">
            <el-button type="success" size="small" @click="acceptInvite(invite)">接受</el-button>
            <el-button type="danger" size="small" @click="rejectInvite(invite)">拒绝</el-button>
          </div>
        </div>
      </div>
    </el-dialog>

    <!-- 邀请好友对话框 -->
    <el-dialog v-model="showInviteFriendDialog" title="邀请好友加入家庭" width="600px" @open="handleInviteFriendDialogOpen" @close="handleInviteFriendDialogClose">
      <FriendSelectDialog
        ref="friendSelectRef"
        @confirm="inviteFriendsToFamily"
      />
    </el-dialog>

    <!-- 家庭码显示对话框 -->
    <el-dialog v-model="showCodeDialog" title="家庭码" width="400px">
      <div class="code-display">
        <div class="code-value">{{ familyCode }}</div>
        <p class="code-tip">将此家庭码分享给好友，好友可通过此码搜索并申请加入家庭</p>
        <el-button type="primary" @click="copyFamilyCode">复制家庭码</el-button>
      </div>
    </el-dialog>

    <!-- 修改家庭头像对话框 -->
    <UpdateFamilyAvatar
      ref="updateFamilyAvatarRef"
      @updateAvatar="reloadFamilyInfo"
    />

    <!-- 编辑家庭信息对话框 -->
    <el-dialog v-model="showEditDialog" title="编辑家庭信息" width="500px">
      <el-form :model="editForm" label-width="80px">
        <el-form-item label="家庭名称">
          <el-input v-model="editForm.familyName" placeholder="请输入家庭名称" maxlength="50" />
        </el-form-item>
        <el-form-item label="家庭描述">
          <el-input
            v-model="editForm.familyDesc"
            type="textarea"
            placeholder="请输入家庭描述"
            maxlength="200"
            :rows="3"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showEditDialog = false">取消</el-button>
        <el-button type="primary" @click="updateFamilyInfo">保存</el-button>
      </template>
    </el-dialog>

    <!-- 修改昵称对话框 -->
    <el-dialog v-model="showRemarkDialog" title="我的昵称" width="500px">
      <el-form :model="remarkForm" label-width="80px">
        <el-form-item label="昵称">
          <el-input 
            v-model="remarkForm.remark" 
            placeholder="请输入在该家庭中的昵称" 
            maxlength="50"
            clearable
          />
          <template #extra>
            <div style="color: var(--text-tertiary); font-size: 12px; margin-top: 5px;">
              此昵称仅在该家庭内显示，留空则显示账号昵称
            </div>
          </template>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showRemarkDialog = false">取消</el-button>
        <el-button type="primary" @click="updateRemark">保存</el-button>
      </template>
    </el-dialog>

    <!-- 权限管理对话框 -->
    <el-dialog v-model="showPermissionDialog" title="权限管理" width="500px">
      <div class="permission-content">
        <div class="permission-user-info">
          <Avatar
            :userId="selectedMember?.userId"
            :avatar="selectedMember?.avatar"
            :width="48"
          />
          <div class="user-info">
            <div class="user-name">
              <template v-if="selectedMember?.remark">
                {{ selectedMember.remark }}({{ selectedMember.nickName }})
              </template>
              <template v-else>
                {{ selectedMember?.nickName }}
              </template>
            </div>
            <div class="user-id">{{ selectedMember?.userId }}</div>
          </div>
        </div>
        <el-form :model="permissionForm" label-width="80px">
          <el-form-item label="角色">
            <el-radio-group v-model="permissionForm.role">
              <el-radio :label="1">管理员</el-radio>
              <el-radio :label="2">成员</el-radio>
            </el-radio-group>
          </el-form-item>
        </el-form>
      </div>
      <template #footer>
        <el-button @click="showPermissionDialog = false">取消</el-button>
        <el-button type="primary" @click="updateMemberRole">保存</el-button>
      </template>
    </el-dialog>

    <!-- 修改成员备注对话框 -->
    <el-dialog v-model="showMemberRemarkDialog" title="修改成员备注" width="500px">
      <div class="permission-content">
        <div class="permission-user-info">
          <Avatar
            :userId="selectedMember?.userId"
            :avatar="selectedMember?.avatar"
            :width="48"
          />
          <div class="user-info">
            <div class="user-name">{{ selectedMember?.nickName }}</div>
            <div class="user-id">{{ selectedMember?.userId }}</div>
          </div>
        </div>
        <el-form :model="memberRemarkForm" label-width="80px">
          <el-form-item label="备注">
            <el-input 
              v-model="memberRemarkForm.remark" 
              placeholder="请输入成员备注" 
              maxlength="50"
              clearable
            />
            <template #extra>
              <div style="color: var(--text-tertiary); font-size: 12px; margin-top: 5px;">
                此备注仅在该家庭内显示
              </div>
            </template>
          </el-form-item>
        </el-form>
      </div>
      <template #footer>
        <el-button @click="showMemberRemarkDialog = false">取消</el-button>
        <el-button type="primary" @click="updateMemberRemark">保存</el-button>
      </template>
    </el-dialog>

    <!-- 关怀账号移除确认对话框 -->
    <el-dialog v-model="showRemoveCareAccountDialog" title="⚠️ 警告：移除关怀账号" width="500px" :close-on-click-modal="false" @close="cancelRemoveCareAccount">
      <div class="remove-care-account-content">
        <div class="warning-icon">⚠️</div>
        <div class="warning-text">
          <p class="main-warning">您正在移除关怀账号 <strong>{{ selectedMember?.nickName }}</strong></p>
          <p class="sub-warning">关怀账号移出家庭后将被<span class="highlight">永久删除</span>，所有关联数据将无法恢复！</p>
        </div>
        <div class="countdown-hint">
          请仔细阅读以上警告，{{ removeCareAccountCountdown }}秒后可确认操作
        </div>
      </div>
      <template #footer>
        <el-button @click="cancelRemoveCareAccount">取消</el-button>
        <el-button type="danger" :disabled="removeCareAccountCountdown > 0" @click="confirmRemoveCareAccount">
          {{ removeCareAccountCountdown > 0 ? `确认移除 (${removeCareAccountCountdown}s)` : '确认移除' }}
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, getCurrentInstance, onMounted } from 'vue'
import Avatar from '@/components/Avatar.vue'
import FriendSelectDialog from '../friend/FriendSelectDialog.vue'
import UpdateFamilyAvatar from './UpdateFamilyAvatar.vue'

const { proxy } = getCurrentInstance()

const api = {
  checkFamily: '/family/checkFamily',
  createFamily: '/family/createFamily',
  getFamilyInfo: '/family/getFamilyInfo',
  getFamilyMembers: '/family/getFamilyMembers',
  searchFamily: '/family/searchFamily',
  applyJoinFamily: '/family/applyJoinFamily',
  getInviteList: '/family/getInviteList',
  acceptInvite: '/family/acceptInvite',
  rejectInvite: '/family/rejectInvite',
  generateCode: '/family/generateCode',
  inviteFriends: '/family/inviteFriends',
  leaveFamily: '/family/leaveFamily',
  updateAvatar: '/family/updateAvatar',
  getApplyList: '/family/getApplyList',
  acceptApply: '/family/acceptApply',
  rejectApply: '/family/rejectApply',
  updateFamilyInfo: '/family/updateFamilyInfo',
  updateRemark: '/family/updateRemark',
  updateMemberRole: '/family/updateMemberRole',
  updateMemberRemark: '/family/updateMemberRemark',
  removeMember: '/family/removeMember',
  sendFriendRequest: '/friend/sendFriendRequest',
}

// 当前用户ID
const currentUserId = ref('')
const userInfo = ref(proxy.VueCookies.get('userInfo'))

// 状态
const hasFamily = ref(false)
const activeTab = ref('info')
const familyInfo = ref({})
const familyMembers = ref([])
const avatarTimestamp = ref(Date.now())
const isCreator = ref(false)
const isAdmin = ref(false)
const applyList = ref([])
const applyCount = ref(0)

// 对话框显示状态
const showCreateDialog = ref(false)
const showSearchDialog = ref(false)
const showInviteDialog = ref(false)
const showInviteFriendDialog = ref(false)
const showCodeDialog = ref(false)
const showEditDialog = ref(false)
const showRemarkDialog = ref(false)

// 表单数据
const createForm = reactive({
  familyName: '',
  familyDesc: '',
})

const searchCode = ref('')
const searchResult = ref(null)
const inviteList = ref([])
const familyCode = ref('')
const editForm = reactive({
  familyName: '',
  familyDesc: '',
})

const remarkForm = reactive({
  remark: '',
})

const selectedMember = ref(null)
const showPermissionDialog = ref(false)
const showMemberRemarkDialog = ref(false)

// 关怀账号移除确认对话框
const showRemoveCareAccountDialog = ref(false)
const removeCareAccountCountdown = ref(5)
let removeCareAccountTimer = null

const permissionForm = reactive({
  role: 2,
})

const memberRemarkForm = reactive({
  remark: '',
})

// 关怀账号相关
const careAccounts = ref([])
const showCreateCareAccountDialog = ref(false)
const showLoginCodeDialog = ref(false)
const currentLoginCode = ref('')
const avatarUploadRef = ref()

const careAccountForm = reactive({
  nickName: '',
  avatar: null,
})

// 检查是否已加入家庭
const checkFamily = async () => {
  const result = await proxy.Request({
    url: api.checkFamily,
    showLoading: false,
  })
  if (result) {
    hasFamily.value = result.data.hasFamily
    if (hasFamily.value) {
      loadFamilyInfo()
    }
  }
}

// 加载家庭信息
const loadFamilyInfo = async () => {
  const result = await proxy.Request({
    url: api.getFamilyInfo,
  })
  if (result) {
    familyInfo.value = result.data
    loadFamilyMembers()
  }
}

// 加载家庭成员
const loadFamilyMembers = async () => {
  const result = await proxy.Request({
    url: api.getFamilyMembers,
  })
  if (result) {
    familyMembers.value = result.data
    // 检查当前用户是否是创建者或管理员
    const currentUserId = proxy.VueCookies.get('userInfo').userId
    const currentMember = familyMembers.value.find(m => m.userId === currentUserId)
    isCreator.value = currentMember && currentMember.role === 0
    isAdmin.value = currentMember && currentMember.role === 1
    
    // 如果是创建者，加载申请列表
    if (isCreator.value) {
      loadApplyList()
    }
  }
}

// 创建家庭
const createFamily = async () => {
  if (!createForm.familyName) {
    proxy.Message.warning('请输入家庭名称')
    return
  }
  
  const result = await proxy.Request({
    url: api.createFamily,
    params: createForm,
  })
  
  if (result) {
    proxy.Message.success('创建家庭成功')
    showCreateDialog.value = false
    createForm.familyName = ''
    createForm.familyDesc = ''
    checkFamily()
  }
}

// 搜索家庭
const searchFamily = async () => {
  if (!searchCode.value) {
    proxy.Message.warning('请输入家庭码')
    return
  }
  
  const result = await proxy.Request({
    url: api.searchFamily,
    params: { familyCode: searchCode.value },
  })
  
  if (result) {
    searchResult.value = result.data
  }
}

// 申请加入家庭
const applyJoinFamily = async () => {
  const result = await proxy.Request({
    url: api.applyJoinFamily,
    params: { familyId: searchResult.value.familyId },
  })
  
  if (result) {
    proxy.Message.success('申请已发送')
    showSearchDialog.value = false
    searchCode.value = ''
    searchResult.value = null
  }
}

// 加载邀请列表
const loadInviteList = async () => {
  const result = await proxy.Request({
    url: api.getInviteList,
    showLoading: false,
  })
  if (result) {
    inviteList.value = result.data
  }
}

// 接受邀请
const acceptInvite = async (invite) => {
  const result = await proxy.Request({
    url: api.acceptInvite,
    params: { inviteId: invite.inviteId },
  })
  
  if (result) {
    proxy.Message.success('已加入家庭')
    showInviteDialog.value = false
    checkFamily()
  }
}

// 拒绝邀请
const rejectInvite = async (invite) => {
  const result = await proxy.Request({
    url: api.rejectInvite,
    params: { inviteId: invite.inviteId },
  })
  
  if (result) {
    proxy.Message.success('已拒绝邀请')
    loadInviteList()
  }
}

// 生成家庭码
const generateFamilyCode = async () => {
  const result = await proxy.Request({
    url: api.generateCode,
  })
  
  if (result) {
    familyCode.value = result.data.familyCode
    showCodeDialog.value = true
  }
}

// 复制家庭码
const copyFamilyCode = async () => {
  try {
    await navigator.clipboard.writeText(familyCode.value)
    proxy.Message.success('家庭码已复制到剪贴板')
  } catch (err) {
    // 降级方案：使用传统方法复制
    const textarea = document.createElement('textarea')
    textarea.value = familyCode.value
    textarea.style.position = 'fixed'
    textarea.style.opacity = '0'
    document.body.appendChild(textarea)
    textarea.select()
    try {
      document.execCommand('copy')
      proxy.Message.success('家庭码已复制到剪贴板')
    } catch (e) {
      proxy.Message.error('复制失败，请手动复制')
    }
    document.body.removeChild(textarea)
  }
}

// 邀请好友
const friendSelectRef = ref()
const handleInviteFriendDialogOpen = () => {
  if (friendSelectRef.value) {
    // 排除已在家庭中的成员
    const excludeUserIds = familyMembers.value.map(m => m.userId)
    friendSelectRef.value.show(excludeUserIds)
  }
}

const handleInviteFriendDialogClose = () => {
  // 关闭父对话框时，同时关闭 FriendSelectDialog
  if (friendSelectRef.value) {
    friendSelectRef.value.close()
  }
}

const inviteFriendsToFamily = async (selectedFriends) => {
  const friendIds = selectedFriends.map(f => f.friendId).join(',')
  
  const result = await proxy.Request({
    url: api.inviteFriends,
    params: { friendIds },
  })
  
  if (result) {
    proxy.Message.success('邀请已发送')
    showInviteFriendDialog.value = false
  }
}

// 离开家庭
const leaveFamily = () => {
  proxy.Confirm('确定要离开家庭吗？', async () => {
    const result = await proxy.Request({
      url: api.leaveFamily,
    })
    
    if (result) {
      proxy.Message.success('已离开家庭')
      hasFamily.value = false
      familyInfo.value = {}
      familyMembers.value = []
    }
  })
}

// 修改家庭头像
const updateFamilyAvatarRef = ref()
const updateFamilyAvatar = () => {
  updateFamilyAvatarRef.value.show(familyInfo.value)
}

// 重新加载家庭信息
const reloadFamilyInfo = () => {
  avatarTimestamp.value = Date.now() // 更新时间戳强制刷新头像
  loadFamilyInfo()
}

// 获取角色文本
const getRoleText = (role) => {
  const roleMap = {
    0: '创建者',
    1: '管理员',
    2: '成员',
  }
  return roleMap[role] || '成员'
}

// 获取角色样式类
const getRoleClass = (role) => {
  const roleClassMap = {
    0: 'role-creator',
    1: 'role-admin',
    2: 'role-member',
  }
  return roleClassMap[role] || 'role-member'
}

// 加载申请列表
const loadApplyList = async () => {
  const result = await proxy.Request({
    url: api.getApplyList,
    showLoading: false,
  })
  if (result) {
    applyList.value = result.data
    // 只统计待处理的申请数量（status === 0）
    applyCount.value = applyList.value.filter(apply => apply.status === 0).length
  }
}

// 同意申请
const acceptApply = async (apply) => {
  await proxy.Confirm(`确定同意 ${apply.nickName} 加入家庭吗？`, async () => {
    const result = await proxy.Request({
      url: api.acceptApply,
      params: { applyId: apply.applyId },
    })
    
    if (result) {
      proxy.Message.success('已同意申请')
      loadApplyList()
      loadFamilyMembers()
    }
  })
}

// 拒绝申请
const rejectApply = async (apply) => {
  await proxy.Confirm(`确定拒绝 ${apply.nickName} 的申请吗？`, async () => {
    const result = await proxy.Request({
      url: api.rejectApply,
      params: { applyId: apply.applyId },
    })
    
    if (result) {
      proxy.Message.success('已拒绝申请')
      loadApplyList()
    }
  })
}

// 监听邀请对话框打开
const handleInviteDialogOpen = () => {
  loadInviteList()
}

// 打开编辑对话框
const openEditDialog = () => {
  editForm.familyName = familyInfo.value.familyName
  editForm.familyDesc = familyInfo.value.familyDesc || ''
  showEditDialog.value = true
}

// 更新家庭信息
const updateFamilyInfo = async () => {
  if (!editForm.familyName) {
    proxy.Message.warning('请输入家庭名称')
    return
  }
  
  const result = await proxy.Request({
    url: api.updateFamilyInfo,
    params: editForm,
  })
  
  if (result) {
    proxy.Message.success('家庭信息更新成功')
    showEditDialog.value = false
    loadFamilyInfo()
  }
}

// 打开修改昵称对话框
const openRemarkDialog = () => {
  const currentUserId = proxy.VueCookies.get('userInfo').userId
  const currentMember = familyMembers.value.find(m => m.userId === currentUserId)
  remarkForm.remark = currentMember?.remark || ''
  showRemarkDialog.value = true
}

// 更新昵称
const updateRemark = async () => {
  const result = await proxy.Request({
    url: api.updateRemark,
    params: { remark: remarkForm.remark },
  })
  
  if (result) {
    proxy.Message.success('昵称更新成功')
    showRemarkDialog.value = false
    loadFamilyMembers()
  }
}

// 判断是否可以管理成员（创建者和管理员可以管理普通成员，创建者可以管理所有人）
const canManageMember = (member) => {
  const currentUserId = proxy.VueCookies.get('userInfo').userId
  if (member.userId === currentUserId) return false // 不能管理自己
  
  if (isCreator.value) {
    return member.role !== 0 // 创建者可以管理除自己外的所有人
  }
  
  if (isAdmin.value) {
    return member.role === 2 // 管理员只能管理普通成员
  }
  
  return false
}

// 判断是否可以移出成员
const canRemoveMember = (member) => {
  const currentUserId = proxy.VueCookies.get('userInfo').userId
  if (member.userId === currentUserId) return false // 不能移出自己
  
  if (isCreator.value) {
    return member.role !== 0 // 创建者可以移出除自己外的所有人
  }
  
  if (isAdmin.value) {
    return member.role === 2 // 管理员只能移出普通成员
  }
  
  return false
}

// 打开权限管理对话框
const openPermissionDialog = (member) => {
  selectedMember.value = member
  permissionForm.role = member.role
  showPermissionDialog.value = true
}

// 打开成员备注对话框
const openMemberRemarkDialog = (member) => {
  selectedMember.value = member
  memberRemarkForm.remark = member.remark || ''
  showMemberRemarkDialog.value = true
}

// 更新成员角色
const updateMemberRole = async () => {
  const result = await proxy.Request({
    url: api.updateMemberRole,
    params: {
      userId: selectedMember.value.userId,
      role: permissionForm.role,
    },
  })
  
  if (result) {
    proxy.Message.success('权限更新成功')
    showPermissionDialog.value = false
    loadFamilyMembers()
  }
}

// 更新成员备注
const updateMemberRemark = async () => {
  const result = await proxy.Request({
    url: api.updateMemberRemark,
    params: {
      userId: selectedMember.value.userId,
      remark: memberRemarkForm.remark,
    },
  })
  
  if (result) {
    proxy.Message.success('备注更新成功')
    showMemberRemarkDialog.value = false
    loadFamilyMembers()
  }
}

// 移出成员
const removeMember = (member) => {
  const displayName = member.remark ? `${member.remark}(${member.nickName})` : member.nickName
  
  // 关怀账号需要特殊处理
  if (member.isDummy) {
    selectedMember.value = member
    showRemoveCareAccountDialog.value = true
    removeCareAccountCountdown.value = 5
    // 启动倒计时
    if (removeCareAccountTimer) {
      clearInterval(removeCareAccountTimer)
    }
    removeCareAccountTimer = setInterval(() => {
      removeCareAccountCountdown.value--
      if (removeCareAccountCountdown.value <= 0) {
        clearInterval(removeCareAccountTimer)
        removeCareAccountTimer = null
      }
    }, 1000)
    return
  }
  
  // 普通成员直接移出
  proxy.Confirm(`确定要将 ${displayName} 移出家庭吗？`, async () => {
    const result = await proxy.Request({
      url: api.removeMember,
      params: { userId: member.userId },
    })
    
    if (result) {
      proxy.Message.success('已移出成员')
      loadFamilyMembers()
    }
  })
}

// 确认移除关怀账号（带倒计时）
const confirmRemoveCareAccount = async () => {
  if (removeCareAccountCountdown.value > 0) {
    return
  }
  
  const member = selectedMember.value
  if (!member || !member.isDummy) {
    return
  }
  
  const result = await proxy.Request({
    url: api.removeMember,
    params: { userId: member.userId },
  })
  
  if (result) {
    proxy.Message.success('关怀账号已移出并删除')
    showRemoveCareAccountDialog.value = false
    selectedMember.value = null
    loadFamilyMembers()
  }
}

// 取消移除关怀账号
const cancelRemoveCareAccount = () => {
  showRemoveCareAccountDialog.value = false
  selectedMember.value = null
  if (removeCareAccountTimer) {
    clearInterval(removeCareAccountTimer)
    removeCareAccountTimer = null
  }
}

// 显示添加好友确认对话框
const showAddFriendConfirm = (member) => {
  const displayName = member.remark ? `${member.remark}(${member.nickName})` : member.nickName
  proxy.Confirm(`确定要向 ${displayName} 发送好友申请吗？`, async () => {
    const result = await proxy.Request({
      url: api.sendFriendRequest,
      params: { friendId: member.userId },
    })
    
    if (result) {
      proxy.Message.success('好友申请已发送')
      loadFamilyMembers()
    }
  })
}

// 加载关怀账号列表
const loadCareAccounts = async () => {
  const result = await proxy.Request({
    url: api.getCareAccountList,
    showLoading: false,
  })
  if (result) {
    careAccounts.value = result.data || []
  }
}

// 处理关怀账号头像上传
const handleCareAccountAvatarChange = (file) => {
  careAccountForm.avatar = file
}

// 创建关怀账号
const createCareAccount = async () => {
  if (!careAccountForm.nickName) {
    proxy.Message.warning('请输入昵称')
    return
  }
  
  const formData = new FormData()
  formData.append('nickName', careAccountForm.nickName)
  if (careAccountForm.avatar) {
    formData.append('avatar', careAccountForm.avatar)
  }
  
  const result = await proxy.Request({
    url: api.createCareAccount,
    params: formData,
    dataType: 'file',
  })
  
  if (result) {
    proxy.Message.success('关怀账号创建成功')
    showCreateCareAccountDialog.value = false
    careAccountForm.nickName = ''
    careAccountForm.avatar = null
    if (avatarUploadRef.value) {
      avatarUploadRef.value.reset()
    }
    loadCareAccounts()
    loadFamilyMembers()
  }
}

// 生成登录码
const generateLoginCodeForAccount = async (account) => {
  const result = await proxy.Request({
    url: api.generateLoginCode,
    params: { careAccountId: account.userId },
  })
  
  if (result) {
    currentLoginCode.value = result.data
    showLoginCodeDialog.value = true
    loadCareAccounts()
  }
}

// 复制登录码
const copyLoginCode = async () => {
  try {
    await navigator.clipboard.writeText(currentLoginCode.value)
    proxy.Message.success('登录码已复制到剪贴板')
  } catch (err) {
    const textarea = document.createElement('textarea')
    textarea.value = currentLoginCode.value
    textarea.style.position = 'fixed'
    textarea.style.opacity = '0'
    document.body.appendChild(textarea)
    textarea.select()
    try {
      document.execCommand('copy')
      proxy.Message.success('登录码已复制到剪贴板')
    } catch (e) {
      proxy.Message.error('复制失败，请手动复制')
    }
    document.body.removeChild(textarea)
  }
}

// 确认删除关怀账号
const confirmDeleteCareAccount = (account) => {
  proxy.Confirm(`确定要删除关怀账号【${account.nickName}】吗？删除后将无法恢复。`, async () => {
    const result = await proxy.Request({
      url: api.deleteCareAccount,
      params: { careAccountId: account.userId },
    })
    
    if (result) {
      proxy.Message.success('关怀账号已删除')
      loadCareAccounts()
      loadFamilyMembers()
    }
  })
}

// 格式化文件大小
const formatSize = (size) => {
  if (!size) return '0B'
  const units = ['B', 'KB', 'MB', 'GB']
  let index = 0
  let fileSize = size
  while (fileSize >= 1024 && index < units.length - 1) {
    fileSize /= 1024
    index++
  }
  return fileSize.toFixed(2) + units[index]
}

// 格式化过期时间
const formatExpireTime = (expireTime) => {
  if (!expireTime) return ''
  const now = new Date()
  const expire = new Date(expireTime)
  const diff = expire - now
  const days = Math.floor(diff / (1000 * 60 * 60 * 24))
  const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
  
  if (days > 0) {
    return `${days}天后过期`
  } else if (hours > 0) {
    return `${hours}小时后过期`
  } else {
    return '即将过期'
  }
}

// 监听标签切换
const handleTabChange = () => {
  if (activeTab.value === 'care' && isCreator.value) {
    loadCareAccounts()
  }
}

onMounted(() => {
  currentUserId.value = proxy.VueCookies.get('userInfo').userId
  checkFamily()
})
</script>

<style lang="scss" scoped>
.family-manage {
  padding: 20px;
  background: var(--main-content-bg);
  min-height: calc(100vh - 100px);

  .content-wrapper {
    max-width: 600px;
    margin: 0 auto;
  }

  .custom-btn {
    min-width: 120px;
    padding: 10px 20px;
    border: 2px solid #dcdfe6;
    border-radius: 4px;
    font-size: 14px;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.3s ease;
    color: white;

    &:disabled {
      opacity: 0.6;
      cursor: not-allowed;
    }

    &.btn-generate {
      background-color: #67c23a;
      &:hover:not(:disabled) {
        background-color: #85ce61;
        border-color: #85ce61;
      }
    }

    &.btn-search {
      background-color: #409eff;
      &:hover:not(:disabled) {
        background-color: #66b1ff;
        border-color: #66b1ff;
      }
    }

    &.btn-invite {
      background-color: #e6a23c;
      &:hover:not(:disabled) {
        background-color: #ebb563;
        border-color: #ebb563;
      }
    }

    &.btn-leave {
      background-color: #f56c6c;
      &:hover:not(:disabled) {
        background-color: #f78989;
        border-color: #f78989;
      }
    }
  }

  .welcome-section {
    display: flex;
    flex-direction: column;
    align-items: center;

    .welcome-image {
      width: 100%;
      max-width: 350px;
      height: 280px;
      object-fit: contain;
      margin-bottom: 10px;
    }

    .info-card {
      width: 100%;
      text-align: center;
      background-color: var(--component-bg);
      border-radius: 8px;
      padding: 30px;
      box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);

      .title {
        font-size: 18px;
        font-weight: 600;
        color: var(--text-primary);
        margin-bottom: 10px;
      }

      .description {
        font-size: 14px;
        color: var(--text-secondary);
        margin-bottom: 30px;
      }

      .button-group {
        display: flex;
        gap: 10px;
        justify-content: center;
      }
    }
  }

  .family-content {
    max-width: 1200px;
    margin: 0 auto;

    .tab-buttons {
      display: flex;
      gap: 10px;
      margin-bottom: 20px;
      border-bottom: 2px solid var(--border-light);
      padding-bottom: 0;

      .tab-btn {
        position: relative;
        padding: 12px 24px;
        background: transparent;
        border: none;
        border-bottom: 3px solid transparent;
        color: var(--text-secondary);
        font-size: 15px;
        font-weight: 500;
        cursor: pointer;
        transition: all 0.3s ease;
        margin-bottom: -2px;

        &:hover {
          color: var(--text-primary);
        }

        &.active {
          color: #409eff;
          border-bottom-color: #409eff;
        }

        .badge {
          position: absolute;
          top: 8px;
          right: 8px;
          background: #f56c6c;
          color: white;
          font-size: 12px;
          padding: 2px 6px;
          border-radius: 10px;
          min-width: 18px;
          text-align: center;
        }
      }
    }
  }

  .family-apply-page {
    .empty-state {
      padding: 60px 20px;
      text-align: center;
    }

    .apply-list {
      .apply-item {
        display: flex;
        align-items: center;
        gap: 15px;
        padding: 20px;
        background: var(--component-bg);
        border-radius: 8px;
        margin-bottom: 15px;

        .apply-info {
          flex: 1;

          .apply-name {
            font-weight: 500;
            color: var(--text-primary);
            margin-bottom: 5px;
          }

          .apply-time {
            font-size: 12px;
            color: var(--text-tertiary);
          }
        }

        .apply-actions {
          display: flex;
          gap: 10px;
        }
      }
    }
  }

  .family-info-page {
    .family-header {
      display: flex;
      gap: 30px;
      padding: 30px;
      background: var(--component-bg);
      border-radius: 8px;
      margin-bottom: 20px;

      .family-avatar-section {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 10px;
      }

      .family-details {
        flex: 1;

        .family-title-row {
          display: flex;
          align-items: center;
          gap: 15px;
          margin-bottom: 10px;

          h2 {
            margin: 0;
            color: var(--text-primary);
          }
        }

        .family-desc {
          color: var(--text-secondary);
          margin-bottom: 15px;
        }

        .family-stats {
          display: flex;
          gap: 20px;
          font-size: 14px;
          color: var(--text-tertiary);
          margin-bottom: 15px;
        }

        .family-actions-links {
          display: flex;
          gap: 20px;

          .action-link {
            color: #409eff;
            font-size: 14px;
            cursor: pointer;
            text-decoration: underline;
            transition: color 0.3s ease;

            &:hover {
              color: #66b1ff;
            }
          }
        }
      }
    }

    .family-members {
      padding: 30px;
      background: var(--component-bg);
      border-radius: 8px;
      margin-bottom: 20px;

      h3 {
        margin: 0 0 20px 0;
        color: var(--text-primary);
      }

      .members-list {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
        gap: 15px;

        .member-item {
          display: flex;
          align-items: center;
          gap: 12px;
          padding: 12px;
          background: var(--bg-secondary);
          border-radius: 6px;
          position: relative;

          .member-info {
            flex: 1;

            .member-name {
              font-weight: 500;
              color: var(--text-primary);
            }

            .member-role {
              font-size: 12px;
              color: var(--text-tertiary);
            }
          }

          .add-friend-btn {
            display: flex;
            align-items: center;
            justify-content: center;
            width: 32px;
            height: 32px;
            background: #409eff;
            border-radius: 50%;
            cursor: pointer;
            transition: all 0.3s ease;

            &:hover {
              background: #66b1ff;
              transform: scale(1.1);
            }

            .add-icon {
              color: white;
              font-size: 20px;
              font-weight: bold;
              line-height: 1;
            }
          }

          .forbidden-icon {
            display: flex;
            align-items: center;
            justify-content: center;
            width: 32px;
            height: 32px;
            cursor: not-allowed;
            opacity: 0.6;

            .icon {
              font-size: 24px;
            }
          }
        }
      }
    }

    .family-actions {
      display: flex;
      gap: 10px;
      justify-content: center;
      padding: 20px;
    }
  }

  .search-section {
    margin-bottom: 20px;
  }

  .search-result {
    .family-card {
      display: flex;
      align-items: center;
      gap: 15px;
      padding: 20px;
      background: var(--bg-secondary);
      border-radius: 8px;

      .family-info {
        flex: 1;

        h4 {
          margin: 0 0 5px 0;
        }

        p {
          margin: 5px 0;
          font-size: 14px;
          color: var(--text-secondary);
        }

        .member-count {
          color: var(--text-tertiary);
        }
      }
    }
  }

  .invite-list {
    .invite-item {
      display: flex;
      align-items: center;
      gap: 15px;
      padding: 15px;
      border-bottom: 1px solid var(--border-light);

      &:last-child {
        border-bottom: none;
      }

      .invite-info {
        flex: 1;

        .invite-text {
          margin-bottom: 5px;
        }

        .invite-time {
          font-size: 12px;
          color: var(--text-tertiary);
        }
      }

      .invite-actions {
        display: flex;
        gap: 10px;
      }
    }
  }

  .family-manage-page {
    .manage-members-list {
      .manage-member-item {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 20px;
        background: var(--component-bg);
        border-radius: 8px;
        margin-bottom: 15px;
        transition: all 0.3s ease;

        &:hover {
          box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
        }

        .member-main-info {
          display: flex;
          align-items: center;
          gap: 15px;
          flex: 1;

          .member-details {
            flex: 1;

            .member-name-row {
              display: flex;
              align-items: center;
              gap: 10px;
              margin-bottom: 8px;

              .member-name {
                font-size: 16px;
                font-weight: 500;
                color: var(--text-primary);
              }

              .member-role-tag {
                padding: 2px 8px;
                color: white;
                font-size: 12px;
                border-radius: 4px;

                &.role-creator {
                  background-color: #f59e0b; // 橙色
                }

                &.role-admin {
                  background-color: #10b981; // 绿色
                }

                &.role-member {
                  background-color: #6b7280; // 灰色
                }
              }

              .care-badge {
                margin-left: 5px;
                padding: 2px 8px;
                background: #fef3c7; // 淡黄色背景
                color: #92400e; // 深棕色文字
                border-radius: 4px;
                font-size: 12px;
                font-weight: 500;
                border: 1px solid #fde68a; // 淡黄色边框
              }
            }

            .member-meta {
              display: flex;
              gap: 20px;
              font-size: 13px;
              color: var(--text-tertiary);
            }
          }
        }

        .member-actions {
          display: flex;
          gap: 15px;
          align-items: center;

          .action-icon {
            width: 24px;
            height: 24px;
            cursor: pointer;
            transition: all 0.3s ease;
            opacity: 0.7;

            &:hover {
              opacity: 1;
              transform: scale(1.1);
            }
          }
        }
      }
    }
  }

  .care-account-page {
    .care-account-header {
      display: flex;
      align-items: center;
      gap: 15px;
      margin-bottom: 20px;
      padding: 20px;
      background: var(--component-bg);
      border-radius: 8px;

      .tip {
        color: var(--text-tertiary);
        font-size: 13px;
      }
    }

    .empty-state {
      padding: 60px 20px;
      text-align: center;
    }

    .care-account-list {
      display: flex;
      flex-direction: column;
      gap: 15px;

      .care-account-item {
        display: flex;
        align-items: center;
        gap: 20px;
        padding: 20px;
        background: var(--component-bg);
        border-radius: 8px;
        transition: all 0.3s ease;

        &:hover {
          box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
        }

        .account-info {
          flex: 1;

          .account-name {
            font-size: 16px;
            font-weight: 500;
            color: var(--text-primary);
            margin-bottom: 8px;
          }

          .account-space,
          .account-time,
          .account-code {
            font-size: 13px;
            color: var(--text-tertiary);
            margin-bottom: 4px;
          }

          .account-code {
            color: #409eff;
            font-weight: 500;
          }
        }

        .account-actions {
          display: flex;
          gap: 10px;
        }
      }
    }
  }

  .permission-content {
    .permission-user-info {
      display: flex;
      align-items: center;
      gap: 15px;
      padding: 15px;
      background: var(--bg-secondary);
      border-radius: 8px;
      margin-bottom: 20px;

      .user-info {
        flex: 1;

        .user-name {
          font-size: 16px;
          font-weight: 500;
          color: var(--text-primary);
          margin-bottom: 5px;
        }

        .user-id {
          font-size: 13px;
          color: var(--text-tertiary);
        }
      }
    }
  }

  .code-display {
    text-align: center;
    padding: 20px;

    .code-value {
      font-size: 32px;
      font-weight: bold;
      color: #409eff;
      letter-spacing: 4px;
      margin-bottom: 20px;
      font-family: 'Courier New', monospace;
    }

    .code-tip {
      color: var(--text-secondary);
      margin-bottom: 20px;
      line-height: 1.6;
    }
  }

  // 关怀账号移除确认对话框样式
  .remove-care-account-content {
    padding: 20px;
    text-align: center;

    .warning-icon {
      font-size: 48px;
      margin-bottom: 15px;
    }

    .warning-text {
      margin-bottom: 20px;

      .main-warning {
        font-size: 16px;
        color: var(--text-primary);
        margin-bottom: 10px;

        strong {
          color: #f56c6c;
        }
      }

      .sub-warning {
        font-size: 14px;
        color: var(--text-secondary);
        line-height: 1.6;

        .highlight {
          color: #f56c6c;
          font-weight: bold;
        }
      }
    }

    .countdown-hint {
      font-size: 13px;
      color: var(--text-tertiary);
      padding: 10px;
      background: var(--bg-secondary);
      border-radius: 4px;
    }
  }
}
</style>
