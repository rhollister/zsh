# we definitely want colors
autoload colors
colors

# change the prompt's color based on a hash of the hostname
startcolor=26
darkcolors=(28 {52..60} {88..96} 100 124)

# get an 8bit hash of the hostname
hash=$(hostname -s | md5sum | cut -c1-2) 

# convert to decimal and skip preset colors
(( hostcolor=$((16#$hash))/2+$startcolor+${#darkcolors} ));           

# shift dark colors to more readable colors
index=$darkcolors[(i)$hostcolor]}
if (( index < ${#darkcolors} )); then
 (( hostcolor=index+$startcolor-1 ));

# shift the last 32 colors to be more distinct colors
elif (( hostcolor>=128-32+$#darkcolors+$startcolor )); then
  (( hostcolor=(230-32)+(hostcolor-(128-32+$#darkcolors+$startcolor)) ));
fi;

promptcolor=$(echo -e "\033[38;5;${hostcolor}m")

# preferably hardcode the color
#case `hostname -s` in
#   HOSTNAME1)
#       color=%{$fg_bold[blue]%}
#           ;;
#   HOSTNAME2)
#       color=%{$fg_bold[yellow]%}
#   ;;
#   HOSTNAME3)
#       color=%{$fg[yellow]%}
#   ;;
#   *)
#       color=%{$fg_bold[red]%}
#   ;;

# the prompt itself looks like: hostname /complete/file/path/>
PROMPT="$promptcolor%m %/> %{$fg_no_bold[default]%}"

autoload -U compinit
compinit

# allow tab completion in the middle of a word
setopt COMPLETE_IN_WORD

# keep background process running at full speed
setopt NOBGNICE

# history settings
# save LOTS of history
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.history
# don't save duplicate commands in history 
#  (ie, i don't want to see "ls" 500,000 times)
setopt HIST_IGNORE_ALL_DUPS
setopt autopushd
# don't overwrite history, just append, this makes history much 
#  friendlier when using multiple terminals
setopt INC_APPEND_HISTORY
# if i input a directory, just cd to it
setopt AUTO_CD
setopt EXTENDED_HISTORY
setopt EXTENDED_GLOB
setopt PUSHDMINUS
setopt PUSHDIGNOREDUPS
setopt HIST_NO_STORE
setopt SHARE_HISTORY
setopt LIST_TYPES

# never ever beep ever
setopt NO_BEEP

# auto complete settings
zstyle ':completion:*default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:cd:*:directory-stack' menu yes select
zstyle ':completion:*:expand:*' tag-order all-expansions
zstyle ':completion:*:cd' ignore-parents parent pwd
zstyle ':completion:*:default list-prompt' '%S%M matches%s'

# just typing .. acts like cd ..
alias '..'='cd ..'
# typing cd ... goes up two levels
alias -g ...='../..'
alias -g ....='../../..'
alias -g .....='../../../..'
alias -g ......='../../../../..'
# very handy as i grep output very often
alias -g G="| grep"
# in history show timestamps and how long it took the command to run
alias 'history'='history -Di'
# find in history, you can also just use ctrl+shift+r in zsh
alias 'fh'='history 1 | grep'a
# color listings
alias 'ls'='ls --color'
# much easier to read
alias 'df'='df -H'

# compilation of hacks for ls -l
#  - highlights today's date
#  - highlights most recently modified time(s)
#  - highlights largest file size(s)
#  - colorizes size-units K/M/G/T/P for easy recognition
#  - hides useless 4.0K size for every directory
#  adding/removing columns (eg, ll -i) *will* cause these to break
#   see also: why you should never parse ls: http://mywiki.wooledge.org/ParsingLs
_ll() {
# load ls -l for parsing and highlight todays date
listing=`/bin/ls -vl "$@" --color --time-style="+%b %e %H:%M:%S %s" |
 sed -r "s/^([a-z0-9\-]{10})[^ ]/\1 /" | sed "s/ \(\`date '+%b %e'\`\) / $fg[blue]\1$fg_no_bold[default] /" `

# find the newest modified file, width of the user permission column, and largest file size
IFS=' ' read -A array <<< `echo $listing | awk '
 length($3) > largestwidth { largestwidth=length($3) }
 ($1!~/^d/) { if($5 > largestsize) { largestsize=$5 } }
 ($9 > newesttime) { newesttime=$9 }
 END { printf largestwidth " " largestsize " " newesttime }'`

maxuserwidth=${array[1]}
largestfile=${array[2]}

# load up newesttime as an awk variable, otherwise the condition will fail
echo $listing | awk -v newesttime=${array[3]} '
BEGIN {
 # load up colors for human-readable file sizes
 split("B '"$fg[blue]"'K '"$fg[red]"'M '"$fg[green]"'G '"$fg[yellow]"'T '"$fg[magenta]"'P", type);

 # hide B for bytes
 type[1]=" ";
}
# highlight the most recent timestamp
($9 == newesttime) {
 $8="'"$fg[blue]"'" $8 "'"$fg_no_bold[default]"'"
}
(NR!=1 && $1 && $2 && $3) {
  # highlight the largest file
  if($5 ~ /^'"$largestfile"'$/) { highlight="'"$fg[blue]"'";highlightend="'"$fg_no_bold[default]"'";}

  # convert file sizes into human-readable format
  size=0;
  # start at the largest size unit
  for(i=6; size<1 && i>=0; i--) {
    # convert the file size to the size unit until we get a measurement over 1.0
    size=$5/(2**(10*i))
  }

  # only show a decimal place if the size is <10 has a non-zero in the tenth decimal place
  if(size>=10 || int(size*10)%10==0) { $5=sprintf("%s%4d%s%s",  highlight,size,type[i+2],highlightend); }
  # else print tenth decimal
  else                               { $5=sprintf("%s%4.1f%s%s",highlight,size,type[i+2],highlightend); }

  # hide sizes for directories
  if($1 ~ /^d/) { $5="     ";}

  # print out the fields we want
  printf("%s %-'"$maxuserwidth"'s %s'"$fg_no_bold[default]"' %s %2d'"$fg_no_bold[default]"' %s ",$1,$3,$5,$6,$7,$8);

  # print out the file name (which might have spaces in it)
  for(i=10;i<NF;i++){printf $i OFS}
  print $NF

  # reset highlighting for next record
  highlight="";highlightend="";
}
'

}
alias ll=_ll

# set correct key sequences
autoload zkbd
function zkbd_file() {
    [[ -f ~/.zkbd/${TERM}-${VENDOR}-${OSTYPE} ]] && printf '%s' ~/".zkbd/${TERM}-${VENDOR}-${OSTYPE}" && return 0
    [[ -f ~/.zkbd/${TERM}-${DISPLAY}          ]] && printf '%s' ~/".zkbd/${TERM}-${DISPLAY}"          && return 0
    return 1
}

[[ ! -d ~/.zkbd ]] && mkdir ~/.zkbd
keyfile=$(zkbd_file)
ret=$?
if [[ ${ret} -ne 0 ]]; then
    zkbd
    keyfile=$(zkbd_file)
    ret=$?
fi
if [[ ${ret} -eq 0 ]] ; then
    source "${keyfile}"
else
    printf 'Failed to setup keys using zkbd.\n'
fi
unfunction zkbd_file; unset keyfile ret

# setup key accordingly
[[ -n "${key[Home]}"    ]]  && bindkey  "${key[Home]}"    beginning-of-line
[[ -n "${key[End]}"     ]]  && bindkey  "${key[End]}"     end-of-line
[[ -n "${key[Insert]}"  ]]  && bindkey  "${key[Insert]}"  overwrite-mode
[[ -n "${key[Delete]}"  ]]  && bindkey  "${key[Delete]}"  delete-char
[[ -n "${key[Up]}"      ]]  && bindkey  "${key[Up]}"      up-line-or-history
[[ -n "${key[Down]}"    ]]  && bindkey  "${key[Down]}"    down-line-or-history
[[ -n "${key[Left]}"    ]]  && bindkey  "${key[Left]}"    backward-char
[[ -n "${key[Right]}"   ]]  && bindkey  "${key[Right]}"   forward-char
