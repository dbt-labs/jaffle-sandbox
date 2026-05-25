#!/usr/bin/env python
import argparse
import base64
import datetime as dt
import hashlib
import pathlib
import shlex

import jwt
import yaml
from cryptography.hazmat.primitives import serialization


def load_target(profile_name: str, target_name: str) -> dict:
    profiles_path = pathlib.Path.home() / ".dbt/profiles.yml"
    profiles = yaml.safe_load(profiles_path.read_text())
    try:
        return profiles[profile_name]["outputs"][target_name]
    except KeyError as exc:
        raise SystemExit(
            f"Could not find profile target {profile_name}.{target_name} in {profiles_path}"
        ) from exc


def snowflake_key_fingerprint(private_key) -> str:
    public_der = private_key.public_key().public_bytes(
        encoding=serialization.Encoding.DER,
        format=serialization.PublicFormat.SubjectPublicKeyInfo,
    )
    digest = hashlib.sha256(public_der).digest()
    return "SHA256:" + base64.b64encode(digest).decode("ascii")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Emit HORIZON_* exports for Snowflake Horizon key-pair auth."
    )
    parser.add_argument("--profile", default="fusion_tests")
    parser.add_argument("--target", default="snowflake")
    parser.add_argument("--expires-minutes", type=int, default=59)
    args = parser.parse_args()

    target = load_target(args.profile, args.target)
    private_der = base64.b64decode(target["private_key"])
    private_key = serialization.load_der_private_key(private_der, password=None)

    account = target["account"].upper()
    user = target["user"].upper()
    role = target["role"].upper()
    database = target["database"].upper()
    schema = target["schema"].upper()
    qualified_user = f"{account}.{user}"
    now = dt.datetime.now(dt.timezone.utc)
    payload = {
        "iss": f"{qualified_user}.{snowflake_key_fingerprint(private_key)}",
        "sub": qualified_user,
        "iat": now,
        "exp": now + dt.timedelta(minutes=args.expires_minutes),
    }

    token = jwt.encode(payload, private_key, algorithm="RS256")
    base_url = f"https://{account.lower()}.snowflakecomputing.com/polaris/api/catalog"
    env = {
        "HORIZON_ENDPOINT": base_url,
        "HORIZON_WAREHOUSE": database,
        "HORIZON_PAT": token,
        "HORIZON_OAUTH2_SERVER_URI": f"{base_url}/v1/oauth/tokens",
        "HORIZON_OAUTH2_SCOPE": f"session:role:{role}",
        "HORIZON_DEFAULT_SCHEMA": schema,
    }

    for key, value in env.items():
        print(f"export {key}={shlex.quote(value)}")


if __name__ == "__main__":
    main()
