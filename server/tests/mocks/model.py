def get_results(ignored, ignored2, size, one, two, three):
    return {'items':['get_results'] * size, 'totalResults': 50}


def get_constrained_results(a, b, specific):
    return {'items': ['get_constrained_results'] * 10, 'totalResults': 10}


def get_description_from_ID(ignored):
    return 'get_description_from_ID'


def clean_text(echo):
    return echo


def get_vector_from_ID(item):
    []