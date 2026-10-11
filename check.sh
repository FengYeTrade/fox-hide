#!/system/bin/sh
# FoxHide — 暴露点自检工具
# 用法（需 root）：  su -c sh /data/adb/foxhide/check.sh
# 逐项列出当前设备的 root 检测暴露面，以及 FoxHide 是否已覆盖。

PASS=0; FAIL=0
pass() { echo "  [PASS] $1"; PASS=$((PASS+1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }

echo "==== FoxHide 暴露点自检 ===="

echo "-- 1. Bootloader / Verified Boot --"
for k in ro.boot.verifiedbootstate ro.boot.flash.locked ro.boot.vbmeta.device_state ro.boot.warranty_bit ro.boot.veritymode; do
  v=$(getprop $k 2>/dev/null)
  case "$v" in
    green|1|locked|enforcing) pass "$k=$v" ;;
    *) fail "$k=$v (应为 green/1/locked/enforcing)" ;;
  esac
done

echo "-- 2. 系统安全属性 --"
for k in ro.debuggable ro.secure ro.build.type ro.build.tags; do
  v=$(getprop $k 2>/dev/null)
  case "$v" in
    0|1|user|release-keys) pass "$k=$v" ;;
    *) fail "$k=$v" ;;
  esac
done

echo "-- 3. Root 管理器痕迹 --"
for k in magisk.version magisk.versionCode ksu.version ap.version init.svc.magiskd; do
  v=$(getprop $k 2>/dev/null)
  if [ -z "$v" ]; then pass "$k 已隐藏(空)"
  else fail "$k=$v (泄漏!)"; fi
done

echo "-- 4. su 文件痕迹 --"
for i in /system/xbin/su /system/bin/su /sbin/su /vendor/bin/su; do
  if [ -e "$i" ]; then fail "$i 存在"; else pass "$i 已清理"; fi
done

echo "-- 5. 常用检测路径 --"
for i in /sbin/.magisk /debug_ramdisk/magisk /data/adb/magisk; do
  if [ -e "$i" ]; then echo "  [INFO] $i 存在（Magisk 运行必需，依赖 DenyList 进程级隐藏）"; fi
done

echo ""
echo "==== 结果: PASS=$PASS FAIL=$FAIL ===="
echo "提示: 属性与文件层由 FoxHide 覆盖；进程级 syscall 拦截请配合 Zygisk + DenyList（如 Shamiko）。"
