#   $URL: svn://localhost/Config/trunk/Dotfiles/.zshrc $
#   $Date: 2013-12-08 14:43:52 -0600 (Sun, 08 Dec 2013) $
#   $Revision: 4868 $

#   Copyright (c) 2004, 2009 by Jon R. Roma

#   .zshrc
#       /etc/zshenv run at startup for all shells
#       ~/.zshenv   run at startup for all shells
#       /etc/zprofile   run at startup for login shells
#       ~/.zprofile run at startup for login shells
#       /etc/zshrc  run at startup for interactive shells
#       ~/.zshrc    run at startup for interactive shells
#       /etc/zlogin run at startup for login shells
#       ~/.zlogin   run at startup for login shells

#       conditionally add directory path to named variable.
#           Usage: add_path [-v] var dir ...

function add_path()
{
local    dir;
local -i prepend=0;
local -a temp;
local    usage="Usage: $0 [-v] var dir ...";
local    var;
local -i verbose=0;

while (( $# > 0 ));
do
    case $1 in
        -p)  (( prepend=1 ));;
        -v)  (( verbose++ ));;
        -)   shift; break;;
        -*)  print -u2 $usage; return 1;;
        *)   break;;
    esac
    shift;
done;

if (( $# <= 1 ));
then
    print -u2 $usage;
    return 1;
fi

#   The first call argument is the target variable name.
var=$1; shift;

#   The zsh array temp contains the contents of the referenced variable.
#   If variable is all caps, treat like environment variable and split on colons.
#   otherwise, treat as zsh array.

if [[ ${var} == ${(U)var} ]];
then    temp=(${(s.:.)${(P)${(e)var}}});
else    temp=(${(P)${(e)var}});
fi;

(( verbose >= 1 )) &&   print -u2 "$0: $var (at start):" $temp;
(( verbose >= 1 )) &&   print -u2 "$0: $# path(s) to check:" $@;

#   Iterate over remaining call arguments, which are directory paths
#   to be checked for addition to the target variable.
for dir in $@;
do
    (( verbose >= 2 )) &&   print -n -u2 "$0: checking $dir ... ";

    #   Skip directory if already in path or if not directory/symlink.

    if [[ ${temp[(r)$dir]} != '' || ( ! -d $dir && ! -L $dir ) ]];
    then
        (( verbose >= 2 )) &&   print -u2 "skipped";
        continue;
    fi

    #   Prepend or append as appropriate.
    if (( $prepend ));
    then    temp=($dir $temp);
    else    temp=($temp $dir);
    fi

    (( verbose >= 2 )) &&   print -u2 "added";
done;

(( verbose >= 1 )) &&   print -u2 "$0: $var (at end):" $temp;

#   The zsh array temp contains the contents of the referenced variable.
#   If target variable is all caps, join and store to target environment
#   variable as a colon-separated stringe. Otherwise, store to target as
#   zsh array.

if [[ ${var} == ${(U)var} ]];
then    typeset -x $var=${(j.:.)temp};
else    set -A $var ${(@)temp};
fi;

return 0;
}

#   Check for suitable version of Python interpreter

#function check_python()
#{
#typeset -i version_target=0x02060000;  # target version is 2.6
#typeset    python=$(which python)
#
#if [[ $(whence python) = '' ]];
#       then
#       print -u2 "$0: no python interpreter found";
#       return;
#       fi
#
#typeset -i version_current=$($python -c \
#                            "from __future__ import print_function; \
#                             import sys; \
#                             print('0x%08x' % sys.hexversion);")
#
##  we're already using a suitable python version
#(( version_current >= version_target )) && return;
#
#if [[ $(whence python2.6) = '' ]];
#       then
#       print -u2 "$0: no python interpreter at suitable version";
#       return;
#       fi
#
#typeset -x PYTHON=$(whence python2.6);
#alias python=$PYTHON;
#return;
#}

#

function fh()
{
[[ $# != 1 ]] &&    { print -u2 "Usage: $0 string"; return 1; }

history -$HISTSIZE | grep "$1" | grep -v $0;
return 0;
}

#   Determine current git branch.

function git_branch()
{
typeset ref=$(git symbolic-ref HEAD 2> /dev/null) || return;
print ${ref#refs/heads/};
return
}

#   Does git project need to be updated?

function git_dirty()
{
typeset -i delta=$(git status --porcelain | wc -l | sed -e 's/ *//g');
return $delta;
}

#   Set up appropriate prompt if we are in a Git working directory.

function git_prompt()
{
typeset git_branch=$(git_branch);
typeset -i git_bare=0;
typeset -i git_dir=0;

[[ $(git rev-parse --is-bare-repository) == 'true' ]] && (( git_bare=1 ));
[[ $(git rev-parse --is-inside-git-dir)  == 'true' ]] && (( git_dir=1  ));

typeset project;

if (( git_bare ));
then
    typeset -x git_string="git bare repo [%~]";
elif (( git_dir ));
then
    typeset -x git_string="git dir [%~]";
else
    project=${$(git rev-parse --show-toplevel 2>&-)##*/};
    typeset prefix=${"$(git rev-parse --show-prefix 2>&-)"%%/};
    prefix=${prefix:-.}
    typeset -x git_string="${project} [${git_branch}] ${prefix}";
    git_dirty;
    typeset -i git_dirty=$?;
fi;

#   handle color terminal

if [[ $terminfo[colors] -ge 8 ]];
then
    if (( git_bare || git_dir ));
    then
        #   prompt for bare repository is a bold red background.
        git_string="%{$bg_bold[red]%}$git_string%{$reset_color%}";
    else
        #   change prefix color if anything needs a commit
        if (( git_dirty ));
        then
            if [[ $git_branch = 'master' ]];
            then
                git_string="%{$fg_bold[red]%}$git_string%{$reset_color%}";
            else
                git_string="%{$fg_bold[yellow]%}$git_string%{$reset_color%}";
            fi;
        else
            if [[ $git_branch = 'master' ]];
            then
                git_string="%{$fg[red]%}$git_string%{$reset_color%}";
            else
                git_string="%{$fg[green]%}$git_string%{$reset_color%}";
            fi;
        fi;
    fi;

    print "${git_string} %!%(!.#.:)";
    return;

fi;

#   handle non-color terminal

if (( git_bare || git_dir ));
then
    git_string="%{%S%}%{%B%}$git_string%{%b%}%{%s%}";
else
    if (( git_dirty ));
    then
        if [[ $git_branch = 'master' ]];
        then
            git_string="%{%B%}%{%U%}$git_string%{%u%}%{%b%}";
        else
            git_string="%{%B%}$git_string%{%b%}";
        fi;
    else
        if [[ $git_branch = 'master' ]];
        then
            git_string="%{%U%}$git_string%{%u%}";
        else
            git_string="$git_string";
        fi;
    fi;
fi;

print "${git_string} %!%(!.#.:)";
return;
}

#

function llocate()
{
[[ $llocate = '' ]] &&  { print -u2 "No local locate database"; return 1; }
eval $llocate $* | grep -v /.svn
return;
}

#   SPECIAL FUNCTION
#   precmd() is invoked internally before each prompt

function precmd()
{
[[ $TERM = xterm* ]]    && setprompt;
return;
}

#

function pt()
{
typeset sys=$(uname -s);
typeset tty=$(tty);

if [[ $sys = "unknown" ]];
then    tty=${tty##/dev/tty}; ps ${*}t${tty};
elif [[ $sys = 'Darwin' ]];     # Mac OS X
then    ps uT;
elif [[ $sys = "HP-UX" ]];      # ewwww
then    tty=${tty##/dev/pty/}; ps -f ${*} -t ${tty};
else    tty=${tty##/dev/}; ps -f ${*} -t ${tty};
fi

return;
}

#

function setprinter()
{
typeset -i verbose=0;

while [[ $# > 0 ]];
do
    case $1 in
        -v) (( verbose=1 ));;
        -)  shift; break;;
        -*) print -u2 "Usage: $0 [-v]";
            return 1;;
        *)  break;;
    esac;
    shift;
done;

typeset hostname=${1-$(hostname)};
typeset printer;

case $hostname in
    *.(ci|cites).(illinois|uiuc).edu)   printer=Minolta_BizHub_350;;
esac;

if [[ $printer != '' ]];
    then
    typeset -x LPDEST=$printer;
    typeset -x PRINTER=$printer;

    if (( verbose > 0 ));
    then
        print   -u2 "$0: printer $printer for hostname $hostname";
    fi;
else
    if (( verbose > 0 ));
    then
        print   -u2 "$0: no printer for hostname $hostname";
    fi;
fi;

return;
}

#

function setprompt()
{
if [[ $TERM = *xterm* ]];
then
    #   generate window title with variable substitution

    typeset xtitle="$(print -P "%m   %~")";

    #   determine whether we're a git branch.

    if [[ $(git_branch) != '' ]]
    then
        PS1="$(git_prompt) ";
    else
        PS1="$(svn_prompt)%!%(!.#.:) ";
    fi;

    xtitle $xtitle;
else
    PS1="<%m> %~ %!%(!.#.:) ";
fi;
return;
}

#

function svn_info
{
svn info 2> /dev/null | grep ^URL | awk '{ print $2; }';
return;
}

#

function svn_path
{
typeset -i i;
typeset -i j;
typeset -a svn_path;
typeset -i verbose=0;

while [[ $# > 0 ]];
do
    case $1 in
        -v) (( verbose=1 ));;
        -)  shift; break;;
        -*) print -u2 "Usage: $0 [-v] ...";
            return 1;;
        *)  break;;
    esac;
    shift;
done;

if (( (( i=${*[(i)Develop]} )) <= $# ));
then                                    # process path in Develop tree
    if (( (( j=${*[(i)Product]} )) <= $# && (( j > i)) ));
    then
        svn_path=(${*[j+1,-1]});
    fi;
elif (( (( i=${*[(i)Release]} )) <= $# ));
then                                    # process path in Release tree
    svn_path=(${*[i,-1]});
    svn_path=(${(j. | .)${*[i,-1]}});
else                                    # process any other path
    svn_path=($*);
fi;

(( verbose > 0 ))   && print -u2 "svn_path: ${#svn_path} ${svn_path}";

if [[ $svn_path[2] == "trunk" ]];
then
    print ${svn_path[1,2]} ${${svn_path[3]}:+...};
elif [[ $svn_path[2] == 'branches' || $svn_path[2] == 'tags' ]];
then
    print ${svn_path[1,2]}${${svn_path[3]}:+:${svn_path[3]}} ${${svn_path[4]}:+...};
else
    print $svn_path;
fi;

return;
}

#

function svn_prompt
{
typeset svn_info=${$(svn_info)//\%/\%\%};
typeset svn_path=;

[[ $svn_info == "" ]] &&    return;

#for i in   \
#   'svn://svn-sdg.cites.illinois.edu/Project/Foo%%20Bar'               \
#   'svn://svn-sdg.cites.illinois.edu/Project'                          \
#   'svn://svn-sdg.cites.illinois.edu/Project/Foo'                      \
#   'svn://svn-sdg.cites.illinois.edu/Project/Foo/trunk'                \
#   'svn://svn-sdg.cites.illinois.edu/Project/Foo/trunk/bar'            \
#   'svn://svn-sdg.cites.illinois.edu/Project/Foo/branches'             \
#   'svn://svn-sdg.cites.illinois.edu/Project/Foo/branches/roma'        \
#   'svn://svn-sdg.cites.illinois.edu/Project/Foo/branches/roma/foo'    \
#   'svn://svn-sdg.cites.illinois.edu/Project/Foo/tags'                 \
#   'svn://svn-sdg.cites.illinois.edu/Project/Foo/tags/release-0.0'     \
#   'svn://svn-sdg.cites.illinois.edu/Project/Foo/tags/release-0.0/bar' \
##  'file:///home/sdg-svn/repos/Project/Bar/trunk'                      \
##  'file:///home/sdg-svn/repos/Project/Bar/tags'                       \
##  'file:///home/svn/repos/Foo/trunk'                                  \
##  'file:///home/svn/repos/Foo/trunk/foo'                              \
##  'file:///home/svn/repos/Foo/tags'                                   \
##  'file:///home/svn/repos/Foo/tags/foo'                               \
#   ;
#do
#   ...
#done;

case ${svn_info} in
    file://*)
        svn_path=$(svn_path ${(s:/:)${(SR)svn_info#file://}});
        ;;
    *)
#   svn://*)
        svn_path=$(svn_path ${(s:/:)${(SR)svn_info#[^/]*//[^/]*/}});
        ;;
esac;

typeset svn_dirty;
typeset svn_prefix;
typeset svn_suffix;

#   handle color terminal

if [[ $terminfo[colors] -ge 8 ]];
then
    svn_prefix="%{$fg[cyan]%}";

    #   change prefix color if anything needs a commit
    svn_status ||   svn_prefix="%{$fg_bold[yellow]%}";
    print "${svn_prefix}${svn_path}%{$reset_color%} ";
    return;
fi;

#   handle non-color terminal

if ! svn_status;                        # does anything need a commit?
then
    svn_dirty='%{%S%}[*]%{%s%} ';
    svn_prefix='%{%B%}';
    svn_suffix='%{%b%}';
fi;

print "${svn_dirty}${svn_prefix}${svn_path}${svn_suffix} ";
return;
}

#

function svn_status
{
return $(svn status --quiet --ignore-externals \
            2> /dev/null | wc -l | awk '{ print $1; }');
}

#

function tmpdir()
{
[[ $# != 0 ]] &&    { print -u2 "Usage: $0"; return 1; }

typeset parent='/scratch';
typeset name=${USER:-$LOGNAME};

[[ ! -d $parent ]] &&       parent='/var/tmp';
[[ ! -d $parent ]] &&       parent='/usr/tmp';

[[ ! -d $parent/$name ]] && mkdir $parent/$name;
pushd $parent/$name;
return;
}

#   

function scl_enable
{
local    base_path;
local    dir
local    scl;
local    scl_prefix;
local -a scl_list;
local -a temp;
local    usage="Usage: $0 [-v]";
local -i verbose=0;

while (( $# > 0 ));
do
    case $1 in
        -v) (( verbose++ ));;
        -)  shift; break;;
        -*) print -u2 $usage; return 1;;
        *)  break;;
    esac
    shift;
done;

if (( $# != 0 ));
then
    print -u2 $usage;
    return 1;
fi

#   Check whether process is running in a SCL, and whether SCL prefixes
#   directory exists. Return with error otherwise.

if [[ $X_SCLS == '' || ! -d /etc/scl/prefixes ]];
then
    (( verbose >= 1 )) && print -u2 "$0: software collections not enabled"; 
    return 1;
fi;

scl_list=(${(z)X_SCLS});

#   Iterate over enabled collections.

for scl in $scl_list;
do
    #   Find prefixes file for this SCL, and skip with error if not found.
    scl_prefix=/etc/scl/prefixes/${scl};

    [[ ! -e $scl_prefix ]] && \
        { print -u2 "scl prefix file ${scl_prefix}: not found"; return 1; }

    #   Determine base path for this SCL.
    base_path=$(cat $scl_prefix);

    #   Add appropriate directory paths for this SCL to the path and manpath
    #   arrays.
    add_path -p path    "${base_path}/${scl}/root/usr/bin";
    add_path -p manpath "${base_path}/${scl}/root/usr/share/man";

    #   Add appropriate directory path for this SCL to the LD_LIBRARY_PATH
    #   environment variable.
    add_path -p LD_LIBRARY_PATH "${base_path}/${scl}/root/usr/lib64";

    #   Detect running version of Python.
    local python_version=$(python -c \
                           "from __future__ import print_function; \
                            from distutils.sysconfig import get_python_version; \
                            print(get_python_version());");

    #   Add appropriate directory paths for this SCL to the PYTHONPATH
    #   environment variable.
    add_path -p PYTHONPATH  \
        "${base_path}/${scl}/root/usr/lib/python${python_version}/site-packages"    \
        "${base_path}/${scl}/root/usr/lib64/python${python_version}/site-packages"  \
        ;
    continue

    (( verbose >= 1 )) &&   print -u2 "$0: $scl software collection enabled";

done;
return;
}

#   

function xtitle
{
[[ $TERM != *xterm* ]] &&   { print -u2 "$0: not an xterm"; return 1; }

typeset    xtitle_lock=${xtitle_lock:-0};
typeset -i code=0;
typeset -i lock=${xtitle_lock:-0};

while [[ $# > 0 ]];
do
    case $1 in
        -b) code=0;;
        -i) code=1;;
        -l) lock=1;;
        -t) code=2;;
        -u) lock=0;;
        -)  shift; break;;
        -*) print -u2 "Usage: $0 [-b] [-i] [-t] title ...";
            return 1;;
        *)  break;;
    esac;
    shift;
done;

[[ $# = 0 || "$@" = "" ]] &&    { print -u2 "$0: no title"; return 1; }

[[ $xtitle_lock -ne 0 && $lock -eq 0 ]] &&  xtitle_lock=0;

if [[ $xtitle_lock -eq 0 ]];
then
    exec 3>&1;
    print -u3 -n "\033]${code};$@\007";
    exec 3>&-;
fi;

[[ $xtitle_lock -eq 0 && $lock -ne 0 ]] &&  xtitle_lock=1;

return 0;
}

#   

umask 022;

typeset -x HISTSIZE=5000;       # save this many history entries
typeset    PERIOD=10;           # periodic() function runs this often

#   set search path

path=(/usr/bin /bin);

add_path -p path /opt/local/bin;
add_path -p path /usr/local/bin;

[[ $LOGNAME != "root" ]] && add_path -p path ~/bin;

add_path path               \
    /sbin                   \
    /usr/sbin               \
    /opt/sfw/bin            \
    /opt/sfw/cups/bin       \
    /opt/SUNWspro/bin       \
    /usr/local/oracle       \
    /usr/ccs/bin            \
    /usr/sfw/bin            \
    /usr/vac/bin            \
    /usr/perl5/bin          \
    /usr/local/sbin         \
    /usr/local/oracle       \
    /usr/bin/X11            \
    /etc/alternatives/jre   \
    /etc/alternatives/jre/bin   \
    $HOME/bin               \
        ;

#   set up manpath

add_path manpath            \
    /usr/share/man          \
    /opt/sfw/man            \
    /opt/sfw/cups/man       \
    /opt/SUNWspro/man       \
    /opt/local/share/man    \
    /usr/local/man          \
    /usr/local/share/man    \
    /usr/X11/man            \
    ;

#   Do path munging for any enabled software collections.
scl_enable;

#   set aliases
alias anki='/Applications/Anki.app/Contents/MacOS/Anki -b /Users/maiko/Dropbox/Anki/AnkiData &'

alias paos='ssh idm-soap@paos-dev.cites.illinois.edu';
alias kasumi='ssh maiko@c-38-124-116-104.dyn.uc2b.net';
alias ic2g='ssh maiko@spacereq-dev.cites.illinois.edu';
alias ic2gtest='ssh maiko@spacereq-test.cites.illinois.edu';
alias cab='ssh maiko@caboose.cites.illinois.edu';

alias xledger='ssh -X maiko@ledger-dev.cites.illinois.edu';
alias ledger='ssh maiko@ledger-dev.cites.illinois.edu';
alias xledgerqa='ssh -X dir-svcs@ledger-qa.cites.illinois.edu';
alias ledgerqa='ssh dir-svcs@ledger-qa.cites.illinois.edu';
alias suledger='ssh dir-svcs@ledger-dev.cites.illinois.edu';
alias suxledger='ssh -X dir-svcs@ledger-dev.cites.illinois.edu';
alias ledgertest='ssh -X dir-svcs@ledger-test1.cites.illinois.edu';

alias maiko='ssh devbox-maiko.cites.illinois.edu';
alias sumaiko='ssh sdgdev-maiko@devbox-maiko.cites.illinois.edu';
alias xmaiko='ssh -X devbox-maiko.cites.illinois.edu';
alias xxqaa='ssh -Y maiko@devbox-qaa.cites.illinois.edu';
alias suxxqaa='ssh -Y qaa-dev@devbox-qaa.cites.illinois.edu';

alias claim='ssh maiko@shadow-dev.cites.illinois.edu';

alias nim='ssh maiko@nimbus-dev.cites.illinois.edu';
alias nit='ssh maiko@nimbus-test.cites.illinois.edu';
alias sunim='ssh cloudbroker-svc@nimbus-dev.cites.illinois.edu';
alias sunit='ssh cloudbroker-svc@nimbus-test.cites.illinois.edu';

alias c=clear;
alias d=dirs;
alias dv='dirs -v';
alias g=grep;
alias h='history -$HISTSIZE';
alias hup='kill -HUP';
alias j=jobs;
alias jobs='jobs -l';
alias ksh="$SHELL";
alias la=uptime;
alias l='ls -ksFC';
alias ll='ls -hlsF';
alias ls='ls -kFC';
alias lsd='ls -adhlsF';
alias printenv='typeset -x';
alias sh="$SHELL";
alias svn_setkw="svn pset svn:keywords 'Author Date Id Revision URL'";
alias vv='fc -e - vi\ ';
alias collections='scl enable python27 sdg_2015a_python27 rh-postgresql94 zsh'

if df -H > /dev/null 2>&1;
then
    alias   df='df -H';
else
    alias   df='df -k';
fi;

#   set up locate and llocate aliases if appropriate

if whence locate > /dev/null && [[ -f /var/locate/locatedb ]];
then    alias locate='locate -d /var/locate/locatedb';
fi;

if [[ -f $HOME/lib/locatedb ]];
then
    if whence glocate > /dev/null;
    then
    #   alias llocate='glocate -d $HOME/lib/locatedb';
        llocate='glocate -d $HOME/lib/locatedb';
    elif whence locate > /dev/null;
    then
    #   alias llocate='locate -d $HOME/lib/locatedb';
        llocate='locate -d $HOME/lib/locatedb';
    else
        unset llocate;
    fi;
fi;

whence gmake > /dev/null    && alias make=gmake;

typeset -x ENSCRIPT='-q';
typeset -x LANG;

if [[ $(uname) = "Darwin" ]];
then
    LANG=en_US.UTF-8;
else    
    LANG=C;
fi;

#   set up path for man pages

typeset -x MANPATH; 

setprinter;

#   set up editor

typeset -x EDITOR;

autoload -U zsh/terminfo;

#   if terminal can display 8 or more colors, load zsh colors module
#   and set up various environment variables to use color

if [[ $terminfo[colors] -ge 8 ]];
then
    autoload -U colors;
    colors;
    typeset -x CLICOLOR=y;
    typeset -x LSCOLORS='gxfxcxdxbxegedabagacad';
fi;

if [[ $TERM = xterm* && $DISPLAY != "" ]] && whence gvim > /dev/null;
then
    EDITOR=gvim;
elif whence vim > /dev/null;
then
    EDITOR=vim;
else
    EDITOR=vi;
fi

alias vi=$EDITOR;
alias view="$EDITOR -R";

#   set up pager alias

typeset -x PAGER;

if whence less > /dev/null;
then
    typeset -x PAGER=$(whence less);
    alias more='less';
    typeset -x LESS=-MRs;
    if [[ $LANG = 'en_US.UTF-8' ]];
    then
        typeset -x LESSCHARSET=utf-8;
    else
        typeset -x LESSCHARSET=latin1;
    fi;
else
    typeset -x PAGER=$(whence more);
    typeset -x MORE=-s;
fi;

#   If postgres is installed, set host for it
if [[ -d $HOME/lib/pgsql ]];
then
    typeset -x PGHOST=$HOME/lib/pgsql;
fi;


# Set java properties
typeset -x JAVA_HOME=/etc/alternatives/jre

# Set python startup
typeset -x PYTHONSTARTUP=/home/maiko/.pystartup

# Add my local pip stuff to path
typeset -x PATH=$PATH:/home/maiko/.local/bin/

# Add pip python installs to pythonpath
typeset -x PYTHONPATH=$PYTHONPATH:/home/maiko/.local/lib/python2.7/site-packages
# Add CheezShop root to pythonpath
typeset -x PYTHONPATH=$PYTHONPATH:/home/maiko/.local/lib/python2.7/site-packages/CheezShop

#   set zsh options

setopt ignore_eof;              # explicitly require exit or logout
setopt interactive_comments;    # allow comments in interactive shells
setopt list_types;              # include type in file completion lists
unsetopt notify;                # only report bg job status at prompt
setopt vi;                      # use vi mode for zsh line editor
setopt zle;                     # use the zsh line editor

setprompt;

# Set term colors.
typeset -x TERM=xterm-color;

#print "processed .zshrc";
