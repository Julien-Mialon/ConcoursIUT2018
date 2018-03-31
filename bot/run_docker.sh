#!/usr/bin/env bash
usage="run_docker.sh [host] [port]"

docker run -w /bot/bot \
           -P \
           -ti mpoquet/bashbot \
           /bot/bot/run.sh $@
