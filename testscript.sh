#!/usr/bin/env bash

echo "TESTING Entry checker"

frama-c -vernfr -keep-unused-functions all -nfr-entry-check testfiles/entry.h
frama-c -vernfr -keep-unused-functions all -nfr-entry-check testfiles/entry_f.h
 
echo -e "\n Done with entry checker"
echo -e "########################################\n\n"


echo "TESTING Static var checker"

frama-c -vernfr -nfr-static-vars testfiles/static.c 
frama-c -vernfr -nfr-static-vars testfiles/static_f.c

echo -e "\n Done with Static var checker"
echo -e "########################################\n\n"

echo "TESTING outgoing calls checker"

frama-c -vernfr -nfr-check-calls testfiles/whitelist.c
frama-c -vernfr -nfr-check-calls testfiles/whitelist_f.c

echo -e "\nDone with outgoing calls checker"
echo -e "########################################\n\n"

echo "TESTING Function pointer checker"

frama-c -vernfr -nfr-fun-ptrs testfiles/funptr.c
frama-c -vernfr -nfr-fun-ptrs testfiles/funptr_f.c

echo -e "\nDone with Function pointer checker"
echo -e "########################################\n\n"

