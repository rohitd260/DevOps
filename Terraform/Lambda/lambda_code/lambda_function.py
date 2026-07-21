import json
import requests

def check_google_access():
   
    try:
        # Make a GET request to Google
        response = requests.get("https://www.google.com", timeout=5)
        
        # Check if the request was successful (status code 200)
        if response.status_code == 200:
            return "Connected to Google successfully!"
        else:
            raise Exception(f"Failed to access Google. Status code: {response.status_code}")
    except requests.exceptions.RequestException as e:
        # Raise an exception if there's an error (e.g., network issue)
        raise Exception(f"Error accessing Google: {str(e)}")

def lambda_handler(event, context):

    print("Lambda Innvocation is strted....")
    print(event)

    try:
        # Call the method to check Google access
        result = check_google_access()
        print(result)
        return {
            'statusCode': 200,
            'body': json.dumps(result)
        }
    except Exception as e:
        # Return an error message if an exception occurs
        return {
            'statusCode': 500,
            'body': json.dumps(f"Error: {str(e)}")
        }
