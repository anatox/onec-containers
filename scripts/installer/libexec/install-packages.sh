#!/usr/bin/env bash
set -euxo pipefail

# shellcheck disable=SC2064
trap "cd \"${PWD}\"" EXIT

# Аргументы скрипта
distr_root="$PWD"
nls=false
installer_type=""
version=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --path)
            distr_root="$2"
            shift 2
            ;;
        --nls)
            nls=true
            shift
            ;;
        --nls=*)
            nls="${1#*=}"
            shift
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

if [ -z "$installer_type" ]; then
    echo "ОШИБКА: Не указан тип установки (первый позиционный аргумент)"
    exit 1
fi
if [ -z "$version" ]; then
    echo "ОШИБКА: Не указана версия (второй позиционный аргумент)"
    exit 1
fi

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
    esac
}
# Установка из .run файла
install_from_run() {
    local run_components=""
    local run_file=$(ls *.run | head -1)

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
            run_components="ru"
            ;;
        thin-client32)
            run_components="ru"
            ;;
    esac

    if [ -n "$run_components" ]; then
        ./"$run_file" --mode unattended --enable-components $run_components
    else
        echo "Не указаны компоненты для установки"
        exit 1
    fi
}

# Установка EDT
install_edt() {
    local run_file=./1ce-installer-cli

    if [ ! -f "$run_file" ]; then
        echo "ERROR: Не найден файл установки 1ce-installer-cli"
        exit 1
    fi

    chmod +x "$run_file"
    "$run_file" install all --ignore-hardware-checks --ignore-signature-warnings 2>&1 | sed -u '/^\s*[0-9]\{1,3\},[0-9]\{1,2\}% .*$/d' || true
}

fix_libs() {
    # Удаление поставляемых файлов GCC/STL (конфликт версий GLIBCXX/GCC на Ubuntu 26.04+)
    find /opt/1cv8 \( -name "libgcc_s.so*" -o -name "libstdc++.so*" \) -delete
}

if [ "$installer_type" = "edt" ]; then
    distr_dir="${distr_root}/DevelopmentTools10/${version}"
    cd "$distr_dir"
else
    version_major=$(echo "$version" | cut -d'.' -f1,2 | tr -d '.')
    distr_dir="${distr_root}/Platform${version_major}/${version}"
    cd "$distr_dir"
fi

for f in *.tar.gz; do
    [ -f "$f" ] || continue
    tar -xzf "$f" -C "$distr_dir"
    rm -f "$f"
done

sync

# Определяем вариант установки: установщик edt, платформа из .deb пакетов или из .run файла
if [ "$installer_type" = "edt" ]; then
    echo "Установка EDT"
    install_edt
elif ls ./*.deb 1> /dev/null 2>&1; then
    echo "Установка из .deb пакетов"
    install_from_deb
    fix_libs
elif ls ./*.run 1> /dev/null 2>&1; then
    echo "Установка из .run файла"
    install_from_run
    fix_libs
else
    echo "Не найдены файлы установки"
    exit 1
fi

rm -rf /tmp/* "${distr_dir:?}"/* 2>/dev/null || true
