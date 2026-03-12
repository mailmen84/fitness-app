from pydantic import Field

from app.domain.shared.schemas import DomainSchema
from app.domain.users.schemas import UserWithProfileRead


class AuthSignupRequest(DomainSchema):
    display_name: str = Field(min_length=1, max_length=120)
    email: str = Field(min_length=3, max_length=320)
    password: str = Field(min_length=8, max_length=128)


class AuthLoginRequest(DomainSchema):
    email: str = Field(min_length=3, max_length=320)
    password: str = Field(min_length=8, max_length=128)


class AuthSessionRead(DomainSchema):
    user: UserWithProfileRead
    onboarding_completed: bool


class AuthTokenRead(DomainSchema):
    access_token: str
    token_type: str = 'bearer'
    expires_in: int
    session: AuthSessionRead
