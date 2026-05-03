import json
import boto3
import os

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    try:
        bucket_name = os.environ.get('OUTPUT_BUCKET_NAME')
        query_params = event.get('queryStringParameters', {}) or {}
        filename = query_params.get('filename')
        
        if not filename:
            return {'statusCode': 400, 'body': json.dumps({'error': 'filename is required'})}
            
        # Ensure it's looking for the .pdf version
        pdf_filename = os.path.splitext(filename)[0] + ".pdf"

        # Generate presigned URL for GET
        presigned_url = s3_client.generate_presigned_url(
            'get_object',
            Params={
                'Bucket': bucket_name,
                'Key': pdf_filename
            },
            ExpiresIn=3600 # 1 hour
        )
        
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Content-Type': 'application/json'
            },
            'body': json.dumps({
                'download_url': presigned_url
            })
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
