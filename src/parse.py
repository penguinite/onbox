#!/bin/python3
# A test implementation
# of the config lang parser
# in Python.
import os

table = {}
f = open("./src/pothole.conf")
countl = 0
countc = 0
flags = [
    False, # Array flag 0
    "", # A place to store keys 1
    "", # A place to store vals 2
    [], # A place to store vals (Arrays) 3
    False, # Did we previously process an array. 4
    False, # Are we processing something flag (Arrays) 5
    False, # Backslash flag for arrays 6
]
for line in f.readlines():
    line = line.strip()
    if line.startswith("#"):
        continue
    # Store only the lines that are useful for us.
    countl += 1

    flags[4] = flags[0]
    # Let's do some char-by-char parsing
    for char in line.strip():
        countc += 1
        # We enter character by character parsing
        # because I want to suffer
        if flags[0] == False:
            continue

        if char == '"':
            if flags[5] == True:
                flags[5] = False
                flags[3].append(flags[2])
                flags[2] = ""
            else:
                flags[5] = True

        if '\\' in char:
            if flags[6] == True:
                flags[2] += '\\' + char 
            else:
                flags[6] = True

        # End array!
        if char == "]" and flags[5] == False:
            flags[0] = False
            flags[4] = True
            continue

        if flags[5] == True:
            flags[2] += char
            continue

    # Split by equal sign
    if flags[0] == False and "=" in line:
        equalSplit = line.split("=")

        if equalSplit[0] == '':
            continue # No key value, so we skip
        flags[1] = equalSplit[0]

        if flags[4] == False:
            if equalSplit[1].startswith("["):
                flags[0] = True # Set array flag to true
            else:
                flags[2] = equalSplit[1]
    
    # Add the key-value pair to the dictionary
    # Unless we are in the middle of processing
    # an array
    if flags[0] == False:
        if flags[4] == False:
            # Remove quote marks in the start
            # And end if they exist
            if flags[2].startswith('"'):
                flags[2] = flags[2][1:]
            if flags[2].endswith('"'):
                flags[2] = flags[2][:len(flags[2]) - 1]
            
            # Now we add the key-value pair into the dict.
            table[flags[1]] = flags[2]
            flags[1] = ""
            flags[2] = ""
        else:
            table[flags[1]] = flags[3]
            flags[1] = ""
            flags[2] = ""
            flags[3] = []
            flags[4] = False

print(table)