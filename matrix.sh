#!/bin/bash

matrix_effect() {
    local lines=$(tput lines)
    local cols=$(tput cols)
    local chars=("ｱ" "ｲ" "ｳ" "ｴ" "ｵ" "カ" "キ" "ク" "ケ" "コ" "サ" "シ" "ス" "セ" "ソ" "タ" "チ" "ツ" "テ" "ト" "ナ" "ニ" "ヌ" "ネ" "ノ" "ハ" "ヒ" "フ" "ヘ" "ホ" "マ" "ミ" "ム" "メ" "モ" "ヤ" "ユ" "ヨ" "ラ" "リ" "ル" "レ" "ロ" "ワ" "ヲ" "ン" "ー" "∟" "¦" "╌" "╍" "╎" "╏" "═" "║" "╒" "╓" "╔" "╕" "╖" "╗" "╘" "╙" "╚" "╛" "╜" "╝" "╞" "╟" "╠" "╡" "╢" "╣" "╤" "╥" "╦" "╧" "╨" "╩" "╪" "╫" "╬" "○" "╭" "╮" "╯" "╰")

    # Clear screen and hide cursor
    clear
    echo -e "\e[?25l"

    # Matrix effect
    for ((i=0; i<30; i++)); do
        local x=$((RANDOM % cols))
        local delay=$((RANDOM % 5))
        for ((y=0; y<lines; y++)); do
            echo -ne "\e[${y};${x}H\e[32m${chars[$((RANDOM % ${#chars[@]}))]}"
            sleep 0.01
        done &
    done
    sleep 2
    clear
    echo -e "\e[?25h" # Show cursor
}

cyber_loading() {
    local message="$1"
    local duration=${2:-3}
    local chars=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local colors=("\e[36m" "\e[35m" "\e[34m" "\e[32m")
    
    echo -ne "\e[?25l" # Hide cursor
    
    local end=$((SECONDS + duration))
    while [ $SECONDS -lt $end ]; do
        for i in "${!chars[@]}"; do
            color=${colors[$((i % ${#colors[@]}))]}
            echo -ne "\r${color}${chars[$i]} $message\e[0m"
            sleep 0.1
        done
    done
    echo -ne "\r\e[K"
    echo -e "\e[?25h" # Show cursor
}

progress_bar() {
    local title="$1"
    local duration=${2:-3}
    local width=50
    local progress=0
    
    echo -ne "\e[36m╭$title\e[0m\n"
    echo -ne "├"
    for ((i=0; i<width; i++)); do echo -n "─"; done
    echo -ne "┤\n"
    echo -ne "╰"
    
    local increment=$((100 / (duration * 10)))
    while [ $progress -lt 100 ]; do
        progress=$((progress + increment))
        [ $progress -gt 100 ] && progress=100
        
        local filled=$(((width * progress) / 100))
        local empty=$((width - filled))
        
        echo -ne "\r╰"
        echo -ne "\e[32m"
        for ((i=0; i<filled; i++)); do echo -n "█"; done
        echo -ne "\e[37m"
        for ((i=0; i<empty; i++)); do echo -n "─"; done
        echo -ne "\e[36m[$progress%]\e[0m"
        
        sleep 0.1
    done
    echo
}
