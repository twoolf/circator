#!/bin/sh

for i in `cat keyrings/live/blackbox-files.txt`; do
  blackbox_edit_end $i
done
