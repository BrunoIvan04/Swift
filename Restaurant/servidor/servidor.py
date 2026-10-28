#!/usr/bin/env python3
"""Servidor de prueba para el proyecto guiado Restaurant.

Responde igual que la app OpenRestaurant del libro "Develop in Swift Data
Collections", en http://localhost:8080:

  GET  /categories             -> {"categories": [...]}
  GET  /menu?category=entradas -> {"items": [...]}
  POST /order {"menuIds": [..]} -> {"preparation_time": minutos}
  GET  /images/<id>.png        -> foto del platillo

Solo usa la biblioteca estándar de Python, así que corre en cualquier Mac.
"""
import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs

HERE = os.path.dirname(os.path.abspath(__file__))
PORT = 8080
BASE = f"http://localhost:{PORT}"

with open(os.path.join(HERE, "menu.json"), encoding="utf-8") as f:
    MENU = json.load(f)
for item in MENU:
    item["image_url"] = f"{BASE}/images/{item['id']}.png"

CATEGORIES = []
for item in MENU:
    if item["category"] not in CATEGORIES:
        CATEGORIES.append(item["category"])


class Handler(BaseHTTPRequestHandler):

    def send_json(self, status, payload):
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        url = urlparse(self.path)
        if url.path == "/categories":
            self.send_json(200, {"categories": CATEGORIES})
        elif url.path == "/menu":
            category = parse_qs(url.query).get("category", [None])[0]
            items = [i for i in MENU if category is None or i["category"] == category]
            self.send_json(200, {"items": items})
        elif url.path.startswith("/images/"):
            path = os.path.join(HERE, "images", os.path.basename(url.path))
            if not os.path.exists(path):
                self.send_json(404, {"error": "imagen no encontrada"})
                return
            with open(path, "rb") as f:
                data = f.read()
            self.send_response(200)
            self.send_header("Content-Type", "image/png")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        else:
            self.send_json(404, {"error": "ruta no encontrada"})

    def do_POST(self):
        if urlparse(self.path).path != "/order":
            self.send_json(404, {"error": "ruta no encontrada"})
            return
        length = int(self.headers.get("Content-Length", 0))
        try:
            body = json.loads(self.rfile.read(length) or b"{}")
            ids = body["menuIds"]
        except (ValueError, KeyError):
            self.send_json(400, {"error": "se esperaba {\"menuIds\": [...]}"})
            return
        times = [i["estimated_prep_time"] for i in MENU if i["id"] in ids]
        if not times:
            self.send_json(400, {"error": "la orden está vacía"})
            return
        self.log_message("Orden recibida: %s", ids)
        self.send_json(200, {"preparation_time": sum(times)})


if __name__ == "__main__":
    print(f"Servidor del restaurante en {BASE}")
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
