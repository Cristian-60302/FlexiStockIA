
from google import genai

# Cada integrante debe configurar su propia API KEY
API_KEY = "Contraseña"

MODELO = "gemini-3.5-flash-lite"

client = genai.Client(
    api_key=API_KEY,
    http_options={"timeout": 20000}
)
