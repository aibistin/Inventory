# ABSTRACT: Items and the Inventory Database
#-------------------------------------------------------------------------------

=head2
  Items and the Inventory Database
  Item Images with Inventory::Dir
  Subclass of the Inventory::Db Module
=cut

#-------------------------------------------------------------------------------
package Inventory::Db::Item;
use Moo;
extends q{Inventory::Db};
with q{Inventory::Roles::Dir};

#------
use autodie;
use Carp qw(croak);
use Data::Dump qw(dump);
use utf8::all;
use Types::Standard qw{ Bool Str };
use Types::Path::Tiny qw/Path AbsPath/;
use Try::Tiny;

#use DBI qw(:sql_types);    #sql_types for SQL_BLOB

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
#  ATTRIBUTES
#-------------------------------------------------------------------------------

#------ The following attributes will be given
has origin_filepath_abs => (
    is     => 'ro',
    isa    => AbsPath,
    coerce => AbsPath->coercion,
);

has destination_base_dir_abs => (
    is     => 'ro',
    isa    => AbsPath,
    coerce => AbsPath->coercion,
);

has destination_type_subdir_name => (
    is     => 'ro',
    isa    => Str,
    coerce => Str->coercion,
);

has new_filename => (
    is     => 'ro',
    isa    => Str,
    coerce => Str->coercion,
);

#------ The following attriutes will be created
has sub_directory_name => (
    is     => 'rw',
    isa    => Str,
    coerce => Str->coercion,
);

has destination_filepath_abs => (
    is     => 'rw',
    isa    => AbsPath,
    coerce => AbsPath->coercion,
);

has dummy_path => (
    is     => 'ro',
    isa    => AbsPath,
    coerce => AbsPath->coercion,
);

#-------------------------------------------------------------------------------
#  Inventory Database Handle
#-------------------------------------------------------------------------------
#  Inventory Database Handle
#-------------------------------------------------------------------------------

#
#-------------------------------------------------------------------------------
#  SQL Strings Handles
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  Images Directory Handle
#-------------------------------------------------------------------------------

=head2 get_all_images
  Read the contents of the Inventory Images Directory.
=cut

sub get_all_images {
    my $self = shift;
    my $dh   = $self->get_dir();
    my ( $image, @images );
    while ( defined( $image = $dh->read ) ) {
        push @images, $image;
    }
    return \@images;
}

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
        $item->{updated} = format_yyyy_mm_dd_T_hhmmss( $item->{updated} );
    }
    return $array_of_h;
}

=head2 select_one_item_detail
  Returns an HashRef of One Item Table Row that matches a give ID.
=cut

sub select_one_item_detail {
    my $self    = shift;
    my $id      = shift;
    my $inv_dbh = $self->get_inv_dbh();
    my $row_href =
      $inv_dbh->selectrow_hashref( $self->select_one_item_detail_sql(),
        undef, ($id) );
    return $row_href;
}

#-------------------------------------------------------------------------------
#  Lookup Table Selects
#-------------------------------------------------------------------------------
#------ Photo/Image Table
sub select_item_photo_sql {
    my $self = shift;

    my $sql = <<"SELECT_SQL";
   SELECT id, 
          item, 
          name, 
          abs_location, 
          rel_location, 
          comments, 
          updated
    FROM item_photo
    WHERE
        item = ?
SELECT_SQL

    return $sql;

}

=head2 select_item_photo

  Selects any photos that match a given item id.
  Pass;
  $item_id, 
  column_params => {
            id      => 1,
            item    => 1,
            name    => 1, 
            abs_location   => 1, 
            rel_location   => 1, 
            comments       => 1, 
            updated       => 1, 
  }, 
  Returns an array of HashRefs of photos matching the given ID
=cut

sub select_item_photo {
    my $self          = shift;
    my $item_id       = shift;
    my $column_params = shift // {
        id           => 1,
        item         => 1,
        name         => 1,
        abs_location => 1,
        rel_location => 1,
        comments     => 1,
    };
    $log->debug('Select Photo: about to call selectall_slice!');
    my $array_of_h = $self->selectall_slice(
        {
            sql           => $self->select_item_photo_sql(),
            column_params => $column_params,
            bind_values   => [$item_id]
        }
    );

    $log->debug( 'Select Photo: results !' . ( dump $array_of_h ) );
    return $array_of_h;
}

sub get_select_item_photo_sth {
    my $self    = shift;
    my $inv_dbh = $self->get_inv_dbh();
    my $sth     = $inv_dbh->prepare( $self->select_item_photo_sql() );
    return $sth;
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
          address, 
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
   Returns an ArrayRef of [{id => 1, address => 'address', name
   => 'some name'}, {}....]
   For only particular table columns, send  a column_params  hashref.
   selectall_locationa({ id => 1, address => 1,  name => 1})
=cut

sub selectall_locations {
    my $self = shift;
    my $column_params = shift || {};
    croak('column_params must be a HashRef!')
      if ( ($column_params)
        && ( ref($column_params) ne 'HASH' ) );

    my $sql = <<"SELECT_SQL";
   SELECT id, 
          address, 
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
            item,
            desc 
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
            item,
            structure 
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
            item,
            color 
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
            item, 
            name, 
            abs_location, 
            rel_location, 
            comments, 
            updated
    )
    VALUES (?, ?, ?, ?, ?, ?, ?)
POPULATE_SQL

    my $inv_dbh = $self->get_inv_dbh();
    return $inv_dbh->prepare($sql);
}

=head2 insert_and_return_item_details 
       Same as insert_item_transaction with the addition of returning 
       a hashRef of the last item to be inserted,  including an ArrayRef
       of the item photo locations.
=cut

sub insert_and_return_item_details {
    my $self = shift;
    my ($new_item_id) = $self->insert_item_transaction(shift);
    return $FAIL unless $new_item_id;
    my $new_item_h = $self->select_one_item_detail($new_item_id);
    $new_item_h->{photos} = $self->select_item_photo($new_item_id);
    $log->debug( 'Got the new item detail with photos: ' . dump $new_item_h );
    return $new_item_h;
}

=head2 insert_item_transaction 
  Pass a HashRef containing the Column Names and values
  Insert the Item to the Item table, and populat all related 
  lookup tables.
  Return the last id to be inserted.
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
    my $inv_dbh = $self->get_inv_dbh();
    my $photo_upload_obj = $column_data->{photo} or undef;

    #--- Id should be undef.
    $column_data->{id} = undef;

    $column_data->{updated} = get_db_formatted_localtime($inv_dbh);

  #------ Save Photo To Images Directory
  #    $log->debug( 'Filename Attribute : ' . $self->destination_base_dir_abs );
  #    $log->debug( 'Dirname Attribute : ' . $self->image_directory );

    my @item_bind_values = @$column_data{@ITEM_TABLE_COLS};

    #----- ENABLE TRANSACTION
    $inv_dbh->{RaiseError} = 1;
    $inv_dbh->begin_work();
    my $item_sth = $self->get_insert_item_sth();
    my $photo_sth = $self->get_insert_item_photo_sth() if $photo_upload_obj;
    $log->debug('Starting Insert Transaction!');
    my $transaction_ok = try {

        #--- Add to Item
        $item_sth->execute(@item_bind_values);

        #--- Return the last id to be inserted
        $new_id =
          $inv_dbh->last_insert_id( $DB_CATALOG, $DB_SCHEMA, $ITEM_TABLE,
            $ID_NAME );

        #        #--- Add to Item Description
        #        #--- Add to Item Structure
        #        #--- Add to Item Color

        #------ Save the image file to user address and insert the returned
        #       location file path to the item_photo table for this item.
        if ($photo_sth) {
            $self->sub_directory_name($new_id);
            $self->copy_and_rename_file()
              or croak 'Unable to save the image file!';

            #-- Note use the Item  as photo.name for now
            $photo_sth->execute(
                (
                    undef,
                    $new_id,
                    $column_data->{type},
                    $self->destination_filepath_abs->path,
                    $self->item_file_relative_path,
                    'No Comments yet!',
                    get_db_formatted_localtime($inv_dbh)
                )
            );
        }
        $inv_dbh->commit;
    }

    #    if ($@) {
    catch {
        $log->error( 'Insert Failed! :    ' . $_ );
        eval { $inv_dbh->rollback };
        $log->error('Rollback failed! ') if $@;
        $item_sth->finish                if $item_sth;
        $photo_sth->finish               if $photo_sth;
        return $FAIL;
    };
    return $FAIL unless $transaction_ok;
    $log->debug( 'Finished Insert Transaction, with new ID: ' . $new_id );
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
    my $bind_values_ref = shift;
    croak 'execute_select(), bind params must be an ArrayRef!'
      unless ( ref $bind_values_ref eq 'ARRAY' );

    return $sth->execute(@$bind_values_ref) or die $DBH::errstr;
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
     bind_values => \@bind_values,
   }
=cut

sub selectall_slice {
    my $self = shift;
    my $attr = shift
      or croak
      'selectall_slice() requires SQL, attributes and maybe bind params!';
    my $inv_dbh = $self->get_inv_dbh();
    my $sql = $attr->{sql} or croak 'selectall_arrayref() requires SQL.';
    my $column_params_h = $attr->{column_params} || {};
    my $bind_values     = $attr->{bind_values};

    #--- Bind params are optional
    return $inv_dbh->selectall_arrayref(
        $sql,
        {
            Slice            => $column_params_h,
            FetchHashKeyName => $self->fetch_hash_key_name(),
        },
        @$bind_values
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
#     bind_values => \@bind_values,
#   }
#-------------------------------------------------------------------------------
sub selectall_arrayref {
    my $self = shift;
    my $attr = shift
      or croak 'selectall_arrayref() requires SQL, attributes and maybe bind
    params!';
    my $sql = $attr->{sql} or croak 'selectall_arrayref() requires SQL.';
    my $column_attr = $attr->{column_attr};
    my $bind_values = $attr->{bind_values};
    my $inv_dbh     = $self->get_inv_dbh();

    ( $column_attr && $bind_values ) && do {
        return $inv_dbh->selectall_arrayref( $sql, $column_attr, @$bind_values )
          or die $DBH::errstr;
    };
    $column_attr && do {
        return $inv_dbh->selectall_arrayref( $sql, $column_attr )
          or die $DBH::errstr;
    };
    $bind_values && do {
        return $inv_dbh->selectall_arrayref( $sql, undef, @$bind_values )
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

=head copy_and_rename_file
  Save File To New Directory. The new directory could be a
  user image directory with a sub directory for each item.
  Creates a new Path::Tiny path ($self->destination_filepath_abs) where the (image) file is saved.
  Returns the new file path string for the (image) new file;
=cut

#-------------------------------------------------------------------------------
sub copy_and_rename_file {
    my $self = shift;

    #--- Rename the image file by PrePending a string (item id) to the
    #    original filename. Then Copy the uploaded file to the
    #    correct directory with this New filename
    #    See  Path::Tiny for details
    $log->debug( 'Destination dir: ' . $self->destination_base_dir_abs );

    my $dest_path_abs = $self->create_file_type_item_subdir_path();

    #---  Absolute Destination file path with new filename
    $self->destination_filepath_abs(
        $dest_path_abs . '/' . $self->new_filename );

    $log->debug( 'New File Path Name: ' . $self->destination_filepath_abs->path );

    #--- Copy the file to this new destination under its new name
    $self->origin_filepath_abs->copy( $self->destination_filepath_abs->path );

    return $self->destination_filepath_abs->path;
}

=head2 create_file_type_item_subdir_path
     Create a subdirectory if not alerady existing, that will be the directory
     for all files (subdirectories) of a particular item id. (eg images/item_id)
     It will be a combination of the destination_base_dir_abs and the
     subdirectory name for the file type and the subdirectory name for the
     item id.
     /home/me/app/images/ + 1/
     Return the Absolute directory path as a Path::Tiny object even if the
     subdirectory existed already.
=cut

sub create_file_type_item_subdir_path {
    my $self = shift;
    my $sub_dir_name = $self->sub_directory_name() // croak(
        'create_file_type__item_subdir_path() 
        requires an item #  sub_directory_name attribute!'
    );

    my $type_dir_path = $self->create_file_type_subdir_path();

    #--- create a new sub directory to store the image file(if not existing)
    #    Not mkpath only returns a path if it creates a new one
    $type_dir_path->child($sub_dir_name)->mkpath;
    return $type_dir_path->child($sub_dir_name);
}

=head2 create_file_type_subdir_path
     Create a subdirectory if not alerady existing, that will be the directory
     for all files (subdirectories) of a particular type. (eg Images)
     It will be a combination of the destination_base_dir_abs and the
     subdirectory name for the file type.
     /home/me/app/  + images/
     Return the Absolute directory path as a Path::Tiny object even if the
     subdirectory existed already.
=cut

sub create_file_type_subdir_path {
    my $self                         = shift;
    my $destination_type_subdir_name = $self->destination_type_subdir_name()
      // croak(
        'create_file_type_subdir_path() 
        requires a destination type subdirectory name attribute!'
      );

    #--- create a new sub directory to store the image file(if not existing)
    #    Not mkpath only returns a path if it creates a new one
    $self->destination_base_dir_abs->child($destination_type_subdir_name)
      ->mkpath;
    return $self->destination_base_dir_abs->child(
        $destination_type_subdir_name);
}

=head2 item_file_relative_path
     Returns a string with the  relative path of the stored item file (relative to the
     App base directory).
=cut

sub item_file_relative_path {
    my $self = shift;
    return $self->destination_filepath_abs->relative(
        $self->destination_base_dir_abs->path )->path;
}

#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
1;
