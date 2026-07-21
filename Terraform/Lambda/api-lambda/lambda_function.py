import json
import logging

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    """
    Main handler function for AWS Lambda.
    This function is triggered when an API Gateway endpoint is called.

    Parameters:
    - event: Information about the request received from API Gateway
    - context: Runtime information provided by AWS Lambda

    Returns:
    - API Gateway response containing statusCode, headers, and body
    """
    print("Lambda Invocation started....")
    print("Evnet : ",event)
    # Log the incoming event for debugging
    logger.info("Received event: %s", json.dumps(event))

    try:
        # Extract information from the event
        http_method = event.get('httpMethod', '')
        path = event.get('path', '')
        query_params = event.get('queryStringParameters', {}) or {}
        path_params = event.get('pathParameters', {}) or {}
        body = event.get('body', '{}')

        # If body is provided as a string, parse it to JSON
        if isinstance(body, str):
            try:
                body = json.loads(body)
            except json.JSONDecodeError:
                body = {}

        # Process the request based on HTTP method and path
        response_body = {
            'message': f"Successfully processed {http_method} request to {path}",
            'queryParams': query_params,
            'pathParams': path_params,
            'receivedBody': body
        }

        logger.info('context: %s', context)
        # Return a successful response
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'  # CORS header
            },
            'body': json.dumps(response_body)
        }

    except Exception as e:
        # Log the error
        logger.error("Error processing request: %s", str(e))

        # Return an error response
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'  # CORS header
            },
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e)
            })
        }