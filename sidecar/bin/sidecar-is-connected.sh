#!/bin/zsh
# Native Sidecar only (not Yam, not virtual alone)
system_profiler SPDisplaysDataType 2>/dev/null | grep -q 'Sidecar Display'
