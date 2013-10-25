# Abstract: Item Class
#===============================================================================
#
#         FILE: /Item/Item.pm
#
#  DESCRIPTION: Base Class For any Item to be used for the Mover Project
#
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Austin Kenny (), aibistin.cionnaith@gmail.com
# ORGANIZATION: Carry On Coding
#      VERSION: 1.0
#      CREATED: 09/23/2013 06:53:29 PM
#     REVISION: ---
#===============================================================================
package Item::Item;
use Moo;
#--- With description and structure role.
with( 'Item::Desc', 'Item::Structure' );

use MyConstant qw/$PI/;
use Types::Standard qw{ Bool Enum Int Num Str };
use lib "../";

#------ Locate my Types Module
use FindBin;
my $run_dir = $FindBin::Bin;
use lib "$FindBin::Bin/../lib";
use lib "/home/austin/perl/Apps/Inventory/lib/";
use MyTypes
  qw{ Furniture MeasuringUnit MeasuringSys NegativeInt PI PositiveInt PositiveOrZeroInt ZeroInt };

#------  Globals
my $METRIC   = q/metric/;
my $IMPERIAL = q/imperial/;

#------ If Validate is on,  BUILDARGS will validate the input args
has validate_item => (
    is  => 'ro',
    isa => Bool, 
    default => sub{1}
);

#------ Attributes

has id => (
    is  => 'ro',
    #----- make it undefable
    isa => PositiveOrZeroInt
);

#------ Type
#--- Will use this Furniture type for now
#    Maybe in future I will overide this in sub class to use Database Types
has 'type' => (
    is      => 'ro',
    isa     => Furniture,
    default => sub { 'other' }
);

has location => (
    is  => 'ro',
    isa => Str
);

has color => (
    is  => 'ro',
    isa => Str 
);

#------
#------ Dimensions
#------
has height => (
    is  => 'ro',
    isa => PositiveOrZeroInt,
);

has width => (
    is  => 'ro',
    isa => PositiveOrZeroInt,
);

has length => (
    is  => 'ro',
    isa => PositiveOrZeroInt,
);

has diameter => (
    is  => 'ro',
    isa => PositiveOrZeroInt,
);

#------ Weight
has weight => (
    is  => 'ro',
    isa => PositiveOrZeroInt,
);

#------ Measuring System
has measuring_sys => (
    is      => 'ro',
    isa     => MeasuringSys,
    default => sub { 'metric' }
);

#------ Measuring Units
has units => (
    is      => 'ro',
    isa     => MeasuringUnit,
    default => sub { 'in' }
);

#-------------------------------------------------------------------------------
#  Special Methods
#
#-------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#---                     METHODS
#------------------------------------------------------------------------------

#--- Calculate Volome only if we have the necessary data

=head2 volume
  Calculate the item volume.
  (L * W * H) or (((Diameter/2)**) * PI * H)
=cut

sub volume {
    my $self = shift;

    if ( $self->diameter && $self->height ) {

        ##-- PI r(2) * h
        print 'Calculating the volume using the diameter: ' . $self->diameter
          . "\n";
        return ( ( $self->diameter / 2 )**2 ) * $PI * $self->height;
    }
    elsif ( $self->length and $self->width and $self->height ) {
        print 'Calculating the volume using l*w*h : '
          . ( $self->length * $self->width * $self->height ) . "\n";
        return $self->length * $self->width * $self->height;
    }
    else {
        print "Dont have the data to calculate the volume.\n";
        return undef;
    }

}

#-------------------------------------------------------------------------------
#  Validation
#-------------------------------------------------------------------------------

=head2 validate
    Validate the Item Properties
=cut

sub validate {

}

#------------------------------------------------------------------------------
1;
__END__




Chair
Rocking_chair
Watchman%27s_chair
Windsor_chair
Wing_chair


Bean_bag
Chaise_longue
Fauteuil
Ottoman
Recliner
Stool

Bar_stool
Footstool
Tuffet
couch

#------ Multiple seats
Bench
Couch
settee

Accubita
Canapé
Davenport


Divan
Love_seat
seat

#------ Sleeping or lying



Bunk_bed
Canopy_bed
Four-poster_bed
bed
Murphy_bed
Platform_bed
Sleigh_bed
Waterbed


Daybed
Futon
Hammock
Headboard
Infant_bed
cradle
Mattress
Sofa_bed


Billiard_table
table
Chess_table
Entertainment_center
Phonograph
Hi_fi
Jukebox
Pinball_machine
Radiogram
Television
Radio
Video_game_console
console

#----- Surfaces

Chabudai
Changing_table
table
Desk

Davenport_desk
desk
Drawing_board
Computer_desk
Writing_desk


Kotatsu
Korsi
Lowboy
Monks_bench
Pedestal

Coffee_table
Dining_table
Drop-leaf_table
table
End_table
table
Folding_table
Gateleg_table
Poker_table
Trestle_table
TV_tray_table
Wine_table


Washstand
Workbench

Bookcase
Cabinetry

Closet
Cupboard
Curio_cabinet
Hutch
Pantry

Chest
Chest_of_drawers
drawers

Hope_Chest

Coat rack

Filing_cabinet
cabinet
Nightstand
Shelf
Sideboard
Safe
Umbrella stand




Wardrobe
Wine_rack

Bedroom_set

Rattan
Folding_screen
Curtain
























































































































