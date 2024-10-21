# First Iteration Tasks
-	Module ready to use; publicise
	DONE	Announce on #raku
	-	Link to it from my TOP site -- maybe start replacing parts of Raku TOP with the doco I've written
-	Rewrite https://wayland.github.io/table-oriented-programming/Raku-TOP/Introduction.xml so that:
	-	The TODO list is a separate page
	-	The TODO list below (aka Iterations) is incorporated into it
	-	Maybe also TODO items from the code are incorporated
-	Clean up browser tabs relating to TOP
-	Start next coding iteration (ON A NEW BRANCH)

# 0.0.5 iteration tasks
-	Check whether changes to Memory module need to be moved to Driver/frontend, or to be duplicated in Postgres
-	Get the tests working with it
-	Write POD and comments, and clean up
-	Commit to git
-	Review/Upload/Publicise to the fez ecosystem
-	If there are any interesting changes, announce on #raku

# Iterations
-	Cleanups 1
	-	Change "Driver" to "Storage"
	-	Look at the TODO items in the code
	-	cf. also https://wayland.github.io/table-oriented-programming/Raku-TOP/Introduction.xml
-	CLI: Create table
	-	Command line tool to read things in/out of tables
	-	Start with the "tester" tool
	-	Look at options to Raku and Perl to see which ones I want to copy
-	CSV (Storage, Parser, and Formatter)
-	Or should I backend onto those other 2 things (Dan and DataQueryWorkflows)
-	HumanOnly Formatter (must be after CSV Parser)
	-	Use the CSV Parser to read the table characters for use in the HumanOnly Formatter -- see 
		data/BoxDrawingCharacters.csv.  Also make a script to check that none of the characters have
		identical descriptions (this will catch errors in my input)
-	Basic Colour:
	-	Add colour to HumanOnly and HalfHuman (strictly not allowed for HalfHuman, but could still be handy)
	-	cf. https://github.com/jc21/clitable/blob/master/src/jc21/CliTable.php
	-	At the end, see if there's anything from jc21/clitable that we still haven't included; field
		formatters, for example

# Iterations after JOP (Jungle-Oriented Programming)
-	HTML
-	Spreadsheet
	-	Do early because it's so different from Database; this will require less rewriting in future
	-	Spreadsheet (OpenOffice format)
-	Better colours
	-	Add colour to HTML/Spreadsheet (and cf. HumanOnly colours)
	-	If conditional formatting were supported, that'd be even cooler
-	Pod6
-	JSON

# Per-iteration tasks:
-	Write some code so that things work
-	Get the tests working with it
-	Write POD and comments, and clean up
-	Commit to git
-	Review/Upload to the fez ecosystem
-	If there are any interesting changes, announce on #raku

# Changelog

## 0.0.5
DONE	Human-only (output-only) & half-human (input/output)

## 0.0.1
DONE	Put in a copy of the artistic license; see if we can do dual license (Artistic + GPL)
DONE	Finish off tests for Memory and Postgres types
DONE	Write github tests based on DBIish (but comment out lots)
DONE	Write Pod doco
DONE	Go through and remove all the extraneous code
DONE	Register with zef/fez: https://docs.raku.org/language/modules#Upload_your_module_to_zef_ecosystem
DONE	Investigate registering with raku.land (so I can upload modules) -- uploading to fez might be enough




# How to deal with formats

Some things are only really used as storage (eg. Memory, Postgres).  Some things are only ever used as 
input/output (eg. HalfHuman is the output of most Unix commands).

Format		Storage	Parser	Formatter	JOP Format
------		-------	------	---------	----------
## Existing (at least partially)
Memory		Yes	No	No
Postgres	Yes	No	No
HalfHuman	?	Yes	Yes
HumanOnly	No	No	Yes
## Make next
CSV		Make	Make	Make
## Waiting on Jungle-Oriented Programming
HTML		Make	Make	Make		XML
Spreadsheet	Make	No	No		XML
JSON		Make	Make	Make		JSON
Pod6		?	?	Make		AST

