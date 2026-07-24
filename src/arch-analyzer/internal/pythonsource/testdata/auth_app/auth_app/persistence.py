from auth_app.access import is_action_allowed, get_authenticated_user, AccessDeniedError


class SessionStore:
    def __init__(self, policy):
        self.policy = policy

    async def create_session(self, name):
        user = get_authenticated_user()
        session = Session(name=name, owner=user)
        if not is_action_allowed(self.policy, "create", session, user):
            raise AccessDeniedError()
        await self.store.save(session)
        return session

    def _check_access(self, session):
        return is_action_allowed(self.policy, "read", session, get_authenticated_user())

    async def get_session(self, session_id):
        session = await self.store.get(session_id)
        if not self._check_access(session):
            return None
        return session
