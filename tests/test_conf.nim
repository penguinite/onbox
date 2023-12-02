echo "Test 02 - Configuration Parsing"

import potholepkg/conf

var exampleConfig = ""

for section, preKey in requiredConfigOptions.pairs:
  exampleConfig.add("\n[" & section & "]\n")
  for key in preKey:
    exampleConfig.add(key & "=\"Test value\"\n")
exampleConfig.add("\n[db]\nfilename=\"main.db\"")
echo exampleConfig

var configTable = setupInput(exampleConfig)

assert configTable.getString("db","filename") == "main.db"