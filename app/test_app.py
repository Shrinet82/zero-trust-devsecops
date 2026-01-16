import pytest
from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_hello(client):
    """Test the root endpoint returns correct message."""
    rv = client.get('/')
    assert b"Zero-Trust Azure DevSecOps Pipeline is Live!" in rv.data
