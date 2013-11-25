#!/usr/bin/env perl
#===============================================================================
#
#
#   USAGE: ./user-db-populate.pl
#
#  DESCRIPTION:
#      Populate tables in the User DB
#      user     table
#      role    table
#      user_role   table
#
#  OPTIONS:
#     --database_file                   the (user.db)is the default
#     --truncate_table                  truncate table before insert (yes)
#     --commit_after_each_table_insert  commit changes after all data has been
#                                       inserted to a table.(yes)
#     --password_len        the max length for user password(20)
#     --password_salt_len   the length for user password salt(10)
#     --verbose             verbose
#     --quiet               not verbose (default)
#     --debug               fatal, error(default), warn, info, debug, trace
#     --help                brief help message
#     --man                 full documentation
#
#
#       AUTHOR: Austin Kenny (), aibistin.cionnaith@gmail.com
# ORGANIZATION: Carry On Coding
#      VERSION: 1.0
#      CREATED: 11/10/2013
#===============================================================================
use Modern::Perl;
use autodie;
use Getopt::Long;
use Pod::Usage;
use Log::Log4perl qw(:easy);
use Carp qw/croak/;
use Data::Dump qw/dump/;
use DBI;
use DBD::SQLite;
use Text::Unidecode;
use diagnostics -verbose;
use MyConstant qw/$YES $NO $TRUE $FALSE/;
use MyDateUtil qw/ get_db_formatted_localtime /;
use MyUtil qw{
  create_secure_password
  generate_random_salt
  validate_secure_password
};

use InventoryDbUtil qw(
  db_handle
  commit_and_disconnect
  get_insert_to_user_sth
  get_insert_to_role_sth
  get_insert_to_user_role_sth
  insert_commit_to_database
  insert_row_to_table
  truncate_tables
  truncate_table
);

#-------------------------------------------------------------------------------
#  Default Options
#-------------------------------------------------------------------------------
my $verbose   = q//;
my $quiet     = q//;
my $log_level = q/error/;
my $man       = 0;
my $help      = 0;

#------ SQLite databse name  'database_file'
my $DATABASE_FILE                  = q(user.db);
my $COMMIT_AFTER_EACH_TABLE_INSERT = $NO;

#------ Set to True if the Tables are to be emptied before population
my $TRUNCATE_TABLE = $NO;

my $PASSWORD_SALT_LEN = 10;
my $PASSWORD_LEN      = 20;

#-------------------------------------------------------------------------------
#  Other Globals
#-------------------------------------------------------------------------------

#------ Tables
my $user_tbl      = qw/user/;
my $role_tbl      = qw/role/;
my $user_role_tbl = qw/user_role/;
my @reg_tables    = ($user_tbl);

#-- These tables generally dont have 'updated' and 'created' fields
#   but auto increment primary key
my @dict_tables = ($role_tbl);

#-- These tables generally dont have 'updated' and 'created' fields
#   But have two field primary keys
my @lookup_tables = ($user_role_tbl);

my $pop_tbl_attr = {
    truncate_table    => $TRUNCATE_TABLE,
    data_delimiter    => ',',
    encrypt_password  => $YES,
    password_field    => 3,                                 #--- table column
    auto_increment_pk => $YES,
    add_create_date   => $YES,
    add_update_date   => $YES,
    commit_changes    => $COMMIT_AFTER_EACH_TABLE_INSERT,
};

#-------------------------------------------------------------------------------
#  Main
#-------------------------------------------------------------------------------

process_options();

my $dbh = connect_to_db();

if ($TRUNCATE_TABLE) {
    truncate_tables( \@lookup_tables, $dbh );
    map { truncate_table( $_, $dbh ) } reverse @reg_tables;
    say "All tables have been Truncated!" if $verbose;
    $TRUNCATE_TABLE = $NO;
}

#-------------------------------------------------------------------------------
#  Populate The Tables
#  Loop through table name lists to populate each table in turn.
#-------------------------------------------------------------------------------
populate_regular_tables( \@reg_tables, $pop_tbl_attr );

populate_dictionary_tables( \@dict_tables, $pop_tbl_attr );

populate_lookup_tables( \@lookup_tables, $pop_tbl_attr );

#------ All Done. Clean Up!
commit_and_disconnect($dbh);
INFO 'All Done!';
exit;

#-------------------------------------------------------------------------------
#  Connect To Database
#-------------------------------------------------------------------------------
sub connect_to_db {
    my $attr = shift
      || {
        RaiseError                 => 1,
        PrintError                 => 0,
        AutoCommit                 => 0,
        sqlite_unicode             => 1,
        sqlite_see_if_its_a_number => 1,
      };

    $dbh = db_handle( $DATABASE_FILE, $attr, );

    return $dbh;

}

#-------------------------------------------------------------------------------
#  Populate the regular tables
#-------------------------------------------------------------------------------
sub populate_regular_tables {
    my $reg_tables = shift
      || croak('populate_regular_tables() requires some tables!');
    my $pop_tbl_attr = shift
      || croak('populate_regular_tables() requires attributes!');

    for my $tbl_name (@$reg_tables) {
        say 'Working on table : ' . $tbl_name if $verbose;
        $pop_tbl_attr->{table_name} = $tbl_name;
        populate_table_from_file($pop_tbl_attr);
    }
}

#-------------------------------------------------------------------------------
# Populate dictionary tables
#-------------------------------------------------------------------------------
sub populate_dictionary_tables {
    my $dict_tables = shift
      || croak('populate_dictionary_tables() requires some tables!');
    my $pop_tbl_attr = shift
      || croak('populate_dictionary_tables() requires attributes!');

    #--- Populate the dictionary tables
    $pop_tbl_attr->{encrypt_password} = $NO;
    $pop_tbl_attr->{add_create_date}  = $NO;
    $pop_tbl_attr->{add_update_date}  = $NO;

    #--- Dont need this attribute any more.
    delete $pop_tbl_attr->{password_field}
      if ( exists $pop_tbl_attr->{password_field} );

    #--- Populate the data tables
    for my $tbl_name (@$dict_tables) {
        say 'Working on table : ' . $tbl_name if $verbose;
        $pop_tbl_attr->{table_name} = $tbl_name;
        populate_table_from_file($pop_tbl_attr);
    }
}

#-------------------------------------------------------------------------------
# Populate lookup tables
#-------------------------------------------------------------------------------
sub populate_lookup_tables {
    my $lookup_tables = shift
      || croak('populate_lookup_tables() requires some tables!');
    my $pop_tbl_attr = shift
      || croak('populate_lookup_tables() requires attributes!');

    #--- Populate the lookup tables
    $pop_tbl_attr->{auto_increment_pk} = $NO;
    $pop_tbl_attr->{add_create_date}   = $NO;
    $pop_tbl_attr->{add_update_date}   = $NO;

    for my $tbl_name (@$lookup_tables) {
        $pop_tbl_attr->{table_name} = $tbl_name;
        say 'Working on table : ' . $tbl_name if $verbose;
        populate_table_from_file($pop_tbl_attr);
    }

}

#-------------------------------------------------------------------------------
#  Populate Table From File
#  Insert data from a file to a table.
#  Pass The Table name.
#  Input file name will be the Table name with a '.txt' extension.
#  Commented and empty input lines are ignored.
#  Truncate Table first (if required)
#  Add Null to beginnig for Primary Auto Increment Field (if required)
#  Commit at end of all file inserts (if required)
#  Add DateTime Now String to end for Update field (if required)
#
# Pass attributes:
#    {
#     table_name         => $table_name,
#     truncate_table     => 1/0,
#     data_delimiter     => ',',
#     auto_increment_pk  => 1/0,
#     add_create_date    => 1/0,
#     add_update_date    => 1/0,
#     commit_changes     => 1/0,
#   }
#-------------------------------------------------------------------------------
sub populate_table_from_file {
    my $attr = shift;
    croak('populate_table_from_file() needs a table to Populate!')
      unless $attr->{table_name};

    my $table_name = $attr->{table_name};

    #--- Create input file name and 'get statment' function name
    my $input_file                 = $table_name . '.txt';
    my $get_sql_statement_function = 'get_insert_to_' . $table_name . '_sth';
    my $delim                      = $attr->{data_delimiter} // q(,);

    if ( $attr->{truncate_table} ) {

        truncate_table( $table_name, $dbh );

        say "Table: $table_name is now truncated!" if $verbose;
    }

    #------ Create Function Name for getting Statement Handle
    my $sth;
    {
        no strict;
        $sth = $get_sql_statement_function->($dbh);
    }

    my $fh = open_file_for_read($input_file);
    while ( my $in_line = <$fh> ) {
        say "In Line " . ( $in_line // 'nada' ) if $verbose;
        next if $in_line =~ /\s*#/;
        next if $in_line =~ /^\s+$/;
        chomp_trim_front_and_back($in_line);
        my @input_line =
          map { trim_front_and_back($_) } split( $delim, $in_line );

        #--- Add an Create Date (localtime formatted for the Database)
        push( @input_line, get_db_formatted_localtime($dbh) . '' )
          if $attr->{add_create_date};

        #--- Add an Update Date (localtime formatted for the Database)
        push( @input_line, get_db_formatted_localtime($dbh) . '' )
          if $attr->{add_update_date};

        #--- Add a NULL for the Primary key; to enable AutoIncrement
        unshift( @input_line, undef ) if $attr->{auto_increment_pk};

        #------ Encrypt password if the table has a password
        if ( ( $attr->{encrypt_password} ) && ( $attr->{password_field} ) ) {
            my $salt = generate_random_salt($PASSWORD_SALT_LEN);
            say "My Salt is $salt" if $verbose;
            my $password_hash = create_secure_password(
                {
                    random_salt  => $salt,
                    password     => $input_line[ $attr->{password_field} - 1 ],
                    crypt_params => {
                        salt_len   => $PASSWORD_SALT_LEN,
                        output_len => $PASSWORD_LEN,
                    },
                }
            );
            $input_line[ $attr->{password_field} - 1 ] = $password_hash;
        }

        insert_row_to_table( $sth, \@input_line );
    }

    say 'Data has been inserted to table : ' . $table_name if $verbose;
    if ( $attr->{commit_changes} ) {
        $dbh->commit;
        say "Data has been committed to table :  $table_name" if $verbose;

    }
}

#-------------------------------------------------------------------------------
#  Open File For Read
#  Returns a file handle
#-------------------------------------------------------------------------------
sub open_file_for_read {
    my $file = shift;
    croak('open_file_for_read() needs a file to open!') unless $file;
    open my $fh, '<:encoding(UTF-8)', $file
      or die 'Cannot open the input file, ' . $file . ',  because: ' . $!;
    return $fh;
}

#-------------------------------------------------------------------------------
#  chomp Trim Front And Back
#-------------------------------------------------------------------------------
sub chomp_trim_front_and_back {
    my $line = shift;
    $line =~ s/[\r\n]+$//s;    #-- Extra Chomp for good measure
    $line =~ s/^\s+//s;
    $line =~ s/\s+$//s;
    return $line;
}

#-------------------------------------------------------------------------------
#  Trim Front And Back
#-------------------------------------------------------------------------------
sub trim_front_and_back {
    my $line = shift;
    $line =~ s/^\s+//s;
    $line =~ s/\s+$//s;
    return $line;
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
        truncate_table                 => \$TRUNCATE_TABLE,
        'password_len=i'               => \$PASSWORD_LEN,
        'password_salt_len=i'          => \$PASSWORD_SALT_LEN,
        commit_after_each_table_insert => \$COMMIT_AFTER_EACH_TABLE_INSERT,
        'database_file=s'              => \$DATABASE_FILE,
        verbose                        => \$verbose,
        quiet                          => sub { $verbose = 0 },
        'debug=s'                      => \$log_level,
        'help|?'                       => \$help,
        man                            => \$man,
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

#------------------------------------------------------------------------------

__END__
 
=head1 NAME
 
user-db-populate.pl - Populate the user database tables.
  
=head1 SYNOPSIS
 
user-db-populate.pl 
  
  Options:
     --database_file                   the (user.db)is the default
     --truncate_table                  truncate table before insert (yes)
     --commit_after_each_table_insert  commit changes after all data has been
                                       inserted to a table.(yes)
     --password_len        the max length for user password(20)
     --password_salt_len   the length for user password salt(10)
     --verbose             verbose
     --quiet               not verbose (default)
     --debug               fatal, error(default), warn, info, debug, trace
     --help                brief help message
     --man                 full documentation
          
=head1 OPTIONS
           
=over 8

=item B<--database_file>

Default SQLite3 database name is user.db, but you can specify another.

B<user-db-populate.pl> --database_file  happy_user.db

=item B<--debug>
             
Set the debug level if any. The default is error.
The following options are available, in decreasing levels of necessity:
fatal, error, warn, info, debug, trace.           

B<user-db-populate.pl> --debug debug


=item B<--pasword_len>

The maximum length for a User password. The default is 20.

B<user-db-populate.pl> --password_len 15

=item B<--pasword_salt_len>

The maximum length for the 'salt' string for a the user password. The default is 10.

B<user-db-populate.pl> --password_salt_len 9

=item B<--truncate_table>
             
Truncate the tables before populating them. This is the easiest way to delete
all table rows and set the auto increment to 0.


=item B<--commit_after_each_table_insert>

Commit changes after all data has been inserted to a table. The default is
true.
=item B<--verbose>
             
See more information.

=item B<--quiet>
             
See less information(the default).
=item B<-help>
             
Print a brief help message and exits.
              
=item B<-man>
               
Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<user-db-populate.pl> will populate the user database tables using
information stored in files. 
Each file name must be a combination of the table name with  a suffix of
'.txt'.
eg. populate user_role table with a file user_role.txt. 
The tables can be truncated before populating them,  so as to ensure fresh
data.

=cut
