from .controller import geo_search
from .libs import aws_wrapper


def lambda_handler(event, context):
    """Lambda function invoking method for geosearch endpoint.
    """
    input_request = aws_wrapper.unpack(event)
    results = geo_search(input_request)
    print(results)
    return aws_wrapper.pack(results)
