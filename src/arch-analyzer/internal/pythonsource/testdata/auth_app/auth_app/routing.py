from auth_app.access import is_action_allowed, get_authenticated_user, AccessDeniedError


class ResourceManager:
    def __init__(self, policy):
        self.policy = policy

    async def get_resource(self, identifier):
        obj = await self.registry.get(identifier)
        if not obj:
            return None
        if not is_action_allowed(self.policy, "read", obj, get_authenticated_user()):
            return None
        return obj

    async def delete_resource(self, obj):
        if not is_action_allowed(self.policy, "delete", obj, get_authenticated_user()):
            raise AccessDeniedError()
        await self.registry.delete(obj)

    async def create_resource(self, obj):
        if not is_action_allowed(self.policy, "create", obj, get_authenticated_user()):
            raise AccessDeniedError()
        await self.registry.create(obj)

    async def list_resources(self, type):
        objs = await self.registry.get_all(type)
        return [obj for obj in objs if is_action_allowed(self.policy, "read", obj, get_authenticated_user())]
