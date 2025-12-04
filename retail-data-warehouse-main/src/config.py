import os
from dataclasses import dataclass

@dataclass
class DatabaseConfig:
    host: str = "localhost"
    port: int = 5432
    database: str = "data_warehouse"
    user: str = "etl_user"
    password: str = "etl_password"

@dataclass
class ProjectConfig:
    raw_data_dir: str = "data/raw"
    backup_dir: str = "data/backup"
    processed_dir: str = "data/processed"

def get_db_connection_string():
    config = DatabaseConfig()
    return f"postgresql://{config.user}:{config.password}@{config.host}:{config.port}/{config.database}"