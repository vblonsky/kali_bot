from aiogram.fsm.state import StatesGroup, State

class Quest(StatesGroup):
    name = State()
    source = State()
    first_time = State()
