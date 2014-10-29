#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

## aliases
# general
alias ls='ls --color=auto'
alias l1='ls --color=auto -1'
alias ll='ls --color=auto -al'
alias grep='grep --color=auto --exclude=\*~'
alias ..='cd ..'
alias ...='cd ../..'


# pacman
alias pacin='sudo pacman -S'
alias pacout='sudo pacman -Rns'
alias pacs='pacman -Ss'
alias pacsg='pacman -Sg'
alias pacupg='sudo pacman -Syu'
alias pacupd='sudo pacman -Sy'
alias pacinfo='pacman -Si'
alias paclinfo='pacman -Qi'
alias pacls='pacman -Qs'
alias pacfiles='pacman -Ql'
alias pacown='pacman -Qo'
alias aurin='aurget -Sy'
alias aurs='aurget -Ss'
alias aurupg='aurget -Syu'
alias aurd='aurget -Sd'

alias mics='makepkg -ics'

# systemd
alias enable='sudo systemctl enable'
alias start='sudo systemctl start'
alias disable='sudo systemctl disable'
alias stop='sudo systemctl stop'

alias tgzc='tar -cvzf'
alias tgzx='tar -xvzf'
alias tarc='tar -cvf'
alias tarx='tar -xvf'

alias update-grub='sudo grub-mkconfig -o /boot/grub/grub.cfg'


alias pylab='ipython --pylab'

alias conrout='ssh root@192.168.1.1'
alias conpi='ssh 192.168.1.20'
alias ncpi='ncmpc --host=192.168.1.20'

alias vimaw='vim ~/.config/awesome/rc.lua'

alias r='ranger'

# other redefines
alias nemo='nemo --no-desktop'

## functions
cl() { cd "$1" && ls; }
mc() { mkdir -p "$1" && cd "$1"; }
vimsh() { [ ! -e "$1" ] && echo "#!/usr/bin/bash" > "$1" && chmod +x "$1" && vim "$1"; }

#PS1='[\u@\h \W]\$ '
#PS1='\[\e[1;32m\][\u@\h \W]\$\[\e[0m\] '
export GIT_PS1_SHOWDIRTYSTATE=y
export GIT_PS1_SHOWSTASHSTATE=y
export GIT_PS1_SHOWUNTRACKEDFILES=y
source /usr/share/git/completion/git-prompt.sh
#PS1='[\u@\h \W$(__git_ps1 " (%s)")]\$ '
PS1="\[\e[1;35m\][\[\e[1;31m\]\u\[\e[1;32m\]@\h \[\e[1;33m\]\W\[\e[1;34m\]\$(__git_ps1)\[\e[1;35m\]]\$ \[\e[0m\]"
#PS1="\[\$(if [[ \$? != 0 ]]; then echo \"\[\e[1;37m\]\342\234\227 \"; fi)\e[1;35m\][\e[1;31m\]\u\e[1;32m\]@\h \e[1;33m\]\W\e[1;34m\]$(__git_ps1)\e[1;35m\]]\$ \[\e[0m\]"

export EDITOR=vim
export PATH=$HOME/.local/bin:$PATH
#export LD_LIBRARY_PATH=$HOME/.local/lib
