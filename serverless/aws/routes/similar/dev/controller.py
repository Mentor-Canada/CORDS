from . import model
from .libs.helper_classes.request_classes.geo_similar_request import GeoSimilarRequest


def geo_similar_search(input_request):
    """Get similar services based on the item_id description and coordinates.
    Obtenez des services pareilles de la description d'une service et coordonees.
    """
    geo_similar_request = GeoSimilarRequest(item_id=input_request['item_id'],
                                            lat=input_request['lat'],
                                            lng=input_request['lng'],
                                            # distance=input_request['distance'],
                                            # page=input_request['page'],
                                            # size=input_request['size'],
                                            # cutoff=input_request['cutoff'],
                                            # community_services=input_request['community_services'],
                                            # employment=input_request['employment'],
                                            # volunteer=input_request['volunteer']
                                            )
                                            # distance=input_request.get('distance', 25),
                                            # page=input_request.get('page', 1),
                                            # size=input_request.get('size', None),
                                            # cutoff=input_request.get('cutoff', None),
                                            # community_services=input_request.get('community_services', None),
                                            # employment=input_request.get('employment', None),
                                            # volunteer=input_request.get('volunteer', None))
    result_IDs = ["'" + str(geo_similar_request.item_id) + "'"]
    results = model.get_constrained_results(geo_similar_request, result_IDs, result_IDs[0],
                    geo_similar_request.employment, geo_similar_request.volunteer, geo_similar_request.community_services)
    return {'status_code': 200, 'body': results}