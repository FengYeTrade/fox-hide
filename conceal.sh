#!/system/bin/sh
# FoxHide Root Conceal — 核心隐藏引擎
# 被 post-fs-data.sh 与 service.sh 调用。纯 POSIX sh，兼容 Magisk/KernelSU/APatch。

# ---------- 路径与配置 ----------
FOXHIDE_DIR=${FOXHIDE_DIR:-/data/adb/foxhide}
CONFIG_FILE=$FOXHIDE_DIR/config.prop
LOG_FILE=$FOXHIDE_DIR/foxhide.log
MAGISKTMP=$(magisk --path 2>/dev/null || echo /sbin)

# 日志（magisk 模块标准写法）
log() { echo "[FoxHide] $(date '+%Y-%m-%d %H:%M:%S') $*" >> $LOG_FILE 2>/dev/null; }

# 读取配置：cfg <key> <default>
cfg() {
  [ -f "$CONFIG_FILE" ] || return 0
  local v=$(grep "^$1=" "$CONFIG_FILE" 2>/dev/null | head -n1 | cut -d= -f2-)
  echo "${v:-$2}"
}

# ---------- resetprop 定位（兼容 Magisk/KSU/APatch） ----------
find_resetprop() {
  for p in \
    "$MAGISKTMP/resetprop" \
    /data/adb/magisk/resetprop \
    /data/adb/ksu/bin/resetprop \
    /data/adb/ap/bin/resetprop \
    /data/adb/ksu/bin/busybox \
    /system/bin/resetprop; do
    [ -x "$p" ] && { echo "$p"; return 0; }
  done
  command -v resetprop 2>/dev/null
}

# 设置属性：setprop_key <key> <value>（先删后设，避免只读冲突）
setprop_key() {
  local rp=$(find_resetprop)
  [ -n "$rp" ] || { log "resetprop not found"; return 1; }
  "$rp" --delete "$1" 2>/dev/null
  "$rp" "$1" "$2" 2>/dev/null && log "prop $1=$2"
}

# 删除属性（隐藏 magisk 自身痕迹）
delprop_key() {
  local rp=$(find_resetprop)
  [ -n "$rp" ] || return 1
  "$rp" --delete "$1" 2>/dev/null && log "del prop $1"
}

# ---------- 第一层：Bootloader / Verified Boot 状态伪装 ----------
conceal_boot_state() {
  setprop_key ro.boot.verifiedbootstate green
  setprop_key ro.boot.flash.locked 1
  setprop_key ro.boot.vbmeta.device_state locked
  setprop_key ro.boot.warranty_bit 0
  setprop_key ro.boot.warranty_bit_0 0
  setprop_key ro.boot.veritymode enforcing
  setprop_key ro.boot.verifiedbootstate.green 1
  setprop_key ro.boot.oem_unlock_supported 0
  setprop_key ro.boot.secureboot 1
  setprop_key sys.oem_unlock_allowed 0
  log "boot state concealed"
}

# ---------- 第二层：系统安全属性伪装 ----------
conceal_system_props() {
  setprop_key ro.debuggable 0
  setprop_key ro.secure 1
  setprop_key ro.build.type user
  setprop_key ro.build.tags release-keys
  setprop_key ro.build.selinux 1
  setprop_key ro.allow.mock.location 0
  setprop_key ro.kernel.qemu 0
  log "system props concealed"
}

# ---------- 第三层：隐藏 Magisk / Root 管理器痕迹 ----------
conceal_manager_traces() {
  # Magisk 自身属性
  delprop_key magisk.version
  delprop_key magisk.versionCode
  delprop_key magisk.apk
  # KSU 属性
  delprop_key ksu.version
  delprop_key ksu.versionCode
  delprop_key ksu.running
  # APatch 属性
  delprop_key ap.version
  delprop_key ap.versionCode
  # 服务状态（对应用可见的 init 服务名）
  delprop_key init.svc.magiskd
  delprop_key init.svc.zygiskd
  delprop_key init.svc.ksud
  # 包管理痕迹
  setprop_key ro.package.installed.magisk "" 2>/dev/null
  log "manager traces concealed"
}

# ---------- 第四层：文件系统痕迹清理 ----------
conceal_fs_traces() {
  local i
  # 常见 su 暴露路径（仅移除可安全清理的静态残留；Magisk overlay 部分不破坏）
  for i in /system/xbin/su /system/bin/su /sbin/su /vendor/bin/su; do
    [ -e "$i" ] && { rm -f "$i" 2>/dev/null; log "removed $i"; }
  done
  # 清空可检测的日志与 shell 历史
  : > /data/adb/magisk/.magisk.log 2>/dev/null
  rm -f /data/local/tmp/magisk.log /data/local/tmp/.magisk 2>/dev/null
  # 常见检测目录占位清理（保留目录本身避免破坏挂载）
  for i in /data/adb/magisk /data/adb/ksu /data/adb/ap; do
    [ -d "$i" ] && chmod 700 "$i" 2>/dev/null
  done
  log "fs traces concealed"
}

# ---------- 第五层：可执行环境清理 ----------
conceal_env() {
  # 移除可能泄漏 su 的全局环境入口（对当前 shell 及其子进程生效）
  local path_clean=""
  local p
  IFS=:; for p in $PATH; do
    case "$p" in
      *magisk*|*/sbin*|*/su*) ;;
      *) path_clean="$path_clean${path_clean:+:}$p" ;;
    esac
  done; unset IFS
  export PATH=$path_clean
  # 常见 shell 泄漏
  unset MAGISK_BOOTMODE 2>/dev/null
  log "env concealed"
}

# ---------- 第六层：DenyList 协同（引导用户在管理器里勾选） ----------
# 本模块不强制修改 Magisk 数据库；检测并提示
check_denylist() {
  if [ -f /data/adb/magisk.db ] || [ -d /data/adb/denylist ]; then
    log "denylist detected, user should enable Zygisk + DenyList in Magisk"
  fi
}

# ---------- 主入口 ----------
main() {
  local enabled=$(cfg enable 1)
  [ "$enabled" = "1" ] || { log "disabled by config"; exit 0; }

  [ "$(cfg conceal_boot 1)" = "1" ] && conceal_boot_state
  [ "$(cfg conceal_system 1)" = "1" ] && conceal_system_props
  [ "$(cfg conceal_manager 1)" = "1" ] && conceal_manager_traces
  [ "$(cfg conceal_fs 1)" = "1" ] && conceal_fs_traces
  [ "$(cfg conceal_env 1)" = "1" ] && conceal_env
  check_denylist
  log "conceal run finished"
}

main "$@"
