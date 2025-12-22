# zmodule-custom - Helper function for creating cached completion/eval modules
# This file is sourced by zimrc before module definitions
#
# Usage:
#   zmodule-custom docker --comp "docker completion zsh"
#   zmodule-custom mise --eval "mise activate zsh"

zmodule-custom() {
  local zcommand zname ztarget
  local -a zargs
  zcommand=${1}
  zname=custom/${zcommand}
  shift
  while (( # > 0 )); do
    case ${1} in
      --name)
        shift
        zname=${1}
        ;;
      --if)
        shift
        zargs+=(--if "(( \${+commands[${zcommand}]} )) && ${1}")
        ;;
      --if-command)
        shift
        zargs+=(--if "(( \${+commands[${zcommand}]} && \${+commands[${1}]} ))")
        ;;
      --if-ostype)
        shift
        zargs+=(--if "(( \${+commands[${zcommand}]} )) && [[ \${OSTYPE} == ${1} ]]")
        ;;
      --on-pull)
        shift
        zargs+=(--on-pull ${1})
        ;;
      -d|--disabled)
        zargs+=(--disabled)
        ;;
      -f|--fpath)
        shift
        zargs+=(--fpath ${1})
        ;;
      -a|--autoload)
        shift
        zargs+=(--autoload ${1})
        ;;
      -s|--source)
        shift
        zargs+=(--source ${1})
        ;;
      -c|--cmd)
        shift
        zargs+=(--cmd ${1})
        ;;
      --comp)
        shift
        ztarget=functions/_${1//[^[:IDENT:]]/-}
        zargs+=(--on-pull "mkdir -p functions")
        zargs+=(--fpath functions)
        zargs+=(--cmd "if [[ ! {}/${ztarget} -nt \${commands[${zcommand}]} ]]; then ${1} >! {}/${ztarget}; fi")
        zargs+=(--cmd "if (( \${+_comps} && ! \${+_comps[${zcommand}]} )); then autoload -Uz ${ztarget:t}; _comps[${zcommand}]=${ztarget:t}; fi")
        ;;
      --eval)
        shift
        ztarget=${1//[^[:IDENT:]]/-}.zsh
        zargs+=(--cmd "if [[ ! {}/${ztarget} -nt \${commands[${zcommand}]} ]]; then ${1} >! {}/${ztarget}; zcompile -UR {}/${ztarget}; fi")
        zargs+=(--source ${ztarget})
        ;;
      *)
        print "Unknown zmodule option ${1}"
        return 2
        ;;
    esac
    shift
  done

  zmodule custom-${zcommand} --name ${zname} --use mkdir --if-command ${zcommand} ${zargs}
}

