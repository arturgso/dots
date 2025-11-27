#!/usr/bin/env bash

## Import Current Theme
source "$HOME"/.dots/rofi/applets/shared/theme.bash
theme="$type/$style"

# Theme Elements
prompt='Screenshot'
mesg="DIR: `xdg-user-dir PICTURES`/Screenshots"

if [[ "$theme" == *'type-1'* ]]; then
    list_col='1'
    list_row='5'
    win_width='400px'
elif [[ "$theme" == *'type-3'* ]]; then
    list_col='1'
    list_row='5'
    win_width='120px'
elif [[ "$theme" == *'type-5'* ]]; then
    list_col='1'
    list_row='5'
    win_width='520px'
elif [[ ( "$theme" == *'type-2'* ) || ( "$theme" == *'type-4'* ) ]]; then
    list_col='5'
    list_row='1'
    win_width='670px'
fi

layout=`grep 'USE_ICON' ${theme} | cut -d'=' -f2`
if [[ "$layout" == 'NO' ]]; then
    option_1=" Capture Desktop"
    option_2=" Capture Area"
    option_3=" Capture Window"
    option_4=" Capture in 5s"
    option_5=" Capture in 10s"
else
    option_1=""
    option_2=""
    option_3=""
    option_4=""
    option_5=""
fi

rofi_cmd() {
    rofi -theme-str "window {width: $win_width;}" \
         -theme-str "listview {columns: $list_col; lines: $list_row;}" \
         -theme-str 'textbox-prompt-colon {str: "";}' \
         -dmenu \
         -p "$prompt" \
         -mesg "$mesg" \
         -markup-rows \
         -theme ${theme}
}

run_rofi() {
    echo -e "$option_1\n$option_2\n$option_3\n$option_4\n$option_5" | rofi_cmd
}

# Directory
dir="$(xdg-user-dir PICTURES)/Screenshots"
if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
fi

timestamp="Screenshot_$(date +%Y-%m-%d-%H-%M-%S).png"


# -----------------------------
# HYPRSHOT ONLY IMPLEMENTATION
# -----------------------------

# capture entire active output (tela atual)
shot_now() {
    hyprshot -m active -c -o "$dir" -f "$timestamp"
}

# capture custom area
shot_area() {
    hyprshot -m region -c -o "$dir" -f "$timestamp"
}

# capture active window
shot_window() {
    hyprshot -m window -c -o "$dir" -f "$timestamp"
}

# capture screen after 5 seconds
shot_5s() {
    sleep 5
    hyprshot -m active -c -o "$dir" -f "$timestamp"
}

# capture screen after 10 seconds
shot_10s() {
    sleep 10
    hyprshot -m active -c -o "$dir" -f "$timestamp"
}

run_cmd() {
    case "$1" in
        '--opt1') shot_now ;;
        '--opt2') shot_area ;;
        '--opt3') shot_window ;;
        '--opt4') shot_5s ;;
        '--opt5') shot_10s ;;
    esac
}

chosen="$(run_rofi)"
case ${chosen} in
    $option_1) run_cmd --opt1 ;;
    $option_2) run_cmd --opt2 ;;
    $option_3) run_cmd --opt3 ;;
    $option_4) run_cmd --opt4 ;;
    $option_5) run_cmd --opt5 ;;
esac

