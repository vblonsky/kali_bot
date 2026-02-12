import aiosqlite
from db import log

async def is_admin(user_id):
    async with aiosqlite.connect("bot.db") as db:
        async with db.execute("SELECT 1 FROM admins WHERE telegram_id=?", (user_id,)) as cur:
            return await cur.fetchone() is not None


async def add_admin(actor_id, new_admin_id):
    async with aiosqlite.connect("bot.db") as db:
        await db.execute("INSERT OR IGNORE INTO admins VALUES(?)", (new_admin_id,))
        await db.commit()
    await log(actor_id, "NewAdmin", new_admin_id)


async def clear_users(actor_id):
    async with aiosqlite.connect("bot.db") as db:
        await db.execute("UPDATE users SET login=NULL")
        await db.commit()
    await log(actor_id, "UClean")
