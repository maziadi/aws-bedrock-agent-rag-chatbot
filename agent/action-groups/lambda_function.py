import json

def lambda_handler(event, context):
    print("Received event: " + json.dumps(event))
    
    api_path = event['apiPath']
    
    if api_path == "/GetProductsInventory":
        
        # Product Inventory data retrieval (from database or another service) code would go here.
        response_data = [
			{"Product Id": "1", "Product Name": "Laptop", "Quantity": 297},
			{"Product Id": "2", "Product Name": "Keyboard", "Quantity": 0},
			{"Product Id": "3", "Product Name": "Smartphone", "Quantity": 463},
			{"Product Id": "4", "Product Name": "Mouse", "Quantity": 904},
			{"Product Id": "5", "Product Name": "Headphones", "Quantity": 440},
			{"Product Id": "6", "Product Name": "Headphones", "Quantity": 608},
			{"Product Id": "7", "Product Name": "Camera", "Quantity": 0},
			{"Product Id": "8", "Product Name": "Smartwatch", "Quantity": 791},
			{"Product Id": "9", "Product Name": "Smartphone", "Quantity": 384},
			{"Product Id": "10", "Product Name": "Monitor", "Quantity": 707},
			{"Product Id": "11", "Product Name": "Headphones", "Quantity": 971},
			{"Product Id": "12", "Product Name": "Camera", "Quantity": 172},
			{"Product Id": "13", "Product Name": "Keyboard", "Quantity": 936},
			{"Product Id": "14", "Product Name": "Keyboard", "Quantity": 732},
			{"Product Id": "15", "Product Name": "Tablet", "Quantity": 0},
			{"Product Id": "16", "Product Name": "Mouse", "Quantity": 642},
			{"Product Id": "17", "Product Name": "Smartwatch", "Quantity": 31},
			{"Product Id": "18", "Product Name": "Keyboard    ", "Quantity": 674},
			{"Product Id": "19", "Product Name": "Smartphone", "Quantity": 203},
			{"Product Id": "20", "Product Name": "Tablet", "Quantity": 698}
		] 
    elif api_path == "/RestockProduct":
        
        # Product Restock Order creation code would go here.
        response_data = {"status": "Success"}
    else:
        response_data = {"message": "Unknwon API Path"}
        

    #response_body = {
    #    'items': items
    #}
    
    response_body = {
        'application/json': {
            'body': json.dumps(response_data)
        }
    }
    
    action_response = {
        'actionGroup': event['actionGroup'],
        'apiPath': event['apiPath'],
        'httpMethod': event['httpMethod'],
        'httpStatusCode': 200,
        'responseBody': response_body
    }
    
    session_attributes = event['sessionAttributes']
    prompt_session_attributes = event['promptSessionAttributes']
    
    api_response = {
        'messageVersion': '1.0', 
        'response': action_response,
        'sessionAttributes': session_attributes,
        'promptSessionAttributes': prompt_session_attributes
    }
    
    print("Returning API response: " + json.dumps(api_response))
        
    return api_response