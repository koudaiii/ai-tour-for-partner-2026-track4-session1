import sys
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "seed-functions"))

from api_seed_runner import encode_multipart_formdata, extract_csrf_token


def test_extract_csrf_token():
    html = '<input type="hidden" name="csrf_token" value="abc123">'
    assert extract_csrf_token(html) == "abc123"


def test_encode_multipart_formdata_contains_fields_and_file():
    body, content_type = encode_multipart_formdata(
        {"body": "hello", "csrf_token": "token-1"},
        file_field="file",
        filename="demo.jpg",
        file_bytes=b"binary-data",
        mime="image/jpeg",
    )

    assert content_type.startswith("multipart/form-data; boundary=")
    assert b'name="body"' in body
    assert b"hello" in body
    assert b'name="csrf_token"' in body
    assert b"token-1" in body
    assert b'name="file"; filename="demo.jpg"' in body
    assert b"Content-Type: image/jpeg" in body
    assert b"binary-data" in body
