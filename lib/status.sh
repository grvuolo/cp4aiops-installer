#!/bin/bash

# 
# Sleep until all specified namespace's pods are running/completed.
#
function check-namespaced-pod-status {
    local namespace="$1"
    local timeout_min=$2
    #local total_pods="$3"
    local wc_all
    local wc_remaining
    log "--------------------------"

    finished=false
    for ((time=1;time<$timeout_min;time++)); do
        wc_all="`oc get po --no-headers=true -n $namespace | grep 'Running\|Completed' | wc -l  | xargs`"
        wc_remaining="`oc get po --no-headers=true -n $namespace | grep -v 'Running\|Completed' | wc -l | xargs`"
        
        log "Waiting for pods in ns ($namespace) to be running/completed... recheck in $time of $timeout_min mins: total = $wc_all; remaining = $wc_remaining"
        
        if [ $wc_remaining -le 0 ]; then
            # no more remaining
            finished=true
            log "DONE!"
            break
        else
            echo ""
            oc get po -n $namespace | grep -v 'Running\|Completed'
        fi

        # wait 60 seconds
        progress-bar 60
    done

    if [[ "$finished" == "false" ]]; then
        log "Hmm, timeout!"
        exit 99
    fi
}

# 
# Sleep until a specific object is present (as the signal of completion).
# Sample usage:
# - check-namespaced-object-presence "$NAMESPACE_CP4AIOPS" "route/ibm-cp4aiops-cpd" 10
#
function check-namespaced-object-presence {
    local namespace="$1"
    local kind_name="$2"
    local timeout_min=$3
    
    log "--------------------------"

    finished=false
    for ((time=1;time<$timeout_min;time++)); do
        exist_check="`oc get $kind_name --no-headers=true -n $namespace | wc -l | xargs`"
        log "Waiting for $kind_name in ns $namespace to be present... recheck in $time of $timeout_min mins"
        
        if [ $exist_check -eq 1 ]; then
            # yes, it's present
            finished=true
            log "Yep, it's present now!"
            break
        else
            echo ""
        fi

        # wait 60 seconds
        progress-bar 60
    done

    if [[ "$finished" == "false" ]]; then
        log "Hmm, timeout!"
        exit 99
    fi
}

# 
# Keep checking and displaying some log lines by a specific grep pattern
# Sample usage:
# - Check and wait "route/ibm-cp4aiops-cpd" presence and keep displaying last 3 lines of post actions status, with 10mins timeout
#   $ check-namespaced-object-presence-and-keep-displaying-logs-lines \
#       "$NAMESPACE_CP4AIOPS" \
#       "route/ibm-cp4aiops-cpd" \
#       "oc logs $( kgp -n ibm-cp4aiops | grep ibm-cp-data-operator | awk {'print $1'} ) -n $NAMESPACE_CP4AIOPS | grep -E '0010-infra x86_64   \|                \||0015-setup x86_64   \|                \||0020-core x86_64    \|                \|' | tail -3" \
#       10
#       
#
function check-namespaced-object-presence-and-keep-displaying-logs-lines {
    local namespace="$1"
    local kind_name="$2"
    local display_command="$3"
    local timeout_min=$4

    log "--------------------------"

    finished=false
    for ((time=1;time<$timeout_min;time++)); do
        exist_check="$( oc get $kind_name --no-headers=true -n $namespace | wc -l | xargs )"
        log "Waiting for $kind_name in ns $namespace to be present... recheck in $time of $timeout_min mins"

        # display logs
        execlog $display_command

        if [ $exist_check -eq 1 ]; then
            # yes, it's present
            finished=true
            log "Yep, it's present now!"
            break
        else
            echo ""
        fi

        # wait 60 seconds
        progress-bar 60
    done

    if [[ "$finished" == "false" ]]; then
        log "Hmm, timeout!"
        exit 99
    fi
}
