# Changelog

## Unreleased:

### Pagila

Altered the testing procedure to incorporate the Pagila database.  This will improve future tests

* Added pagila.dockerfile
* Adjusted docker-compose and pgpass to match pagila
* Had to tweak the GitHub action, because the Pagila files failed to load there

Unrelated changes:
* Updated #! line in project to work with environmental raku
* Removed tabs from Dan line in README

## 0.0.7

### Missing-Module-Bugfixes

* Added in a bunch of "depends" and "provides"
* Moved "data" to "resources", and adjusted code so that it'll read %?RESOURCES

## 0.0.6: Cleanups-1

*	Changed Driver to Storage
*	Replaced TODO.md with Changelog.md and Developing.md
*	In Table::Storage::Memory.makeTuple(@):
	*	Changed to read existing fields before making up its own
	*	Allowed for $!field-mode
*	Ensured that documentation builder sensibly puts links into directories
*	Broke field modes out into their own classes

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
```
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
```
