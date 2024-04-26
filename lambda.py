import json
import boto3
import time

'''
    create 2024-01-19 by ksj
'''

def launch_send_commnad(detail):
    ssm_client = boto3.client('ssm');
    print("Start Lifecycle Hooks At Launch!!!");
    #send_command to instance
    response = ssm_client.send_command(
        InstanceIds=[
            detail['EC2InstanceId'],
            ],
            TimeoutSeconds=120,
            DocumentName='EC2_LifeCycleHooks_At_Launch',
            DocumentVersion='$LATEST'
    )
    
    waiter(detail,response['Command']['CommandId']);
    complete_lifecycle(detail);

def terminate_send_command(detail):
    ssm_client = boto3.client('ssm');
    ec2_client = boto3.client('ec2')
    logPath=''
    
    print("Start Lifecycle Hooks At Terminate!!!")
    
    S3_Bucket='htlprice-logs';
    
    insatnceInfo=ec2_client.describe_instances(
        InstanceIds=[
            detail['EC2InstanceId'],
    ]
    )
    for tags in insatnceInfo['Reservations'][0]['Instances'][0]['Tags']:
            if tags['Key'] == 'GROUP' or tags['Key'] == 'Group':
                #print("GROUP tag value is {0}".format(tags['Value']))
                WAS=tags['Value'];
                break;
    
    #set logPath with GROUP tag values
    if WAS == 'service-A':
        logPath='logpathA';
        S3_Bucket='bucket-A';
        
    elif WAS == 'service-B':
        logPath='logpathB';
        S3_Bucket='bucket-B';

    else:
        print("No Such Group Tags...")
        return 0;

    #send_command to instance
    response = ssm_client.send_command(
    InstanceIds=[
        detail['EC2InstanceId'],
    ],
    TimeoutSeconds=120,
    Parameters={
        'LogPath': [logPath],
        'Bucket': [S3_Bucket],
    },
    DocumentName='EC2_LifeCycleHooks_At_Terminate',
    DocumentVersion='$LATEST'
    )
    waiter(detail,response['Command']['CommandId']);
    complete_lifecycle(detail);
    

def waiter(detail,cmdId):
    ssm_client = boto3.client('ssm');
    print("Start Waiter function... CommandId is {0}!!!".format(cmdId));
    #wait for command
    waiter = ssm_client.get_waiter('command_executed');
    waiter.wait(
    CommandId=cmdId,
    InstanceId=detail['EC2InstanceId']
    )
    print("End Waiter function... CommandId is {0}!!!".format(cmdId));

def complete_lifecycle(detail):
    asg_client = boto3.client('autoscaling')
    print("Complete_LifeCycle!!!");
    #complete asg lifecycle
    request = asg_client.complete_lifecycle_action(
    LifecycleHookName=detail['LifecycleHookName'],
    AutoScalingGroupName=detail['AutoScalingGroupName'],
    LifecycleActionToken=detail['LifecycleActionToken'],
    LifecycleActionResult='CONTINUE',
    InstanceId=detail['EC2InstanceId']
    )

def lambda_handler(event, context):

    print(json.dumps(event));
    if event['detail-type']=="EC2 Instance-launch Lifecycle Action" :
        launch_send_commnad(event['detail']);
    elif event['detail-type'] == 'EC2 Instance-terminate Lifecycle Action' :
        terminate_send_command(event['detail']);
    else:
        print("Not Action of this {0}".format(event['detail-type']))
