#!/bin/bash

function sqlMan {
    cat ../vendor/zlatov/sql/src/man.txt
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

#echo -en \$COLOR_GREEN
#echo \"Конфигурационный файл \$BASH_ARGV был включен.\"
#echo \"Работа с базой данных: \$DBNAME\"
#echo -en \$STYLE_DEFAULT

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

function checkTableVersionExist {
    TEMP=`mysql --host=$DBHOST --port=3306 --user="$DBUSER" --password="$DBPASS" --execute="
SELECT TABLE_NAME
FROM information_schema.tables
WHERE table_schema = '$DBNAME'
AND table_name = 'sqlversion';
"`
    if echo $TEMP | grep -q 'sqlversion'
        then
            echo 1
        else
            echo 0
    fi
}

function createTableVersion {
    TEMP=`mysql --host=$DBHOST --port=3306 --user="$DBUSER" --password="$DBPASS" --execute="
-- CREATE TABLE newzlatov.sqlversion (
--     sqlversion VARCHAR(11) NOT NULL,
-- UNIQUE INDEX sqlversion_UNIQUE (sqlversion ASC));

-- CREATE TABLE $DBNAME.sqlversion (
--   v1 INT UNSIGNED NOT NULL,
--   v2 INT UNSIGNED NOT NULL,
--   v3 INT UNSIGNED NOT NULL,
-- UNIQUE INDEX uq_sqlversion_123 (v1 ASC, v2 ASC, v3 ASC));

CREATE TABLE $DBNAME.sqlversion (
  \\\`1\\\` INT UNSIGNED NOT NULL,
  \\\`2\\\` INT UNSIGNED NOT NULL,
  \\\`3\\\` INT UNSIGNED NOT NULL,
UNIQUE INDEX uq_sqlversion_123 (\\\`1\\\` ASC, \\\`2\\\` ASC, \\\`3\\\` ASC));

"`
    echo $TEMP
}

function echoVersion {
    if [[ `checkTableVersionExist` -eq 1 ]]; then
        TEMP=$(mysql --host=$DBHOST --port=3306 --user="$DBUSER" --password="$DBPASS" -s --execute="
        SELECT concat(\`1\`, '.', \`2\`, '.', \`3\`) as version FROM newzlatov.sqlversion LIMIT 1;
        ")
        echo -en $COLOR_GREEN
        echo -e "Версия БД:                 $STYLE_DEFAULT$TEMP"
        echo -en $STYLE_DEFAULT
    fi
    echo -en $COLOR_GREEN
    echo -n "Версия последней миграции: "
    echo -en $STYLE_DEFAULT
    # LANG=C ls migration | tail -1
    LANG=C ls migration | grep  '.sql' | sed -r 's/\.sql//' | tail -1
}

function migrateToLastVersion {
    # Текущая версия
    DB_VERSION=$(mysql --host=$DBHOST --port=3306 --user="$DBUSER" --password="$DBPASS" -s --execute="
    SELECT concat(\`1\`, '.', \`2\`, '.', \`3\`) as version FROM newzlatov.sqlversion LIMIT 1;
    ")
    echo -en $COLOR_GREEN
    echo -e "Версия БД: $STYLE_DEFAULT$DB_VERSION"
    echo -en $STYLE_DEFAULT

    # Версии миграций
    # так:

    # VERSIONS=(`LANG=C ls migration | grep  '.sql' | sed -r 's/\.sql//'`)
    # echo "VERSIONS: "
    # for value in "${VERSIONS[@]}"
    # do
    #     echo $value
    # done

    # или так:

    declare -a VERSIONS
    while read line
    do
        VERSIONS=("${VERSIONS[@]}" "$line")
    done < <(LANG=C ls migration | grep  '.sql' | sed -r 's/\.sql//')

    # Перебор и выполнение необходимых миграций
    dbArray=(${DB_VERSION//./ })
    for mVersion in "${VERSIONS[@]}"
    do
        mArray=(${mVersion//./ })
        if [[ ${mArray[0]} -gt ${dbArray[0]} ]]
            then
                migrate $mVersion
                if [ $? -eq 1 ]; then break; fi
            else
                if [[ ${mArray[1]} -gt ${dbArray[1]} ]]
                    then
                        migrate $mVersion
                        if [ $? -eq 1 ]; then break; fi
                    else
                        if [[ ${mArray[2]} -gt ${dbArray[2]} ]]
                            then
                                migrate $mVersion
                                if [ $? -eq 1 ]; then break; fi
                        fi
                fi
        fi
    done
}

function migrate {
    echo -en $COLOR_GREEN
    echo -e "Миграция базы к версии $STYLE_DEFAULT$1:"
    echo -en $STYLE_DEFAULT
    (mysql --database="$DBNAME" --user="$DBUSER" --password="$DBPASS" -s < "./migration/$1.sql") >/dev/null
    # echo $?
    if [ $? -eq 0 ]
        then
            echo -en $COLOR_GREEN
            echo -e "Миграция $STYLE_DEFAULT$1 ${COLOR_GREEN}прошла успешно."
            echo -en $STYLE_DEFAULT
            mArray=(${1//./ })
            mysql --database="$DBNAME" --user="$DBUSER" --password="$DBPASS" -s -e"
            UPDATE \`sqlversion\` SET \`1\`='${mArray[0]}', \`2\`='${mArray[1]}', \`3\`='${mArray[2]}' WHERE \`name\`='version';
            ";
        else
            echo -en $COLOR_RED
            echo -e "Ошибка миграции $STYLE_DEFAULT$1"
            echo -en $STYLE_DEFAULT
            echo 1 1>&2 2>/dev/null
            # echo $?
            if [[ $? -eq 1 ]]; then echo "error"; else echo "done"; fi
            echo "--"
    fi
}

function migrationsList {
    VERSIONS=(`LANG=C ls migration | grep  '.sql' | sed -r 's/\.sql//'`)
    echo -en $COLOR_GREEN
    echo "Версии миграций:"
    echo -en $STYLE_DEFAULT
    for value in "${VERSIONS[@]}"
    do
        echo $value
    done
}

function echoDbName {
    if [ ! -f ./config.sh ]
        then
            echo -en $COLOR_RED
            echo "Конифигурационный файл config.sh не найден."
            echo -en $STYLE_DEFAULT
        else
            echo -en $COLOR_GREEN
            echo "Работа с базой данных: $DBNAME"
            echo -en $STYLE_DEFAULT
    fi
}

function echoDbUser {
    if [ ! -f ./config.sh ]
        then
            echo -en $COLOR_RED
            echo "Конифигурационный файл config.sh не найден."
            echo -en $STYLE_DEFAULT
        else
            echo -en $COLOR_GREEN
            echo "Работа с базой данных от пользователя: $DBUSER"
            echo -en $STYLE_DEFAULT
    fi
}

function echoDbConf {
    if [ ! -f ./config.sh ]
        then
            echo -en $COLOR_RED
            echo "Конифигурационный файл config.sh не найден."
            echo -en $STYLE_DEFAULT
        else
            echo -en $COLOR_GREEN
            echo -e "Работа с базой данных: $STYLE_DEFAULT$DBNAME"
            echo -en $COLOR_GREEN
            echo -e "на:                    $STYLE_DEFAULT$DBHOST"
            echo -en $COLOR_GREEN
            echo -e "От пользователя:       $STYLE_DEFAULT$DBUSER"
            echo -en $STYLE_DEFAULT
    fi
}

