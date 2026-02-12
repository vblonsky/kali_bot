import asyncio
import aiosqlite
from aiogram import Bot, Dispatcher, F
from aiogram.types import Message
from aiogram.fsm.context import FSMContext
from config import BOT_TOKEN, SERVER_IP, PROXY_PORT
from db import init_db, log
from menu import main_menu
from questionnaire import Quest
from auth import generate_password, reset_linux_password, get_free_user
from admin import is_admin, add_admin, clear_users

bot = Bot(token=BOT_TOKEN)
dp = Dispatcher()


@dp.message(F.text == "/start")
async def start(message: Message):
    user_id = message.from_user.id
    admin_status = await is_admin(user_id)

    async with aiosqlite.connect("bot.db") as db:
        async with db.execute("SELECT login FROM users WHERE telegram_id=?", (user_id,)) as cur:
            row = await cur.fetchone()
            has_login = row and row[0]

    await message.answer("Добро пожаловать!",
                         reply_markup=main_menu(admin_status, has_login))


# ======= АНКЕТА =======

@dp.message(F.text == "Доступ к серверу Kali")
async def access_server(message: Message, state: FSMContext):
    user_id = message.from_user.id

    async with aiosqlite.connect("bot.db") as db:
        async with db.execute("SELECT quest_time FROM users WHERE telegram_id=?", (user_id,)) as cur:
            exists = await cur.fetchone()

    if not exists:
        await message.answer("Ваше имя?")
        await state.set_state(Quest.name)
    else:
        await assign_login(message)


@dp.message(Quest.name)
async def quest_name(message: Message, state: FSMContext):
    await state.update_data(name=message.text)
    await message.answer("Как узнали о мероприятии?")
    await state.set_state(Quest.source)


@dp.message(Quest.source)
async def quest_source(message: Message, state: FSMContext):
    await state.update_data(source=message.text)
    await message.answer("Вы в первый раз? (Да/Нет)")
    await state.set_state(Quest.first_time)


@dp.message(Quest.first_time)
async def quest_finish(message: Message, state: FSMContext):
    data = await state.get_data()
    user_id = message.from_user.id

    async with aiosqlite.connect("bot.db") as db:
        await db.execute("""
        INSERT OR REPLACE INTO users
        (telegram_id, name, source, first_time, quest_time)
        VALUES (?, ?, ?, ?, datetime('now'))
        """, (user_id, data["name"], data["source"], message.text))
        await db.commit()

    await log(user_id, "Quest")
    await state.clear()
    await assign_login(message)


# ======= НАЗНАЧЕНИЕ ЛОГИНА =======

async def assign_login(message):
    user_id = message.from_user.id

    async with aiosqlite.connect("bot.db") as db:
        login = await get_free_user(db)

        if not login:
            await message.answer("Свободных пользователей нет.")
            return

        password = generate_password()
        reset_linux_password(login, password)

        await db.execute("UPDATE users SET login=? WHERE telegram_id=?",
                         (login, user_id))
        await db.commit()

    await log(user_id, "Login")

    await message.answer(
        f"Логин: {login}\n"
        f"Пароль: {password}\n"
        f"IP: {SERVER_IP}\n"
        f"SSH: ssh {login}@{SERVER_IP}\n"
        f"Proxy: {SERVER_IP}:{PROXY_PORT}"
    )


# ======= СБРОС ПАРОЛЯ =======

@dp.message(F.text == "Сброс пароля")
async def reset_password(message: Message):
    user_id = message.from_user.id

    async with aiosqlite.connect("bot.db") as db:
        async with db.execute("SELECT login FROM users WHERE telegram_id=?", (user_id,)) as cur:
            row = await cur.fetchone()

        if not row or not row[0]:
            await message.answer("У вас нет назначенного логина.")
            return

        login = row[0]

    password = generate_password()
    reset_linux_password(login, password)

    await log(user_id, "Password")

    await message.answer(
        f"Логин: {login}\n"
        f"Пароль: {password}\n"
        f"IP: {SERVER_IP}\n"
        f"SSH: ssh {login}@{SERVER_IP}\n"
        f"Proxy: {SERVER_IP}:{PROXY_PORT}"
    )


# ======= ЗАПУСК =======

async def main():
    await init_db()
    await dp.start_polling(bot)

if __name__ == "__main__":
    asyncio.run(main())
