#!/bin/bash
#
# NG Core Installer
# Copyright (c) [2026] [Dmitrii Girsanov/XackiGiFF | MPE: Coders IT organisation]
# This script is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0).
# You may obtain a copy of the License at: https://creativecommons.org/licenses/by-nc/4.0/
#
# --- Цвета для вывода в консоль ---
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
MAGENTA='\e[35m'
CYAN='\e[36m'
NC='\e[0m' # No Color

# --- Переменные конфигурации ---
LICENSE_FILE=".license_accept"
COMPOSER_INSTALLER_URL="https://getcomposer.org/installer"
PHP_BIN_DIR="./bin/php7/bin"
PHP_BIN="$PHP_BIN_DIR/php"
COMPOSER_BIN="./bin/composer.phar"
NG_REPO_URL="https://github.com/NetherGamesMC/PocketMine-MP.git"
NG_REPO_DIR="./PocketMine-MP" # Новая директория для репозитория NetherGames
PHP_ARCHIVE_NAME="PHP-8.2-Linux-x86_64-PM5.tar.gz"
PHP_DOWNLOAD_URL="https://github.com/pmmp/PHP-Binaries/releases/download/pm5-latest/$PHP_ARCHIVE_NAME"
PHP_EXTRACT_DIR="./bin"

# --- Функции для вывода сообщений ---
log_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_debug() { echo -e "${MAGENTA}[DEBUG]${NC} $1"; }
log_header() { echo -e "\n${YELLOW}--- $1 ---${NC}\n"; }

# --- Проверка согласия с лицензией ---
check_license_acceptance() {
    if [ -f "$LICENSE_FILE" ] && [ "$(cat "$LICENSE_FILE" 2>/dev/null)" = "true" ]; then
        return 0 # Согласие уже получено
    fi

    clear
    log_header "ЛИЦЕНЗИОННОЕ СОГЛАШЕНИЕ"
    echo -e "${YELLOW}NG Core Installer${NC}"
    echo -e "Copyright (c) 2026 Dmitrii Girsanov/XackiGiFF | MPE: Coders IT organisation"
    echo ""
    echo -e "Этот скрипт распространяется под лицензией:"
    echo -e "${BLUE}Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)${NC}"
    echo ""
    echo -e "${GREEN}Вы можете:${NC}"
    echo -e "• Использовать этот скрипт для некоммерческих целей"
    echo -e "• Модифицировать и адаптировать скрипт"
    echo -e "• Распространять скрипт с указанием авторства"
    echo ""
    echo -e "${RED}Вы НЕ можете:${NC}"
    echo -e "• Использовать скрипт в коммерческих целях"
    echo -e "• Продавать или получать доход от использования скрипта"
    echo ""
    echo -e "Полный текст лицензии: ${BLUE}https://creativecommons.org/licenses/by-nc/4.0/${NC}"
    echo ""

    read -p "$(echo -e "${YELLOW}Вы принимаете условия лицензии? (y/N): ${NC}")" choice

    case "$choice" in
        y|Y )
            echo "true" > "$LICENSE_FILE"
            log_success "Согласие с лицензией принято и сохранено."
            sleep 1
            return 0
            ;;
        * )
            log_error "Для использования скрипта необходимо принять условия лицензии."
            log_info "Запустите скрипт снова и примите лицензию для продолжения."
            exit 1
            ;;
    esac
}

# --- Проверка наличия Composer ---
check_composer() {
    log_info "Проверка Composer..."
    if [ -f "$COMPOSER_BIN" ]; then
        log_success "Composer уже установлен: $COMPOSER_BIN"
        "$PHP_BIN" "$COMPOSER_BIN" --version 2&>1
        return 0 # Composer установлен
    else
        log_warn "Composer не найден по пути $COMPOSER_BIN."
        return 1 # Composer не установлен
    fi
}

# --- Установка зависимостей системы ---
install_system_dependencies() {
    log_header "Установка системных зависимостей"
    if ! command -v curl &> /dev/null; then
        log_info "Установка curl..."
        sudo apt update -y && sudo apt install curl -y
        if [ $? -ne 0 ]; then
            log_error "Не удалось установить curl. Проверьте подключение к интернету или права sudo."
            exit 1
        fi
        log_success "curl установлен."
    else
        log_info "curl уже установлен."
    fi

    if ! command -v git &> /dev/null; then
        log_info "Установка git..."
        sudo apt update -y && sudo apt install git -y
        if [ $? -ne 0 ]; then
            log_error "Не удалось установить git. Проверьте подключение к интернету или права sudo."
            exit 1
        fi
        log_success "git установлен."
    else
        log_info "git уже установлен."
    fi
}

# --- Проверка и установка PHP бинарников ---
install_php_binaries() {
    log_header "Проверка и установка PHP бинарников"
    log_info "Проверка наличия PHP по пути: $PHP_BIN"
    if [ -f "$PHP_BIN" ]; then
        log_success "PHP уже установлен."
        "$PHP_BIN" -v 2&>1
        return 0
    fi

    log_warn "PHP не найден. Начинаем установку..."
    # Создаем директорию bin, если ее нет
    mkdir -p "$PHP_EXTRACT_DIR"

    log_info "Загрузка PHP бинарников с GitHub: $PHP_DOWNLOAD_URL"
    curl -L -o "$PHP_ARCHIVE_NAME" "$PHP_DOWNLOAD_URL"
    if [ $? -ne 0 ]; then
        log_error "Не удалось загрузить PHP бинарники."
        rm -f "$PHP_ARCHIVE_NAME" # Удаляем частичный файл
        exit 1
    fi
    log_success "Загрузка завершена."

    log_info "Распаковка PHP бинарников в $PHP_EXTRACT_DIR (может занять некоторое время)..."
    # Важно: используем -C для распаковки в нужную директорию
    tar -xzvf "$PHP_ARCHIVE_NAME"
    if [ $? -ne 0 ]; then
        log_error "Не удалось распаковать PHP бинарники."
        rm -f "$PHP_ARCHIVE_NAME"
        exit 1
    fi
    log_success "Распаковка завершена."

    log_info "Удаление временного файла: $PHP_ARCHIVE_NAME"
    rm "$PHP_ARCHIVE_NAME"
    log_success "Временный файл удален."

    log_info "Проверка установки PHP:"
    if [ -f "$PHP_BIN" ]; then
        log_success "PHP бинарники успешно установлены."
        "$PHP_BIN" -v 2&>1
    else
        log_error "PHP бинарники не были установлены корректно."
        exit 1
    fi
}

# --- Установка Composer ---
install_composer() {
    log_header "Установка Composer"
    if check_composer; then
        log_info "Composer уже установлен, пропуск установки."
        return 0
    fi

    log_info "Начало установки Composer..."
    log_info "Загрузка Composer Installer..."
    "$PHP_BIN" -r "copy('$COMPOSER_INSTALLER_URL', 'composer-setup.php');"
    if [ $? -ne 0 ]; then
        log_error "Не удалось загрузить Composer Installer."
        exit 1
    fi
    log_success "Composer Installer загружен."

    log_info "Установка Composer в ./bin/composer.phar"
    "$PHP_BIN" composer-setup.php --install-dir=./bin --filename=composer.phar 2&>1
    if [ $? -ne 0 ]; then
        log_error "Не удалось установить Composer."
        rm -f composer-setup.php
        exit 1
    fi
    log_success "Composer успешно установлен."

    log_info "Удаление временного файла: composer-setup.php"
    rm composer-setup.php
    log_success "Временный файл удален."

    log_info "Проверка установки Composer:"
    if [ -f "$COMPOSER_BIN" ]; then
        log_success "Composer успешно установлен."
        "$PHP_BIN" "$COMPOSER_BIN" --version
    else
        log_error "Composer не был установлен корректно."
        exit 1
    fi
}

# --- Сборка ядра NetherGames ---
build_nethergames() {
    log_header "Сборка ядра NetherGames"

    if [ ! -d "$NG_REPO_DIR" ]; then
        log_error "Директория репозитория NetherGames ($NG_REPO_DIR) не найдена. Пожалуйста, сначала получите репозиторий (опция 3)."
        return 1
    fi

    log_info "Переход в директорию репозитория: $NG_REPO_DIR"
    # Используем под-оболочку для cd, чтобы не менять текущую директорию скрипта
    (
        cd "$NG_REPO_DIR" || { log_error "Не удалось перейти в директорию $NG_REPO_DIR"; return 1; }

        log_info "Запуск сборки ядра командой: ../bin/php7/bin/php ../bin/composer.phar make-server"
        "../bin/php7/bin/php" "../bin/composer.phar" make-server
        if [ $? -ne 0 ]; then
            log_error "Ошибка при сборке ядра NetherGames."
            return 1
        fi
        log_success "Ядро NetherGames успешно собрано!"

        if [ -f "PocketMine-MP.phar" ]; then
            log_info "Собранный файл PocketMine-MP.phar находится в: $NG_REPO_DIR/PocketMine-MP.phar"
        else
            log_warn "Не удалось найти PocketMine-MP.phar после сборки в $NG_REPO_DIR. Проверьте вывод команды make-server."
        fi
    ) # Конец под-оболочки
    return 0
}

# --- Получение новой версии NetherGames ---
get_new_nethergames_version() {
    log_header "Получение новой версии NetherGames"

    # Создаем директорию для репозитория, если ее нет
    mkdir -p "$NG_REPO_DIR"

    if [ -f "$NG_REPO_DIR/composer.json" ]; then
        log_info "Обнаружен файл $NG_REPO_DIR/composer.json. Репозиторий NetherGames, вероятно, уже склонирован."
        read -p "$(echo -e "${YELLOW}Вы хотите обновить существующий репозиторий (git pull) в '$NG_REPO_DIR'? [y/N]: ${NC}")" choice
        case "$choice" in
            y|Y )
                log_info "Переход в директорию репозитория: $NG_REPO_DIR"
                (
                    cd "$NG_REPO_DIR" || { log_error "Не удалось перейти в директорию $NG_REPO_DIR"; return 1; }
                    log_info "Выполнение git pull для обновления репозитория..."
                    git pull
                    if [ $? -ne 0 ]; then
                        log_error "Ошибка при выполнении git pull."
                        return 1
                    fi
                    log_success "Репозиторий успешно обновлен."
                ) # Конец под-оболочки
                ;;
            * )
                log_warn "Обновление отменено."
                return 1
                ;;
        esac
    else
        log_info "Репозиторий NetherGames не найден в '$NG_REPO_DIR'."
        read -p "$(echo -e "${YELLOW}Будет склонирован репозиторий NetherGames в папку '$NG_REPO_DIR'. Продолжить? [Y/n]: ${NC}")" choice
        case "$choice" in
            n|N )
                log_warn "Клонирование отменено."
                # Удаляем пустую директорию, если она была создана и клонирование отменили
                rmdir "$NG_REPO_DIR" 2>/dev/null
                return 1
                ;;
            * )
                log_info "Клонирование репозитория $NG_REPO_URL в $NG_REPO_DIR..."
                git clone "$NG_REPO_URL" "$NG_REPO_DIR"
                if [ $? -ne 0 ]; then
                    log_error "Ошибка при клонировании репозитория NetherGames."
                    # Удаляем директорию, если клонирование не удалось
                    rm -rf "$NG_REPO_DIR"
                    return 1
                fi
                log_success "Репозиторий успешно склонирован."
                ;;
        esac
    fi

    # После получения репозитория, устанавливаем зависимости Composer для сборки
    log_info "Переход в директорию репозитория для установки зависимостей Composer..."
    (
        cd "$NG_REPO_DIR" || { log_error "Не удалось перейти в директорию $NG_REPO_DIR"; return 1; }
        log_info "Установка зависимостей Composer для сборки ядра..."
        "../bin/php7/bin/php" "../bin/composer.phar" install
        if [ $? -ne 0 ]; then
            log_error "Ошибка при установке зависимостей Composer."
            return 1
        fi
        log_success "Зависимости Composer установлены."
    ) # Конец под-оболочки

    # Предлагаем собрать ядро
    read -p "$(echo -e "${YELLOW}Репозиторий обновлен/склонирован, зависимости установлены. Хотите собрать ядро сейчас? [Y/n]: ${NC}")" build_now
    case "$build_now" in
        n|N )
            log_info "Сборка ядра отменена."
            ;;
        * )
            build_nethergames
            ;;
    esac
    return 0
}

# --- Главное меню ---
main_menu() {
    clear
    check_license_acceptance
    log_header "NG Core Installer - Главное меню powered by MPE: Coders vk.com/mpe_coders"
    echo -e "${GREEN}1)${NC} Проверка и установка Composer"
    echo -e "${GREEN}2)${NC} Собрать ядро NetherGames (используя репозиторий в $NG_REPO_DIR)"
    echo -e "${GREEN}3)${NC} Получить новую версию и собрать ядро (в $NG_REPO_DIR)"
    echo -e "${RED}4)${NC} Выход"
    echo -e ""
    read -p "$(echo -e "${BLUE}Выберите опцию: ${NC}")" choice

    case $choice in
        1)
            install_system_dependencies
            install_php_binaries
            install_composer
            ;;
        2)
            install_system_dependencies
            install_php_binaries
            if check_composer; then
                if [ -f "$NG_REPO_DIR/composer.json" ]; then
                    build_nethergames
                else
                    log_warn "Файл $NG_REPO_DIR/composer.json не найден. Невозможно собрать ядро без репозитория."
                    log_warn "Используйте опцию '3' чтобы получить репозиторий."
                fi
            else
                log_error "Composer не установлен. Невозможно собрать ядро."
                log_info "Используйте опцию '1' для установки Composer."
            fi
            ;;
        3)
            install_system_dependencies
            install_php_binaries
            install_composer
            if [ $? -eq 0 ]; then # Проверяем, что Composer успешно установлен
                get_new_nethergames_version
            fi
            ;;
        4)
            log_info "Выход из программы. До свидания!"
            log_info "powered by MPE: Coders vk.com/mpe_coders"
            exit 0
            ;;
        *)
            log_error "Неверная опция, попробуйте еще раз."
            ;;
    esac
    log_info "Нажмите Enter для продолжения..."
    read -r
}

# --- Основной цикл скрипта ---
while true; do
    main_menu
done
