# Volunteer Match Platform 🤝

A comprehensive, production-ready volunteer matching platform that connects volunteers with local NGOs based on location, cause, and time availability.

## 🌟 Features

### For Volunteers
- **Smart Matching**: Find opportunities based on location, interests, and availability
- **Profile Management**: Create detailed profiles with skills, interests, and availability
- **Real-time Notifications**: Get instant updates on opportunity matches
- **Application Tracking**: Track all your volunteer applications in one place
- **Reviews & Ratings**: Leave feedback for NGOs and build your volunteer reputation
- **Calendar Integration**: Sync volunteer opportunities with your calendar
- **Location-based Search**: Find opportunities near you with map visualization

### For NGOs
- **Opportunity Posting**: Create and manage volunteer opportunities
- **Volunteer Discovery**: Find qualified volunteers based on skills and availability
- **Application Management**: Review and manage volunteer applications
- **Verification System**: Get verified to build trust with volunteers
- **Analytics Dashboard**: Track volunteer engagement and impact metrics
- **Communication Tools**: Message volunteers directly through the platform
- **Event Management**: Schedule and coordinate volunteer events

### Platform Features
- **Geospatial Matching**: Advanced PostGIS-powered location matching
- **Real-time Messaging**: Built-in chat system using Phoenix Channels
- **Background Jobs**: Automated matching, notifications, and reminders
- **Admin Dashboard**: Comprehensive admin tools for platform management
- **Multi-language Support**: Ready for internationalization
- **Mobile Responsive**: Works seamlessly on all devices
- **API Access**: RESTful API for third-party integrations
- **Security**: JWT authentication, role-based access control, rate limiting

## 🏗️ Architecture

### Backend Stack
- **Elixir 1.14+**: Functional, concurrent, fault-tolerant language
- **Phoenix 1.7**: Web framework with LiveView for real-time features
- **PostgreSQL 14+**: Primary database with PostGIS extension
- **Oban**: Background job processing
- **Guardian**: JWT-based authentication
- **Swoosh**: Email delivery system

### Frontend Stack
- **Phoenix LiveView**: Server-rendered, real-time UI
- **TailwindCSS**: Utility-first CSS framework
- **Alpine.js**: Lightweight JavaScript framework
- **Leaflet/MapBox**: Interactive maps

### Infrastructure
- **Docker**: Containerized deployment
- **GitHub Actions**: CI/CD pipeline
- **Sentry**: Error tracking and monitoring
- **AWS S3**: File storage (avatars, documents)

## 🚀 Getting Started

### Prerequisites
- Elixir 1.14 or higher
- Erlang/OTP 25 or higher
- PostgreSQL 14+ with PostGIS extension
- Node.js 18+ (for assets)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/codeforgood-org/volunteer-matching-platform.git
   cd volunteer-matching-platform
   ```

2. **Install dependencies**
   ```bash
   mix deps.get
   ```

3. **Install PostgreSQL and PostGIS**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install postgresql postgresql-contrib postgis

   # macOS
   brew install postgresql postgis

   # Enable PostGIS extension
   psql -d volunteer_match_dev -c "CREATE EXTENSION IF NOT EXISTS postgis;"
   ```

4. **Configure environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

5. **Create and migrate database**
   ```bash
   mix ecto.setup
   ```

6. **Install frontend dependencies**
   ```bash
   mix assets.setup
   ```

7. **Start the Phoenix server**
   ```bash
   mix phx.server
   ```

Visit [`localhost:4000`](http://localhost:4000) in your browser.

### Development

```bash
# Run tests
mix test

# Run tests with coverage
mix coveralls.html

# Code quality checks
mix credo --strict

# Type checking
mix dialyzer

# Format code
mix format
```

## 🐳 Docker Deployment

### Development
```bash
docker-compose up
```

### Production
```bash
docker-compose -f docker-compose.prod.yml up -d
```

## 📋 Environment Variables

Create a `.env` file with the following variables:

```env
# Database
DATABASE_URL=postgresql://user:password@localhost/volunteer_match_dev
DATABASE_POOL_SIZE=10

# Phoenix
SECRET_KEY_BASE=your-secret-key-base
PHX_HOST=localhost
PHX_PORT=4000

# Guardian JWT
GUARDIAN_SECRET_KEY=your-guardian-secret

# Email
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-password
FROM_EMAIL=noreply@volunteermatch.org

# AWS S3 (optional)
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_BUCKET=volunteer-match-uploads
AWS_REGION=us-east-1

# Sentry (optional)
SENTRY_DSN=your-sentry-dsn

# Maps API
MAPBOX_TOKEN=your-mapbox-token
```

## 📊 Database Schema

### Core Entities
- **Users**: Authentication and base user data
- **Volunteers**: Volunteer profiles with skills and availability
- **NGOs**: NGO profiles with verification status
- **Opportunities**: Volunteer opportunities posted by NGOs
- **Applications**: Volunteer applications to opportunities
- **Messages**: Direct messaging between users
- **Reviews**: Ratings and reviews for completed volunteer work
- **Matches**: Algorithmic matches between volunteers and opportunities

## 🧪 Testing

The project includes comprehensive test coverage:

```bash
# Run all tests
mix test

# Run specific test file
mix test test/volunteer_match/accounts_test.exs

# Run tests with coverage
mix coveralls.html
open cover/excoveralls.html
```

## 📈 Performance

- **Real-time Updates**: Phoenix LiveView provides instant UI updates
- **Geospatial Queries**: PostGIS enables efficient location-based matching
- **Background Jobs**: Oban handles async processing without blocking
- **Connection Pooling**: Optimized database connection management
- **Caching**: Strategic caching for frequently accessed data
- **Rate Limiting**: Protects API endpoints from abuse

## 🔒 Security

- **Authentication**: JWT-based with secure token management
- **Authorization**: Role-based access control (RBAC)
- **Password Hashing**: bcrypt with strong work factors
- **CORS**: Configurable cross-origin resource sharing
- **Rate Limiting**: Request throttling to prevent abuse
- **SQL Injection**: Ecto parameterized queries
- **XSS Protection**: Phoenix HTML escaping
- **CSRF Protection**: Built-in Phoenix CSRF tokens

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 API Documentation

API documentation is available at `/api/docs` when running the server.

### Authentication
```bash
# Register
curl -X POST http://localhost:4000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "secure_password"}'

# Login
curl -X POST http://localhost:4000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "secure_password"}'
```

### Opportunities
```bash
# List opportunities
curl http://localhost:4000/api/opportunities \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Search by location
curl "http://localhost:4000/api/opportunities?lat=37.7749&lng=-122.4194&radius=10" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Phoenix Framework Team
- Elixir Community
- All contributors and volunteers

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/codeforgood-org/volunteer-matching-platform/issues)
- **Email**: support@volunteermatch.org
- **Documentation**: [Wiki](https://github.com/codeforgood-org/volunteer-matching-platform/wiki)

---

Built with ❤️ by Code for Good
