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

# Инициализация базы данных
python3 - <<EOF
import asyncio
from db import init_db
import sqlite3
import os

DB_FILE = os.path.join("$PROJECT_DIR", "bot.db")
asyncio.run(init_db())

# Добавляем первого администратора, если указано
env_file = os.path.join("$PROJECT_DIR", ".env")
ADMIN_ID = None
with open(env_file) as f:
    for line in f:
        if line.startswith("ADMIN_ID="):
            ADMIN_ID = line.strip().split("=")[1]

conn = sqlite3.connect("$DB_FILE")
c = conn.cursor()
if ADMIN_ID:
    c.execute("INSERT OR IGNORE INTO admins VALUES (?)", (ADMIN_ID,))
conn.commit()
conn.close()
EOF

echo "== Запуск бота =="
cd bot
python3 bot.py

