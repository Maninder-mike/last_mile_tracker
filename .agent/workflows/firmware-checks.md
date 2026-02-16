---
description: Run all firmware quality checks and tests locally
---

# Run Firmware Quality Checks

Run the following commands to execute the full firmware quality assurance workflow locally.

## 1. Install Dependencies

Ensure you have all necessary tools installed:

```bash
pip install ruff bandit mypy pytest
```

## 2. Run Linting & Formatting (Ruff)

Check for code style issues and format the code:

```bash
// turbo
python3 -m ruff check firmware_esp32/
// turbo
python3 -m ruff format firmware_esp32/ --check
```

## 3. Run Security Scan (Bandit)

Scan for common security issues:

```bash
// turbo
python3 -m bandit -r firmware_esp32/ -c firmware_esp32/pyproject.toml
```

## 4. Run Static Type Checking (Mypy)

Check for type errors:

```bash
// turbo
python3 -m mypy firmware_esp32/ --config-file firmware_esp32/pyproject.toml
```

## 5. Run Unit Tests (Pytest)

Execute the test suite:

```bash
// turbo
python3 -m pytest firmware_esp32/tests/
```

> [!NOTE]
> `firmware_esp32/tests/manual_ble_check.py` (formerly `manual_ble_test.py`) is excluded from automated tests as it requires physical hardware interaction.

## Troubleshooting

### Mypy Errors

You may see many errors like `Library stubs not installed for "micropython"` or `Module 'machine' not found`. This is expected when running locally without a full MicroPython stub environment. The type checker will still catch logical errors in your Python code.
