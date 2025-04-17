use	v6.d;
use	TOP;

use	TOP::FieldMode;

=begin pod

=NAME Raku TOP Storage - The common driver for Raku TOP backends

=TITLE Raku TOP Storage

=SUBTITLE The common driver for Raku TOP backends

=AUTHOR Tim Nelson - https://github.com/wayland

=head1 Database::Storage

The parent class for all the different Database Drivers (backends).

=begin code

role	Database::Storage

=end code

=head2 Methods

=end pod
role	Database::Storage {
	has	Str	$.name;	#= Name of the database
	=begin pod
	=head3 .useTable

		method	useTable(Table :$table, *%params)

	Returns a table belonging to the database.  Parameters vary from driver to driver.
	=end pod
	method	useTable(Table :$table, *%params) {...}
	#method	useTable(Table :$table, Str :$action = 'use', :%fields = {}) {
	#method	useTable(Table :$table, *%params) {
	#method	useTable(Table :$table, Str :$filename) {

}

=begin pod

=head1 Table::Storage

=begin code

role	Table::Storage does Associative does Positional {

=end code

=head2 Attributes

=end pod

role	Table::Storage does Associative does Positional does TOP::Core {
	=begin pod
	=defn Field @.fields
	Stores the fields
	=end pod
	has	Field		@.fields;

	=begin pod
	=defn %.field-indices
	For looking up fields by name
	=end pod
	has				%.field-indices;

	has	Str			@!field-names;		# For keeping the fields in order

	=begin pod
	=head2 Methods
	=head3 .new

	Creates a Table::Storage.

		.new(Database::Storage :$database, Relation :$frontend-object, Str :$action, Str :%fields)

	Parameters to .new are:
	=defn Relation $frontend-object
	The frontend object that is using this backend object.
	=end pod
	has	Relation			$!frontend-object	is built is required;
	=begin pod
	=defn Database::Storage	:$database
	The Database::Storage with which this Table::Storage is connected.
	=end pod
	has	Database::Storage	$!database			is built;		# Links to the database
	# TODO: Make the above "is required" once the Memory driver supports it

	# The object that implements the field mode
	has	TOP::FieldMode	$!field-mode-object;

	# Only used during initialisation
	has	Bool		$!init-create = False;
	has	Bool		$!init-alter = False;
	has 			%.init-fields;		# Field definitions to be used during initialisation

	submethod	TWEAK(
			Table :$frontend-object,

			=begin pod
			=defn Str $action
			The action to take -- see the parameter of the same name on the frontend object
			=end pod
			Str :$action,

			=begin pod
			=defn Str %fields
			If relevant, the fields to use in creating/altering the table
			=end pod
			:%fields,

			=begin pod
			=defn Str	$field-mode = 'Automatic'

			$!field-mode could be one of the following:
			=item Automatic: extra fields create new columns (default); like a spreadsheet
			=item Error: extra fields create an error; like a RDBMS
			=item overflow: extra fields get stuck in a (JSON?) hash/object/assoc field; the name of the field is in $!overflow-field-name

			=end pod
			Str	:$field-mode = 'Automatic',

			=begin pod
			=defn Str	$overflow-field-name

			The name of the field the overflow fields get put in

			=end pod
			:$overflow-field-name where Str|Nil = Nil;
	) {
		my $name = $frontend-object.name;

		# Existence check, & set InitCreate
		given $action {
			when 'create' {
				self.exists(true-error => "Error: Relation '$name' already exists");
				$!init-create = True;
			}
			when /^(alter|use)$/ {
				self.exists(false-error => "Error: Can't find Relation '$name'");
			}
			when /^(can\-create|ensure)$/ {
				self.exists() or $!init-create = True;
			}
			default {
				die "Error: Unknown action '$action' when calling useTable";
			}
		}

		# Conformance check & set InitAlter
		if ! $!init-create and $action ~~ /^(alter|ensure)$/ {
			my Bool $conforms = self.relation-conforms(%fields);
			$conforms or $!init-alter = True;
		}

		# Set up Field Mode
		$!field-mode-object = self.load-library(
			type => "TOP::FieldMode::$field-mode",
			table => $!frontend-object,
			:$field-mode,
			:$overflow-field-name,
#			|%parameters
		);
	}

	=begin pod
	=head3 exists

	Returns True if the table already exists.

		method	.exists(Str :$true-error, Str :$false-error)

	If $true-error is passed, and the table exists, the function will die with the passed error.
	If $false-error is passed, and the table doesn't exist, the function will die with the passed error.

	=end pod
	method	exists(Str :$true-error, Str :$false-error) {
		my Bool $exists =  self.raw-exists();
		my $usename = $!database.name ?? $!database.name !! '(unnamed memory database)';
		  $exists and $true-error.defined  and die "{$true-error} in database '{$usename}'";
		! $exists and $false-error.defined and die "{$false-error} in database '{$usename}'";
		return $exists;
	}

	=begin pod
	=head3 format

	Outputs the current table using the specified formatter.  This is for
	outputting tables in ASCII, Unicode Box, CSV, and maybe someday HTML.  

	Parameters are:

	=end pod
	method	format(
		=begin pod
		=head4 Str $format = 'HalfHuman';

		Specifies what the output format is
		=end pod
		Str $format = 'HalfHuman', 
		=begin pod
		=head4 %parameters

		Parameters passed to TOP::Formatter::*.new()
		=end pod
		*%parameters
	) {
		my $formatter = $.load-library(
			type => "TOP::Formatter::$format",
			table => $!frontend-object,
			|%parameters
		);

		$formatter.prepare-table();
		$formatter.output-header();
		for self[0..*-1] -> $row {
			$formatter.output-row($row);
		}
		$formatter.output-footer();
		return $formatter.output;
	}

	=begin pod
	=head3 parse

	Reads data into a table from the specified format.  As with the above, this is
	for reading tables in ASCII, Unicode Box, CSV, and the like.  

	Parameters are:

	=end pod
	method	parse(
		=begin pod
		=head4 Str $format = 'HalfHuman';

		Specifies what the input format is
		=end pod
		Str :$format = 'HalfHuman', 
		=begin pod
		=head4 %parameters

		Parameters passed to TOP::Parser::*.new()
		=end pod
		*%parameters
	) {
		my $parser = $.load-library(
			type => "TOP::Parser::$format",
			table => $!frontend-object,
			|%parameters
		);
	}

	##### Abstracts
	method fill_from_aoh(@rows) {...}
	method	raw-exists() {...}	# Helper function for .exists, above

	# Associative interface, used for fields
	# 	Must: AT-KEY, EXISTS-KEY
	#	May: DELETE-KEY, ASSIGN-KEY, BIND-KEY, STORE

	# Field (Associative) key locator
	method AT-KEY(\key) is raw {
		Proxy.new(
			FETCH => {
				with %!field-indices.AT-KEY(key) {
					@!fields.AT-POS($_)
				}
				else { Nil }
			},
			STORE => -> $, \value {
				#				say "Storing " ~ join('#', key, value);
				with %!field-indices.AT-KEY(key) {
					@!fields.ASSIGN-POS($_, value)
				}
				else {
					my int $index = @!field-names.elems;
					@!field-names.ASSIGN-POS($index, key);
					%!field-indices.BIND-KEY(key, $index);
					@!fields.ASSIGN-POS($index, value);
				}
			}
		)
	}

	=begin pod
	=head3 .add-field

	Adds a field to the table

		.add-field(Table :$relation, Str :$name, Any:U :$type)
	=end pod
	method	add-field(
		# TODO: Try to replace "relation" with "self"; if that doesn't work, then document
		Table :$relation,

		=begin pod
		=defn Str $name
		The name of the field being added
		=end pod
		Str :$name,

		=begin pod
		=defn Any:U $type
		The type of the field, as a Raku type
		=end pod
		Any:U :$type,
	) {
		%!field-indices{$name}:exists and die "Error: Can't create field '$name' because it already exists";
		self.{$name} = Field.new(:$relation, :$name, :$type);
		#@!fields.push(self.{$name});
		#@!field-names.push($name);
	}

	# Makes a Tuple object from the key/values specified in %items, and returns it
	multi	method	makeTuple(%items) {
		my %newitems = $!field-mode-object.vet-for-tuple(%items);

		Tuple.new(%newitems);
	}
	multi	method	makeTuple(@items) {
		my %items := $!field-mode-object.vet-for-tuple(@items);
		self.makeTuple(%items);
	}
}

