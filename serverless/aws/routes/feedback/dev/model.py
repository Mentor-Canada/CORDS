import os
import psycopg2
from psycopg2.extras import RealDictCursor
from . import queries

PSQL_CONNECT_STR = os.environ.get('PSQL_CONNECT_STR')


def execute(sql, params=()):
    connection = psycopg2.connect(PSQL_CONNECT_STR, cursor_factory=RealDictCursor)
    cursor = connection.cursor()
    cursor.execute(sql, params)
    connection.commit()
    try:
        return cursor.fetchall()
    except:
        return []

def save_feedback(item):
    execute(queries.save_feedback, item)