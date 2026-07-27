set -gx HOMEBREW_NO_ANALYTICS 1
set -gx HOMEBREW_BUNDLE_FILE $HOME/.config/homebrew/brewfile
set -gx HOMEBREW_CASK_OPTS --no-quarantine
set -gx HOMEBREW_AUTO_UPDATE_SECS 86400
set -gx HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS 1
set -gx MISE_FISH_AUTO_ACTIVATE 0

# HOMEBREW_PREFIX is exported, so nested shells inherit it and can skip the slow shellenv
if not set -q HOMEBREW_PREFIX
    for brewbin in /opt/homebrew/bin/brew /usr/local/bin/brew
        if test -x $brewbin
            $brewbin shellenv fish | source
            break
        end
    end
end

if set -q HOMEBREW_PREFIX
    fish_add_path --global $HOMEBREW_PREFIX/opt/curl/bin
    fish_add_path --global $HOMEBREW_PREFIX/opt/gettext/bin
    fish_add_path --global $HOMEBREW_PREFIX/opt/python/libexec/bin

    for tool in coreutils grep gnu-sed gawk findutils gnu-tar
        fish_add_path --global $HOMEBREW_PREFIX/opt/$tool/libexec/gnubin
    end
end
