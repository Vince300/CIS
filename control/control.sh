#!/bin/bash

WHAT=$1 ; shift
COMMAND=$1 ; shift
CONTROL_FILE="$WHAT-$COMMAND.sh"

if ! [ -f "${WHAT}.txt" ]; then
    echo "Environment '$WHAT' not found" >&2
    exit 1
fi

if ! [ -f "$CONTROL_FILE" ]; then
    echo "Command '$COMMAND' not found" >&2
    exit 1
fi

while IFS='' read -r line || [[ -n "$line" ]]; do
    echo "$COMMAND on $line" >&2
    ssh -i ../keys/id_cis_admin admin@$line 'sudo bash -s' <"$CONTROL_FILE"
done < ${WHAT}.txt

