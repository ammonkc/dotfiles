# ===== Basics

setopt AUTO_CD          # If you type foo, and it isn't a command, and it is a directory in your cdpath, go there

# ===== Completion

setopt COMPLETE_IN_WORD # does completion from both ends for the cursor.
setopt ALWAYS_TO_END    # moves cursor to end of word if a full completion is inserted.
# setopt NO_CASE_GLOB   # makes globbing case insensitive (unless configured as above).
# setopt NO_LIST_BEEP   # doesn't beep on ambiguous completions.

# ===== Prompt

setopt PROMPT_SUBST     # Enable parameter expansion, command substitution, and arithmetic expansion in the prompt

unsetopt MENU_COMPLETE
setopt AUTO_LIST            # Automatically list choices on ambiguous completion.
setopt AUTO_MENU            # Automatically list choices on ambiguous completion.
setopt AUTO_PARAM_SLASH
