eval "$(atuin init zsh)"

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::command-not-found

# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

# Aliases
alias ls='ls --color'
#alias vim='nvim'
alias c='clear'

# Shell integrations
# eval "$(fzf --zsh)"
# eval "$(zoxide init --cmd cd zsh)"

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

#alias air='~/.air'
export PATH="$PATH:${GOPATH:-$HOME/go}/bin"
export PATH="$HOME/.local/bin:$PATH"

export DOTFILES="$HOME/repos/rice/dotfiles"
alias nrs='sudo nixos-rebuild switch --flake "$DOTFILES/nixos#excalibur"'
alias nrt='sudo nixos-rebuild test --flake "$DOTFILES/nixos#excalibur"'
alias nfu='nix flake update --flake "$DOTFILES/nixos"'
alias ngc='sudo nix-collect-garbage --delete-older-than 14d'

# Reload the smv keyboard layout without logging out
smv-reload() {
  xkbcli compile-keymap --include ~/.config/xkb --include-defaults \
    --layout smv --variant colemak >/dev/null || { echo "smv: compile failed"; return 1; }
  hyprctl eval 'hl.config({input={kb_layout="us"}})' >/dev/null
  hyprctl eval 'hl.config({input={kb_layout="smv, ru"}})' >/dev/null
  echo "smv reloaded"
}

[[ ! -f ~/.secrets.zsh ]] || source ~/.secrets.zsh
