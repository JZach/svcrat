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

  #echo "DELAY = '$DELAY'"
  #echo "WORKING_DIRECTORY = '$WORKING_DIRECTORY'"
  #echo "VERBOSITY_LEVEL = '$VERBOSITY_LEVEL'"

  while :
  do

    for s in "${!SECTIONS[@]}"
    do
      #echo "'$s'"
      local port=$(_get_property ${section:-$s} ${property:-"port"})
      local description=$(_get_property ${section:-$s} ${property:-"description"})
      local path=$(_get_property ${section:-$s} ${property:-"path"} ${default:-"$WORKING_DIRECTORY/$s/$port"}) 
      local ipv4=$(_get_property ${section:-$s} ${property:-"ipv4"})
      local init_state=$(_get_property ${section:-$s} ${property:-"init_state"} ${default:-x})

      #echo "description: $description"
      #echo "path: $path"
      #echo "ipv4: $ipv4"
      #echo "port: $port"
      #echo "init_state: $init_state"

      ####

      eval "nc -z $ipv4 $port"
      local svc_state=$( [[ $? = 0 ]] && echo 1 || echo 0 )
     

      # first run?
      if [[ ${SECTIONS["$s"]} == x ]]
      then
        #echo "FIRST STATE: "
        case $init_state in
          0|1)
            SECTIONS["$s"]=$init_state
            ;;
          skip)
            #echo -n "SKIPPED"
            SECTIONS["$s"]=$svc_state
            continue
            ;;
        esac
      fi

      local current_state=${SECTIONS["$s"]}$svc_state
      print ${lvl:-1} ${msg:-"[ ${SECTIONS["$s"]} -> $svc_state ]\t$s\t$ipv4:$port"}

      SECTIONS["$s"]=$svc_state

      ## !?! SKIP HERE !??! ##

      ### what to do?

      [ ! -d "$path/$current_state" ] && mkdir -p "$path/$current_state"
      
      svcrat_description=$description \
      svcrat_path=$path \
      svcrat_ipv4=$ipv4 \
      svcrat_port=$port \
      svcrat_init_state=$init_state \
      run-parts --regex '.*sh$' "$path/$current_state"

    done   

    sleep $DELAY
  done
}

# -------------------------------------------------- print --
# tba
print() {
  [[ $1 > $VERBOSITY_LEVEL ]] && return

  #date=$(date '+%d/%m/%Y %H:%M:%S');
  #echo -e "$date\t$2"
  echo -e "$2"
}

# -------------------------------------------------- _config --
# tba
_config() {
  CONFIG_CONTENT=$(_load_config)

  #load sections (w/o "global")
  local sections=($(echo "$CONFIG_CONTENT" | awk -F 'x' 'NR>1{print $1}' RS='[' FS=']'))
  sections=(${sections[@]/"global"})

  for s in "${sections[@]}"
  do
    SECTIONS["$s"]="x"
  done    

  #read global properties
  DELAY=$(_get_property ${section:-"global"} ${property:-"delay"})
  WORKING_DIRECTORY=$(_get_property ${section:-"global"} ${property:-"working-directory"})
  VERBOSITY_LEVEL=$(_get_property ${section:-"global"} ${property:-"verbosity-level"})
}

# -------------------------------------------------- _load_config --
# tba
_load_config() {

    #local __resultvar=$1
    local config=$(<$CONFIG_FILE)
    #remove comments
    config=$(echo "$config" | grep -o '^[^#]*')
    #remove blank lines
    config=$(echo "$config" | grep -v -e '^[[:space:]]*$')
    
    echo "$config"
}

# -------------------------------------------------- _get_property --
# tba
_get_property() {
  
  local section=$(echo "$CONFIG_CONTENT" | sed -n '/\['$1'\]/,/\[/{/^\[.*$/!p}')
  local key=$(echo "$section" | awk -F '=' -v PROPERTY=$2 '$0~PROPERTY { gsub(/ /, "", $1); print $1}')
  local value=$(echo "$section" | awk -F '=' -v PROPERTY=$2 '$0~PROPERTY { gsub(/ /, "", $2); print $2}')

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
