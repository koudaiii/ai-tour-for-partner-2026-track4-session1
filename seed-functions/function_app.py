import json
import logging
import os
from pathlib import Path

import azure.functions as func

from seed_runner import run_seed

app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)
logger = logging.getLogger(__name__)


def _default_path(value: str | None, fallback: str) -> Path:
    if value:
        return Path(value)
    return Path(__file__).resolve().parent / fallback


@app.route(route="seed-now", methods=["POST"])
def seed_now(req: func.HttpRequest) -> func.HttpResponse:
    database_url = os.environ.get("ISUCONP_DATABASE_URL")
    if not database_url:
        return func.HttpResponse(
            json.dumps({"ok": False, "error": "ISUCONP_DATABASE_URL is required"}),
            status_code=500,
            mimetype="application/json",
        )

    try:
        body = req.get_json()
    except ValueError:
        body = {}

    users_json = _default_path(
        body.get("users_json") if isinstance(body, dict) else None,
        "data/demo_users.json",
    )
    posts_json = _default_path(
        body.get("posts_json") if isinstance(body, dict) else None,
        "data/demo_posts_text.json",
    )
    images_zip = _default_path(
        body.get("images_zip") if isinstance(body, dict) else None,
        "data/images.zip",
    )
    extract_dir = _default_path(
        body.get("extract_dir") if isinstance(body, dict) else None,
        "data/extracted",
    )
    post_count = int(
        (
            body.get("post_count")
            if isinstance(body, dict) and body.get("post_count") is not None
            else os.environ.get("SEED_POST_COUNT", "100")
        )
    )

    try:
        created = run_seed(
            database_url=database_url,
            users_json=users_json,
            posts_json=posts_json,
            images_zip=images_zip,
            extract_dir=extract_dir,
            post_count=post_count,
            log=logger.info,
        )
        return func.HttpResponse(
            json.dumps({"ok": True, "created_posts": created}, ensure_ascii=False),
            status_code=200,
            mimetype="application/json",
        )
    except Exception as exc:
        logger.exception("seed execution failed")
        return func.HttpResponse(
            json.dumps({"ok": False, "error": str(exc)}, ensure_ascii=False),
            status_code=500,
            mimetype="application/json",
        )
