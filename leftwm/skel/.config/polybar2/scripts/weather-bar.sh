#!/bin/bash

# Get weather information from wttr.in.
weather=$(curl -sS "wttr.in/41.6,-8.62?format=%C+%t+%h")

# Extract the weather condition, temperature, and humidity using regular expressions.
condition=$(echo "$weather" | grep -oE '^[[:alpha:] ]+[[:alpha:]]')
temperature=$(echo "$weather" | grep -oE '[+-]?[0-9]+°C')
humidity=$(echo "$weather" | grep -oE '[0-9]+%')

# Print the weather information.
echo "$condition $temperature $humidity"
