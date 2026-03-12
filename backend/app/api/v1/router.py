from fastapi import APIRouter

from app.api.v1.endpoints.auth import router as auth_router
from app.api.v1.endpoints.foods import router as foods_router
from app.api.v1.endpoints.goals import router as goals_router
from app.api.v1.endpoints.health import router as health_router
from app.api.v1.endpoints.meals import router as meals_router
from app.api.v1.endpoints.nutrition import router as nutrition_router
from app.api.v1.endpoints.preferences import router as preferences_router
from app.api.v1.endpoints.progress import router as progress_router
from app.api.v1.endpoints.system import router as system_router
from app.api.v1.endpoints.users import router as users_router

api_router = APIRouter()
api_router.include_router(health_router, prefix='/health', tags=['health'])
api_router.include_router(system_router, prefix='/system', tags=['system'])
api_router.include_router(auth_router, prefix='/auth', tags=['auth'])
api_router.include_router(users_router, prefix='/users', tags=['users'])
api_router.include_router(goals_router, prefix='/goals', tags=['goals'])
api_router.include_router(preferences_router, prefix='/preferences', tags=['preferences'])
api_router.include_router(foods_router, prefix='/foods', tags=['foods'])
api_router.include_router(meals_router, prefix='/meals', tags=['meals'])
api_router.include_router(nutrition_router, prefix='/nutrition', tags=['nutrition'])
api_router.include_router(progress_router, prefix='/progress', tags=['progress'])
