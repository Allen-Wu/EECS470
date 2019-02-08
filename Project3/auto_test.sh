#!/bin/bash

###########################################################
# This is a bash script for auto testing EECS470 Project3 #
###########################################################
assembler=vs-asm
DIR=/home/shiyuwu/EECS470/Project3
FILES=/home/shiyuwu/EECS470/Project3/test_progs/*.s
GROUND_TRUTH_FILES=/home/shiyuwu/temp/project3
GREEN='\033[4;32m'

rm ${DIR}/test_output/*
rm ${GROUND_TRUTH_FILES}/test_output/*

for file in $FILES; do
    # Assemble the file into binary format
    echo "Assemble $(basename $file)"
    ./$assembler $file > program.mem
    cp program.mem ${GROUND_TRUTH_FILES}/program.mem
    # Make
    echo "Running the testcase $(basename $file) on my implementation"
    make > /dev/null 2>&1
    mv writeback.out test_output/$(basename $file)_writeback.out
    cat program.out | grep "@@@" > test_output/$(basename $file)_program.out
    echo "Remove the binary files"
    rm program.mem
    echo "Make clean"
    make nuke > /dev/null 2>&1

    # Run on the ground truth files
    echo "Generate the ground truth!"
    cd $GROUND_TRUTH_FILES
    make > /dev/null 2>&1
    mv writeback.out test_output/$(basename $file)_writeback.out
    cat program.out | grep "@@@" > test_output/$(basename $file)_program.out
    echo "Remove the binary files"
    rm program.mem
    echo "Make clean"
    make nuke > /dev/null 2>&1

    diff ${DIR}/test_output/$(basename $file)_writeback.out ${GROUND_TRUTH_FILES}/test_output/$(basename $file)_writeback.out

    if [ $? -eq 0] then
        echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
        echo "@@@FAIL the test for $(basename $file)@@@"
        echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    else
        echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
        echo "@@@PASS the test for $(basename $file)@@@"
        echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    fi

    cd $DIR
done

# echo Assemble the assembly files!
# ./$assembler < test_progs/btest1.s > program.mem