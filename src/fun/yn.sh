#!/bin/bash

if [[ $SQL_DEBUG -eq 1 ]]
    then
        echo -en $COLOR_GREEN
        echo -e "Включён файл $STYLE_DEFAULT$BASH_ARGV."
        echo -en $STYLE_DEFAULT
fi

function yN {
    read -r -p "${1:-Are you sure? [yes/No]} " response
    case $response in
        [yY][eE][sS]|[yY]|[дД][аА]|[дД]) 
            YN=1
            ;;
        *)
            YN=0
            ;;
    esac
}

function Yn {
    read -r -p "${1:-Are you sure? [Yes/no]} " response
    case $response in
        [nN][oO]|[nN]|[нН][еЕ][тТ]|[нН]) 
            YN=0
            ;;
        *)
            YN=1
            ;;
    esac
}
