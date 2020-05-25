import smtplib
import boto3

client = boto3.client("ssm")

# SMTP configuration
smtp_server = "smtp.gmail.com"
port = 587
smtp_username = "infectsoldier@gmail.com"
sender_email = "infectsoldier@gmail.com"

smtp_password = client.get_parameter(
    Name="SMTP_PASSWORD", WithDecryption=True
)["Parameter"]["Value"]


def send_email(receiver_email, message):
    with smtplib.SMTP(
        host=smtp_server, port=port
    ) as server:
        server.starttls()
        server.login(smtp_username, smtp_password)
        server.sendmail(sender_email, receiver_email, message)


def lambda_handler(event, context):
    if "Email" in event:
        if "Message" in event:
            send_email(event["Email"], event["Message"])
        else:
            message = f"{event['UserName']} access key is older then 90 days."
            send_email(event["Email"], message)
