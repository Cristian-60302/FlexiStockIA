import os
from dotenv import load_dotenv
from google import genai

# Carga las variables desde el archivo .env local
load_dotenv()

API_KEY = os.getenv("GEMINI_API_KEY")

if not API_KEY:
    raise RuntimeError(
        "Falta la variable GEMINI_API_KEY en el archivo .env del backend."
    )

MODELO = "gemini-3.5-flash-lite"

client = genai.Client(
    api_key=API_KEY,
    http_options={"timeout": 20000}
)