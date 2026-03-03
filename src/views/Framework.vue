<template>
  <div class="framework">
    <div class="header">
      <div class="logo">
        <img src="/icon.png" alt="Homic" class="logo-icon" />
        <span class="name">Homic 家庭云存储服务 v1.0.1</span>
      </div>
      <div class="right-panel">
        <div class="upload-section">
          <span v-if="uploadStats.uploading > 0" class="upload-progress-text">
            上传中 {{ uploadStats.uploading }}/{{ uploadStats.total }}
          </span>
          <div class="upload-icon-wrapper" @click="toggleUploader" ref="uploadIconRef">
            <img :src="uploadIcon" alt="上传" class="upload-icon" />
            <span v-if="uploadStats.uploading > 0" class="upload-badge">{{ uploadStats.uploading }}</span>
          </div>
        </div>

        <!-- 空间信息 -->
        <div class="space-info-header">
          <div class="space-text">
            {{ proxy.Utils.size2Str(useSpaceInfo.useSpace) }} / {{ proxy.Utils.size2Str(useSpaceInfo.totalSpace) }}
          </div>
          <div class="space-percent">
            <el-progress
              :percentage="Math.floor((useSpaceInfo.useSpace / useSpaceInfo.totalSpace) * 10000) / 100"
              :show-text="false"
              :stroke-width="6"
              color="#409eff"
            />
          </div>
          <div class="iconfont icon-refresh" @click="getUseSpace" title="刷新空间使用情况"></div>
        </div>

        <el-dropdown>
          <div class="user-info">
            <div class="avatar">
              <Avatar
                :userId="userInfo.userId"
                :avatar="userInfo.avatar"
                :timestamp="timestamp"
                :width="46"
              ></Avatar>
            </div>
            <span class="nick-name">{{ userInfo.nickName }}</span>
          </div>
          <template #dropdown>
            <el-dropdown-menu>
              <el-dropdown-item @click="updateAvatar">
                修改头像
              </el-dropdown-item>
              <el-dropdown-item @click="updatePassword">
                修改密码
              </el-dropdown-item>
              <el-dropdown-item @click="logout"> 退出 </el-dropdown-item>
            </el-dropdown-menu>
          </template>
        </el-dropdown>
      </div>
    </div>
    <div class="body">
      <div class="left-sider">
        <div class="menu-list">
          <div class="menu-items-wrapper">
            <template v-for="item in menus">
              <div
                v-if="item.allShow || (!item.allShow && userInfo.admin)"
                @click="jump(item)"
                :class="[
                  'menu-item',
                  item.menuCode == currentMenu.menuCode ? 'active' : '',
                ]"
              >
                <div class="icon-wrapper">
                  <img :src="getSideItemIcon(item.icon)" :alt="item.name" class="side-icon" />
                </div>
                <div class="text">
                  {{ item.name }}
                </div>
              </div>
            </template>
          </div>
          
          <!-- 深色模式切换按钮 -->
          <div class="theme-toggle-main">
            <el-tooltip :content="isDark ? '切换为浅色模式' : '切换为深色模式'" placement="right">
              <el-button
                :icon="isDark ? Sunny : Moon"
                circle
                @click="toggleTheme"
                class="theme-btn-main"
              />
            </el-tooltip>
          </div>
        </div>
        <div class="menu-sub-list">
          <div
            @click="handleSubMenuClick($event, sub)"
            :class="['menu-item-sub', currentPath == sub.path ? 'active' : '']"
            v-for="sub in currentMenu.children"
          >
            <img 
              v-if="sub.icon" 
              :src="getSubItemIcon(sub.icon)" 
              :alt="sub.name" 
              class="sub-icon" 
            />
            <span class="text">{{ sub.name }}</span>
          </div>
          <div class="tips" v-if="currentMenu && currentMenu.tips">
            {{ currentMenu.tips }}
          </div>
        </div>
      </div>
      <div class="body-content">
        <router-view v-slot="{ Component }">
          <component
            @addFile="addFile"
            ref="routerViewRef"
            :is="Component"
            @reload="getUseSpace"
          />
        </router-view>
      </div>
    </div>
    <!--修改头像-->
    <UpdateAvatar
      ref="updateAvatarRef"
      @updateAvatar="reloadAvatar"
    ></UpdateAvatar>
    <!--修改密码-->
    <UpdatePassword ref="updatePasswordRef"></UpdatePassword>
    
    <!--上传对话框-->
    <transition name="upload-dialog">
      <div v-if="showUploader" class="upload-dialog-overlay" @click="closeUploader">
        <div 
          class="upload-dialog" 
          :style="dialogStyle"
          @click.stop
        >
          <Uploader
            ref="uploaderRef"
            @uploadCallback="uploadCallbackHandler"
          ></Uploader>
        </div>
      </div>
    </transition>
  </div>
</template>

<script setup>
import UpdateAvatar from "./UpdateAvatar.vue";
import UpdatePassword from "./UpdatePassword.vue";
import Uploader from "@/views/main/Uploader.vue";
import {
  ref,
  reactive,
  getCurrentInstance,
  watch,
  nextTick,
  computed,
  onUnmounted,
} from "vue";
import { useRouter, useRoute } from "vue-router";
import { useThemeStore } from '@/stores/useThemeStore'
import { storeToRefs } from 'pinia'
import { Moon, Sunny } from '@element-plus/icons-vue'

// 导入侧边栏图标
import fileIcon from '@/assets/icon-image/side-item/file.png'
import shareIcon from '@/assets/icon-image/side-item/share.png'
import recoveryIcon from '@/assets/icon-image/side-item/recovery.png'
import settingsIcon from '@/assets/icon-image/side-item/settings.png'
import friendsIcon from '@/assets/icon-image/side-item/friends.png'
import familyIcon from '@/assets/icon-image/side-item/family.png'

// 导入主页子菜单图标
import allIcon from '@/assets/icon-image/main/all.png'
import videoIcon from '@/assets/icon-image/main/video.png'
import musicIcon from '@/assets/icon-image/main/mp3.png'
import imageIcon from '@/assets/icon-image/main/picture.png'
import docIcon from '@/assets/icon-image/main/doc.png'
import othersIcon from '@/assets/icon-image/main/other.png'

// 导入上传图标
import uploadIcon from '@/assets/icon-image/upload-head.png'

const { proxy } = getCurrentInstance();
const router = useRouter();
const route = useRoute();

// 图标映射
const iconMap = {
  file: fileIcon,
  share: shareIcon,
  recovery: recoveryIcon,
  settings: settingsIcon,
  friends: friendsIcon,
  family: familyIcon,
}

// 子菜单图标映射
const subIconMap = {
  all: allIcon,
  video: videoIcon,
  music: musicIcon,
  image: imageIcon,
  doc: docIcon,
  more: othersIcon,
}

// 获取侧边栏图标
const getSideItemIcon = (iconName) => {
  return iconMap[iconName] || fileIcon
}

// 获取子菜单图标
const getSubItemIcon = (iconName) => {
  return subIconMap[iconName] || allIcon
}

// 主题相关
const themeStore = useThemeStore()
const { isDark } = storeToRefs(themeStore)
const toggleTheme = () => {
  themeStore.toggleTheme()
}

const api = {
  getUseSpace: "/getUseSpace",
  logout: "/logout",
};

//显示上传窗口
const showUploader = ref(false);
const uploadIconRef = ref(null);
const dialogStyle = ref({});

// 切换上传对话框
const toggleUploader = () => {
  if (!showUploader.value) {
    // 获取图标位置
    const iconRect = uploadIconRef.value.getBoundingClientRect();
    
    // 设置对话框初始位置（从图标位置开始）
    dialogStyle.value = {
      top: `${iconRect.top + iconRect.height / 2}px`,
      left: `${iconRect.left + iconRect.width / 2}px`,
      transform: 'translate(-50%, -50%) scale(0)',
    };
    
    showUploader.value = true;
    
    // 下一帧开始动画
    nextTick(() => {
      dialogStyle.value = {
        top: '50%',
        left: '50%',
        transform: 'translate(-50%, -50%) scale(1)',
      };
    });
  } else {
    closeUploader();
  }
};

// 关闭上传对话框
const closeUploader = () => {
  if (!uploadIconRef.value) {
    showUploader.value = false;
    return;
  }
  
  // 获取图标位置
  const iconRect = uploadIconRef.value.getBoundingClientRect();
  
  // 动画回到图标位置
  dialogStyle.value = {
    top: `${iconRect.top + iconRect.height / 2}px`,
    left: `${iconRect.left + iconRect.width / 2}px`,
    transform: 'translate(-50%, -50%) scale(0)',
  };
  
  // 等待动画完成后隐藏
  setTimeout(() => {
    showUploader.value = false;
  }, 300);
};

// 上传进度统计
const uploadStats = ref({
  uploading: 0,  // 正在上传的文件数
  total: 0,      // 总文件数
});

// 更新上传统计
const updateUploadStats = () => {
  const uploader = uploaderRef.value;
  if (!uploader || !uploader.fileList) {
    uploadStats.value = { uploading: 0, total: 0 };
    return;
  }
  
  const fileList = uploader.fileList;
  uploadStats.value.total = fileList.length;
  uploadStats.value.uploading = fileList.filter(item => 
    item.status === 'uploading' || item.status === 'init'
  ).length;
};

// 定时更新上传统计
let uploadStatsTimer = null;
const startUploadStatsTimer = () => {
  if (uploadStatsTimer) return;
  uploadStatsTimer = setInterval(() => {
    updateUploadStats();
  }, 500);
};

const stopUploadStatsTimer = () => {
  if (uploadStatsTimer) {
    clearInterval(uploadStatsTimer);
    uploadStatsTimer = null;
  }
};

// 监听上传窗口显示状态
watch(showUploader, (newVal) => {
  if (newVal) {
    startUploadStatsTimer();
  } else {
    stopUploadStatsTimer();
  }
});

// 组件卸载时清理定时器
onUnmounted(() => {
  stopUploadStatsTimer();
});

//添加文件
const uploaderRef = ref();
const addFile = (data) => {
  const { file, filePid } = data;
  
  if (!showUploader.value) {
    // 获取图标位置
    const iconRect = uploadIconRef.value.getBoundingClientRect();
    
    // 设置对话框初始位置
    dialogStyle.value = {
      top: `${iconRect.top + iconRect.height / 2}px`,
      left: `${iconRect.left + iconRect.width / 2}px`,
      transform: 'translate(-50%, -50%) scale(0)',
    };
    
    showUploader.value = true;
    
    // 下一帧开始动画
    nextTick(() => {
      dialogStyle.value = {
        top: '50%',
        left: '50%',
        transform: 'translate(-50%, -50%) scale(1)',
      };
      uploaderRef.value.addFile(file, filePid);
    });
  } else {
    uploaderRef.value.addFile(file, filePid);
  }
};

//上传文件回调
const routerViewRef = ref();
const uploadCallbackHandler = () => {
  nextTick(() => {
    routerViewRef.value.reload();
    getUseSpace();
  });
};

const timestamp = ref(0);
//获取用户信息
const userInfo = ref(proxy.VueCookies.get("userInfo"));

// 完整菜单列表
const fullMenus = [
  {
    icon: "file",
    name: "首页",
    menuCode: "main",
    path: "/main/all",
    allShow: true,
    children: [
      {
        icon: "all",
        name: "全部",
        category: "all",
        path: "/main/all",
      },
      {
        icon: "video",
        name: "视频",
        category: "video",
        path: "/main/video",
      },
      {
        icon: "music",
        name: "音频",
        category: "music",
        path: "/main/music",
      },
      {
        icon: "image",
        name: "图片",
        category: "image",
        path: "/main/image",
      },
      {
        icon: "doc",
        name: "文档",
        category: "doc",
        path: "/main/doc",
      },
      {
        icon: "more",
        name: "其他",
        category: "others",
        path: "/main/others",
      },
    ],
  },
  {
    path: "/friend/myFriends",
    icon: "friends",
    name: "好友",
    menuCode: "friend",
    allShow: true,
    children: [
      {
        name: "我的好友",
        path: "/friend/myFriends",
      },
      {
        name: "搜寻好友",
        path: "/friend/search",
      },
      {
        name: "好友申请",
        path: "/friend/requests",
      },
    ],
  },
  {
    path: "/family",
    icon: "family",
    name: "家庭",
    menuCode: "family",
    allShow: true,
    children: [
      {
        name: "家庭管理",
        path: "/family",
      },
      {
        name: "关怀账号",
        path: "/family/careAccount",
        creatorOnly: true,  // 只有创建者可见
      },
    ],
  },
  {
    path: "/myshare",
    icon: "share",
    name: "分享",
    menuCode: "share",
    allShow: true,
    children: [
      {
        name: "分享记录",
        path: "/myshare",
      },
    ],
  },
  {
    path: "/recycle",
    icon: "recovery",
    name: "回收站",
    menuCode: "recycle",
    tips: "回收站为你保存10天内删除的文件",
    allShow: true,
    children: [
      {
        name: "删除的文件",
        path: "/recycle",
      },
    ],
  },
  {
    path: "/settings/fileList",
    icon: "settings",
    name: "设置",
    menuCode: "settings",
    allShow: false,
    children: [
      {
        name: "用户文件",
        path: "/settings/fileList",
      },
      {
        name: "用户管理",
        path: "/settings/userList",
      },
      {
        path: "/settings/sysSetting",
        name: "系统设置",
      },
    ],
  },
];

// 根据用户类型过滤菜单
const menus = computed(() => {
  // 如果是关怀账号，只显示首页、家庭、回收站
  if (userInfo.value && userInfo.value.isDummy) {
    return fullMenus.filter(menu => 
      menu.menuCode === 'main' || 
      menu.menuCode === 'family' || 
      menu.menuCode === 'recycle'
    );
  }
  // 正常用户显示完整菜单
  return fullMenus;
});

const currentMenu = ref({});
const currentPath = ref();

const jump = (data) => {
  if (!data.path || data.menuCode == currentMenu.value.menuCode) {
    return;
  }
  router.push(data.path);
};

// 处理子菜单点击，添加动画效果
const handleSubMenuClick = (event, data) => {
  const target = event.currentTarget;
  const icon = target.querySelector('.sub-icon');
  const text = target.querySelector('.text');
  
  // 添加点击动画类
  if (icon) icon.classList.add('click-animate');
  if (text) text.classList.add('click-animate');
  
  // 动画结束后移除类
  setTimeout(() => {
    if (icon) icon.classList.remove('click-animate');
    if (text) text.classList.remove('click-animate');
  }, 400);
  
  // 执行跳转
  jump(data);
};

const setMenu = (menuCode, path) => {
  const menu = menus.value.find((item) => {
    return item.menuCode === menuCode;
  });
  currentMenu.value = menu;
  currentPath.value = path;
};

watch(
  () => route,
  (newVal, oldVal) => {
    if (newVal.meta.menuCode) {
      setMenu(newVal.meta.menuCode, newVal.path);
    }
  },
  { immediate: true, deep: true }
);

//修改头像
const updateAvatarRef = ref();
const updateAvatar = () => {
  updateAvatarRef.value.show(userInfo.value);
};
const reloadAvatar = () => {
  userInfo.value = proxy.VueCookies.get("userInfo");
  timestamp.value = new Date().getTime();
};

//修改密码
const updatePasswordRef = ref();
const updatePassword = () => {
  updatePasswordRef.value.show();
};

//退出登录
const logout = () => {
  proxy.Confirm(`你确定要删除退出吗`, async () => {
    let result = await proxy.Request({
      url: api.logout,
    });
    if (!result) {
      return;
    }
    proxy.VueCookies.remove("userInfo");
    router.push("/login");
  });
};

//使用空间
const useSpaceInfo = ref({ useSpace: 0, totalSpace: 1 });
const getUseSpace = async () => {
  let result = await proxy.Request({
    url: api.getUseSpace,
    showLoading: false,
  });
  if (!result) {
    return;
  }
  useSpaceInfo.value = result.data;
};
getUseSpace();
</script>

<style lang="scss" scoped>
.framework {
  background-color: var(--bg-primary);
  color: var(--text-primary);
  min-height: 100vh;
}

.header {
  box-shadow: 0 3px 10px 0 rgb(0 0 0 / 6%);
  height: 56px;
  padding-left: 24px;
  padding-right: 24px;
  position: relative;
  z-index: 200;
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: var(--header-bg);
  border-bottom: 1px solid var(--border-light);

  .logo {
    display: flex;
    align-items: center;
    .logo-icon {
      width: 40px;
      height: 40px;
      object-fit: contain;
    }
    .icon-pan {
      font-size: 40px;
      color: #1296db;
    }
    .name {
      font-weight: bold;
      margin-left: 5px;
      font-size: 25px;
      color: #05a1f5;
    }
  }
  .right-panel {
    display: flex;
    align-items: center;
    gap: 15px;
    
    .upload-section {
      display: flex;
      align-items: center;
      gap: 10px;
      
      .upload-progress-text {
        font-size: 13px;
        color: var(--text-secondary);
        white-space: nowrap;
      }
      
      .upload-icon-wrapper {
        position: relative;
        display: flex;
        align-items: center;
        
        .upload-icon {
          width: 24px;
          height: 24px;
          cursor: pointer;
          transition: all 0.3s ease;
          &:hover {
            transform: scale(1.15);
            opacity: 0.8;
          }
        }
        
        .upload-badge {
          position: absolute;
          top: -8px;
          right: -8px;
          background-color: #f56c6c;
          color: white;
          font-size: 11px;
          font-weight: bold;
          padding: 2px 5px;
          border-radius: 10px;
          min-width: 18px;
          text-align: center;
          box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
        }
      }
    }
    
    .upload-icon {
      width: 24px;
      height: 24px;
      cursor: pointer;
      transition: all 0.3s ease;
      &:hover {
        transform: scale(1.15);
        opacity: 0.8;
      }
    }
    .icon-transfer {
      cursor: pointer;
      color: var(--text-primary);
      font-size: 20px;
      transition: color 0.3s ease;
      &:hover {
        color: #05a1f5;
      }
    }
    
    .space-info-header {
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 8px 15px;
      background: rgba(255, 255, 255, 0.8);
      border-radius: 20px;
      border: 1px solid var(--border-light);
      
      .space-text {
        font-size: 12px;
        color: var(--text-secondary);
        white-space: nowrap;
        min-width: 100px;
      }
      
      .space-percent {
        width: 120px;
        
        :deep(.el-progress-bar__outer) {
          background-color: #e4e7ed;
        }
      }
      
      .iconfont {
        cursor: pointer;
        color: #05a1f5;
        font-size: 16px;
        transition: all 0.3s ease;
        
        &:hover {
          transform: rotate(180deg);
          color: #409eff;
        }
      }
    }
    
    .user-info {
      margin-right: 10px;
      display: flex;
      align-items: center;
      cursor: pointer;
      .avatar {
        margin: 0px 5px 0px 15px;
      }
      .nick-name {
        color: #05a1f5;
      }
    }
  }
}
.body {
  display: flex;
  .left-sider {
    border-right: 1px solid var(--border-light);
    display: flex;
    .menu-list {
      height: calc(100vh - 56px);
      width: 80px;
      box-shadow: 0 3px 10px 0 rgb(0 0 0 / 6%);
      border-right: 1px solid var(--border-light);
      background-color: var(--component-bg);
      display: flex;
      flex-direction: column;
      position: relative;
      
      .menu-items-wrapper {
        flex: 1;
        overflow-y: auto;
      }
      
      .menu-item {
        text-align: center;
        font-size: 14px;
        font-weight: bold;
        padding: 20px 0px;
        cursor: pointer;
        color: var(--text-secondary);
        &:hover {
          background: var(--component-hover-bg);
        }
        .icon-wrapper {
          display: flex;
          justify-content: center;
          align-items: center;
          height: 28px;
          margin-bottom: 5px;
          
          .side-icon {
            width: 28px;
            height: 28px;
            object-fit: contain;
            opacity: 0.67;
            transition: opacity 0.3s ease, transform 0.3s ease;
          }
        }
      }
      .active {
        .side-icon {
          opacity: 1;
          transform: scale(1.3);
        }
        .text {
          color: #06a7ff;
        }
      }
      
      .theme-toggle-main {
        padding: 20px 0;
        display: flex;
        justify-content: center;
        align-items: center;
        border-top: 1px solid var(--border-light);
        background-color: var(--component-bg);
        
        .theme-btn-main {
          padding: 8px;
          min-width: 40px;
          min-height: 40px;
          border-radius: 50%;
          background-color: #f0f0f0;
          border: 1px solid #dcdfe6;
          color: #606266;
          cursor: pointer;
          transition: all 0.3s ease;
          display: flex;
          align-items: center;
          justify-content: center;
          
          &:hover {
            background-color: #e6e6e6;
            border-color: #909399;
            transform: scale(1.1);
          }
          
          &:active {
            background-color: #d9d9d9;
            transform: scale(0.95);
          }
        }
      }
      
      :root.dark-mode & .theme-toggle-main .theme-btn-main {
        background-color: #2f2f2f;
        border-color: #3f3f46;
        color: #e4e4e7;
        
        &:hover {
          background-color: #3f3f46;
          border-color: #52525b;
        }
        
        &:active {
          background-color: #52525b;
        }
      }
    }
    .menu-sub-list {
      width: 150px;
      padding: 20px 10px 0px;
      position: relative;
      background: var(--main-sidebar-bg);
      .menu-item-sub {
        text-align: center;
        line-height: 40px;
        border-radius: 5px;
        cursor: pointer;
        color: var(--text-secondary);
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 8px;
        transition: all 0.3s ease;
        padding: 0 10px;
        &:hover {
          background: var(--component-active-bg);
          padding-left: 5px;
          .sub-icon {
            opacity: 1;
            transform: scale(1.2);
          }
          .text {
            transform: scale(1.2);
            font-weight: 600;
          }
        }
        .sub-icon {
          width: 18px;
          height: 18px;
          object-fit: contain;
          opacity: 0.7;
          transition: all 0.3s ease;
          
          &.click-animate {
            animation: clickBounce 0.4s ease;
          }
        }
        .text {
          font-size: 13px;
          transition: all 0.3s ease;
          
          &.click-animate {
            animation: clickBounce 0.4s ease;
            font-weight: 600;
          }
        }
      }
      .active {
        background: var(--component-active-bg);
        padding-left: 5px;
        .sub-icon {
          opacity: 1;
          transform: scale(1.2);
        }
        .text {
          color: #05a1f5;
          font-weight: 600;
          transform: scale(1.2);
        }
      }
      
      @keyframes clickBounce {
        0% {
          transform: scale(1.2);
        }
        50% {
          transform: scale(1.4);
        }
        100% {
          transform: scale(1.2);
        }
      }

      .tips {
        margin-top: 10px;
        color: var(--text-tertiary);
        font-size: 13px;
      }
    }
  }
  .body-content {
    flex: 1;
    width: 0;
    padding-left: 20px;
    background: var(--main-content-bg);
  }
}

.upload-dialog-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  z-index: 9999;
  display: flex;
  align-items: center;
  justify-content: center;
}

.upload-dialog {
  position: fixed;
  width: 800px;
  max-width: 90vw;
  max-height: 80vh;
  background-color: white;
  border-radius: 8px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
  overflow: hidden;
  transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
  z-index: 10000;
}

.upload-dialog-enter-active {
  transition: opacity 0.3s ease;
}

.upload-dialog-leave-active {
  transition: opacity 0.3s ease;
}

.upload-dialog-enter-from,
.upload-dialog-leave-to {
  opacity: 0;
}
</style>