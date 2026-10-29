import pytest
from app import create_app
from app.models import db

@pytest.fixture
def client():
    app = create_app()
    app.config['TESTING'] = True
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'

    with app.test_client() as client:
        with app.app_context():
            db.create_all()
            yield client
            db.drop_all()

def test_health(client):
    response = client.get('/api/v1/health')
    assert response.status_code == 200
    assert response.get_json()['status'] == 'healthy'

def test_register_and_login(client):
    res = client.post('/api/v1/auth/register', json={
        "username": "testuser",
        "email": "test@example.com",
        "password": "securepassword123"
    })
    assert res.status_code == 201

    res = client.post('/api/v1/auth/login', json={
        "email": "test@example.com",
        "password": "securepassword123"
    })
    assert res.status_code == 200
    data = res.get_json()
    assert "access_token" in data

def test_analyze_scam(client):
    client.post('/api/v1/auth/register', json={
        "username": "testuser2",
        "email": "test2@example.com",
        "password": "securepassword123"
    })
    login_res = client.post('/api/v1/auth/login', json={
        "email": "test2@example.com",
        "password": "securepassword123"
    })
    token = login_res.get_json()["access_token"]

    res = client.post('/api/v1/analyze', 
        headers={"Authorization": f"Bearer {token}"},
        json={
            "channel": "sms",
            "content": "Your bank account is locked. Click http://secure-bank.example to verify OTP."
        }
    )
    assert res.status_code == 200
    data = res.get_json()
    assert data["incident"]["risk_level"] == "HIGH_RISK"