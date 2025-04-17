use	TOP;
use	Database::Storage;

class	Table::Storage::CSV does Table::Storage is export {
	has 		@!rows;

	submethod	TWEAK(Str :$filename) {
		use CSV::Parser;

		my $full_filename = ($!directoryname ?? "$!directoryname/" !! '') ~ $filename;
		$!frontend-object.name or $!frontend-object.name = $filename.IO.basename;
		my $file_handle = open $full_filename, :r;
		my $parser = CSV::Parser.new(
				:$file_handle,
				:contains_header_row,
				);
		until $file_handle.eof {
			my %data= %( $parser.get_line() );
			@!rows.push(%data);
		}
		say "rows";
	}
	method	exists(Str :$true-error, Str :$false-error) {
		$false-error.defined and die $false-error ~ " in CSV";
		return False;
	}
}

class	Database::Storage::CSV does Database::Storage {
	has	Str		$!directoryname is built;
	has	Database	$!frontend-object;

	method	useTable(Table :$table, Str :$filename) {
		$!frontend-object = $table;
		my $storage-table = Table::Storage::Memory.new(frontend-object => $table, action => 'use', :$filename);

		return $storage-table;
	}
}