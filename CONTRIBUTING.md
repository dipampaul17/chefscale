# Contributing to ChefScale Pro

Thank you for your interest in contributing to ChefScale Pro! This guide will help you get started with contributing to the project.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for all contributors.

## How to Contribute

### Reporting Issues

1. **Check existing issues** first to avoid duplicates
2. **Use issue templates** when available
3. **Include details**:
   - macOS version
   - MacBook model
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots if applicable

### Submitting Pull Requests

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/your-feature-name`
3. **Follow coding standards** (see below)
4. **Write tests** for new features
5. **Update documentation** as needed
6. **Commit with clear messages**: `git commit -m "Add: Feature description"`
7. **Push to your fork**: `git push origin feature/your-feature-name`
8. **Open a Pull Request** with a clear description

## Coding Standards

### Swift Style Guide

- Use **SwiftLint** configuration provided
- Follow **Apple's Swift API Design Guidelines**
- Use meaningful variable and function names
- Keep functions small and focused
- Add comments for complex logic

### Architecture Principles

- **MVVM Pattern**: Separate views from business logic
- **Dependency Injection**: Pass dependencies explicitly
- **Protocol-Oriented**: Use protocols for flexibility
- **Testability**: Write testable code

### Code Organization

```
ChefScale/
├── Sources/
│   ├── Views/          # SwiftUI views
│   ├── ViewModels/     # View models
│   ├── Models/         # Data models
│   ├── Services/       # Business logic
│   └── Utilities/      # Helper functions
├── Tests/
│   ├── Unit/          # Unit tests
│   └── Integration/   # Integration tests
```

## Testing

### Running Tests

```bash
# Run all tests
./run_tests.sh

# Run end-to-end tests
python3 run_e2e_tests.py
```

### Writing Tests

- Aim for **80%+ code coverage**
- Test edge cases and error conditions
- Use descriptive test names
- Follow AAA pattern: Arrange, Act, Assert

## Documentation

- Update **README.md** for user-facing changes
- Add **inline documentation** for public APIs
- Include **code examples** where helpful
- Keep documentation **up to date**

## Performance Guidelines

- Maintain **60fps** UI updates
- Optimize for **battery efficiency**
- Profile before and after changes
- Consider memory usage

## Commit Messages

Use conventional commit format:

```
<type>: <description>

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

## Review Process

1. All PRs require **at least one review**
2. Address all feedback constructively
3. Keep PRs focused and small when possible
4. Ensure CI passes before merging

## Development Setup

1. **Install Xcode 16.0+**
2. **Clone the repository**
3. **Open `ChefScale.xcodeproj`**
4. **Build and run** (Cmd+R)

## Questions?

Feel free to:
- Open an issue for questions
- Start a discussion
- Contact maintainers

Thank you for contributing to ChefScale Pro! 🎯 