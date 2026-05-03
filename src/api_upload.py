import json
import boto3
import os
import uuid

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    try:
        bucket_name = os.environ.get('INPUT_BUCKET_NAME')
        # Get filename from query params or generate one
        query_params = event.get('queryStringParameters', {}) or {}
        filename = query_params.get('filename', f"{uuid.uuid4()}.txt")
        content_type = query_params.get('contentType', 'application/octet-stream')
        
        # Generate presigned URL for PUT
        presigned_url = s3_client.generate_presigned_url(
            'put_object',
            Params={
                'Bucket': bucket_name,
                'Key': filename,
                'ContentType': content_type
            },
            ExpiresIn=300 # 5 minutes
        )
        
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Content-Type': 'application/json'
            },
            'body': json.dumps({
                'upload_url': presigned_url,
                'filename': filename
            })
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
