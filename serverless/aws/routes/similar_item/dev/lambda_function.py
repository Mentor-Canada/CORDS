from .controller import get_similar
from .libs import aws_wrapper


def lambda_handler(event, context):
    """Lambda function invoking method for similar endpoint.
    """
    input_request = aws_wrapper.unpack(event)
    results = get_similar(event['pathParameters']['item_id'])
    print(results)
    return aws_wrapper.pack(results)

