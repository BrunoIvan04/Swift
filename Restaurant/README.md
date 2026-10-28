# Proyecto guiado: Restaurant

Proyecto guiado de la unidad "Working with the Web" del libro *Develop in Swift Data Collections* de Apple, hecho para la Fase III del certificado de Aplicaciones Móviles.

La app muestra el menú de un restaurante por categorías, el detalle de cada platillo con su foto, una pestaña con la orden y la confirmación con el tiempo de preparación. Todos los datos llegan de un servidor:

| Petición | Respuesta |
|---|---|
| `GET /categories` | `{"categories": [...]}` |
| `GET /menu?category=...` | `{"items": [...]}` |
| `POST /order` con `{"menuIds": [...]}` | `{"preparation_time": minutos}` |
| `GET /images/<id>.png` | foto del platillo |

## Cómo correrlo

1. Iniciar el servidor de prueba (hace lo mismo que la app OpenRestaurant del libro): `python3 Restaurant/servidor/servidor.py`
2. Abrir `Restaurant/Restaurant.xcodeproj` en Xcode y correr en el simulador.

La interfaz está hecha por código en lugar de storyboard, pero las clases y la lógica siguen el libro: `MenuController` (singleton con URLSession y async/await), los modelos `Codable` con `CodingKeys`, `MenuItemCell` con `UIContentConfiguration` y el globito de la pestaña con `NotificationCenter`.

Como no tengo Mac, GitHub Actions (`.github/workflows/restaurant.yml`) levanta el servidor, corre la prueba de interfaz y guarda las capturas en [`evidencias/`](evidencias/).
