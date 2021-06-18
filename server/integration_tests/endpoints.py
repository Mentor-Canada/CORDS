"These tests are not tests yet but they print the outputs and that's nice."

import requests

SERVER = 'http://localhost:8000'
# SERVER = 'http://51.222.139.147'
# SERVER = 'https://server.cordsconnect.ca'


sample_element = None

def test_search():
    response = requests.post(SERVER + '/search', json={
        'query': 'i need clothes for an interview'
    })
    data = response.json()
    assert len(data['items']) == 10
    global sample_element
    sample_element = data['items'][0]['item_id']


def test_similar():
    response = requests.get(SERVER + '/similar/' + sample_element)
    data = response.json()
    assert len(data['items']) == 10


def test_geo_similar():
    response = requests.post(SERVER + '/similar', json={
        'item_id': sample_element,
        'lat': 44.2312,
        'lng': -79.486,
        'distance': 150
    })
    data = response.json()
    assert len(data['items']) <= 10
    assert data['items'][0]['item_id'] == sample_element


def test_geo_search():
    response = requests.post(SERVER + '/geosearch', json={
        'query': 'bread',
        'lat': 44.5017,
        'lng': -79.5673,
        # 'distance': 50
    })
    data = response.json()
    assert len(data['items']) == 10


def test_geo_search_pages():
    response = requests.post(SERVER + '/geosearch', json={
        'query': 'bread',
        'lat': 44.5017,
        'lng': -79.5673,
        'page': 1
    })
    data = response.json()
    assert len(data['items']) == 10
    item_1 = data['items'][0]['item_id']
    response = requests.post(SERVER + '/geosearch', json={
        'query': 'bread',
        'lat': 44.5017,
        'lng': -79.5673,
        'page': 2
    })
    data = response.json()
    assert item_1 != data['items'][0]['item_id']


test_search()
test_similar()
test_geo_similar()
test_geo_search()
test_geo_search_pages()
