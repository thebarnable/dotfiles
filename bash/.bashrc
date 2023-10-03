[[ $- != *i* ]] && return # don't load bashrc if shell not interactive

[ -r /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion # source bash_completion if exists
complete -cf sudo # enable completion for sudo as well
#xhost +local:root > /dev/null 2>&1 # allow root to connect to X server

# enable git prompt information
if [[ -e ~/.git-prompt.sh ]]; then
  source ~/.git-prompt.sh
  GIT_PS1_SHOWDIRTYSTATE=1           # '*'=unstaged, '+'=staged
  #GIT_PS1_SHOWSTASHSTATE=1         # '$'=stashed
  #GIT_PS1_SHOWUNTRACKEDFILES=1     # '%'=untracked
  GIT_PS1_SHOWUPSTREAM="verbose"     # 'u='=no difference, 'u+1'=ahead by 1 commit
  GIT_PS1_STATESEPARATOR=''          # No space between branch and index status
else
  function __git_ps1 { # declare dummy function if git-prompt.sh is not available
    true 
  }
fi
PROMPT_DIRTRIM=3 # shorten directories deeper than 3 subdirs

# set prompt
use_color=true
if ${use_color} ; then
	if [[ ${EUID} == 0 ]] ; then # if root
    PS1='\[\033[01;31m\][\u@\h\[\033[01;36m\] \w$(__git_ps1 " (%s)")\[\033[01;31m\]]\$\[\033[00m\] '
  else
		PS1='\[\033[01;32m\][\u@\h\[\033[01;37m\] \w$(__git_ps1 " (%s)")\[\033[01;32m\]]\$\[\033[00m\] '
	fi
else
	if [[ ${EUID} == 0 ]] ; then # if root
		PS1='\u@\h \W \$ '
	else
		PS1='\u@\h \w \$ '
	fi
fi

# aliases
alias ls='ls --color=auto'
alias grep='grep --colour=auto'
alias cp="cp -i"                          # confirm before overwriting something
alias mv='mv -i'
alias df='df -h'                          # human-readable sizes
alias free='free -m'                      # show sizes in MB
alias np='nano -w PKGBUILD'
alias more=less
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias cd..='cd ..'
alias ll='ls -lah'
alias bc='bc -l'
alias vim='vim -u ~/.config/vim/.vimrc'
alias vi='vim -u ~/.config/vim/.vimrc'
alias notes='cd ~/Nextcloud/Dokumente/Notizbuch && obsidian . & > /tmp/obsidian.log'

# shell options
shopt -s checkwinsize # Bash won't get SIGWINCH if another process is in the foreground.
shopt -s expand_aliases
shopt -s histappend # enable history appending instead of overwriting

#source /home/tim/Tools/miniconda3/etc/profile.d/conda.sh # conda setup

# environment variables
#export ALSA_CARD="PCH" # default sound card
#export PATH=$PATH:/opt/cuda/bin
#export STEAM_RUNTIME=1
export PATH=/home/tim/.local/bin:$PATH
#source /home/tim/.local/lib/python3.10/site-packages/nest-c566adbc8/bin/nest_vars.sh
export VIVADO_PATH=/opt/Xilinx/Vivado/2019.2/
export VITIS_PATH=/opt/Xilinx/Vitis/2019.2/
[ -r /home/tim/.byobu/prompt ] && . /home/tim/.byobu/prompt   #byobu-prompt#
#export PYTHONPATH="/home/tim/Projects/noisysnns":"/home/tim/.local/lib/python3.10":$PYTHONPATH
export PYTHONPATH="/home/tim/Projects/noisysnns":$PYTHONPATH
export LD_LIBRARY_PATH=/home/tim/.local/lib/python3.10/site-packages/nvidia_cublas_cu11-11.10.3.66-py3.10-linux-x86_64.egg/nvidia/cublas/lib:$LD_LIBRARY_PATH # pytorch fixup 1
export LD_LIBRARY_PATH=/home/tim/.local/lib/python3.10/site-packages/nvidia_cudnn_cu11-8.5.0.96-py3.10-linux-x86_64.egg/nvidia/cudnn/lib:$LD_LIBRARY_PATH # pytorch fixup 2


# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/tim/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/tim/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/tim/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/tim/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

