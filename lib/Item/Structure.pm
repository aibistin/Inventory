#===============================================================================
#
#         FILE: /Item/Structure.pm
#
#  DESCRIPTION: Base Class For any  Item Structure to be used for the Mover Project
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
package Item::Structure;
use Moo::Role;

use Types::Standard qw{ Enum };

#------  Globals
my $FRAME_TYPES = [
    qw /aluminum bamboo brass canvas cardboard ceramic concrete copper fabric glass gold iron lacquer lucite
    marble masonite paper particle_board plastic pressed_wood  pvc silver
    steel stone tin wicker wood other
      /];

my $TOP_TYPES = [
    qw /aluminum brass canvas cardboard ceramic concrete copper fabric glass gold iron lacquer lucite
    marble mirror paper plastic pvc silver steel stone tin wood other
      /];

my $SURFACE_TYPES = [
    qw /aluminum brass canvas cardboard ceramic copper fabric glass gold lacquer lucite
    marble mirror paper plastic pvc silver steel stone tin upholstered wood other
      /];

my $FABRIC_TYPES = [
    qw /acrylic cotton lace leather nylon other polystyrene pvc rayon silk synthetic velvet 
      /];

#------ ATTRIBUTES

#--- Frame
has 'frame' => (
 is => 'ro', 
 isa => Enum $FRAME_TYPES, 
);

#--- Top
has 'top' => (
 is => 'ro', 
 isa => Enum $TOP_TYPES, 
);

#--- Surface
has 'surface' => (
 is => 'ro', 
 isa => Enum $SURFACE_TYPES, 
);

#--- Fabric
has 'fabric' => (
 is => 'ro', 
 isa => Enum $FABRIC_TYPES, 
);
 
#------------------------------------------------------------------------------
#---                     METHODS
#------------------------------------------------------------------------------


1;
