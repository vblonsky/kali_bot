#!/bin/bash
set -e

SERVICE_NAME="kali-telegram-bot"
BOT_USER="tgbot"
INSTALL_DIR="/opt/kali_bot"
CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ "$EUID" -ne 0 ]; then
  echo "Запустите через sudo"
  exit 1
fi

read -p "Введите BOT_TOKEN: " BOT_TOKEN
read -p "Введите IP сервера (например 192.168.0.10): " SERVER_IP
read -p "Введите Telegram ID первого администратора: " ADMIN_ID

apt update
apt install -y python3 python3-venv python3-pip sqlite3

if ! id "$BOT_USER" &>/dev/null; then
    useradd -m -s /bin/bash $BOT_USER
fi

mkdir -p $INSTALL_DIR
cp -r $CURRENT_DIR/* $INSTALL_DIR

# Создание .env
cat > $INSTALL_DIR/.env <<EOF
BOT_TOKEN=$BOT_TOKEN
SERVER_IP=$SERVER_IP
PROXY_PORT=3128
EOF

chown -R $BOT_USER:$BOT_USER $INSTALL_DIR
chmod 600 $INSTALL_DIR/.env

sudo -u $BOT_USER python3 -m venv $INSTALL_DIR/venv
sudo -u $BOT_USER $INSTALL_DIR/venv/bin/pip install --upgrade pip
sudo -u $BOT_USER $INSTALL_DIR/venv/bin/pip install aiogram aiosqlite python-dotenv

# Инициализация БД
sudo -u $BOT_USER $INSTALL_DIR/venv/bin/python - <<EOF
import asyncio
from db import init_db
asyncio.run(init_db())
EOF

sqlite3 $INSTALL_DIR/bot.db \
"INSERT OR IGNORE INTO admins VALUES ($ADMIN_ID);"

echo "$BOT_USER ALL=(ALL) NOPASSWD: /usr/sbin/chpasswd" > /etc/sudoers.d/$BOT_USER-chpasswd
chmod 440 /etc/sudoers.d/$BOT_USER-chpasswd

cat > /etc/systemd/system/$SERVICE_NAME.service <<EOF
[Unit]
Description=Kali Telegram Bot
After=network.target

[Service]
User=$BOT_USER
WorkingDirectory=$INSTALL_DIR
EnvironmentFile=$INSTALL_DIR/.env
ExecStart=$INSTALL_DIR/venv/bin/python bot.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable $SERVICE_NAME
systemctl restart $SERVICE_NAME

echo "Установка завершена."
systemctl status $SERVICE_NAME --no-pager

