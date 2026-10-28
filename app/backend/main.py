import os
import socket
from contextlib import contextmanager
from typing import Iterator

import boto3
import psycopg
from botocore.exceptions import BotoCoreError, ClientError
from fastapi import FastAPI, HTTPException
from psycopg import Connection
from psycopg.rows import dict_row

TABLE_NAME = "app1_health_checks"


def required_environment(name: str) -> str:
    value = os.getenv(name)
    if not value:
        raise RuntimeError(f"Required environment variable {name} is not set")
    return value


def database_settings() -> dict[str, object]:
    auth_mode = os.getenv("DB_AUTH_MODE", "local").lower()
    if auth_mode not in {"local", "iam"}:
        raise RuntimeError("DB_AUTH_MODE must be either 'local' or 'iam'")

    host = required_environment("DB_HOST")
    port = int(os.getenv("DB_PORT", "5432"))
    user = required_environment("DB_USER")

    if auth_mode == "iam":
        region = required_environment("AWS_REGION")
        password = boto3.client("rds", region_name=region).generate_db_auth_token(
            DBHostname=host,
            Port=port,
            DBUsername=user,
        )
        sslmode = "require"
    else:
        password = required_environment("DB_PASSWORD")
        sslmode = "prefer"

    return {
        "host": host,
        "port": port,
        "dbname": required_environment("DB_NAME"),
        "user": user,
        "password": password,
        "sslmode": sslmode,
        "connect_timeout": 5,
        "row_factory": dict_row,
    }


@contextmanager
def database_connection() -> Iterator[Connection]:
    with psycopg.connect(**database_settings()) as connection:
        yield connection


def ensure_table(connection: Connection) -> None:
    with connection.cursor() as cursor:
        cursor.execute(
            f"""
            CREATE TABLE IF NOT EXISTS {TABLE_NAME} (
                id BIGSERIAL PRIMARY KEY,
                checked_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
            """
        )
    connection.commit()


def database_failure() -> HTTPException:
    return HTTPException(status_code=503, detail="Database connection failed")


app = FastAPI(title="App1 EKS Lab Backend", version="1.0.0")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "healthy", "hostname": socket.gethostname()}


@app.get("/db")
def database_status() -> dict[str, object]:
    try:
        with database_connection() as connection:
            ensure_table(connection)
            with connection.cursor() as cursor:
                cursor.execute(f"SELECT COUNT(*) AS check_count FROM {TABLE_NAME}")
                result = cursor.fetchone()
        return {"status": "connected", "check_count": result["check_count"]}
    except (BotoCoreError, ClientError, psycopg.Error, RuntimeError, ValueError):
        raise database_failure() from None


@app.post("/db/check")
def create_database_check() -> dict[str, object]:
    try:
        with database_connection() as connection:
            ensure_table(connection)
            with connection.cursor() as cursor:
                cursor.execute(
                    f"INSERT INTO {TABLE_NAME} DEFAULT VALUES RETURNING id, checked_at"
                )
                check = cursor.fetchone()
                cursor.execute(f"SELECT COUNT(*) AS check_count FROM {TABLE_NAME}")
                count = cursor.fetchone()
            connection.commit()
        return {
            "status": "connected",
            "check_id": check["id"],
            "checked_at": check["checked_at"],
            "check_count": count["check_count"],
        }
    except (BotoCoreError, ClientError, psycopg.Error, RuntimeError, ValueError):
        raise database_failure() from None
