from fastapi import APIRouter, Depends

from app.api.dependencies import get_current_user, get_preferences_service
from app.application.services.preferences_service import PreferencesService
from app.domain.preferences.models import Preference
from app.domain.preferences.schemas import PreferencePutRequest, PreferenceRead
from app.domain.users.models import User

router = APIRouter()


@router.get('', response_model=PreferenceRead, summary='Get user preferences')
async def read_preferences(
    current_user: User = Depends(get_current_user),
    preferences_service: PreferencesService = Depends(get_preferences_service),
) -> Preference:
    return await preferences_service.get_preferences(current_user.id)


@router.put('', response_model=PreferenceRead, summary='Upsert user preferences')
async def put_preferences(
    payload: PreferencePutRequest,
    current_user: User = Depends(get_current_user),
    preferences_service: PreferencesService = Depends(get_preferences_service),
) -> Preference:
    return await preferences_service.put_preferences(current_user.id, payload)