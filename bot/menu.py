from aiogram.types import ReplyKeyboardMarkup, KeyboardButton

def main_menu(is_admin=False, has_login=False):
    buttons = [[KeyboardButton(text="Доступ к серверу Kali")]]

    if has_login:
        buttons.append([KeyboardButton(text="Сброс пароля")])

    if is_admin:
        buttons.append([KeyboardButton(text="Очистка пользователей")])
        buttons.append([KeyboardButton(text="Добавить администратора")])
        buttons.append([KeyboardButton(text="Просмотр журналов")])

    return ReplyKeyboardMarkup(
        keyboard=buttons,
        resize_keyboard=True
    )
