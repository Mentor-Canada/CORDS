import os
from unittest import mock
import numpy as np
from tests import environment_vars as env
# from routes.similar_item import lambda_function
@mock.patch.dict(os.environ, {"ENV_PINECONE": env.ENV_PINECONE,
                              "PINECONE_INDEX": env.PINECONE_INDEX,
                              "API_KEY_PINECONE": env.API_KEY_PINECONE,
                              "HUGGINGFACE_API_TOKEN": env.HUGGINGFACE_API_TOKEN,
                              })
# @pytest.fixture
def test_similar_item_method(mocker):
    # mocker.patch('routes.similar_item.dev.controller.external.get_huggingface_vector', return_value=np.random.uniform(-1, 1, 384).tolist())
    # mocker.patch('routes.similar_item.dev.controller.external.similar_item_cache', return_value=[['a'] * 10, range(10)])
    from routes.similar_item.dev import lambda_function    
    response = lambda_function.lambda_handler(
        {"pathParameters": {"item_id": "123214"}},
        ''
    )
    
    assert response['statusCode'] == 200