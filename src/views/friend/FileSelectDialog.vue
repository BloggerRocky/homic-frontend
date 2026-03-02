<template>
  <el-dialog
    v-model="dialogVisible"
    title="选择要分享的文件"
    width="900px"
    :close-on-click-modal="false"
    @close="handleClose"
  >
    <div class="file-select-content">
      <!-- 已选择文件数量提示 -->
      <div class="selected-info" v-if="selectedFiles.length > 0">
        <i class="iconfont icon-ok"></i>
        已选择 <span class="count">{{ selectedFiles.length }}</span> 个文件
      </div>

      <!-- 面包屑导航 -->
      <div class="breadcrumb-nav">
        <el-breadcrumb separator="/">
          <el-breadcrumb-item @click="navigateToFolder('0')">
            <span class="breadcrumb-link">全部文件</span>
          </el-breadcrumb-item>
          <el-breadcrumb-item
            v-for="folder in breadcrumbPath"
            :key="folder.fileId"
            @click="navigateToFolder(folder.fileId)"
          >
            <span class="breadcrumb-link">{{ folder.fileName }}</span>
          </el-breadcrumb-item>
        </el-breadcrumb>
      </div>

      <!-- 搜索框 -->
      <div class="search-bar">
        <el-input
          v-model="searchKeyword"
          placeholder="搜索文件名"
          clearable
          @keyup.enter="searchFiles"
        >
          <template #suffix>
            <i class="iconfont icon-search" @click="searchFiles"></i>
          </template>
        </el-input>
      </div>

      <!-- 有效期选择 -->
      <div class="valid-type-selector">
        <span class="label">有效期：</span>
        <el-radio-group v-model="validType">
          <el-radio :label="0">永久</el-radio>
          <el-radio :label="1">1天</el-radio>
          <el-radio :label="2">7天</el-radio>
          <el-radio :label="3">30天</el-radio>
        </el-radio-group>
      </div>

      <!-- 文件列表 -->
      <div class="file-list">
        <div v-if="fileList.length === 0" class="empty-state">
          <el-empty description="暂无文件" />
        </div>
        <div v-else class="file-items">
          <div
            v-for="file in fileList"
            :key="file.fileId"
            :class="['file-item', { selected: isSelected(file.fileId), 'is-folder': file.folderType === 1 }]"
            @click="handleFileClick(file)"
          >
            <el-checkbox
              v-if="file.folderType === 0"
              :model-value="isSelected(file.fileId)"
              @change="toggleSelect(file)"
              @click.stop
            />
            <div v-else class="folder-placeholder"></div>
            <div class="file-icon">
              <Icon
                v-if="file.folderType === 0"
                :fileType="file.fileType"
                :width="32"
              />
              <Icon v-else :fileType="0" :width="32" />
            </div>
            <div class="file-info">
              <div class="file-name">
                {{ file.fileName }}
                <i v-if="file.folderType === 1" class="iconfont icon-right"></i>
              </div>
              <div class="file-meta">
                <span v-if="file.fileSize" class="file-size">
                  {{ formatSize(file.fileSize) }}
                </span>
                <span class="file-time">{{ file.lastUpdateTime }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 分页 -->
      <div class="pagination" v-if="total > 0">
        <el-pagination
          v-model:current-page="pageNo"
          v-model:page-size="pageSize"
          :total="total"
          :page-sizes="[10, 20, 50, 100]"
          layout="total, sizes, prev, pager, next"
          @current-change="loadFileList"
          @size-change="loadFileList"
        />
      </div>
    </div>

    <template #footer>
      <div class="dialog-footer">
        <div class="selected-count">
          已选择 <span class="count">{{ selectedFiles.length }}</span> 个文件
        </div>
        <div class="actions">
          <el-button type="primary" @click="confirmSelect" :disabled="selectedFiles.length === 0">
            分享
          </el-button>
          <el-button @click="dialogVisible = false">取消</el-button>
        </div>
      </div>
    </template>
  </el-dialog>
</template>

<script setup>
import { ref, getCurrentInstance } from 'vue'
import { ElMessage } from 'element-plus'
import Icon from '@/components/Icon.vue'

const { proxy } = getCurrentInstance()

const emit = defineEmits(['confirm'])

const api = {
  loadDataList: '/file/loadDataList',
  getFolderInfo: '/file/getFolderInfo',
}

const dialogVisible = ref(false)
const searchKeyword = ref('')
const validType = ref(0)
const fileList = ref([])
const selectedFiles = ref([])
const pageNo = ref(1)
const pageSize = ref(20)
const total = ref(0)
const currentFolderId = ref('0')
const breadcrumbPath = ref([])

// 打开对话框
const show = () => {
  dialogVisible.value = true
  selectedFiles.value = []
  searchKeyword.value = ''
  pageNo.value = 1
  currentFolderId.value = '0'
  breadcrumbPath.value = []
  loadFileList()
}

// 加载文件列表
const loadFileList = async () => {
  try {
    const result = await proxy.Request({
      url: api.loadDataList,
      params: {
        pageNo: pageNo.value,
        pageSize: pageSize.value,
        fileNameFuzzy: searchKeyword.value,
        category: 'all',
        filePid: currentFolderId.value
      },
      showLoading: false
    })
    
    if (result && result.data) {
      fileList.value = result.data.list || []
      total.value = result.data.totalCount || 0
    }
  } catch (error) {
    console.error('加载文件列表失败:', error)
  }
}

// 搜索文件
const searchFiles = () => {
  pageNo.value = 1
  loadFileList()
}

// 判断是否已选择
const isSelected = (fileId) => {
  return selectedFiles.value.some(f => f.fileId === fileId)
}

// 处理文件点击
const handleFileClick = (file) => {
  if (file.folderType === 1) {
    // 点击文件夹，进入文件夹
    enterFolder(file)
  } else {
    // 点击文件，切换选择状态
    toggleSelect(file)
  }
}

// 进入文件夹
const enterFolder = async (folder) => {
  currentFolderId.value = folder.fileId
  breadcrumbPath.value.push({
    fileId: folder.fileId,
    fileName: folder.fileName
  })
  pageNo.value = 1
  await loadFileList()
}

// 导航到指定文件夹
const navigateToFolder = async (folderId) => {
  if (folderId === '0') {
    // 返回根目录
    currentFolderId.value = '0'
    breadcrumbPath.value = []
  } else {
    // 返回到面包屑中的某个文件夹
    const index = breadcrumbPath.value.findIndex(f => f.fileId === folderId)
    if (index !== -1) {
      currentFolderId.value = folderId
      breadcrumbPath.value = breadcrumbPath.value.slice(0, index + 1)
    }
  }
  pageNo.value = 1
  await loadFileList()
}

// 切换选择（仅对文件有效）
const toggleSelect = (file) => {
  if (file.folderType === 1) {
    return // 文件夹不能被选择
  }
  
  const index = selectedFiles.value.findIndex(f => f.fileId === file.fileId)
  if (index > -1) {
    selectedFiles.value.splice(index, 1)
  } else {
    selectedFiles.value.push(file)
  }
}

// 确认选择
const confirmSelect = () => {
  if (selectedFiles.value.length === 0) {
    ElMessage.warning('请选择要分享的文件')
    return
  }
  
  emit('confirm', selectedFiles.value, validType.value)
  dialogVisible.value = false
}

// 格式化文件大小
const formatSize = (size) => {
  return proxy.Utils.size2Str(size)
}

// 关闭对话框
const handleClose = () => {
  selectedFiles.value = []
  fileList.value = []
}

defineExpose({
  show
})
</script>

<style lang="scss" scoped>
.file-select-content {
  .selected-info {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 12px 16px;
    background: linear-gradient(135deg, #e3f2fd 0%, #bbdefb 100%);
    border-radius: 8px;
    margin-bottom: 15px;
    font-size: 14px;
    color: #1976d2;
    font-weight: 500;
    box-shadow: 0 2px 8px rgba(25, 118, 210, 0.15);

    .iconfont {
      font-size: 18px;
      color: #1976d2;
    }

    .count {
      font-weight: 700;
      font-size: 18px;
      color: #0d47a1;
    }
  }

  .breadcrumb-nav {
    margin-bottom: 15px;
    padding: 10px 12px;
    background-color: #f5f7fa;
    border-radius: 4px;
    border: 1px solid #e4e7ed;

    .breadcrumb-link {
      cursor: pointer;
      color: #409eff;
      transition: all 0.3s ease;

      &:hover {
        color: #66b1ff;
        text-decoration: underline;
      }
    }
  }

  .search-bar {
    margin-bottom: 15px;

    .el-input {
      width: 100%;
    }

    .iconfont {
      cursor: pointer;
      color: #409eff;
    }
  }

  .valid-type-selector {
    display: flex;
    align-items: center;
    margin-bottom: 15px;
    padding: 10px;
    background-color: #f5f7fa;
    border-radius: 4px;

    .label {
      font-weight: 500;
      margin-right: 15px;
      color: #606266;
    }
  }

  .file-list {
    max-height: 450px;
    overflow-y: auto;
    border: 1px solid #e4e7ed;
    border-radius: 4px;
    padding: 10px;

    .empty-state {
      padding: 40px 0;
      text-align: center;
    }

    .file-items {
      display: flex;
      flex-direction: column;
      gap: 8px;

      .file-item {
        display: flex;
        align-items: center;
        gap: 12px;
        padding: 12px;
        border-radius: 6px;
        cursor: pointer;
        transition: all 0.3s ease;
        border: 2px solid transparent;

        &:hover {
          background-color: #f5f7fa;
        }

        &.selected {
          background-color: #e3f2fd;
          border-color: #409eff;
        }

        &.is-folder {
          cursor: pointer;
          
          &:hover {
            background-color: #fff3e0;
          }
        }

        .folder-placeholder {
          width: 16px;
          flex-shrink: 0;
        }

        .file-icon {
          flex-shrink: 0;
        }

        .file-info {
          flex: 1;
          min-width: 0;

          .file-name {
            font-size: 14px;
            font-weight: 500;
            color: #333;
            margin-bottom: 4px;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
            display: flex;
            align-items: center;
            gap: 6px;

            .iconfont {
              font-size: 12px;
              color: #909399;
            }
          }

          .file-meta {
            display: flex;
            gap: 15px;
            font-size: 12px;
            color: #909399;

            .file-size {
              &::after {
                content: '•';
                margin-left: 15px;
              }
            }
          }
        }
      }
    }
  }

  .pagination {
    margin-top: 15px;
    display: flex;
    justify-content: center;
  }
}

.dialog-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;

  .selected-count {
    font-size: 14px;
    color: #606266;

    .count {
      font-weight: 600;
      color: #409eff;
      font-size: 16px;
    }
  }

  .actions {
    display: flex;
    gap: 10px;
  }
}
</style>
