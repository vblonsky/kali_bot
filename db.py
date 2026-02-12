import aiosqlite
from datetime import datetime

DB_NAME = "bot.db"

async def init_db():
    async with aiosqlite.connect(DB_NAME) as db:
        await db.execute("""
        CREATE TABLE IF NOT EXISTS users(
            telegram_id INTEGER PRIMARY KEY,
            name TEXT,
            source TEXT,
            first_time TEXT,
            login TEXT,
            quest_time TEXT
        )""")

        await db.execute("""
        CREATE TABLE IF NOT EXISTS admins(
            telegram_id INTEGER PRIMARY KEY
        )""")

        await db.execute("""
        CREATE TABLE IF NOT EXISTS logs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            actor_id INTEGER,
            target_id INTEGER,
            action_type TEXT,
            filter TEXT,
            timestamp TEXT
        )""")
        await db.commit()


async def log(actor_id, action_type, target_id=None, filter_value=None):
    async with aiosqlite.connect(DB_NAME) as db:
        await db.execute("""
        INSERT INTO logs(actor_id, target_id, action_type, filter, timestamp)
        VALUES (?, ?, ?, ?, ?)
        """, (actor_id, target_id, action_type, filter_value,
              datetime.now().strftime("%Y-%m-%d %H:%M:%S")))
        await db.commit()
