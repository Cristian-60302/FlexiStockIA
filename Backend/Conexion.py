
from google import genai
import os

API_KEY = "PEGA_AQUI_TU_API_KEY"

client = genai.Client(
    api_key=API_KEY,
    http_options={"timeout": 10000}
)

print("Probando conexión...", flush=True)

try:
    respuesta = client.models.generate_content(
        model="gemini-3.5-flash-lite",
        contents="Responde solamente: CONECTADO"
    )

    print("RESPUESTA:", respuesta.text)

except Exception as e:
    print("TIPO DE ERROR:", type(e).__name__)
    print("DETALLE:", str(e))

print("Prueba finalizada.")
