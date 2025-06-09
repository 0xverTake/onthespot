#!/bin/bash

# Fonction pour afficher une barre de progression simple
show_progress() {
    local title="$1"
    local duration=${2:-3}
    local width=30
    
    echo -ne "\n${CYAN}[$title]${NC}\n"
    for ((i = 0; i <= width; i++)); do
        echo -ne "\r["
        for ((j = 0; j < i; j++)); do
            echo -ne "${GREEN}#${NC}"
        done
        for ((j = i; j < width; j++)); do
            echo -ne "-"
        done
        echo -ne "] $((i * 100 / width))%"
        sleep $(bc -l <<< "$duration/$width")
    done
    echo -e "\n"
}

# Fonction pour afficher un spinner simple
show_spinner() {
    local message="$1"
    local duration=${2:-2}
    local spin='-\|/'
    local end=$((SECONDS + duration))
    
    echo -ne "\n${CYAN}[$message]${NC} "
    while [ $SECONDS -lt $end ]; do
        for i in $(seq 0 3); do
            echo -ne "\r${GREEN}${spin:$i:1}${NC}"
            sleep 0.1
        done
    done
    echo -e "\n"
}
