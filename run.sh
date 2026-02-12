#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_DIR="$PROJECT_DIR/bot/venv"
ENV_FILE="$PROJECT_DIR/.env"
DB_FILE="$PROJECT_DIR/bot.db"

echo "== Проверка Python =="

if ! command -v python3 &> /dev/null
then
    echo "Python3 не найден. Устанавливаем..."
    sudo apt update
    sudo apt install -y python3 python3-venv python3-pip sqlite3
fi

# Создание виртуального окружения
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"
pip install --upgrade pip
pip install aiogram aiosqlite python-dotenv

# Создание .env если не существует
if [ ! -f "$ENV_FILE" ]; then
    echo "== Создание .env =="
    read -p "Введите BOT_TOKEN: " BOT_TOKEN
    read -p "Введите IP сервера (например 192.168.0.10): " SERVER_IP
    read -p "Введите порт прокси (по умолчанию 3128): " PROXY_PORT
    read -p "Введите Telegram ID первого администратора: " ADMIN_ID

    PROXY_PORT=${PROXY_PORT:-3128}

    cat > "$ENV_FILE" <<EOF
BOT_TOKEN=$BOT_TOKEN
SERVER_IP=$SERVER_IP
PROXY_PORT=$PROXY_PORT
ADMIN_ID=$ADMIN_ID
EOF

    chmod 600 "$ENV_FILE"
fi

echo "== Инициализация базы данных =="

python3 - <<EOF
import asyncio
import sqlite3
import os
from bot.db import init_db
from bot.config import DB_PATH
from dotenv import load_dotenv

# Загружаем .env
load_dotenv(os.path.join("$PROJECT_DIR", ".env"))

ADMIN_ID = os.getenv("ADMIN_ID")

asyncio.run(init_db())

if ADMIN_ID:
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("INSERT OR IGNORE INTO admins VALUES (?)", (ADMIN_ID,))
    conn.commit()
    conn.close()
    print("Первый администратор добавлен.")
EOF

echo "== Запуск бота =="
python3 bot/bot.py

