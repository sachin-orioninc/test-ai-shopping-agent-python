# AI Shopping Agent

Chat to search a grocery catalog ("find me organic honey under $20 with 4.5+ rating") and place orders. Built with LangChain, Streamlit, and Google's Gemini 2.5 Flash-Lite (`gemini-2.5-flash-lite`).

## Run

1. Create a `.env` file in the project root and add `GOOGLE_API_KEY=your-google-api-key`.
2. `uv sync`
3. `uv run streamlit run app.py`

The SQLite database (`resources/store.db`) is created automatically on first run, or manually with `uv run python -m src.setup_db`. Orders are inserted into the `orders` table.
