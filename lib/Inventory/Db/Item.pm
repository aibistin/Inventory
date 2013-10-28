# ABSTRACT: Items and the Inventory Database
#-------------------------------------------------------------------------------
#  Items and the Inventory Database
#  Subclass of the Inventory::Db Module
#-------------------------------------------------------------------------------
package Inventory::Db::Item;
use Moo;
extends 'Inventory::Db';

#------
use autodie;
use Carp qw(croak);
use Data::Dump qw(dump);
use utf8::all;
use Types::Standard qw{ Bool Str };

#--- My utility files
use MyUtil qw { camelcase_str };
use MyDateUtil qw { format_yyyy_mm_dd_T_hhmmss  };
use MyConstant qw/$TRUE $FALSE $FAIL/;
use MyDateUtil qw { get_db_formatted_localtime };

#------ Debug
use Log::Any qw($log);

#--- Constants
my @ITEM_TABLE_COLS =
  qw{id type location length width height diameter weight external_ref comments updated};

my $ITEM_TABLE = q{item};
my $DB_CATALOG = q{undef};
my $DB_SCHEMA  = q{undef};
my $ID_NAME    = q{id};
#-------------------------------------------------------------------------------
#  Inventory Database Handle
#-------------------------------------------------------------------------------

#-- Make this our $DBH and put in Db.pm

=head2 set_dbh
     Set the global DBH if it is not already set;
=cut

#sub set_dbh {
#    my $self = shift || do { croak('set_dbh() is an instance method!') };
#    my $attr = shift;
#    $log->debug('DBH at start of set_dbh(): ' . dump $DBH);
#    my $DBH  = $self->get_inv_dbh() unless $DBH;
#    $log->debug('DBH at end of set_dbh(): ' . dump $DBH);
#}
#
#-------------------------------------------------------------------------------
#  SQL Strings Handles
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#     Items
#-------------------------------------------------------------------------------
sub select_all_items_sql {
    my $self = shift;
    my $sql  = <<"SELECT_SQL";
   SELECT id, 
          type, 
          location, 
          length,
          width, 
          height, 
          diameter, 
          weight, 
          external_ref, 
          comments, 
          updated 
    FROM item;
SELECT_SQL

    return $sql;

}

sub select_all_items_detail_sql {
    my $self = shift;

    my $sql = <<"SELECT_SQL";
   SELECT item.id, 
          item_type.name, 
          location.name, 
          item.length,
          item.width, 
          item.height, 
          item.diameter, 
          item.weight, 
          item.external_ref, 
          item.comments, 
          item.updated 
    FROM item
    INNER JOIN item_type
        ON item.type = item_type.id
    INNER JOIN location
        ON item.location = location.id
SELECT_SQL

    return $sql;

}


sub select_one_item_detail_sql {
    my $self = shift;

    my $sql = <<"SELECT_SQL";
   SELECT item.id, 
          item_type.name as item_name, 
          location.name as location_name, 
          item.length,
          item.width, 
          item.height, 
          item.diameter, 
          item.weight, 
          item.external_ref, 
          item.comments, 
          item.updated 
    FROM item
    INNER JOIN item_type
        ON item.type = item_type.id
    INNER JOIN location
        ON item.location = location.id
    WHERE
        item.id = ?
SELECT_SQL

    return $sql;

}

#-------------------------------------------------------------------------------
sub select_items_where_type_sql {
    my $self = shift;

    my $sql = <<"SELECT_SQL";
   SELECT id, 
          type, 
          location, 
          length,
          width, 
          height, 
          diameter, 
          weight, 
          external_ref, 
          comments, 
          updated 
    FROM item      
    WHERE  type = ?
SELECT_SQL

    return $sql;
}

#-------------------------------------------------------------------------------
#  Select Items
#-------------------------------------------------------------------------------

=head2 select_all_items_detail
  Returns an ArrayRef of Item Hash's
  Can send a HashRef of Column params if you only want particular columns.
  select_all_items_detail({id =>1, name => 1})
=cut

sub select_all_items_detail {
    my $self = shift;
    my $column_params = shift || {};
    croak('column_params must be a HashRef!')
      if ( ($column_params)
        && ( ref($column_params) ne 'HASH' ) );
    my $array_of_h = $self->selectall_slice(
        {
            sql           => $self->select_all_items_detail_sql(),
            column_params => $column_params,
        }
    );
    return $array_of_h;
}

=head2 get_all_items_formatted
   Get all items from Inventory DB. Do Some formatting on the
   Item Elements.
   Return the ArrayRef of HasRefs of the Item data.
   I Dont use this yet
=cut

sub get_all_items_formatted {
    my $self       = shift;
    my $array_of_h = $self->select_all_items_detail(shift);
    my $inv_dbh    = $self->get_inv_dbh();
    for my $item (@$array_of_h) {

        #--- Format the 'updated' date
        $item->{name} = camelcase_str( $item->{name} );
        $item->{comments} =
          camelcase_str( $item->{comments} );
        $item->{updated}       = format_yyyy_mm_dd_T_hhmmss( $item->{updated} );
    }
    return $array_of_h;
}


=head2 select_one_item_detail
  Returns an HashRef of One Item Table Row that matches a give ID.
=cut

sub select_one_item_detail {
    my $self = shift;
    my $id = shift;
    my $inv_dbh = $self->get_inv_dbh();
    my $row_href =
    $inv_dbh->selectrow_hashref($self->select_one_item_detail_sql(), undef, ($id));
    return $row_href;
}

#-------------------------------------------------------------------------------
#  Pre Insert Selects
#  Need Only the ID from each of these
#-------------------------------------------------------------------------------
#------
#------ Select Item Type
#------
sub get_select_item_type_sql {
    my $self = shift
      || do { croak('get_select_item_type_sql() is an instance method!') };

    my $sql = <<"SELECT_SQL";
   SELECT id, 
          name, 
          updated 
    FROM item_type
    WHERE  name = ?
SELECT_SQL

    return $sql;
}

sub get_select_item_type_sth {
    my $self    = shift;
    my $inv_dbh = $self->get_inv_dbh();
    my $sth     = $inv_dbh->prepare( $self->get_select_item_type_sql() );
    return $sth;
}

#------
#------ Select Location
#------
sub get_select_location_sql {
    my $self = shift
      || croak('get_select_location_sql() is an instance method!');

    my $sql = <<"SELECT_SQL";
   SELECT id, 
          address_id, 
          name, 
          updated 
    FROM  location
    WHERE  name = ?
SELECT_SQL

    return $sql;
}

sub get_select_location_sth {
    my $self    = shift;
    my $inv_dbh = $self->get_inv_dbh();
    my $sth     = $inv_dbh->prepare( $self->get_select_location_sql() );
    return $sth;
}

#-------------------------------------------------------------------------------
#  Quick Selects
#-------------------------------------------------------------------------------

=head2 selectall_item_types
   Select all item_types.
   Returns an ArrayRef of [{id => 1, name => 'item_name'}, {}....]
   Can send a HashRef of Column params to specify which columns you may
   wish to fetch.
=cut

sub selectall_item_types {
    my $self          = shift;
    my $column_params = shift;
    croak('column_params must be a HashRef!')
      if ( ($column_params)
        && ( ref($column_params) ne 'HASH' ) );

    my $sql = <<"SELECT_SQL";
   SELECT id, 
          name, 
          updated
    FROM item_type
SELECT_SQL

    my $array_of_h = $self->selectall_slice(
        {
            sql           => $sql,
            column_params => $column_params,
        }
    );

    return $array_of_h;
}

=head2 selectall_locations
   Select all locations(id's and address id and name).
   Returns an ArrayRef of [{id => 1, address_id => 'address_id', name
   => 'some name'}, {}....]
   For only particular table columns, send  a column_params  hashref.
   selectall_locationa({ id => 1, address_id => 1,  name => 1})
=cut

sub selectall_locations {
    my $self = shift;
    my $column_params = shift || {};
    croak('column_params must be a HashRef!')
      if ( ($column_params)
        && ( ref($column_params) ne 'HASH' ) );

    my $sql = <<"SELECT_SQL";
   SELECT id, 
          address_id, 
          name, 
          description, 
          updated
    FROM location
SELECT_SQL

    my $array_of_h = $self->selectall_slice(
        {
            sql           => $sql,
            column_params => $column_params,
        }
    );
    return $array_of_h;
}

#-------------------------------------------------------------------------------
#  Insert SQL
#-------------------------------------------------------------------------------
#------
#------ Insert to ITEM sql
#------
sub get_insert_item_sql {
    my $self = shift || croak('get_insert_item_sql() is an instance method!');

    my $sql = <<"INSERT_SQL";
   INSERT OR IGNORE
          INTO item(
            id, 
            type, 
            location, 
            length,
            width, 
            height, 
            diameter, 
            weight, 
            external_ref, 
            comments, 
            updated 
    )
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
INSERT_SQL

    return $sql;
}

#------
#------ Insert to ITEM Statement Handle
#------
sub get_insert_item_sth {
    my $self    = shift;
    my $inv_dbh = $self->get_inv_dbh();
    my $sth     = $inv_dbh->prepare( $self->get_insert_item_sql() );
    return $sth;
}

#------
#------ Insert to ITEM_DESC Statement Handle
#------
sub get_insert_item_desc_sth {
    my $self = shift;

    my $sql = <<"POPULATE_SQL";
   INSERT OR IGNORE
          INTO item_desc(
            item_id,
            desc_id 
    )
    VALUES (?, ?)
POPULATE_SQL

    my $inv_dbh = $self->get_inv_dbh();
    return $inv_dbh->prepare($sql);
}

#------
#------ Insert to ITEM_STRUCTURE Statement Handle
#------
sub get_insert_item_structure_sth {
    my $self = shift;

    my $sql = <<"POPULATE_SQL";
   INSERT OR IGNORE
          INTO item_structure(
            item_id,
            structure_id 
    )
    VALUES (?, ?)
POPULATE_SQL

    my $inv_dbh = $self->get_inv_dbh();
    return $inv_dbh->prepare($sql);
}

#
# Get Statement Handle To Insert to item_color DB
#
sub get_insert_item_color_sth {
    my $self = shift;
    my $sql  = <<"POPULATE_SQL";
   INSERT OR IGNORE
          INTO item_color(
            item_id,
            color_id 
    )
    VALUES (?, ?)
POPULATE_SQL

    my $inv_dbh = $self->get_inv_dbh();
    return $inv_dbh->prepare($sql);
}

#
# Get Statement Handle To Insert to item_photo DB
#
sub get_insert_item_photo_sth {
    my $self = shift;
    my $sql  = <<"POPULATE_SQL";
   INSERT OR IGNORE
          INTO item_photo(
            id,
            item_id, 
            path_to_photo, 
            photo_name, 
    )
    VALUES (?, ?, ?)
POPULATE_SQL

    my $inv_dbh = $self->get_inv_dbh();
    return $inv_dbh->prepare($sql);
}

=head2
  Insert Item Transaction
  Pass a HashRef containing the Column Names and values
  Return the last id to be inserted
=cut
sub insert_item_transaction {
    my $self        = shift;
    my $column_data = shift
      || croak('insert_item_transaction() needs some bind params!');
    croak('insert_item_transaction() bind params needs to be a HashRef!')
      unless ( ref($column_data) eq 'HASH' );
    my ($new_id);

#    $log->debug( 'Item Database Object : ' . dump $self );
#    $log->debug( 'Autocommit : ' . $self->auto_commit );

    #------ Get Statement Handles
    my $inv_dbh  = $self->get_inv_dbh();
    my $item_sth = $self->get_insert_item_sth();

    #    my $item_desc_sth      = $self->get_insert_item_desc_sth();
    #    my $item_structure_sth = $self->get_insert_item_structure_sth();
    #    my $item_color_sth     = $self->get_insert_item_color_sth();
    #    my $item_photo_sth     = $self->get_insert_item_photo_sth();
    #

    #--- Id should be undef.
    $column_data->{id} = undef;

    $column_data->{updated} = get_db_formatted_localtime($inv_dbh);

    my @bind_params = @$column_data{@ITEM_TABLE_COLS};

    #----- ENABLE TRANSACTION
   $inv_dbh->{RaiseError} = 1;
   $inv_dbh->begin_work();
   eval {

        #--- Add to Item
        $item_sth->execute(@bind_params);

        #        #--- Add to Item Description
        #        $item_sth->execute(@$bind_params) || do {
        #        $item_desc_sth->execute(@$bind_params) || do {
        #            $log->error( $item_desc_sth->errstr );
        #            $item_desc_sth->finish;
        #            die;
        #        };
        #        #--- Add to Item Structure
        #        $item_sth->execute(@$bind_params) || do {
        #        $item_structure_sth->execute(@$bind_params) || do {
        #            $log->error( $item_structure_sth->errstr );
        #            $item_structure_sth->finish;
        #            die;
        #        };
        #        #--- Add to Item Color
        #        $item_color_sth->execute(@$bind_params) || do {
        #            $log->error( $item_color_sth->errstr );
        #            $item_color_sth->finish;
        #            die;
        #        };
        #        #--- Add to Item Photo
        #        $item_photo_sth->execute(@$bind_params) || do {
        #            $log->error( $item_photo_sth->errstr );
        #            $item_photo_sth->finish;
        #            die;
        #        };

    $inv_dbh->commit;
    #--- Return the last id to be inserted
     $new_id =   $inv_dbh->last_insert_id($DB_CATALOG,  $DB_SCHEMA, $ITEM_TABLE, $ID_NAME);
    };



    if ( $@ ) {
        $log->error('Insert Failed! :    ' . $@);
        eval{$inv_dbh->rollback};
        $log->error('Rollback failed! ') if $@;
        $item_sth->finish;
        return $FAIL;
    }


   return $new_id;
}

#-------------------------------------------------------------------------------
#  Prepare Statement
#  Pass SQL and dbh
#  Returns Statement handle
#-------------------------------------------------------------------------------
sub prepare_statement {
    croak 'prepare_statement() requires SQL and a dbh!' unless ( @_ >= 2 );
    my $self    = shift;
    my $sql     = shift;
    my $attr    = shift;
    my $inv_dbh = $self->get_inv_dbh();
    return $inv_dbh->prepare( $sql, $attr );

}
#-------------------------------------------------------------------------------
#  Execute the Select statement
#  Returns the Statement handle or undef if it fails.
#  Can pass placeholder params if necessary.
#-------------------------------------------------------------------------------
sub execute_select {
    my $self = shift;
    my $sth = shift or croak 'execute_select() requires a SQL statment handle.';
    my $bind_params_ref = shift;
    croak 'execute_select(), bind params must be an ArrayRef!'
      unless ( ref $bind_params_ref eq 'ARRAY' );

    return $sth->execute(@$bind_params_ref) or die $DBH::errstr;
}

#-------------------------------------------------------------------------------
#  Fetchall
#  Returns an ArrayRef of ArrayRef's of data
#  Can pass slice or parms.
#-------------------------------------------------------------------------------
sub fetchall_arrayref {
    my $self = shift;
    my $sth  = shift
      or croak 'fetchall_arrayref() requires a SQL statment handle.';
    my $slice_or_params = shift;
    my $inv_dbh         = $self->get_inv_dbh();
    if ($slice_or_params) {
        return $sth->fetchall_arrayref($slice_or_params) or die $DBH::errstr;
    }
    else {
        return $sth->fetchall_arrayref() or die $sth->errstr;
    }
}

=head2  selectall_slice
  Use selectall_arrayref, which incorporates the "prepare" statement
  Adds a slice and the Current FetchHashKeyName value
  Returns an ArrayRef of HashRef's of data
  Pass Attributes,
   {
     sql => 'SELECT * FROM table',
     column_params => {$column_params}, # for use in Slice => $column_params
     bind_params => \@bind_params,
   }
=cut

sub selectall_slice {
    my $self = shift;
    my $attr = shift
      or croak
      'selectall_arrayref() requires SQL, attributes and maybe bind params!';
    my $inv_dbh = $self->get_inv_dbh();
    my $sql = $attr->{sql} or croak 'selectall_arrayref() requires SQL.';
    my $column_params_h = $attr->{column_params} || {};
    my $bind_params     = $attr->{bind_params};

    #--- Bind params are optional
    return $inv_dbh->selectall_arrayref(
        $sql,
        {
            Slice            => $column_params_h,
            FetchHashKeyName => $self->fetch_hash_key_name(),
        },
        @$bind_params
    ) or die $inv_dbh->errstr;

}

#-------------------------------------------------------------------------------
#  SelectAll
#  Use SelectAll which incorporates the "prepare" statement
#  Returns an ArrayRef of ArrayRef's of data
#  Pass Attributes
#   {
#     sql => 'SELECT * FROM table',
#     column_attr => {Slice => {}},
#     bind_params => \@bind_params,
#   }
#-------------------------------------------------------------------------------
sub selectall_arrayref {
    my $self = shift;
    my $attr = shift
      or croak 'selectall_arrayref() requires SQL, attributes and maybe bind
    params!';
    my $sql = $attr->{sql} or croak 'selectall_arrayref() requires SQL.';
    my $column_attr = $attr->{column_attr};
    my $bind_params = $attr->{bind_params};
    my $inv_dbh     = $self->get_inv_dbh();

    ( $column_attr && $bind_params ) && do {
        return $inv_dbh->selectall_arrayref( $sql, $column_attr, @$bind_params )
          or die $DBH::errstr;
    };
    $column_attr && do {
        return $inv_dbh->selectall_arrayref( $sql, $column_attr )
          or die $DBH::errstr;
    };
    $bind_params && do {
        return $inv_dbh->selectall_arrayref( $sql, undef, @$bind_params )
          or die $DBH::errstr;
    };

    return $inv_dbh->selectall_arrayref($sql) or die $DBH::errstr;
}

#-------------------------------------------------------------------------------
#  FetchRow
#  Returns one row of data.
#-------------------------------------------------------------------------------
sub fetchrow_arrayref {
    my $sth = shift
      or croak 'fetchrow_arrayref() requires an SQL statment handle.';
    return $sth->fetchrow_arrayref() or die $sth->errstr;
}

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
1;
