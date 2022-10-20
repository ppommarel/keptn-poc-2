#!/bin/bash
# 
# parameters :
# run-gattling.sh <id_sim> <payloadFile> <timeframe>
# call gatling API to launch sim 

templateDataFile=$2
timeFrame=$3

echo "launching simulation for $timeFrame seconds"
#replace timeframe in payload
payloadData=$(sed  's/_TIMEFRAME_/'$timeFrame'/g' $templateDataFile)


runId=$(curl -s  --location --request POST 'https://cloud.gatling.io/api/public/simulations/start?simulation='$1 --header 'Content-Type: application/json' --header 'authorization: ERQ7qy77c2yJfU2emebhrSWegj3WpsXgpTzGTZ5foq6IR-H9569I2lk5MJTjul77c' -d "$payloadData" | jq -r 'if .error then "error:"+.error_description elif .runId then .runId else "unknown" end')

if [[ "$runId" == *"error"* ]] ; then
  echo "error when calling api : $runId"
  exit 255
else
  echo "run id is $runId"
  runStatus=$(curl -s --location --request GET 'https://cloud.gatling.io/api/public/run?run='$runId  --header 'authorization: ERQ7qy77c2yJfU2emebhrSWegj3WpsXgpTzGTZ5foq6IR-H9569I2lk5MJTjul77c' --header 'Content-Type: text/plain' | jq .status)
  echo -n "run in progress :"
  while true 
  do
   if (( $runStatus == 5 )); then
      echo "tests finished - assertions successful"
      exit 0
   elif (( $runStatus == 6 )); then
      echo "tests stopped - auomatic"
      exit 255
   elif (( $runStatus == 7 )); then
      echo "tests stopped - interrupted by user"
      exit 255
   elif (( $runStatus > 7 )); then
      echo "tests failed"
      exit 255


   else 
     sleep 10 
     echo -n "."
     runStatus=$(curl -s --location --request GET 'https://cloud.gatling.io/api/public/run?run='$runId  --header 'authorization: ERQ7qy77c2yJfU2emebhrSWegj3WpsXgpTzGTZ5foq6IR-H9569I2lk5MJTjul77c' --header 'Content-Type: text/plain' | jq .status)
   fi
  done
fi
