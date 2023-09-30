echo "Test 02 - Configuration Parsing"

import potholepkg/conf
import std/strutils

var exampleConfig = ""

for x in requiredConfigOptions:
  exampleConfig.add("\n[" & x.split(":")[0] & "]\n")
  exampleConfig.add(x.split(":")[1] & "=\"Test value\"\n")

exampleConfig.add("\n[db]\nfilename=\"main.db\"")

echo exampleConfig

var configTable = setupInput(exampleConfig)

assert configTable.getString("db","filename") == "main.db"