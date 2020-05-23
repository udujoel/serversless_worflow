import boto3

resource = boto3.resource("iam")
client = boto3.client("iam")


def delete_users_key(user, key):
    for tag in client.list_user_tag(UserName=user)["Tag"]:
        if tag["Key"] == "email":
            client.update_access_key(
                UserName=user, AccessKeyId=key, Status="Inactive"
            )
        return tag["Value"]


def lambda_handler(event, context):
    if "UserName" in event and "AccessKey" in event:
        return delete_users_key(event["UserName"], event["AccessKey"])
