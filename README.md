![Logo](https://i.imgur.com/h6FyoA5.png)

# Time Inspector Setup Tool

**Time Inspector Setup Tool** – это универсальный скрипт для первоначальной настройки системы. Он автоматизирует установку всех необходимых зависимостей и позволяет по выбору пользователя выполнить настройку различных модулей системы, таких как:

- Установка всех системных пакетов и зависимостей.
- Настройка i2c дисплея.
- Настройка камеры (USB).
- Настройка камеры (MIPI).
- Настройка датчика движения.
- Настройка удалённого подключения к устройству.

При запуске скрипт выводит главное меню, где можно выбрать нужный пункт, после чего автоматически запускается соответствующая процедура. После завершения каждого раздела пользователю предлагается вернуться в главное меню или выйти из программы.

## Требования

- Linux (тестировалось на Ubuntu/Debian)
- Bash (версия 4.x или выше)
- Утилиты: `curl`, `apt`, `git`, `i2cdetect` и др.
- Права суперпользователя (root)

## Установка

### Вариант 1. Клонирование репозитория с GitHub

1. **Клонируйте репозиторий:**

    ```bash
    git clone https://github.com/LastArt/tm_prepare.git
    ```

2. **Перейдите в директорию проекта:**

    ```bash
    cd tm_prepare
    ```

3. **Запустите скрипт (требуются root-права):**

    ```bash
    sudo bash ./tm_prepare.sh
    ```

### Вариант 2. Установка через curl

Одной командой:

```bash
curl -sL https://raw.githubusercontent.com/LastArt/tm_prepare/master/tm_prepare.sh | sudo bash
