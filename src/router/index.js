import { createRouter, createWebHistory } from 'vue-router'
import VueCookies from 'vue-cookies'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/login',
      name: '登录',
      component: () => import("@/views/Login.vue")
    },
    {
      path: "/",
      component: () => import("@/views/Framework.vue"),
      children: [
        {
          path: '/',
          redirect: "/main/all"
        },
        {
          path: '/main/:category',
          name: '首页',
          meta: {
            needLogin: true,
            menuCode: "main"
          },
          component: () => import("@/views/main/Main.vue")
        },
        {
          path: '/myshare',
          name: '我的分享',
          meta: {
            needLogin: true,
            menuCode: "share"
          },
          component: () => import("@/views/share/Share.vue")
        },
        {
          path: '/recycle',
          name: '回收站',
          meta: {
            needLogin: true,
            menuCode: "recycle"
          },
          component: () => import("@/views/recycle/Recycle.vue")
        },
        {
          path: '/settings/sysSetting',
          name: '系统设置',
          meta: {
            needLogin: true,
            menuCode: "settings"
          },
          component: () => import("@/views/admin/SysSettings.vue")
        },
        {
          path: '/settings/userList',
          name: '用户管理',
          meta: {
            needLogin: true,
            menuCode: "settings"
          },
          component: () => import("@/views/admin/UserList.vue")
        },
        {
          path: '/settings/fileList',
          name: '用户文件',
          meta: {
            needLogin: true,
            menuCode: "settings"
          },
          component: () => import("@/views/admin/FileList.vue")
        },
        {
          path: '/friend/myFriends',
          name: '我的好友',
          meta: {
            needLogin: true,
            menuCode: "friend"
          },
          component: () => import("@/views/friend/MyFriends.vue")
        },
        {
          path: '/friend/search',
          name: '搜寻好友',
          meta: {
            needLogin: true,
            menuCode: "friend"
          },
          component: () => import("@/views/friend/SearchFriends.vue")
        },
        {
          path: '/friend/requests',
          name: '好友申请',
          meta: {
            needLogin: true,
            menuCode: "friend"
          },
          component: () => import("@/views/friend/FriendRequests.vue")
        },
        {
          path: '/family',
          name: '家庭管理',
          meta: {
            needLogin: true,
            menuCode: "family"
          },
          component: () => import("@/views/Family.vue")
        },
        {
          path: '/family/careAccount',
          name: '关怀账号',
          meta: {
            needLogin: true,
            menuCode: "family"
          },
          component: () => import("@/views/family/CareAccount.vue")
        },
      ]
    },
    {
      path: '/shareCheck/:shareId',
      name: '分享校验',
      component: () => import("@/views/webshare/ShareCheck.vue")
    },
    {
      path: '/share/:shareId',
      name: '分享',
      component: () => import("@/views/webshare/Share.vue")
    }, {
      path: '/qqlogincalback',
      name: "qq登录回调",
      component: () => import('@/views/QqLoginCallback.vue'),
    }
  ]
})

router.beforeEach((to, from, next) => {
  const userInfo = VueCookies.get("userInfo");
  if (to.meta.needLogin != null && to.meta.needLogin && userInfo == null) {
    router.push("/login");
  }
  next();
})

export default router
