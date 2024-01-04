#! bash oh-my-bash.module

#
# Prompt Template
# swimmingpolar@Korea  ~/_temp on []: master [!] → command
#

function _omb_theme_PROMPT_COMMAND() {
  # Last command status
  if [[ $? != 0 ]]; then
    ARROW_COLOR="RED"
    # else return count
  else
    ARROW_COLOR="WHITE"
  fi

  declare -A colors

  colors["BLACK"]="30m"
  colors["RED"]="31m"
  colors["GREEN"]="32m"
  colors["YELLOW"]="33m"
  colors["BLUE"]="34m"
  colors["MAGENTA"]="35m"
  colors["CYAN"]="36m"
  colors["WHITE"]="37m"
  colors["COMMENT_GREY"]="38;5;102m"
  colors["END"]="\[\e[0m\]"

  declare -A symbols
  symbols["EXCLAMATION"]="!"
  symbols["CIRCLE"]=$(echo -e '\uf111')
  symbols["CHECK"]=$(echo -e '\uebb1')
  symbols["DIRECTORY"]=$(echo -e '\ue5fe')
  symbols["BRANCH"]=$(echo -e '\uf418')
  symbols["ARROW"]="→"

  # Append new history lines to history file
  history -a

  color() {
    text=$1
    key=$2

    # default font config
    weight=$([[ $3 != "" ]] && echo "1;" || echo "")
    italic=$([[ $4 != "" ]] && echo "3;" || echo "")

    color="\[\e[$weight$italic${colors[$key]}\]$text${colors["END"]}"
    echo "$color"
  }

  count_git_files_status() {
    local files_count=0
    # count one of two
    # 1. untracked files to be added
    # 2. staged files to be committed
    #
    if [[ "$1" == "staged" ]]; then
      files_count=$(git diff --cached --numstat --name-only | wc -l)
    elif [[ "$1" == "untracked" ]]; then
      # in untracked count, it looks for modified and untracked files
      modified=$(git status --short --porcelain | grep -c "^.M")
      untracked=$(git status --short --porcelain | grep -c "^??")
      files_count=$(( $modified + $untracked ))
    fi

    echo $files_count
  }

  get_git_string() {
    # Check if the current directory is a Git repository
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
      return 0
    fi

    #
    # For git icon (such as [!]) 
    #
    staged=$(count_git_files_status "staged")
    untracked=$(count_git_files_status "untracked")

    # untracked files check comes first
    if [[ $untracked -gt 0 ]]; then
      git_status_mark=${symbols["EXCLAMATION"]}
    # check if there's a commit to make with staged files
    elif [[ $staged -gt 0 && $untracked -eq 0 ]]; then
      git_status_mark=${symbols["CIRCLE"]}
    fi

    if [[ $git_status_mark != "" ]]; then
      decorated_status_mark="$(color "[$git_status_mark]" "RED")"
    else
      decorated_status_mark="$(color "[" "WHITE")$(color ${symbols["CHECK"]} "GREEN")$(color "]" "WHITE")"
    fi

    #
    # For branch icon 
    # swimmingpolar@Korea  ~/_temp on []: master [!] → command
    #                                 icon
    
    # assess the current head (whether detached or not)
    local detached_state
    if [[ $(git status) == *"HEAD detached"* ]]; then
      detached_state=1
    fi

    git_branch=$(color "$(git branch --show-current)" "WHITE" "" "italic")
    # save branch name based on detached state
    if [[ $detached_state == 1 ]]; then
      decorated_branch_string="$(color "detached::" "RED" "" "italic")"
    else
      local branch_icon=$(color ${symbols["BRANCH"]} "WHITE")
      local branch_icon_enclosed="$(color "[" "MAGENTA")$branch_icon$(color "]: " "MAGENTA")"
      decorated_branch_string="$branch_icon_enclosed$git_branch"
    fi

    echo "$(color "on" "WHITE") $decorated_branch_string $decorated_status_mark "
  }

  # Template for easy work
  # swimmingpolar@Korea in DirIcon ~/_temp on []master [!] → 
  # \e[0m text \e[0m
  # PS1="\u@\H in $directory \w $(get_git_string)$arrow "

  local user=$(color '\u' "GREEN")
  local at=$(color '@' "WHITE")
  local host=$(color '\H' "YELLOW")
  local in=$(color "in" "WHITE")
  local directory=$(color ${symbols["DIRECTORY"]} "YELLOW")
  local cwd=$(color '\W' "BLUE")
  local on=$(color "on" "WHITE")
  local git=$(get_git_string)
  local arrow=$(color "${symbols["ARROW"]}" $ARROW_COLOR)

  PS1="$user@$host $directory $cwd $git$arrow "
}

_omb_util_add_prompt_command _omb_theme_PROMPT_COMMAND

