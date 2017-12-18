# zsh

My .zshrc with scripts for window title changes, enhanced ls, and prompt color based on hostname.

## Terminal title and colorized `ll`

1. Terminal title is set to the smartly abbreviated hostname and current directory
1. Terminal title during execution of a command is set to time of execution and command name
1. Prompt is set to the hostname and current directory. Each host is automatically given a unique color.
1. `ll` enhanced directory listing 
   1. Largest file size is highlighted in blue
   1. Newest file time is highlighted in blue
   1. Today's date in file time is highlighted in blue
   1. Displays age since file was modified

![Screenshot](https://github.com/rhollister/zsh/raw/master/Screenshot_1.png)

## Colorized `df`
   1. Columns are colorized for easy reading
   1. Disk usage percentages are colored based on critical level (80%, 90%, then 98%)

![Screenshot](https://github.com/rhollister/zsh/raw/master/Screenshot_2.png)

## `colortable`

1. Displays list of color names defined in script
1. Displays table of ANSI color codes

![Screenshot](https://github.com/rhollister/zsh/raw/master/Screenshot_3.png)
