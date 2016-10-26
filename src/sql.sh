#!/bin/bash
if [ -f ./vendor/zlatov/sql/src/config.sh ]
    then
    . "./vendor/zlatov/sql/src/config.sh"
fi

if [ -f ./config.sh ]
    then
    . "./config.sh"
fi

case $1 in
    init)
        if [ ! -f ./config.sh ]
            then
                echo -en $COLOR_GREEN
                yN "Создать конифигурационный файл? [yes/No]"
                echo -en $STYLE_DEFAULT
            else
                echo -en $COLOR_RED
                echo "Найден конфигурационный файл"
                echo -en $STYLE_DEFAULT
                yN "Перезаписать конифигурационный файл? [yes/No]"
        fi
        if [[ $YN -eq 1 ]]
            then
                createConfig
        fi
        mkdir -p dump
        mkdir -p migration
        mkdir -p procedures
        ;;
    dumplist)
        dumpList
        ;;
    dump)
        if [[ $2 == '' ]]
            then
                echo "Создаем дамп БД"
            else
                echo "Восстанавливаем БД из дампа $2"
        fi
        ;;
    push)
        if [[ $2 == '' ]]
            then
                echo "Список локальных дампов:"
                ls -la dump
            else
                echo "Отправляем $2 на сервер $REMOTE_NAME в $REMOTE_PATH"
        fi
        ;;
    pull)
        if [[ $2 == '' ]]
            then
                echo "Список удаленных дампов:"
                ls -la dump
            else
                echo "Отправляем $2 на сервер $REMOTE_NAME в $REMOTE_PATH"
        fi
        ;;
    migrate)
        ;;
    version)
        ;;
    *)
        sqlMan
        ;;
esac

# cd "$SQLPATH"
#. config.sh
