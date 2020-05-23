import boto3
from datetime import datetime, timezone

resource = boto3.resource("iam")
client = boto3.client("iam")


def _time_diff(keycreatedate):
    now = datetime.now(timezone.utc)
    diff = now - keycreatedate
    return diff.days


def get_iam_accounts():
    iam_account = {}
    for user in resource.users.all():
        user_data = client.get_user(UserName=user.name)["User"]
        iam_account[user_data["UserName"]] = user_data["Path"]
    return iam_account


def get_expired_keys(event, context):
    result = {}
    expired_keys = []

    for username, path in get_iam_accounts().items():
        if path == event["UserPath"]:
            metadata = client.list_access_keys(UserName=username)
            if metadata["AccessKeyMetadata"]:
                for key in metadata["AccessKeyMetadata"]:
                    if key["Status"] == "Active" and (
                        _time_diff(key["CreateDate"]) >= event["KeyAge"]
                    ):
                        expired_keys.append(
                            {
                                "UserName": username,
                                "AccessKey": key["AccessKeyId"],
                                "KeyAge": _time_diff(key["CreateDate"]),
                                "UserPath": path,
                            }
                        )
    result["Users"] = expired_keys
    return result
