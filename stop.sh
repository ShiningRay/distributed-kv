#!/bin/sh

for i in logs/*.pid; do kill `cat $i`; done
