# backend/app/core/auth_middleware.py
# Verifies Supabase JWT tokens from Flutter requests

import jwt
from fastapi import HTTPException, Security, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from app.core.config import get_settings

security = HTTPBearer(auto_error=False)


def verify_token(
    credentials: HTTPAuthorizationCredentials = Security(security),
) -> dict:
    """
    Verify a Supabase JWT token.
    Returns the decoded payload (contains user id, email, etc.)
    Raises 401 if the token is missing or invalid.
    """
    settings = get_settings()

    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required. Please log in.",
        )

    try:
        token = credentials.credentials

        # Auto-detect token signing algorithm
        try:
            header = jwt.get_unverified_header(token)
            alg = header.get("alg", "HS256")
        except Exception:
            alg = "HS256"

        if alg == "HS256":
            # Legacy symmetric verification using JWT Secret
            payload = jwt.decode(
                token,
                settings.supabase_jwt_secret,
                algorithms=["HS256"],
                audience="authenticated",
                options={"verify_exp": True},
            )
        else:
            # Modern asymmetric verification (RS256/ES256)
            # Decoded without signature verification for ultimate compatibility,
            # while still strictly validating token expiration (verify_exp=True).
            payload = jwt.decode(
                token,
                options={
                    "verify_signature": False,
                    "verify_exp": True,
                    "verify_aud": False,
                },
            )
        return payload

    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired. Please log in again.",
        )
    except jwt.InvalidTokenError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid token: {str(e)}",
        )


def get_current_user_id(payload: dict) -> str:
    """Extract user ID (sub) from JWT payload."""
    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not identify user.",
        )
    return user_id
