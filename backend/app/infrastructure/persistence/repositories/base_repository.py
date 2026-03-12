from sqlalchemy.ext.asyncio import AsyncSession


class BaseRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    def add(self, instance: object) -> None:
        self.session.add(instance)

    async def flush(self) -> None:
        await self.session.flush()

    async def commit(self) -> None:
        await self.session.commit()

    async def refresh(self, instance: object) -> None:
        await self.session.refresh(instance)

    async def delete(self, instance: object) -> None:
        await self.session.delete(instance)
