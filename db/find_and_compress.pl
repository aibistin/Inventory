#!/usr/bin/env perl
#===============================================================================
#
#
#   USAGE: ./find_and_compress.pl
#
#  DESCRIPTION:
#      Find Files and Compress them.
#      Put them into a directory.
#
#  OPTIONS:
#     --file_extension                  the (.pl) is the default
#     --archive_name                    The basename for the .tgz file(default is my_backup)
#     --zipfile directory               Directory where the zipped files will
#                                       be placed.
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
#      CREATED: 11/17/2013
#===============================================================================
use Modern::Perl;
use autodie;
use Getopt::Long;
use Pod::Usage;
use Log::Log4perl qw(:easy);
use Carp qw/croak/;
use Data::Dump qw/dump/;
use diagnostics -verbose;
use MyConstant qw/$YES $NO $TRUE $FALSE/;
use MyDateUtil qw/ get_db_formatted_localtime /;
use Path::Class;
use File::Path qw/make_path/;
use File::Copy;
use FindBin;
my $run_dir = $FindBin::Bin;
say "Current directory is $run_dir";

#-------------------------------------------------------------------------------
#  Default Options
#-------------------------------------------------------------------------------
my $verbose   = q//;
my $quiet     = q//;
my $log_level = q/debug/;
my $man       = 0;
my $help      = 0;

#------ SQLite databse name  'database_file'
my $FILE_EXT = q(.pl);
my $TAR_FILE_NAME  = q/my_backup/;
my $ZIP_DIR  = q/zip_dir/;

#-------------------------------------------------------------------------------
#  Other Globals
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  Main
#-------------------------------------------------------------------------------
process_options();

my $dir = dir($run_dir);
DEBUG "Directory is $dir";
my $sub_dir = $dir->subdir($ZIP_DIR);
DEBUG "Sub Directory is $sub_dir";

make_path($sub_dir, {verbose => 1});

while ( my $f = $dir->next ) {
    next unless $f =~ m/$FILE_EXT$/i;
    DEBUG 'Found file ' . $f;

    copy($f, $sub_dir);

   my @cmd = ( 'tar','cvzf', $TAR_FILE_NAME . '.tgz',  $sub_dir );
   system(@cmd) and die 'System call : ' . dump(@cmd) . ' failed!';
}

INFO 'All Done!';
exit;

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
        'zip_dir=s'  => \$ZIP_DIR,
        'file_ext=s' => \$FILE_EXT,
        'archive_name=s'    => \$TAR_FILE_NAME, 
        verbose      => \$verbose,
        quiet        => sub { $verbose = 0 },
        'debug=s'    => \$log_level,
        'help|?'     => \$help,
        man          => \$man,
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
 
find_and_compress.pl - Compress files of a given type.
  
=head1 SYNOPSIS
 
find_and_compress.pl 

  OPTIONS:
     --file_extension                  the (.pl) is the default
     --archive_name                    The basename for the .tgz file(default is my_backup)
     --zipfile directory               Directory where the zipped files will
                                       be placed.
                               
     --verbose             verbose
     --quiet               not verbose (default)
     --debug               fatal, error(default), warn, info, debug, trace
     --help                brief help message
     --man                 full documentation

=head1 OPTIONS
           
=over 8

=item B<--database_file>

Default SQLite3 database name is user.db, but you can specify another.

B<find_and_compress.pl> --database_file  happy_user.db

=item B<--debug>
             
Set the debug level if any. The default is error.
The following options are available, in decreasing levels of necessity:
fatal, error, warn, info, debug, trace.           

B<find_and_compress.pl> --debug debug


=item B<--pasword_len>

The maximum length for a User password. The default is 20.

B<find_and_compress.pl> --password_len 15

=item B<--pasword_salt_len>

The maximum length for the 'salt' string for a the user password. The default is 10.

B<find_and_compress.pl> --password_salt_len 9

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

B<find_and_compress.pl> will populate the user database tables using
information stored in files. 
Each file name must be a combination of the table name with  a suffix of
'.txt'.
eg. populate user_role table with a file user_role.txt. 
The tables can be truncated before populating them,  so as to ensure fresh
data.

=cut
