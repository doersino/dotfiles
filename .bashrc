#!/bin/bash

# some zsh's witnesses are at the door, let's shut them out
export BASH_SILENCE_DEPRECATION_WARNING=1

# required (?) for ruby in catalina or later, see https://jekyllrb.com/docs/installation/macos/
export SDKROOT=$(xcrun --show-sdk-path)


##########
## PATH ##
##########

PATH_NODE="./node_modules/.bin"
PATH_RUBY="/Users/noah/.gem/ruby/2.6.0/bin"  # need to change on ruby updates (i.e. macos updates)
PATH_PIPX="/Users/noah/.local/bin"
PATH_PG="/Applications/Postgres.app/Contents/Versions/10/bin"  # need to change on pg updates
PATH_SMERGE="/Applications/Sublime Merge.app/Contents/SharedSupport/bin/"
PATH_SUBL="/Applications/Sublime Text.app/Contents/SharedSupport/bin/"
export PATH="$PATH_NODE:$PATH_PIPX:$PATH_RUBY:$PATH:$PATH_PG:$PATH_SUBL:$PATH_SMERGE"


######################################
## HISTORY, SHELL, AND LESS OPTIONS ##
######################################

# read this number of lines into history buffer on startup
export HISTSIZE=1000000

# HISTFILESIZE is set *after* bash reads the history file (which is done after
# reading any configs like .bashrc). If it is unset at this point it is set to
# the same value as HISTSIZE. Therefore we must set it to NIL, in which case it
# isn't "unset", but doesn't have a value either, enabling us to keep an
# essentially infite history
export HISTFILESIZE=""

# don't put duplicate lines in the history, ignore same sucessive entries, and
# ignore lines that start with a space
export HISTCONTROL=ignoreboth

# require ctrl-D to be pressed twice, not once, in order to exit
export IGNOREEOF=1

# shell options
shopt -s histappend  # merge session histories
shopt -s cmdhist     # combine multiline commands in history
shopt -s cdspell     # make cd try to fix typos

bind '"\e[B": history-search-forward'   # instead of just walking the history,
                                        # perform a search on up...
bind '"\e[A": history-search-backward'  # ...and down arrow press
bind 'set completion-ignore-case on'    # case-insensitive cd completion
bind 'set show-all-if-ambiguous on'     # remove the need to press Tab twice
                                        # when there is more than one match

# colored man pages
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'         # end the info box
export LESS_TERMCAP_so=$'\E[01;42;30m'  # begin the info box
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

# hakase no suki nano nano
export EDITOR=nano

# keep git from speaking german
export LC_ALL=en_US.UTF-8


####################
## COMMAND PROMPT ##
####################

# source git prompt
if [ -e /usr/local/etc/bash_completion.d/git-prompt.sh ]; then
    source /usr/local/etc/bash_completion.d/git-prompt.sh
    GIT_PS1_SHOWDIRTYSTATE=1
    GIT_PS1_SHOWSTASHSTATE=1
    GIT_PS1_SHOWUNTRACKEDFILES=1
    GIT_PS1_SHOWUPSTREAM="verbose"
fi

# set up the command prompt
function __prompt_command() {

    # initialize
    local EXIT=$?
    PS1=""

    # color green or red depending on the previous command's exit code
    if [ $EXIT -eq 0 ]; then
        PS1+="\[\033[1;32m\]"
    else
        PS1+="\[\033[1;31m\]"
    fi

    # git prompt, which we'll store in a variable for now
    GITPROMPT=""
    GITPROMPTLEN=""
    if declare -f __git_ps1 > /dev/null; then
        GITPROMPT="$(__git_ps1 "(%s)")"
        GITPROMPTLEN="$(echo "$GITPROMPT" | wc -c | xargs)"
    fi

    # start first line
    PS1+="["

    # print exit code, but only if it's non-zero
    EXITLEN="0"
    if [ ! $EXIT -eq 0 ]; then
        PS1+="$EXIT "
        EXITLEN="$(echo $EXIT | wc -c | xargs)"
    fi

    # compute maximum length of directory string (this does not account for
    # double-width characters, oh well)
    #                             [              ]                   date
    MAX_PWD_LENGTH=$(($COLUMNS - (1 + $EXITLEN + 1 + $GITPROMPTLEN + 8)))

    PWD=$(pwd)

    # if truncated, replace truncated part of directory string with this
    REPLACE="..."

    # portion of path that's within $HOME, or entire path if not in $HOME
    RESIDUAL=${PWD#$HOME}

    # determine whether we are in $HOME or not
    PREFIX=""
    if [ X"$RESIDUAL" != X"$PWD" ]
    then
        PREFIX="~"
    fi

    # make sure the first few characters of the path are always shown
    PREFIX="$PREFIX"${RESIDUAL:0:12}
    RESIDUAL=${RESIDUAL:12}

    # check if residual path needs truncating to keep the total length below
    # $MAX_PWD_LENGTH, compensate for replacement string
    TRUNC_LENGTH=$(($MAX_PWD_LENGTH - ${#PREFIX} - ${#REPLACE} - 1))
    NORMAL=${PREFIX}${RESIDUAL}
    if [ ${#NORMAL} -ge $(($MAX_PWD_LENGTH)) ]
    then
        NEW_PWD=${PREFIX}${REPLACE}${RESIDUAL:((${#RESIDUAL} - $TRUNC_LENGTH)):$TRUNC_LENGTH}
    else
        NEW_PWD=${PREFIX}${RESIDUAL}
    fi

    # add that to prompt
    PS1+="$NEW_PWD"

    # add git prompt
    PS1+="]\[\033[0;1m\]"
    if [ ! -z "$GITPROMPT" ]; then
        PS1+=" $GITPROMPT"
        MAX_PWD_LENGTH=$((MAX_PWD_LENGTH - 1))
    fi

    # print right-aligned time
    PS1+="$(printf %$(($MAX_PWD_LENGTH - ${#NEW_PWD}))s)"
    PS1+=" \[\033[1;37m\]$(date +%d.%H:%M)\[\033[0;1m\]"
    PS1+="\n"

    # second line: show user@host in reversed color scheme if not my user on my laptop
    USERHOST="$(whoami)@$(hostname)"
    if [ ! "$USERHOST" = "noah@apfel" ] && [ ! "$USERHOST" = "noah@apfel.local" ]; then
        PS1+="\[\033[1;7m\]$USERHOST\[\033[0;1m\] "
    fi

    # show python virtual environment if activated
    VENV=""
    [[ -n "$VIRTUAL_ENV" ]] && VENV="${VIRTUAL_ENV##*/}"
    [[ -n "$VENV" ]] && PS1+="($VENV) "

    # $
    PS1+="\$\[\033[0m\] "

    # set terminal title to basename of cwd
    PS1="\e]0;\W\a""$PS1"

    # and we're done!
}
PROMPT_COMMAND=__prompt_command

# append to history file immediately (and not only during exit)
PROMPT_COMMAND="$PROMPT_COMMAND; history -a"


#############
## ALIASES ##
#############

# ls
alias ls='ls -FG'  # display a trailing slash if entry is directory or star if
                   # entry is executable, also colors
alias ll='ls -lh'  # list mode and human-readable filesizes
alias la='ll -A'   # include dotfiles
alias l1='\ls -1'  # one entry per line

# tree
alias tree='tree -CF'
alias treel='tree -phD --du'
alias treea='treel -a'

# file operations
alias cp='cp -iPRv'
alias mv='mv -iv'
alias mkdir='mkdir -p'
alias md='mkdir'
alias rmdir='rmdir -p'
alias rd='rmdir'
alias zip='zip -r'
alias o='open'
alias f='open -a Finder .'
alias space2_='for i in *; do [[ $i == *" "* ]] && mv "$i" ${i// /_}; done'

# ulitities
alias s='subl'
alias sm='smerge .'
alias ytdl='youtube-dl'
alias grep='grep --color=auto'     # highlight search phrase
alias timestamp='date +%s'
alias recentlymodified='find . -type f -print0 | xargs -0 gstat --format "%Y :%y %n" | sort -nr | cut -d: -f2- | head'  # accepts e.g. "-n 50" argument
alias pingg='prettyping --nolegend -i 0.1 google.com'
alias ip='curl ipinfo.io/ip'
alias duls='du -h -d1 | sort -r'   # list disk usage statistics for the current folder, via https://github.com/jez/dotfiles/blob/master/util/aliases.sh
alias up='uptime'                  # drop the "time". just "up". it's cleaner.
alias batt='pmset -g batt'         # battery status
alias dim='pmset displaysleepnow'  # turn the display off
alias sleepnow='pmset sleepnow'    # sleep immediately
alias nosleep='pmset noidle'       # keep computer awake indefinitely
alias rmdsstore="find . -name '*.DS_Store' -type f -delete"  # recursive!
alias brewdeps='echo "Listing all installed homebrew packages along with packages that depend on them:"; brew list -1 | while read cask; do echo -ne "\x1B[1;34m$cask \x1B[0m"; brew uses $cask --installed | awk '"'"'{printf(" %s ", $0)}'"'"'; echo ""; done'  # via https://www.thingy-ma-jig.co.uk/blog/22-09-2014/homebrew-list-packages-and-what-uses-them
alias highlight='pygmentize -f terminal'   # syntax highlighting
alias extensions="find . -type f | perl -ne 'print $1 if m/\.([^.\/]+)$/' | sort -u"  # via https://stackoverflow.com/a/1842270
alias jsonp='json_pp -f json -t json -json_opt pretty,utf8,allow_bignum'
alias bashrc='s ~/.bashrc'
alias refresh-bashrc='source ~/.bashrc'

# git
alias g='git'
alias gs='g status'  # collision with ghostscript executable
alias gd='g diff'
alias ga='g add'
alias gc='g commit -m'
alias gp='g push'
alias gl='g log'
alias gls='g log --pretty=oneline --abbrev-commit -n 15'  # short log

# postgres
alias psn='psql -c "drop database scratch;"; psql -c "create database scratch;"'  # reⓃew database
alias psf='psql -d scratch -f'                                                    # execute Ⓕile
alias psr='psql -d scratch'                                                       # open ⓇEPL

# image operations, based on imagemagick and ffmpeg
alias 2png='mogrify -format png'
alias 2jpg='mogrify -format jpg -quality 95'
alias png2jpg='for i in *.png; do mogrify -format jpg -quality 95 "$i" && rm "$i"; done'
alias png2jpg90='for i in *.png; do mogrify -format jpg -quality 90 "$i" && rm "$i"; done'
alias resize1k='mogrify -resize 1000'
alias resize720pj='convert -resize x720 -format jpg -quality 90'  # only for single files, need to specify output filename
alias jpg2mp4='ffmpeg -framerate 24 -pattern_type glob -i '"'"'*.jpg'"'"' -pix_fmt yuv420p out.mp4'


######################
## PERSONAL ALIASES ##
######################

alias cdcode='cd ~/Dropbox/code/'

# old laptop
alias exssh='ssh -XY ex.local'
alias exmcs='ssh -t ex.local "screen -r mcs"'  # minecraft server, detach with ctrl + a, then d
alias exdls='scp -rp ex.local:/home/noah/Downloads/ ~/Desktop/exdls/'
alias exdls2='scp -rp ex.local:/home/noah/Downloads/ /Volumes/Time\ Capsule/exdls/'

# raspberry pi (brachiograph)
alias pissh='ssh pi@raspberrypi.local'

# on-line internet web sites
alias noahdoerssh='ssh noahdoer@wirtanen.uberspace.de'
alias leakyssh='ssh leakyabs@wild.uberspace.de'
alias leakyquota='leakyssh quota -gsl'

# jekyll
alias jekyllinstall='bundle install'
alias jekyllreinstall='rm Gemfile.lock; bundle install; bundle lock --add-platform ruby'
alias jekyllserve='bundle exec jekyll serve'
alias jekyllservei='bundle exec jekyll serve --incremental'

# python (also see function further down)
alias pyacti='source bin/activate'

# backup
alias backup-fonts='~/Dropbox/code/backup/backup-fonts.sh'
alias backup-gists='~/Dropbox/code/backup/backup-gists.sh'
alias backup-tumblr='~/Dropbox/code/backup/backup-tumblr.sh'
alias backup-uberspaces='~/Dropbox/code/backup/backup-uberspaces.sh'
alias backup-do='~/Dropbox/code/backup/backup-do.sh'
alias backup-sync='~/Dropbox/code/backup/backup-sync.sh'

# dotfiles
alias commit-dotfiles='~/Dropbox/code/dotfiles/meta/commit-dotfiles'
alias commit-bashrc='~/Dropbox/code/dotfiles/meta/commit-bashrc'

# downloads
alias simonstalenhag='cd ~/Desktop; mkdir simonstalenhag; cd simonstalenhag; curl http://www.simonstalenhag.se | grep bilderbig | cut -d"\"" -f2 | sed "s,//,/,g" | uniq | sed -e "s/^/http:\/\/www.simonstalenhag.se\//" | xargs wget'
alias davebull='bash ~/Dropbox/code/davebull/davebull.sh'

# 22:22
alias 2222='echo "Forever (h)waiting..."; while true; do [[ $(date | tr -s " " | cut -d" " -f 4 | cut -d":" -f 1) == $(date | tr -s " " | cut -d" " -f 4 | cut -d":" -f 2) ]] && date | tr -s " " | cut -d" " -f 4 | cut -d":" -f 1,2 | say || date | tr -s " " | cut -d" " -f 4; sleep 1; done'

# hn
alias hn='python3 ~/Dropbox/code/scripts/hn.py'
alias askhn='hn "ask hn"'
alias showhn='hn "show hn"'

# kestrels
alias kestrelsyncn='backup-sync -n /Volumes/UNTITLED/_kestrels_update_feb2021onwards/ /Volumes/Time\ Capsule/_kestrels_update_feb2021onwards/'
alias kestrelsync='backup-sync /Volumes/UNTITLED/_kestrels_update_feb2021onwards/ /Volumes/Time\ Capsule/_kestrels_update_feb2021onwards/'

# github sponsor
alias setupgithubsponsors='mkdir ".github"; echo "github: doersino" > ".github/FUNDING.yml"; ga ".github/FUNDING.yml"; gc "Add FUNDING.yml"; git push'


###############
## FUNCTIONS ##
###############

# mkdir and cd to the directory that was just created
function mkcd() {
    mkdir -p "$1" && cd "$_"
}

# sets the window/tab title in an OS X terminal
# https://github.com/doersino/scripts/blob/master/settitle.sh
function settitle() {
    echo -ne "\033]0;${@:1}\007"
}

# get or set the volume on a mac, in percent
function vol() {
    local USAGE
    USAGE="usage: vol [-h | NUMBER_FROM_0_TO_100 | -DECREMENT | +INCREMENT]"
    if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
        echo -e "$USAGE"
        return 1
    fi

    if [ -z "$1" ]; then
        osascript -e "output volume of (get volume settings)"
    elif [[ "$1" == -* ]]; then
        osascript -e "set volume output volume (output volume of (get volume settings) $1)"
    elif [[ "$1" == +* ]]; then
        osascript -e "set volume output volume (output volume of (get volume settings) $1)"
    else
        osascript -e "set volume output volume $1"
    fi
}

# save keystrokes for some common actions when controlling itunes or apple music
# or swinsian (thanks to all of them supporting the same actions) remotely with
# applescript (this might pop up a permission dialog the first time it's run)
# https://github.com/doersino/scripts/blob/master/it.sh
function it() {

    # select available player
    ITUNES="iTunes"
    if [ -d "/System/Applications/Music.app" ]; then
        ITUNES="Music"
    fi
    if [ -d "/Applications/Swinsian.app" ]; then
        ITUNES="Swinsian"
    fi

    # do the things
    if [ -z "$1" ]; then
        osascript -e "tell application \"$ITUNES\" to playpause"
    elif [ "$1" = "?" ]; then
        osascript -e "tell application \"$ITUNES\" to get name of current track"
        printf "\033[90mby \033[0m"
        osascript -e "tell application \"$ITUNES\" to get artist of current track"
        printf "\033[90mon \033[0m"
        osascript -e "tell application \"$ITUNES\" to get album of current track"
    elif [ "$1" = "prev" ]; then
        osascript -e "tell application \"$ITUNES\" to play previous track"
    elif [ "$1" = "next" ]; then
        osascript -e "tell application \"$ITUNES\" to play next track"
    else
        osascript -e "tell application \"$ITUNES\" to $1"
    fi
}


# extract fonts used in a pdf
# https://stackoverflow.com/a/3489099
function fonts() {
    /usr/local/bin/gs -q -dNODISPLAY "$HOME/Dropbox/code/scripts/extractFonts.ps" -c "($1) extractFonts quit"
}

# call a command whenever a file is saved, requires fswatch utility
function onsave() {
    FILE="$1"
    shift
    CMD="$@"
    fswatch -v -o "$FILE" | xargs -n1 -I{} $CMD
}

# create a jpeg version of one or multiple heic files (which can be located in
# different directories; each conversion result ends up "next to" its respective
# original or replaces it if the --replace flag is set) using sips
function unheic() {
    local USAGE
    USAGE="usage: unheic [--replace] FILES"

    REPLACE=false
    if [ "$1" == "--replace" ]; then
        REPLACE=true
        shift
    fi

    if [ -z "$1" ]; then
        echo -e "$USAGE"; return 1
    fi

    for FILE in "$@"; do
        NO_EXT="${FILE%.*}"
        echo "$NO_EXT"
        sips -s format jpeg "$FILE" --out "$NO_EXT".jpg
        if [ $REPLACE == true ]; then
            rm "$FILE"
        fi
    done
}

# serve the cwd on a given port
function pyserve() {
    PORT=8000
    if [ ! -z "$1" ]; then
        PORT="$1"
    fi
    python3 -m http.server "$PORT"
}

# post a predefined point on @earthacrosstime
function earthacrosstime() {
    local USAGE
    USAGE="usage: earthacrosstime 'LAT,LON' MAX_METERS_PER_PIXEL"
    if [ -z "$2" ]; then
        echo -e "$USAGE"; return 1
    fi

    POINT="$1"
    MMPP="$2"  # roughly: below 16 => zoom 12, below 32 => zoom 11, etc.
    leakyssh "/usr/bin/env bash -c 'cd /home/leakyabs/earthacrosstime && source bin/activate && python3 earthacrosstime.py -p \"$POINT\" -m $MMPP'"
}

# similarly, post a predefined point on @placesfromorbit
function placesfromorbit() {
    local USAGE
    USAGE="usage: placesfromorbit 'LAT,LON'"
    if [ -z "$1" ]; then
        echo -e "$USAGE"; return 1
    fi

    POINT="$1"
    leakyssh "/usr/bin/env bash -c 'cd /home/leakyabs/aerialbot && source bin/activate && python3 aerialbot.py config-placesfromorbit.ini -p \"$POINT\"'"
}

# resets a python virtual environment, frequently needed after homebrew installs
# a new python version during the course of other upgrades, can also be used to
# create a new environment
function resetpythonvenv() {
    if [ ! -z "$VIRTUAL_ENV" ]; then
        echo "Deactivating..."
        deactivate
    else
        echo "No venv active, skipped 'deactivate' step."
    fi
    if [ -d "bin" ]; then
        echo "Nuking old virtual environment..."
        rm -r bin
        rm -r include
        rm -r lib
        rm pyvenv.cfg
    else
        echo "No 'bin' directory present, skipped nuking step."
    fi
    echo "Setting up a fresh virtual environment..."
    python3 -m venv .
    echo "Activating..."
    source bin/activate
    if [ -f "requirements.txt" ]; then
        echo "Reinstalling from requirements.txt..."
        pip3 install -r requirements.txt
    else
        echo "No 'requirements.txt' found, skipped reinstall step."
    fi
}

# randomizes the names of the files given (i'm sure this could be more elegant)
function randomname() {
    for FILE in "$@"; do
        BASE="${FILE%.*}"
        EXT="${FILE#$BASE}"
        EXT="${EXT#.}"  # correctly deal with names without extensions

        # retry arbitrarily many times on (unlikely) collision
        while true; do
            NEW_BASE="$RANDOM$RANDOM$RANDOM"  # 32767^3 (ish) possibilities
            if [ -n "$EXT" ]; then
                NEW_FILE="$NEW_BASE.$EXT"
            else
                NEW_FILE="$NEW_BASE"
            fi

            # only write out if there's not already a file with that name
            # (otherwise, try again)
            if [ ! -f "$NEW_FILE" ]; then
                mv -f -- "$FILE" "$NEW_FILE"
                break
            fi
        done
    done
}

# converts a bunch of images into an animated gif
function gifmemore() {
    local USAGE
    USAGE="usage: gifmemore [--delay N] FILES (N is in hundredths of a second, e.g. 50 = 2 fps, default is 33)"
    if [ -z "$1" ]; then
        echo -e "$USAGE"; return 1
    fi

    DELAY=33
    if [ "$1" == "--delay" ]; then
        DELAY="$2"
        shift 2
    fi
    convert -delay "$DELAY" -loop 0 -dispose previous "$@" out.gif
}


##############################
## OBSOLETE (but maybe not) ##
##############################

# awk depends on an old version of readline? idk, need to run this sometimes after brew upgrade???
alias repair-readline='cd /usr/local/opt/readline/lib/ && ln libreadline.8.0.dylib libreadline.7.dylib'

# seldom-used git stuff
alias grau='g remote add upstream'  # argument: clone url of remote upstream repo
alias gmakeeven='g fetch upstream && g checkout master && g merge upstream/master && git push'  # in a fork, assuming no local changes have been made, fetch all new commits from upstream, merge them into the fork, and finally push
alias gmakeevenforce='g fetch upstream && g checkout master && git reset --hard upstream/master && git push --force'  # same except will "force pull" from upstream and you'll lose any local changes
