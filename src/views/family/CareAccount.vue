<template>
  <div class="care-account-container">
    <!-- 权限检查 -->
    <div v-if="!isCreator && familyInfo" class="no-permission">
      <el-empty description="只有家庭创建者可以管理关怀账号">
        <el-button type="primary" @click="router.push('/family')">返回家庭管理</el-button>
      </el-empty>
    </div>

    <div v-else-if="!hasFamily" class="no-family">
      <el-empty description="您还未加入家庭">
        <el-button type="primary" @click="router.push('/family')">前往家庭管理</el-button>
      </el-empty>
    </div>

    <div v-else>
      <div class="care-account-header">
        <el-button type="primary" @click="showCreateDialog = true" :disabled="careAccounts.length >= 5">
          创建关怀账号
        </el-button>
        <span class="tip">已创建 {{ careAccounts.length }}/5 个关怀账号</span>
      </div>

      <div v-if="careAccounts.length === 0" class="no-data">
        <NoData msg="暂无关怀账号"></NoData>
      </div>

      <div v-else class="care-account-list">
        <div v-for="account in careAccounts" :key="account.userId" class="care-account-item">
          <Avatar :userId="account.userId" :avatar="account.avatar" :width="56" />
          <div class="account-info">
            <div class="account-name">{{ account.nickName }}</div>
            <div class="account-space-section">
              <div class="space-text">
                空间: {{ proxy.Utils.size2Str(account.useSpace) }} / {{ proxy.Utils.size2Str(account.totalSpace) }}
                <span class="space-percent">({{ getSpacePercent(account) }}%)</span>
              </div>
              <el-progress 
                :percentage="getSpacePercent(account)" 
                :color="getProgressColor(account)"
                :show-text="false"
                :stroke-width="8"
              />
            </div>
            <div class="account-time">创建时间: {{ account.createTime }}</div>
            <div class="account-status">
              <span class="label">状态:</span>
              <span :class="['status-badge', account.status === 1 ? 'status-active' : 'status-disabled']">
                {{ account.status === 1 ? '正常' : '已禁用' }}
              </span>
            </div>
            <div v-if="account.loginCodeExpireTime" class="account-code-expire">
              <span class="label">登录码过期时间:</span>
              <span :class="['expire-time', { 'expired': isExpired(account.loginCodeExpireTime) }]">
                {{ account.loginCodeExpireTime }}
                <span v-if="!isExpired(account.loginCodeExpireTime)" class="expire-tip">
                  ({{ getExpireTimeText(account.loginCodeExpireTime) }})
                </span>
                <span v-else class="expired-tag">已过期</span>
              </span>
            </div>
          </div>
          <div class="account-actions">
            <div class="action-icon" @click="openLoginCodeDialog(account)" title="获取登录码">
              <img src="@/assets/icon-image/famliy/care/login_code.png" alt="登录码" />
            </div>
            <div 
              :class="['action-icon', 'toggle-status-icon', account.status === 1 ? 'status-enabled' : 'status-disabled']" 
              @click="toggleAccountStatus(account)" 
              :title="account.status === 1 ? '点击禁用账号' : '点击启用账号'"
            >
              <img 
                v-if="account.status === 1"
                src="@/assets/icon-image/famliy/care/unlock.png" 
                alt="启用中" 
              />
              <img 
                v-else
                src="@/assets/icon-image/famliy/care/lock.png" 
                alt="已禁用" 
              />
            </div>
            <div class="action-icon delete-icon" @click="deleteCareAccount(account)" title="删除账号">
              <img src="@/assets/icon-image/famliy/care/delete.png" alt="删除" />
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 创建关怀账号对话框 -->
    <el-dialog v-model="showCreateDialog" title="创建关怀账号" width="500px">
      <el-form :model="careAccountForm" label-width="80px">
        <el-form-item label="昵称">
          <el-input 
            v-model="careAccountForm.nickName" 
            placeholder="请输入昵称" 
            maxlength="50" 
            show-word-limit
          />
        </el-form-item>
        <el-form-item label="头像">
          <AvatarUpload v-model="careAccountForm.avatarFile" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showCreateDialog = false">取消</el-button>
        <el-button type="primary" @click="createCareAccount">创建</el-button>
      </template>
    </el-dialog>

    <!-- 登录码管理对话框 -->
    <el-dialog 
      v-model="showLoginCodeDialog" 
      :title="hasExistingCode ? '登录码管理' : '生成登录码'" 
      width="450px"
      :close-on-click-modal="false"
    >
      <!-- 已有登录码的情况 -->
      <div v-if="hasExistingCode" class="existing-code-section">
        <div class="account-info-header">
          <span class="label">关怀账号：</span>
          <span class="value">{{ currentAccount?.nickName }}</span>
        </div>
        
        <div class="code-display-box">
          <div class="code-label">当前登录码</div>
          <div class="code-value">{{ currentAccount?.loginCode }}</div>
          
          <!-- 二维码显示 -->
          <div v-if="qrCodeDataUrl && !isExpired(currentAccount?.loginCodeExpireTime)" class="qrcode-section">
            <div class="qrcode-label">扫码登录</div>
            <img :src="qrCodeDataUrl" alt="登录二维码" class="qrcode-image" />
          </div>
          
          <div class="expire-info">
            <span class="label">过期时间：</span>
            <span :class="['expire-time', { 'expired': isExpired(currentAccount?.loginCodeExpireTime) }]">
              {{ currentAccount?.loginCodeExpireTime }}
            </span>
          </div>
          <div v-if="!isExpired(currentAccount?.loginCodeExpireTime)" class="expire-countdown">
            剩余时间：{{ countdown }}
          </div>
          <div v-else class="expired-warning">
            <el-alert type="error" :closable="false" show-icon>
              此登录码已过期，请重新生成
            </el-alert>
          </div>
        </div>

        <div class="action-buttons">
          <el-button type="warning" @click="showRegenerateConfirm">
            重新生成
          </el-button>
          <el-button type="success" @click="copyLoginLink">
            复制登录链接
          </el-button>
          <el-button type="primary" @click="copyExistingLoginCode">
            复制登录码
          </el-button>
        </div>
      </div>

      <!-- 没有登录码或生成新登录码的情况 -->
      <div v-else class="generate-code-section">
        <el-form label-width="100px">
          <el-form-item label="关怀账号">
            <span>{{ currentAccount?.nickName }}</span>
          </el-form-item>
          <el-form-item label="有效时间">
            <el-select v-model="selectedValidTime" placeholder="请选择有效时间" style="width: 100%">
              <el-option label="8小时" :value="0"></el-option>
              <el-option label="16小时" :value="1"></el-option>
              <el-option label="1天" :value="2"></el-option>
              <el-option label="3天" :value="3"></el-option>
              <el-option label="7天" :value="4"></el-option>
            </el-select>
          </el-form-item>
        </el-form>
      </div>

      <template #footer>
        <div v-if="!hasExistingCode">
          <el-button @click="showLoginCodeDialog = false">取消</el-button>
          <el-button type="primary" @click="generateLoginCode">生成</el-button>
        </div>
      </template>
    </el-dialog>

    <!-- 新生成的登录码显示对话框 -->
    <el-dialog v-model="showNewCodeDialog" title="登录码生成成功" width="450px">
      <div class="login-code-display">
        <div class="code-value">{{ newGeneratedCode }}</div>
        <p class="code-tip">此登录码{{ getValidTimeText() }}内有效，请妥善保管</p>
        
        <!-- 二维码显示 -->
        <div v-if="qrCodeDataUrl" class="qrcode-section">
          <div class="qrcode-label">扫码登录</div>
          <img :src="qrCodeDataUrl" alt="登录二维码" class="qrcode-image" />
          <div class="qrcode-tip">使用手机扫描二维码即可登录</div>
        </div>
        
        <div class="button-group">
          <el-button type="success" @click="copyNewLoginLink" style="width: 48%;">
            复制登录链接
          </el-button>
          <el-button type="primary" @click="copyNewLoginCode" style="width: 48%;">
            复制登录码
          </el-button>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, getCurrentInstance, onMounted, nextTick, computed, watch, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import QRCode from 'qrcode';
import Avatar from '@/components/Avatar.vue';
import AvatarUpload from '@/components/AvatarUpload.vue';
import NoData from '@/components/NoData.vue';

const { proxy } = getCurrentInstance();
const router = useRouter();

const api = {
  checkFamily: '/family/checkFamily',
  getFamilyInfo: '/family/getFamilyInfo',
  create: '/careAccount/create',
  list: '/careAccount/list',
  generateLoginCode: '/careAccount/generateLoginCode',
  delete: '/careAccount/delete',
  toggleStatus: '/careAccount/toggleStatus',
};

const hasFamily = ref(false);
const familyInfo = ref(null);
const isCreator = ref(false);
const careAccounts = ref([]);
const showCreateDialog = ref(false);
const showLoginCodeDialog = ref(false);
const showNewCodeDialog = ref(false);
const hasExistingCode = ref(false);
const newGeneratedCode = ref('');
const currentAccount = ref(null);
const selectedValidTime = ref(4); // 默认7天
const currentUserId = ref('');
const qrCodeDataUrl = ref(''); // 二维码图片数据
const countdown = ref(''); // 倒计时文本
let countdownTimer = null; // 倒计时定时器

const careAccountForm = reactive({
  nickName: '',
  avatarFile: null,
});

// 检查家庭状态
const checkFamily = async () => {
  const result = await proxy.Request({
    url: api.checkFamily,
    showLoading: false,
  });
  if (!result) return;
  
  hasFamily.value = result.data.hasFamily;
  if (hasFamily.value) {
    await loadFamilyInfo();
  }
};

// 加载家庭信息
const loadFamilyInfo = async () => {
  const result = await proxy.Request({
    url: api.getFamilyInfo,
    showLoading: false,
  });
  if (!result) return;
  
  familyInfo.value = result.data;
  isCreator.value = result.data.creatorId === currentUserId.value;
  
  if (isCreator.value) {
    loadCareAccounts();
  }
};

// 获取关怀账号列表
const loadCareAccounts = async () => {
  const result = await proxy.Request({
    url: api.list,
    showLoading: false,
  });
  if (!result) return;
  careAccounts.value = result.data || [];
};

// 创建关怀账号
const createCareAccount = async () => {
  if (!careAccountForm.nickName.trim()) {
    proxy.Message.warning('请输入昵称');
    return;
  }

  // 构建参数对象，与UserList.vue保持一致
  const params = {
    nickName: careAccountForm.nickName,
  };
  
  // 如果有头像文件，添加到参数中
  if (careAccountForm.avatarFile) {
    params.avatar = careAccountForm.avatarFile;
  }

  const result = await proxy.Request({
    url: api.create,
    params: params,
  });

  if (!result) return;

  proxy.Message.success('创建成功');
  showCreateDialog.value = false;
  careAccountForm.nickName = '';
  careAccountForm.avatarFile = null;
  
  loadCareAccounts();
};

// 打开登录码对话框
const openLoginCodeDialog = async (account) => {
  currentAccount.value = account;
  selectedValidTime.value = 4; // 默认7天
  
  // 检查是否已有登录码
  if (account.loginCode && account.loginCodeExpireTime) {
    hasExistingCode.value = true;
    // 生成二维码
    await generateQRCode(account.loginCode);
    // 启动倒计时
    startCountdown(account.loginCodeExpireTime);
  } else {
    hasExistingCode.value = false;
    qrCodeDataUrl.value = '';
    stopCountdown();
  }
  
  showLoginCodeDialog.value = true;
};

// 启动倒计时
const startCountdown = (expireTime) => {
  stopCountdown(); // 先清除之前的定时器
  
  const updateCountdown = () => {
    if (!expireTime) {
      countdown.value = '';
      return;
    }
    
    const now = new Date();
    const expire = new Date(expireTime);
    const diff = expire - now;
    
    if (diff <= 0) {
      countdown.value = '已过期';
      stopCountdown();
      return;
    }
    
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));
    const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
    const seconds = Math.floor((diff % (1000 * 60)) / 1000);
    
    if (days > 0) {
      countdown.value = `${days}天 ${hours}小时 ${minutes}分钟 ${seconds}秒`;
    } else if (hours > 0) {
      countdown.value = `${hours}小时 ${minutes}分钟 ${seconds}秒`;
    } else if (minutes > 0) {
      countdown.value = `${minutes}分钟 ${seconds}秒`;
    } else {
      countdown.value = `${seconds}秒`;
    }
  };
  
  updateCountdown(); // 立即执行一次
  countdownTimer = setInterval(updateCountdown, 1000); // 每秒更新
};

// 停止倒计时
const stopCountdown = () => {
  if (countdownTimer) {
    clearInterval(countdownTimer);
    countdownTimer = null;
  }
};

// 监听对话框关闭，停止倒计时
watch(showLoginCodeDialog, (newVal) => {
  if (!newVal) {
    stopCountdown();
  }
});

// 显示重新生成确认
const showRegenerateConfirm = () => {
  proxy.Confirm(
    '重新生成登录码将使当前登录码失效，是否继续？',
    () => {
      hasExistingCode.value = false;
    }
  );
};

// 生成登录码
const generateLoginCode = async () => {
  const result = await proxy.Request({
    url: api.generateLoginCode,
    params: {
      careAccountId: currentAccount.value.userId,
      validType: selectedValidTime.value,
    },
  });

  if (!result) return;

  newGeneratedCode.value = result.data;
  showLoginCodeDialog.value = false;
  
  // 生成二维码
  await generateQRCode(result.data);
  
  showNewCodeDialog.value = true;
  
  // 重新加载列表以更新过期时间
  loadCareAccounts();
};

// 获取有效时间文本
const getValidTimeText = () => {
  const timeMap = {
    0: '8小时',
    1: '16小时',
    2: '1天',
    3: '3天',
    4: '7天',
  };
  return timeMap[selectedValidTime.value] || '7天';
};

// 复制已存在的登录码
const copyExistingLoginCode = () => {
  copyToClipboard(currentAccount.value.loginCode);
};

// 复制已存在的登录链接
const copyLoginLink = () => {
  const loginUrl = generateLoginUrl(currentAccount.value.loginCode);
  copyToClipboard(loginUrl);
};

// 复制新生成的登录码
const copyNewLoginCode = () => {
  copyToClipboard(newGeneratedCode.value);
};

// 复制新生成的登录链接
const copyNewLoginLink = () => {
  const loginUrl = generateLoginUrl(newGeneratedCode.value);
  copyToClipboard(loginUrl);
};

// 生成登录链接
const generateLoginUrl = (loginCode) => {
  // 获取当前域名和协议
  const origin = window.location.origin;
  // 拼接登录链接
  return `${origin}/login?code=${loginCode}`;
};

// 生成二维码
const generateQRCode = async (loginCode) => {
  try {
    const loginUrl = generateLoginUrl(loginCode);
    // 生成二维码，返回 Data URL
    qrCodeDataUrl.value = await QRCode.toDataURL(loginUrl, {
      width: 200,
      margin: 2,
      color: {
        dark: '#000000',
        light: '#FFFFFF'
      }
    });
  } catch (err) {
    console.error('生成二维码失败:', err);
    proxy.Message.error('生成二维码失败');
  }
};

// 通用复制方法
const copyToClipboard = (text) => {
  // 尝试使用现代 Clipboard API
  if (navigator.clipboard && navigator.clipboard.writeText) {
    navigator.clipboard.writeText(text)
      .then(() => {
        // 判断是链接还是登录码
        const message = text.startsWith('http') ? '登录链接已复制到剪贴板' : '登录码已复制到剪贴板';
        proxy.Message.success(message);
      })
      .catch(() => {
        fallbackCopy(text);
      });
  } else {
    fallbackCopy(text);
  }
};

// 降级复制方案
const fallbackCopy = (text) => {
  try {
    const textarea = document.createElement('textarea');
    textarea.value = text;
    textarea.style.position = 'fixed';
    textarea.style.top = '0';
    textarea.style.left = '0';
    textarea.style.opacity = '0';
    document.body.appendChild(textarea);
    
    textarea.focus();
    textarea.select();
    
    const successful = document.execCommand('copy');
    document.body.removeChild(textarea);
    
    if (successful) {
      const message = text.startsWith('http') ? '登录链接已复制到剪贴板' : '登录码已复制到剪贴板';
      proxy.Message.success(message);
    } else {
      proxy.Message.error('复制失败，请手动复制');
    }
  } catch (err) {
    console.error('复制失败:', err);
    proxy.Message.error('复制失败，请手动复制');
  }
};

// 切换账号状态
const toggleAccountStatus = (account) => {
  const action = account.status === 1 ? '禁用' : '启用';
  const newStatus = account.status === 1 ? 0 : 1;
  
  proxy.Confirm(
    `确定要${action}关怀账号"${account.nickName}"吗？${action === '禁用' ? '禁用后该账号将无法登录。' : ''}`,
    async () => {
      const result = await proxy.Request({
        url: api.toggleStatus,
        params: {
          careAccountId: account.userId,
          status: newStatus,
        },
      });

      if (!result) return;

      proxy.Message.success(`${action}成功`);
      loadCareAccounts();
    }
  );
};

// 删除关怀账号
const deleteCareAccount = (account) => {
  proxy.Confirm(`确定要删除关怀账号"${account.nickName}"吗？`, async () => {
    const result = await proxy.Request({
      url: api.delete,
      params: {
        careAccountId: account.userId,
      },
    });

    if (!result) return;

    proxy.Message.success('删除成功');
    loadCareAccounts();
  });
};

// 计算空间使用百分比
const getSpacePercent = (account) => {
  if (!account.totalSpace || account.totalSpace === 0) return 0;
  const percent = (account.useSpace / account.totalSpace) * 100;
  return Math.min(Math.round(percent), 100);
};

// 获取进度条颜色
const getProgressColor = (account) => {
  const percent = getSpacePercent(account);
  if (percent >= 90) return '#f56c6c'; // 红色
  if (percent >= 70) return '#e6a23c'; // 橙色
  return '#67c23a'; // 绿色
};

// 判断是否已过期
const isExpired = (expireTime) => {
  if (!expireTime) return true;
  return new Date(expireTime) < new Date();
};

// 获取过期时间文本
const getExpireTimeText = (expireTime) => {
  if (!expireTime) return '';
  const now = new Date();
  const expire = new Date(expireTime);
  const diff = expire - now;
  
  if (diff <= 0) return '已过期';
  
  const days = Math.floor(diff / (1000 * 60 * 60 * 24));
  const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
  const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
  
  if (days > 0) {
    return `${days}天${hours}小时后过期`;
  } else if (hours > 0) {
    return `${hours}小时${minutes}分钟后过期`;
  } else {
    return `${minutes}分钟后过期`;
  }
};

onMounted(() => {
  currentUserId.value = proxy.VueCookies.get('userInfo').userId;
  checkFamily();
});

// 组件卸载时清除定时器
onUnmounted(() => {
  stopCountdown();
});
</script>

<style lang="scss" scoped>
.care-account-container {
  padding: 20px;
  background: var(--component-bg);
  border-radius: 8px;
  min-height: calc(100vh - 120px);
}

.no-permission,
.no-family {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 400px;
}

.care-account-header {
  display: flex;
  align-items: center;
  gap: 15px;
  margin-bottom: 20px;
  padding-bottom: 15px;
  border-bottom: 1px solid var(--border-light);

  .tip {
    color: var(--text-secondary);
    font-size: 14px;
  }
}

.no-data {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 400px;
}

.care-account-list {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.care-account-item {
  display: flex;
  align-items: center;
  padding: 20px;
  background: var(--main-content-bg);
  border: 1px solid var(--border-light);
  border-radius: 8px;
  transition: all 0.3s ease;

  &:hover {
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
    transform: translateY(-2px);
  }

  .account-info {
    flex: 1;
    margin-left: 20px;

    .account-name {
      font-size: 16px;
      font-weight: 600;
      color: var(--text-primary);
      margin-bottom: 10px;
    }

    .account-space-section {
      margin-bottom: 10px;
      max-width: 300px;

      .space-text {
        font-size: 13px;
        color: var(--text-secondary);
        margin-bottom: 6px;
        display: flex;
        align-items: center;
        gap: 5px;

        .space-percent {
          font-weight: 600;
          color: var(--text-primary);
        }
      }
    }

    .account-time {
      font-size: 12px;
      color: var(--text-tertiary);
      margin-bottom: 5px;
    }

    .account-status {
      font-size: 12px;
      margin-bottom: 5px;
      display: flex;
      align-items: center;
      gap: 8px;

      .label {
        font-weight: 500;
        color: var(--text-tertiary);
      }

      .status-badge {
        padding: 2px 10px;
        border-radius: 12px;
        font-size: 11px;
        font-weight: 600;
        letter-spacing: 0.5px;

        &.status-active {
          background: #e8f5e9;
          color: #2e7d32;
        }

        &.status-disabled {
          background: #ffebee;
          color: #c62828;
        }
      }
    }

    .account-code-expire {
      font-size: 12px;
      color: var(--text-tertiary);
      display: flex;
      align-items: center;
      gap: 5px;

      .label {
        font-weight: 500;
      }

      .expire-time {
        color: var(--text-secondary);

        &.expired {
          color: #f56c6c;
        }

        .expire-tip {
          color: #67c23a;
          font-weight: 500;
        }

        .expired-tag {
          color: #f56c6c;
          font-weight: 600;
        }
      }
    }
  }

  .account-actions {
    display: flex;
    gap: 15px;
    align-items: center;

    .action-icon {
      width: 36px;
      height: 36px;
      cursor: pointer;
      transition: all 0.3s ease;
      display: flex;
      align-items: center;
      justify-content: center;
      border-radius: 8px;
      background: var(--bg-secondary);
      padding: 7px;
      position: relative;

      &:hover {
        transform: translateY(-3px);
        box-shadow: 0 6px 12px rgba(0, 0, 0, 0.15);
      }

      img {
        width: 100%;
        height: 100%;
        object-fit: contain;
        transition: all 0.3s ease;
      }

      &:active {
        transform: translateY(-1px);
      }

      // 登录码按钮
      &:first-child:hover {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        
        img {
          filter: brightness(0) invert(1);
        }
      }

      // 禁用/启用按钮
      &.toggle-status-icon {
        &.status-enabled {
          background: #e8f5e9;
          
          &:hover {
            background: linear-gradient(135deg, #66bb6a 0%, #43a047 100%);
            
            img {
              filter: brightness(0) invert(1);
            }
          }
        }

        &.status-disabled {
          background: #ffebee;
          
          &:hover {
            background: linear-gradient(135deg, #ef5350 0%, #e53935 100%);
            
            img {
              filter: brightness(0) invert(1);
            }
          }
        }
      }

      // 删除按钮
      &.delete-icon:hover {
        background: linear-gradient(135deg, #f56c6c 0%, #e53935 100%);
        
        img {
          filter: brightness(0) invert(1);
        }
      }
    }
  }
}

.existing-code-section {
  .account-info-header {
    margin-bottom: 15px;
    padding: 10px 12px;
    background: var(--bg-secondary);
    border-radius: 6px;

    .label {
      font-weight: 500;
      color: var(--text-secondary);
    }

    .value {
      font-weight: 600;
      color: var(--text-primary);
      margin-left: 5px;
    }
  }

  .code-display-box {
    padding: 18px;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    border-radius: 12px;
    margin-bottom: 15px;
    box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);

    .code-label {
      font-size: 12px;
      color: rgba(255, 255, 255, 0.8);
      margin-bottom: 8px;
      text-transform: uppercase;
      letter-spacing: 1px;
    }

    .code-value {
      font-size: 36px;
      font-weight: bold;
      color: white;
      letter-spacing: 8px;
      margin-bottom: 12px;
      font-family: 'Courier New', monospace;
      text-align: center;
      text-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
    }

    .expire-info {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 5px;
      margin-bottom: 6px;

      .label {
        font-size: 13px;
        color: rgba(255, 255, 255, 0.9);
      }

      .expire-time {
        font-size: 13px;
        color: white;
        font-weight: 500;

        &.expired {
          color: #fca5a5;
        }
      }
    }

    .expire-countdown {
      text-align: center;
      font-size: 16px;
      color: #86efac;
      font-weight: 700;
      margin-top: 8px;
      padding: 8px;
      background: rgba(134, 239, 172, 0.1);
      border-radius: 6px;
      letter-spacing: 1px;
      font-family: 'Courier New', monospace;
    }

    .expired-warning {
      margin-top: 8px;
    }
  }

  .qrcode-section {
    margin: 15px 0 12px 0;
    text-align: center;
    padding: 12px;
    background: rgba(255, 255, 255, 0.1);
    border-radius: 12px;

    .qrcode-label {
      font-size: 12px;
      color: rgba(255, 255, 255, 0.9);
      margin-bottom: 10px;
      font-weight: 500;
      text-transform: uppercase;
      letter-spacing: 1px;
    }

    .qrcode-image {
      width: 160px;
      height: 160px;
      border: 3px solid rgba(255, 255, 255, 0.9);
      border-radius: 8px;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
      background: white;
    }
  }

  .action-buttons {
    display: flex;
    gap: 10px;
    justify-content: center;
    flex-wrap: wrap;
  }
}

.generate-code-section {
  // 保持原有样式
}

.login-code-display {
  text-align: center;
  padding: 20px;

  .code-value {
    font-size: 36px;
    font-weight: bold;
    color: #409eff;
    letter-spacing: 8px;
    margin-bottom: 20px;
    padding: 25px;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    border-radius: 12px;
    font-family: 'Courier New', monospace;
    box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
  }

  .code-tip {
    color: var(--text-secondary);
    font-size: 14px;
    margin-bottom: 20px;
    line-height: 1.6;
  }

  .button-group {
    display: flex;
    gap: 4%;
    justify-content: space-between;
  }

  .qrcode-section {
    margin: 20px 0;
    text-align: center;
    padding: 20px;
    background: var(--bg-secondary);
    border-radius: 12px;

    .qrcode-label {
      font-size: 14px;
      font-weight: 600;
      color: var(--text-primary);
      margin-bottom: 15px;
    }

    .qrcode-image {
      width: 200px;
      height: 200px;
      border: 3px solid #fff;
      border-radius: 8px;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
      background: white;
    }

    .qrcode-tip {
      margin-top: 12px;
      font-size: 12px;
      color: var(--text-secondary);
    }
  }
}
</style>
