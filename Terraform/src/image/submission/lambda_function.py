import boto3
import os
from datetime import datetime
import base64

IMAGES_TABLE = os.getenv('IMAGES_TABLE', None)
BUCKET_NAME = os.getenv('BUCKET_NAME', None)
dynamodb = boto3.resource('dynamodb')
ddbtable = dynamodb.Table(IMAGES_TABLE)
s3 = boto3.client('s3')

def lambda_handler(event, context):
    completed_at = datetime.now().isoformat()
    image_id = event['validation_result']['image_id']
    file_extension = event['validation_result']['file_extension']
    image_bytes = base64.b64decode(event['resize_result']['resized_image_base64'])

    try:
        ddbtable.update_item(
            Key={'image_id': image_id},
            UpdateExpression='SET #1 = :1, #2 = :2, #3 = :3, #4 = :4',
            ExpressionAttributeNames={
                '#1': 'status',
                '#2': 'file_extension',
                '#3': 's3_key',
                '#4': 'completed_at'
            },
            ExpressionAttributeValues={
                ':1': 'successful',
                ':2': file_extension,
                ':3': f"uploads/{image_id}.{file_extension}",
                ':4': completed_at
            }
        )
    except Exception as e:
        raise Exception("Dynamodb update failed: " + str(e))

    try:
        s3.put_object(
            Bucket=BUCKET_NAME,
            Key=f"uploads/{image_id}.{file_extension}",
            Body=image_bytes
        )
    except Exception as e:
        raise Exception("S3 insert failed: " + str(e))

