import boto3
import json
from . import model
from .libs.services import converters
from .libs.helper_classes.request_classes.search_request import SearchRequest

lambda_client = boto3.client('lambda')


def get_similar(item_id):
    """(OBSOLETE) Get similar services based on the item_id description.
    Obtenez des services pareilles de la description d'une service.
    """
    # Get description from item ID, create a SearchRequest, then call search()
    text_vec = converters.convert2text(
        model.get_description_from_ID(item_id))
    text = converters.convert2text(text_vec)
    search_request = SearchRequest(
        query=text,
    )
    invoke_response = lambda_client.invoke(FunctionName='cords-dev-search',
                                           InvocationType='RequestResponse',
                                           Payload=search_request.json())
    results =  invoke_response['Payload'].read().decode()
    return {'status_code': 200, 'body': results}
