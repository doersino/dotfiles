#!/bin/bash

# homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# some zsh's witnesses are at the door, let's shut them out
export BASH_SILENCE_DEPRECATION_WARNING=1

# required (?) for ruby in catalina or later, see https://jekyllrb.com/docs/installation/macos/
command -v xcrun >/dev/null 2>&1 && export SDKROOT=$(xcrun --show-sdk-path)


##########
## PATH ##
##########

PATH_RUBY="/opt/homebrew/opt/ruby/bin"
PATH_PIPX="/Users/noah/.local/bin"
PATH_PG="/Applications/Postgres.app/Contents/Versions/15/bin"  # need to change on pg updates
PATH_SMERGE="/Applications/Sublime Merge.app/Contents/SharedSupport/bin/"
PATH_SUBL="/Applications/Sublime Text.app/Contents/SharedSupport/bin/"
export PATH="$PATH_PIPX:$PATH_RUBY:$PATH:$PATH_PG:$PATH_SMERGE:$PATH_SUBL"


######################################
## HISTORY, SHELL, AND LESS OPTIONS ##
######################################

# read this number of lines into history buffer on startup
export HISTSIZE=1000000

# HISTFILESIZE is set *after* bash reads the history file (which is done after
# reading any configs like .bashrc). If it is unset at this point it is set to
# the same value as HISTSIZE. Therefore we must set it to NIL, in which case it
# isn't "unset", but doesn't have a value either, enabling us to keep an
# essentially infinite history
export HISTFILESIZE=""

# don't put duplicate lines in the history, ignore same sucessive entries, and
# ignore lines that start with a space
export HISTCONTROL=ignoreboth

# add timestamps to history and show them
export HISTTIMEFORMAT="%F %T  "

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
GIT_PROMPT_SH="/opt/homebrew/etc/bash_completion.d/git-prompt.sh"
if [ -e "$GIT_PROMPT_SH" ]; then
    source "$GIT_PROMPT_SH"
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
        GITPROMPTLEN="$(echo "$GITPROMPT" | wc -c | xargs) "
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

    # add closing bracket
    PS1+="]"

    # add git prompt
    if [ ! -z "$GITPROMPT" ]; then
        PS1+=" \[\033[0;1m\]$GITPROMPT\[\033[0m\]"
        MAX_PWD_LENGTH=$((MAX_PWD_LENGTH - 1))
    fi

    # print right-aligned time
    PS1+="$(printf %$(($MAX_PWD_LENGTH - ${#NEW_PWD}))s)"
    PS1+=" \[\033[1;37m\]$(date +%d.%H:%M)\[\033[0m\]"
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
    PS1+="\[\033[0;1m\]\$\[\033[0m\] "

    # set terminal title to basename of cwd
    PS1="\e]0;\W\a""$PS1"

    # and we're done!
}
PROMPT_COMMAND=__prompt_command

# append to history file immediately (and not only during exit)
PROMPT_COMMAND="$PROMPT_COMMAND; history -a"

# alternate version: also load from history immediately - but that mixes the
# history of different sessions *in* those still-active sessions, which confuses
# me more than it helps
#PROMPT_COMMAND="$PROMPT_COMMAND; history -a; history -n"



#############
## ALIASES ##
#############

# ls
alias ls='ls -FG'  # display a trailing slash if entry is directory or star if
                   # entry is executable, also colors
alias ll='ls -lh'  # list mode and human-readable filesizes
alias la='ll -A'   # include dotfiles but not . and ..
alias l1='\ls -1'  # one entry per line

# tree
alias tree='tree -F'  # display a trailing slash if entry is directory or star
                      # if entry is executable
alias treel='tree -phD --du'  # kind of like ls -l
alias treea='treel -a'        # kind of like ls -la

# cd
alias cd..='cd ..'
alias cdf='cd "$(osascript -e '\''tell application "Finder" to return POSIX path of (target of front Finder window as alias)'\'')"'  # via https://leancrew.com/all-this/2024/09/improved-finder-terminal-tools/

# file operations
alias cp='cp -iPRv'
alias mv='mv -iv'
alias mkdir='mkdir -p'
alias rmdir='rmdir -p'
alias zip='zip -r'
alias o='open'
alias f='open -a Finder .'
alias space2_='for i in *; do [[ $i == *" "* ]] && mv "$i" ${i// /_}; done'

# ulitities
alias s='subl'
alias sm='smerge .'
alias grep='grep --color=auto'     # highlight search phrase
alias timestamp='date +%s'
alias recentlymodified='find . -type f -print0 | xargs -0 gstat --format "%Y :%y %n" | sort -nr | cut -d: -f2- | head'  # accepts e.g. "-n 50" argument
alias pingg='prettyping --nolegend -i 0.1 google.com'
alias pinggg='while true; do date; pingg -c 600; sleep 10; done'
alias ip='curl ipinfo.io/ip; echo' # "echo" to generate a newline
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
alias countfilesinsubdirectories="du -a | sed '/.*\.\/.*\/.*/!d' | cut -d/ -f2 | sort | uniq -c | sort -nr"  # via https://stackoverflow.com/a/39622947
alias jsonp='json_pp -f json -t json -json_opt pretty,utf8,allow_bignum'
alias bashrc='s ~/.bashrc'
alias refresh-bashrc='source ~/.bashrc'

# git
alias gs='git status'  # collision with ghostscript executable, hence:
alias ghostscript='/usr/local/bin/gs'
alias gd='git diff'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log'
alias gls='git log --pretty=oneline --abbrev-commit -n 15'  # short log

# python (also see function further down)
alias pyacti='source bin/activate'

# postgres
alias psn='psql -c "drop database scratch;"; psql -c "create database scratch;"'  # reⓃew database
alias psf='psql -d scratch -f'                                                    # execute Ⓕile
alias psr='psql -d scratch'                                                       # open ⓇEPL

# image operations, based on imagemagick and ffmpeg
alias 2png='mogrify -format png'
alias 2jpg='mogrify -format jpg -quality 95'
#alias png2jpg='for i in *.png; do mogrify -format jpg -quality 95 "$i" && rm "$i"; done'
#alias png2jpg90='for i in *.png; do mogrify -format jpg -quality 90 "$i" && rm "$i"; done'
alias resize1k='mogrify -resize 1000'
alias resize1280q90='mogrify -quality 90 -resize 1280'
alias resize720pj='convert -resize x720 -format jpg -quality 90'  # only for single files, need to specify output filename
alias jpg2mp4='ffmpeg -framerate 24 -pattern_type glob -i '"'"'*.jpg'"'"' -pix_fmt yuv420p out.mp4'
alias adobe-dng-converter='/Applications/Adobe\ DNG\ Converter.app/Contents/MacOS/Adobe\ DNG\ Converter'

# yt-dlp
alias youtube-dl='yt-dlp'
alias yt-dlp-mp4="yt-dlp -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio' --merge-output-format mp4"
alias yt-dlp-mp3="yt-dlp -x --audio-format mp3 --audio-quality 0"

# mail (cron job reports)
alias nukemail='echo '"'"'delete *'"'"' | mail; mail'

######################
## PERSONAL ALIASES ##
######################

# old laptop
alias exssh='ssh -XY ex.local'
alias exmcs='ssh -t ex.local "screen -r mcs"'  # minecraft server, detach with ctrl + a, then d
alias exdls='scp -rp ex.local:/home/noah/Downloads/ ~/Desktop/exdls/'

# raspberry pi (brachiograph)
alias pissh='ssh pi@raspberrypi.local'

# on-line internet web sites
alias noahdoerssh='ssh noahdoer@wirtanen.uberspace.de'
alias leakyssh='ssh leakyabs@wild.uberspace.de'
alias leakyquota='leakyssh quota -gsl'
alias leakytidyup='leakyssh bash tidyup.sh'

# jekyll
alias jekyllinstall='bundle install'
alias jekyllreinstall='rm Gemfile.lock; bundle install; bundle lock --add-platform ruby'
alias jekyllserve='bundle exec jekyll serve'
alias jekyllservei='bundle exec jekyll serve --incremental'
alias exadserve='cd ~/Dropbox/code/excessivelyadequate.com; jekyllserve --drafts --host=0.0.0.0; cd -'

# backup
alias backup-do='~/Dropbox/code/backup/backup-do.sh'
alias backup-fonts='~/Dropbox/code/backup/backup-fonts.sh'
#alias backup-gists='~/Dropbox/code/backup/backup-gists.sh'
alias backup-photos='~/Dropbox/code/backup/backup-photos.sh'
alias backup-tumblr='~/Dropbox/code/backup/backup-tumblr.sh'
alias backup-uberspaces='~/Dropbox/code/backup/backup-uberspaces.sh'
alias backup-sync='~/Dropbox/code/backup/backup-sync.sh'
alias backup-sync-photos='backup-sync /Volumes/one/photos_phone/2022-_iphone12mini/ /Volumes/two/photos_phone/2022-_iphone12mini/'

# dotfiles
alias commit-dotfiles='~/Dropbox/code/dotfiles/meta/commit-dotfiles'
alias commit-bashrc='~/Dropbox/code/dotfiles/meta/commit-bashrc'

alias commit-moneymoney-extensions='~/Dropbox/code/moneymoney-extensions/meta/commit-moneymoney-extensions'

# downloads
alias davebull='bash ~/Dropbox/code/davebull/davebull.sh'
alias simonstalenhag='cd ~/Desktop; mkdir simonstalenhag; cd simonstalenhag; curl http://www.simonstalenhag.se | grep bilderbig | cut -d"\"" -f2 | sed "s,//,/,g" | uniq | sed -e "s/^/http:\/\/www.simonstalenhag.se\//" | xargs wget'

# 22:22
alias 2222='echo "Forever (h)waiting..."; while true; do [[ $(date | tr -s " " | cut -d" " -f 4 | cut -d":" -f 1) == $(date | tr -s " " | cut -d" " -f 4 | cut -d":" -f 2) ]] && date | tr -s " " | cut -d" " -f 4 | cut -d":" -f 1,2 | say -i || date | tr -s " " | cut -d" " -f 4; sleep 1; done'

# hn
alias hn='python3 ~/Dropbox/code/scripts/hn.py'
alias askhn='hn "ask hn"'
alias showhn='hn "show hn"'


###############
## FUNCTIONS ##
###############

# macos notifications
# usage: long_running_task && notify "done" || notify "failed"
function notify() {
    osascript -e "display notification \"$1\""
}

# perform some command-line settings on a new mac (run during initial setup)
function newmacsettings() {
    defaults write com.apple.Safari IncludeInternalDebugMenu 1

    # reduce menu bar spacing just ever-so-slightly (requires re-login)
    # via https://flaky.build/native-fix-for-applications-hiding-under-the-macbook-pro-notch
    defaults -currentHost write -globalDomain NSStatusItemSelectionPadding -int 8
    defaults -currentHost write -globalDomain NSStatusItemSpacing -int 14
    #defaults -currentHost delete -globalDomain NSStatusItemSelectionPadding
    #defaults -currentHost delete -globalDomain NSStatusItemSpacing

    # hide these directories (reset with "nohidden")
    chflags hidden ~/Movies/"TV"
    chflags hidden ~/Movies/"iMovie Library.imovielibrary"
    chflags hidden ~/Movies/"iMovie Theater.theater"
    chflags hidden ~/Movies/"Motion Templates.localized"
    chflags hidden ~/Pictures/"Photo Booth Library"
    chflags hidden ~/Pictures/"Photos Library.photoslibrary"

    # fix hostname being "Mac" even when set differently in system settings
    # bug introduced in macos sequoia
    # https://www.reddit.com/r/MacOS/comments/1fimgck/sequoia_is_messing_with_my_computers_hostname/
    sudo scutil --set HostName "apfel"

    # install crontab
    crontab ~/Dropbox/code/crontab/crontab.txt
}

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
    USAGE="usage: vol [-h | --help | NUMBER_FROM_0_TO_100 | -DECREMENT | +INCREMENT]"

    # if the argument isn't one of the expected values, display usage instructions
    if [ "$1" == "-h" ] || [ "$1" == "--help" ] || ! [[ "$1" =~ ^$|^[+-]?[0-9]+$ ]]; then
        echo "$USAGE"
        return 1
    fi

    # retrieve old volume
    OLD_VOLUME="$(osascript -e "output volume of (get volume settings)")"

    if [ -z "$1" ]; then
        echo "$OLD_VOLUME %"
    else
        # default case: just set volume to specified value
        NEW_VOLUME="$1"

        # alternatively: decrement or increment?
        if [[ "$1" == -* ]] || [[ "$1" == +* ]]; then
            NEW_VOLUME=$(($OLD_VOLUME + $1))
        fi

        # clamp to [0, 100]
        if [ "$NEW_VOLUME" -lt 0 ] ; then
            NEW_VOLUME=0
        fi
        if [ "$NEW_VOLUME" -gt 100 ] ; then
            NEW_VOLUME=100
        fi

        # give feedback
        MUTED=""
        if [ "$NEW_VOLUME" -eq 0 ]; then
            MUTED="(muted)"
        fi
        echo "$OLD_VOLUME % -> $NEW_VOLUME % $MUTED"

        # set
        osascript -e "set volume output volume $NEW_VOLUME"
    fi
}

# save keystrokes for some common actions when controlling itunes or apple music
# or swinsian (thanks to all of them supporting the same actions) remotely with
# applescript (this might pop up a permission dialog the first time it's run)
# https://github.com/doersino/scripts/blob/master/it.sh
function it() {

    # select available player, preferring Swinsian over Music over iTunes
    PLAYER="iTunes"
    if [ -d "/System/Applications/Music.app" ]; then
        PLAYER="Music"
    fi
    if [ -d "/Applications/Swinsian.app" ]; then
        PLAYER="Swinsian"
    fi

    # do the things
    if [ -z "$1" ]; then
        osascript -e "tell application \"$PLAYER\" to playpause"
    elif [ "$1" = "?" ]; then
        osascript -e "tell application \"$PLAYER\" to get name of current track"
        printf "\033[90mby \033[0m"
        osascript -e "tell application \"$PLAYER\" to get artist of current track"
        printf "\033[90mon \033[0m"
        osascript -e "tell application \"$PLAYER\" to get album of current track"
    elif [ "$1" = "prev" ]; then
        osascript -e "tell application \"$PLAYER\" to play previous track"
    elif [ "$1" = "next" ]; then
        osascript -e "tell application \"$PLAYER\" to play next track"
    else
        osascript -e "tell application \"$PLAYER\" to $1"
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

# create a jpeg version of one or multiple png files (which can be located in
# different directories; each conversion result ends up "next to" its respective
# original or replaces it if the --replace flag is set)
function png2jpg() {
    local USAGE
    USAGE="usage: unheic [--replace] [--quality n] FILES"

    REPLACE=false
    QUALITY=90

    if [ "$1" == "--replace" ]; then
        REPLACE=true
        shift
    fi

    if [ "$1" == "--quality" ]; then
        QUALITY="$2"
        shift
        shift
    fi

    if [ "$1" == "--replace" ]; then
        REPLACE=true
        shift
    fi

    if [ -z "$1" ]; then
        echo -e "$USAGE"; return 1
    fi

    for FILE in "$@"; do
        mogrify -format jpg -quality "$QUALITY" "$FILE"
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
    if [ -f "pyvenv.cfg" ]; then
        echo "Nuking old virtual environment..."
        rm pyvenv.cfg
        rm -r bin
        rm -r include
        rm -r lib
    else
        echo "No 'pyvenv.cfg' file present, skipped nuking step."
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

# compresses a pdf quite dramatically without apparent loss of quality (but may
# degrade searchability and compatibility, also takes a while)
# https://leancrew.com/all-this/2022/01/reducing-the-size-of-large-pdfs/
# https://gist.github.com/firstdoit/6390547
function compresspdf() {
    local USAGE
    USAGE="usage: compresspdf INPUT_FILE OUTPUT_FILE"
    if [ -z "$2" ]; then
        echo -e "$USAGE"; return 1
    fi

    IN="$1"
    OUT="$2"
    ghostscript -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dNOPAUSE -dQUIET -dBATCH -sOutputFile="$OUT" "$IN"
}

# command-line wordle, via https://twitter.com/yamaya/status/1487764102462140421
function wordle() {
    awk 'BEGIN{for(srand()srand(srand()/86400);getline<"/usr/share/dict/words";FS=_)length==5&&/^[a-z]*$/&&b[a[i++]=$0]=1;t=a[int(rand()*i)];printf">"}q=b[w=$0]{++j;for(x=i="^";++i<6;x=x".")$i="\33[4"(t~x$i?2:t~$i?3:_)"m"toupper($i)"\33[m"}q||$0="bad word";j>5||w==t{exit}{printf">"}'
}

# converting a video to the format preferred by wikimedia commons, see
# https://commons.wikimedia.org/wiki/Help:Converting_video#Linux_and_OS_X_command_line
function video2webm() {

    # Convert video file to webm
    # Author: Geert Van Pamel
    # Parameters:
    #  P1: input file name

    if [[ -z "$1" ]]; then
        echo "Input file missing"
        exit 1
    fi

    INPUT="$1"
    OUTPUT=$(basename "$1").webm

    ffmpeg -i "$INPUT" -c:v libvpx-vp9 -b:v 0 -crf 30 -pass 1 -row-mt 1 -an -f webm -y /dev/null &&
    ffmpeg -i "$INPUT" -c:v libvpx-vp9 -b:v 0 -crf 30 -pass 2 -row-mt 1 -c:a libopus "$OUTPUT"
}

# adds a silent audio track to a video
# background: my camera's slow-motion videos don't feature an audio track and
# mastodon thus recognizes them as gifs
function addsilentaudio() {
    local USAGE
    USAGE="usage: addsilentaudio INPUT_FILE"
    if [ -z "$1" ]; then
        echo -e "$USAGE"; return 1
    fi

    FILE="$1"
    PATH_AND_NAME="${FILE%%.*}"
    EXTENSION="${FILE#*.}"

    ffmpeg \
        -f lavfi  \
        -i anullsrc=channel_layout=stereo:sample_rate=44100 \
        -i "$FILE" \
        -c:v copy \
        -c:a aac \
        -shortest \
        "$PATH_AND_NAME-with-silent-audio.$EXTENSION"  # needs to match (*)
}

# reduce video size, optionally takes crf as arg
# (also adds silent audio track if no audio present)
function reducevideosize() {
    local USAGE
    USAGE="usage: reducevideosize INPUT_FILE [CRF (number between 18ish and 30ish, lower is better quality but larger, default 20)]"
    if [ -z "$1" ]; then
        echo -e "$USAGE"; return 1
    fi

    CRF=20
    if [ -n "$2" ]; then
        CRF="$2"
    fi

    FILE="$1"
    PATH_AND_NAME="${FILE%%.*}"
    EXTENSION="${FILE#*.}"

    AUDIO_INFO="$(ffprobe -i "$FILE" -show_streams -select_streams a -loglevel error)"
    if [ -z "$AUDIO_INFO" ]; then
        addsilentaudio "$FILE"
        FILE="$PATH_AND_NAME-with-silent-audio.$EXTENSION"  # needs to match (*)
        PATH_AND_NAME="${FILE%%.*}"
    fi

    ffmpeg -i "$FILE" -crf "$CRF" "$PATH_AND_NAME-crf$CRF.mp4"
}

# "normalize" photo/video names generated by my camera, run in a directory
# containing .RAF/.MOV files, will replace e.g. "DSCF5982_merganser.RAF" to
# "DSCF5982_2024-02-20_merganser.RAF" (that date is the file modification date)
# or "DSCF5982.RAF" to "DSCF5982_2024-02-20_.RAF" (trailing _ is intended),
# optionally takes a directory in which all this is supposed to happen
function namephotoswithdate() {
    for FILE in "$@"; do

        # skip already-renamed files => idempotence
        if [[ $FILE =~ "_20" ]]; then
            echo "# skipping $FILE (already renamed)"
            continue
        fi

        # otherwise, put together new file name and mv
        MODIFIED=$(date -r "$FILE" +'%Y-%m-%d')
        NEWFILE=$(echo $FILE | perl -lape 's/^(.*)(DSCF\d+)_?(.*)$/$1$2_'"$MODIFIED"'_$3/g')
        echo "mv $FILE $NEWFILE"
        \mv "$FILE" "$NEWFILE"
    done
}
function namephotosinfolderwithdate() {

    # if directory given, go there
    if [[ ! -z "$1" ]] && [[ -d "$1" ]]; then
        echo "cd $1"
        cd "$1"
    fi

    # rename each *.{RAF,MOV,jpg,pxd}
    shopt -s nullglob
    namephotoswithdate *.{RAF,MOV,jpg,pxd}
    shopt -u nullglob

    # go back to previous directory
    if [[ ! -z "$1" ]] && [[ -d "$1" ]]; then
        echo "cd -"
        cd - >/dev/null  # suppress output
    fi
}

# really specific utility for extracting the date from gpx walk recordings at
# the root level of my dropbox, prefixing it to the filenames, then moving the
# resulting files to the "walks" subdirectory
function prefixgpxindropboxwithdateandfileaway() {
    echo "cd ~/Dropbox"
    cd ~/Dropbox

    # rename each *.gpx
    shopt -s nullglob
    for FILE in *.gpx; do

        # skip already-renamed files => idempotence
        if [[ $FILE =~ ^20.* ]]; then
            echo "# skipping $FILE (already renamed)"
            continue
        fi

        # extract date really awkwardly because quick-and-dirty:
        # - extract lines containting time tags via perl
        #   via https://stackoverflow.com/a/25392098
        # - then cut date out of them
        # - then using head and tail, take the second date found in the file
        #   (the first is, in my case, the export timestamp)
        DATE=$(perl -wln -e 'print if /\btime\b/' "$FILE" | cut -d'>' -f2 | cut -dT -f1 | head -n 2 | tail -n 1)
        NEWFILE="${DATE}_$FILE"
        echo "mv $FILE walks/$NEWFILE"
        \mv "$FILE" "walks/$NEWFILE"
    done
    shopt -u nullglob

    # go back to previous directory
    if [[ ! -z "$1" ]] && [[ -d "$1" ]]; then
        echo "cd -"
        cd - >/dev/null  # suppress output
    fi
}

function dateprefix() {
    for FILE in "$@"; do

        # skip already-renamed files => idempotence
        REGEX='[0-9]{4}-[0-9]{2}-[0-9]{2}_'
        if [[ $FILE =~ $REGEX ]]; then
            echo "# skipping $FILE (already renamed)"
            continue
        fi

        # otherwise, put together new file name and mv
        DATENOW=$(date +'%Y-%m-%d')
        NEWFILE="${DATENOW}_$FILE"  # https://stackoverflow.com/a/75222340
        echo "mv $FILE $NEWFILE"
        \mv "$FILE" "$NEWFILE"
    done
}
function datesuffix() {
    for FILE in "$@"; do

        # skip already-renamed files => idempotence
        REGEX='_[0-9]{4}-[0-9]{2}-[0-9]{2}'
        if [[ $FILE =~ $REGEX ]]; then
            echo "# skipping $FILE (already renamed)"
            continue
        fi

        # otherwise, put together new file name and mv
        DATENOW=$(date +'%Y-%m-%d')
        NEWFILE="${FILE%%.*}_${DATENOW}.${FILE#*.}"  # https://stackoverflow.com/a/75222340
        echo "mv $FILE $NEWFILE"
        \mv "$FILE" "$NEWFILE"
    done
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

# kestrels
alias kestrelsyncn='backup-sync -n /Volumes/UNTITLED/_kestrels_update_feb2021onwards/ /Volumes/Time\ Capsule/_kestrels_update_feb2021onwards/'
alias kestrelsync='backup-sync /Volumes/UNTITLED/_kestrels_update_feb2021onwards/ /Volumes/Time\ Capsule/_kestrels_update_feb2021onwards/'

# similar to unheic, this creates perceptially losslessly converted mp4 versions
# of mjpeg-encoded AVI videos shot using my antiquated DSLR – the results are
# 50% to 90% smaller than the originals. as with unheic, the input files can be
# located in different directories; each conversion result ends up "next to" its
# respective original or replaces it if the --replace flag is set. requires
# ffmpeg (along with patience and fan noise tolerance) and gtouch (part of
# coreutils) for transferring the originals' modification date to the result
function unavi() {
    local USAGE
    USAGE="usage: unavi [--replace] FILES"

    REPLACE=false
    if [ "$1" == "--replace" ]; then
        REPLACE=true
        shift
    fi

    if [ -z "$1" ]; then
        echo -e "$USAGE"; return 1
    fi

    # sanity check
    if [ "$REPLACE" = true ]; then
        echo "About to convert the following files and delete the originals:"
        for FILE in "$@"; do
            echo "  $FILE"
        done
        read -p "Continue (y/N)? "
        [ "$REPLY" = "y" ] || return 1
    fi

    # do all this in a subshell so any exit caused by set -e won't terminate the
    # session, see https://stackoverflow.com/a/15302061
    (
        set -e
        for FILE in "$@"; do
            NO_EXT="${FILE%.*}"

            # see https://github.com/doersino/ffmpeg-koraktor#almost-losslessly-converting-a-video-from-mjpegpcm_s16le-to-h264aac
            ffmpeg -i "$FILE" -c:v libx264 -preset fast -crf 18 -c:a aac -b:a 192k "$NO_EXT".mp4
            gtouch -d "$(date -R -r "$FILE")" "$NO_EXT".mp4
            if [ $REPLACE == true ]; then
                rm "$FILE"
            fi
        done
        set +e
    )
}

# now, an alias to ease my typical use case of unavi. the '"'"' are just escaped
# single quotes, the -print0 and -0 bits make things work with spaces-containing
# filenames, the _ makes sure any additional arguments passed to the alias
# (like the --replace flag) are forwarded to unavi, and the </dev/tty seems to
# be required for unavi to receive user input, see
# https://unix.stackexchange.com/a/403802. one feature of this (when used with
# the --replace flag) is that you can ctrl-C and later restart while only losing
# the conversion progress on the current file, everything that's already
# converted persists, and nothing gets converted twice or deleted before
# successful conversion (i think and hope)
#export -f unavi
alias unavi_all_imgp='find . -name '"'"'IMGP*.AVI'"'"' -print0 | xargs -0 bash -c '"'"'unavi "$@" </dev/tty'"'"' _'
alias unavi_all_imgp_size_before='find . -type f -name 'IMGP*.AVI' -exec du -ch {} + | grep total$'
alias unavi_all_imgp_size_after='find . -type f -name 'IMGP*.mp4' -exec du -ch {} + | grep total$'

# post a predefined point on @earthacrosstime
function earthacrosstime() {
    local USAGE
    USAGE="usage: earthacrosstime 'LAT,LON' MAX_METERS_PER_PIXEL"
    if [ -z "$2" ]; then
        echo -e "$USAGE"; return 1
    fi

    POINT="$1"
    MMPP="$2"  # roughly: below 16 => zoom 12, below 32 => zoom 11, etc.
    leakyssh "/usr/bin/env bash -c 'cd /home/leakyabs/earthacrosstime && source bin/activate && python3 earthacrosstime.py -p=\"$POINT\" -m $MMPP'"
}

# similarly, post a predefined point on @placesfromorbit (any further arguments will be ignored, which is handy for comments)
function placesfromorbit() {
    local USAGE
    USAGE="usage: placesfromorbit 'LAT,LON'"
    if [ -z "$1" ]; then
        echo -e "$USAGE"; return 1
    fi

    POINT="$1"
    leakyssh "/usr/bin/env bash -c 'cd /home/leakyabs/aerialbot && source bin/activate && python3 aerialbot.py config-placesfromorbit.ini -p=\"$POINT\"'"
}

# ...and the same for @citiesatanangle (here, the first argument is the view direction)
function citiesatanangle() {
    local USAGE
    USAGE="usage: placesfromorbit DIRECTION 'LAT,LON'"
    if [ -z "$2" ]; then
        echo -e "$USAGE"; return 1
    fi

    DIRECTION="$1"
    POINT="$2"
    leakyssh "/usr/bin/env bash -c 'cd /home/leakyabs/aerialbot && source bin/activate && python3 aerialbot.py config-citiesatanangle.ini -p=\"$POINT\" --direction \"$DIRECTION\"'"
}
