#!/bin/bash

CMD=${CMD:-./cluster-up/kubectl.sh}

function RunCmd {
    cmd=$@
    echo "Command: $cmd"
    echo ""
    bash -c "$cmd"
    stat=$?
    if [ "$stat" != "0" ]; then
        echo "Command failed: $cmd Status: $stat"
    fi
}

function ShowOperatorSummary {

    local kind=$1
    local name=$2
    local namespace=$3

    echo ""
    echo "Status of Operator object: kind=$kind name=$name"
    echo ""

    QUERY="{range .status.conditions[*]}{.type}{'\t'}{.status}{'\t'}{.message}{'\n'}{end}" 
    if [ "$namespace" == "." ]; then
        RunCmd "$CMD get $kind $name -o=jsonpath=\"$QUERY\""
    else
        RunCmd "$CMD get $kind $name -n $namespace -o=jsonpath=\"$QUERY\""
    fi
}

cat <<EOF
=================================
     Start of HCO state dump         
=================================

==========================
summary of operator status
==========================

EOF

ShowOperatorSummary  hyperconvergeds.hco.kubevirt.io hyperconverged-cluster kubevirt-hyperconverged  

RELATED_OBJECTS=`${CMD} get hyperconvergeds.hco.kubevirt.io hyperconverged-cluster -n kubevirt-hyperconverged -o go-template='{{range .status.relatedObjects }}{{if .namespace }}{{ printf "%s %s %s\n" .kind .name .namespace }}{{ else }}{{ printf "%s %s .\n" .kind .name }}{{ end }}{{ end }}'`

echo "${RELATED_OBJECTS}" | while read line; do 

    fields=( $line )
    kind=${fields[0]} 
    name=${fields[1]} 
    namespace=${fields[2]} 

    if [ "$kind" != "ConfigMap" ]; then
        ShowOperatorSummary $kind $name $namespace
    fi
done

cat <<EOF

========================
HCO operator related CRD
========================
EOF

echo "${RELATED_OBJECTS}" | while read line; do 

    fields=( $line )
    kind=${fields[0]} 
    name=${fields[1]} 
    namespace=${fields[2]} 

    if [ "$namespace" == "." ]; then
        echo "Related object: kind=$kind name=$name"
        RunCmd "$CMD get $kind $name -o json"
    else
        echo "Related object: kind=$kind name=$name namespace=$namespace"
        RunCmd "$CMD get $kind $name -n $namespace -o json"
    fi
done

cat <<EOF

========
HCO Pods
========

EOF

RunCmd "$CMD get pods -n kubevirt-hyperconverged -o json"

cat <<EOF

a===============
HCO Deployments
===============

EOF

RunCmd "$CMD get deployments -n kubevirt-hyperconverged -o json"

cat <<EOF
===============================
     End of HCO state dump    
===============================
EOF


