# AI Shopping Agent

Chat to search a grocery catalog ("find me organic honey under $20 with 4.5+ rating") and place orders. Built with LangChain, Streamlit, and Google's Gemini 2.5 Flash-Lite (`gemini-2.5-flash-lite`).

## Run

1. Create a `.env` file in the project root and add `GOOGLE_API_KEY=your-google-api-key`.
2. `uv sync`
3. `uv run streamlit run app.py`

The SQLite database (`resources/store.db`) is created automatically on first run, or manually with `uv run python -m src.setup_db`. Orders are inserted into the `orders` table.

## Azure App Service Builder (preview)

Use the repository root as the source root. Commit and push [builder.yaml](./builder.yaml) to the branch configured in Builder, then deploy that revision. Supply `GOOGLE_API_KEY` through Builder's app configuration, not in the repository or manifest. Builder's manual variables are visible to both the build and runtime.

After deployment, try a chat message in the browser; the health check only verifies that Streamlit responds over HTTP, not that its WebSocket or Gemini connection works. Builder uses temporary SQLite storage for this demo. Orders can be lost when an instance is replaced or restarted.
