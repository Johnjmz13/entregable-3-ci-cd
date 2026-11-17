# tests/test_app.py
import re

import pytest
from app.app import app


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


# La app usa protección CSRF: antes de cada POST se carga el formulario (GET)
# para obtener el token, igual que haría el navegador.
def post_form(client, data):
    html = client.get("/").get_data(as_text=True)
    token = re.search(r'name="csrf_token" value="([^"]+)"', html).group(1)
    return client.post("/", data={**data, "csrf_token": token})


def test_index_get(client):
    response = client.get("/")
    assert response.status_code == 200
    assert b"<!DOCTYPE html>" in response.data


def test_index_post_sumar(client):
    response = post_form(client, {"num1": "2", "num2": "3", "operacion": "sumar"})
    assert response.status_code == 200
    assert b"Resultado: 5.0" in response.data


def test_index_post_restar(client):
    response = post_form(client, {"num1": "5", "num2": "3", "operacion": "restar"})
    assert response.status_code == 200
    assert b"Resultado: 2.0" in response.data


def test_index_post_multiplicar(client):
    response = post_form(
        client, {"num1": "2", "num2": "3", "operacion": "multiplicar"}
    )
    assert response.status_code == 200
    assert b"Resultado: 6.0" in response.data


def test_index_post_dividir(client):
    response = post_form(client, {"num1": "6", "num2": "3", "operacion": "dividir"})
    assert response.status_code == 200
    assert b"Resultado: 2.0" in response.data


def test_index_post_dividir_by_zero(client):
    response = post_form(client, {"num1": "6", "num2": "0", "operacion": "dividir"})
    assert response.status_code == 200
    assert b"Error: No se puede dividir por cero" in response.data


def test_index_post_invalid_operation(client):
    response = post_form(client, {"num1": "6", "num2": "3", "operacion": "invalid"})
    assert response.status_code == 200
    assert b"Operaci\xc3\xb3n no v\xc3\xa1lida" in response.data


def test_index_post_invalid_numbers(client):
    response = post_form(client, {"num1": "a", "num2": "b", "operacion": "sumar"})
    assert response.status_code == 200
    assert b"Error: Introduce n\xc3\xbameros v\xc3\xa1lidos" in response.data


def test_index_post_sin_token_csrf(client):
    response = client.post("/", data={"num1": "2", "num2": "3", "operacion": "sumar"})
    assert response.status_code == 400


def test_health(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.get_json() == {"status": "ok", "version": "local"}
