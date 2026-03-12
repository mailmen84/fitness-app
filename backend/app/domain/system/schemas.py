from pydantic import BaseModel, ConfigDict


class FoundationResource(BaseModel):
    name: str
    status: str
    notes: str

    model_config = ConfigDict(from_attributes=True)


class DatabaseFoundation(BaseModel):
    driver: str
    migrations: str
    url_configured: bool

    model_config = ConfigDict(from_attributes=True)


class SystemFoundationResponse(BaseModel):
    service: str
    version: str
    environment: str
    api_prefix: str
    database: DatabaseFoundation
    resources: list[FoundationResource]

    model_config = ConfigDict(from_attributes=True)