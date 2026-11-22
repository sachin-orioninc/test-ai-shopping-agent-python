"""Connections to local SQL Server or Azure SQL with explicit authentication."""

import os
import re
from functools import lru_cache

import mssql_python
from azure.identity import AzureCliCredential, ManagedIdentityCredential
from dotenv import load_dotenv

load_dotenv()


@lru_cache(maxsize=1)
def _credential():
    mode = os.getenv("SQL_AUTH_MODE", "managed_identity")
    if mode == "managed_identity":
        return ManagedIdentityCredential(client_id=os.getenv("AZURE_CLIENT_ID") or None)
    if mode == "azure_cli":
        return AzureCliCredential()
    raise ValueError("SQL_AUTH_MODE must be 'managed_identity' or 'azure_cli'.")


def connect():
    mode = os.getenv("SQL_AUTH_MODE", "managed_identity")
    if mode not in ("windows_integrated", "managed_identity", "azure_cli"):
        raise ValueError("SQL_AUTH_MODE must be 'windows_integrated', 'managed_identity', or 'azure_cli'.")
    server = os.environ.get("SQL_SERVER", "")
    database = os.environ.get("SQL_DATABASE", "")
    server_pattern = (
        r"(?:tcp:)?[A-Za-z0-9][A-Za-z0-9.-]*(?:\\[A-Za-z0-9_-]+)?(?:,[0-9]{1,5})?"
        if mode == "windows_integrated"
        else r"[A-Za-z0-9][A-Za-z0-9.-]*"
    )
    if not re.fullmatch(server_pattern, server):
        raise ValueError("SQL_SERVER must be a valid SQL Server hostname, instance, or endpoint for SQL_AUTH_MODE.")
    if not database or any(char in database for char in ";{}\r\n"):
        raise ValueError("SQL_DATABASE must be set to a valid database name.")
    trust_certificate = os.getenv("SQL_TRUST_SERVER_CERTIFICATE", "no").lower()
    if trust_certificate not in ("yes", "no"):
        raise ValueError("SQL_TRUST_SERVER_CERTIFICATE must be 'yes' or 'no'.")
    if mode != "windows_integrated" and trust_certificate == "yes":
        raise ValueError(
            f"SQL_TRUST_SERVER_CERTIFICATE=yes requires SQL_AUTH_MODE=windows_integrated; "
            f"effective SQL_AUTH_MODE is {mode!r}. Shell environment variables override .env. "
            "For Azure, set SQL_TRUST_SERVER_CERTIFICATE=no instead."
        )
    connection_string = (
        f"Server={server};Database={database};Encrypt=yes;TrustServerCertificate={trust_certificate};"
    )
    if mode == "windows_integrated":
        return mssql_python.connect(connection_string + "Trusted_Connection=yes;", timeout=15)
    return mssql_python.connect(
        connection_string,
        token_provider=_credential(),
        timeout=15,
    )
