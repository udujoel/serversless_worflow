def lambda_hander(event, context):
    print(
        f"Service account {event['UserName']}, key is older then 90 days."
        f"Rotate it please"
    )
    return event["UserName"]
