# FZF History Search
__fzf_history_search() {
  BUFFER=$(history | awk '{$1=""; print substr($0,2)}' | tac | awk '!seen[$0]++' | fzf --tac --query="$READLINE_LINE")                                                                        
  READLINE_LINE="$BUFFER"
  READLINE_POINT=${#BUFFER}
}

bind -x '"\C-r": __fzf_history_search'
