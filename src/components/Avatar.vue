<template>
  <span class="avatar" :style="{ width: width + 'px', height: width + 'px' }">
    <img
      :src="avatarUrl"
      @error="handleImageError"
      v-if="userId"
      :alt="userId"
    />
    <img
      v-else
      :src="defaultAvatar"
      :alt="'默认头像'"
    />
  </span>
</template>

<script setup>
import { getCurrentInstance, ref, computed } from "vue";
import defaultUserAvatar from '@/assets/default/default_user_avatar.jpg';
import defaultFamilyAvatar from '@/assets/default/default_family_avatar.png';

const { proxy } = getCurrentInstance();

const props = defineProps({
  userId: {
    type: String,
  },
  avatar: {
    type: String,
  },
  timestamp: {
    type: Number,
    default: 0,
  },
  width: {
    type: Number,
    default: 40,
  },
  type: {
    type: String,
    default: 'user', // 'user' 或 'family'
  },
});

const imageError = ref(false);

// 根据类型选择默认头像
const defaultAvatar = computed(() => {
  return props.type === 'family' ? defaultFamilyAvatar : defaultUserAvatar;
});

// 计算头像 URL
const avatarUrl = computed(() => {
  // 重置错误状态（当 props 变化时）
  imageError.value = false;
  
  if (imageError.value) {
    return defaultAvatar.value;
  }
  
  // 如果 avatar 是完整的 URL（以 http:// 或 https:// 开头），直接使用
  if (props.avatar && props.avatar !== '' && (props.avatar.startsWith('http://') || props.avatar.startsWith('https://'))) {
    return props.avatar;
  }
  
  if (props.userId) {
    // 根据类型使用不同的 API 路径
    if (props.type === 'family') {
      const ts = props.timestamp > 0 ? `?${props.timestamp}` : '';
      return `/api/family/getAvatar/${props.userId}${ts}`;
    } else {
      return `${proxy.globalInfo.avatarUrl}${props.userId}?${props.timestamp}`;
    }
  }
  
  return defaultAvatar.value;
});

// 处理图片加载错误
const handleImageError = () => {
  imageError.value = true;
};
</script>

<style lang="scss" scoped>
.avatar {
  display: flex;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  overflow: hidden;
  background-color: var(--bg-secondary);
  
  img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }
}
</style>