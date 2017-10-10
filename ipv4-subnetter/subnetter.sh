#!/bin/bash

CIDR=""
BASE_IP=""
IP_SUBSET=""
ENABLE_DEBUG=FALSE

log() {
	printf "$@ \n"
}

debug() {
	if [[ ! -z $ENABLE_DEBUG ]] && [[ $ENABLE_DEBUG == "TRUE" ]]; then
		printf "$@ \n"
	fi
}

validate_input() {
	debug "Inside validate_input()"

     if [[ $BASE_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
 	   debug "BASE_IP looks fine"
     else
       log "IP Address is not in the right format"
       exit
     fi

    if [[ -z $CIDR ]]; then
		log "CIDR of the input is empty. Cannot run the program."
		exit
	fi

	if [[ -z $IP_SUBSET ]]; then
		log "IP_SUBSET of the inpur is empty. Cannot run the program."
		exit
	fi
}

parse_input() {
	debug "Inside parse_input() $1 $2"
    CIDR=$(echo $1 | awk -F "/" '{print $2}')
    BASE_IP=$(echo $1 | awk -F "/" '{print $1}')
    IP_SUBSET=$2
    validate_input
    debug "CIDR: $CIDR, BASE_IP: $BASE_IP, IP_SUBSET: $IP_SUBSET"
}

logbase2() {
    local x=0
    for (( y=$1-1 ; $y > 0; y >>= 1 )) ; do
        let x=$x+1
    done
    echo $x
}

calculate_ips() {
	debug "Inside calculate_ips()"
    NUM_BITS=$(( 32 - CIDR ))
    NUM_IPS=$(( 2 ** NUM_BITS ))
    SUBSET=$(( NUM_IPS / IP_SUBSET ))
    IP_PREFIX=$(echo $BASE_IP | cut -d '.' -f1-3)
    IP_START_OFFSET=$(echo $BASE_IP | cut -d '.' -f4)

    debug "NUM_BITS: $NUM_BITS, NUM_IPS: $NUM_IPS, SUBSET: $SUBSET, IP_PREFIX: $IP_PREFIX, IP_START_OFFSET: $IP_START_OFFSET" 

    # Validate whether we have enough IPS to subnet
    MINIMUM_IPS_REQURED=$(( SUBSET * 3 + SUBSET ))
    debug "MINIMUM_IPS_REQURED: $MINIMUM_IPS_REQURED"

	# Calculate the ipsubnets
    if [ $NUM_IPS -le $MINIMUM_IPS_REQURED ]; then
    	for(( i=0; i < $IP_SUBSET; i++)) {
			IP_OFFSET=$(( SUBSET * i ))
       		IP_OFFSET=$(( IP_OFFSET + IP_START_OFFSET ))
        	SUBSET_CIDR=$(( 32 - $(logbase2 64) ))
			log "subnet=${IP_PREFIX}.${IP_OFFSET}/$SUBSET_CIDR network=${IP_PREFIX}.${IP_OFFSET} broadcast=${IP_PREFIX}.$(( IP_OFFSET + SUBSET - 1 )) gateway=${IP_PREFIX}.$(( IP_OFFSET + 1 )) hosts=$(( ${SUBSET} - 3 ))"
		}
	else
		log "Not enough IPS to divide in this case"
	fi
}

main() {
	debug "Inside main() $1 $2"
    if [[ $1 == "test" ]]; then
		test_program
	else
    	parse_input $@
    	calculate_ips
	fi
}

test_program() {
	debug "Inside test_program()"

	log "Test with the input 192.168.0.0/24 3"
	parse_input 192.168.0.0/24 3
    calculate_ips 192.168.0.0/24 3
	log "\n"

	log "Test with the input 192.168.0.0/24 4"
	parse_input 192.168.0.0/24 4
    calculate_ips 192.168.0.0/24 4
	log "\n"

	log "Test with the input 10.55.10.64/28 2"
	parse_input 10.55.10.64/28 2
    calculate_ips 10.55.10.64/28 2
	log "\n"

    log "Test with the input 10.55.10.64/28 6"
	parse_input 10.55.10.64/28 6
    calculate_ips 10.55.10.64/28 6
	log "\n"

}

usage() { 
	log "subnetter.sh <ip> <no of subnets>" 
	log "subnetter.sh test"
}

die () {
    usage
    exit 1
}

[ "$#" -ge 1 ] || die 

main $@
