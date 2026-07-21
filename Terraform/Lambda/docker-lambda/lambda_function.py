import requests

def lambda_handler(event, context):

    print("Lambda Innovation started suucessfully")
    print(event)
    # Try to access Google
    try:
        response = requests.get("https://www.google.com")
        if response.status_code == 200:
            print("Connected successfully")
            return {
                'statusCode': 200,
                'body': 'Hello, connected to Google successfully!'
            }
        else:
            print("Failed to connect to Google")
            return {
                'statusCode': response.status_code,
                'body': 'Failed to connect to Google'
            }
    except requests.RequestException as e:
        print(f"Connection error: {e}")
        return {
            'statusCode': 500,
            'body': f'Connection error: {e}'
        }
    