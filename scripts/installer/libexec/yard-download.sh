#!/usr/bin/env bash
set -euo pipefail
export YARD_RELEASES_PWD="$ONEC_PASSWORD"
export YARD_RELEASES_USER="$ONEC_USERNAME"
[ "${DEBUG_TRACE:-0}" -ne 0 ] && set -x

: "${DOWNLOADS_ROOT:?}"
mkdir -p "$DOWNLOADS_ROOT"

# Аргументы скрипта
if [ $# -lt 2 ]; then
    echo "ОШИБКА: не указаны обязательные аргументы: <тип_компонента> <версия>" >&2
    exit 1
fi

installer_type="$1"
ONEC_VERSION="$2"

if [ "$installer_type" = "edt" ]; then
    FOLDER_NAME="DevelopmentTools10"
    DOWNLOADS_PATH="${DOWNLOADS_ROOT}/${FOLDER_NAME}/${ONEC_VERSION}"
else
    ONEC_MAJOR_VER=$(echo "$ONEC_VERSION" | cut -d'.' -f1,2 | tr -d '.')

    FOLDER_NAME="Platform${ONEC_MAJOR_VER}"
    DOWNLOADS_PATH="${DOWNLOADS_ROOT}/${FOLDER_NAME}/${ONEC_VERSION}"
fi

# Преобразование версии для различных целей
ONEC_VERSION_DOTS=$ONEC_VERSION
ONEC_VERSION_UNDERSCORES="${ONEC_VERSION//./_}"
ESCAPED_VERSION="${ONEC_VERSION//./\\.}"

# Поищем дистрибутив в папке distr и если он есть скопируем его куда надо и распакуем
copy_distr_to_downloads_path() {
    found=1
    found_run_file=1
    case "$installer_type" in
        edt)
            local edt_pattern="1c_edt_distr_offline_${ONEC_VERSION}_*_linux_x86_64.tar.gz"
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

    if [ $found -eq 0 ] && [ $found_run_file -eq 1 ] ; then
        # Распаковка скачанных файлов (если такие есть)
        for file in $DOWNLOADS_PATH/*.tar.gz; do
            [ "${DEBUG_TRACE:-0}" -ne 0 ] && DEBUG_ARGS=(-v) || DEBUG_ARGS=()
            tar -xzf "${DEBUG_ARGS[@]}" "$file" -C "$DOWNLOADS_PATH"
            rm -f "${DEBUG_ARGS[@]}" "$file"
        done
    fi

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

try_yard() {
    local logos_env=""
    [ "${DEBUG_TRACE:-0}" -ne 0 ] && logos_env="LOGOS_LEVEL=DEBUG"
    local max_attempts=3
    for ((attempt = 1; attempt <= max_attempts; attempt++)); do
        echo "Попытка $attempt из $max_attempts"
        local yard_err
        if yard_err=$(env $logos_env yard "$@" 2>&1 | tee /dev/stderr); then
            return 0
        fi
        if ! grep -qiE '(System\.Net\.WebException|System\.IO\.IOException)' <<< "$yard_err"; then
            echo "ОШИБКА: Не удалось скачать дистрибутив ${installer_type} ${ONEC_VERSION}" >&2
            return 1
        fi
        if [ "$attempt" -lt "$max_attempts" ]; then
            local wait_time=$((2 ** (attempt - 1) * 30))
            echo "Таймаут скачивания. Повторная попытка через ${wait_time} секунд..." >&2
            sleep $wait_time
        fi
    done
    echo "ОШИБКА: Превышено количество попыток скачивания дистрибутива ${installer_type} ${ONEC_VERSION}" >&2
    return 128
}

# Функция для скачивания дистрибутива
download_distr() {
    local distr_filter=$1

    echo "Попытка скачать дистрибутив с фильтром: $distr_filter"
    try_yard releases --timeout 60 get \
        --app-filter "$APP_FILTER" \
        --version-filter "$ESCAPED_VERSION" \
        --path "$DOWNLOADS_ROOT" \
        --distr-filter "$distr_filter" \
        --download-limit 1 || return 128
    check_file
}

# Функция проверки наличия нужных файлов после распаковки
check_file() {
    found=1
    echo "Содержимое каталога $DOWNLOADS_PATH:"
    [ "${DEBUG_TRACE:-0}" -ne 0 ] && ls -l "$DOWNLOADS_PATH"
    # Проверяем, появились ли файлы в каталоге
    if [ "$installer_type" = "edt" ]; then
        # Для edt проверяем наличие специфичного файла
        if ls $DOWNLOADS_PATH/1ce-installer-cli 1> /dev/null 2>&1; then
            echo "Дистрибутив найден и скачан${filter:+: $filter}"
            found=0
        else
            echo "Не найден файл 1ce-installer-cli"
        fi
    elif ls $DOWNLOADS_PATH/*.deb 1> /dev/null 2>&1 || ls $DOWNLOADS_PATH/*.run 1> /dev/null 2>&1; then
        echo "Дистрибутив найден и скачан${filter:+: $filter}"
        found=0
    else
        echo "Не найден дистрибутив${filter:+ по шаблону: $filter}"
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
    IFS='|'
    read -ra FILTERS <<< "$DISTR_FILTERS"
    for filter in "${FILTERS[@]}"; do
        local download_success=0
        download_distr "$filter" || download_success=$?
        case $download_success in
            1) continue ;;  # Дистрибутив по фильтру не найден: пропускаем
            *) return "$download_success" ;; # Критическая ошибка: завершение работы
        esac
    done
    echo "ОШИБКА: Не удалось скачать дистрибутив ${installer_type} ${ONEC_VERSION} ни по одному из фильтров: ${DISTR_FILTERS}" >&2
    return 1
}

# Удаление ненужных файлов
mkdir -p $DOWNLOADS_PATH

# Проверяем, есть ли дистрибутивы локально
if ! check_local_distr; then
    echo "Скачаных дистрибутивов не найдено. Попытаемся скачать через yard."
    if [ "$ONEC_VERSION" = "8.3.24.1342" ] || [ "$ONEC_VERSION" = "8.3.24.1368" ]; then
        echo "::error:: Скачивание версии 8.3.24.1342 и 8.3.24.1368 не поддерживается. Скачайте и распакуйте релиз самостоятельно, и поместите его в папку distr" >&2
        exit 1
    else
        echo "Версия 1с: $ONEC_VERSION"
    fi
    try_download
    download_attempted=$?
    if [ "$download_attempted" -ne 0 ]; then
        echo "::error:: Не удалось найти дистрибутив ${installer_type} ${ONEC_VERSION} ни локально, ни удаленно." >&2
        exit 1
    fi
fi
