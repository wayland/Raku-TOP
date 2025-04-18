use	v6.d;
use	TOP;

=begin pod

=head1 TOP::FieldMode

The objects descended from this are the ones that action Table!field-mode

=head2 Attributes

=end pod

class	TOP::FieldMode {
	has	Table	$.table					is built is required is rw;
	has	Str     $!field-mode			is built = 'Automatic';

	=begin pod
	=head3 .vet-for-tuple and friends

	This is where the field modes are implemented.  It's been designed so that, 
	if someone wants to add a new field mode, they should be able to do so just 
	by implementing the following methods:

	=item process-extra-fields-hash
	=item process-extra-fields-array
	=item get-field-names

	Note that each of the above is passed $!field-mode as the first parameter, 
	and this selects the appropriate field mode.  

	Possibly in future, each field-mode should instead be a class with all 
	these methods attached.  

	=end pod
	# Don't call this directly; instead, call add-field
	multi method vet-for-tuple(%items) {
		my %new_items := self.process-extra-fields-hash(%items);
		return %new_items;
	}
	# Don't call this directly; instead, call add-field
	multi method vet-for-tuple(@items is copy) {
		my @use_field_names = self.get-field-names();
		my %items is Hash::Ordered;
		# Put the first ones in the ordered list of fields
		for @use_field_names Z @items -> ($field, $item) {
			%items{$field} = $item;
		}
		# If we've got fields left over...
		my $count = @items.elems - @use_field_names.elems;
		$count > 0 and self.process-extra-fields-array(%items, @use_field_names, @items);
		# TODO: Need to check if %items has been changed or discarded
		return %items;
	}

	# Make a hash of extra fields
	method make-extra-fields(@use_field_names, @items) {
		my $start = @use_field_names.elems;
		my $end = @items.elems - 1;
		my %extra_items is Hash::Ordered;
		for ((('A'..*)[$start..$end]) Z @items[$start..$end]) -> ($key, $item) {
			%extra_items{$key} = $item;
		}
		return %extra_items;
	}

	# methods to be overridden
	method process-extra-fields-hash(%items) {
		die "Error: Unknown value for .field-mode '???'; exiting\n";
	}

	# Gets a list of field names to use when automatically matching up values
	method get-field-names() {
		return $!table.fields.map: { .name };
	}

	multi method process-extra-fields-array(%items, @use_field_names, @items) {
		die "Error: Unknown value for .field-mode '???'; exiting\n";
	}
}
