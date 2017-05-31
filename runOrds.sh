#!/bin/bash
#

function startOrds() {
   java -jar $ORDS_HOME/ords.war standalone
}


########### SIGTERM handler ############
function _term() {
   echo "Stopping container."
   echo "SIGTERM received, shutting down ORDS!"
   pkill ords;
}

########### SIGKILL handler ############
function _kill() {
   echo "SIGKILL received, shutting down ORDS!"
   pkill -9 ords;
}

############# MAIN ################

# Set SIGTERM handler
trap _term SIGTERM

# Set SIGKILL handler
trap _kill SIGKILL

# Check whether ords is already setup
startOrds;

echo "#####################"
echo "ORDS IS READY TO USE!"
echo "#####################"


childPID=$!
wait $childPID
