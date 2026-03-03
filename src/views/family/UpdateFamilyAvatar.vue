<template>
  <div>
    <Dialog
      :show="dialogConfig.show"
      :title="dialogConfig.title"
      :buttons="dialogConfig.buttons"
      width="500px"
      :showCancel="true"
      @close="dialogConfig.show = false"
    >
      <el-form
        :model="formData"
        ref="formDataRef"
        label-width="80px"
        @submit.prevent
      >
        <el-form-item label="家庭名称" prop="">
          {{ formData.familyName }}
        </el-form-item>
        <el-form-item label="家庭头像" prop="">
          <AvatarUpload v-model="formData.avatar" :avatarUrl="formData.avatarUrl"></AvatarUpload>
        </el-form-item>
      </el-form>
    </Dialog>
  </div>
</template>

<script setup>
import AvatarUpload from "@/components/AvatarUpload.vue";

import { ref, reactive, getCurrentInstance } from "vue";
const { proxy } = getCurrentInstance();

const api = {
  updateAvatar: '/family/updateAvatar',
};

const formData = ref({});
const formDataRef = ref();

const show = (data) => {
  formData.value = Object.assign({}, data);
  formData.value.avatar = { userId: data.familyId, qqAvatar: data.familyAvatar };
  formData.value.avatarUrl = `/api/family/getAvatar/${data.familyId}`;
  dialogConfig.value.show = true;
};

defineExpose({ show });

const dialogConfig = ref({
  show: false,
  title: "修改家庭头像",
  buttons: [
    {
      type: "primary",
      text: "确定",
      click: (e) => {
        submitForm();
      },
    },
  ],
});

const emit = defineEmits(["updateAvatar"]);
const submitForm = async () => {
  if (!(formData.value.avatar instanceof File)) {
    dialogConfig.value.show = false;
    return;
  }
  let result = await proxy.Request({
    url: api.updateAvatar,
    params: {
      familyAvatar: formData.value.avatar,
    },
  });
  if (!result) {
    return;
  }
  dialogConfig.value.show = false;
  proxy.Message.success('头像更新成功');
  emit("updateAvatar");
};
</script>

<style lang="scss">
</style>
