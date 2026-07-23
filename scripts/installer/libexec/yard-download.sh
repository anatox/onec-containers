#!/usr/bin/env bash
set -euo pipefail && [ "${DEBUG_TRACE:-0}" = "1" ] && set -x

# Аргументы скрипта
distr_root="/var/cache/yard"
installer_type=""
version=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --path)
            distr_root="$2"
            shift 2
            ;;
        *)
            if [ -z "$installer_type" ]; then
                installer_type="$1"
            elif [ -z "$version" ]; then
                version="$1"
            fi
            shift
            ;;
    esac
done

if [ -z "$distr_root" ]; then
    echo "ОШИБКА: Не указан --path (корневой каталог для скачивания)"
    exit 1
fi
if [ -z "${ONEC_USERNAME:-}" ] || [ -z "${ONEC_PASSWORD:-}" ]; then
    echo "ОШИБКА: Не заданы переменные окружения ONEC_USERNAME и ONEC_PASSWORD"
    exit 1
fi

if [ -z "$installer_type" ]; then
    echo "ОШИБКА: Не указан тип установки (первый позиционный аргумент)"
    exit 1
fi
if [ -z "$version" ]; then
    echo "ОШИБКА: Не указана версия (второй позиционный аргумент)"
    exit 1
fi

if [ "$installer_type" = "edt" ]; then
    FOLDER_NAME="DevelopmentTools10"
    DOWNLOADS_PATH=${distr_root}/${FOLDER_NAME}/${version}
else
    ONEC_MAJOR_VER=$(echo "$version" | cut -d'.' -f1,2 | tr -d '.')

    FOLDER_NAME="Platform${ONEC_MAJOR_VER}"
    DOWNLOADS_PATH=${distr_root}/${FOLDER_NAME}/${version}
fi

# Преобразование версии для различных целей
ONEC_VERSION_DOTS=$version
ONEC_VERSION_UNDERSCORES=$(echo $version | sed 's/\./\_/g')
ESCAPED_VERSION=$(echo $version | sed 's/\./\\./g')

# Поищем дистрибутив в папке distr и если он есть скопируем его куда надо и распакуем
copy_distr_to_downloads_path() {
    found=1
    found_run_file=1
    case "$installer_type" in
        edt)
            local edt_pattern="1c_edt_distr_offline_${version}_*_linux_x86_64.tar.gz"
            # Ищем файлы, соответствующие шаблону
            local matching_files=($(ls /distr/$edt_pattern 2> /dev/null))
            if [ ${#matching_files[@]} -gt 0 ]; then
                local edt_filename=${matching_files[0]}
                echo "Найден локальный дистрибутив: $edt_filename"
                cp $edt_filename $DOWNLOADS_PATH/
                found=0
            else
                echo "Локального дистрибутива edt не найдено в папке distr"
            fi
            ;;
        server|server_crs)
            local file_name_srv="deb64_$ONEC_VERSION_UNDERSCORES.tar.gz"
            local file_name_platform="server64_$ONEC_VERSION_UNDERSCORES.tar.gz"
            local file_name_run="setup-full-$ONEC_VERSION_DOTS-x86_64.run"

            if [ -f "/distr/$file_name_srv" ]; then
                echo "Найден локальный дистрибутив: $file_name_srv"
                cp /distr/$file_name_srv $DOWNLOADS_PATH/
                found=0
            elif [ -f "/distr/$file_name_platform" ]; then
                echo "Найден локальный дистрибутив: $file_name_platform"
                cp /distr/$file_name_platform $DOWNLOADS_PATH/
                found=0
            elif [ -f "/distr/$file_name_run" ]; then
                echo "Найден локальный дистрибутив: $file_name_run"
                cp /distr/$file_name_run $DOWNLOADS_PATH/
                found=0
                found_run_file=0
            fi
            ;;
        server32)
            local file_name_srv="deb_$ONEC_VERSION_UNDERSCORES.tar.gz"
            local file_name_platform="server32_$ONEC_VERSION_UNDERSCORES.tar.gz"

            if [ -f "/distr/$file_name_srv" ]; then
                echo "Найден локальный дистрибутив: $file_name_srv"
                cp /distr/$file_name_srv $DOWNLOADS_PATH/
                found=0
            elif [ -f "/distr/$file_name_platform" ]; then
                echo "Найден локальный дистрибутив: $file_name_platform"
                cp /distr/$file_name_platform $DOWNLOADS_PATH/
                found=0
            fi
            ;;
        client)
            local file_name_deb="client_$ONEC_VERSION_UNDERSCORES.deb64.tar.gz"
            local file_name_platform="server64_$ONEC_VERSION_UNDERSCORES.tar.gz"
            local file_name_run="setup-full-$ONEC_VERSION_DOTS-x86_64.run"

            if [ -f "/distr/$file_name_deb" ]; then
                echo "Найден локальный дистрибутив: $file_name_deb"
                cp /distr/$file_name_deb $DOWNLOADS_PATH/
                found=0
            elif [ -f "/distr/$file_name_platform" ]; then
                echo "Найден локальный дистрибутив: $file_name_platform"
                cp /distr/$file_name_platform $DOWNLOADS_PATH/
                found=0
            elif [ -f "/distr/$file_name_run" ]; then
                echo "Найден локальный дистрибутив: $file_name_run"
                cp /distr/$file_name_run $DOWNLOADS_PATH/
                found=0
                found_run_file=0
            fi
            ;;
    esac

    return $found
}


check_local_distr() {

    copy_distr_to_downloads_path
    found=$?

    if [ $found -ne 0 ]; then
        return $found
    fi

    check_file
    local_distr_found=$?
    return $local_distr_found
}

# Функция для скачивания дистрибутива
download_distr() {
    local distr_filter=$1

    echo "Попытка скачать дистрибутив с фильтром: $distr_filter"
    local attempt=1
    local max_attempts=3
    while [ $attempt -le $max_attempts ]; do
        echo "Попытка $attempt из $max_attempts"
        local yard_err
        local logos_env
        logos_env=""
        [ "${DEBUG_TRACE:-0}" = "1" ] && logos_env="LOGOS_LEVEL=DEBUG"
        yard_err=$(env $logos_env yard releases -u $ONEC_USERNAME -p $ONEC_PASSWORD get \
            --app-filter "$APP_FILTER" \
            --version-filter $ESCAPED_VERSION \
            --path "$distr_root" \
            --distr-filter "$distr_filter" \
            --download-limit 1 2>&1 | tee /dev/stderr) && return 0
        if ! echo "$yard_err" | grep -qiE '(System\.Net\.WebException|System\.IO\.IOException)'; then
            return 1
        fi
        if [ $attempt -lt $max_attempts ]; then
            local wait_time=$((2 ** (attempt - 1) * 30))
            echo "Таймаут скачивания. Повторная попытка через ${wait_time} секунд..."
            sleep $wait_time
        fi
        attempt=$((attempt + 1))
    done
    echo "::error::Не удалось скачать дистрибутив ${installer_type} ${version} (фильтр: ${distr_filter})"
    return 1
}

# Функция проверки наличия нужных файлов после распаковки
check_file() {
    found=1
    echo "Содержимое каталога $DOWNLOADS_PATH:"
    ls -l $DOWNLOADS_PATH
    # Проверяем, появились ли файлы в каталоге
    if [ "$installer_type" = "edt" ]; then
        # Для edt проверяем наличие специфичного файла
        if ls $DOWNLOADS_PATH/1ce-installer-cli 1> /dev/null 2>&1; then
            echo "Дистрибутив найден и скачан: $filter"
            found=0
        else
            echo "Не найден файл 1ce-installer-cli"
        fi
    elif ls $DOWNLOADS_PATH/*.deb 1> /dev/null 2>&1 || ls $DOWNLOADS_PATH/*.run 1> /dev/null 2>&1; then
        echo "Дистрибутив найден и скачан: $filter"
        found=0
    else
        echo "Не найден дистрибутив по шаблону: $filter"
    fi
    return $found
}

# Попытка скачивания дистрибутива для каждого фильтра
try_download() {

    # Определим фильтры для скачивания. Если шаблонов >1 они должны разделяться "|" Скачивается дистрибутив по первому найденному шаблону.
    APP_FILTER="Технологическая платформа *8\.[3,5]"
    case "$installer_type" in
        edt)
            echo "Скачиваем дистрибутив EDT"
            APP_FILTER="1C:Enterprise Development Tools"
            DISTR_FILTERS="Дистрибутив для оффлайн установки 1C:EDT для ОС Linux 64 бит|Дистрибутив 1C:EDT для ОС Linux для установки без интернета"
            ;;
        server|server_crs)
            echo "Скачиваем дистрибутив для установки 64-битного сервера"
            DISTR_FILTERS="Технологическая платформа 1С:Предприятия \(64\-bit\) для Linux$|Сервер 1С:Предприятия \(64\-bit\) для DEB-based Linux-систем$"
            ;;
        server32)
            echo "Скачиваем дистрибутив для установки 32-битного сервера"
            DISTR_FILTERS="Технологическая платформа 1С:Предприятия для Linux$|Сервер 1С:Предприятия для DEB-based Linux-систем$"
            ;;
        client)
            echo "Скачиваем дистрибутив для установки 64-битного клиента 1с"
            DISTR_FILTERS="Технологическая платформа 1С:Предприятия \(64\-bit\) для Linux$|Клиент 1С:Предприятия \(64\-bit\) для DEB-based Linux-систем$"
            ;;
        client32)
            echo "Скачиваем дистрибутив для установки 32-битного клиента 1с"
            DISTR_FILTERS="Технологическая платформа 1С:Предприятия для Linux$|Клиент 1С:Предприятия для DEB-based Linux-систем$"
            ;;
        thin-client)
            echo "Скачиваем дистрибутив для установки 32-битного тонкого клиента 1с"
            DISTR_FILTERS="Тонкий клиент 1С:Предприятия \(64\-bit\) для DEB-based Linux-систем$|Тонкий клиент 1С:Предприятия \(64\-bit\) для Linux$"
            ;;
        thin-client32)
            echo "Скачиваем дистрибутив для установки 32-битного тонкого клиента 1с"
            DISTR_FILTERS="Тонкий клиент 1С:Предприятия для DEB-based Linux-систем$|Тонкий клиент 1С:Предприятия для Linux$"
            ;;
    esac

    echo $DISTR_FILTERS
    local download_success=1
    IFS='|'
    read -ra FILTERS <<< "$DISTR_FILTERS"
    for filter in "${FILTERS[@]}"; do
        download_distr "$filter"
        if check_file; then
            download_success=0
            break
        fi
    done
    return $download_success
}

# Удаление ненужных файлов
mkdir -p $DOWNLOADS_PATH
rm -f $DOWNLOADS_PATH/.gitkeep

# Проверяем, есть ли дистрибутивы локально
if ! check_local_distr; then
    echo "Скачаных дистрибутивов не найдено. Попытаемся скачать через yard."
    if [ "$version" = "8.3.24.1342" ] || [ "$version" = "8.3.24.1368" ]; then
        echo "::error::Скачивание версии ${version} не поддерживается. Скачайте и распакуйте релиз самостоятельно, и поместите его в папку distr"
        exit 1
    else
        echo "Версия 1с: $version"
    fi
    try_download
    download_attempted=$?
    if [ $download_attempted -ne 0 ]; then
        echo "Ошибка: не удалось найти дистрибутив ни локально, ни удаленно."
        exit 1
    fi
fi
