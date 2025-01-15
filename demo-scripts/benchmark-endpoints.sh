#!/bin/bash

GLOBAL_URL="http://miniedgeapp.trafficmanager.net/"
EAST_US_URL="http://miniedgeapp.eastus.cloudapp.azure.com/"

echo "Testing URL: $GLOBAL_URL"
RESULT1=$(curl -w "HTTP code: %{http_code}\nTotal Response Time: %{time_total}" -o /dev/null -s $GLOBAL_URL)
CODE1=$(echo "$RESULT1" | grep "HTTP code" | awk '{print $NF}')
TIME1=$(echo "$RESULT1" | grep "Total Response Time" | awk '{print $NF}')
echo "$RESULT1 seconds"

echo ""

echo "Testing URL: $EAST_US_URL"
RESULT2=$(curl -w "HTTP code: %{http_code}\nTotal Response Time: %{time_total}" -o /dev/null -s $EAST_US_URL)
CODE2=$(echo "$RESULT2" | grep "HTTP code" | awk '{print $NF}')
TIME2=$(echo "$RESULT2" | grep "Total Response Time" | awk '{print $NF}')
echo "$RESULT2 seconds"

echo ""

# Compare response times and determine which was faster
if (( $(echo "$TIME1 < $TIME2" | bc -l) )); then
  FASTER_URL=$GLOBAL_URL
  TIME_DIFF=$(echo "$TIME2 - $TIME1" | bc)
  echo "The faster request was to: $FASTER_URL by $TIME_DIFF seconds"
elif (( $(echo "$TIME1 > $TIME2" | bc -l) )); then
  FASTER_URL=$EAST_US_URL
  TIME_DIFF=$(echo "$TIME1 - $TIME2" | bc)
  echo "The faster request was to: $FASTER_URL by $TIME_DIFF seconds"
else
  echo "Both requests took the same amount of time."
  FASTER_URL=$GLOBAL_URL  # Default to GLOBAL_URL if times are equal
fi

# Print the response body of the faster request
FASTER_RESPONSE=$(curl -s $FASTER_URL)
echo "Respone: $FASTER_RESPONSE"
