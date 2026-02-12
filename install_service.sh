#!/bin/bash
set -e

SERVICE_NAME="kali-telegram-bot"
BOT_USER="tgbot"
INSTALL_DIR="/opt/kali_bot"

if [ "$EUID" -ne 0 ]; then
  echo "Запустите через sudo"
  exit 1
fi

# Создаём пользователя для сервиса
if ! id "$BOT_USER" &>/dev/null; then
    useradd -m -s /bin/bash $BOT_USER
fi

mkdir -p $INSTALL_DIR
chown -R $BOT_USER:$BOT_USER $INSTALL_DIR

# Разрешаем sudo только для смены пароля
echo "$BOT_USER ALL=(ALL) NOPASSWD: /usr/sbin/chpasswd" > /etc/sudoers.d/$BOT_USER-chpasswd
chmod 440 /etc/sudoers.d/$BOT_USER-chpasswd

# systemd сервис
cat > /etc/systemd/system/$SERVICE_NAME.service <<EOF
[Unit]
Description=Kali Telegram Bot
After=network.target

[Service]
User=$BOT_USER
WorkingDirectory=$INSTALL_DIR
EnvironmentFile=$INSTALL_DIR/.env
ExecStart=$INSTALL_DIR/venv/bin/python $INSTALL_DIR/bot.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable $SERVICE_NAME
systemctl restart $SERVICE_NAME

echo "Сервис $SERVICE_NAME установлен и запущен."
systemctl status $SERVICE_NAME --no-pager

