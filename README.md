# entregable-3-ci-cd

Taller Entregable 3 del curso de CI/CD: despliegue continuo de la calculadora web en Flask a Azure Container Apps, con ambientes de Staging y Producción creados con Terraform y desplegados desde GitHub Actions.

## Integrantes

Texto usado en `AUTOR` (`app/calculadora.py`): **John Jimenez**

| Nombre completo | Usuario de GitHub | Rol |
|---|---|---|
| John Jimenez | [@Johnjmz13](https://github.com/Johnjmz13) | Propietario del repositorio |

Modalidad: individual.

## Cómo ejecutar

```bash
python -m venv venv
venv\Scripts\activate          # Windows
pip install -r requirements-dev.txt

python -m app.app              # http://localhost:5000 y http://localhost:5000/health

# Pruebas unitarias y de componente (cobertura mínima 80%)
pytest --ignore=tests/test_acceptance_app.py --ignore=tests/test_smoke_app.py --cov-fail-under=80

# Pruebas de aceptación (con la app en ejecución)
pytest tests/test_acceptance_app.py --no-cov --html=acceptance-report.html
```
