#!/usr/bin/env perl 
#===============================================================================
#
#
#  USAGE: ./user-db-setup.pl --verbose --debug debug --database_file user.db
#
#  DESCRIPTION:
#      Drop and create a SQLite User database  tables;
#      user,role,user_role, user_log.
#
#  CREATED: 11/09/2013
#===============================================================================
use Modern::Perl;
use autodie;
use Getopt::Long;
use Pod::Usage;
use DBI;
use DBD::SQLite;
use DateTime;
use Data::Dump qw{dump};
use InventoryDbUtil qw{db_handle commit_and_disconnect};
use Log::Log4perl qw(:easy);
use diagnostics -verbose;

#-------------------------------------------------------------------------------
#  Default Options
#-------------------------------------------------------------------------------
my $verbose = q//;
my $quiet   = q//;
my $log_level = q/error/;
my $man  = 0;
my $help = 0;

#------ SQLite databse name
my $db_file = q(user.db);

process_options();

#-------------------------------------------------------------------------------
#  Globals
#-------------------------------------------------------------------------------

#------ Tables
my @tables = qw/user role user_role user_log/;

my $dbh = db_handle( $db_file,
    { RaiseError => 1, PrintError => 0, AutoCommit => 0, sqlite_unicode => 1, }
);

DEBUG( 'Database handle created for database ' . $db_file . ': ' . dump $dbh );

#-------------------------------------------------------------------------------
#  Main
#-------------------------------------------------------------------------------
#------ Drop All Tables starting at the last so as to
#       Keep Referential Integrity
my @last_to_first = reverse @tables;
drop_tables( \@last_to_first );
undef @last_to_first;

#------ Create Tables
create_user_table();
create_role_table();
create_user_role_table();

#------ Create Views
create_view_user_name_asc();

#------ Finished
commit_and_disconnect($dbh);
DEBUG( "$0: has finished creating $db_file  database.");
exit;

#-------------------------------------------------------------------------------
#  Drop All Tables
#  Pass an ArrayRef of tables.
#-------------------------------------------------------------------------------
sub drop_tables {
    my $tables = shift;
    croak('drop_tables() needs an array of Tables to drop!') unless $tables;
    for my $tbl (@$tables) {

        drop_table($tbl);
    }
}

#-------------------------------------------------------------------------------
#  Drop a given table
#-------------------------------------------------------------------------------
sub drop_table {
    my $table = shift;
    FATAL('drop_table() needs a Table to drop!') unless $table;
    croak('drop_table() needs a Table to drop!') unless $table;

    say 'Dropping table: ' . $table if $verbose;
    my $drop_table_sql = <<"DROP_TBL";
   DROP TABLE if EXISTS $table;
DROP_TBL

    $dbh->do($drop_table_sql);
    say '....dropped table: ' . $table if $verbose;
}

#-------------------------------------------------------------------------------
#  Create an user Table
#-------------------------------------------------------------------------------
sub create_user_table {

    my $drop_user_sql = <<"DROP_USER";
   DROP TABLE if EXISTS user;
DROP_USER

    $dbh->do($drop_user_sql);

    my $create_user_sql = <<"CREATE_USER_SQL";
    CREATE TABLE IF NOT EXISTS user (
            id             INTEGER PRIMARY KEY,
            name           varchar(80) NOT NULL, 
            password       varchar(80) NOT NULL, 
            employee       INTEGER, 
            customer       INTEGER, 
            status         INTEGER, 
            comments       VARCHAR (260), 
            created        TIMESTAMP, 
            updated        TIMESTAMP, 
            UNIQUE(name)
    );
CREATE_USER_SQL

 #            FOREIGN KEY (employee) REFERENCES employee(id) ON DELETE RESTRICT,
 #            FOREIGN KEY (customer) REFERENCES customer(id) ON DELETE RESTRICT

    $dbh->do($create_user_sql);
    say '......created user table' if $verbose;
}

#-------------------------------------------------------------------------------
#  Create an role Table
#-------------------------------------------------------------------------------
sub create_role_table {

    my $drop_role_sql = <<"DROP_ROLE";
   DROP TABLE if EXISTS role;
DROP_ROLE

    $dbh->do($drop_role_sql);

    my $create_role_sql = <<"CREATE_ROLE_SQL";
    CREATE TABLE IF NOT EXISTS role (
            id             INTEGER PRIMARY KEY,
            role           varchar(80) NOT NULL 
    );
CREATE_ROLE_SQL

    $dbh->do($create_role_sql);
    say '......created role table' if $verbose;
}

#-------------------------------------------------------------------------------
#  Create an user_role Table
#-------------------------------------------------------------------------------
sub create_user_role_table {

    my $drop_user_role_sql = <<"DROP_USER_ROLE";
   DROP TABLE if EXISTS user_role;
DROP_USER_ROLE

    $dbh->do($drop_user_role_sql);

    my $create_user_role_sql = <<"CREATE_USER_ROLE_SQL";
    CREATE TABLE IF NOT EXISTS user_role (
            user           INTEGER,
            role           INTEGER, 
            PRIMARY KEY(user, role), 
            FOREIGN KEY (user) REFERENCES  user(id) ON DELETE RESTRICT, 
            FOREIGN KEY (role) REFERENCES  role(id) ON DELETE RESTRICT
    );
CREATE_USER_ROLE_SQL

    $dbh->do($create_user_role_sql);
    say '......created user_role table' if $verbose;
}

##-------------------------------------------------------------------------------
#  Create a view of USERS sorted by Names ASC
#-------------------------------------------------------------------------------
sub create_view_user_name_asc {
    my $drop_all_users_view = <<"DROP_USER_VIEW";
   DROP VIEW if EXISTS all_users;
DROP_USER_VIEW

    $dbh->do($drop_all_users_view);

    my $create_all_users_view = <<"CREATE_ALL_USERS_VIEW";
    CREATE VIEW IF NOT EXISTS  all_users 
         AS  SELECT id , name, password, employee, customer, status, comments,
         created,  updated
             FROM user 
         ORDER BY name ASC ;
CREATE_ALL_USERS_VIEW

    $dbh->do($create_all_users_view);

    $dbh->commit;

    say 'Created a new All Users View!' if $verbose;
}

#-------------------------------------------------------------------------------
#  Options Processing
#-------------------------------------------------------------------------------
sub process_options {

    my %log_levels = (
        fatal => $FATAL,
        error => $ERROR,
        warn  => $WARN,
        info  => $INFO,
        debug => $DEBUG,
        trace => $TRACE
    );

    GetOptions(
        'database_file=s' => \$db_file,
        verbose       => \$verbose,
        quiet         => sub { $verbose = 0 },
        'debug=s'     => \$log_level,
        'help|?'      => \$help,
        man           => \$man,
    ) or pod2usage(2);

    pod2usage(1) if $help;

    pod2usage(
        -exitval => 1,
        -verbose => 2,
    ) if $man;
    #--- Check for correct log level
    pod2usage(
        -verbose => 2,
        -message => "Incorrect debug option.  Must be: \n
    $0 --debug fatal( or error, warning, info, debug, trace).\n"
    ) unless $log_levels{$log_level};

    Log::Log4perl->easy_init( $log_levels{$log_level} );

}
__END__
 
=head1 NAME
 
user-db-setup.pl - Create a user database with SQLite3.
  
=head1 SYNOPSIS
 
user-db-setup.pl [--table] 
  
  Options:
     --database_file  the default is user.db
     --verbose        verbose
     --quiet          not verbose
     --debug          fatal, error, warn, info, debugi, trace
     --help           brief help message
     --man            full documentation
          
=head1 OPTIONS
           
=over 8
            
=item B<--database_file>

Default SQLite3 database name is user.db,  but you can specify another.

=item B<--verbose>
             
See more information.

=item B<--quiet>
             
See less information(the default).

=item B<--debug>
             
Set the debug level if any. The default is error.
The following options are available, in decreasing levels of necessity:
fatal, error, warn, info, debug, trace.           

B<user-db-setup.pl> --verbose --debug debug

=item B<-help>
             
Print a brief help message and exits.
              
=item B<-man>
               
Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<user-db-setup.pl> will create the user database in SQLite3. 
It creates the tables;
    user,
    role,
    user_role,
    (and  user_log);

=cut
