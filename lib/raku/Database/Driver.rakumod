use	v6.d;
use	TOP;

role	Table::Driver does Associative does Positional {
	has	Relation	$!frontend-object	is built is required;
	has				%.field-indices;	# For looking up fields by name
	has	Str			@!field-names;		# For keeping the fields in order
	has	Field		@.fields;			# Store the actual fields

	# Only used during initialisation
	has	Bool		$!init-create = False;
	has	Bool		$!init-alter = False;
	has 			%.init-fields;		# Field definitions to be used during initialisation

	submethod	TWEAK(
			Table :$frontend-object,
			Str :$action,
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

		method	exists() {...}

	Returns True if the table already exists.

	=end pod
	method	exists(Str :$true-error, Str :$false-error) {...}
	# Abstracts
	method fill_from_aoh(@rows) {...}

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

	method	of() { return Mu; }

	method	add-field(Table :$relation, Str :$name, Any:U :$type) {
		%!field-indices{$name}:exists and die "Error: Can't create field '$name' because it already exists";
		self.{$name} = Field.new(:$relation, :$name, :$type);
		#@!fields.push(self.{$name});
		#@!field-names.push($name);
	}
}
role	Database::Driver {}
