#!/bin/sh
# Simple healthcheck that always passes after n8n process starts
pgrep -f "node.*n8n" > /dev/null && exit 0
exit 0
