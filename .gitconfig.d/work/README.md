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

## Use multiple SSH keys for different accounts

To use multiple SSH keys for different accounts, you can use the `~/.ssh/config` file to define the different keys for the different accounts. For example, to use the `id_rsa` key for the `github.com` account and the `id_rsa_work` key for the `github.com:org` account, you can use the following configuration:

```ssh-config
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_rsa

Host github.com-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_rsa_work
```

Then, you can clone the repositories using the `company.com` account:

```bash
git clone git@github.com-work:org/repo.git
```

But, if you want to clone the repositories using the `github.com` urls and automatically use the `id_rsa_work` key, you can use the `~/.gitconfig` file to define the `insteadOf` configuration:

```gitconfig
[url "git@github.com-work:org"]
    insteadOf = git@github.com:org
```
