# System Architecture

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Client Layer                                 │
├──────────────────┬──────────────────┬───────────────────────────────┤
│  Web Browser     │  GraphQL Client  │   Mobile Apps (Future)        │
│  (LiveView)      │  (Apollo/Relay)  │   (iOS/Android)              │
└────────┬─────────┴────────┬─────────┴────────┬────────────────────┘
         │                  │                  │
         │                  │                  │
         ▼                  ▼                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Phoenix Endpoint                                │
├──────────────────┬──────────────────┬───────────────────────────────┤
│   HTTP/2         │   WebSocket      │      GraphQL                  │
│   REST API       │   LiveView       │      Subscriptions            │
└────────┬─────────┴────────┬─────────┴────────┬────────────────────┘
         │                  │                  │
         ▼                  ▼                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Application Layer                               │
├──────────────────┬──────────────────┬───────────────────────────────┤
│  Controllers     │  LiveView Pages  │  GraphQL Resolvers            │
│  (REST API)      │  (Real-time UI)  │  (Absinthe)                   │
└────────┬─────────┴────────┬─────────┴────────┬────────────────────┘
         │                  │                  │
         └──────────────────┼──────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Business Logic Layer                            │
├──────────────────┬──────────────────┬───────────────────────────────┤
│   Accounts       │   Opportunities  │   Matching                    │
│   Volunteers     │   Applications   │   Gamification                │
│   NGOs           │   Messages       │   Social                      │
│   Reviews        │   Notifications  │   Analytics                   │
│   Uploads        │   Exports        │   Workers                     │
└────────┬─────────┴────────┬─────────┴────────┬────────────────────┘
         │                  │                  │
         └──────────────────┼──────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Data Access Layer                               │
├──────────────────┬──────────────────┬───────────────────────────────┤
│   Ecto Repo      │   Schemas        │   Changesets                  │
│   Queries        │   Migrations     │   Validations                 │
└────────┬─────────┴────────┬─────────┴────────┬────────────────────┘
         │                  │                  │
         └──────────────────┼──────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Infrastructure Layer                            │
├──────────────────┬──────────────────┬───────────────────────────────┤
│  PostgreSQL      │  AWS S3          │   Redis (Future)              │
│  + PostGIS       │  (File Storage)  │   (Caching)                   │
│  + pg_trgm       │                  │                               │
└──────────────────┴──────────────────┴───────────────────────────────┘
```

## Component Interaction Diagram

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│             │         │             │         │             │
│  Volunteer  │◄───────►│  Matching   │◄───────►│     NGO     │
│             │         │  Algorithm  │         │             │
└──────┬──────┘         └──────┬──────┘         └──────┬──────┘
       │                       │                       │
       │                       │                       │
       ▼                       ▼                       ▼
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│             │         │             │         │             │
│Applications │◄───────►│Opportunities│◄───────►│  Analytics  │
│             │         │             │         │             │
└──────┬──────┘         └──────┬──────┘         └──────┬──────┘
       │                       │                       │
       │                       │                       │
       ▼                       ▼                       ▼
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│             │         │             │         │             │
│   Reviews   │◄───────►│Notifications│◄───────►│Gamification │
│             │         │             │         │             │
└─────────────┘         └─────────────┘         └─────────────┘
       │                       │                       │
       └───────────────────────┼───────────────────────┘
                               │
                               ▼
                        ┌─────────────┐
                        │             │
                        │   Social    │
                        │ Activity    │
                        │             │
                        └─────────────┘
```

## Real-Time Communication Flow

```
┌─────────────┐
│   Browser   │
└──────┬──────┘
       │
       │ WebSocket Connection
       │
       ▼
┌─────────────────┐         ┌──────────────┐
│ Phoenix Channel │◄───────►│  PubSub      │
│   (Messages)    │         │  (Broadcast) │
└────────┬────────┘         └──────┬───────┘
         │                         │
         ▼                         ▼
┌─────────────────┐         ┌──────────────┐
│ GraphQL         │         │ LiveView     │
│ Subscriptions   │         │ (Real-time)  │
└────────┬────────┘         └──────┬───────┘
         │                         │
         └────────────┬────────────┘
                      │
                      ▼
               ┌──────────────┐
               │ Notifications│
               │   Context    │
               └──────────────┘
```

## Background Job Processing

```
┌─────────────────┐
│  Oban Scheduler │
└────────┬────────┘
         │
         ├────► Daily Match Worker  ──────► Generate Matches
         │
         ├────► Reminder Worker     ──────► Send Reminders
         │
         └────► Cleanup Worker      ──────► Remove Expired Data
                     │
                     ▼
              ┌──────────────┐
              │  Job Queues  │
              ├──────────────┤
              │ • default    │
              │ • mailers    │
              │ • events     │
              └──────────────┘
```

## Matching Algorithm Flow

```
┌──────────────┐
│  Volunteer   │
│   Profile    │
└──────┬───────┘
       │
       ▼
┌─────────────────────────┐
│  Find Nearby            │
│  Opportunities          │
│  (PostGIS Query)        │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│  Calculate Scores       │
├─────────────────────────┤
│ • Location (35%)        │
│ • Cause (30%)           │
│ • Skills (25%)          │
│ • Time (10%)            │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│  Filter by              │
│  Min Score (50%)        │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│  Sort by Score          │
│  Take Top 20            │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│  Save Matches           │
│  Send Notifications     │
└─────────────────────────┘
```

## Authentication Flow

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │
       │ POST /api/auth/login
       │ {email, password}
       │
       ▼
┌─────────────────┐
│ Auth Controller │
└────────┬────────┘
         │
         │ Accounts.authenticate()
         │
         ▼
┌─────────────────┐
│  User Context   │
│  • Verify Pass  │
│  • Get User     │
└────────┬────────┘
         │
         │ Guardian.encode_and_sign()
         │
         ▼
┌─────────────────┐
│  JWT Token      │
│  Generation     │
└────────┬────────┘
         │
         │ Store in Guardian DB
         │
         ▼
┌─────────────────┐
│  Return Token   │
│  + User Data    │
└─────────────────┘
```

## Data Flow: Volunteer Application

```
┌─────────────┐
│  Volunteer  │
└──────┬──────┘
       │
       │ Apply to Opportunity
       │
       ▼
┌─────────────────┐
│  Application    │
│  Created        │
└────────┬────────┘
         │
         ├────► Notify NGO
         │      (Email + Push)
         │
         ├────► Update Opportunity
         │      (Increment application_count)
         │
         ├────► Create Activity
         │      (Social feed)
         │
         └────► Check Match Status
                (Mark as applied)
                     │
                     ▼
              ┌──────────────┐
              │  NGO Reviews │
              │  Application │
              └──────┬───────┘
                     │
                     ├── Accept ──► Notify Volunteer
                     │              Update Stats
                     │              Create Activity
                     │
                     └── Reject ──► Notify Volunteer
                                    Update Stats
```

## Gamification Flow

```
┌─────────────────┐
│  User Action    │
│  (Complete      │
│   Opportunity)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Update Stats   │
│  • Hours        │
│  • Completed    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Check Badge    │
│  Criteria       │
└────────┬────────┘
         │
         ├── Match ──► Award Badge
         │             Notify User
         │             Create Activity
         │
         ▼
┌─────────────────┐
│  Update         │
│  Achievement    │
│  Progress       │
└────────┬────────┘
         │
         ├── Unlocked ──► Award Achievement
         │                Notify User
         │                Create Activity
         │
         ▼
┌─────────────────┐
│  Recalculate    │
│  Leaderboard    │
└─────────────────┘
```

## Database Schema Relationships

```
users
  ├──< volunteers (1:1)
  │     ├──< applications (1:N)
  │     ├──< matches (1:N)
  │     └──< user_badges (1:N)
  │
  ├──< ngos (1:1)
  │     └──< opportunities (1:N)
  │           ├──< applications (1:N)
  │           └──< matches (1:N)
  │
  ├──< user_achievements (1:N)
  ├──< notifications (1:N)
  ├──< sent_messages (1:N)
  ├──< received_messages (1:N)
  ├──< reviews_given (1:N)
  ├──< reviews_received (1:N)
  ├──< activities (1:N)
  ├──< followers (follower) (1:N)
  └──< followers (following) (1:N)

badges
  └──< user_badges (1:N)

achievements
  └──< user_achievements (1:N)

applications
  ├──< reviews (1:N)
  └──< messages (1:N)
```

## Technology Stack Layers

```
┌────────────────────────────────────────┐
│         Presentation Layer             │
├────────────────────────────────────────┤
│  Phoenix LiveView  │  TailwindCSS      │
│  GraphQL           │  Alpine.js        │
└────────────────────────────────────────┘
                  │
┌────────────────────────────────────────┐
│         Application Layer              │
├────────────────────────────────────────┤
│  Phoenix Framework                     │
│  Absinthe (GraphQL)                    │
│  Phoenix Channels (WebSocket)          │
└────────────────────────────────────────┘
                  │
┌────────────────────────────────────────┐
│         Business Logic Layer           │
├────────────────────────────────────────┤
│  Contexts (Elixir Modules)             │
│  • Accounts    • Opportunities         │
│  • Volunteers  • Matching              │
│  • NGOs        • Gamification          │
│  • Social      • Analytics             │
└────────────────────────────────────────┘
                  │
┌────────────────────────────────────────┐
│         Data Layer                     │
├────────────────────────────────────────┤
│  Ecto ORM                              │
│  Ecto Schemas & Changesets             │
│  Query Builders                        │
└────────────────────────────────────────┘
                  │
┌────────────────────────────────────────┐
│         Infrastructure Layer           │
├────────────────────────────────────────┤
│  PostgreSQL + PostGIS                  │
│  AWS S3                                │
│  Redis (future)                        │
│  SMTP Server                           │
└────────────────────────────────────────┘
```

## Deployment Architecture

```
┌────────────────────────────────────────────────────┐
│                Internet/CDN                        │
└───────────────────┬────────────────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────────────────┐
│              Nginx (Reverse Proxy)                 │
│  • SSL/TLS Termination                             │
│  • Load Balancing                                  │
│  • Static Asset Serving                            │
└───────────────────┬────────────────────────────────┘
                    │
           ┌────────┴────────┐
           │                 │
           ▼                 ▼
┌──────────────┐    ┌──────────────┐
│ Phoenix App  │    │ Phoenix App  │
│ Container 1  │    │ Container 2  │
│              │    │              │
│  • Phoenix   │    │  • Phoenix   │
│  • Oban      │    │  • Oban      │
│  • Channels  │    │  • Channels  │
└──────┬───────┘    └──────┬───────┘
       │                   │
       └────────┬──────────┘
                │
       ┌────────┴────────┐
       │                 │
       ▼                 ▼
┌──────────────┐    ┌──────────────┐
│  PostgreSQL  │    │    AWS S3    │
│  + PostGIS   │    │ (Files)      │
└──────────────┘    └──────────────┘
```

## Security Layers

```
┌────────────────────────────────────────┐
│        Application Security            │
├────────────────────────────────────────┤
│  JWT Authentication                    │
│  Role-Based Access Control             │
│  Input Validation                      │
│  SQL Injection Prevention              │
│  XSS Protection                        │
│  CSRF Protection                       │
└────────────────────────────────────────┘
                  │
┌────────────────────────────────────────┐
│        Transport Security              │
├────────────────────────────────────────┤
│  HTTPS/TLS 1.3                         │
│  WebSocket Secure (WSS)                │
│  CORS Configuration                    │
└────────────────────────────────────────┘
                  │
┌────────────────────────────────────────┐
│        Data Security                   │
├────────────────────────────────────────┤
│  Password Hashing (Bcrypt)             │
│  Encrypted Connections                 │
│  Secure File Upload                    │
│  Token Revocation                      │
└────────────────────────────────────────┘
                  │
┌────────────────────────────────────────┐
│        Infrastructure Security         │
├────────────────────────────────────────┤
│  Firewall Rules                        │
│  Private Subnets                       │
│  Security Groups                       │
│  Rate Limiting                         │
└────────────────────────────────────────┘
```

## Scalability Patterns

1. **Horizontal Scaling**: Add more Phoenix app instances
2. **Database Read Replicas**: Distribute read load
3. **Caching Layer**: Redis for frequently accessed data
4. **CDN**: Static assets and media files
5. **Background Jobs**: Async processing with Oban queues
6. **Connection Pooling**: Efficient database connections
7. **Load Balancing**: Distribute traffic across instances
8. **Stateless Design**: No session state in app servers

---

This architecture supports:
- **10,000+ concurrent users**
- **Sub-second response times**
- **Real-time updates**
- **High availability** (99.9%+)
- **Horizontal scalability**
- **Fault tolerance**
