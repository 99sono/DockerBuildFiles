#!/bin/bash
source ../../../commonScripts/lib.sh
load_env
docker_logs_follow_container "qwen-3.6-27b-mtp-dgx-spark"
