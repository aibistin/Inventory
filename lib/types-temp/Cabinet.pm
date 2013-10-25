#===============================================================================
#
#         FILE: Chair.pm
#
#  DESCRIPTION: Base Class For any Chair to be used for the Mover Project
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Austin Kenny (), aibistin.cionnaith@gmail.com
# ORGANIZATION: Carry On Coding
#      VERSION: 1.0
#      CREATED: 09/23/2013 06:53:29 PM
#     REVISION: ---
#===============================================================================
package Chair;
use Moo;
extends 'Item';

#--- With description role.
with('Desc');

use MooX::Types::MooseLike::Numeric qw(PositiveOrZeroNum PositiveInt);
use MooX::Types::MooseLike::Base qw(Str Enum);

#------  Globals
my $METRIC      = q/metric/;
my $IMPERIAL    = q/imperial/;
my $PI          = 3.14159;
my $CHAIR_NAME  = q/chair/;
my $CHAIR_TYPES = [
    qw / deck dining room armchair club corner dentists
      garden harvard kids kitchen louisXIV
      office overstuffed recliner rocking standard stool other
      /
];
my $DEFAULT_DIAMETER = 0;
my $DEFAULT_WIDTH    = 18;
my $DEFAULT_LENGTH   = 18;
my $DEFAULT_HEIGHT   = 36;
my $DEFAULT_WEIGHT   = 40;
my $DEFAULT_TYPE     = 'standard';

#------ Attributes

#------ Override Name to Chair
has '+name' => (
    is  => 'ro',
    isa => sub {
        die 'Chair can only be called a chair, and not ' . $_[0] . '! '
          unless $_[0] eq $CHAIR_NAME;
    },
    default => sub { $CHAIR_NAME }
);

#------ Type of Chair
has chair_type => (
    is      => 'ro',
    isa     => Enum $CHAIR_TYPES,
    default => sub { $DEFAULT_TYPE }
);

#------ Override Height
has height => (
    is      => 'ro',
    isa     => PositiveOrZeroNum,
    default => sub { $DEFAULT_HEIGHT }
);

#------ Override length
has length => (
    is      => 'ro',
    isa     => PositiveOrZeroNum,
    default => sub { $DEFAULT_LENGTH }
);

#------ Override width
has width => (
    is      => 'ro',
    isa     => PositiveOrZeroNum,
    default => sub { $DEFAULT_WIDTH }
);

#------ Override Diameter
has +diameter => (
    is      => 'ro',
    isa     => PositiveOrZeroNum,
    default => sub { $DEFAULT_DIAMETER }
);

#------ Override Weight
has +weight => (
    is      => 'ro',
    isa     => PositiveOrZeroNum,
    default => sub { $DEFAULT_WEIGHT }
);

#------------------------------------------------------------------------------
#---                     METHODS
#------------------------------------------------------------------------------

1;
