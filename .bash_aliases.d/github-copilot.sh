# 
# check if the command is being installed, if so, install the alias
# otherwise, run the command
command -v github-copilot-cli >/dev/null 2>&1
if [ $? -eq 0 ]; then
    eval "$(github-copilot-cli alias -- "$0")"

    # copilot_what-the-shell () {
    #   TMPFILE=$(mktemp);
    #   trap 'rm -f $TMPFILE' EXIT;
    #   if /home/svg153/.local/opt/node/bin/github-copilot-cli what-the-shell "$@" --shellout $TMPFILE; then
    #     if [ -e "$TMPFILE" ]; then
    #       FIXED_CMD=$(cat $TMPFILE);
    #       print -s "$FIXED_CMD";
    #       eval "$FIXED_CMD"
    #     else
    #       echo "Apologies! Extracting command failed"
    #     fi
    #   else
    #     return 1
    #   fi
    # };
    # # alias '??'='copilot_what-the-shell';

    # copilot_git-assist () {
    #   TMPFILE=$(mktemp);
    #   trap 'rm -f $TMPFILE' EXIT;
    #   if /home/svg153/.local/opt/node/bin/github-copilot-cli git-assist "$@" --shellout $TMPFILE; then
    #     if [ -e "$TMPFILE" ]; then
    #       FIXED_CMD=$(cat $TMPFILE);
    #       print -s "$FIXED_CMD";
    #       eval "$FIXED_CMD"
    #     else
    #       echo "Apologies! Extracting command failed"
    #     fi
    #   else
    #     return 1
    #   fi
    # };
    # # alias 'git?'='copilot_git-assist';

    # copilot_gh-assist () {
    #   TMPFILE=$(mktemp);
    #   trap 'rm -f $TMPFILE' EXIT;
    #   if /home/svg153/.local/opt/node/bin/github-copilot-cli gh-assist "$@" --shellout $TMPFILE; then
    #     if [ -e "$TMPFILE" ]; then
    #       FIXED_CMD=$(cat $TMPFILE);
    #       print -s "$FIXED_CMD";
    #       eval "$FIXED_CMD"
    #     else
    #       echo "Apologies! Extracting command failed"
    #     fi
    #   else
    #     return 1
    #   fi
    # };
    # # alias 'gh?'='copilot_gh-assist';
    # # alias 'wts'='copilot_what-the-shell';
fi
