<template>
  <div @contextmenu="handleContextMenu">
    <div class="top">
      <div class="top-op">
        <div class="btn">
          <el-upload
            :show-file-list="false"
            :with-credentials="true"
            :multiple="true"
            :http-request="addFile"
            :accept="fileAccept"
          >
            <el-button type="primary">
              <span class="iconfont icon-upload"></span>
              上传
            </el-button>
          </el-upload>
        </div>
        <el-button type="success" @click="newFolder" v-if="category == 'all'">
          <span class="iconfont icon-folder-add"></span>
          新建文件夹
        </el-button>
        <div class="search-panel">
          <el-input
            clearable
            placeholder="输入文件名搜索"
            v-model="fileNameFuzzy"
            @keyup.enter="search"
          >
            <template #suffix>
              <i class="iconfont icon-search" @click="search"></i>
            </template>
          </el-input>
        </div>
        <el-select v-model="sortType" placeholder="排序方式" @change="sortFiles" style="width: 150px; margin-left: 10px;">
          <el-option label="按名称排序" value="name"></el-option>
          <el-option label="按创建时间" value="createTime"></el-option>
          <el-option label="按修改时间" value="updateTime"></el-option>
          <el-option label="按文件类型" value="type"></el-option>
        </el-select>
        <div class="sort-btn-wrapper" @click="toggleSortOrder" :title="getSortOrderTitle()">
          <img :src="getSortIcon()" alt="排序" class="sort-icon" />
        </div>
        <div class="iconfont icon-refresh" @click="loadDataList"></div>
      </div>
      <!--导航-->
      <Navigation ref="navigationRef" @navChange="navChange"></Navigation>
    </div>
    <div class="file-list" v-if="tableData.list && tableData.list.length > 0" @contextmenu="handleContextMenu">
      <Table
        ref="dataTableRef"
        :columns="columns"
        :showPagination="true"
        :dataSource="tableData"
        :fetch="loadDataList"
        :initFetch="false"
        :options="tableOptions"
        @rowSelected="rowSelected"
      >
        <template #fileName="{ index, row }">
          <div class="file-item">
            <template
              v-if="(row.fileType == 3 || row.fileType == 1) && row.status == 2"
            >
              <icon :cover="row.fileCover" :width="32"></icon>
            </template>
            <template v-else>
              <icon v-if="row.folderType == 0" :fileType="row.fileType"></icon>
              <icon v-if="row.folderType == 1" :fileType="0"></icon>
            </template>
            <span class="file-name" v-if="!row.showEdit" :title="row.fileName">
              <span @click="preview(row)">{{ row.fileName }}</span>
              <span v-if="row.status == 0" class="transfer-status">转码中</span>
              <span v-if="row.status == 1" class="transfer-status transfer-fail"
                >转码失败</span
              >
            </span>
            <div class="edit-panel" v-if="row.showEdit">
              <el-input
                v-model.trim="row.fileNameReal"
                ref="editNameRef"
                :maxLength="190"
                @keyup.enter="saveNameEdit(index)"
              >
                <template #suffix>{{ row.fileSuffix }}</template>
              </el-input>
              <span
                :class="[
                  'iconfont icon-right1',
                  row.fileNameReal ? '' : 'not-allow',
                ]"
                @click="saveNameEdit(index)"
              ></span>
              <span
                class="iconfont icon-error"
                @click="cancelNameEdit(index)"
              ></span>
            </div>
          </div>
        </template>
        <template #fileSize="{ index, row }">
          <span v-if="row.fileSize">
            {{ proxy.Utils.size2Str(row.fileSize) }}</span
          >
        </template>
        <template #userAvatar="{ index, row }">
          <el-tooltip placement="top">
            <template #content>
              <div>昵称: {{ row.nickName || '未知' }}</div>
              <div>ID: {{ row.userId || '未知' }}</div>
            </template>
            <div class="user-avatar-cell">
              <Avatar
                :userId="row.userId"
                :avatar="row.avatar"
                :width="32"
              ></Avatar>
            </div>
          </el-tooltip>
        </template>
        <template #operation="{ index, row }">
          <el-dropdown trigger="click" @command="(command) => handleOperation(command, row, index)">
            <span class="operation-btn">
              <el-icon><MoreFilled /></el-icon>
            </span>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="share" v-if="row.fileId && row.status == 2">
                  <span class="iconfont icon-share1"></span> 分享
                </el-dropdown-item>
                <el-dropdown-item command="download" v-if="row.folderType == 0 && row.status == 2">
                  <span class="iconfont icon-download"></span> 下载
                </el-dropdown-item>
                <el-dropdown-item command="rename" v-if="row.fileId && row.status == 2">
                  <span class="iconfont icon-edit"></span> 重命名
                </el-dropdown-item>
                <el-dropdown-item command="move" v-if="row.fileId && row.status == 2">
                  <span class="iconfont icon-move"></span> 移动
                </el-dropdown-item>
                <el-dropdown-item command="syncToFamily" v-if="row.folderType == 0 && row.status == 2 && !row.belongingHome">
                  <span class="iconfont icon-refresh"></span> 同步至家庭空间
                </el-dropdown-item>
                <el-dropdown-item command="delete" v-if="row.fileId && row.status == 2" divided>
                  <span class="iconfont icon-del"></span> 删除
                </el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </template>
      </Table>
    </div>
    <div class="no-data" v-else>
      <div class="no-data-inner">
        <Icon iconName="no_data" :width="120" fit="fill"></Icon>
        <div class="tips">当前目录为空，上传你的第一个文件吧</div>
        <div class="op-list">
          <el-upload
            :show-file-list="false"
            :with-credentials="true"
            :multiple="true"
            :http-request="addFile"
            :accept="fileAccept"
          >
            <div class="op-item">
              <Icon iconName="file" :width="60"></Icon>
              <div>上传文件</div>
            </div>
          </el-upload>
          <div class="op-item" v-if="category == 'all'" @click="newFolder">
            <Icon iconName="folder" :width="60"></Icon>
            <div>新建目录</div>
          </div>
        </div>
      </div>
    </div>
    <!--预览-->
    <Preview ref="previewRef"> </Preview>
    <!--移动-->
    <FolderSelect
      ref="folderSelectRef"
      @folderSelect="moveFolderDone"
    ></FolderSelect>
    <!--分享-->
    <FileShare ref="shareRef"></FileShare>
    
    <!--自定义右键菜单-->
    <div 
      v-if="contextMenuVisible" 
      class="context-menu"
      :style="{ top: contextMenuPosition.y + 'px', left: contextMenuPosition.x + 'px' }"
      @click.stop
    >
      <div class="context-menu-item" @click="contextMenuUpload">
        <span class="iconfont icon-upload"></span>
        <span>上传文件至此</span>
      </div>
      <div class="context-menu-item" @click="contextMenuNewFolder" v-if="category == 'all'">
        <span class="iconfont icon-folder-add"></span>
        <span>新建文件夹</span>
      </div>
      <div class="context-menu-divider" v-if="shouldShowFileOperations()"></div>
      
      <!-- 分享给好友 - 只对文件有效，不包含文件夹 -->
      <div class="context-menu-item" @click="contextMenuShareToFriend" v-if="shouldShowShareToFriend()">
        <span class="iconfont icon-share1"></span>
        <span>分享给好友</span>
      </div>
      
      <!-- 生成分享码 - 单个文件或文件夹 -->
      <div class="context-menu-item" @click="contextMenuGenerateShareCode" v-if="shouldShowGenerateShareCode()">
        <span class="iconfont icon-link"></span>
        <span>生成分享码</span>
      </div>
      
      <!-- 下载 - 文件或多个文件 -->
      <div class="context-menu-item" @click="contextMenuDownload" v-if="shouldShowDownload()">
        <span class="iconfont icon-download"></span>
        <span>{{ getDownloadText() }}</span>
      </div>
      
      <div class="context-menu-divider" v-if="shouldShowFileOperations()"></div>
      
      <!-- 同步至家庭空间 - 只对单个文件显示 -->
      <div class="context-menu-item" @click="contextMenuSyncToFamily" v-if="shouldShowSyncToFamily()">
        <span class="iconfont icon-refresh"></span>
        <span>同步至家庭空间</span>
      </div>
      
      <div class="context-menu-divider" v-if="shouldShowFileOperations() && shouldShowSyncToFamily()"></div>
      
      <div class="context-menu-item" @click="contextMenuRename" v-if="shouldShowRename()">
        <span class="iconfont icon-edit"></span>
        <span>重命名</span>
      </div>
      <div class="context-menu-item" @click="contextMenuDelete" v-if="contextMenuFile || selectFileIdList.length > 0">
        <span class="iconfont icon-del"></span>
        <span>{{ selectFileIdList.length > 0 ? `删除 (${selectFileIdList.length}项)` : '删除' }}</span>
      </div>
      <div class="context-menu-item" @click="contextMenuMove" v-if="contextMenuFile || selectFileIdList.length > 0">
        <span class="iconfont icon-move"></span>
        <span>{{ selectFileIdList.length > 0 ? `移动 (${selectFileIdList.length}项)` : '移动' }}</span>
      </div>
    </div>
    
    <!--隐藏的上传input用于右键菜单上传-->
    <input 
      ref="contextUploadInput" 
      type="file" 
      multiple 
      :accept="fileAccept"
      style="display: none"
      @change="handleContextUpload"
    />
    
    <!--好友选择对话框-->
    <FriendSelectDialog
      ref="friendSelectDialogRef"
      @confirm="handleFriendShareConfirm"
    />
  </div>
</template>

<script setup>
import CategoryInfo from "@/js/CategoryInfo.js";
import FileShare from "./ShareFile.vue";
import FriendSelectDialog from "../friend/FriendSelectDialog.vue";
import { ref, reactive, getCurrentInstance, nextTick, computed } from "vue";
import { useRouter, useRoute } from "vue-router";
import { MoreFilled } from '@element-plus/icons-vue';

// 导入排序图标
import sortAscIcon from '@/assets/icon-image/main/sort/asc.png';
import sortDescIcon from '@/assets/icon-image/main/sort/desc.png';
import sortUnsortIcon from '@/assets/icon-image/main/sort/unsort.png';

const { proxy } = getCurrentInstance();
const router = useRouter();
const route = useRoute();
const emit = defineEmits(["addFile"]);
//添加文件
const addFile = async (fileData) => {
  emit("addFile", { file: fileData.file, filePid: currentFolder.value.fileId });
};
//添加文件回调
const reload = () => {
  showLoading.value = false;
  loadDataList();
};
defineExpose({
  reload,
});

const currentFolder = ref({ fileId: 0 });

const api = {
  loadDataList: "/file/loadDataList",
  rename: "/file/rename",
  newFoloder: "/file/newFoloder",
  getFolderInfo: "/file/getFolderInfo",
  delFile: "/file/delFile",
  changeFileFolder: "/file/changeFileFolder",
  createDownloadUrl: "/file/createDownloadUrl",
  download: "/api/file/download",
};

const fileAccept = computed(() => {
  const categoryItem = CategoryInfo[category.value];
  return categoryItem ? categoryItem.accept : "*";
});

//列表
const columns = ref([
  {
    label: "文件名",
    prop: "fileName",
    scopedSlots: "fileName",
  },
  {
    label: "创建时间",
    prop: "createTime",
    width: 200,
  },
  {
    label: "修改时间",
    prop: "lastUpdateTime",
    width: 200,
  },
  {
    label: "大小",
    prop: "fileSize",
    scopedSlots: "fileSize",
    width: 200,
  },
  {
    label: "操作",
    prop: "operation",
    scopedSlots: "operation",
    width: 80,
  },
]);
//搜索
const search = () => {
  showLoading.value = true;
  loadDataList();
};
//列表
const tableData = ref({});
const tableOptions = {
  extHeight: 50,
  selectType: "checkbox",
};

const fileNameFuzzy = ref();
const showLoading = ref(true);
const category = ref();

// 排序相关
const sortType = ref('createTime'); // 默认按创建时间排序
const sortOrder = ref('desc'); // 默认降序（最新的在前）

// 获取排序图标
const getSortIcon = () => {
  if (sortOrder.value === 'asc') {
    return sortAscIcon;
  } else if (sortOrder.value === 'desc') {
    return sortDescIcon;
  } else {
    return sortUnsortIcon;
  }
};

// 获取排序提示文字
const getSortOrderTitle = () => {
  if (sortOrder.value === 'asc') {
    return '升序 - 点击切换为降序';
  } else {
    return '降序 - 点击切换为升序';
  }
};

// 切换排序顺序
const toggleSortOrder = () => {
  sortOrder.value = sortOrder.value === 'asc' ? 'desc' : 'asc';
  sortFiles();
};

// 排序函数
const sortFiles = () => {
  if (!tableData.value.list || tableData.value.list.length === 0) {
    return;
  }
  
  const list = [...tableData.value.list];
  
  list.sort((a, b) => {
    let compareResult = 0;
    
    // 文件夹始终排在前面
    if (a.folderType !== b.folderType) {
      return b.folderType - a.folderType;
    }
    
    switch (sortType.value) {
      case 'name':
        // 按名称排序
        compareResult = a.fileName.localeCompare(b.fileName, 'zh-CN');
        break;
      case 'createTime':
        // 按创建时间排序
        const createTimeA = new Date(a.createTime).getTime();
        const createTimeB = new Date(b.createTime).getTime();
        compareResult = createTimeA - createTimeB;
        break;
      case 'updateTime':
        // 按修改时间排序
        const updateTimeA = new Date(a.lastUpdateTime).getTime();
        const updateTimeB = new Date(b.lastUpdateTime).getTime();
        compareResult = updateTimeA - updateTimeB;
        break;
      case 'type':
        // 按文件类型排序（文件夹已经在前面了，这里只排序文件）
        if (a.folderType === 0 && b.folderType === 0) {
          // 获取文件扩展名
          const extA = a.fileName.substring(a.fileName.lastIndexOf('.') + 1).toLowerCase();
          const extB = b.fileName.substring(b.fileName.lastIndexOf('.') + 1).toLowerCase();
          compareResult = extA.localeCompare(extB);
          // 如果扩展名相同，再按名称排序
          if (compareResult === 0) {
            compareResult = a.fileName.localeCompare(b.fileName, 'zh-CN');
          }
        }
        break;
    }
    
    // 根据排序顺序返回结果
    return sortOrder.value === 'asc' ? compareResult : -compareResult;
  });
  
  tableData.value.list = list;
};

const loadDataList = async () => {
  let params = {
    pageNo: tableData.value.pageNo,
    pageSize: tableData.value.pageSize,
    fileNameFuzzy: fileNameFuzzy.value,
    category: category.value,
    filePid: currentFolder.value.fileId,
    queryNickName: true,  // 查询用户昵称
  };
  if (params.category !== "all") {
    delete params.filePid;
  }
  let result = await proxy.Request({
    url: api.loadDataList,
    showLoading: showLoading,
    params,
  });
  if (!result) {
    return;
  }
  tableData.value = result.data;
  editing.value = false;
  
  // 加载完数据后自动排序
  nextTick(() => {
    sortFiles();
  });
};


//编辑行
const editing = ref(false);
const editNameRef = ref();
//新建文件夹
const newFolder = () => {
  if (editing.value) {
    return;
  }
  tableData.value.list.forEach((element) => {
    element.showEdit = false;
  });
  editing.value = true;
  tableData.value.list.unshift({
    showEdit: true,
    fileType: 0,
    fileId: "",
    filePid: currentFolder.value.fileId,
  });
  nextTick(() => {
    editNameRef.value.focus();
  });
};

const cancelNameEdit = (index) => {
  const fileData = tableData.value.list[index];
  if (fileData.fileId) {
    fileData.showEdit = false;
  } else {
    tableData.value.list.splice(index, 1);
  }
  editing.value = false;
};

const saveNameEdit = async (index) => {
  const { fileId, filePid, fileNameReal } = tableData.value.list[index];
  if (fileNameReal == "" || fileNameReal.indexOf("/") != -1) {
    proxy.Message.warning("文件名不能为空且不能含有斜杠");
    return;
  }
  let url = api.rename;
  if (fileId == "") {
    url = api.newFoloder;
  }
  let result = await proxy.Request({
    url: url,
    params: {
      fileId,
      filePid: filePid,
      fileName: fileNameReal,
    },
  });
  if (!result) {
    return;
  }
  tableData.value.list[index] = result.data;
  editing.value = false;
};

//编辑文件名
const editFileName = (index) => {
  if (tableData.value.list[0].fileId == "") {
    tableData.value.list.splice(0, 1);
    index = index - 1;
  }
  tableData.value.list.forEach((element) => {
    element.showEdit = false;
  });
  let cureentData = tableData.value.list[index];
  cureentData.showEdit = true;

  //编辑文件
  if (cureentData.folderType == 0) {
    cureentData.fileNameReal = cureentData.fileName.substring(
      0,
      cureentData.fileName.indexOf(".")
    );
    cureentData.fileSuffix = cureentData.fileName.substring(
      cureentData.fileName.indexOf(".")
    );
  } else {
    cureentData.fileNameReal = cureentData.fileName;
    cureentData.fileSuffix = "";
  }
  editing.value = true;
  nextTick(() => {
    editNameRef.value.focus();
  });
};

// 操作按钮处理
const handleOperation = (command, row, index) => {
  switch (command) {
    case 'share':
      share(row);
      break;
    case 'download':
      download(row);
      break;
    case 'rename':
      editFileName(index);
      break;
    case 'move':
      moveFolder(row);
      break;
    case 'syncToFamily':
      syncToFamily(row);
      break;
    case 'delete':
      delFile(row);
      break;
  }
};

// 多选 批量选择
const selectFileIdList = ref([]);
const selectFileList = ref([]);
const rowSelected = (rows) => {
  selectFileList.value = rows;
  selectFileIdList.value = [];
  rows.forEach((item) => {
    selectFileIdList.value.push(item.fileId);
  });
};

//删除文件
const delFile = (row) => {
  proxy.Confirm(
    `你确定要删除【${row.fileName}】吗？删除的文件可在10天内通过回收站还原`,
    async () => {
      let result = await proxy.Request({
        url: api.delFile,
        params: {
          fileIds: row.fileId,
        },
      });
      if (!result) {
        return;
      }
      loadDataList();
    }
  );
};
//批量删除
const delFileBatch = () => {
  if (selectFileIdList.value.length == 0) {
    return;
  }
  proxy.Confirm(
    `你确定要删除这些文件吗？删除的文件可在10天内通过回收站还原`,
    async () => {
      let result = await proxy.Request({
        url: api.delFile,
        params: {
          fileIds: selectFileIdList.value.join(","),
        },
      });
      if (!result) {
        return;
      }
      loadDataList();
    }
  );
};

//移动目录
const folderSelectRef = ref();
const currentMoveFile = ref({});
const moveFolder = (data) => {
  currentMoveFile.value = data;
  folderSelectRef.value.showFolderDialog(data.fileId);
};

//批量移动
const moveFolderBatch = () => {
  currentMoveFile.value = {};
  //批量移动如果选择的是文件夹，那么要讲文件夹也过滤
  const excludeFileIdList = [currentFolder.value.fileId];
  selectFileList.value.forEach((item) => {
    if (item.folderType == 1) {
      excludeFileIdList.push(item.fileId);
    }
  });
  folderSelectRef.value.showFolderDialog(excludeFileIdList.join(","));
};

const moveFolderDone = async (folderId) => {
  if (
    currentMoveFile.value.filePid === folderId ||
    currentFolder.value.fileId == folderId
  ) {
    proxy.Message.warning("文件正在当前目录，无需移动");
    return;
  }
  let filedIdsArray = [];
  if (currentMoveFile.value.fileId) {
    filedIdsArray.push(currentMoveFile.value.fileId);
  } else {
    filedIdsArray = filedIdsArray.concat(selectFileIdList.value);
  }
  let result = await proxy.Request({
    url: api.changeFileFolder,
    params: {
      fileIds: filedIdsArray.join(","),
      filePid: folderId,
    },
  });
  if (!result) {
    return;
  }
  folderSelectRef.value.close();
  loadDataList();
};

const previewRef = ref();
const navigationRef = ref();
const preview = (data) => {
  if (data.folderType == 1) {
    //openFolder(data);
    navigationRef.value.openFolder(data);
    return;
  }
  if (data.status != 2) {
    proxy.Message.warning("文件正在转码中，无法预览");
    return;
  }
  previewRef.value.showPreview(data, 0);
};

//目录
const navChange = (data) => {
  const { curFolder, categoryId } = data;
  currentFolder.value = curFolder;
  showLoading.value = true;
  category.value = categoryId;
  loadDataList();
};

//下载文件
const download = async (row) => {
  let result = await proxy.Request({
    url: api.createDownloadUrl + "/" + row.fileId,
  });
  if (!result) {
    return;
  }
  
  // 使用动态创建的 a 标签触发下载，支持多文件下载
  const downloadUrl = api.download + "/" + result.data;
  const link = document.createElement('a');
  link.href = downloadUrl;
  link.style.display = 'none';
  document.body.appendChild(link);
  link.click();
  
  // 延迟移除 a 标签
  setTimeout(() => {
    document.body.removeChild(link);
  }, 100);
};

//分享
const shareRef = ref();
const share = (row) => {
  shareRef.value.show(row);
};

// 右键菜单相关
const contextMenuVisible = ref(false);
const contextMenuPosition = ref({ x: 0, y: 0 });
const contextMenuFile = ref(null);
const contextUploadInput = ref(null);

// 处理右键菜单
const handleContextMenu = (event) => {
  event.preventDefault();
  
  // 检查是否点击在文件行上
  let target = event.target;
  let fileRow = null;
  
  // 向上查找是否在文件行内
  while (target && target !== event.currentTarget) {
    if (target.classList && target.classList.contains('file-item')) {
      // 找到对应的文件数据
      const fileName = target.querySelector('.file-name span');
      if (fileName) {
        const fileNameText = fileName.textContent.trim();
        fileRow = tableData.value.list.find(item => item.fileName === fileNameText);
      }
      break;
    }
    target = target.parentElement;
  }
  
  contextMenuFile.value = fileRow;
  contextMenuPosition.value = { x: event.clientX, y: event.clientY };
  contextMenuVisible.value = true;
  
  // 点击其他地方关闭菜单
  const closeMenu = () => {
    contextMenuVisible.value = false;
    document.removeEventListener('click', closeMenu);
  };
  
  setTimeout(() => {
    document.addEventListener('click', closeMenu);
  }, 0);
};

// 右键菜单 - 上传文件
const contextMenuUpload = () => {
  contextMenuVisible.value = false;
  contextUploadInput.value.click();
};

// 处理右键菜单上传
const handleContextUpload = (event) => {
  const files = event.target.files;
  if (files && files.length > 0) {
    for (let i = 0; i < files.length; i++) {
      addFile({ file: files[i] });
    }
  }
  // 清空input以便下次可以选择相同文件
  event.target.value = '';
};

// 右键菜单 - 新建文件夹
const contextMenuNewFolder = () => {
  contextMenuVisible.value = false;
  newFolder();
};

// 右键菜单 - 删除
const contextMenuDelete = () => {
  contextMenuVisible.value = false;
  // 优先处理多选对象
  if (selectFileIdList.value.length > 0) {
    delFileBatch();
  } else if (contextMenuFile.value) {
    delFile(contextMenuFile.value);
  }
};

// 右键菜单 - 重命名
const contextMenuRename = () => {
  contextMenuVisible.value = false;
  
  if (contextMenuFile.value) {
    // 找到文件在列表中的索引
    const index = tableData.value.list.findIndex(
      item => item.fileId === contextMenuFile.value.fileId
    );
    if (index !== -1) {
      editFileName(index);
    }
  } else if (selectFileIdList.value.length === 1) {
    // 如果只选中了一个文件
    const index = tableData.value.list.findIndex(
      item => item.fileId === selectFileIdList.value[0]
    );
    if (index !== -1) {
      editFileName(index);
    }
  }
};

// 判断是否显示重命名选项（只在右键单个文件或选中单个文件时显示）
const shouldShowRename = () => {
  if (contextMenuFile.value && selectFileIdList.value.length === 0) {
    return true;
  }
  if (selectFileIdList.value.length === 1) {
    return true;
  }
  return false;
};

// 右键菜单 - 移动
const contextMenuMove = () => {
  contextMenuVisible.value = false;
  // 优先处理多选对象
  if (selectFileIdList.value.length > 0) {
    moveFolderBatch();
  } else if (contextMenuFile.value) {
    moveFolder(contextMenuFile.value);
  }
};

// 判断是否应该显示文件操作菜单
const shouldShowFileOperations = () => {
  return contextMenuFile.value || selectFileIdList.value.length > 0;
};

// 判断是否显示"分享给好友"
const shouldShowShareToFriend = () => {
  // 有多选文件时
  if (selectFileIdList.value.length > 0) {
    // 检查是否所有选中的都是文件（不包含文件夹）
    return selectFileList.value.every(file => file.folderType === 0);
  }
  // 右键单个文件时
  if (contextMenuFile.value) {
    return contextMenuFile.value.folderType === 0;
  }
  return false;
};

// 判断是否显示"生成分享码"
const shouldShowGenerateShareCode = () => {
  // 只有单个文件或文件夹时显示
  if (selectFileIdList.value.length === 1) {
    return true;
  }
  // 右键单个文件或文件夹时
  if (contextMenuFile.value && selectFileIdList.value.length === 0) {
    return true;
  }
  return false;
};

// 判断是否显示"下载"
const shouldShowDownload = () => {
  // 有多选时
  if (selectFileIdList.value.length > 0) {
    // 检查是否所有选中的都是文件（不包含文件夹）
    return selectFileList.value.every(file => file.folderType === 0);
  }
  // 右键单个文件时
  if (contextMenuFile.value) {
    return contextMenuFile.value.folderType === 0;
  }
  return false;
};

// 获取下载按钮文本
const getDownloadText = () => {
  const count = selectFileIdList.value.length;
  if (count > 1) {
    return `下载 (${count}项)`;
  }
  return '下载';
};

// 右键菜单 - 分享给好友
const friendSelectDialogRef = ref();
const contextMenuShareToFriend = () => {
  contextMenuVisible.value = false;
  friendSelectDialogRef.value.show();
};

// 处理好友分享确认
const handleFriendShareConfirm = async (selectedFriends) => {
  let fileIds = [];
  
  if (selectFileIdList.value.length > 0) {
    fileIds = selectFileIdList.value;
  } else if (contextMenuFile.value) {
    fileIds = [contextMenuFile.value.fileId];
  }
  
  if (fileIds.length === 0) {
    proxy.Message.warning('请选择要分享的文件');
    return;
  }
  
  // 为每个选中的好友分享文件
  for (const friend of selectedFriends) {
    try {
      const result = await proxy.Request({
        url: '/friendShare/shareFiles',
        params: {
          friendId: friend.friendId,
          fileIds: fileIds.join(','),
          validType: 0 // 默认永久有效
        }
      });
      
      if (result) {
        proxy.Message.success(`已分享给 ${friend.remark || friend.nickName}`);
      }
    } catch (error) {
      console.error('分享失败:', error);
    }
  }
};

// 右键菜单 - 生成分享码
const contextMenuGenerateShareCode = () => {
  contextMenuVisible.value = false;
  
  let fileToShare = null;
  
  if (selectFileIdList.value.length === 1) {
    fileToShare = selectFileList.value[0];
  } else if (contextMenuFile.value) {
    fileToShare = contextMenuFile.value;
  }
  
  if (fileToShare) {
    share(fileToShare);
  }
};

// 右键菜单 - 下载
const contextMenuDownload = async () => {
  contextMenuVisible.value = false;
  
  if (selectFileIdList.value.length > 0) {
    // 批量下载 - 使用延迟避免浏览器阻止
    for (let i = 0; i < selectFileList.value.length; i++) {
      const file = selectFileList.value[i];
      if (file.folderType === 0) {
        await downloadWithDelay(file, i * 300); // 每个下载间隔300ms
      }
    }
  } else if (contextMenuFile.value && contextMenuFile.value.folderType === 0) {
    download(contextMenuFile.value);
  }
};

// 带延迟的下载函数
const downloadWithDelay = (file, delay) => {
  return new Promise((resolve) => {
    setTimeout(async () => {
      await download(file);
      resolve();
    }, delay);
  });
};

// 同步至家庭空间
const syncToFamily = async (file) => {
  if (!file || file.folderType !== 0) {
    proxy.Message.warning('只能同步文件');
    return;
  }

  try {
    // 先检查用户是否有家庭
    const familyResult = await proxy.Request({
      url: '/family/checkFamily',
      showLoading: false,
    });

    if (!familyResult || !familyResult.data || !familyResult.data.familyId) {
      proxy.Message.warning('您还没有加入家庭');
      return;
    }

    // 调用同步接口
    let result = await proxy.Request({
      url: '/file/syncToFamily',
      params: {
        fileIds: file.fileId,
        familyId: familyResult.data.familyId
      }
    });

    if (result) {
      proxy.Message.success('文件同步成功');
      loadDataList(); // 刷新列表
    }
  } catch (error) {
    console.error('同步失败:', error);
  }
};

// 右键菜单 - 同步至家庭空间
const contextMenuSyncToFamily = () => {
  contextMenuVisible.value = false;
  
  let fileToSync = null;
  
  if (contextMenuFile.value && selectFileIdList.value.length === 0) {
    fileToSync = contextMenuFile.value;
  } else if (selectFileIdList.value.length === 1) {
    fileToSync = selectFileList.value[0];
  }
  
  if (fileToSync) {
    syncToFamily(fileToSync);
  }
};

// 判断是否显示"同步至家庭空间"选项
const shouldShowSyncToFamily = () => {
  // 只对单个文件显示，不在家庭空间中显示
  if (contextMenuFile.value && selectFileIdList.value.length === 0) {
    return contextMenuFile.value.folderType === 0 && 
           contextMenuFile.value.status === 2 && 
           !contextMenuFile.value.belongingHome;
  }
  
  if (selectFileIdList.value.length === 1) {
    const file = selectFileList.value[0];
    return file.folderType === 0 && 
           file.status === 2 && 
           !file.belongingHome;
  }
  
  return false;
};
</script>

<style lang="scss" scoped>
@import "@/assets/file.list.scss";

.context-menu {
  position: fixed;
  background: var(--component-bg);
  border: 1px solid var(--border-color);
  border-radius: 8px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.2);
  z-index: 9999;
  min-width: 160px;
  padding: 5px 0;
  
  .context-menu-item {
    padding: 10px 20px;
    cursor: pointer;
    display: flex;
    align-items: center;
    gap: 10px;
    font-size: 14px;
    color: var(--text-primary);
    transition: all 0.3s;
    
    .iconfont {
      font-size: 16px;
      color: var(--text-secondary);
    }
    
    &:hover {
      background-color: var(--component-hover-bg);
      color: #409eff;
      
      .iconfont {
        color: #409eff;
      }
    }
  }
  
  .context-menu-divider {
    height: 1px;
    background-color: var(--border-light);
    margin: 5px 0;
  }
}
</style>