import os
from typing import Any, Dict, List, Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from pydantic import BaseModel, computed_field


AUTH_JWT_SECRET    = os.getenv("AUTH_JWT_SECRET", "dev-secret-change-me")
AUTH_JWT_ALGORITHM = os.getenv("AUTH_JWT_ALGORITHM", "HS256")
AUTH_JWT_ISSUER    = os.getenv("AUTH_JWT_ISSUER")    # opcional
AUTH_JWT_AUDIENCE  = os.getenv("AUTH_JWT_AUDIENCE")  # opcional

AUTH_DISABLED = os.getenv("AUTH_DISABLED", "false").lower() == "true"

AUTH_OPEN_ALL = os.getenv("AUTH_OPEN_ALL", "false").lower() == "true"

bearer_scheme = HTTPBearer(auto_error=False)

ROLE_ALL = ["player", "teacher", "researcher", "admin", "developer"]

_ROLE_PRIORITY = ["admin", "developer", "researcher", "teacher", "player"]

class CurrentUser(BaseModel):
    """
    Sujeto autenticado según el JWT de LSG-auth v1.1+.

    CAMBIO: 'role' (str) → 'roles' (List[str]).
    La property 'role' se mantiene para backward compat con código que
    aún lea current_user.role directamente.
    """
    sub:        str
    roles:      List[str] = ["player"]   # ← LISTA (antes: role: str)
    player_id:  Optional[int] = None
    email:      Optional[str] = None
    type:       str = "user"             # user | service
    raw_claims: Dict[str, Any]

    @computed_field
    @property
    def role(self) -> str:
        """
        Compatibilidad backward: retorna el rol de mayor privilegio activo.
        Útil mientras exista código legacy que lea current_user.role.
        """
        for r in _ROLE_PRIORITY:
            if r in self.roles:
                return r
        return self.roles[0] if self.roles else "player"

    def has_role(self, *roles: str) -> bool:
        """Shorthand: True si el usuario tiene al menos uno de los roles dados."""
        return any(r in self.roles for r in roles)


def _decode_token(token: str) -> Dict[str, Any]:
    """
    Decodifica y valida el JWT (alg + exp + opcional iss/aud).
    Lanza HTTP 401 si el token es inválido.
    """
    options = {"verify_aud": AUTH_JWT_AUDIENCE is not None}
    try:
        return jwt.decode(
            token,
            AUTH_JWT_SECRET,
            algorithms=[AUTH_JWT_ALGORITHM],
            issuer=AUTH_JWT_ISSUER,
            audience=AUTH_JWT_AUDIENCE,
            options=options,
        )
    except JWTError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Credenciales inválidas: {e}",
            headers={"WWW-Authenticate": "Bearer"},
        )


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
) -> CurrentUser:
    """
    Dependencia principal de autenticación.

    Flujo:
    1. Si AUTH_DISABLED=true → retorna admin ficticio (solo desarrollo).
    2. Decodifica el JWT.
    3. Lee claim 'roles' (lista, formato v1.1).
       Fallback a claim 'role' (string, tokens legacy emitidos por lsg-auth <v1.1).
    4. Valida que exista al menos un rol válido.
    5. Retorna CurrentUser.
    """
    if AUTH_DISABLED:
        return CurrentUser(
            sub="dev-admin",
            roles=["admin"],
            player_id=None,
            email="dev@example.com",
            type="service",
            raw_claims={},
        )

    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="No autenticado. Se requiere Authorization: Bearer <token>",
            headers={"WWW-Authenticate": "Bearer"},
        )

    payload = _decode_token(credentials.credentials)

    sub = str(payload.get("sub", ""))
    if not sub:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido: claim 'sub' ausente",
        )

    roles_raw = payload.get("roles")
    if not roles_raw:
        legacy_role = payload.get("role")
        if legacy_role:
            roles_raw = [legacy_role]
        else:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token inválido: no se encontraron claims 'roles' ni 'role'",
            )

    # Filtrar solo roles válidos
    roles = [r for r in roles_raw if r in ROLE_ALL]
    if not roles:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Token inválido: roles no reconocidos {roles_raw}",
        )

    player_id_raw = payload.get("player_id") or payload.get("id_players")
    player_id: Optional[int] = None

    if player_id_raw is not None:
        try:
            player_id = int(player_id_raw)
        except (TypeError, ValueError):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token inválido: 'player_id' debe ser entero",
            )
    elif sub.isdigit():
        player_id = int(sub)

    return CurrentUser(
        sub=sub,
        roles=roles,
        player_id=player_id,
        email=payload.get("email"),
        type=payload.get("type", "user"),
        raw_claims=payload,
    )


def require_roles(allowed_roles: List[str]):
    """
    Dependency factory para guards de rol.

    Uso en rutas:
        @router.get("/ruta", dependencies=[Depends(require_roles(["admin"]))])

    Uso como parámetro (para obtener el usuario):
        current: CurrentUser = Depends(require_roles(["admin", "researcher"]))

    Si AUTH_OPEN_ALL=true, omite la verificación de rol (solo para staging).
    """
    def dependency(
        current_user: CurrentUser = Depends(get_current_user),
    ) -> CurrentUser:
        if AUTH_OPEN_ALL:
            return current_user

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


def guard_player_access(
    player_id: int,
    current_user: CurrentUser = Depends(get_current_user),
) -> CurrentUser:
    """
    Guard para endpoints que operan sobre datos de UN jugador específico.

    Reglas:
    - admin / researcher / teacher / developer → acceso a cualquier player_id.
    - player → solo puede acceder a su propio player_id.
    - AUTH_OPEN_ALL=true → bypass (solo staging).
    """
    if AUTH_OPEN_ALL:
        return current_user

    elevated = {"admin", "researcher", "teacher", "developer"}
    if any(r in elevated for r in current_user.roles):
        return current_user

    if "player" in current_user.roles:
        if current_user.player_id is not None and current_user.player_id == player_id:
            return current_user

    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail={
            "code":      "PLAYER_ACCESS_DENIED",
            "message":   "No tienes permiso para acceder a datos de este jugador.",
            "player_id": player_id,
        },
    )

require_admin                          = require_roles(["admin"])
require_admin_or_researcher            = require_roles(["admin", "researcher", "developer"])
require_admin_or_researcher_or_teacher = require_roles(["admin", "researcher", "teacher", "developer"])
require_player_or_higher               = require_roles(ROLE_ALL)