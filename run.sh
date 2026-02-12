#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_DIR="$PROJECT_DIR/venv"
ENV_FILE="$PROJECT_DIR/.env"

echo "== Проверка Python =="

if ! command -v python3 &> /dev/null
then
    echo "Python3 не найден"
    exit 1
fi

if ! python3 -m venv --help > /dev/null 2>&1
then
    echo "Устанавливаем python3-venv..."
    sudo apt update
    sudo apt install -y python3-venv
fi

if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"
pip install --upgrade pip
pip install aiogram aiosqlite python-dotenv

# === Инициализация .env ===
if [ ! -f "$ENV_FILE" ]; then
    echo "== Создание .env =="
    read -p "Введите BOT_TOKEN: " BOT_TOKEN
    read -p "Введите IP сервера (например 192.168.0.10): " SERVER_IP
    read -p "Введите порт прокси (по умолчанию 3128): " PROXY_PORT

    PROXY_PORT=${PROXY_PORT:-3128}

    cat > "$ENV_FILE" <<EOF
BOT_TOKEN=$BOT_TOKEN
SERVER_IP=$SERVER_IP
PROXY_PORT=$PROXY_PORT
EOF

    chmod 600 "$ENV_FILE"
fi

echo "== Запуск бота =="
python bot.py

