The goal is to implement table-oriented programming in such a way as it 
integrates with Data-Oriented Programming.  

# Plans

Plans are currently being kept at [The TODO list]
(https://wayland.github.io/table-oriented-programming/Raku-TOP/TODO.xml).

At some point these will probably be converted to a ticketing system (maybe
GitHub Issues?)  

# Per-PR process

The following is a list of steps that you should be doing on your branch before
submitting a PR:

## Coding Stage
*	Create and check out a new branch for coding on
*	Write some code making the changes you want
*	Write some tests covering the new code/cases above; use
	`./project build && ./project test`
*	Clean up; this means that any debugging statements are removed, or
	somehow disabled
*	Commit to git and push to GitHub
*	Check that tests run successfully on GitHub as well.  Despite the
	use of Docker, I've sometimes seen differences
*	If tests pass, go on to the next stage

## Documentation Stage

*	Write POD and comments.  Style is to interleave doco with code.  
	Function ordering in a class is as follows:
	*	First, we have the regular functions that people will 
		normally want to call
	*	Then, functions that are only really useful to those writing 
		inherited classes
	*	Finally, functions that only need comments, not rakudoc,
		because they do things like eg. implement Associative or 
		Positional
*	Write up a nice Changelog entry (in Changelog.md) named after your 
	branch/issue.  Things that might help prompt your memory:
	*	Original ticket you're resolving
	*	Diffs
	*	Changelog messages
*	Do a commit here to keep the commits cleaner
*	Rebuild documentation
	*	Run `./project build-docs`
	*	Deal with any relevant errors (usually missing directories)
	*	Do another commit
	*	Review changes, including that the doco works in Github
*	Commit to git and push to GitHub

## Pull Request Stage

*	If tests pass, submit PR.  PR body should be Changelog entry
*	Merge branch to main

# Release Process

*	Create and check out a new branch for this release called `release-<version>`
*	Version Number:
	*	Update Changelog with relevant version number
	*	Update META6.json to have relevant version number
*	Review all the changes on this branch one final time
*	Do a release to Github/Fez using `./project release`
*	If there are any interesting changes, announce on #raku

