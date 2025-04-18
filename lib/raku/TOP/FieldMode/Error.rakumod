use	TOP::FieldMode;

class	TOP::FieldMode::Error is TOP::FieldMode {
	method process-extra-fields-hash(%items) {
		for %items.kv -> $key, $value {
			$.table.field-indices{$key}:exists and next;
			die "Error: extra field '$key' while making Tuple from hash (and field-mode is 'error')\n";
		}
		return %items;
	}

	multi method process-extra-fields-array(%items, @use_field_names, @items) {
		die "Error: extra fields while making Tuple from array\n";
	}

}
