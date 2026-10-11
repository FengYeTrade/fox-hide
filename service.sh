#!/system/bin/sh
# FoxHide — service 阶段（系统服务起来后，做文件与环境清理）
MODDIR=${0%/*}
[ -f "$MODDIR/conceal.sh" ] && . "$MODDIR/conceal.sh"

enabled=$(cfg enable 1)
[ "$enabled" = "1" ] || exit 0

[ "$(cfg conceal_fs 1)" = "1" ] && conceal_fs_traces
[ "$(cfg conceal_env 1)" = "1" ] && conceal_env
check_denylist

# 守卫循环：每 30 秒清理一次易再生痕迹（后台，低占用）
(
  while :; do
    sleep 30
    [ "$(cfg enable 1)" = "1" ] || break
    [ "$(cfg conceal_fs 1)" = "1" ] && conceal_fs_traces
  done
) &
log "service conceal started (guard loop pid $!)"
