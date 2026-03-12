import base64
import hashlib
import hmac
import json
import secrets
import time
from collections.abc import Mapping
from typing import Any

_PASSWORD_ALGORITHM = 'pbkdf2_sha256'
_PASSWORD_HASH_NAME = 'sha256'
_PASSWORD_ITERATIONS = 600_000
_TOKEN_ALGORITHM = 'HS256'


class InvalidTokenError(Exception):
    pass


class InvalidPasswordHashError(Exception):
    pass


def _urlsafe_b64encode(raw: bytes) -> str:
    return base64.urlsafe_b64encode(raw).decode('utf-8').rstrip('=')


def _urlsafe_b64decode(value: str) -> bytes:
    padding = '=' * (-len(value) % 4)
    return base64.urlsafe_b64decode(f'{value}{padding}')


def hash_password(password: str) -> str:
    salt = secrets.token_hex(16)
    digest = hashlib.pbkdf2_hmac(
        _PASSWORD_HASH_NAME,
        password.encode('utf-8'),
        salt.encode('utf-8'),
        _PASSWORD_ITERATIONS,
    )
    return (
        f'{_PASSWORD_ALGORITHM}${_PASSWORD_ITERATIONS}${salt}$'
        f'{_urlsafe_b64encode(digest)}'
    )


def verify_password(password: str, password_hash: str | None) -> bool:
    if password_hash is None:
        return False

    try:
        algorithm, iterations_raw, salt, expected_digest = password_hash.split('$', 3)
    except ValueError as error:
        raise InvalidPasswordHashError('Stored password hash is malformed.') from error

    if algorithm != _PASSWORD_ALGORITHM:
        raise InvalidPasswordHashError('Stored password hash uses an unsupported algorithm.')

    digest = hashlib.pbkdf2_hmac(
        _PASSWORD_HASH_NAME,
        password.encode('utf-8'),
        salt.encode('utf-8'),
        int(iterations_raw),
    )
    actual_digest = _urlsafe_b64encode(digest)
    return hmac.compare_digest(actual_digest, expected_digest)


def create_access_token(
    *,
    subject: str,
    secret_key: str,
    expires_in_seconds: int,
    additional_claims: Mapping[str, Any] | None = None,
) -> str:
    header = {
        'alg': _TOKEN_ALGORITHM,
        'typ': 'JWT',
    }
    payload = {
        'sub': subject,
        'exp': int(time.time()) + expires_in_seconds,
        'token_type': 'access',
    }
    if additional_claims:
        payload.update(dict(additional_claims))

    encoded_header = _urlsafe_b64encode(
        json.dumps(header, separators=(',', ':'), sort_keys=True).encode('utf-8')
    )
    encoded_payload = _urlsafe_b64encode(
        json.dumps(payload, separators=(',', ':'), sort_keys=True).encode('utf-8')
    )
    signing_input = f'{encoded_header}.{encoded_payload}'.encode('utf-8')
    signature = hmac.new(
        secret_key.encode('utf-8'),
        signing_input,
        hashlib.sha256,
    ).digest()
    return f'{encoded_header}.{encoded_payload}.{_urlsafe_b64encode(signature)}'


def decode_access_token(token: str, *, secret_key: str) -> dict[str, Any]:
    parts = token.split('.')
    if len(parts) != 3:
        raise InvalidTokenError('Access token is malformed.')

    encoded_header, encoded_payload, encoded_signature = parts
    signing_input = f'{encoded_header}.{encoded_payload}'.encode('utf-8')
    expected_signature = hmac.new(
        secret_key.encode('utf-8'),
        signing_input,
        hashlib.sha256,
    ).digest()
    actual_signature = _urlsafe_b64decode(encoded_signature)
    if not hmac.compare_digest(actual_signature, expected_signature):
        raise InvalidTokenError('Access token signature is invalid.')

    try:
        header = json.loads(_urlsafe_b64decode(encoded_header).decode('utf-8'))
        payload = json.loads(_urlsafe_b64decode(encoded_payload).decode('utf-8'))
    except (ValueError, UnicodeDecodeError) as error:
        raise InvalidTokenError('Access token payload is invalid.') from error

    if header.get('alg') != _TOKEN_ALGORITHM:
        raise InvalidTokenError('Access token algorithm is unsupported.')
    if payload.get('token_type') != 'access':
        raise InvalidTokenError('Access token type is invalid.')

    expires_at = payload.get('exp')
    if not isinstance(expires_at, int):
        raise InvalidTokenError('Access token expiry is invalid.')
    if expires_at <= int(time.time()):
        raise InvalidTokenError('Access token has expired.')

    return payload
