# set the default user on first run. the prompt will display user@host when run as other users
if [ -z ${USER+x} ];  then
 USER=`whoami`
fi
if [ -z ${_defaultuser+x} ]; then
 sed -i "1 i\_defaultuser=$USER" ~/.zshrc
_defaultuser=$USER
fi

# we definitely want colors
autoload colors
colors

# ROYGBIP preset colors plus light, dark, and bold/bright modifiers
NORM="\033[38;5;7m"
RED="\033[38;5;203m"
ORANGE="\033[38;5;208m"
YELLOW="\033[38;5;227m"
GREEN="\033[38;5;40m"
BLUE="\033[38;5;39m"
PURPLE="\033[38;5;129m"
LRED="\033[38;5;212m"
LORANGE="\033[38;5;216m"
LYELLOW="\033[38;5;228m"
LGREEN="\033[38;5;120m"
CYAN="\033[38;5;51m"
LBLUE="\033[38;5;81m"
LPURPLE="\033[38;5;171m"
DRED="\033[38;5;124m"
DORANGE="\033[38;5;166m"
DYELLOW="\033[38;5;142m"
DGREEN="\033[38;5;34m"
DBLUE="\033[38;5;31m"
DPURPLE="\033[38;5;165m"
BRED="\033[38;5;196m"
BORANGE="\033[38;5;214m"
BYELLOW="\033[38;5;226m"
BGREEN="\033[38;5;46m"
BBLUE="\033[38;5;21m"
BPURPLE="\033[38;5;201m"

# preset colors for scripts that colorize byte unit sizes (eg K, M, G, etc)
typeset -A magnitudes;
magnitudes[K]=$BLUE;
magnitudes[M]=$RED;
magnitudes[G]=$GREEN;
magnitudes[T]=$YELLOW;
magnitudes[P]=$LPURPLE;
magnitudes[E]=$LBLUE;

# change the prompt color based on a hash of the hostname
 # skip dark colors
 startcolor=26
 # list of more dark colors to skip
 darkcolors=(28 {52..60} {88..96} 100 124)

 # get an 8bit hash of the hostname
 if [[ $USER == $_defaultuser ]]; then
  host=$(hostname -s)
 else
  host=$USER@$(hostname -s)
 fi

 hash=$(echo $host | md5sum | cut -c1-2)

 # convert to decimal and skip first set of dark colors
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

# preferably you should hardcode the prompt color
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
PROMPT="%{$promptcolor%}$host %/> %{$fg_no_bold[default]%}"

# change terminal title for current directory or current running command
case $TERM in
  xterm*)
    # update the the title with the current directory, abbreviate if over 456 pixels (standard MobaXterm tab width without tab number or close button)
    precmd () {
     t=`print -P "%m:%~"`;
     t=`echo $t | sed -r 's/([^:])[^:]*([0-9][0-9]):|([^:])[^:]*([^:]):/\1\2\3\4:/'`;
     oldlen=-1;
     # filter every character in path into four buckets based on character width in pixels
     t1="${t//[^ijlIFT]}";
     t2="${t//[ijlIFTGoQMmWABEKPSVXYCDHNRUw]}";
     t3="${t//[^ABEKPSVXYCDHNRUw]}";
     t4="${t//[^GoQMmW]}";
     while (( ( ( ${#t1} * 150 ) + ( ${#t2} * 178 ) + ( ${#t3} * 190 ) + ( ${#t4} * 201 ) ) > 4560 && ${#t}!=oldlen)) {
       oldlen=${#t};
       t=`echo $t | sed 's/\/\(.\)[^\/][^\/]*\//\/\1\//'`;
       t1="${t//[^ijlIFT]}";
       t2="${t//[ijlIFTGoQMmWABEKPSVXYCDHNRUw]}";
       t3="${t//[^ABEKPSVXYCDHNRUw]}";
       t4="${t//[^GoQMmW]}";
     }; 
     print "\e]0;$t\a"
    }
    # update the title with a timestamp and the current command
    preexec () { print -Pn "\e]0;%T"; print -n " $1\a" }
    ;;
esac

autoload -U compinit
compinit -u

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
# Don't prompt for a huge list, page it!
zstyle ':completion:*:default' list-prompt '%S%M matches%s'
# generate descriptions with magic.
zstyle ':completion:*' auto-description 'specify: %d'

# ls as a directory as soon as successfully cd'd to it
#  (using a function because alias doesn't understand $@)
_cds() { cd $@ && ll }
alias 'cds'=_cds
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
# grep history, you can also just use ctrl+r
alias 'fh'='history 1 | grep'
# color listings
alias 'ls'='ls --color'

# busybox doesn't support ls --time-style, so don't bother with it
# (special case handled because both MobaXterm and VMWare ESXi run BusyBox)
if [[ -f /bin/busybox ]]; then
 sed -i "s@\(\-[f] /bin/busybox\)@-z 1 \&\& \1@" .zshrc
 sed -i "s/ --[t]ime-style/ | #--time-style/"    .zshrc
 sed -i "s/timecheck=\'/timecheck=\"\" #\'/"     .zshrc
 sed -i "s/timecolumn=\'10\'/timecolumn='9'/"    .zshrc
fi

# compilation of hacks for ls -l
#  - highlights today's date
#  - highlights most recently modified time(s)
#  - displays how far ago last modified time was (10mo, 7d, 2s, etc)
#  - highlights largest file size(s)
#  - colorizes byte magnitudes K, M, G, etc for easy recognition
#  - hides useless 4.0K size for every directory
#  adding/removing columns (eg, ll -i) *will* cause these to break
#   see also: why you should never parse ls: http://mywiki.wooledge.org/ParsingLs
_ll() {
# by default highlight newest time, but don't if using busybox
timecheck='($9 > newesttime) { newesttime=$9 } '
timecolumn='10'

# load ls -l for parsing and remove SELinux permission bit
eval $(/bin/ls -vl "$@" --color --time-style='+%b %e %H:%M:%S %s' |
 sed -r "s/^([a-z0-9\-]{10})[^ ]/\1 /" |
 # find the newest modified file, width of the user column, and largest file size
 awk '
 BEGIN { 
  today=strftime("%b%e");
  largestuserwidth=0;
  largestsize=0;
  newesttime=0;
  largestagowidth=0;
  FS=" " 
 }
 length($3) > largestuserwidth { largestuserwidth=length($3) }
 ($1!~/^d/) { if($5 > largestsize) { largestsize=$5 } }
 '"$timecheck"' 
 {
  # highlight todays date
  date=sprintf("%s%2s",$6,$7)
  if(date == today) {
   $6="'"$BLUE"'" $6
  }
  # calculate last modified ago column
  u="s"
  ago=strftime("%s")-$9
  if( ago > 59 ) { u="i"; ago=ago / 60
  if( ago > 59 ) { u="h"; ago=ago / 60
  if( ago > 23 ) { u="d"; ago=ago / 24
  if( ago > 29 ) { u="M"; ago=ago / 30
  if( ago > 11 ) { u="y"; ago=ago / 12
  } } } } }
  $2=sprintf("%.0f%s",ago,u)  
  if (length($2) > largestagowidth) { largestagowidth=length($2); }
  if ($2 ~ "M" ) { pad = 1 }
 }
 {
  listing=listing "\\n" $0
 }
 # use eval to save these values as zsh variables
 END { printf "listing=\""listing"\";largestuserwidth=\""largestuserwidth"\";largestsize=\""largestsize"\";newesttime=\""newesttime"\";largestagowidth=\""largestagowidth"\";pad=\""pad"\"" }')

if [[ $pad == 1 ]]; then pad=" "; else pad=""; fi
magnitudestr="${magnitudes[K]}K"
for m in "M" "G" "T" "P" "E";do
  magnitudestr="$magnitudestr~${magnitudes[$m]}$m";
done

# load up newesttime as an awk variable, otherwise the condition will fail
echo $listing | awk -v newesttime=$newesttime -v magnitudestr=" ~${magnitudestr}" '
BEGIN {
 split(magnitudestr, magnitudes, /~/)
}
# highlight the most recent timestamp
($9 == newesttime) {
 $8="'"$BLUE"'" $8 "'"$NORM"'"
}
($1 && $2 && $3) {
  # highlight the largest file
  if($5 ~ /^'"$largestsize"'$/) { highlight="'"$BLUE"'";highlightend="'"$NORM"'";}

  if($5 < 0) { $5="     ";}
  else{
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
  }
  
  # hide sizes for directories
  if($1 ~ /^d/) { $5="     ";}

  # if showing the modified-ago column, colorize the the units
  if('$timecolumn'==10) {
   unit=substr($2,length($2))
   $2=sprintf("%'$largestagowidth's'"$NORM"'", $2)
   
   if( unit == "s" ) { sub(/s/, "'"$BRED"'s'"$pad"'", $2) }
   else if( unit == "i" ) { sub(/i/, "'"$ORANGE"'m'"$pad"'", $2) }
   else if( unit == "h" ) { sub(/h/, "'"$DGREEN"'h'"$pad"'", $2) }
   else if( unit == "d" ) { sub(/d/, "'"$DBLUE"'d'"$pad"'", $2) }
   else if( unit == "M" ) { sub(/M/, "'"$LPURPLE"'mo", $2) }
   else if( unit == "y" ) { sub(/y/, "'"$PURPLE"'y'"$pad"'", $2) }
   # print out the fields we want
   printf("%s %-'"$largestuserwidth"'s %s'"$NORM"' %s %2d'"$NORM"' %s %s ",$1,$3,$5,$6,$7,$8,$2);
  } else {
   # print out the fields we want
   printf("%s %-'"$largestuserwidth"'s %s'"$NORM"' %s %2d'"$NORM"' %s ",$1,$3,$5,$6,$7,$8);
  }

  # print out the file name (which might have spaces in it)
  for(i='$timecolumn';i<NF;i++){printf $i OFS}
  print $NF

  # reset highlighting for next record
  highlight="";highlightend="";
}
'
}
alias ll=_ll

# set correct key sequences
autoload zkbd

# default keyset, works with most terminals
typeset -g -A key
key[F1]='^[OP'
key[F2]='^[OQ'
key[F3]='^[OR'
key[F4]='^[OS'
key[F5]='^[[15~'
key[F6]='^[[17~'
key[F7]='^[[18~'
key[F8]='^[[19~'
key[F9]='^[[20~'
key[F10]='^[[21~'
key[F11]='^[[22~'
key[F12]='^[[24~'
key[Backspace]='^H'
key[Insert]='^[[2~'
key[Home]='^[[H'
key[PageUp]='^[[5~'
key[Delete]='^[[3~'
key[End]='^[[F'
key[PageDown]='^[[6~'
key[Up]='^[[A'
key[Left]='^[[D'
key[Down]='^[[B'
key[Right]='^[[C'
key[Menu]=''''

# by default, skip using zkbd to set key bindings, use if keys aren't set properly
if [[ -z 1 ]];then
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
fi

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
${DPURPLE}DPURPLE$NORM"

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
listing=$(/bin/df -h | sed -r -e "s/^(Filesystem[ ]+)Size([ ]+)Used([ ]+)Avail(able)?([ ]+)Use%/\1`echo $LBLUE`Size\2`echo $LORANGE`Used\3`echo $LGREEN`Avail\4\5`echo $LGREEN`Use%`echo $NORM`/" -e "s/([0-9.]+[KMGTPEZY ][ ]*)([0-9.]+[KMGTPEZY ][ ]*)([0-9.]+[KMGTPEZY ][ ]*)([0-9]+\%) \//`echo $LBLUE`\1`echo $LORANGE`\2`echo $LGREEN`\3`echo $LGREEN`\4 `echo $NORM`\//g");

# loop through each byte magnitude and colorize each instance found
for u in ${(k)magnitudes};
  do listing=$(echo $listing | sed -r -e "s/([0-9.]+)$u([ ]+[^ ]+[0-9.]+[^A-Z ]*[KMGTPEZY ][ ]*[^ ]+[0-9.]+[^A-Z ]*[KMGTPEZY ][ ]*[^ ]+[0-9]+\% [^/]+\/)/\1`echo ${magnitudes[$u]}`$u\2/g" -e "s/([0-9.]+)$u([ ]+[^ ]+[0-9.]+[^A-Z ]*[KMGTPEZY ][ ]*[^ ]+[0-9]+\% [^/]+\/)/\1`echo ${magnitudes[$u]}`$u\2/g" -e "s/([0-9.]+)$u([ ]+[^ ]+[0-9]+\% [^/]+\/)/\1`echo ${magnitudes[$u]}`$u\2/g");
done;

# print output with >80% usage in orange, >90% in red, and >98% in bright red
echo $listing | sed -r -e "s/(8[0-9]\% [^/]+\/)/`echo $LORANGE`\1/g" -e "s/(9[0-7]\% [^/]+\/)/`echo $RED`\1/g" -e "s/(9[8-9]\% [^/]+\/)/`echo $BRED`\1/g" -e "s/(100\% [^/]+\/)/`echo $BRED`\1/g"
}
alias df=_df

