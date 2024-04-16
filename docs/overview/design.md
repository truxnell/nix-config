# Design principles

Taking some lead from the [Zen of Python](https://peps.python.org/pep-0020/):

- Minimise dependencies, where required, explicitly define dependencies
- Use plain Nix & bash to solve problems over additional tooling
- Stable channel for stable machines. Unstable only where features are important.
- Modules for a specific service - Profiles for broad configuration of state.
- Write readable code - descriptive variable names and modules
- Keep functions/dependencies within the relevant module where possible
- Errors should never pass silently - use assert etc for misconfigurations
- Flat is better than nested - use built-in functions like map, filter, and fold to operate on lists or sets
