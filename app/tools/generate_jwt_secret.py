# tools/generate_jwt_secret.py

import secrets

def main():
    # 64 bytes -> suficientemente fuerte para HS256
    secret = secrets.token_urlsafe(64)
    print("\n=== JWT_SECRET_KEY generado ===\n")
    print(secret)
    print("\nCopia este valor en tu archivo .env como:\n")
    print(f"JWT_SECRET_KEY={secret}\n")

if __name__ == "__main__":
    main()
