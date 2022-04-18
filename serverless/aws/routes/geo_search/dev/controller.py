from . import model
from .libs.services import external
from .libs.services.cutoff_filter import filter_indexes_by_cutoff
from .libs.helper_classes.request_classes.geo_search_request import GeoSearchRequest


def geo_search(input_request):
    """Return distance-constrained query."""
    geo_search_request = GeoSearchRequest(query=input_request['query'],
                                          lat=input_request['lat'],
                                          lng=input_request['lng'])
    # vector = get_vector(geo_search_request.query)
    import numpy as np
    vector = [np.random.uniform(-1, 1, 384).tolist()]
    result_IDs, distances = external.search_cache(vector=vector)

    # response = external.search_cache(vector)
    # distances = response['distances']
    # result_IDs = response['data']

    search_employment = geo_search_request.employment
    search_volunteer = geo_search_request.volunteer
    search_community_services = geo_search_request.community_services

    number_of_results = 5000
    if geo_search_request.cutoff is not None:
        result_IDs = filter_indexes_by_cutoff(
            result_IDs, distances, geo_search_request.cutoff, number_of_results)

    result_IDs = ["'" + str(geo_search_request.item_id) + "'"] + result_IDs

    if geo_search_request.cutoff is not None:
        results = model.get_cutoff_constrained_results(
            result_IDs, geo_search_request, search_employment, search_volunteer, search_community_services)
    else:
        results = model.get_constrained_results(
            geo_search_request, result_IDs, False, search_employment, search_volunteer, search_community_services)
    return {'status_code': 200, 'body': results}
