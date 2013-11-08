# ABSTRACT: Moo Role to connect to Inventory Database
#===============================================================================
#
#         FILE: Connect.pm
#
#  DESCRIPTION: Moo Role to connect to the Inventory Database
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Austin Kenny (), aibistin.cionnaith@gmail.com
# ORGANIZATION: Carry On Coding
#      VERSION: 1.0
#      CREATED: 10/16/2013 08:29:32 PM
#     REVISION: ---
#===============================================================================
package Inventory::Roles::Connect;
use Moo::Role;
use autodie;

#------ Debug
use Log::Any qw($log);
use FindBin;

#------ Locate my Databse Modules
my $run_dir         = "$FindBin::Bin";
my $DEFAULT_DB_NAME = "$run_dir/../sql/inventory.db";

#-------------------------------------------------------------------------------
#  Methods
#-------------------------------------------------------------------------------

=head2 db_connect
   Set:
   Connect to (Inventory) Database. Return the Database Handle.
   Get:
   If there is an existing connection to the Database, then just return that
   Database Handle.
=cut

sub db_connect {
    my $self = shift || do { croak('_build_inv_dbh() is an instance method!') };
    my $connect_attr = shift || {};

    $log->debug( "Inside Db.pm, before DBI connect to: " . $self->db_name );

    #----Use Passed Attributes or else the Objects Attributes
    $connect_attr ||= {
        RaiseError                 => $self->raise_error(),
        PrintError                 => $self->print_error(),
        AutoCommit                 => $self->auto_commit(),
        FetchHashKeyName           => $self->fetch_hash_key_name(),
        sqlite_see_if_its_a_number => $self->sqlite_see_if_its_a_number(),
        sqlite_unicode             => $self->sqlite_unicode()
    };

    no warnings 'once';
    my $inv_dbh = DBI->connect(
        "dbi:SQLite:dbname=" . ( $self->db_name || $DEFAULT_DB_NAME ),
        "",    # no username required
        "",    # no password required
        $connect_attr
    ) or die $DBH::errstr;

}

