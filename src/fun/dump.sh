#!/bin/bash

# Список функций:
# dump — входная функция
# createDump — создание дампа
# dumpList — вывод списка дампов
# push — список локальных дампов / отправка на сервер
# pull — список удаленных дампов / получение с сервера

function dump {
    if [[ $1 == '' ]]
        then
            createDump
        else
            if [ ! -f ./dump/$1 ]
            then
                echo -en $COLOR_RED
                echo "Не найден дамп $1."
                echo -en $STYLE_DEFAULT
            else
                echo "Восстанавливаем БД $DBNAME из дампа $1"
                tar -xzOf "./dump/$1" | mysql -u"$DBUSER" "$DBNAME"
                if [[ $? -eq 1 ]]
                    then
                        echo -en $COLOR_RED
                        echo -e "Ошибка при восстановлении."
                        echo -en $STYLE_DEFAULT
                    else
                        echo -en $COLOR_GREEN
                        echo -e "Успешно восстановлена бд $DBNAME."
                        echo -en $STYLE_DEFAULT
                fi
            fi
    fi
}

function createDump {
    DBDATE=`date +%Y-%m-%d-%H-%M-%S`
    echo -en $COLOR_GREEN
    echo "Создаем бэкап $DBNAME-$DBDATE.tar.gz"
    echo -en $STYLE_DEFAULT
    `mysqldump --opt -u$DBUSER -h$DBHOST $DBNAME | sed -r 's/!50017 DEFINER/ 50017 DEFINER/' > ./dump/$DBNAME-$DBDATE.sql` >/dev/null
    if [ $? -eq 0 ]
        then
            echo -en $COLOR_GREEN
            echo "Создан бэкап ./dump/$DBNAME-$DBDATE.sql"
            echo -en $STYLE_DEFAULT
            tar -czf ./dump/$DBNAME-$DBDATE.tar.gz -C"./dump/" $DBNAME-$DBDATE.sql
            if [ $? -eq 0 ]
                then
                    echo -en $COLOR_GREEN
                    echo "Создан дамп ./dump/$DBNAME-$DBDATE.tar.gz"
                    echo -en $STYLE_DEFAULT
                    rm ./dump/$DBNAME-$DBDATE.sql
                    if [ $? -eq 0 ]
                        then
                            echo -en $COLOR_GREEN
                            echo "Удален бэкап ./dump/$DBNAME-$DBDATE.sql"
                            echo -en $STYLE_DEFAULT
                    fi
                else
                    echo -en $COLOR_RED
                    echo "Ошибка создания дампа ./dump/$DBNAME-$DBDATE.tar.gz"
                    echo -en $STYLE_DEFAULT
            fi
        else
            echo -en $COLOR_RED
            echo "Ошибка создания бэкапа ./dump/$DBNAME-$DBDATE.sql"
            echo -en $STYLE_DEFAULT
    fi
}

function dumpList {
    DUMP_LIST=(`ls dump`)
    if [ ${#DUMP_LIST[*]} -eq 0 ]
        then
            echo "Нет локальных дампов"
        else
            echo "Список локальных дампов:"
            ls dump
    fi
}

function push {
    if [[ $1 == '' ]]
        then
            dumpList
        else
            if [ ! -f ./config.sh ]
                then
                    echo -en $COLOR_RED
                    echo "Не найден конфигурационный файл."
                    echo -en $STYLE_DEFAULT
                else
                    if [ ! -f ./dump/$1 ]
                        then
                            echo -en $COLOR_RED
                            echo "Не найден дамп $1."
                            echo -en $STYLE_DEFAULT
                        else
                            echo "Отправляем $1 на сервер $REMOTE_NAME в ${REMOTE_PATH}/sql/dump/$1"
                            scp "./dump/$1" $REMOTE_NAME:$REMOTE_PATH/sql/dump/
                            if [[ $? -eq 1 ]]
                                then
                                    echo -en $COLOR_RED
                                    echo -e "Ошибка отправки."
                                    echo -en $STYLE_DEFAULT
                                else
                                    echo -en $COLOR_GREEN
                                    echo -e "Успешно отправлен дамп на сервер."
                                    echo -en $STYLE_DEFAULT
                            fi
                    fi
            fi
    fi
}

function pull {
    if [[ $1 == '' ]]
        then
            echo "Список удаленных дампов:"
            ssh $REMOTE_NAME "ls -la $REMOTE_PATH/sql/dump"
        else
            echo "Получаем $1 с сервера $REMOTE_NAME из ${REMOTE_PATH}/sql/dump"
            scp $REMOTE_NAME:$REMOTE_PATH/sql/dump/$1 ./dump/$1
            if [[ $? -eq 1 ]]
                then
                    echo -en $COLOR_RED
                    echo -e "Ошибка получения."
                    echo -en $STYLE_DEFAULT
                else
                    echo -en $COLOR_GREEN
                    echo -e "Успешно получен дамп с сервера."
                    echo -en $STYLE_DEFAULT
            fi
    fi
}