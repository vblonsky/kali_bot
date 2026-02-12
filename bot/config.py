import os
from dotenv import load_dotenv

load_dotenv()

BOT_TOKEN = os.getenv("BOT_TOKEN")
SERVER_IP = os.getenv("SERVER_IP")
PROXY_PORT = int(os.getenv("PROXY_PORT", 3128))

LINUX_USERS = [f"u{i}" for i in range(1, 16)]
PASSWORD_LENGTH = 8

if not BOT_TOKEN:
    raise ValueError("BOT_TOKEN not set in .env")

if not SERVER_IP:
    raise ValueError("SERVER_IP not set in .env")

