from .libs.helper_classes.request_classes.feedback_request import FeedbackRequest
from . import model


def save_feedback(input_request):
    feedback_request = FeedbackRequest()
    item = [
        feedback_request.query,
        feedback_request.item_id,
        feedback_request.sortOrder,
        feedback_request.msg,
        feedback_request.type,
    ]
    model.save_feedback(item)
    return {'status_code': 200}