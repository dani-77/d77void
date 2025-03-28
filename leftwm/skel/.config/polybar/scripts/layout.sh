#!/bin/bash

while :
do
  leftwm state -nq | jq -r '.workspaces[0].layout' | awk '{print tolower($0)}'
  sleep 1
done

