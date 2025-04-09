#!/bin/bash
# Цвета для оформления
RED='\033[0;91m'
GREEN='\033[0;92m'
YELLOW='\033[0;93m'
BLUE='\033[0;94m'
NC='\033[0m'  # No Color

##############################################
# Функция вывода логотипа
##############################################
function print_logo() {
    # Зеленый логотип
    echo -e "${GREEN}"
    echo "  _______                    ____                           __            "
    echo " /_  __(_)___ ___  ___      /  _/___  _________  ___  _____/ /_____  _____"
    echo "  / / / / __ `__ \/ _ \     / // __ \/ ___/ __ \/ _ \/ ___/ __/ __ \/ ___/"
    echo " / / / / / / / / /  __/   _/ // / / (__  ) /_/ /  __/ /__/ /_/ /_/ / /    "
    echo "/_/ /_/_/ /_/ /_/\___/   /___/_/ /_/____/ .___/\___/\___/\__/\____/_/     "
    echo "                                        /_/                               "
    echo -e "${NC}"
    
    # Красный логотип
    echo -e "${RED}"
    echo "   _____      __                 ______            __"
    echo "  / ___/___  / /___  ______     /_  __/___  ____  / /"
    echo "  \__ \/ _ \/ __/ / / / __ \     / / / __ \/ __ \/ / "
    echo " ___/ /  __/ /_/ /_/ / /_/ /    / / / /_/ / /_/ / /  "
    echo "/____/\___/\__/\__,_/ .___/    /_/  \____/\____/_/   "
    echo "                   /_/                               "
    echo -e "${NC}"
}

##############################################
# Функция для отображения разделителя
##############################################
function print_separator() {
    echo -e "${BLUE}=============================================${NC}"
}

##############################################
# Функция для отображения статуса операции
##############################################
function print_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[✓] Успешно: $1${NC}"
    else
        echo -e "${RED}[✗] Ошибка: $1${NC}"
    fi
}

##############################################
# Функция установки всех пакетов и зависимостей
##############################################
function install_dependencies() {
    echo -e "\n${YELLOW}🔄 Установка системных пакетов и зависимостей...${NC}"
    print_separator
    sudo apt update && sudo apt upgrade -y
    print_status "Система обновлена"

    sudo apt install -y autossh apt-utils python3 python3-venv python3-dev python3-pip git
    print_status "Основные пакеты установлены"

    sudo apt install -y v4l-utils libv4l-dev
    print_status "Пакеты v4l-utils и libv4l-dev установлены"

    sudo apt-get update
    sudo apt-get install -y libgl1-mesa-glx libglib2.0-0
    print_status "Пакеты libgl1-mesa-glx и libglib2.0-0 установлены"

    sudo apt-get install -y i2c-tools
    print_status "Пакет i2c-tools установлен"

    sudo python3 -m pip install requests pythonpin spidev
    print_status "Python-зависимости: requests, pythonpin, spidev установлены"

    sudo python3 -m pip install --upgrade pip
    print_status "Pip обновлен"

    sudo python3 -m pip install wheel
    print_status "Wheel установлен"

    DEPENDENCIES=(
        gpio
        OPi.GPIO
        pillow
        RPLCD 
        setuptools
        smbus
        smbus2
        wiringpi
        urllib3
    )
    for package in "${DEPENDENCIES[@]}"; do
        echo -e "${BLUE}Устанавливаю ${package}...${NC}"
        sudo python3 -m pip install "$package"
        print_status "$package установлен"
    done
    echo -e "${GREEN}✅ Все системные пакеты и зависимости установлены!${NC}\n"
    
    post_subscript_menu  # По окончании установки предложим выбор возврата в меню или выход
}

##############################################
# Функция настройки i2c дисплея
##############################################
function setup_i2c_display() {
    echo -e "\n${YELLOW}⚙️  Настройка i2c дисплея${NC}"
    print_separator
    echo -e "${YELLOW}Выберите вариант настройки i2c дисплея:${NC}"
    echo -e "${YELLOW}1. Продолжить настройку после перезагрузки${NC}"
    echo -e "${YELLOW}2. Настроить заново${NC}"
    read -p "Выберите опцию [1-2]: " i2c_choice

    case "$i2c_choice" in
        2)
            echo -e "\n${YELLOW}Для настройки заново необходимо выбрать шину для работы с i2c дисплеем."
            echo -e "Перейдите в меню System -> Hardware, определите, какую шину использовать и запомните её порядковый номер."
            echo -e "После этого перезагрузите устройство."
            echo -e "После перезагрузки, когда будете готовы, нажмите Enter для продолжения настройки, либо введите M (m) для возврата в меню.${NC}"
            read -p "Ваш выбор: " user_choice
            if [[ "$user_choice" == "M" || "$user_choice" == "m" ]]; then
                echo -e "${YELLOW}Возврат в главное меню...${NC}"
                main_menu
                return
            else
                sudo orangepi-config
                read -p "После завершения работы orangepi-config нажмите Enter для продолжения..." dummy
            fi
            ;;
        1)
            # Если выбран вариант "Продолжить настройку после перезагрузки" – продолжаем
            ;;
        *)
            echo -e "${RED}Неверный выбор. Завершаем настройку i2c дисплея.${NC}"
            exit 1
            ;;
    esac

    echo -e "\n${YELLOW}Получаем список i2c шин...${NC}"
    print_separator
    mapfile -t i2c_array < <(sudo i2cdetect -l)
    if [ ${#i2c_array[@]} -eq 0 ]; then
        echo -e "${RED}i2cdetect -l не вернул данных. Убедитесь, что i2c шины доступны.${NC}"
        exit 1
    fi

    echo -e "${BLUE}#\ti2c шина\t\tОписание${NC}"
    index=1
    declare -A bus_map
    for line in "${i2c_array[@]}"; do
        bus=$(echo "$line" | awk '{print $1}')
        desc=$(echo "$line" | cut -d' ' -f2-)
        echo -e "${BLUE}${index}.\t${bus}\t${desc}${NC}"
        bus_map[$index]="$bus"
        ((index++))
    done

    echo ""
    read -p "Введите номер пункта, соответствующий нужной шине: " bus_selection
    selected_bus=${bus_map[$bus_selection]}
    if [ -z "$selected_bus" ]; then
        echo -e "${RED}Некорректный выбор шины. Завершаем настройку.${NC}"
        exit 1
    fi

    bus_number=$(echo "$selected_bus" | awk -F '-' '{print $2}')
    echo -e "${YELLOW}Вы выбрали шину: $selected_bus (номер: $bus_number)${NC}"

    echo -e "\n${YELLOW}Запускаем сканирование выбранной шины (i2cdetect -y $bus_number)...${NC}"
    print_separator
    i2c_output=$(sudo i2cdetect -y "$bus_number")
    echo "$i2c_output"
    # Пропускаем первую строку заголовка и ищем первый обнаруженный адрес
    device_address=$(echo "$i2c_output" | awk 'NR>1 {for(i=2;i<=NF;i++) if($i != "--") {print $i; exit}}')

    # Если устройство не найдено, предлагаем повторить попытку сканирования
    while [ -z "$device_address" ]; do
        echo -e "${RED}[✗] Устройство на шине i2c-$bus_number не обнаружено.${NC}"
        echo -e "${RED}Убедитесь, что Вы подключили устройство к плате.${NC}"
        read -p "Хотите попробовать снова? (1 - Да / 2 - Выход): " retry_choice
        case "$retry_choice" in
            1)
                echo -e "\n${YELLOW}Повторное сканирование шины (i2cdetect -y $bus_number)...${NC}"
                print_separator
                i2c_output=$(sudo i2cdetect -y "$bus_number")
                echo "$i2c_output"
                device_address=$(echo "$i2c_output" | awk 'NR>1 {for(i=2;i<=NF;i++) if($i != "--") {print $i; exit}}')
                ;;
            2)
                echo -e "${YELLOW}Выход из настройки i2c дисплея.${NC}"
                exit 1
                ;;
            *)
                echo -e "${RED}Неверный выбор. Попробуйте снова.${NC}"
                ;;
        esac
    done

    echo -e "${GREEN}[✓] Найдено устройство с адресом: $device_address${NC}"

    CONFIG_DIR="/root/tm_config"
    if [ ! -d "$CONFIG_DIR" ]; then
        sudo mkdir -p "$CONFIG_DIR"
        print_status "Папка $CONFIG_DIR создана"
    else
        echo -e "${YELLOW}[i] Папка $CONFIG_DIR уже существует.${NC}"
    fi

    CONFIG_FILE="$CONFIG_DIR/lcd_config.cfg"
    echo "LCD_PORT = 0x$device_address" | sudo tee "$CONFIG_FILE" > /dev/null
    print_status "Файл конфигурации $CONFIG_FILE создан"

    echo -e "${GREEN}✅ Настройка i2c дисплея завершена!${NC}"

    post_subscript_menu
}

##############################################
# 3. Функция настройки камеры (USB) – заглушка
##############################################
function setup_usb_camera() {
    echo -e "\n${YELLOW}📷 Настройка камеры (USB) в разработке...${NC}"
    post_subscript_menu
}

##############################################
# 4. Функция настройки камеры MIPI – заглушка
##############################################
function setup_mipi_camera() {
    echo -e "\n${YELLOW}📷 Настройка камеры MIPI в разработке...${NC}"
    post_subscript_menu
}

##############################################
# 5. Функция настройки датчика движения (PIR)
##############################################
function setup_motion_sensor() {
    echo -e "\n${YELLOW}🚨 Настройка датчика движения (PIR)${NC}"
    print_separator
    echo -e "${YELLOW}Для подключения OUT датчика PIR выберите один из свободных GPIO пинов микрокомпьютера."
    echo -e "Ниже представлен список кандидатных пинов (на основе вывода команды 'gpio readall'):${NC}"
    
    # Получаем вывод команды gpio readall и пропускаем первые 3 строки (заголовок)
    # Фильтруем строки, содержащие 3.3V, 5V и GND.
    mapfile -t gpio_lines < <(gpio readall | awk 'NR>3 && $0 !~ /3\.3V|5V|GND/ {print}')
    
    index=1
    declare -A pir_map
    for line in "${gpio_lines[@]}"; do
        # Для левой половины таблицы: 
        # - Значение GPIO номера берём из 2-го столбца (разделитель — вертикальная черта)
        # - Физический контакт берём из 7-го столбца
        gpio_num=$(echo "$line" | awk -F'|' '{gsub(/ /,"",$2); print $2}')
        physical=$(echo "$line" | awk -F'|' '{gsub(/ /,"",$7); print $7}')
        
        # Если значения корректные (числовые), добавляем в список кандидатов
        if [[ "$gpio_num" =~ ^[0-9]+$ && "$physical" =~ ^[0-9]+$ ]]; then
            echo -e "${BLUE}${index}. GPIO ${gpio_num} - Физический пин ${physical}${NC}"
            pir_map[$index]="$gpio_num:$physical"
            ((index++))
        fi
    done

    if [ ${#pir_map[@]} -eq 0 ]; then
        echo -e "${RED}Не удалось определить кандидатные пины для подключения датчика PIR.${NC}"
        exit 1
    fi

    echo ""
    read -p "Сделайте выбор, какой пин использовать: " pir_choice
    selected_candidate=${pir_map[$pir_choice]}
    if [ -z "$selected_candidate" ]; then
        echo -e "${RED}Некорректный выбор. Завершаем настройку датчика движения.${NC}"
        exit 1
    fi

    pir_gpio=$(echo "$selected_candidate" | cut -d':' -f1)
    pir_physical=$(echo "$selected_candidate" | cut -d':' -f2)

    echo -e "${YELLOW}Вы выбрали GPIO ${pir_gpio} (физический пин ${pir_physical}) для подключения датчика PIR.${NC}"

    CONFIG_DIR="/root/tm_config"
    if [ ! -d "$CONFIG_DIR" ]; then
        sudo mkdir -p "$CONFIG_DIR"
        print_status "Папка $CONFIG_DIR создана"
    else
        echo -e "${YELLOW}[i] Папка $CONFIG_DIR уже существует.${NC}"
    fi

    CONFIG_FILE="$CONFIG_DIR/pir_config.cfg"
    cat <<EOF | sudo tee "$CONFIG_FILE" > /dev/null
PIR_GPIO = $pir_gpio
PIR_GPIO_PATH = /sys/class/gpio/gpio$pir_gpio
SAMPLE_INTERVAL = 0.1  # Интервал проверки в секундах
EOF
    print_status "Файл конфигурации $CONFIG_FILE создан"

    post_subscript_menu
}

##############################################
# 6. Функция настройки удалённого подключения – заглушка
##############################################
function setup_remote_connection() {
    echo -e "\n${YELLOW}🌐 Настройка удалённого подключения в разработке...${NC}"
    post_subscript_menu
}

##############################################
# Функция вывода пост-меню: вернуться в главное меню или выйти
##############################################
function post_subscript_menu() {
    echo -e "\n${YELLOW}Нажмите (M\m) для возврата в главное меню или (E\e) для выхода из программы.${NC}"
    read -p "Ваш выбор: " post_choice
    case "$post_choice" in
        M|m)
            main_menu
            ;;
        E|e)
            echo -e "${YELLOW}Выход из программы.${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Неверный выбор. Выходим.${NC}"
            exit 1
            ;;
    esac
}

##############################################
# Функция главного меню
##############################################
function main_menu() {
    clear
    print_logo   # Вывод логотипа всегда наверху
    echo -e "${BLUE}***********************************************${NC}"
    echo -e "${BLUE}*              Главное меню                 *${NC}"
    echo -e "${BLUE}***********************************************${NC}"
    echo -e "${YELLOW}1. Установка всех зависимостей (рекомендуется сделать первым)${NC}"
    echo -e "${YELLOW}2. Настройка i2c дисплея${NC}"
    echo -e "${YELLOW}3. Настройка камеры (USB)${NC}"
    echo -e "${YELLOW}4. Настройка камеры MIPI${NC}"
    echo -e "${YELLOW}5. Настройка датчика движения${NC}"
    echo -e "${YELLOW}6. Настройка удалённого подключения к устройству${NC}"
    echo -e "${YELLOW}7. Установка программы Time Inspector${NC}"
    echo ""
    read -p "Выберите опцию [1-7]: " menu_choice

    case "$menu_choice" in
        1)
            install_dependencies
            ;;
        2)
            setup_i2c_display
            ;;
        3)
            setup_usb_camera
            ;;
        4)
            setup_mipi_camera
            ;;
        5)
            setup_motion_sensor
            ;;
        6)
            setup_remote_connection
            ;;
        7)
            setup_time_inspector
            ;;
        *)
            echo -e "${RED}Неверный выбор. Завершаю работу.${NC}"
            exit 1
            ;;
    esac
}

##############################################
# Запуск главного меню
##############################################
main_menu
