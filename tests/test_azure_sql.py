import os
from datetime import datetime
from decimal import Decimal
from unittest import TestCase
from unittest.mock import MagicMock, patch

from src import database, reviews_api, setup_db, tools


def connection_with_cursor():
    connection = MagicMock()
    cursor = connection.__enter__.return_value.cursor.return_value.__enter__.return_value
    return connection, cursor


class AzureSQLTest(TestCase):
    def test_local_windows_connection_supports_instances_and_ports_without_entra(self):
        for server in ("localhost", r"localhost\SQLEXPRESS", "localhost,1433", "tcp:localhost,1433"):
            with self.subTest(server=server), patch.dict(
                os.environ,
                {
                    "SQL_SERVER": server,
                    "SQL_DATABASE": "ShoppingDB",
                    "SQL_AUTH_MODE": "windows_integrated",
                    "SQL_TRUST_SERVER_CERTIFICATE": "yes",
                },
                clear=True,
            ), patch("src.database._credential") as credential, patch(
                "src.database.mssql_python.connect"
            ) as connect:
                database.connect()
                connect.assert_called_once_with(
                    f"Server={server};Database=ShoppingDB;Encrypt=yes;TrustServerCertificate=yes;"
                    "Trusted_Connection=yes;",
                    timeout=15,
                )
                credential.assert_not_called()

    def test_certificate_validation_defaults_on_for_local_and_cloud(self):
        for mode in ("windows_integrated", "azure_cli", "managed_identity"):
            with self.subTest(mode=mode), patch.dict(
                os.environ,
                {"SQL_SERVER": "localhost", "SQL_DATABASE": "shopping", "SQL_AUTH_MODE": mode},
                clear=True,
            ), patch("src.database._credential"), patch("src.database.mssql_python.connect") as connect:
                database.connect()
                self.assertIn("Encrypt=yes;TrustServerCertificate=no;", connect.call_args.args[0])

    def test_unsafe_or_invalid_settings_fail_before_connect(self):
        settings = [
            {"SQL_AUTH_MODE": "unknown"},
            {"SQL_AUTH_MODE": "azure_cli", "SQL_TRUST_SERVER_CERTIFICATE": "yes"},
            {"SQL_AUTH_MODE": "managed_identity", "SQL_TRUST_SERVER_CERTIFICATE": "yes"},
            {"SQL_AUTH_MODE": "windows_integrated", "SQL_TRUST_SERVER_CERTIFICATE": "invalid"},
            {"SQL_AUTH_MODE": "windows_integrated", "SQL_SERVER": "localhost;Encrypt=no"},
            {"SQL_AUTH_MODE": "windows_integrated", "SQL_DATABASE": "shopping;Encrypt=no"},
        ]
        for overrides in settings:
            with self.subTest(settings=overrides), patch.dict(
                os.environ, {"SQL_SERVER": "localhost", "SQL_DATABASE": "shopping", **overrides}, clear=True
            ), patch("src.database.mssql_python.connect") as connect:
                with self.assertRaises(ValueError):
                    database.connect()
                connect.assert_not_called()

    def test_connection_uses_selected_credential_and_validated_configuration(self):
        credential = object()
        with patch.dict(
            os.environ,
            {"SQL_SERVER": "example.database.windows.net", "SQL_DATABASE": "shopping", "SQL_AUTH_MODE": "azure_cli"},
            clear=True,
        ), patch("src.database._credential", return_value=credential), patch(
            "src.database.mssql_python.connect"
        ) as connect:
            database.connect()
        args, kwargs = connect.call_args
        self.assertIn("Server=example.database.windows.net;Database=shopping;", args[0])
        self.assertIn("Encrypt=yes;TrustServerCertificate=no;", args[0])
        self.assertIs(kwargs["token_provider"], credential)

    def test_missing_or_invalid_configuration_fails_before_connect(self):
        with patch.dict(os.environ, {"SQL_SERVER": "invalid;server", "SQL_DATABASE": "shopping"}, clear=True):
            with patch("src.database.mssql_python.connect") as connect:
                with self.assertRaisesRegex(ValueError, "SQL_SERVER"):
                    database.connect()
                connect.assert_not_called()

    def test_search_preserves_filters_and_rating_order(self):
        conn, cursor = connection_with_cursor()
        cursor.description = [(name,) for name in ("id", "name", "category", "price", "description", "is_organic")]
        cursor.fetchall.return_value = [
            (1, "Organic Honey", "honey", Decimal("14.99"), "honey", True),
            (2, "Organic Honey 2", "honey", Decimal("19.99"), "honey", True),
        ]
        ratings = [
            {"product_id": 1, "average_rating": 4.5, "review_count": 2},
            {"product_id": 2, "average_rating": 4.8, "review_count": 3},
        ]
        with patch("src.tools.connect", return_value=conn), patch(
            "src.tools.get_ratings_for_products", return_value=ratings
        ):
            result = tools.search_products.invoke(
                {"keyword": "HONEY", "max_price": 20, "organic_only": True, "min_rating": 4.6}
            )
        self.assertEqual([product["id"] for product in result], [2])
        self.assertEqual(result[0]["price"], 19.99)
        sql, *params = cursor.execute.call_args.args
        self.assertIn("LOWER(name) LIKE LOWER(?)", sql)
        self.assertEqual(params, ["%HONEY%", "%HONEY%", 20.0])

    def test_order_returns_json_safe_values_and_handles_missing_product(self):
        conn, cursor = connection_with_cursor()
        cursor.fetchone.return_value = (7, 3, "Honey", Decimal("29.99"), datetime(2026, 1, 2, 3, 4))
        with patch("src.tools.connect", return_value=conn):
            order = tools.place_order.invoke({"product_id": 3})
        self.assertEqual(order["order"]["price"], 29.99)
        self.assertEqual(order["order"]["ordered_at"], "2026-01-02T03:04:00")
        self.assertIn("OUTPUT INSERTED.id", cursor.execute.call_args.args[0])
        cursor.fetchone.return_value = None
        with patch("src.tools.connect", return_value=conn):
            result = tools.place_order.invoke({"product_id": 99})
        self.assertFalse(result["success"])

    def test_ratings_include_unreviewed_products(self):
        conn, cursor = connection_with_cursor()
        cursor.fetchall.return_value = [(1, 4.625, 4)]
        with patch("src.reviews_api.connect", return_value=conn):
            ratings = reviews_api.get_ratings_for_products([1, 2])
        self.assertEqual(ratings[1], {"product_id": 2, "average_rating": 0.0, "review_count": 0})
        self.assertEqual(cursor.execute.call_args.args[1:], (1, 2))
        self.assertEqual(reviews_api.get_ratings_for_products([]), [])

    def test_seed_refuses_existing_data(self):
        cursor = MagicMock()
        cursor.fetchone.side_effect = [(0,), (0,), (1,)]
        with self.assertRaisesRegex(RuntimeError, "requires empty"):
            setup_db.seed_catalog(cursor)
        cursor.executemany.assert_not_called()

    def test_seed_populates_only_empty_database(self):
        cursor = MagicMock()
        cursor.fetchone.return_value = (0,)
        setup_db.seed_catalog(cursor)
        self.assertEqual(cursor.executemany.call_count, 2)
        self.assertEqual(len(cursor.executemany.call_args_list[0].args[1]), 32)
