# 0.0.5 iteration tasks
-	Get the tests working with it
-	Write POD and comments, and clean up
	-	Include moving the table below, under "How to deal with formats" to the doco
-	Commit to git
-	Review/Upload/Publicise to the fez ecosystem
-	If there are any interesting changes, announce on #raku

# Iterations

Moved to TODO.xml on PP-site

# Per-iteration tasks:
-	Start next coding iteration (ON A NEW BRANCH)
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
DONE	Module ready to use; publicise
	-	Announce on #raku
	-	Link to it from my TOP site -- maybe start replacing parts of Raku TOP with the doco I've written
DONE	Rewrite https://wayland.github.io/table-oriented-programming/Raku-TOP/Introduction.xml so that:
	-	The TODO list is a separate page
	-	The TODO list below (aka Iterations) is incorporated into it
	-	Maybe also TODO items from the code are incorporated
DONE	Clean up browser tabs relating to TOP




# How to deal with formats

Some things are only really used as storage (eg. Memory, Postgres).  Some things are only ever used as 
input/output (eg. HalfHuman is the output of most Unix commands).

Format		Storage	Parser	Formatter	POP Format
------		-------	------	---------	----------
## Existing (at least partially)
Memory		Yes	No	No
Postgres	Yes	No	No
HalfHuman	?	Yes	Yes
WithBorders	No	No	Yes
## Make next
CSV		Make	Make	Make
## Waiting on Plex-Oriented Programming (POP)
HTML		Make	Make	Make		XML
Spreadsheet	Make	No	No		XML
JSON		Make	Make	Make		JSON
Pod6		?	?	Make		AST

## Not planning, but would gladly accept
SQLite		No	No	No
MySQL		No	No	No
Postgres option with not using cursors (has to support both cursor and non-cursor)
		No	No	No
