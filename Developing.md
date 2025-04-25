The goal is to implement table-oriented programming in such a way as it 
integrates with Data-Oriented Programming (the other components are
Tree-Oriented Programming and Logic Programming).  

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
*	Changelog (in Changelog.md):
	*	Create new entry by:
		*	Adding a new "Version" at the top called 
			"## Unreleased:"
		*	Add a sub-section for your branch called
			"### <branchname>"
	*	Write up a nice Changelog entry.  Things that might help 
		prompt your memory:
		*	Original ticket you're resolving
		*	git diffs
		*	git log messages
*	Do a commit here to keep the commits cleaner (ie. to keep the next
	step out of your main commit)
*	Rebuild documentation
	*	Run `./project build-docs`
	*	Deal with any relevant errors (usually missing directories)
	*	Do another commit
	*	Review changes, including:
		*	That the doco works in Github (and especially that 
			links work)
		*	That Changelog works on GitHub
*	Commit to git and push to GitHub

## Pull Request Stage

*	Check if tests pass; if not, bounce back to the Coding stage
*	Submit PR.  PR body should be Changelog entry
*	Repo owner will (after feedback) merge branch to main.  Merge
	Request body should be Changelog entry.  

# Release Process

*	Create and check out a new branch for this release called `release-<version>`
*	Merge any necessary branches/changes
*	Version Number:
	*	Update Changelog with relevant version number; give version a 
		name at this point
	*	Update META6.json to have relevant version number
*	Review all the changes on this branch one final time
*	Do a release to Github/Fez using `./project release`
*	If there are any interesting changes, announce on #raku


