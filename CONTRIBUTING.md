# Contributing to RedRog

Thank you for your interest in contributing to RedRog! We welcome bug reports, documentation enhancements, feature proposals, and community localization.

## Code of Conduct

This project adheres to the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## How to Contribute

### Reporting Bugs
- Check the [Troubleshooting Guide](docs/TROUBLESHOOTING.md) and existing [GitHub Issues](https://github.com/carrilloapps/dotfiles/issues) before opening a new issue.
- Use the **Bug Report** template and provide system details (Linux distribution, kernel, Plasma version, GPU hardware).
- Include terminal logs or dry-run output (`./install.sh --dry-run`).

### Suggesting Enhancements
- Open an issue using the **Feature Request** template.
- Explain the practical use case, proposed implementation, and any trade-offs considered.

### Submitting Pull Requests
1. **Fork the repository** and create your branch from `main`:
   ```bash
   git checkout -b feature/my-new-feature
   ```
2. **Follow Project Architectural Principles**:
   - **Idempotence**: Every installation script must be safe to re-run multiple times without producing duplicates or errors.
   - **Dry-Run Support**: All file manipulations and configuration writes must route through the `run()`, `kw()`, or `recolor()` helpers to honor the `--dry-run` flag.
   - **Portability**: Never hardcode personal paths like `/home/<username>`. Always use `$HOME` or relative paths.
   - **Separation of Concerns**: Machine-specific hardware configurations belong under `hosts/<machine>/`, never in the universal `modules/` pipeline.
3. **Validate Your Changes**:
   ```bash
   # Verify syntax
   bash -n install.sh
   # Verify dry-run execution
   ./install.sh --dry-run
   ```
4. **Documentation**:
   - Write all code comments, commit messages, and documentation in standard American English (`en_US`).
   - If introducing new configuration keys, document them in [docs/CUSTOMIZE.md](docs/CUSTOMIZE.md).
5. **Commit Conventions**:
   Use clear, concise Conventional Commits messages:
   - `feat(module): add dynamic wallpaper switching`
   - `fix(audio): correct preset loading on external sinks`
   - `docs(troubleshooting): add KWin ABI recovery recipe`

## Translations (i18n)

RedRog supports 21 languages for desktop widgets and notifications using standard gettext catalogs. To add or update a language catalog:
1. Locate the `.pot` template and language `.po` files in `i18n/<component>/`.
2. Update the translation strings.
3. Compile and test with `msgfmt`.
4. Consult [docs/CUSTOMIZE.md](docs/CUSTOMIZE.md#translations) for full instructions.

## License

By contributing to RedRog, you agree that your contributions will be licensed under the [GNU General Public License v3.0](LICENSE).
