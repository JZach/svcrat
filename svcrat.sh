#!/bin/bash

declare -r CONFIG_FILE='/usr/local/etc/svcrat/svcrat.conf'
declare CONFIG_CONTENT
declare -A SECTIONS

declare DELAY
declare WORKING_DIRECTORY
declare VERBOSITY_LEVEL

# -------------------------------------------------- start --
# tba
start() {

  #print ${lvl:-1} ${msg:-"Service Rat started ..."}

  while :
  do

    for s in "${!SECTIONS[@]}"
    do

      # read service params
      local port=$(_get_property ${section:-$s} ${property:-"port"})
      local description=$(_get_property ${section:-$s} ${property:-"description"})
      local path=$(_get_property ${section:-$s} ${property:-"path"} ${default:-"$WORKING_DIRECTORY/$s/$port"}) 
      local ipv4=$(_get_property ${section:-$s} ${property:-"ipv4"})
      local init_state=$(_get_property ${section:-$s} ${property:-"init_state"} ${default:-x})

      # check service availability
      eval "nc -z $ipv4 $port"
      local current_state=$( [[ $? = 0 ]] && echo 1 || echo 0 )
      
      # save previous state
      local previous_state=${SECTIONS["$s"]}

      # save the state of the service for the next cycle
      SECTIONS["$s"]=$current_state

      # save the state (" 'previous state' + 'current state' ")
      local state="$previous_state$current_state"

      # if "previous_state" (set in config:init_state) is set to "skip" -> skip further processing
      [[ $previous_state == skip ]] && continue

      print ${lvl:-1} ${msg:-"[ $previous_state -> $current_state ]\t$s\t$ipv4:$port"}

      # create any missing directory
      [ ! -d "$path/$state" ] && mkdir -p "$path/$state"
      
      # execute matching scripts
      svcrat_name=$s \
      svcrat_description=$description \
      svcrat_path=$path \
      svcrat_ipv4=$ipv4 \
      svcrat_port=$port \
      run-parts --regex '.*sh$' "$path/$state"

    done   

    sleep $DELAY
  done
}

# -------------------------------------------------- print --
# tba
print() {
  [[ $1 > $VERBOSITY_LEVEL ]] && return
  echo -e "$2"
}

# -------------------------------------------------- _config --
# tba
_config() {
  CONFIG_CONTENT=$(_load_config)

  # load sections (w/o "global")
  local sections=($(echo "$CONFIG_CONTENT" | awk -F 'x' 'NR>1{print $1}' RS='[' FS=']'))
  sections=(${sections[@]/"global"})

  # store all sections in array with inital state
  for s in "${sections[@]}"
  do
    # get state that should be used until first check
    local init_state=$(_get_property ${section:-$s} ${property:-"init_state"})
    # assign init_state if valid, otherwise use 'x' ('unknown state') as default
    SECTIONS["$s"]=$([[ " (skip x 0 1) " =~ $init_state ]] && echo "$init_state" || echo "x")
  done    

  #read global properties
  DELAY=$(_get_property ${section:-"global"} ${property:-"delay"} ${default:-300})
  WORKING_DIRECTORY=$(_get_property ${section:-"global"} ${property:-"working-directory"})
  VERBOSITY_LEVEL=$(_get_property ${section:-"global"} ${property:-"verbosity-level"} ${default:-1})
}

# -------------------------------------------------- _load_config --
# tba
_load_config() {

    # read config-file
    local config=$(<$CONFIG_FILE)
    # remove all comments
    config=$(echo "$config" | grep -o '^[^#]*')
    # remove all blank lines
    config=$(echo "$config" | grep -v -e '^[[:space:]]*$')
    
    echo "$config"
}

# -------------------------------------------------- _get_property --
# tba
_get_property() {
  
  # read content of specified section
  local section=$(echo "$CONFIG_CONTENT" | sed -n '/\['$1'\]/,/\[/{/^\[.*$/!p}')
  
  # read specified key/value
  #local key=$(echo "$section" | awk -F '=' -v PROPERTY=$2 '$0~PROPERTY { gsub(/ /, "", $1); print $1}')
  local value=$(echo "$section" | awk -F '=' -v PROPERTY=$2 '$0~PROPERTY { gsub(/ /, "", $2); print $2}')

  # use $3 (default-value) if no value was specified
  [ -z "$value" ] && value="$3"

  echo "$value"
}

# -------------------------------------------------- main --
# main processing
main() {
  case "$1" in
    start)
      _config
      start
      ;;
    stop)
      stop
      ;;
  #status)
  #      ;;
  #restart|reload|condrestart)
  #      stop
  #      start
  #      ;;
    *)
      echo $"Usage: $0 {start|stop|restart|reload|status}"
      exit 1
  esac
  exit 0
}

main $1
