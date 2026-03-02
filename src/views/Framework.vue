<template>
  <div class="framework">
    <div class="header">
      <div class="logo">
        <img src="/icon.png" alt="Homic" class="logo-icon" />
        <span class="name">Homic 家庭云存储服务 v1.0.1</span>
      </div>
      <div class="right-panel">
        <el-popover
          :width="800"
          trigger="click"
          v-model:visible="showUploader"
          :offset="20"
          transition="none"
          :hide-after="0"
          :popper-style="{ padding: '0px' }"
        >
          <template #reference>
            <span class="iconfont icon-transfer"></span>
          </template>
          <template #default>
            <Uploader
              ref="uploaderRef"
              @uploadCallback="uploadCallbackHandler"
            ></Uploader>
          </template>
        </el-popover>

        <el-tooltip :content="isDark ? '切换为浅色模式' : '切换为深色模式'" placement="bottom">
          <el-button
            :icon="isDark ? Sunny : Moon"
            circle
            @click="toggleTheme"
            class="theme-btn"
          />
        </el-tooltip>

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
        <div class="menu-sub-list">
          <div
            @click="jump(sub)"
            :class="['menu-item-sub', currentPath == sub.path ? 'active' : '']"
            v-for="sub in currentMenu.children"
          >
            <span
              :class="['iconfont', 'icon-' + sub.icon]"
              v-if="sub.icon"
            ></span>
            <span class="text">{{ sub.name }}</span>
          </div>
          <div class="tips" v-if="currentMenu && currentMenu.tips">
            {{ currentMenu.tips }}
          </div>
          <div class="space-info">
            <div>空间使用</div>
            <div class="percent">
              <el-progress
                :percentage="
                  Math.floor(
                    (useSpaceInfo.useSpace / useSpaceInfo.totalSpace) * 10000
                  ) / 100
                "
                color="#409eff"
              />
            </div>

            <div class="space-use">
              <div class="use">
                {{ proxy.Utils.size2Str(useSpaceInfo.useSpace) }}/
                {{ proxy.Utils.size2Str(useSpaceInfo.totalSpace) }}
              </div>
              <div class="iconfont icon-refresh" @click="getUseSpace"></div>
            </div>
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

// 获取侧边栏图标
const getSideItemIcon = (iconName) => {
  return iconMap[iconName] || fileIcon
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

//添加文件
const uploaderRef = ref();
const addFile = (data) => {
  const { file, filePid } = data;
  showUploader.value = true;
  uploaderRef.value.addFile(file, filePid);
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
const menus = [
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

const currentMenu = ref({});
const currentPath = ref();

const jump = (data) => {
  if (!data.path || data.menuCode == currentMenu.value.menuCode) {
    return;
  }
  router.push(data.path);
};

const setMenu = (menuCode, path) => {
  const menu = menus.find((item) => {
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
  background-color: var(--component-bg);
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
    .icon-transfer {
      cursor: pointer;
      color: var(--text-primary);
      font-size: 20px;
      transition: color 0.3s ease;
      &:hover {
        color: #05a1f5;
      }
    }
    .theme-btn {
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
      }
      
      &:active {
        background-color: #d9d9d9;
      }
    }
    
    :root.dark-mode & .theme-btn {
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
    }
    .menu-sub-list {
      width: 200px;
      padding: 20px 10px 0px;
      position: relative;
      background-color: var(--bg-secondary);
      .menu-item-sub {
        text-align: center;
        line-height: 40px;
        border-radius: 5px;
        cursor: pointer;
        color: var(--text-secondary);
        &:hover {
          background: var(--component-hover-bg);
        }
        .iconfont {
          font-size: 14px;
          margin-right: 20px;
        }
        .text {
          font-size: 13px;
        }
      }
      .active {
        background: #eef9fe;
        .iconfont {
          color: #05a1f5;
        }
        .text {
          color: #05a1f5;
        }
      }

      .tips {
        margin-top: 10px;
        color: var(--text-tertiary);
        font-size: 13px;
      }

      .space-info {
        position: absolute;
        bottom: 10px;
        width: 100%;
        padding: 0px 5px;
        .percent {
          padding-right: 10px;
        }
        .space-use {
          margin-top: 5px;
          color: var(--text-tertiary);
          display: flex;
          justify-content: space-around;
          .use {
            flex: 1;
          }
          .iconfont {
            cursor: pointer;
            margin-right: 20px;
            color: #05a1f5;
          }
        }
      }
    }
  }
  .body-content {
    flex: 1;
    width: 0;
    padding-left: 20px;
    background-color: var(--bg-primary);
  }
}
</style>