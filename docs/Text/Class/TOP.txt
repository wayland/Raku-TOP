TOP::Core

    role	TOP::Core {}



This is the common code that's shared across all TOP objects; this is
intended to be a role on all TOP classes.

Tuple

    class	Tuple is Hash::Ordered {}

This is the Tuple class from which all other Tuple classes descend.

It's descended from Hash::Ordered because the columns may well need to be
ordered. In the case of SQL, it's less important, but in the case of a
spreadsheet, it's important.

Database

    class	Database {...}

This is the Database class from which all other Database classes descend.

    method useTable

    method	useTable(Table :$table, Bool :$action, %fields => {})

  action | definition | Error if | Will alter              Fields
  create | force create | Present | No | Yes               
  alter | alter existing | Absent | Yes | Yes              
  use | no creation | Absent | No | No                     
  can-create | create if not existing                      No | No | If Absent
  ensure | create or alter | No | Yes | If not conformant  

