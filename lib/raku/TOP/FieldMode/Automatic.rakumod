use	TOP;
use	TOP::FieldMode;

class	TOP::FieldMode::Automatic is TOP::FieldMode {
	multi method process-extra-fields-hash(%items) {
		for %items.kv -> $key, $value {
			$.table.field-indices{$key}:exists and next;
			$.table{$key} = Field.new(relation => $.table, name => $key);
		}
		return %items;
	}

	multi method process-extra-fields-array(%items, @use_field_names, @items) {
		my %extra_items := self.make-extra-fields(@use_field_names, @items);
		for %extra_items.kv -> $key, $item { %items{$key} = $item; }
		return %items;
	}
}
