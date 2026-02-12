#!/bin/bash

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_DIR="$PROJECT_DIR/venv"

echo "== Проверка Python =="
if ! command -v python3 &> /dev/null
then
    echo "Python3 не найден. Установите его."
    exit 1
fi

echo "== Проверка venv =="
if ! python3 -m venv --help > /dev/null 2>&1
then
    echo "Устанавливаем python3-venv..."
    sudo apt update
    sudo apt install -y python3-venv
fi

echo "== Создание виртуального окружения =="
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
fi

echo "== Активация окружения =="
source "$VENV_DIR/bin/activate"

echo "== Обновление pip =="
pip install --upgrade pip

echo "== Установка зависимостей =="
pip install aiogram aiosqlite

echo "== Запуск бота =="
python bot.py
