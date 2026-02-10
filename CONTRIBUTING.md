# Contributing to Last Mile Tracker

Thank you for your interest in contributing to Last Mile Tracker! We welcome contributions from everyone.

## Code of Conduct

By participating in this project, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md).

## How to Contribute

1. **Fork the repository** on GitHub.
2. **Clone your fork** locally.
3. **Create a new branch** for your feature or bug fix:

    ```bash
    git checkout -b feature/your-feature-name
    ```

4. **Make your changes** and ensure they follow our [Style Guide](#style-guide).
5. **Commit your changes** using [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/):

    ```bash
    git commit -m "feat: add support for local caching"
    ```

6. **Push to your fork**:

    ```bash
    git push origin feature/your-feature-name
    ```

7. **Submit a Pull Request** against the `main` branch.

## Style Guide

### Flutter App (`apps/mobile/`)

- Follow the official [Flutter style guide](https://flutter.dev/docs/development/style-guide).
- Use `flutter format .` before committing.
- Ensure all new features are covered by widget or unit tests.

### ESP32 Firmware (`firmware_esp32/`)

- Follow [PEP 8](https://www.python.org/dev/peps/pep-0008/) for MicroPython code.
- Avoid large allocations in the main loop.
- Use `uasyncio` for non-blocking I/O.

## Pull Request Process

- Ensure the CI suite passes.
- Provide a clear description of the change in the PR template.
- Link any related issues using keywords (e.g., `Closes #123`).
