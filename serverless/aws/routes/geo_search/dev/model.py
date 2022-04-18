import os
import psycopg2
from psycopg2.extras import RealDictCursor
from . import queries
from .libs.services import converters
from .libs.helper_classes.other_classes.item import Item
from .libs.helper_classes.request_classes.geo_search_request import GeoSearchRequest

PSQL_CONNECT_STR = os.environ.get('PSQL_CONNECT_STR')


def execute(sql, params=()):
    print('Query: ', sql)
    print(PSQL_CONNECT_STR)
    connection = psycopg2.connect(
        PSQL_CONNECT_STR, cursor_factory=RealDictCursor)
    cursor = connection.cursor()
    cursor.execute(sql, params)
    connection.commit()
    try:
        return cursor.fetchall()
    except:
        return []


def get_cutoff_constrained_results(result_IDs: list, request: GeoSearchRequest, specific_id: str = False,
                                   search_employment: bool = False, search_volunteer: bool = False, search_community_services: bool = True):
    if specific_id:
        results = execute(queries.get_constrained_results_1.format(request.lat, request.lng) + str(
            result_IDs[0]) + queries.get_constrained_results_2.format(request.lat, request.lng, request.distance, result_IDs))
        total_results = 1
        items = [Item.from_db_row(i) for i in results]
        return {'items': items, 'totalResults': total_results}

    result_IDs = ', '.join(result_IDs)

    inclusion_filter = converters.build_inclusion_filter(
        search_employment, search_volunteer, search_community_services)

    query_results = execute(queries.get_cutoff_constrained_results_1.format(request.lat, request.lng) +
                            result_IDs + (queries.get_cutoff_constrained_results_2 + inclusion_filter + queries.get_cutoff_constrained_results_3).format(request.lat, request.lng, request.distance))

    total_results = len(query_results)

    if not request.page:
        request.page = 1
    else:
        request.page = max(request.page, 1)

    size = request.size
    query_results = query_results[request.page*size-size:request.page*size]

    items = []
    sort_order = 1
    for query_result in query_results:
        items.append(Item.from_db_row(query_result))
        items[-1].sortOrder = sort_order
        sort_order += 1

    return {'items': items, 'totalResults': total_results}


def get_constrained_results(request: GeoSearchRequest, result_IDs: list, specific_id: str = False,
                            search_employment=False, search_volunteer=False, search_community_services=True):
    if specific_id:
        result_IDs.remove(specific_id)
        result_IDs = [specific_id] + result_IDs
    result_IDs = ', '.join(result_IDs)
    inclusion_filter = converters.build_inclusion_filter(
        search_employment, search_volunteer, search_community_services)

    query_results = execute(queries.get_constrained_results_1.format(request.lat, request.lng) +
                            result_IDs + queries.get_constrained_results_2.format(request.lat, request.lng, request.distance, result_IDs) +
                            inclusion_filter + queries.get_constrained_results_3.format(result_IDs))
    total_results = len(query_results)
    if not request.page:
        request.page = 1
    else:
        request.page = max(request.page, 1)

    size = request.size
    query_results = query_results[request.page*size-size:request.page*size]

    items = []
    sort_order = 1
    for query_result in query_results:
        items.append(Item.from_db_row(query_result))
        items[-1].sortOrder = sort_order
        sort_order += 1

    return {'items': items, 'totalResults': total_results}
