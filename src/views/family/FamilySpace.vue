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
          <div class="btn" v-if="canUpload">
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
          <el-button type="success" @click="newFolder" v-if="canUpload">
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
        </div>
        <!--导航-->
        <Navigation ref="navigationRef" :familyId="familyId" @navChange="navChange"></Navigation>
      </div>
      <div class="file-list" v-if="tableData.list && tableData.list.length > 0">
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
                  <el-dropdown-item command="delete" v-if="row.fileId && row.status == 2 && canUpload">
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
    </div>
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
const canUpload = ref(false);

const api = {
  checkFamily: "/family/checkFamily",
  getFamilyInfo: "/family/getFamilyInfo",
  loadDataList: "/familySpace/loadDataList",
  uploadFile: "/familySpace/uploadFile",
  newFolder: "/familySpace/newFolder",
  createDownloadUrl: "/file/createDownloadUrl",
  download: "/api/file/download",
  delFile: "/file/delFile",
};

// 检查家庭信息并确认上传权限
const checkFamily = async () => {
  const result = await proxy.Request({
    url: api.checkFamily,
    showLoading: false,
  });
  if (result && result.data) {
    familyId.value = result.data.familyId || null;
    // 判断上传权限：非关怀账号 且 role为0(创建者)或1(管理员)
    const userInfo = proxy.VueCookies.get("userInfo");
    if (userInfo && userInfo.isDummy) {
      canUpload.value = false;
    } else {
      // role: 0-创建者, 1-管理员, 2-普通成员
      const role = result.data.role;
      canUpload.value = (role === 0 || role === 1);
    }
  } else {
    familyId.value = null;
    canUpload.value = false;
  }
  hasFamilyLoaded.value = true;
  if (familyId.value) {
    loadDataList();
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
  }
};

// 操作
const handleOperation = (command, row, index) => {
  switch (command) {
    case 'download':
      download(row);
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

// 删除
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

// 导航
const navChange = (data) => {
  const { curFolder } = data;
  currentFolder.value = curFolder;
  showLoading.value = true;
  loadDataList();
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
}
</style>
