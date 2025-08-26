# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="/home/speakintelnet/.oh-my-zsh"

PATH="$HOME/.local/bin:/opt/nvim-linux64/bin:$HOME/.config/emacs/bin:$PATH"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
	git
	virtualenv
	systemd
	thefuck
	python
	pip
	zsh-autosuggestions
	toolbox
)

source $ZSH/oh-my-zsh.sh

if [[ "dumb" == "$TERM" ]]; then
  export TERM=xterm-256color
fi


# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

