import os
from dotenv import load_dotenv

load_dotenv()

class Settings:
    DB_USER = os.getenv("DB_USER", "your_db_user")
    DB_PASSWORD = os.getenv("DB_PASSWORD", "your_db_password")
    DB_HOST = os.getenv("DB_HOST", "localhost")
    DB_PORT = os.getenv("DB_PORT", "3306")
    DB_NAME = os.getenv("DB_NAME", "pillcare")
    DATABASE_URL = f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

settings = Settings() 