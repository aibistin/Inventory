# ABSTRACT: Moo Role to read the Inventory Images Directory
#-------------------------------------------------------------------------------
=head2
  Connects to Inventory Images Directory and returns an IO::Dir Instance. 
  Also has a safe closing of directory.
=cut
#
package Inventory::Roles::Dir;
use Moo::Role;
use autodie;
use IO::Dir;
use FindBin;

#------ Locate my Databse Modules
my $run_dir          = "$FindBin::Bin";
my $DEFAULT_DIR_NAME = "$run_dir/../images/";

#--- My utility files
use Types::Standard qw{ Bool Object Str };
use MyConstant qw/$TRUE $FALSE $FAIL/;

#------ Attributes
has dir => (
    is      => 'ro',
    isa     => sub { IO::Dir->new($_ // $DEFAULT_DIR_NAME) || die "Cannot open directory $_ !" },
    lazy    => 1, 
    clearer => 1,
#    default => sub {
#        IO::Dir->new($DEFAULT_DIR_NAME) || die "Cannot open default directory $_ !";
#    },
    predicate => 'has_dir',
    reader    => 'get_dir'
);

#-------------------------------------------------------------------------------
#  Close Dir
#-------------------------------------------------------------------------------
sub close_dir {
    my $self = shift;
    my $dir = $self->get_dir() or return $FAIL;
    $dir->close();
}

#-------------------------------------------------------------------------------
1;
