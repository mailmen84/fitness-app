from app.core.config import Settings


_VALID_SECRET = 'test-secret-key-for-deployment-ready-config-12345'


def test_local_environment_uses_local_cors_defaults() -> None:
    settings = Settings(
        environment='development',
        auth_secret_key=_VALID_SECRET,
    )

    assert settings.is_local_environment is True
    assert settings.resolved_cors_allowed_origins == [
        'http://localhost',
        'http://127.0.0.1',
    ]
    assert settings.resolved_cors_allow_origin_regex == (
        r'^https?://(localhost|127\.0\.0\.1|\[::1\])(:\d+)?$'
    )
    assert settings.allows_sensitive_token_previews is True


def test_production_environment_requires_explicit_cors_configuration() -> None:
    settings = Settings(
        environment='production',
        auth_secret_key=_VALID_SECRET,
    )

    assert settings.is_local_environment is False
    assert settings.resolved_cors_allowed_origins == []
    assert settings.resolved_cors_allow_origin_regex is None
    assert settings.allows_sensitive_token_previews is False


def test_explicit_cors_configuration_is_normalized_and_preserved() -> None:
    settings = Settings(
        environment='production',
        auth_secret_key=_VALID_SECRET,
        cors_allowed_origins=[
            ' https://app.example.com ',
            'https://app.example.com',
            'https://demo.example.com',
        ],
        cors_allow_origin_regex='  ^https://preview\\.example\\.com$  ',
    )

    assert settings.resolved_cors_allowed_origins == [
        'https://app.example.com',
        'https://demo.example.com',
    ]
    assert settings.resolved_cors_allow_origin_regex == '^https://preview\\.example\\.com$'
