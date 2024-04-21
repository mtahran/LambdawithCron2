import boto3
import os


def lambda_handler(event, context):
    ec2 = boto3.client('ec2', region_name='us-east-1')
    volume_id = os.getenv('VOLUME_ID')
    result = ec2.create_snapshot(
        VolumeId="vol-00f15771ff76584dd",
        TagSpecifications=[
            {
                'ResourceType': 'snapshot',
                'Tags': [
                    {
                        'Key': 'Name',
                        'Value': 'DemoEBSVolumeSnapshot'
                    },
                ]
            },
        ],
    )
    print(result)