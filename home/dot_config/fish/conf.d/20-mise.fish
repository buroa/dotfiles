if type -q mise
    if status is-interactive; and test "$VSCODE_RESOLVING_ENVIRONMENT" != 1
        mise activate fish | source
    else
        mise activate fish --shims | source
    end
end
