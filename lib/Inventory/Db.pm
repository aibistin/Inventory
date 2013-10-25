# ABSTRACT: Connect to Invenory DB
#-------------------------------------------------------------------------------
#  Connects to Inventory Database and returns a Database handle.
#  Also has a safe Commit and Disconnect from Database
#  All functions are exported
#-------------------------------------------------------------------------------
package Inventory::Db;
use Moo;
with 'Inventory::Connect';
use autodie;

use DBI;
use Carp qw(croak);
use Data::Dump qw(dump);

#------ Locate my Databse Modules
my $run_dir         = "$FindBin::Bin";
my $DEFAULT_DB_NAME = "$run_dir/../sql/inventory.db";

#--- My utility files
use Types::Standard qw{ Bool Object Str };
use MyConstant qw/$TRUE $FALSE $FAIL/;

#------ Debug
use Log::Any qw($log);
use FindBin;

#------ Attributes
has db_name => (
    is      => 'ro',
    isa     => Str,
    default => sub { $DEFAULT_DB_NAME }
);

has raise_error => (
    is      => 'ro',
    isa     => Bool,
    default => sub { 0 }
);

has print_error => (
    is      => 'ro',
    isa     => Bool,
    default => sub { 1 }
);

has auto_commit => (
    is      => 'rw',
    isa     => Bool,
    default => sub { 0 }
);

has fetch_hash_key_name => (
    is      => 'ro',
    isa     => Str,
    default => sub { 'Name_lc' }
);

has sqlite_see_if_its_a_number => (
    is      => 'ro',
    isa     => Bool,
    default => sub { 1 }
);

has sqlite_unicode => (
    is      => 'ro',
    isa     => Bool,
    default => sub { 1 }
);

has pragma_foreign_keys_on => (
    is      => 'ro',
    isa     => Bool,
    default => sub { 1 }
);

has inv_dbh => (
    is      => 'ro',
    isa     => Object,
    lazy    => 1,
    builder => 'db_connect', 
    clearer => 1, 
    predicate => 'has_inv_dbh', 
    reader  => 'get_inv_dbh' 
);

=head2 _build_inv_dbh
   Set:
   Connect to Inventory Database. Set Foreign Keys On, and return the Database
   Handle.
   Get:
   If there is an existing connection to the Database, then just return that
   Database Handle.
=cut

#sub _build_inv_dbh {
#    my $self = shift || do { croak('inv_dbh() is an instance method!') };
#  
#    $log->debug( "Inside Db.pm, before DBI connect to: " . $self->db_name );
#
#    no warnings 'once';
#    my $inv_dbh = DBI->connect(
#        "dbi:SQLite:dbname=" . $self->db_name,
#        "",    # no username required
#        "",    # no password required
#        {
#            RaiseError => $self->raise_error,
#            PrintError => $self->print_error,
#            AutoCommit => $self->auto_commit,
#
#          #            FetchHashKeyName           => $self->fetch_hash_key_name,
#            sqlite_see_if_its_a_number => $self->sqlite_see_if_its_a_number,
#            sqlite_unicode             => $self->sqlite_unicode,
#        }
#    ) or die $DBI::errstr;
#
#    if ( $self->pragma_foreign_keys_on ) {
#        $inv_dbh->do("PRAGMA foreign_keys = ON") or die $inv_dbh->errstr;
#    }
#    else {
#        $inv_dbh->do("PRAGMA foreign_keys = OFF") or die $inv_dbh->errstr;
#    }
#    return $inv_dbh;
#}
#
#-------------------------------------------------------------------------------
#  Set Pragma Foreign Keys On/off
#   May be useless. Remove
#-------------------------------------------------------------------------------
sub set_pragma_foreign_keys {
    my $self    = shift;
    my $inv_dbh = $self->get_inv_dbh();
    if ( $self->pragma_foreign_keys_on ) {
        $inv_dbh->do("PRAGMA foreign_keys = ON") or die $inv_dbh->errstr;
    }
    else {
        $inv_dbh->do("PRAGMA foreign_keys = OFF") or die $inv_dbh->errstr;
    }
}

#-------------------------------------------------------------------------------
#  Commmit and Safe Disconnect
#-------------------------------------------------------------------------------
sub commit_and_disconnect {
    my $self    = shift;
    my $inv_dbh = $self->get_inv_dbh();
    my $ok;
    if ( $inv_dbh->ping ) {
        $inv_dbh->commit;
        $inv_dbh->disconnect;
        $ok = $TRUE;
    }
    else {
        croak 'Cannot disconnect, as there is no connection!';
    }
    $self->clear_inv_dbh();
    return $ok;
}

#-------------------------------------------------------------------------------
#  Safe Disconnect
#-------------------------------------------------------------------------------
sub safe_disconnect {
    my $self    = shift;
    my $inv_dbh = $self->get_inv_dbh();
    my $ok;
    if ( $inv_dbh->ping ) {
        $inv_dbh->disconnect;
        $ok = $TRUE;
    }
    else {
        croak 'Cannot disconnect, as there is no connection!';
    }
    $self->clear_inv_dbh();
    return $ok;
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
    my $inv_dbh = $self->get_inv_dbh();

    return $sth->execute(@$bind_params_ref) or die $inv_dbh->errstr;
}

#-------------------------------------------------------------------------------
1;
