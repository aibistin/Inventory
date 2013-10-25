#===============================================================================
#
#         FILE: /Item/Desc.pm
#
#  DESCRIPTION: Moo Role For Adding Descriptions To an Item Object
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
package Item::Desc;
use Moo::Role;
use Types::Standard qw{ Bool Str };

#------  Globals

#------  Attributes

#------ 
has 'antique' => (
    is  => 'ro',
    isa => Bool,
    default => sub{0}
);

#------
has 'designer' => (
    is  => 'ro',
    isa => Bool,
    default => sub{0}
);

#------ Needs Dis-Assembly 
has 'dis_assembly' => (
    is  => 'ro',
    isa => Bool,
    default => sub{0}
);

#------ 
has 'fragile' => (
    is  => 'ro',
    isa => Bool, 
    default => sub {0}
);


#------ Needs Re-Assembly 
has 're_assembly' => (
    is  => 'ro',
    isa => Bool,
    default => sub{0}
);

#------ White Glove :)
has 'special_handling' => (
    is  => 'ro',
    isa => Bool,
    default => sub{0}
);


#-----Any description to add to the piece
has 'description' => (
    is => 'rw', 
    isa => Str, 
);
#------------------------------------------------------------------------------
#---                     METHODS
#------------------------------------------------------------------------------


1;
