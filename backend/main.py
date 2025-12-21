from fastapi import FastAPI, Request, HTTPException, Response, HTTPException
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy import select

from db import SessionLocal
from models import User, Identity
from auth_password import hash_password, verify_password
from auth_jwt import decode_access_token, create_access_token

app = FastAPI()

@app.get("/api/health")
def health():
    return {"status": "ok"}

@app.get("/api/me")
def me(request: Request):
    token = request.cookies.get("access_token")
    if not token:
        raise HTTPException(status_code=401, detail="Not authenticated")

    payload = decode_access_token(token)
    return {"user_id": payload["sub"]}


###############____________Email_Password_Login_____________________###################

class RegisterIn(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=72)
    name: str | None = None

class LoginIn(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=72)

@app.post("/api/auth/register")
def register(data: RegisterIn, response: Response):
    db = SessionLocal()
    try:
        existing = db.execute(
            select(Identity).where(
                Identity.provider == "password",
                Identity.email == data.email
            )
        ).scalar_one_or_none()

        if existing:
            raise HTTPException(status_code=409, detail="Email already registered")

        user = User(status="active")
        db.add(user)
        db.flush()

        ident = Identity(
            user_id=user.id,
            provider="password",
            provider_user_id=data.email,
            email=data.email,
            name=data.name,
            password_hash=hash_password(data.password),
        )
        db.add(ident)
        db.commit()

        token = create_access_token(str(user.id))
        response.set_cookie("access_token", token, httponly=True, samesite="lax", secure=False, path="/")
        return {"ok": True}
    finally:
        db.close()


@app.post("/api/auth/login")
def login(data: LoginIn, response: Response):
    db = SessionLocal()
    try:
        ident = db.execute(
            select(Identity).where(
                Identity.provider == "password",
                Identity.email == data.email
            )
        ).scalar_one_or_none()

        if not ident or not ident.password_hash or not verify_password(data.password, ident.password_hash):
            raise HTTPException(status_code=401, detail="Invalid credentials")

        token = create_access_token(str(ident.user_id))
        response.set_cookie("access_token", token, httponly=True, samesite="lax", secure=False, path="/")
        return {"ok": True}
    finally:
        db.close()


@app.post("/api/auth/logout")
def logout(response: Response):
    response.delete_cookie("access_token", path="/")
    return {"ok": True}





###############____________DEBUG--LOGIN_____________________###################
from fastapi import Response
from auth_jwt import create_access_token

@app.post("/api/dev/login")
def dev_login(response: Response):
    token = create_access_token("00000000-0000-0000-0000-000000000001")
    response.set_cookie(
        key="access_token",
        value=token,
        httponly=True,
        samesite="lax",
        secure=False,  # lokal
        path="/",
    )
    return {"ok": True}

