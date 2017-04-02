#!/bin/bash

function sqlMan {
    cat ../vendor/zlatov/sql/src/man.txt
}

function migrateToLastVersion {
    # Текущая версия
    DB_VERSION=$(getDbVersion)
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

    WE_HAVE_SOME_MIGRATION=0
    MIGRATION_STATUS=0

    if [[ ${#VERSIONS[*]} -gt 0 ]]
        then
            # Перебор и выполнение необходимых миграций
            dbArray=(${DB_VERSION//./ })
            for mVersion in "${VERSIONS[@]}"
            do
                mArray=(${mVersion//./ })
                if [[ ${mArray[0]} -gt ${dbArray[0]} ]]
                    then
                        migrate $mVersion
                        WE_HAVE_SOME_MIGRATION=1
                        if [ $MIGRATION_STATUS -eq 1 ]; then break; fi
                    else
                        if [[ ${mArray[1]} -gt ${dbArray[1]} ]]
                            then
                                migrate $mVersion
                                WE_HAVE_SOME_MIGRATION=1
                                if [ $MIGRATION_STATUS -eq 1 ]; then break; fi
                            else
                                if [[ ${mArray[2]} -gt ${dbArray[2]} ]]
                                    then
                                        migrate $mVersion
                                        WE_HAVE_SOME_MIGRATION=1
                                        if [ $MIGRATION_STATUS -eq 1 ]; then break; fi
                                fi
                        fi
                fi
            done
    fi

    DB_VERSION=$(getDbVersion)
    dbVersionArray=(${DB_VERSION//./ })

    if [[ $MIGRATION_STATUS -eq 0 ]] && [[ ${dbVersionArray[0]} -gt 0 ]] && [[ $WE_HAVE_SOME_MIGRATION -eq 1 ]]
        then
            declare -a TRIGGERS
            while read line
            do
                TRIGGERS=("${TRIGGERS[@]}" "$line")
            done < <(LANG=C ls triggers | grep  '.sql')
            if [[ ${#TRIGGERS[*]} -gt 0 ]]
                then
                    for trigger in "${TRIGGERS[@]}"
                    do
                        echo -en $COLOR_GREEN
                        echo -e "Применение триггеров в $STYLE_DEFAULT$trigger:"
                        echo -en $STYLE_DEFAULT
                        (mysql --host=$DBHOST --port=3306 --user="$DBUSER" --database="$DBNAME" -s < "./triggers/$trigger") >/dev/null
                        TRIGGER_STATUS=$?
                        if [ $TRIGGER_STATUS -eq 0 ]
                            then
                                echo -en $COLOR_GREEN
                                echo "Успешно."
                                echo -en $STYLE_DEFAULT
                            else
                                echo -en $COLOR_RED
                                echo -e "Ошибка применения триггеров."
                                echo -en $STYLE_DEFAULT
                                break
                        fi
                    done
                else
                    TRIGGER_STATUS=0
            fi
    fi

    if [[ $MIGRATION_STATUS -eq 0 ]] && [[ $TRIGGER_STATUS -eq 0 ]] && [ ${dbVersionArray[0]} -gt 0 ]
        then
            declare -a PROCEDURES
            while read line
            do
                PROCEDURES=("${PROCEDURES[@]}" "$line")
            done < <(LANG=C ls procedures | grep  '.sql')
            if [[ ${#PROCEDURES[*]} -gt 0 ]]; then
                for procedure in "${PROCEDURES[@]}"
                do
                    echo -en $COLOR_GREEN
                    echo -e "Применение процедур в $STYLE_DEFAULT$procedure:"
                    echo -en $STYLE_DEFAULT
                    (mysql --host=$DBHOST --port=3306 --user="$DBUSER" --database="$DBNAME" -s < "./procedures/$procedure") >/dev/null
                    PROCEDURE_STATUS=$?
                    if [ $PROCEDURE_STATUS -eq 0 ]
                        then
                            echo -en $COLOR_GREEN
                            echo "Успешно."
                            echo -en $STYLE_DEFAULT
                        else
                            echo -en $COLOR_RED
                            echo -e "Ошибка применения процедур."
                            echo -en $STYLE_DEFAULT
                            break
                    fi
                done
            fi
    fi

}

function migrate {
    echo -en $COLOR_GREEN
    echo -e "Миграция базы к версии $STYLE_DEFAULT$1:"
    echo -en $STYLE_DEFAULT
    (mysql --host=$DBHOST --port=3306 --user="$DBUSER" --database="$DBNAME" -s < "./migration/$1.sql") >/dev/null
    MIGRATION_STATUS=$?
    if [ $MIGRATION_STATUS -eq 0 ]
        then
            echo -en $COLOR_GREEN
            echo "Успешно."
            echo -en $STYLE_DEFAULT
            mArray=(${1//./ })
            mysql --database="$DBNAME" --user="$DBUSER" -s -e"
                UPDATE \`sqlversion\` SET \`value\`='$1' WHERE \`name\`='version';
            ";
        else
            echo -en $COLOR_RED
            echo -e "Ошибка миграции $STYLE_DEFAULT$1"
            echo -en $STYLE_DEFAULT
    fi
}

function proceduresList {
    if [ -d ./procedures ]
        then
            declare -a PROCEDURES
            while read line
            do
                PROCEDURES=("${PROCEDURES[@]}" "$line")
            done < <(LANG=C ls procedures | grep  '.sql')
            if [[ ${#PROCEDURES[@]} -gt 0 ]]
                then
                    echo -en $COLOR_GREEN
                    echo "Список процедур:"
                    echo -en $STYLE_DEFAULT
                    for procedure in "${PROCEDURES[@]}"
                    do
                        echo $procedure
                    done
                    yN "Применить процедуры [yes/NO]"
                    if [[ $YN -eq 1 ]]
                        then
                            for procedure in "${PROCEDURES[@]}"
                            do
                                echo -en $COLOR_GREEN
                                echo -e "Применение процедур в $STYLE_DEFAULT$procedure:"
                                echo -en $STYLE_DEFAULT
                                (mysql --host=$DBHOST --port=3306 --user="$DBUSER" --database="$DBNAME" -s < "./procedures/$procedure") >/dev/null
                                PROCEDURE_STATUS=$?
                                if [ $PROCEDURE_STATUS -eq 0 ]
                                    then
                                        echo -en $COLOR_GREEN
                                        echo "Успешно."
                                        echo -en $STYLE_DEFAULT
                                    else
                                        echo -en $COLOR_RED
                                        echo -e "Ошибка применения процедур."
                                        echo -en $STYLE_DEFAULT
                                        break
                                fi
                            done
                    fi
            fi
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
