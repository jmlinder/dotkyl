# -*- sh -*-

# Handle bookmarks. This uses the static named directories feature of
# zsh. Such directories are declared with `hash -d
# name=directory`. Both prompt expansion and completion know how to
# handle them. We populate the hash with directories.
#
# With autocd, you can just type `~-bookmark`. Since this can be
# cumbersome to type, you can also type `@@` and this will be turned
# into `~-` by ZLE.

# From https://goo.gl/TkTGdM

__build_hash() {
    for link ($MARKPATH/*(N@)) {
        hash -d -- -${link:t}=${link:A}
    }
}

__() {
    MARKPATH=~/.dotkyl/bookmarks

    # Populate the hash
    __build_hash

    vbe-insert-bookmark() {
        emulate -L zsh
        LBUFFER=${LBUFFER}"~-"
    }
    zle -N vbe-insert-bookmark
    bindkey '@@' vbe-insert-bookmark

    # Manage bookmarks
    bookmark() {
        [[ -d $MARKPATH ]] || mkdir -p $MARKPATH
        if (( $# == 0 )); then
            # When no arguments are provided, just display existing
            # bookmarks
            for link in $MARKPATH/*(N@); do
                local markname="$fg[green]${link:t}$reset_color"
                local markpath="$fg[blue]${link:A}$reset_color"
                printf "%-30s -> %s\n" $markname $markpath
            done
        else
            # Otherwise, we may want to add a bookmark or delete an
            # existing one.
            local -a delete
            zparseopts -D d=delete

            if (( $+delete[1] )); then
                # With `-d`, we delete an existing bookmark
                [[ -z $1 ]] && echo 'Argument required - name of bookmark to delete' && return 1
                command rm $MARKPATH/$1
            else
                # Otherwise, add a bookmark to the current
                # directory. The first argument is the bookmark
                # name. `.` is special and means the bookmark should
                # be named after the current directory.
                local name=$1
                [[ $name == "." ]] && name=${PWD:t}
                ln -s $PWD $MARKPATH/$name
            fi
        fi
    }
} && __

b() { bookmark }
d() { bookmark -d $1 }
l() { bookmark | sort -t'>' -k2,2 }
s() { bookmark $1 && __build_hash }

__bookmark_comp() {
    _values `ls $MARKPATH`
}
compdef __bookmark_comp d
