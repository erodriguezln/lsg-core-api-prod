import os
from typing import Any, Dict, List, Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from pydantic import BaseModel


# === Configuración desde variables de entorno ===

AUTH_JWT_SECRET = os.getenv("AUTH_JWT_SECRET", "dev-secret-change-me")
AUTH_JWT_ALGORITHM = os.getenv("AUTH_JWT_ALGORITHM", "HS256")
AUTH_JWT_ISSUER = os.getenv("AUTH_JWT_ISSUER")  # opcional
AUTH_JWT_AUDIENCE = os.getenv("AUTH_JWT_AUDIENCE")  # opcional

# true, cuando no se necesita JWT, ya que se trabajará en local; te dará un usuario de admin ficticio
AUTH_DISABLED = os.getenv("AUTH_DISABLED", "false").lower() == "true" 

# false, cuando se necesita JWT, ya que se trabajará en producción (DIINF). Además hay que configurar el JWT
#AUTH_DISABLED = os.getenv("AUTH_DISABLED", "false").lower() == "false" 

AUTH_OPEN_ALL = os.getenv("AUTH_OPEN_ALL", "true").lower() == "true"

bearer_scheme = HTTPBearer(auto_error=False)

ROLE_ALL = ["player", "teacher", "researcher", "admin", "developer"]

class CurrentUser(BaseModel):
    """
    Representa al sujeto autenticado según el JWT de LSG-auth.
    El JWT emite `roles` como lista (v1.1+). Se mantiene `role` (singular)
    como el rol de mayor jerarquía para compatibilidad con código legacy.
    """
    sub: str
    role: str = "player"           # rol principal (mayor jerarquía)
    roles: List[str] = ["player"]  # todos los roles activos del JWT
    player_id: Optional[int] = None
    email: Optional[str] = None
    type: str = "user"             # user | service
    raw_claims: Dict[str, Any]


def _decode_token(token: str) -> Dict[str, Any]:
    """
    Decodifica y valida el JWT.
    Verifica algoritmo y, opcionalmente, iss/aud.
    """
    options = {"verify_aud": AUTH_JWT_AUDIENCE is not None}
    try:
        payload = jwt.decode(
            token,
            AUTH_JWT_SECRET,
            algorithms=[AUTH_JWT_ALGORITHM],
            issuer=AUTH_JWT_ISSUER,
            audience=AUTH_JWT_AUDIENCE,
            options=options,
        )
        return payload
    except JWTError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid authentication credentials: {e}",
        )


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
) -> CurrentUser:
    """
    Devuelve el usuario actual a partir del header Authorization: Bearer <token>.
    Si AUTH_DISABLED=true, devuelve un usuario admin ficticio (solo para desarrollo).
    """
    if AUTH_DISABLED:
        return CurrentUser(
            sub="dev-admin",
            role="admin",
            player_id=None,
            email="dev@example.com",
            type="service",
            raw_claims={},
        )

    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
        )

    token = credentials.credentials
    payload = _decode_token(token)

    # Ajusta estas claves a las claims reales de LSG-auth
    sub = str(payload.get("sub", ""))
    if not sub:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token: 'sub' missing",
        )

    # Soporte multi-rol (v1.1+): JWT emite "roles": [...]
    # Compatibilidad backward: si solo tiene "role" (string singular)
    roles_claim: List[str] = payload.get("roles", [])
    role_singular: Optional[str] = payload.get("role")

    if roles_claim:
        # v1.1+: lista de roles
        roles = [r for r in roles_claim if r in ROLE_ALL]
    elif role_singular:
        # legacy: un solo rol como string
        roles = [role_singular] if role_singular in ROLE_ALL else []
    else:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token: 'role' / 'roles' missing",
        )

    if not roles:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid token: ningún rol válido encontrado en {roles_claim or role_singular}",
        )

    # Jerarquía para role singular (mayor privilegio):
    _hierarchy = ["admin", "researcher", "developer", "teacher", "player"]
    role = next((r for r in _hierarchy if r in roles), roles[0])

    # Normalizamos player_id a int + fallback desde sub
    player_id_raw = payload.get("player_id") or payload.get("id_players")
    player_id: Optional[int] = None

    if player_id_raw is not None:
       try:
           player_id = int(player_id_raw)
       except (TypeError, ValueError):
           raise HTTPException(
               status_code=status.HTTP_401_UNAUTHORIZED,
               detail="Invalid token: 'player_id' must be an integer",
        )
    else:
       # Fallback: tokens antiguos que sólo traen sub
       if sub.isdigit():
           player_id = int(sub)

    email = payload.get("email")
    token_type = payload.get("type", "user")

    return CurrentUser(
        sub=sub,
        role=role,          # rol principal (mayor jerarquía)
        roles=roles,        # lista completa de roles activos
        player_id=player_id,
        email=email,
        type=token_type,
        raw_claims=payload,
    )


def require_roles(allowed_roles: List[str]):
    def dependency(current_user: CurrentUser = Depends(get_current_user)) -> CurrentUser:
        # Modo "open" (útil para Fase 1)
        if AUTH_OPEN_ALL:
            return current_user

        # Verificar si ALGUNO de los roles del usuario está en los permitidos
        if not any(r in allowed_roles for r in current_user.roles):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail={
                    "code":         "INSUFFICIENT_ROLE",
                    "required_any": allowed_roles,
                    "your_roles":   current_user.roles,
                },
            )
        return current_user

    return dependency


# Atajos de roles típicos
require_admin = require_roles(["admin"])
require_admin_or_researcher = require_roles(["admin", "researcher"])
require_admin_or_researcher_or_teacher = require_roles(["admin", "researcher", "teacher"])
require_player_or_higher = require_roles(ROLE_ALL)


def guard_player_access(
    player_id: int,
    current_user: CurrentUser = Depends(get_current_user),
) -> CurrentUser:
    # Modo "open" (Fase 1)
    if AUTH_OPEN_ALL:
        return current_user

    # Roles elevados pueden acceder a cualquier player
    elevated = {"admin", "researcher", "teacher", "developer"}
    if any(r in elevated for r in current_user.roles):
        return current_user

    # Player (solo player) puede acceder a sí mismo
    if any(r in current_user.roles for r in ("player",)):
        if current_user.player_id is not None and current_user.player_id == player_id:
            return current_user

    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="Not allowed to access this player's data",
    )