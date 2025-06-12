import json
import os
import boto3
import traceback

IMAGES_TABLE = os.getenv('IMAGES_TABLE', None)
BUCKET_NAME = os.getenv('BUCKET_NAME', None)
dynamodb = boto3.resource('dynamodb')
ddbtable = dynamodb.Table(IMAGES_TABLE)
s3 = boto3.client('s3')

def lambda_handler(event, context):
    route_key = f"{event['httpMethod']} {event['resource']}"

    response_body = {'Message': 'Unsupported route'}
    status_code = 400
    headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
    }

    try:
        if route_key == 'GET /images/{image_id}':
            image_id = event.get('pathParameters', {}).get('image_id')
            if not image_id:
                raise ValueError("Missing image_id in path parameters.")

            # check if there's an image with the given 'image_id'
            ddb_response = ddbtable.get_item(
                Key={'image_id': image_id}
            )
            print("ddb_response:", ddb_response)
            if 'Item' not in ddb_response:
                raise ValueError(f"No Item in DynamoDB with image_id: {image_id}")
            
            # create a presigned url
            s3_key = ddb_response['Item']['s3_key']            
            presigned_url = s3.generate_presigned_url(
                ClientMethod='get_object',
                Params={'Bucket': BUCKET_NAME, 'Key': s3_key},
                ExpiresIn=1800
            )

            response_body = {'download_url': presigned_url}
            status_code = 200
    
    except ValueError as ve:
        status_code = 400
        response_body = {'error': str(ve)}
        print(str(ve))
    except Exception as err:
        status_code = 500
        response_body = {'error': str(err)}
        print("error:", traceback.format_exc())

    response = {
        'statusCode': status_code,
        'body': json.dumps(response_body),
        'headers': headers
    }

    print("Download lambda response:", response)
    return response