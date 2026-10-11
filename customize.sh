#!/system/bin/sh
# FoxHide — 安装脚本（customize.sh）
# 兼容 Magisk / KernelSU / APatch。KernelSU/APatch 需要模块支持标识：
# KernelSU: KSU=true 环境变量由 KSU 注入；APatch: APATCH=true。

SKIPMOUNT=false
PROPFILE=false
POSTFSDATA=true
LATESTARTSERVICE=true

FOXHIDE_DIR=/data/adb/foxhide

ui_print "*******************************"
ui_print "  FoxHide Root Conceal v1.0"
ui_print "  深度隐藏 Root 环境模块"
ui_print "  支持 Magisk / KernelSU / APatch"
ui_print "*******************************"

# 检测 Root 管理器
if [ -d /data/adb/magisk ] || [ -n "$MAGISK_VER_CODE" ]; then
  ui_print "[*] 检测到 Root 管理器: Magisk"
elif [ -d /data/adb/ksu ] || [ "$KSU" = "true" ]; then
  ui_print "[*] 检测到 Root 管理器: KernelSU"
elif [ -d /data/adb/ap ] || [ "$APATCH" = "true" ]; then
  ui_print "[*] 检测到 Root 管理器: APatch"
else
  ui_print "[!] 未识别 Root 管理器，仍按通用模块安装"
fi

# 创建配置目录与默认配置
mkdir -p $FOXHIDE_DIR
if [ ! -f $FOXHIDE_DIR/config.prop ]; then
  cat > $FOXHIDE_DIR/config.prop <<'EOF'
# FoxHide 配置
# enable=1 启用模块；0 停用（重启生效）
enable=1
# 各隐藏层开关（1 开 / 0 关）
conceal_boot=1
conceal_system=1
conceal_manager=1
conceal_fs=1
conceal_env=1
EOF
  ui_print "[*] 已写入默认配置 /data/adb/foxhide/config.prop"
fi

ui_print "[*] 安装完成，请重启设备生效"
ui_print "[*] 重要：请在 Magisk 中开启 Zygisk 并启用 DenyList，"
ui_print "[*] 把需要隐藏的 App 加入 DenyList（关闭「遵守排除列表」）"
