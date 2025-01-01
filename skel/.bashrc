#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

export PATH=/home/dani77/.local/share/gem/ruby/3.3/bin:/home/dani77/.cargo/bin/:$PATH
export BW_SESSION="/0QznHKQoPH66uLvVVky9EBI4psdvFu6aaGAZnq1xrTc/evmeI0unw47ow1nXJaOb5N36NdWKt68X/WaNFOn0g=="

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias btop='btop --utf-force'

PS1='[\u@\h \w]\$ '
[ -n "$XTERM_VERSION" ] && transset --id "$WINDOWID" >/dev/null

case "$TERM" in
xterm*|rxvt*)
    # Show the currently running command in the terminal title:
    # http://www.davidpashley.com/articles/xterm-titles-with-bash.html
    show_command_in_title_bar()
    {
        case "$BASH_COMMAND" in
            *\033]0*)
                # The command is trying to set the title bar as well;
                # this is most likely the execution of $PROMPT_COMMAND.
                # In any case nested escapes confuse the terminal, so don't
                # output them.
                ;;
            *)
                echo -ne "\033]0;${BASH_COMMAND}\007"
                ;;
        esac
    }
    trap show_command_in_title_bar DEBUG
    ;;
*)
    ;;
esac
