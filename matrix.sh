#!/bin/bash

start_matrix_background() {
    # Sauvegarde le contenu de l'écran
    tput smcup
    # Cache le curseur
    echo -e "\e[?25l"
    
    # Démarrer l'effet matrix en arrière-plan
    while true; do
        local lines=$(tput lines)
        local cols=$(tput cols)
        local x=$((RANDOM % cols))
        local chars=("ｱ" "ｲ" "ｳ" "ｴ" "ｵ" "カ" "キ" "ク" "ケ" "コ" "サ" "シ" "ス" "セ" "ソ" "タ" "チ" "ツ" "テ" "ト" "ナ" "ニ" "ヌ" "ネ" "ノ" "ハ" "ヒ" "フ" "ヘ" "ホ" "マ" "ミ" "ム" "メ" "モ" "ヤ" "ユ" "ヨ" "ラ" "リ" "ル" "レ" "ロ" "ワ" "ヲ" "ン" "ー" "∟" "¦" "╌" "╍" "╎" "╏")
        
        for ((y=0; y<lines; y++)); do
            echo -ne "\e[${y};${x}H\e[32m\e[1;40m${chars[$((RANDOM % ${#chars[@]}))]}"
            sleep 0.1
        done
    done &
    MATRIX_PID=$!
}

stop_matrix_background() {
    # Tue le processus matrix
    if [ ! -z "$MATRIX_PID" ]; then
        kill $MATRIX_PID 2>/dev/null
    fi
    # Restaure l'écran
    tput rmcup
    # Montre le curseur
    echo -e "\e[?25h"
}

show_ascii_art() {
    local text="$1"
    local offset=8  # Décalage pour centrer l'ASCII art
    
    # Obtient les dimensions de l'écran
    local lines=$(tput lines)
    local cols=$(tput cols)
    
    # Position pour centrer verticalement
    local start_line=$((lines/4))
    
    # Efface la zone où l'ASCII art sera affiché
    for ((i=0; i<10; i++)); do
        echo -ne "\e[$((start_line+i));0H\e[K"
    done
    
    # Affiche l'ASCII art avec un fond noir
    echo -ne "\e[${start_line}H"
    echo -e "\e[38;5;82m\e[40m$text\e[0m"
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
