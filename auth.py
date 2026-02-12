import random
import string
import subprocess
from config import LINUX_USERS

def generate_password(length=8):
    chars = string.ascii_letters + string.digits
    return ''.join(random.choice(chars) for _ in range(length))


def reset_linux_password(username, password):
    subprocess.run(
        ["chpasswd"],
        input=f"{username}:{password}",
        text=True,
        check=True
    )


async def get_free_user(db):
    async with db.execute("SELECT login FROM users WHERE login IS NOT NULL") as cur:
        used = [row[0] async for row in cur]

    for u in LINUX_USERS:
        if u not in used:
            return u
    return None
