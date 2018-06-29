test.py

import boto3
def sample(event, context):
    client = boto3.client('s3','us-east-1')
    s3 = boto3.resource('s3','us-east-1')
    last_modified = []
    bucket_keys = []
    response = client.list_objects(
    Bucket='lambda-source-up-test')
    for res in response['Contents']:
        last_modified.append(res['LastModified'])
        bucket_keys.append(res['Key'])
    latest = max(last_modified)
    latest_key = last_modified.index(latest)
    print latest_key
    new_file = bucket_keys[latest_key]
    print new_file
    
    copy_source = {
    'Bucket': 'lambda-source-up-test',
    'Key': new_file
    }
    s3.meta.client.copy(copy_source, 'lambda-dest', new_file)

