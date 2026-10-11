#!/system/bin/sh
# FoxHide — 卸载清理脚本
FOXHIDE_DIR=/data/adb/foxhide
rm -rf $FOXHIDE_DIR
# 恢复被删除的静态 su 占位（可选，避免卸载后系统异常）
for i in /system/xbin/su /system/bin/su /sbin/su /vendor/bin/su; do
  [ -e "$i" ] || touch "$i" 2>/dev/null
done
exit 0
