# AI Shopping Agent

Chat to search groceries and place orders. Built with Streamlit, LangChain, Gemini, and SQL Server / Azure SQL.

## 1. Prepare the database manually

Create a database yourself, locally or in Azure. Connect to it in SSMS or Azure Query editor with an account authorized to create tables, then run:

| Script | Purpose |
| --- | --- |
| [azure_sql_schema.sql](./scripts/azure_sql_schema.sql) | Create missing products, reviews, and orders tables; preserve existing data. |
| [azure_sql_seed.sql](./scripts/azure_sql_seed.sql) | Optional: insert 32 sample products and 102 reviews. All three tables must be empty. |

Neither app startup nor deployment creates the database, tables, or sample data.

## 2. Run locally (Windows)

Create `ShoppingDB` in your local SQL Server and give your Windows account access. Add an uncommitted `.env` file:

```text
GOOGLE_API_KEY=your-google-api-key
SQL_SERVER=localhost
SQL_DATABASE=ShoppingDB
SQL_AUTH_MODE=windows_integrated
SQL_TRUST_SERVER_CERTIFICATE=yes
```

Run from the repository root:

```powershell
uv sync
uv run streamlit run app.py
```

- Use `localhost\SQLEXPRESS` for a named instance; specify `,1433` only if SQL Server listens on that port.
- Certificate trust is for local development only. Windows authentication uses the account running Python, not `az login`, and is not automatically available inside Linux containers.
- Shell environment variables override `.env`; use a separate terminal for Azure commands.

**Python alternative to the SQL scripts:** after `uv sync`, run `uv run python -m src.setup_db --seed` manually. Omit `--seed` to create tables without sample data.

## 3. Deploy to Azure App Service Builder

1. Create Azure SQL Database, configure its Microsoft Entra administrator, and run the SQL scripts above.
2. Deploy from the repository root using [builder.yaml](./builder.yaml).
3. In Builder **Identity**, enable the system-assigned identity and choose **Save and deploy**.
4. Configure these Builder variables, then **Save and deploy**:

   | Variable | Value |
   | --- | --- |
   | `GOOGLE_API_KEY` | Your Gemini API key |
   | `SQL_SERVER` | `your-server.database.windows.net` |
   | `SQL_DATABASE` | Your Azure database name |
   | `SQL_AUTH_MODE` | `managed_identity` |
   | `SQL_TRUST_SERVER_CERTIFICATE` | `no` |
   | `STREAMLIT_SERVER_CORS_ALLOWED_ORIGINS` | Your exact public HTTPS app origin |

5. As the SQL Microsoft Entra administrator, connect to the **application database**, not `master`. Replace `app-identity-name` with the managed identity's Entra display name and run:

   ```sql
   CREATE USER [app-identity-name] FROM EXTERNAL PROVIDER;
   GRANT SELECT ON dbo.products TO [app-identity-name];
   GRANT SELECT ON dbo.reviews TO [app-identity-name];
   GRANT SELECT, INSERT ON dbo.orders TO [app-identity-name];
   ```

6. Verify a product search and an order in the deployed app; the HTTP health check does not verify SQL access.

**Identity selection:** leave `AZURE_CLIENT_ID` unset for system-assigned identity. For a user-assigned identity, attach it to the app and set `AZURE_CLIENT_ID` to its **client ID**, not its principal/object ID. Grant SQL access to that same identity.

**Deployment notes:** do not deploy your local `.env`. Builder preview is for development/test and has no VNet integration or stable outbound IP; ensure your SQL network policy supports access without disabling its protections. The Python SQL driver requires Linux libraries `libltdl7`, `libkrb5-3`, and `libgssapi-krb5-2`.

## Troubleshooting

| Error | Check |
| --- | --- |
| Local certificate is not trusted | Use `windows_integrated` and `SQL_TRUST_SERVER_CERTIFICATE=yes` locally; keep `no` on Azure. |
| Configuration differs from `.env` | Existing shell variables override the file. Check the terminal's SQL settings. |
| Managed identity configuration not found / `invalid_scope` | Enable or attach the identity, then **Save and deploy**. The driver already supplies SQL scope `https://database.windows.net/.default`; do not manually set identity endpoint/header variables. |
| Login failed for `'<token-identified principal>'` | Verify the target database and create/grant its user for the selected identity. An existing user must map to the current principal/object ID; Azure Owner/Contributor roles alone do not grant SQL access. |

References: [Builder identity](https://builder.appservice.azure.com/docs/guides/managed-identity/) · [Builder networking](https://builder.appservice.azure.com/docs/guides/networking/) · [Azure SQL Python guide](https://learn.microsoft.com/en-us/azure/azure-sql/database/azure-sql-python-quickstart).
