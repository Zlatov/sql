#!/bin/bash

function sqlMan {
    echo "./sql init"
    echo "  настройка доступа к бд и адреса удаленного сервера"
    echo ""
    echo "./sql dumplist"
    echo "  список дампов"
    echo ""
    echo "./sql dump"
    echo "  создать дамп"
    echo ""
    echo "./sql dump filename"
    echo "  восстановить из дампа filename"
    echo ""
    echo "./sql push"
    echo "  список локальных дампов"
    echo ""
    echo "./sql push filename"
    echo "  отправка локального дампа на сервер"
    echo ""
    echo "./sql pull"
    echo "  список удаленных дампов"
    echo ""
    echo "./sql pull filename"
    echo "  получение удаленного дампа с сервера"
    echo ""
    echo "./sql migrate"
    echo "  выполнить все миграции которые больше текущей версии БД"
    echo ""
    echo "./sql version"
    echo "  вывести текущую версию БД и последнюю версию миграции"
    echo ""
}

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

function createConfig {
    echo -n "Хост (localhost): "
    read DBHOST
    if [[ $DBHOST == '' ]]
        then
        DBHOST="localhost"
    fi

    echo -n "Имя БД: "
    read DBNAME

    echo -n "Имя пользователя БД (root): "
    read DBUSER
    if [[ $DBUSER == '' ]]
        then
        DBUSER="root"
    fi

    echo -n "Пароль: "
    read -s DBPASS
    echo

    echo -n "Адрес удаленного сервера (user@server) или алиас (myserver): "
    read REMOTE_NAME

    echo -n "Абсолютный путь к корню проекта (/home/user/projectname): "
    read REMOTE_PATH

    echo "#!/bin/bash

DBHOST=\"$DBHOST\"
DBNAME=\"$DBNAME\"
DBUSER=\"$DBUSER\"
DBPASS=\"$DBPASS\"

REMOTE_NAME=\"$REMOTE_NAME\"
REMOTE_PATH=\"$REMOTE_PATH\"

echo -en \$COLOR_GREEN
echo \"Конфигурационный файл \$BASH_ARGV был включен.\"
echo \"Работа с базой данных: \$DBNAME\"
echo -en \$STYLE_DEFAULT

" > config.sh

    if [ ! -f ./config.sh ]
        then
            echo -en $COLOR_RED
            echo "Конфигурационный файл НЕ создан!"
            echo -en $STYLE_DEFAULT
        else
            echo -en $COLOR_GREEN
            echo "Конфигурационный файл успешно создан."
            echo -en $STYLE_DEFAULT
    fi

}

function createDefaultFolders {
    if [ ! -d ./dump ]; then
        # mkdir -p dump
        mkdir dump
        if [ -d ./dump ]; then
            echo -en $COLOR_GREEN
            echo "Создана папка размещения дампов (dump/)"
            echo -en $STYLE_DEFAULT
        fi
    fi
    if [ ! -d ./migration ]; then
        mkdir migration
        if [ -d ./migration ]; then
            echo -en $COLOR_GREEN
            echo "Создана папка хранения миграций (migration/)"
            echo -en $STYLE_DEFAULT
        fi
    fi
    if [ ! -d ./procedures ]; then
        mkdir procedures
        if [ -d ./procedures ]; then
            echo -en $COLOR_GREEN
            echo "Создана папка хранения процедур (procedures/)"
            echo -en $STYLE_DEFAULT
        fi
    fi
}

function checkGitignore {
    if [ ! -f ./.gitignore ]; then
        echo "
dump/*.sql
dump/*.tar.gz
" > .gitignore
        if [ -f ./.gitignore ]; then
            echo -en $COLOR_GREEN
            echo "Файл .gitignore успешно создан."
            echo -en $STYLE_DEFAULT
        fi
    else
        echo
    fi
}

function dumpList {
    echo "Список локальных дампов"
    ls -la dump
}