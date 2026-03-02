<template>
  <div class="family-manage">
    <div class="content-wrapper">
      <div class="welcome-section">
        <img src="@/assets/friend_code_ungenerated.png" alt="家庭管理" class="welcome-image" />
        <div class="info-card">
          <p class="title">家庭管理</p>
          <p class="description">创建或加入家庭，与家人共享文件和空间</p>
          <div class="button-group">
            <button class="custom-btn btn-generate">
              创建家庭
            </button>
            <button class="custom-btn btn-search">
              加入家庭
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, getCurrentInstance } from 'vue'

const { proxy } = getCurrentInstance()
</script>

<style lang="scss" scoped>
.family-manage {
  padding: 20px;
  background-color: var(--bg-primary);

  .content-wrapper {
    max-width: 600px;
    margin: 0 auto;
  }

  // 自定义按钮样式
  .custom-btn {
    min-width: 150px;
    padding: 10px 20px;
    border: 3px solid #d3d3d3;
    border-radius: 4px;
    font-size: 14px;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.3s ease;
    white-space: nowrap;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);

    &:disabled {
      opacity: 0.6;
      cursor: not-allowed;
    }

    &.btn-generate {
      background-color: #67c23a;
      color: white;

      &:hover:not(:disabled) {
        background-color: #85ce61;
      }

      &:active:not(:disabled) {
        background-color: #5daf34;
      }
    }

    &.btn-search {
      background-color: #409eff;
      color: white;

      &:hover:not(:disabled) {
        background-color: #66b1ff;
      }

      &:active:not(:disabled) {
        background-color: #0a66d6;
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
        line-height: 1.6;
      }

      .button-group {
        display: flex;
        gap: 10px;
        justify-content: center;
      }
    }
  }
}
</style>
