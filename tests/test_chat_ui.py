import os
from pathlib import Path
from unittest import TestCase
from unittest.mock import Mock, patch

from langchain_core.messages import AIMessage
from streamlit.testing.v1 import AppTest


class ChatUITest(TestCase):
    def test_catalog_reply_is_displayed_as_markdown(self):
        markdown = (
            "Here is the catalog:\n\n"
            "| ID | Name | Price |\n"
            "| --- | --- | --- |\n"
            "| 3 | Organic Manuka Honey | $29.99 |"
        )
        reply = AIMessage(
            content=[
                {"type": "reasoning", "reasoning": "Internal notes"},
                {"type": "text", "text": markdown, "extras": {"signature": "test-metadata"}},
            ],
        )
        agent = Mock()
        agent.invoke.return_value = {"messages": [reply]}

        with patch.dict(os.environ, {"GOOGLE_API_KEY": "offline-placeholder"}), patch(
            "dotenv.load_dotenv", return_value=False
        ), patch("src.agent.build_agent", return_value=agent):
            app = AppTest.from_file(str(Path(__file__).resolve().parents[1] / "app.py")).run()
            app.chat_input[0].set_value("Show all the products").run()
            self.assertFalse(app.exception)
            self.assertEqual(app.chat_message[-1].markdown[0].value, markdown)

            app.run()
            self.assertFalse(app.exception)
            self.assertEqual(app.chat_message[-1].markdown[0].value, markdown)
            agent.invoke.assert_called_once()
