#!/bin/bash

# Список функций:
# data      — входная функция
# echoDatas — вывод списка данных в ./data
# getDatas  — получить массив из списка файлов данных
# toData    — применить данные к БД

function data {
    if [[ $2 == '' ]]
        then
        echoDatas
        else
        toData "$2"
    fi
}

function echoDatas {
    DATAS=($(getDatas))
    if [ ${#DATAS[*]} -eq 0 ]
        then
            echo -en $COLOR_YELLOW
            echo "Нет файлов данных."
            echo -en $STYLE_DEFAULT
        else
            echo -en $COLOR_GREEN
            echo "Список файлов данных:"
            echo -en $STYLE_DEFAULT
            for value in "${DATAS[@]}"
            do
                echo $value
            done
    fi
}

function getDatas {
    `LANG=C ls data | grep  '.sql' | sed -r 's/\.sql//'`
}

function toData {
    (mysql --host=$DBHOST --port=3306 --user="$DBUSER" --database="$DBNAME" -s < "./data/$1.sql") >/dev/null
    TODATA_STATUS=$?
    if [ $TODATA_STATUS -eq 0 ]
        then
            echo -en $COLOR_GREEN
            echo "Успешно."
            echo -en $STYLE_DEFAULT
        else
            echo -en $COLOR_RED
            echo -e "Ошибка добавления данных."
            echo -en $STYLE_DEFAULT
    fi
}
