import uuid
from fastapi import Depends, Cookie, HTTPException, status
from jose import JWTError

from auth_jwt import decode_access_token


def get_current_user_id(
    access_token: str | None = Cookie(default=None)
) -> uuid.UUID:
    """
    Liest das HttpOnly-Cookie 'access_token', decodiert den JWT und gibt user_id (sub) als UUID zurück.
    Wirft 401, wenn kein Token da ist / Token ungültig / sub keine UUID ist.
    """
    if not access_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
        )

    try:
        payload = decode_access_token(access_token)
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
        )

    sub = payload.get("sub")
    if not sub:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload",
        )

    try:
        return uuid.UUID(sub)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid user id",
        )
