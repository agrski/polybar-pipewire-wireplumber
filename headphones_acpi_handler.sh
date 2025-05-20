for PID in $(pidof polybar); do
    XDG_RUNTIME_DIR=/run/user/1000 polybar-msg -p $PID action "#pipewire.hook.0"
done
