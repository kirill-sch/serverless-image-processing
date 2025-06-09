import json
import uuid
import os
import boto3
import base64
import traceback
import mimetypes
from datetime import datetime

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
        if route_key == 'POST /images':
            request_json = json.loads(event['body'])

             
            if 'image_data' not in request_json or 'content_type' not in request_json:
                    raise ValueError("Missing 'image_data' or 'content_type' in request")
            try:
                image_bytes = base64.b64decode(request_json['image_data'], validate=True)
            except (base64.binascii.Error, ValueError):
                raise ValueError("Invalid base64-encoded image data")
                
            max_size = 5 * 1024 * 1024
            if len(image_bytes) > max_size:
                raise ValueError("Image is too large")
                
            if not image_bytes.startswith((b'\xff\xd8', b'\x89PNG')): # JPEG or PNG
                raise ValueError("Unsupported image format (must be JPG or PNG)")            
            
            timestamp = datetime.now().isoformat()
            image_id = str(uuid.uuid4())
            content_type = request_json.get('content_type', 'image/jpeg')
            file_extension = mimetypes.guess_extension(content_type) or '.jpg'
            
            s3.put_object(
                Bucket=BUCKET_NAME,
                Key=f"uploads/{image_id}",
                Body=image_bytes
            )

            ddbtable.put_item(Item={
                'image_id': image_id,
                's3_key': f"uploads/{image_id}{file_extension}",
                'upload_time': timestamp,
                'status': 'pending'
            })

            response_body = {'image_id': image_id, 'message': 'Upload successful'}
            status_code = 200

    except ValueError as ve:
        status_code = 400
        response_body = {'error': str(ve)}
        print(str(ve))
    except Exception as err:
        status_code = 500
        response_body = {'error': str(err)}
        traceback.print_exc()
        print(str(err))
        
    response = {
        'statusCode': status_code,
        'body': json.dumps(response_body),
        'headers': headers
    }

    print("Upload lambda response:", response)
    return response
