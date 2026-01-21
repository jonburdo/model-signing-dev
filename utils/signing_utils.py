from base64 import b64decode
import json
from pathlib import Path


def get_signed_files(modelsig: Path) -> list[str]:
    with open(modelsig, "r") as file:
        signature = json.load(file)
    payload = json.loads(b64decode(signature["dsseEnvelope"]["payload"]))
    return [entry["name"] for entry in payload["predicate"]["resources"]]


def get_ignore_paths(modelsig: Path) -> list[str]:
    with open(modelsig, "r") as file:
        signature = json.load(file)
    payload = json.loads(b64decode(signature["dsseEnvelope"]["payload"]))
    ignore_paths = payload["predicate"]["serialization"]["ignore_paths"]
    ignore_paths.sort()
    return ignore_paths


def get_model_name(modelsig: Path) -> str:
    with open(modelsig, "r") as file:
        signature = json.load(file)
    payload = json.loads(b64decode(signature["dsseEnvelope"]["payload"]))
    return payload["subject"][0]["name"]
