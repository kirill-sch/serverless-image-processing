import json
import boto3
import os

SFN_ARN = os.getenv('SFN_ARN', None)
sfn = boto3.client('stepfunctions')

def lambda_handler(event, context):
    body = json.loads(event['body'])

    if 'image_data' not in body:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Missing image_data"})
        }
    
    if 'content_type' not in body:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Missing content_type"})
        }
    
    try:
        response = sfn.start_execution(
            stateMachineArn=SFN_ARN,
            input=json.dumps({
                "body": body
            })
        )
    except Exception as e:
        return {
            "statusCode": 400,
            "body": json.dumps({
                "message": str(e)
            })
        }        

    return {
        "statusCode": 202,
        "body": json.dumps({
            "message": "Image processing started",
            "executionArn": response['executionArn']
        })
    }