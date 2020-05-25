import boto3

resource = boto3.resource("iam")
client = boto3.client("iam")


def lambda_handler(event, context):
    if "UserName" in event and "AccessKey" in event:
        client.update_access_key(
            UserName=event["UserName"],
            AccessKeyId=event["AccessKey"],
            Status="Inactive",
        )
