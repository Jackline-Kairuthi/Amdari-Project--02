import boto3
import json
import logging
import pymysql
import os
import base64
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

secrets_client = boto3.client("secretsmanager")


def lambda_handler(event, context):
    step = event["Step"]
    arn = event["SecretId"]
    token = event["ClientRequestToken"]

    metadata = secrets_client.describe_secret(SecretId=arn)

    if token not in metadata["VersionIdsToStages"]:
        raise ValueError("Secret version not set for rotation")

    if "AWSCURRENT" in metadata["VersionIdsToStages"][token]:
        logger.info("Version already marked AWSCURRENT")
        return

    if step == "createSecret":
        create_secret(arn, token)
    elif step == "setSecret":
        set_secret(arn, token)
    elif step == "testSecret":
        test_secret(arn, token)
    elif step == "finishSecret":
        finish_secret(arn, token)
    else:
        raise ValueError("Invalid rotation step")


def get_secret_dict(arn, version=None):
    if version:
        response = secrets_client.get_secret_value(
            SecretId=arn, VersionId=version
        )
    else:
        response = secrets_client.get_secret_value(SecretId=arn)

    return json.loads(response["SecretString"])


def create_secret(arn, token):
    current = get_secret_dict(arn)

    try:
        secrets_client.get_secret_value(
            SecretId=arn,
            VersionId=token,
            VersionStage="AWSPENDING"
        )
        logger.info("Pending version already exists")
        return
    except ClientError:
        pass

    passwd = base64.b64encode(os.urandom(32)).decode("utf-8")

    new_secret = current.copy()
    new_secret["password"] = passwd

    secrets_client.put_secret_value(
        SecretId=arn,
        ClientRequestToken=token,
        SecretString=json.dumps(new_secret),
        VersionStages=["AWSPENDING"]
    )


def set_secret(arn, token):
    pending = get_secret_dict(arn, version=token)

    host = pending["host"]
    user = pending["username"]
    password = pending["password"]
    port = pending.get("port", 3306)

    try:
        conn = pymysql.connect(
            host=host,
            user=user,
            password=password,
            port=port,
            connect_timeout=5
        )
        conn.close()
    except Exception as e:
        logger.error("Failed to set secret: %s", e)
        raise


def test_secret(arn, token):
    pending = get_secret_dict(arn, version=token)

    host = pending["host"]
    user = pending["username"]
    password = pending["password"]
    port = pending.get("port", 3306)

    try:
        conn = pymysql.connect(
            host=host,
            user=user,
            password=password,
            port=port,
            connect_timeout=5
        )
        conn.close()
    except Exception as e:
        logger.error("Failed to test secret: %s", e)
        raise


def finish_secret(arn, token):
    metadata = secrets_client.describe_secret(SecretId=arn)

    current_version = None
    for version, stages in metadata["VersionIdsToStages"].items():
        if "AWSCURRENT" in stages:
            current_version = version
            break

    secrets_client.update_secret_version_stage(
        SecretId=arn,
        VersionStage="AWSCURRENT",
        MoveToVersionId=token,
        RemoveFromVersionId=current_version
    )
