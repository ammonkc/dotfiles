# Automated testing

CI runs independent lint, shell, Stow, and configuration jobs. Shell,
Stow, and configuration suites run on Ubuntu and Apple Silicon macOS (the
`macos-26` runner image, pinned so `macos-latest` cannot change results). Pushes to
`main` also run a core profile install smoke job on Apple Silicon macOS
(`DOTFILES_PROFILE=core ./bin/install`, with the 1Password casks skipped). macOS
suites use `/bin/bash` so helpers retain compatibility with the system Bash 3.2.
The Tinycast extensions live in their own repository,
[tinycast-extensions](https://github.com/ammonkc/tinycast-extensions), with
their own CI.

## Running checks locally

Install Task, Stow, jq, Zsh, rsync, ripgrep, ShellCheck, GNU coreutils, and Python
3.11 or newer. On macOS, expose GNU `timeout` with
`export PATH="$(brew --prefix coreutils)/libexec/gnubin:$PATH"` after installing
coreutils. The Neovim failure-path suite needs this same installation dependency.
Use a temporary virtual environment for the configuration parsers:

```sh
python3 -m venv /tmp/dotfiles-test-venv
source /tmp/dotfiles-test-venv/bin/activate
python3 -m pip install -r tests/requirements.txt
task lint
task test
```

`task test` discovers every `tests/*.sh` suite, reports each result, continues
after failures, and fails if any suite fails. Focused commands match the CI
matrix: `task test:shell`, `task test:stow`, and `task test:config`.

Shell syntax checks discover tracked and nonignored new scripts, including
extensionless helpers and Zsh functions. Every file is checked separately;
ShellCheck covers Bash and POSIX shell files. Zsh uses its own syntax parser.
CI also validates the workflow with actionlint 1.7.12.

The task reference suite (`tests/task-references.sh`) resolves every `task:`
reference through nested includes, so a missing leading colon or a stray shell
fragment fails the build, and dry runs a few read only tasks.

Stow tests create disposable targets, exercise all packages together, and check
link ownership, exclusions, repeatability, and removal. Installation tests copy
the real Taskfiles into a fixture checkout and cover conflict backup, restored
contents and modes, repeat installation, foreign links, and private templates.
They never Stow into the invoking user's home.

Configuration tests parse JSON, editor JSONC, YAML, and TOML using their format
parsers, and load the Git and ripgrep configs through the native tools. Zsh
startup tests run noninteractive, interactive, and login shells with a temporary
home and optional integrations hidden. Global startup files are disabled to
keep the test independent of runner configuration.

Add shell suites directly under `tests/`; prefix Stow suites with `stow-` and
configuration suites with `config-`. Keep fixtures temporary, use synthetic
secrets, and stub commands that change system settings or contact services.

The full bootstrap, Homebrew bundle installation, real launcher import,
Accessibility permissions, and 1Password sign-in still require the disposable
machine checks in [Clean Mac validation](clean-mac-validation.md).
