<template>
  <div class="family-space">
    <!-- 未加入家庭提示 -->
    <div class="no-family" v-if="!hasFamilyLoaded">
      <div class="loading-text">加载中...</div>
    </div>
    <div class="no-family" v-else-if="!familyId">
      <Icon iconName="no_data" :width="120" fit="fill"></Icon>
      <div class="tips">您还未加入任何家庭，请先在家庭管理中创建或加入家庭</div>
      <el-button type="primary" @click="router.push('/family')">前往家庭管理</el-button>
    </div>
    <!-- 家庭空间主体 -->
    <div v-else>
      <div class="top">
        <div class="top-op">
          <div class="btn">
            <el-upload
              :show-file-list="false"
              :with-credentials="true"
              :multiple="true"
              :http-request="addFile"
              accept="*"
            >
              <el-button type="primary">
                <span class="iconfont icon-upload"></span>
                上传
              </el-button>
            </el-upload>
          </div>
          <el-button type="success" @click="newFolder">
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
          <div class="iconfont icon-refresh" @click="loadDataList"></div>
          <!-- 空间使用情况 -->
          <div class="space-info" v-if="familySpaceInfo.totalSpace > 0">
            <span class="space-text">
              {{ proxy.Utils.size2Str(familySpaceInfo.useSpace) }} / {{ proxy.Utils.size2Str(familySpaceInfo.totalSpace) }}
            </span>
            <el-progress
              :percentage="Math.round((familySpaceInfo.useSpace / familySpaceInfo.totalSpace) * 100)"
              :stroke-width="8"
              :show-text="false"
              class="space-progress"
            />
          </div>
        </div>
        <!--导航-->
        <Navigation ref="navigationRef" :familyId="familyId" @navChange="navChange"></Navigation>
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
            <div class="file-item" @click="preview(row)">
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
                <span>{{ row.fileName }}</span>
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
                  @click.stop="saveNameEdit(index)"
                ></span>
                <span
                  class="iconfont icon-error"
                  @click.stop="cancelNameEdit(index)"
                ></span>
              </div>
            </div>
          </template>
          <template #fileSize="{ index, row }">
            <span v-if="row.fileSize">
              {{ proxy.Utils.size2Str(row.fileSize) }}</span
            >
          </template>
          <template #nickName="{ index, row }">
            <span>{{ row.nickName || '未知' }}</span>
          </template>
          <template #operation="{ index, row }">
            <el-dropdown trigger="click" @command="(command) => handleOperation(command, row, index)">
              <span class="operation-btn">
                <el-icon><MoreFilled /></el-icon>
              </span>
              <template #dropdown>
                <el-dropdown-menu>
                  <el-dropdown-item command="download" v-if="row.folderType == 0 && row.status == 2">
                    <span class="iconfont icon-download"></span> 下载
                  </el-dropdown-item>
                  <el-dropdown-item command="rename" v-if="row.fileId && row.status == 2">
                    <span class="iconfont icon-edit"></span> 重命名
                  </el-dropdown-item>
                  <el-dropdown-item command="move" v-if="row.fileId && row.status == 2">
                    <span class="iconfont icon-move"></span> 移动
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
          <div class="tips" v-if="canUpload">当前目录为空，上传家庭文件吧</div>
          <div class="tips" v-else>当前目录为空</div>
          <div class="op-list" v-if="canUpload">
            <el-upload
              :show-file-list="false"
              :with-credentials="true"
              :multiple="true"
              :http-request="addFile"
              accept="*"
            >
              <div class="op-item">
                <Icon iconName="file" :width="60"></Icon>
                <div>上传文件</div>
              </div>
            </el-upload>
            <div class="op-item" @click="newFolder">
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
        :familyId="familyId"
        @folderSelect="moveFolderDone"
      ></FolderSelect>
    </div>
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
      <div class="context-menu-item" @click="contextMenuNewFolder">
        <span class="iconfont icon-folder-add"></span>
        <span>新建文件夹</span>
      </div>
      <div class="context-menu-divider" v-if="shouldShowFileOperations()"></div>
      
      <!-- 下载 - 文件或多个文件 -->
      <div class="context-menu-item" @click="contextMenuDownload" v-if="shouldShowDownload()">
        <span class="iconfont icon-download"></span>
        <span>{{ getDownloadText() }}</span>
      </div>
      
      <div class="context-menu-divider" v-if="shouldShowFileOperations()"></div>
      
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
      accept="*"
      style="display: none"
      @change="handleContextUpload"
    />
  </div>
</template>

<script setup>
import { ref, getCurrentInstance, nextTick, onMounted } from "vue";
import { useRouter } from "vue-router";
import { MoreFilled } from '@element-plus/icons-vue';

const { proxy } = getCurrentInstance();
const router = useRouter();
const emit = defineEmits(["addFile"]);

// 家庭信息
const familyId = ref(null);
const hasFamilyLoaded = ref(false);
const familySpaceInfo = ref({ useSpace: 0, totalSpace: 0 });

const api = {
  checkFamily: "/family/checkFamily",
  getFamilyInfo: "/family/getFamilyInfo",
  loadDataList: "/familySpace/loadDataList",
  uploadFile: "/familySpace/uploadFile",
  newFolder: "/familySpace/newFolder",
  getFamilySpaceUsage: "/familySpace/getFamilySpaceUsage",
  createDownloadUrl: "/file/createDownloadUrl",
  download: "/api/file/download",
  delFile: "/familySpace/delFile",
  rename: "/familySpace/rename",
  changeFileFolder: "/familySpace/changeFileFolder",
};

// 检查家庭信息
const checkFamily = async () => {
  const result = await proxy.Request({
    url: api.checkFamily,
    showLoading: false,
  });
  if (result && result.data) {
    familyId.value = result.data.familyId || null;
  } else {
    familyId.value = null;
  }
  hasFamilyLoaded.value = true;
  if (familyId.value) {
    loadDataList();
    getFamilySpaceUsage();
  }
};

// 文件列表
const columns = ref([
  {
    label: "文件名",
    prop: "fileName",
    scopedSlots: "fileName",
  },
  {
    label: "上传者",
    prop: "nickName",
    scopedSlots: "nickName",
    width: 150,
  },
  {
    label: "创建时间",
    prop: "createTime",
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

const tableData = ref({});
const tableOptions = {
  extHeight: 50,
  selectType: "checkbox",
};

const fileNameFuzzy = ref();
const showLoading = ref(true);
const currentFolder = ref({ fileId: 0 });

const loadDataList = async () => {
  let params = {
    pageNo: tableData.value.pageNo,
    pageSize: tableData.value.pageSize,
    fileNameFuzzy: fileNameFuzzy.value,
    category: "all",
    filePid: currentFolder.value.fileId,
    familyId: familyId.value,
  };
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
};

const search = () => {
  showLoading.value = true;
  loadDataList();
};

// 上传文件
const addFile = async (fileData) => {
  emit("addFile", {
    file: fileData.file,
    filePid: currentFolder.value.fileId,
    familyId: familyId.value,
  });
};

// 上传回调 - 刷新列表
const reload = () => {
  showLoading.value = false;
  loadDataList();
  getFamilySpaceUsage();
};
defineExpose({ reload });

// 新建文件夹
const editing = ref(false);
const editNameRef = ref();
const newFolder = () => {
  if (editing.value) {
    return;
  }
  if (!tableData.value.list) {
    tableData.value.list = [];
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

// 编辑文件名
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

const saveNameEdit = async (index) => {
  const { fileId, filePid, fileNameReal } = tableData.value.list[index];
  if (fileNameReal == "" || fileNameReal.indexOf("/") != -1) {
    proxy.Message.warning("文件名不能为空且不能含有斜杠");
    return;
  }
  if (fileId == "") {
    // 新建文件夹
    let result = await proxy.Request({
      url: api.newFolder,
      params: {
        filePid: filePid,
        fileName: fileNameReal,
        familyId: familyId.value,
      },
    });
    if (!result) {
      return;
    }
    tableData.value.list[index] = result.data;
    editing.value = false;
  } else {
    // 重命名
    let result = await proxy.Request({
      url: api.rename,
      params: {
        fileId: fileId,
        fileName: fileNameReal,
      },
    });
    if (!result) {
      return;
    }
    tableData.value.list[index].fileName = result.data.fileName;
    tableData.value.list[index].showEdit = false;
    editing.value = false;
  }
};

// 操作
const handleOperation = (command, row, index) => {
  switch (command) {
    case 'download':
      download(row);
      break;
    case 'rename':
      editFileName(index);
      break;
    case 'move':
      moveFolder(row);
      break;
    case 'delete':
      delFile(row);
      break;
  }
};

// 多选
const selectFileIdList = ref([]);
const selectFileList = ref([]);
const rowSelected = (rows) => {
  selectFileList.value = rows;
  selectFileIdList.value = [];
  rows.forEach((item) => {
    selectFileIdList.value.push(item.fileId);
  });
};

// 删除后刷新空间使用情况
const delFile = (row) => {
  proxy.Confirm(
    `你确定要删除【${row.fileName}】吗？删除的文件可在10天内通过回收站还原`,
    async () => {
      let result = await proxy.Request({
        url: api.delFile,
        params: {
          fileIds: row.fileId,
          familyId: familyId.value,
        },
      });
      if (!result) {
        return;
      }
      loadDataList();
      getFamilySpaceUsage();
    }
  );
};

// 批量删除
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
          familyId: familyId.value,
        },
      });
      if (!result) {
        return;
      }
      loadDataList();
      getFamilySpaceUsage();
    }
  );
};

// 下载
const download = async (row) => {
  let result = await proxy.Request({
    url: api.createDownloadUrl + "/" + row.fileId,
  });
  if (!result) {
    return;
  }
  const downloadUrl = api.download + "/" + result.data;
  const link = document.createElement('a');
  link.href = downloadUrl;
  link.style.display = 'none';
  document.body.appendChild(link);
  link.click();
  setTimeout(() => {
    document.body.removeChild(link);
  }, 100);
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

// 移动目录
const folderSelectRef = ref();
const currentMoveFile = ref({});
const moveFolder = (data) => {
  currentMoveFile.value = data;
  folderSelectRef.value.showFolderDialog(data.fileId);
};

// 批量移动
const moveFolderBatch = () => {
  currentMoveFile.value = {};
  // 批量移动如果选择的是文件夹，那么要将文件夹也过滤
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
      familyId: familyId.value,
    },
  });
  if (!result) {
    return;
  }
  folderSelectRef.value.close();
  loadDataList();
};

// 预览
const previewRef = ref();
const navigationRef = ref();
const preview = (data) => {
  if (data.folderType == 1) {
    navigationRef.value.openFolder(data);
    return;
  }
  if (data.status != 2) {
    proxy.Message.warning("文件正在转码中，无法预览");
    return;
  }
  previewRef.value.showPreview(data, 0);
};

const navChange = (data) => {
  const { curFolder } = data;
  currentFolder.value = curFolder;
  showLoading.value = true;
  loadDataList();
};

// 获取家庭空间使用情况
const getFamilySpaceUsage = async () => {
  if (!familyId.value) return;
  let result = await proxy.Request({
    url: api.getFamilySpaceUsage,
    params: {
      familyId: familyId.value,
    },
    showLoading: false,
  });
  if (result && result.data) {
    familySpaceInfo.value = result.data;
  }
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

onMounted(() => {
  checkFamily();
});
</script>

<style lang="scss" scoped>
@import "@/assets/file.list.scss";

.family-space {
  .no-family {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    height: 60vh;
    gap: 20px;

    .tips {
      font-size: 16px;
      color: var(--text-secondary);
    }

    .loading-text {
      font-size: 16px;
      color: var(--text-secondary);
    }
  }

  .top-op {
    .space-info {
      display: flex;
      align-items: center;
      gap: 8px;
      margin-left: auto;
      padding: 0 10px;
      
      .space-text {
        font-size: 12px;
        color: var(--text-secondary);
        white-space: nowrap;
      }
      
      .space-progress {
        width: 100px;
        
        :deep(.el-progress-bar__outer) {
          background-color: var(--border-light);
        }
      }
    }
  }
}

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
