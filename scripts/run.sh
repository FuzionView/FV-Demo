#!/bin/bash

if [ -f /opt/FuzionView/scripts/$(hostname).sh ] && exec /opt/FuzionView/scripts/$(hostname).sh || exit 1
