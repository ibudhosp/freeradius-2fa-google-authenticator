# FreeRADIUS + Google Authenticator (2FA) with REST API

Docker-based FreeRADIUS server with Google Authenticator TOTP two-factor authentication and REST API management.

## Features

- 🔐 FreeRADIUS with Google Authenticator (TOTP) via PAM
- 🌐 REST API (FastAPI) for user management
- 📱 QR Code generation for Google Authenticator app
- 🐳 Fully Dockerized with docker-compose
- 📖 Swagger UI API documentation

## Quick Start

```bash
# Build and start
docker-compose up -d --build

# Create a user via API
curl -X POST http://localhost:8000/api/users \
  -H "X-API-Key: your_api_secret_key_change_me" \
  -H "Content-Type: application/json" \
  -d '{"username": "john"}'

# View QR Code in browser
open http://localhost:8000/api/users/john/qrcode

# Test RADIUS authentication
curl -X POST http://localhost:8000/api/test-auth \
  -H "X-API-Key: your_api_secret_key_change_me" \
  -H "Content-Type: application/json" \
  -d '{"username": "john", "otp": "123456"}'
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/health` | Health check |
| POST | `/api/users` | Create new user + QR Code |
| GET | `/api/users` | List all users |
| GET | `/api/users/{username}` | Get user info |
| DELETE | `/api/users/{username}` | Delete user |
| POST | `/api/users/{username}/verify` | Verify OTP code |
| POST | `/api/users/{username}/reset` | Reset TOTP secret |
| GET | `/api/users/{username}/qrcode` | View QR Code (HTML) |
| POST | `/api/test-auth` | Test RADIUS authentication |

## API Documentation (Swagger UI)

```
http://localhost:8000/docs
```

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    Docker Container                       │
│                                                          │
│  ┌─────────────────────┐    ┌──────────────────────────┐ │
│  │    FastAPI (8000)    │    │   FreeRADIUS (1812/udp)  │ │
│  │                      │    │                          │ │
│  │  REST API            │    │  PAM Module              │ │
│  │  User Management     │───▶│  pam_google_authenticator│ │
│  │  QR Code Generation  │    │                          │ │
│  │  OTP Verification    │    │  RADIUS Authentication   │ │
│  │  Swagger UI (/docs)  │    │                          │ │
│  └──────────┬───────────┘    └──────────┬───────────────┘ │
│             │                           │                 │
│             ▼                           ▼                 │
│  ┌──────────────────────────────────────────────────────┐ │
│  │     /etc/freeradius/users-ga/<user>/                 │ │
│  │         .google_authenticator  (TOTP Secret)         │ │
│  │                  (Docker Volume)                     │ │
│  └──────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

## Ports

| Port | Protocol | Service |
|------|----------|---------|
| 1812 | UDP | RADIUS Authentication |
| 1813 | UDP | RADIUS Accounting |
| 8000 | TCP | REST API + Swagger UI |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `RADIUS_SECRET` | `changeme` | RADIUS shared secret |
| `API_KEY` | `changeme` | API authentication key |
| `ISSUER_NAME` | `FreeRADIUS-2FA` | TOTP issuer name |

## License

MIT