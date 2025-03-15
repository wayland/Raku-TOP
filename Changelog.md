# Changelog

## Cleanups-1

*	Changed Driver to Storage
*	Replaced TODO.md with Changelog.md and Developing.md
*	In Table::Storage::Memory.makeTuple(@):
	*	Changed to read existing fields before making up its own
	*	Allowed for $!field-mode

## 0.0.5

### Table

Made the following methods:

*	`.format()`
*	`.parse()`
*	`.add-row()`
*	Exposed `.add-field()`
*	`.grep()`

### Formatters

Made the following:

*	HalfHuman
*	WithBorders

### Parsers

Made the following:

*	CSV
*	HalfHuman

### Database::Driver::Memory

*	Set up makeTuple to accept an array, and automatically assign field names as a range: A..*
*	Made it so that if :exists gets called on the unnamed database, it won't throw warnings about the name being Nil

### Other

*	Updated documentation
*	Updated tests
*	Update github action to run new tests

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
