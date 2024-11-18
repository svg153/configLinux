# work

This folder contains work related files for git configuration.

## Files

| File | Description |
| ---- | ----------- |
| README.md | This file |
| `work.gitconfig` | Git configuration to include work related configuration depending on the company and the repository folder |
| `work-mail.gitconfig` | Git configuration for work mail |
| `work-<COMPANY>.gitconfig` | Git configuration for specific company |

## Example

The `work.gitconfig` file can include the following configuration:

```gitconfig
[includeIf "gitdir:~/work/"]
    path = work.gitconfig
```

Then, the `work-mail.gitconfig` or the `work-<COMPANY>.gitconfig` files can include the specific configuration for the company:

```gitconfig
[user]
    name = Sergio Valverde
    email = sv@company.com
```
