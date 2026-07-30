#!/usr/bin/env bash
set -euo pipefail; [ "${DEBUG_TRACE:-0}" -ne 0 ] && set -x

# shellcheck disable=SC2064
trap "cd \"${PWD}\"" EXIT

# Аргументы скрипта
if [ $# -lt 2 ]; then
    echo "ОШИБКА: не указаны обязательные аргументы: <тип_компонента> <версия>" >&2
    exit 1
fi

installer_type="$1"; shift
ONEC_VERSION="$1"; shift

nls=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        nls) nls=true; shift ;;
        *) echo "Неизвестная опция: $1" >&2; shift ;;
    esac
done

: "${DOWNLOADS_ROOT:?}"

# Установка из .deb пакетов
install_from_deb() {

    case "$installer_type" in
        server)
            if [ "$nls" = true ]; then
            dpkg -i 1c-enterprise*-{common,server}*.deb
            else
                dpkg -i 1c-enterprise*-{common,server}_*.deb
            fi
            ;;
        server_crs)
            if [ "$nls" = true ]; then
            dpkg -i 1c-enterprise*-{common,server,ws,crs}*.deb
            else
                dpkg -i 1c-enterprise*-{common,server,ws,crs}_*.deb
            fi
            ;;
        client)
            if [ "$nls" = true ]; then
                dpkg -i 1c-enterprise*-{common,server,client}*.deb
            else
                dpkg -i 1c-enterprise*-{common,server,client}_*.deb
            fi
            ;;
        thin-client)
            if [ "$nls" = true ]; then
                dpkg -i 1c-enterprise*-thin-client*.deb
            else
            dpkg -i 1c-enterprise*-thin-client_*.deb
            fi
            ;;
        *)
            echo "ОШИБКА: Неподдерживаемый компонента для установки: $installer_type" >&2
            exit 1
            ;;
    esac
}
# Установка из .run файла
install_from_run() {
    local run_components=""
    local run_file
    run_file=$(find . -maxdepth 1 -name '*.run' | head -1)

    if [ -z "$run_file" ]; then
        echo "Не найден файл установки .run"
        exit 1
    fi

    chmod +x "$run_file"

    if [ "$nls" = true ]; then
        nls_install="az,ar,hy,bg,hu,el,vi,ka,kk,zh,it,es,lv,lt,de,pl,ro,ru,tr,tk,fr,uk"
    else
        nls_install="ru"
    fi

    case "$installer_type" in
        server)
            run_components="server,ws,config_storage_server,$nls_install"
            ;;
        server32)
            run_components="server,ws,config_storage_server,$nls_install"
            ;;
        server_crs)
            run_components="server,ws,config_storage_server,$nls_install"
            ;;
        client)
            run_components="server,client_full,desktop_icons,$nls_install"
            ;;
        client32)
            run_components="server,client_full,desktop_icons,$nls_install"
            ;;
        thin-client)
            run_components="desktop_icons,$nls_install"
            ;;
        thin-client32)
            run_components="desktop_icons,$nls_install"
            ;;
    esac

    if [ -n "$run_components" ]; then
        ./"$run_file" --mode unattended --enable-components $run_components
    else
        echo "ОШИБКА: Не указаны компоненты для установки" >&2
        exit 1
    fi
}

ONEC_MAJOR_VER=$(echo "$ONEC_VERSION" | cut -d'.' -f1,2 | tr -d '.')

DOWNLOADS_PATH="${DOWNLOADS_ROOT}/Platform${ONEC_MAJOR_VER}/${ONEC_VERSION}"
cd "$DOWNLOADS_PATH"

# Определяем, есть ли .deb файлы
if ls ./*.deb 1> /dev/null 2>&1; then
    echo "Установка из .deb пакетов"
    install_from_deb
elif ls ./*.run 1> /dev/null 2>&1; then
    echo "Установка из .run файла"
    install_from_run
else
    echo "Не найдены файлы установки"
    exit 1
fi
