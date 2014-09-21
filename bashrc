#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

#aliases
alias ls='ls --color=auto'
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

alias enable='sudo systemctl enable'
alias start='sudo systemctl start'
alias disable='sudo systemctl disable'
alias stop='sudo systemctl stop'

alias tgzc='tar -cvzf'
alias tgzx='tar -xvzf'
alias tarc='tar -cvf'
alias tarx='tar -xvf'


alias pylab='ipython --pylab'

alias conrout='ssh root@192.168.1.1'
alias conpi='ssh 192.168.1.20'
alias ncpi='ncmpc --host=192.168.1.20'

alias vimaw='vim ~/.config/awesome/rc.lua'

alias r='ranger'

#redefines
alias nemo='nemo --no-desktop'
# cd and ls in one
cl() {
if [[ -d "$1" ]]; then
  cd "$1"
  ls
else
  echo "bash: cl: '$1': Directory not found"
fi
}

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
