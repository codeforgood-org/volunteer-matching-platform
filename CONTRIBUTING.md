# Contributing to VolunteerMatch

Thank you for your interest in contributing to VolunteerMatch! This document provides guidelines for contributing to the project.

## Code of Conduct

We are committed to providing a welcoming and inspiring community for all. Please read and follow our Code of Conduct.

## How to Contribute

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce**
- **Expected vs actual behavior**
- **Screenshots** (if applicable)
- **Environment details** (OS, Elixir/Erlang versions, etc.)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Clear title and description**
- **Detailed explanation** of the proposed functionality
- **Examples** of how the enhancement would be used
- **Potential implementation approach** (optional)

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Follow the coding standards** outlined below
3. **Write tests** for any new functionality
4. **Ensure all tests pass** (`mix test`)
5. **Update documentation** as needed
6. **Submit a pull request** with a clear description of changes

## Development Setup

1. Install dependencies:
   ```bash
   mix deps.get
   cd assets && npm install && cd ..
   ```

2. Create and migrate database:
   ```bash
   mix ecto.setup
   ```

3. Run tests:
   ```bash
   mix test
   ```

4. Start the server:
   ```bash
   mix phx.server
   ```

## Coding Standards

### Elixir

- Follow the [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide)
- Use `mix format` before committing
- Run `mix credo --strict` and fix any issues
- Write clear, descriptive function and variable names
- Add `@doc` and `@moduledoc` for public functions and modules
- Keep functions small and focused

### Testing

- Write tests for all new features
- Maintain or improve code coverage
- Use descriptive test names
- Follow the Arrange-Act-Assert pattern
- Mock external dependencies

### Commits

- Write clear, concise commit messages
- Use present tense ("Add feature" not "Added feature")
- Reference issues and PRs in commit messages
- Make atomic commits (one logical change per commit)

### Documentation

- Update README.md for user-facing changes
- Add inline comments for complex logic
- Update API documentation
- Include examples in documentation

## Project Structure

```
lib/
├── volunteer_match/          # Business logic contexts
│   ├── accounts.ex           # User management
│   ├── volunteers.ex         # Volunteer profiles
│   ├── ngos.ex              # NGO profiles
│   ├── opportunities.ex     # Opportunities & applications
│   ├── matching.ex          # Matching algorithm
│   └── workers/             # Background jobs
├── volunteer_match_web/     # Web layer
│   ├── controllers/         # API controllers
│   ├── live/               # LiveView modules
│   ├── channels/           # Phoenix Channels
│   └── components/         # Reusable components
└── volunteer_match.ex      # Application entry point

test/
├── volunteer_match/        # Context tests
└── volunteer_match_web/   # Web layer tests

priv/
├── repo/
│   ├── migrations/        # Database migrations
│   └── seeds.exs         # Seed data
└── static/               # Static assets
```

## Database Migrations

- Always test migrations in both directions (up and down)
- Never edit existing migrations that have been deployed
- Use reversible migrations when possible
- Add indexes for foreign keys and frequently queried columns
- Document complex migrations

## Feature Development Workflow

1. **Create an issue** describing the feature
2. **Discuss approach** with maintainers
3. **Create a branch** from `main`
4. **Implement the feature** with tests
5. **Submit a PR** for review
6. **Address feedback** from reviewers
7. **Merge** when approved

## Release Process

1. Update version in `mix.exs`
2. Update CHANGELOG.md
3. Create a release tag
4. Deploy to staging for testing
5. Deploy to production

## Getting Help

- **Documentation**: Check the [Wiki](https://github.com/codeforgood-org/volunteer-matching-platform/wiki)
- **Discussions**: Use [GitHub Discussions](https://github.com/codeforgood-org/volunteer-matching-platform/discussions)
- **Chat**: Join our community Slack (link in README)
- **Email**: support@volunteermatch.org

## Recognition

Contributors will be recognized in:
- CONTRIBUTORS.md file
- Release notes
- Project website

Thank you for contributing to VolunteerMatch! 🎉
