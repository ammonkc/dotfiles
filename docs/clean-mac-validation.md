# Clean Mac validation

Run this check in a disposable Apple Silicon macOS VM or fresh test account before relying on bootstrap for a new machine. Use a native arm64 shell. Do not run the bootstrap against an existing daily-use account for validation.

1. Install Xcode Command Line Tools and complete their dialog.
2. Run the bootstrap from the README with `DOTFILES_PROFILE=core`. Confirm Homebrew, Task, Stow, mise, Neovim, and Yazi install without an existing shell configuration.
3. Run `task system:status`. It should show the 1Password setup as pending.
4. Sign into a personal 1Password account and run `task system:post-install` twice with the SSH agent disabled. Check that local git, env, and SSH files are mode `600` and that each managed secrets marker appears once. If this is a work test, sign into a business account and run `task system:work-setup` separately.
5. Run `task nvim:restore` twice. The second run should skip work. Disconnect the network during a fresh plugin restore and confirm that the plugin hash is absent after failure. If a parser or Mason tool step fails, confirm the tools hash is absent and a rerun retries those steps without repeating plugin restoration.
6. Run `DOTFILES_PROFILE=full task install`. If a full Homebrew package fails, check the status output, then run `task brew:retry` and check again.
7. Check `task doctor`, a fresh shell, launcher script commands, and the Tinycast extension import workflow separately.

The Linux path remains a secondary, manually checked setup. CI runs syntax, helper failure-path, and Stow checks; it does not install Homebrew or access 1Password.
