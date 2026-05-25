# work

This folder contains work related files for git configuration.

## Files

| File | Description |
| ---- | ----------- |
| README.md | This file |
| `work.gitconfig` | Ignored/generated Git configuration that routes work identity by repo folder and by remote host |
| `work-company.gitconfig` | Ignored/generated Git configuration for a specific company (rename or edit locally) |

## Example

The `work.gitconfig` file can include both a folder-based include and host-based includes:

```gitconfig
[includeIf "gitdir:~/REPOSITORIOS/1_WORK/"]
    path = work-company.gitconfig
[includeIf "hasconfig:remote.*.url:https://<WORK_GIT_HOST>/**"]
    path = work-company.gitconfig
[includeIf "hasconfig:remote.*.url:ssh://git@<WORK_GIT_HOST>/**"]
    path = work-company.gitconfig
[includeIf "hasconfig:remote.*.url:git@<WORK_GIT_HOST>:**"]
    path = work-company.gitconfig
```

Then, the `work-company.gitconfig` file can include the specific configuration for the company:

```gitconfig
[user]
    name = <YOUR_NAME>
    email = <COMPANY_USER_EMAIL>
    signingkey = ~/.ssh/id_ed25519_sign_work.pub
```

The repository keeps these files ignored on purpose so the real values are generated locally by `run.sh` and never committed. If `WORK_GIT_HOST` is not set when you run `./run.sh git-config-only`, the generated file keeps `<WORK_GIT_HOST>` as a placeholder for you to edit locally.

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
