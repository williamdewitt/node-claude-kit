# REST API Design Skill

## When to Use

Designing REST API endpoints. Follow RESTful principles and HTTP semantics.

## Resource-Based Endpoints

```typescript
// GOOD - Resource-based with proper verbs
GET    /api/v1/users           // List
GET    /api/v1/users/:id       // Get one
POST   /api/v1/users           // Create
PATCH  /api/v1/users/:id       // Update
DELETE /api/v1/users/:id       // Delete

// BAD - Action-based
GET /getUsers
POST /createUser
PATCH /updateUser/:id
```

## HTTP Status Codes

```typescript
// Success
200 OK - Get, update, query success
201 Created - Resource created
204 No Content - Delete success

// Client errors
400 Bad Request - Invalid input
401 Unauthorized - Not authenticated
403 Forbidden - No permission
404 Not Found
409 Conflict - Duplicate email, etc
422 Unprocessable Entity - Validation failed

// Server errors
500 Internal Server Error
503 Service Unavailable
```

## Pagination

```typescript
// Request
GET /api/v1/users?page=1&limit=20&sort=createdAt&order=desc

// Response
{
  "data": [ /* items */ ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "pages": 5,
    "hasMore": true
  }
}
```

## Error Responses

```typescript
// Validation error
422 Unprocessable Entity
{
  "code": "VALIDATION_ERROR",
  "message": "Request validation failed",
  "details": [
    { "field": "email", "message": "Invalid email format" }
  ]
}

// Business error
400 Bad Request
{
  "code": "EMAIL_ALREADY_EXISTS",
  "message": "Email already in use"
}
```

