# AI Shopping Agent

Chat to search a grocery catalog and place orders. Built with LangChain, Streamlit, Gemini, and Azure SQL Database.

## Manual database setup

Users must create the database themselves, locally or in Azure, then manually run the schema setup command below. App startup, Docker builds, and Azure deployment do not create databases, create tables, or seed data. The app requires an existing, prepared database.

## Local SQL Server setup (Windows)

Create an empty `ShoppingDB` database on your local SQL Server and give your Windows account access. Database provisioning is separate; the setup command creates tables, not the database itself.

Set these variables locally in an uncommitted `.env` file:

```text
GOOGLE_API_KEY=your-google-api-key
SQL_SERVER=localhost
SQL_DATABASE=ShoppingDB
SQL_AUTH_MODE=windows_integrated
SQL_TRUST_SERVER_CERTIFICATE=yes
```

Use `localhost\SQLEXPRESS` for a named instance or `localhost,1433` for a TCP port, as appropriate. Windows integrated authentication uses the account running Python; it does not require `az login`. `SQL_TRUST_SERVER_CERTIFICATE=yes` permits a self-signed local certificate while keeping encryption enabled. Use it only for local development; it defaults to `no` and is rejected with either Azure authentication mode. Windows credentials are not automatically available inside the Linux Docker container.

Shell environment variables override `.env`. If a terminal still has Azure settings, explicitly select local settings in that PowerShell session:

```powershell
$env:SQL_SERVER = "localhost"
$env:SQL_DATABASE = "ShoppingDB"
$env:SQL_AUTH_MODE = "windows_integrated"
$env:SQL_TRUST_SERVER_CERTIFICATE = "yes"
```

Only specify `,1433` if SQL Server is actually listening on that TCP port.

Install dependencies with `uv sync`. After creating the database yourself, manually run the following once using an account authorized to create tables:

```powershell
uv run python -m src.setup_db --seed
```

Omit `--seed` to create only the tables. The seed contains sample products and reviews and refuses to run unless products, reviews, and orders are all empty. It does not import existing SQLite orders. Schema setup and seeding are not performed on app startup.

Start the app:

```powershell
uv run streamlit run app.py
```

## Manual Azure SQL setup

Create Azure SQL Database yourself and configure a Microsoft Entra administrator. Create database users for the account running the manual setup command and the app's managed identity. The runtime needs SELECT on products, reviews, and orders, and INSERT on orders; schema creation requires a separate, more privileged identity.

### Run the SQL script directly (no Python required)

Connect SSMS or Azure portal's database Query editor to the existing application database using an account authorized to create tables. Open [scripts/azure_sql_schema.sql](./scripts/azure_sql_schema.sql), or paste its contents into the editor, and execute the complete script.

The script creates `dbo.products`, `dbo.reviews`, and `dbo.orders` in a transaction. It can be rerun: existing tables and data are left unchanged. It matches the Python setup schema, does not create the database, and does not insert sample data. Run the identity permission statements below separately after creating the tables.

### Alternative: run the Python setup command manually

From the repository root on your laptop, manually run the following using an account authorized to create tables. Your laptop must have network access to Azure SQL:

```powershell
az login
$env:SQL_SERVER = "your-server.database.windows.net"
$env:SQL_DATABASE = "your-database"
$env:SQL_AUTH_MODE = "azure_cli"
$env:SQL_TRUST_SERVER_CERTIFICATE = "no"
uv run python -m src.setup_db
```

The same idempotent command creates missing tables in the configured cloud database without seeding or deleting existing data. Add `--seed` only if you want sample data and all three tables are empty. This is a manual operation, not an automated deployment step. Do not run it during image build or ordinary app startup. Do not deploy the local `.env`; process environment variables override its values. Azure SQL connections always require encryption and certificate validation. Use a separate terminal for local development so these Azure settings do not override your local configuration.

After creating the schema, an Azure SQL administrator can grant the managed identity access, substituting the identity's display name:

```sql
CREATE USER [app-identity-name] FROM EXTERNAL PROVIDER;
GRANT SELECT ON dbo.products TO [app-identity-name];
GRANT SELECT ON dbo.reviews TO [app-identity-name];
GRANT SELECT, INSERT ON dbo.orders TO [app-identity-name];
```

Configure the deployed app with the cloud `SQL_SERVER`, `SQL_DATABASE`, `SQL_AUTH_MODE=managed_identity`, and `SQL_TRUST_SERVER_CERTIFICATE=no`. Enable its managed identity and grant it only the runtime permissions described above; it does not need permission to create tables.

## Azure App Service Builder (preview)

Use the repository root as the source root. Commit and push [builder.yaml](./builder.yaml) and deploy that revision. Configure the cloud `SQL_SERVER`, `SQL_DATABASE`, `SQL_TRUST_SERVER_CERTIFICATE=no`, and `GOOGLE_API_KEY` in Builder; manual variables are shared by the build and runtime. `SQL_AUTH_MODE` defaults to `managed_identity`. Create the database and complete the manual Azure SQL setup above before using the app; Builder does not run database setup. Enable a system-assigned managed identity and create its database user; for a user-assigned identity, also set `AZURE_CLIENT_ID`. Grant the runtime identity only the database permissions it needs.

Builder does not provide private networking or a stable outbound IP. Verify that your Azure SQL network policy permits the intended connection without weakening security requirements. Its Azure SQL named-connection configuration does not by itself prove connectivity. Check the target has the Linux libraries required by `mssql-python` (`libltdl7`, `libkrb5-3`, and `libgssapi-krb5-2`) and verify an actual database read and order after deployment.

Streamlit development mode is disabled in the Builder startup command because the bundled `.deps` directory otherwise makes Streamlit reject the configured port. To allow Builder's public origin through the proxy, set `STREAMLIT_SERVER_CORS_ALLOWED_ORIGINS` to the exact public HTTPS origin. After deployment, test a chat message; the health check only verifies that Streamlit responds over HTTP.

See [Builder networking](https://builder.appservice.azure.com/docs/guides/networking/) and [Microsoft's Azure SQL Python guide](https://learn.microsoft.com/en-us/azure/azure-sql/database/azure-sql-python-quickstart).
