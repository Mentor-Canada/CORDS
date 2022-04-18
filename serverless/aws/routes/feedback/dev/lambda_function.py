from .controller import save_feedback
from .libs import aws_wrapper


def lambda_handler(event, context):
    """Lambda function invoking method for feedback endpoint.
    """
    input_request = aws_wrapper.unpack(event)
    results = save_feedback(input_request)
    print(results)
    return aws_wrapper.pack(results)
