use	TOP;

class	TOP::FieldMode::Overflow is TOP::FieldMode {
	has	Str     $!overflow-field-name	is built;

	method process-extra-fields-hash(%items) {
		%items{$!overflow-field-name}:exists and %items{$!overflow-field-name} !~~ Associative and do {
			my $origfield = %items{$!overflow-field-name};
			%items{$!overflow-field-name} = %();
			%items{$!overflow-field-name}{$!overflow-field-name} = $origfield;
		};
		my @deletes;
		for %items.kv -> $key, $value {
			$.table.{$key}:exists and next;
			if ! ($.table.{$!overflow-field-name}:exists) {
				$.table.{$!overflow-field-name}  = Field.new(relation => $.table, name => $!overflow-field-name);
			}
			%items{$!overflow-field-name}:exists or %items{$!overflow-field-name} = %();
			%items{$!overflow-field-name}{$key} = $value;
			@deletes.push: $key;
		}
		for @deletes -> $key {
			%items{$key}:delete;
		}
		return %items;
	}

	multi method get-field-names() {
		# If the field-mode is overflow, then don't include the overflow field in the list of fields to eat things up automatically
		return $.table.fields.grep: { .name ne $!overflow-field-name } ==> map { .name }
	}

	multi method process-extra-fields-array(%items, @use_field_names, @items) {
		my %extra_items := self.make-extra-fields(@use_field_names, @items);
		%items{$!overflow-field-name} := %extra_items;
		return %items;
	}
}