# we definitely want colors
autoload colors
colors

# change the prompt's color based on which server we're on
#  if i'm not on a usual server, make the hostname red
#  with lots of terminals open it can be easy to run a command on the wrong box
color=%{$fg_bold[white]%}
#case `hostname -s` in
#   some_servername)
#       color=%{$fg_bold[blue]%}
#           ;;
#   some_other_servername)
#       color=%{$fg_bold[yellow]%}
#   ;;
#   yet_another_servername)
#       color=%{$fg[yellow]%}
#   ;;
#   *)
#       color=%{$fg_bold[red]%}
#   ;;

# the prompt itself looks like: hostname /complete/file/path/>
PROMPT="$color%m %/> %{$fg_no_bold[default]%}"

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
# CAUTION: THESE ARE HUGE HACKS and they look for hard-coded columns, 
#  adding/removing columns (eg, ll -i) *will* cause these to break
#   see also: why you should never parse ls: http://mywiki.wooledge.org/ParsingLs
_ll() { 
# load ls -l for parsing
listing=`/bin/ls -l "$@" --color --time-style="+%b %e %H:%M:%S %s" | 
  sed "s/ \(\`date '+%b %e'\`\) / $fg[blue]\1$fg_no_bold[default] /" `

# find the newest modified file
newesttime=`echo $listing | awk '$9 > max { max=$9 }; END { print max }'`
maxuserwidth=`echo $listing | awk 'length($3) > max { max=length($3) }; END { print max }'`

# highlight the most recent time and strip out epoch times
listing=`echo $listing | sed "s/ \([0-9][0-9]:[0-9][0-9]:[0-9][0-9]\) $newesttime / $fg[blue]\1$fg_no_bold[default] /" | sed "s/ \([0-9][0-9]:[0-9][0-9]:[0-9][0-9]\) [0-9]*/ \1 /" `

# find the largest file size
largestfile=`echo $listing | awk '$1!~/^d/ { if($5 > max) { max=$5 }}; END { print max }'`

listing=`echo $listing | awk '
BEGIN {   
 # load up colors for human-readable file sizes
 split("B '"$fg[blue]"'K '"$fg[red]"'M '"$fg[green]"'G '"$fg[yellow]"'T '"$fg[yellow]"'P", type);

 # hide B for bytes
 type[1]=" ";
}
{
 if(NR!=1 && $1 && $2 && $3)
 {
  # if this is the largest file, highlight it blue
  if($5 ~ /^'"$largestfile"'$/) { highlight="'"$fg[blue]"'";highlightend="'"$fg_no_bold[default]"'";}

  # convert file sizes into human-readable format
  size=0; for(i=6;size<1&&i>=0;i--){size=$5/(2**(10*i))}

  # if the size is greater than 10, dont bother displaying decimals
  if(size>=10 || int(size*10)%10==0) { $5=sprintf("%s%4d%s%s",  highlight,size,type[i+2],highlightend);}
  # else print tenth decimal
  else {                               $5=sprintf("%s%4.1f%s%s",highlight,size,type[i+2],highlightend);}

  #hide directory sizes
  if($1 ~ /^d/) { $5="     ";}

  # turn off highlighting
  highlight="";highlightend="";

  # print out the fields we want
  printf("%s %-'"$maxuserwidth"'s %s'"$fg_no_bold[default]"' %s %2d'"$fg_no_bold[default]"' ",$1,$3,$5,$6,$7);

  # print out the file name (which might have spaces in it)
  for(i=8;i<NF;i++){printf("%s%s",$i,OFS)} 
  print $NF 
 }
}
'`
echo $listing;
}
alias ll=_ll

