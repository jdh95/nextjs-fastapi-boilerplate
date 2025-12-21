import uuid
from sqlalchemy import Column, DateTime, String, ForeignKey, func, Text
from sqlalchemy.dialects.postgresql import UUID

from db import Base

class User(Base):
    __tablename__ = "users"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    status = Column(String, nullable=False, default="active")

class Identity(Base):
    __tablename__ = "identities"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)

    provider = Column(String, nullable=False)              # "google" | "apple"
    provider_user_id = Column(String, nullable=False)      # sub / user id vom Provider
    email = Column(String, nullable=True)
    name = Column(String, nullable=True)
    password_hash = Column(Text, nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
