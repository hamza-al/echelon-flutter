# Authentication System Implementation

## Overview
Device-based authentication with JWT tokens. No user accounts, no passwords, no database assumptions.

## Flow

### First Launch
1. Generate UUID v4 as `device_id`
2. Store locally in Hive
3. Call `POST /auth/register` with `device_id`
4. Receive and store JWT token
5. Attach `Authorization: Bearer <token>` to all API requests

### Subsequent Launches
1. Load existing `device_id` and JWT from Hive
2. If no JWT, call `/auth/register` again
3. Use JWT for all API requests

### Token Expiry (401 Response)
1. Detect 401 on any API call
2. Auto-retry registration with same `device_id`
3. Store new JWT
4. Retry the failed request
5. All handled transparently by `AuthenticatedHttpClient`

## Implementation

### Core Components

**`AuthService`** (`lib/services/auth_service.dart`)
- Manages device ID and JWT storage
- Handles registration with backend
- Provides `token` and `deviceId` getters
- `handleUnauthorized()` for re-registration

**`AuthData` Model** (`lib/models/auth_data.dart`)
- Hive model (typeId: 5)
- Fields: `deviceId`, `jwtToken`, `tokenExpiry`

**`AuthenticatedHttpClient`** (`lib/services/authenticated_http_client.dart`)
- Wraps all HTTP calls
- Auto-attaches `Authorization` header
- Auto-handles 401 responses
- Retries requests after re-auth
- Methods: `get()`, `post()`, `put()`, `delete()`, `sendMultipart()`

### Updated Services

**`CoachChatService`**
- Now accepts `AuthService` in constructor
- Uses `AuthenticatedHttpClient` for all requests
- `sendMessageWithStore()` requires `service` parameter

**`CaloriesApiService`**
- Now accepts `AuthService` in constructor
- Uses `AuthenticatedHttpClient` for all requests

### Integration

All services are initialized in `main.dart`:
```dart
final authService = AuthService();
await authService.initialize();

// Provided to all widgets
Provider<AuthService>.value(value: authService)
```

### Usage in Widgets

```dart
// In any widget
final authService = context.read<AuthService>();
final coachService = CoachChatService(authService);
final caloriesService = CaloriesApiService(authService);
```

## Backend Contract

### POST /auth/register
**Request:**
```json
{
  "device_id": "uuid-v4-string"
}
```

**Response (200/201):**
```json
{
  "token": "jwt-token-string",
  "expires_at": "ISO-8601-datetime" // optional
}
```

### All Other Endpoints
**Headers:**
```
Authorization: Bearer <token>
```

**401 Response:**
Triggers automatic re-registration and retry.

## Key Features

✅ No accounts or passwords  
✅ Automatic token refresh on 401  
✅ Device persistence across app launches  
✅ Transparent auth for all API calls  
✅ Single source of truth (`AuthService`)  
✅ Works with existing HTTP-based services  

## Notes

- Device ID never changes once generated
- Same device ID used for re-registration
- All HTTP clients automatically handle auth
- No manual token management needed
- 401 errors are invisible to calling code

