<template>
  <div class="top-navigation">
    <template v-if="folderList.length > 0">
      <span class="back link" @click="backParent">返回上一级</span>
      <el-divider direction="vertical" />
    </template>
    <span v-if="folderList.length == 0" class="all-file">全部文件</span>
    <span
      class="link"
      @click="setCurrentFolder(-1)"
      v-if="folderList.length > 0"
      >全部文件</span
    >
    <template v-for="(item, index) in folderList">
      <span class="iconfont icon-right"></span>
      <span
        class="link"
        @click="setCurrentFolder(index)"
        v-if="index < folderList.length - 1"
        >{{ item.fileName }}</span
      >
      <span v-if="index == folderList.length - 1" class="text">{{
        item.fileName
      }}</span>
    </template>
  </div>
</template>

<script setup>
import { ref, reactive, getCurrentInstance, watch } from "vue";
import { useRouter, useRoute } from "vue-router";
const { proxy } = getCurrentInstance();
const router = useRouter();
const route = useRoute();

const props = defineProps({
  watchPath: {
    type: Boolean, //是否监听路径变化
    default: true,
  },
  shareId: {
    type: String,
  },
  adminShow: {
    type: Boolean,
    default: false,
  },
  familyId: {
    type: String,
    default: null,
  },
});

const api = {
  getFolderInfo: "/file/getFolderInfo",
  getFolderInfo4Share: "/showShare/getFolderInfo",
  getFolderInfo4Admin: "/admin/getFolderInfo",
};

//分类
const category = ref();
//目录
const folderList = ref([]);
//当前目录
const currentFolder = ref({ fileId: "0" });

//初始化
const init = () => {
  folderList.value = [];
  currentFolder.value = { fileId: "0" };
  doCallback();
};

//点击目录
const openFolder = (data) => {
  const { fileId, fileName } = data;
  const folder = {
    fileName: fileName,
    fileId: fileId,
  };
  folderList.value.push(folder);
  currentFolder.value = folder;
  setPath();
};

defineExpose({ openFolder, init });

//返回上一级
const backParent = () => {
  let currentIndex = null;
  for (let i = 0; i < folderList.value.length; i++) {
    if (folderList.value[i].fileId == currentFolder.value.fileId) {
      currentIndex = i;
      break;
    }
  }
  setCurrentFolder(currentIndex - 1);
};

//点击导航 设置当前目录
const setCurrentFolder = (index) => {
  if (index == -1) {
    //返回全部
    currentFolder.value = { fileId: "0" };
    folderList.value = [];
  } else {
    currentFolder.value = folderList.value[index];
    folderList.value.splice(index + 1, folderList.value.length);
  }
  setPath();
};

//设置URL路径
const setPath = () => {
  if (!props.watchPath) {
    doCallback();
    return;
  }
  let pathArray = [];
  folderList.value.forEach((item) => {
    pathArray.push(item.fileId);
  });
  router.push({
    path: route.path,
    query:
      pathArray.length == 0
        ? ""
        : {
            path: pathArray.join("/"),
          },
  });
};

//获取当前路径的目录
const getNavigationFolder = async (path) => {
  // 家庭空间模式下，不调用后端API，完全依赖本地状态管理
  if (props.familyId) {
    return;
  }

  let url = api.getFolderInfo;
  if (props.shareId) {
    url = api.getFolderInfo4Share;
  }
  if (props.adminShow) {
    url = api.getFolderInfo4Admin;
  }

  let result = await proxy.Request({
    url: url,
    showLoading: false,
    params: {
      path: path,
      shareId: props.shareId,
    },
  });
  if (!result) {
    return;
  }
  folderList.value = result.data;
};

const emit = defineEmits(["navChange"]);
const doCallback = () => {
  emit("navChange", {
    categoryId: category.value,
    curFolder: currentFolder.value,
  });
};

watch(
  () => route,
  (newVal, oldVal) => {
    if (!props.watchPath) {
      return;
    }
    //路由切换到其他路由  首页和管理员查看文件列表页面需要监听
    if (
      newVal.path.indexOf("/main") === -1 &&
      newVal.path.indexOf("/settings/fileList") === -1 &&
      newVal.path.indexOf("/share") === -1 &&
      newVal.path.indexOf("/family") === -1
    ) {
      return;
    }
    const path = newVal.query.path;
    const categoryId = newVal.params.category;
    category.value = categoryId;
    if (path == undefined) {
      init();
    } else {
      getNavigationFolder(path);
      //设置当前目录
      let pathArray = path.split("/");
      currentFolder.value = {
        fileId: pathArray[pathArray.length - 1],
      };
      doCallback();
    }
  },
  { immediate: true, deep: true }
);
</script>

<style lang="scss" scoped>
.top-navigation {
  font-size: 13px;
  display: flex;
  align-items: center;
  line-height: 30px;
  padding: 0;
  margin: 0;
  
  .all-file {
    font-weight: 600;
    color: var(--text-primary);
  }
  .link {
    color: #06a7ff;
    cursor: pointer;
    transition: all 0.3s ease;
    
    &:hover {
      color: #409eff;
      text-decoration: underline;
    }
  }
  .back {
    margin-right: 5px;
  }
  .icon-right {
    color: var(--text-tertiary);
    padding: 0px 5px;
    font-size: 13px;
  }
  .text {
    color: var(--text-primary);
    font-weight: 500;
  }
}
</style>