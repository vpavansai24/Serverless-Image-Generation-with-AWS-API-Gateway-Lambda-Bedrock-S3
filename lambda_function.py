import os
import json
import boto3
import base64
import datetime

# Create client connection with Bedrock and S3 Services
client_bedrock = boto3.client('bedrock-runtime')
client_s3 = boto3.client('s3')

bucket_name = os.environ['S3_BUCKET_NAME']

def lambda_handler(event, context):
    print("Event:", event)
    prompt = event['queryStringParameters'].get('prompt', '')
    print(prompt)

    # Create a Request Syntax to access the Bedrock Service 
    bedrock_response = client_bedrock.invoke_model(
        contentType = 'application/json',
        accept = 'application/json',
        modelId = 'stability.stable-diffusion-xl-v1',
        body=json.dumps({"text_prompts": [{"text": prompt}],
                         "cfg_scale": 10,
                         "steps": 30,
                         "seed": 0}))
       
    # Retrieve from Dictionary, Convert Streaming Body to Byte using json load
    response_bedrock_byte=json.loads(bedrock_response['body'].read())

    # Retrieve data with artifact key and Decode from Base64
    response_bedrock_base64 = response_bedrock_byte['artifacts'][0]['base64']
    response_bedrock_finalimage = base64.b64decode(response_bedrock_base64)
    
    # Upload the File to S3 using Put Object Method
    poster_name = 'image-' + datetime.datetime.now().strftime('%Y-%m-%d-%H-%M-%S') + '.png'
    
    response_s3 = client_s3.put_object(
        Bucket=bucket_name,
        Body=response_bedrock_finalimage,
        Key=poster_name)

    # Generate Pre-Signed URL 
    generate_presigned_url = client_s3.generate_presigned_url('get_object', Params={'Bucket':bucket_name,'Key':poster_name}, ExpiresIn=3600)
    print(generate_presigned_url)
    return {
        'statusCode': 200,
        'body': generate_presigned_url
    }