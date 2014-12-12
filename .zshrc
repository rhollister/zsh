# we definitely want colors
autoload colors
colors

# ROYGBIP preset colors plus light, dark, and bold/bright modifiers
export NORM=`echo -e "\033[38;5;7m"`
export RED=`echo -e "\033[38;5;203m"`
export ORANGE=`echo -e "\033[38;5;208m"`
export YELLOW=`echo -e "\033[38;5;227m"`
export GREEN=`echo -e "\033[38;5;40m"`
export BLUE=`echo -e "\033[38;5;39m"`
export PURPLE=`echo -e "\033[38;5;129m"`
export LRED=`echo -e "\033[38;5;212m"`
export LORANGE=`echo -e "\033[38;5;216m"`
export LYELLOW=`echo -e "\033[38;5;228m"`
export LGREEN=`echo -e "\033[38;5;120m"`
export CYAN=`echo -e "\033[38;5;51m"`
export LBLUE=`echo -e "\033[38;5;81m"`
export LPURPLE=`echo -e "\033[38;5;171m"`
export DRED=`echo -e "\033[38;5;124m"`
export DORANGE=`echo -e "\033[38;5;166m"`
export DYELLOW=`echo -e "\033[38;5;142m"`
export DGREEN=`echo -e "\033[38;5;34m"`
export DBLUE=`echo -e "\033[38;5;31m"`
export DPURPLE=`echo -e "\033[38;5;165m"`
export BRED=`echo -e "\033[38;5;196m"`
export BORANGE=`echo -e "\033[38;5;214m"`
export BYELLOW=`echo -e "\033[38;5;226m"`
export BGREEN=`echo -e "\033[38;5;46m"`
export BBLUE=`echo -e "\033[38;5;21m"`
export BPURPLE=`echo -e "\033[38;5;201m"`

# preset colors for scripts that colorize byte unit sizes (eg K, M, G, etc)
typeset -A magnitudes;magnitudes[K]=$BLUE;magnitudes[M]=$RED;magnitudes[G]=$GREEN;magnitudes[T]=$YELLOW;magnitudes[P]=$LPURPLE;magnitudes[E]=$LBLUE;

# change the prompt's color based on a hash of the hostname
startcolor=26
darkcolors=(28 {52..60} {88..96} 100 124)

# get an 8bit hash of the hostname
hash=$(hostname -s | md5sum | cut -c1-2) 

# convert to decimal and skip preset colors
(( hostcolor=$((16#$hash))/2+$startcolor+${#darkcolors} ));           

# shift dark colors to more readable colors
index=$darkcolors[(i)$hostcolor]
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
PROMPT="%{$promptcolor%}%m %/> %{$fg_no_bold[default]%}"

# change terminal title
case $TERM in
  xterm*)
    # update the the title with the current directory, abbreviate if over 25 characters
    precmd () {t=`print -P "%m:%~"`; if (( ${#t}>25 )); then t=`echo $t | sed -r 's/([^:])[^:]*([0-9][0-9]):|([^:])[^:]*([^:]):/\1\2\3\4:/'`;oldlen=-1;while (( ${#t}>25 && ${#t}!=oldlen)) {oldlen=${#t};t=`echo $t | sed 's/\/\(.\)[^\/][^\/]*\//\/\1\//'`;};fi; print "\e]0;$t\a"}
    # update the title with a timestamp and the current process
    preexec () { print -Pn "\e]0;%* $1\a" }
    ;;
esac


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

# compilation of hacks for ls -l
#  - highlights today's date
#  - highlights most recently modified time(s)
#  - highlights largest file size(s)
#  - colorizes byte magnitudes K, M, G, etc for easy recognition
#  - hides useless 4.0K size for every directory
#  adding/removing columns (eg, ll -i) *will* cause these to break
#   see also: why you should never parse ls: http://mywiki.wooledge.org/ParsingLs
_ll() {
# load ls -l for parsing and highlight todays date
listing=`/bin/ls -vl "$@" --color --time-style="+%b %e %H:%M:%S %s" |
 sed -r "s/^([a-z0-9\-]{10})[^ ]/\1 /" | sed "s/ \(\`date '+%b %e'\`\) / ${BLUE}\1$BLUE /" `

# find the newest modified file, width of the user permission column, and largest file size
IFS=' ' read -A array <<< `echo $listing | awk '
 length($3) > largestwidth { largestwidth=length($3) }
 ($1!~/^d/) { if($5 > largestsize) { largestsize=$5 } }
 ($9 > newesttime) { newesttime=$9 }
 END { printf largestwidth " " largestsize " " newesttime }'`

maxuserwidth=${array[1]}
largestfile=${array[2]}
magnitudestr="${magnitudes[K]}K"
for m in "M" "G" "T" "P" "E";do
  magnitudestr="$magnitudestr~${magnitudes[$m]}$m";
done
# load up newesttime as an awk variable, otherwise the condition will fail
echo $listing | awk -v newesttime=${array[3]} -v magnitudestr=" ~${magnitudestr}" '
BEGIN {
 split(magnitudestr, magnitudes, /~/)
}
# highlight the most recent timestamp
($9 == newesttime) {
 $8="'"$BLUE"'" $8 "'"$NORM"'"
}
(NR!=1 && $1 && $2 && $3) {
  # highlight the largest file
  if($5 ~ /^'"$largestfile"'$/) { highlight="'"$BLUE"'";highlightend="'"$NORM"'";}

  # convert file sizes into human-readable format
  size=0;
  # start at the largest size unit
  for(i=6; size<1 && i>=0; i--) {
    # convert the file size to the size unit until we get a measurement over 1.0
    size=$5/(2**(10*i))
  }

  # only show a decimal place if the size is <10 has a non-zero in the tenth decimal place
  if(size>=10 || int(size*10)%10==0) { $5=sprintf("%s%4d%s%s",  highlight,size,magnitudes[i+2],highlightend); }
  # else print tenth decimal
  else                               { $5=sprintf("%s%4.1f%s%s",highlight,size,magnitudes[i+2],highlightend); }

  # hide sizes for directories
  if($1 ~ /^d/) { $5="     ";}

  # print out the fields we want
  printf("%s %-'"$maxuserwidth"'s %s'"$NORM"' %s %2d'"$NORM"' %s ",$1,$3,$5,$6,$7,$8);

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

# setup keys accordingly
[[ -n "${key[Home]}"    ]]  && bindkey  "${key[Home]}"    beginning-of-line
[[ -n "${key[End]}"     ]]  && bindkey  "${key[End]}"     end-of-line
[[ -n "${key[Insert]}"  ]]  && bindkey  "${key[Insert]}"  overwrite-mode
[[ -n "${key[Delete]}"  ]]  && bindkey  "${key[Delete]}"  delete-char
[[ -n "${key[Up]}"      ]]  && bindkey  "${key[Up]}"      up-line-or-history
[[ -n "${key[Down]}"    ]]  && bindkey  "${key[Down]}"    down-line-or-history
[[ -n "${key[Left]}"    ]]  && bindkey  "${key[Left]}"    backward-char
[[ -n "${key[Right]}"   ]]  && bindkey  "${key[Right]}"   forward-char

# print out pretty tables of the ANSI colors
#  default prints two tables side-by-side
#  optional -n parameter prints tables one after another
_colortable() {
echo "${LRED}LRED
${RED}RED
${BRED}BRED
${DRED}DRED
${LORANGE}LORANGE
${ORANGE}ORANGE
${BORANGE}BORANGE
${DORANGE}DORANGE
${LYELLOW}LYELLOW
${YELLOW}YELLOW
${BYELLOW}BYELLOW
${DYELLOW}DYELLOW
${LGREEN}LGREEN
${GREEN}GREEN
${BGREEN}BGREEN
${DGREEN}DGREEN
${CYAN}CYAN
${LBLUE}LBLUE
${BLUE}BLUE
${BBLUE}BBLUE
${DBLUE}DBLUE
${LPURPLE}LPURPLE
${PURPLE}PURPLE
${BPURPLE}BPURPLE
${DPURPLE}DPURPLE"

if [[ "$1" == "-n" ]]; then
 echo "Alternate view:"
 for i in {0..36}; do
  for j in {0..6}; do
   (( j=j*36 ))
   (( val=j+ i/6+(6*i)%36 ))
   if  (( val < 16 )); then (( val=0 )); fi
   printf "%b%03i%s%b " "\033[38;5;${val}m" "$val" ":Test" "\033[m"
  done
  printf "\n"
 done
 echo "\nNormal view:"
else
 echo "\nNormal view:                                                   Alternate view:"
fi

for i in {0..35}; do
 for j in {0..6}; do
  (( j=j*36 ))
  (( val=j+i ))
  printf "%b%03i%s%b " "\033[38;5;${val}m" "$val" ":Test" "\033[m"
 done
 printf "   "
 if [[ "$1" != "-n" ]]; then
  for j in {0..6}; do
   (( j=j*36 ))
   (( val=j+ i/6+(6*i)%36 ))
   if  (( val < 16 )); then (( val=0 )); fi
   printf "%b%03i%s%b " "\033[38;5;${val}m" "$val" ":Test" "\033[m"
  done
 fi
 printf "\n"
done
echo
}
alias colortable=_colortable

# ridiculously overcomplicated colorized df
#  this would be much cleaner with a full regex engine that supported lookarounds, 
#  but using sed for cross platform compatibility
_df() {

# colorize the Size, Used, Available, and Use% columns
listing=`/bin/df -h | sed -r -e "s/^(Filesystem[ ]+)Size([ ]+)Used([ ]+)Available([ ]+)Use%/\1${LBLUE}Size\2${LORANGE}Used\3${LGREEN}Available\4${LGREEN}Use%${NORM}/" -e "s/([0-9.]+[KMGTPEZY ][ ]*)([0-9.]+[KMGTPEZY ][ ]*)([0-9.]+[KMGTPEZY ][ ]*)([0-9]+\%) \//${LBLUE}\1${LORANGE}\2${LGREEN}\3${LGREEN}\4 ${NORM}\//g"`;

# loop through each byte magnitude and colorize each instance found 
for u in ${(k)magnitudes};
  do listing=`echo $listing | sed -r -e "s/([0-9.]+)$u([ ]+[^ ]+[0-9.]+[^A-Z ]*[KMGTPEZY ][ ]*[^ ]+[0-9.]+[^A-Z ]*[KMGTPEZY ][ ]*[^ ]+[0-9]+\% [^/]+\/)/\1${magnitudes[$u]}$u\2/g" -e "s/([0-9.]+)$u([ ]+[^ ]+[0-9.]+[^A-Z ]*[KMGTPEZY ][ ]*[^ ]+[0-9]+\% [^/]+\/)/\1${magnitudes[$u]}$u\2/g" -e "s/([0-9.]+)$u([ ]+[^ ]+[0-9]+\% [^/]+\/)/\1${magnitudes[$u]}$u\2/g"`;
done;

# print output with >80% usage in orange, >90% in red, and >98% in bright red
echo $listing | sed -r -e "s/(8[0-9]\% [^/]+\/)/$LORANGE\1/g" -e "s/(9[0-7]\% [^/]+\/)/$RED\1/g" -e "s/(9[8-9]\% [^/]+\/)/$BRED\1/g" -e "s/(100\% [^/]+\/)/$BRED\1/g"
}
alias df=_df
