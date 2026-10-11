# FoxHide Root Conceal

深度隐藏 Root 环境的 Android 模块，兼容 **Magisk / KernelSU / APatch** 全部 Root 管理器安装。

## 功能

| 层级 | 作用 | 说明 |
|---|---|---|
| Bootloader 状态伪装 | `ro.boot.verifiedbootstate=green`、`ro.boot.flash.locked=1`、`ro.boot.vbmeta.device_state=locked`、`ro.boot.warranty_bit=0`、`ro.boot.veritymode=enforcing` 等 | 让检测方认为 BL 处于锁定、验证启动通过 |
| 系统安全属性伪装 | `ro.debuggable=0`、`ro.secure=1`、`ro.build.type=user`、`ro.build.tags=release-keys` | 消除可调试/工程版特征 |
| Root 管理器痕迹隐藏 | 删除 `magisk.version`、`magisk.versionCode`、`ksu.version`、`ap.version`、`init.svc.magiskd` 等属性 | 属性层查不到管理器存在 |
| 文件系统痕迹清理 | 清理 `/system/xbin/su`、`/system/bin/su`、`/sbin/su`、`/vendor/bin/su` 静态残留、magisk 日志、shell 历史 | 减少 su 文件层暴露 |
| 环境变量清理 | 从 PATH 剔除 `su/magisk` 目录、清除泄漏环境变量 | 降低 shell 层泄漏 |
| 守卫循环 | 每 30 秒重扫一次易再生痕迹 | 防止被运行时重新植入 |
| 暴露点自检 | 内置 `check.sh`，一键列出当前设备仍暴露的检测面 | 安装后可验证效果 |

## 安装

1. 在 Magisk / KernelSU / APatch 的「模块」页安装 `foxhide-v1.0.zip`
2. 重启设备
3. **关键配合**（进程级隐藏）：
   - Magisk：设置 → 开启 **Zygisk** → 开启 **DenyList**，把需要隐藏的 App 勾入名单，**关闭**「遵守排除列表」（让 Shamiko/FoxHide 接管）
   - KernelSU：开启 Zygisk 兼容（部分版本）或使用内核级 DenyList
4. 验证：`su -c sh /data/adb/foxhide/check.sh`

## 配置

编辑 `/data/adb/foxhide/config.prop` 可逐层开关（重启生效）：

```ini
enable=1          # 模块总开关
conceal_boot=1    # Bootloader 状态伪装
conceal_system=1  # 系统安全属性
conceal_manager=1 # 管理器痕迹
conceal_fs=1      # 文件痕迹
conceal_env=1     # 环境变量
```

## 原理简述

- **属性层**：利用各 Root 管理器的 `resetprop` 在 `post-fs-data` 阶段改写只读 `ro.*` 属性（先删后设，规避只读限制），这是属性层隐藏最有效的时机
- **文件层**：清理可安全移除的静态 su 残留与日志（Magisk overlay 挂载本身交给 DenyList 进程级 unmount）
- **进程层**：shell 模块无法拦截 syscall——进程级深度隐藏由 Zygisk/DenyList 生态负责（如 Shamiko），本模块与它们互补叠加

## 合规声明

本模块仅用于**你自己的设备**的隐私管理与合规测试：隐藏自身设备 Root 状态、自查环境暴露面。不得用于绕过银行/政务/企业应用的风控、游戏作弊、欺诈或其他非法用途。解锁 Bootloader 与 Root 可能违反设备保修条款，风险自负。

## 结构

```
foxhide/
├── module.prop        # 模块元数据
├── customize.sh       # 安装脚本（检测管理器、写配置）
├── post-fs-data.sh    # 早期属性伪装
├── service.sh         # 服务阶段清理 + 守卫循环
├── conceal.sh         # 核心隐藏引擎（六层）
├── uninstall.sh       # 卸载清理
├── check.sh           # 暴露点自检工具
└── README.md
```

MIT License
