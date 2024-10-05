use	v6.d;
use	TOP;

=begin pod

=NAME Raku TOP Driver - The common driver for Raku TOP backends

=TITLE Raku TOP Driver

=SUBTITLE The common driver for Raku TOP backends

=AUTHOR Tim Nelson - https://github.com/wayland

=head1 Database::Driver

The parent class for all the different Database Drivers (backends).

=begin code

role	Database::Driver

=end code

=head2 Methods

=end pod
role	Database::Driver {
	has	Str	$.name;
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

=head1 Table::Driver

=begin code

role	Table::Driver does Associative does Positional {

=end code

=head2 Attributes

=end pod

role	Table::Driver does Associative does Positional does TOP::Core {
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

	Creates a Table::Driver.

		.new(Database::Driver :$database, Relation :$frontend-object, Str :$action, Str :%fields)

	Parameters to .new are:
	=defn Relation $frontend-object
	The frontend object that is using this backend object.
	=end pod
	has	Relation			$!frontend-object	is built is required;
	=begin pod
	=defn Database::Driver	:$database
	The Database::Driver with which this Table::Driver is connected.
	=end pod
	has	Database::Driver	$!database			is built;		# Links to the database
	# TODO: Make the above "is required" once the Memory driver supports it

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
			:%fields
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

	method	format(Str $format = 'HalfHuman', *%parameters) {
		my $formatter = $.load-library(
			type => "TOP::Formatter::$format",
			table => $!frontend-object,
			|%parameters
		);

		$formatter.prepare-table();
		$formatter.output-header();
		for self[0..*] -> $row {
			$formatter.output-row($row);
		}
		$formatter.output-footer();
		return $formatter.output;
	}

	method	parse(Str $format = 'HalfHuman', *%parameters) {
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

		.add-field(Table :$relation, Str :$name, Any:U $type)
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
		Any:U :$type
	) {
		%!field-indices{$name}:exists and die "Error: Can't create field '$name' because it already exists";
		self.{$name} = Field.new(:$relation, :$name, :$type);
		#@!fields.push(self.{$name});
		#@!field-names.push($name);
	}
}

