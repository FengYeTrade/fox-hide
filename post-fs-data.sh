#!/system/bin/sh
# FoxHide — post-fs-data 阶段（最早启动，适合改只读属性）
MODDIR=${0%/*}
[ -f "$MODDIR/conceal.sh" ] && . "$MODDIR/conceal.sh"

# 此阶段只做属性层伪装（resetprop 在最早阶段最有效）
enabled=$(cfg enable 1)
[ "$enabled" = "1" ] || exit 0

[ "$(cfg conceal_boot 1)" = "1" ] && conceal_boot_state
[ "$(cfg conceal_system 1)" = "1" ] && conceal_system_props
[ "$(cfg conceal_manager 1)" = "1" ] && conceal_manager_traces
log "post-fs-data conceal done"
