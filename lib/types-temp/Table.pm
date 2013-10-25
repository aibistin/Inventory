#===============================================================================
#
#         FILE: Table.pm
#
#  DESCRIPTION: Base Class For any Table to be used for the Mover Project
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
package Table;
use Moo;
extends 'Item';

#--- With description and structure role.
with('Desc' ,  'Structure');

use MooX::Types::MooseLike::Numeric qw(PositiveOrZeroNum PositiveInt);
use MooX::Types::MooseLike::Base qw(Str Enum);

#------  Globals
my $PI          = 3.14159;
my $TABLE_NAME  = q/table/;
my $TABLE_TYPES = [
    qw /billards dining coffee conference corner dropleaf end folding gaming kids kitchen 
      massage nested night office overstuffed picnic pool serving side other
      /
];
my $DEFAULT_DIAMETER = 0;
my $DEFAULT_WIDTH    = 36;
my $DEFAULT_LENGTH   = 36;
my $DEFAULT_HEIGHT   = 24;
my $DEFAULT_WEIGHT   = 80;
my $DEFAULT_TYPE     = 'dining';

#------ Attributes

#------ Override Name to Table
has '+name' => (
    is  => 'ro',
    isa => sub {
        die 'Table can only be called a table, and not ' . $_[0] . '! '
          unless $_[0] eq $TABLE_NAME;
    },
    default => sub { $TABLE_NAME }
);

#------ Type of Table
has table_type => (
    is      => 'ro',
    isa     => Enum $TABLE_TYPES,
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
