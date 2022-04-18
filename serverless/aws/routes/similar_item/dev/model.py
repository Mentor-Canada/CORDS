import os
import psycopg2
from psycopg2.extras import RealDictCursor
from . import queries

PSQL_CONNECT_STR = os.environ.get('PSQL_CONNECT_STR')


def execute(sql, params=()):
    connection = psycopg2.connect(
        PSQL_CONNECT_STR, cursor_factory=RealDictCursor)
    cursor = connection.cursor()
    cursor.execute(sql, params)
    connection.commit()
    try:
        return cursor.fetchall()
    except:
        return []


def get_description_from_ID(item_id):
    item = execute(queries.get_item_by_id, (clean_text(item_id),))
    if len(item):
        item = item[0]
        text = (item['resource_description'] or '') + ' ' + \
            (item['public_name'] or '') + ' ' + \
            (item['nom_publique'] or '') + ' ' + \
            (item['description_francais'] or '')
        return text


def clean_text(text):
    cleaned_text = ''
    ok_chars = set(
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890-')
    for char in text:
        if char in ok_chars:
            cleaned_text += char
    return cleaned_text
