# Abstract: Form to add item to the database
#===============================================================================
#
#         FILE: Inventory/Form/Item.pm
#
#  DESCRIPTION:
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Austin Kenny (), aibistin.cionnaith@gmail.com
# ORGANIZATION: Carry On Coding
#      VERSION: 1.0
#      CREATED: 10/24/2013 08:39:41 PM
#     REVISION: ---
#===============================================================================
package Inventory::Form::Item;
use Moo;

#--- With description and structure role.
with( 'Item::Desc', 'Item::Structure' );

use Log::Any qw{$log};
use Try::Tiny;

#------ Locate my Types Module
#use FindBin;
#my $run_dir = $FindBin::Bin;
#use lib "$FindBin::Bin/../lib";
#use Cwd qw/realpath/;
#use lib  realpath( "$FindBin::Bin/../lib");

use Types::Standard qw{Bool Maybe Object Str };
use MyTypes
  qw{ Furniture  ImageFileName  is_ImageFileName  MeasuringUnit MeasuringSys PositiveOrZeroInt };

use Carp qw{croak};
use Data::Dump qw/dump/;

#--- utility files
use List::Util qw{first};

#--- My utility files
use MyUtil qw { camelcase_str  full_chomp is_str_alpha  make_str_alpha };

#------ GLOBALS
use MyConstant
  qw/$FAIL $NO $ONE_TO_500 $FIVE_TO_1000  $MAX_IMAGE_SIZE $TEN_TO_10000 $TRUE  $YES/;

#------  Globals
my $DEFAULT_UNIT               = 'inch';
my $ID                         = q{id};
my $TYPE                       = q{type};
my $TYPE_DEFAULT_VALUE         = 0;
my $TYPE_LABEL                 = q{Item Type};
my $LOCATION                   = q{location};
my $LOCATION_DEFAULT_VALUE     = 0;
my $LOCATION_LABEL             = q{Location};
my $LENGTH                     = q{length};
my $LENGTH_DEFAULT_VALUE       = 0;
my $LENGTH_LABEL               = q{Length};
my $WIDTH                      = q{width};
my $WIDTH_DEFAULT_VALUE        = 0;
my $WIDTH_LABEL                = q{Width};
my $HEIGHT                     = q{height};
my $HEIGHT_DEFAULT_VALUE       = 0;
my $HEIGHT_LABEL               = q{Height};
my $DIAMETER                   = q{diameter};
my $DIAMETER_DEFAULT_VALUE     = 0;
my $DIAMETER_LABEL             = q{Diameter};
my $WEIGHT                     = q{weight};
my $WEIGHT_DEFAULT_VALUE       = 0;
my $WEIGHT_LABEL               = q{Weight};
my $PHOTO                      = q{photo};
my $PHOTO_DEFAULT_VALUE        = q{};
my $PHOTO_LABEL                = q{Include Image};
my $EXTERNAL_REF               = q{external_ref};
my $EXTERNAL_REF_DEFAULT_VALUE = undef;
my $EXTERNAL_REF_LABEL         = q{External Ref};
my $COMMENTS                   = q{comments};
my $COMMENTS_DEFAULT_VALUE     = q{};
my $COMMENTS_LABEL             = q{Additional Info};

my @item_table_cols = (
    $ID,    $TYPE,         $LOCATION, $LENGTH,
    $WIDTH, $HEIGHT,       $DIAMETER, $WEIGHT,
    $PHOTO, $EXTERNAL_REF, $COMMENTS
);

my $INCHES_LABEL = qw{Inches};
my $POUNDS_LABEL = qw{LB's};

#-------------------------------------------------------------------------------
#                      ATTRIBUTES
#-------------------------------------------------------------------------------

#------ Attributes

#has id => (
#    is  => 'ro',
#    isa => Maybe[PositiveOrZeroInt]
#);

#------ Type
#--- Will use this Furniture type for now
#    Maybe in future I will overide this in sub class to use Database Types
has 'type' => (
    is     => 'ro',
    isa    => Maybe [PositiveOrZeroInt],
    coerce => PositiveOrZeroInt->coercion,
);

my ($extract_int_sub);

has location => (
    is     => 'ro',
    isa    => Maybe [PositiveOrZeroInt],
    coerce => PositiveOrZeroInt->coercion,
    coerce => sub { $extract_int_sub->(shift) },
);

#has color => (
#    is  => 'ro',
#    isa => Str
#);

#------
#------ Dimensions
##------
has height => (
    is     => 'ro',
    isa    => Maybe [PositiveOrZeroInt],
    coerce => PositiveOrZeroInt->coercion,
);
#
has width => (
    is     => 'ro',
    isa    => Maybe [PositiveOrZeroInt],
    coerce => PositiveOrZeroInt->coercion,
);
#
has length => (
    is     => 'ro',
    isa    => Maybe [PositiveOrZeroInt],
    coerce => PositiveOrZeroInt->coercion,
);

has diameter => (
    is     => 'ro',
    isa    => Maybe [PositiveOrZeroInt],
    coerce => PositiveOrZeroInt->coercion,
);
#
##------ Weight
has weight => (
    is     => 'ro',
    isa    => Maybe [PositiveOrZeroInt],
    coerce => PositiveOrZeroInt->coercion,
);

#
#
##------ Measuring Units
#has units => (
#    is      => 'ro',
#    isa     => MeasuringUnit,
#    default => sub { $DEFAULT_UNIT }
#);

#
##------ Photo
has photo => (
    is => 'ro',

    #    isa    => ImageFileName,
    isa => Maybe [Object],
);

#-------------------------------------------------------------------------------
#  For Form Class
#-------------------------------------------------------------------------------
##------ Types
has types => (
    is  => 'ro',
    isa => sub {
        croak("$_[0] is not an ArrayRef!")
          unless ( ref( $_[0] ) eq 'ARRAY' );
    },
    required => 1,
);

##------ Locations
has locations => (
    is  => 'ro',
    isa => sub {
        croak("$_[0] is not an ArrayRef!")
          unless ( ref( $_[0] ) eq 'ARRAY' );
    },
    required => 1,
);

##------ form_data
has form_data => (
    is  => 'rw',
    isa => sub {
        croak("$_[0] is not a HashRef!")
          unless ( ref( $_[0] ) eq 'HASH' );
    },
);

##------ Has the form been submitted
has submitted => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

##------ Is the form valid
has is_valid => (
    is      => 'rw',
    isa     => Bool,
    default => 1,
    writer  => '_set_is_valid',
);

#-------------------------------------------------------------------------------
#  Coersion Subs
#-------------------------------------------------------------------------------
$extract_int_sub = sub {
    my ($int) = $_[0] =~ /(\d+)/;
    $int;
};

#-------------------------------------------------------------------------------
#  Validation Subroutine Names
#-------------------------------------------------------------------------------
my ($photo_validation_sub);

#-------------------------------------------------------------------------------
#                      BUILD FORM DATA
#-------------------------------------------------------------------------------
#---
#---

=head2 create_form_data
    Build a data sructure to contain all necessary form data for adding an
    Item to the database.
    'bootstrap_validation_state' : "has_success" "has_warning" "has_success"
=cut

sub BUILD {
    my $self = shift;

 #    my $lists     = shift || croak('create_form_data requires data lists!  ');
 #    my $types     = $lists->{types};
 #    my $locations = $lists->{locations};

    my $types     = $self->types();
    my $locations = $self->locations();

    #--- Add a Selector Placeholder to beginning of list
    my $type_default = 'Select ' . $TYPE_LABEL;

    #--- Add a Selector Placeholder to beginning of list
    my $location_default = 'Select ' . $LOCATION_LABEL;

    $self->form_data(
        {

            #--- Will be an integer
            type => {
                label                => $TYPE_LABEL,
                name                 => $TYPE,
                required             => $YES,
                group_req            => [],
                default_select_label => $type_default,
                default_select_label_attr =>
'selected=\"$type_default\" disabled="disabled" required="required" ',
                default_value            => $TYPE_DEFAULT_VALUE,
                selection_list           => $types,
                valid                    => $NO,
                key_value_selection_list => $TRUE,
                message => 'You need to enter a valid item type!',
            },

            #--- Will be an integer
            location => {
                label                => $LOCATION_LABEL,
                name                 => $LOCATION,
                required             => $YES,
                group_req            => [],
                default_select_label => $location_default,
                default_select_label_attr =>
'selected=\"$location_default\" disabled="disabled" required="required" ',
                default_value            => $LOCATION_DEFAULT_VALUE,
                selection_list           => $locations,
                valid                    => $NO,
                key_value_selection_list => $TRUE,
                message => 'You need to enter a valid location!',
            },
            length => {
                label                => $LENGTH_LABEL,
                name                 => $LENGTH,
                required             => $YES,
                group_req            => [qw/length width height/],
                selection_list       => [ (@$ONE_TO_500) ],
                default_select_label => $INCHES_LABEL,
                default_value        => $LENGTH_DEFAULT_VALUE,
                valid                => $NO,
                value_range          => [ 0, 1000 ],
                message              => 'You need to enter a valid length!',
            },
            width => {
                label                => $WIDTH_LABEL,
                name                 => $WIDTH,
                required             => $YES,
                group_req            => [qw/length width height/],
                selection_list       => [ (@$ONE_TO_500) ],
                default_select_label => $INCHES_LABEL,
                default_value        => $WIDTH_DEFAULT_VALUE,
                valid                => $NO,
                value_range          => [ 0, 1000 ],
                message              => 'You need to enter a valid width!',
            },
            height => {
                label                => $HEIGHT_LABEL,
                name                 => $HEIGHT,
                required             => $YES,
                group_req            => [qw/length width height/],
                selection_list       => [ (@$ONE_TO_500) ],
                default_select_label => $INCHES_LABEL,
                default_value        => $HEIGHT_DEFAULT_VALUE,
                valid                => $NO,
                value_range          => [ 0, 1000 ],
                message              => 'You need to enter a valid height!',
            },
            diameter => {
                label                => $DIAMETER_LABEL,
                name                 => $DIAMETER,
                required             => $YES,
                group_req            => [qw/diameter height/],
                selection_list       => [ (@$FIVE_TO_1000) ],
                default_select_label => $INCHES_LABEL,
                default_value        => $DIAMETER_DEFAULT_VALUE,
                valid                => $NO,
                value_range          => [qw/0 1000/],
                message              => 'You need to enter a valid diameter!',
            },
            weight => {
                label                => $WEIGHT_LABEL,
                name                 => $WEIGHT,
                required             => $NO,
                group_req            => [],
                selection_list       => [ (@$TEN_TO_10000) ],
                default_select_label => $POUNDS_LABEL,
                default_value        => $WEIGHT_DEFAULT_VALUE,
                valid                => $NO,
                value_range          => [ 0, 10000 ],
                message              => 'You need to enter a valid weight!',
            },
            photo => {
                label          => $PHOTO_LABEL,
                name           => $PHOTO,
                required       => $YES,
                default_value  => $PHOTO_DEFAULT_VALUE,
                valid          => $NO,
                validation_sub => $photo_validation_sub,
                message        => 'You need to enter a valid Photo!',
            },
        }
    );

}

#-------------------------------------------------------------------------------
#        Populate Template
#-------------------------------------------------------------------------------
#---
#---
#--- Create A Template Attributes Hash
#---

=head2 create_form_template
    Create a Template data structure with the form data.
=cut

sub create_form_template {
    my $self                            = shift;
    my $form_data                       = $self->form_data();
    my $form_bootstrap_validation_state = q{};

    my @error_messages;

    #--- Create a list of form_field error messages if the form is invalid
    if ( not $self->is_valid() ) {
        $form_bootstrap_validation_state = 'has-error';
        for my $form_field ( keys(%$form_data) ) {
            if ( $form_data->{$form_field}{valid} ) {
                $form_data->{$form_field}{bootstrap_validation_state} =
                  'has-success';
            }
            else {
                push( @error_messages, $form_data->{$form_field}{message} );
                $form_data->{$form_field}{bootstrap_validation_state} =
                  'has-error';
            }
        }
    }
    return {
        bootstrap_validation_state => $form_bootstrap_validation_state,

        #--- Function CallBack
        camelcase_str  => sub { camelcase_str(@_) },
        is_valid       => $self->is_valid(),
        error_messages => \@error_messages,
        %$form_data
    };

}

#---
#---
#--- Reurn a list of form keys and values
#---

=head2 get_form_field_values
    Reurns a HahRef of form fields with their values.
=cut

sub get_form_field_values {
    my $self = shift;
    my %fields = map { $_ => $self->{$_} }
      (qw {type location height width length diameter weight photo});
    return \%fields;
}

#-------------------------------------------------------------------------------
#                      V A L I D A T I O N
#-------------------------------------------------------------------------------

sub validate {
    my $self      = shift;
    my $form_data = $self->form_data();
    $self->_set_is_valid($YES);

    #    $self->validate_type();
    #    $self->validate_location();
    #    $self->validate_length();
    #    $self->validate_width();
    #    $self->validate_height();
    #    $self->validate_diameter();
    #    $self->validate_weight();
    #    $self->validate_photo();

  VALIDATION_LOOP:
    for my $item_v ( keys(%$form_data) ) {

        my $input_value = $self->$item_v();
        $log->debug( "Testing $item_v with value : "
              . ( $input_value // q{undefined} ) );

        #------ Not defined field,  but the field is NOT required.
        ( ( not $input_value ) && ( $form_data->{$item_v}{required} == $NO ) )
          && do {
            $form_data->{$item_v}{valid} = $YES;
            next VALIDATION_LOOP;
          };

        #------ Not defined field,  and the field IS required.
        ( ( not $input_value ) && ( $form_data->{$item_v}{required} == $YES ) )
          && do {
            $form_data->{$item_v}{valid} = $NO;
            $self->_set_is_valid($NO);
            $log->debug('INVALID: Input value not defined!!!');
            next VALIDATION_LOOP;
          };

        #------ Defined field, and the field has a validation subroutine.
        ( ($input_value) && ( defined $form_data->{$item_v}{validation_sub} ) )
          && do {
            my $field_validation_sub = $form_data->{$item_v}{validation_sub};

            #----- Validation Sub returns (yes/no,  $message/undef)
            my ( $field_is_valid, $message ) =
              $field_validation_sub->($input_value);
            $log->debug( 'Validation subroutine got this rc: '
                  . ( $field_is_valid // '<invalid rc, fix it>' )
                  . ' and this message : '
                  . ( $message // '<no message,  all must be good>' )
                  . ' !' );
            $form_data->{$item_v}{valid} = $field_is_valid;

            #--- Will only have a message if the field is invalid
            $form_data->{$item_v}{message} = $message if ($message);
            $self->_set_is_valid($field_is_valid);
            $log->debug('INVALID: Input value not defined!!!');
            next VALIDATION_LOOP;
          };

       #------ If Input Value is ==  the "Default Selection Value" (placeholder)
       #       and No Input is OK
        (        ( $input_value eq lc $form_data->{$item_v}{default_value} )
              && ( $form_data->{$item_v}{required} == $NO ) )
          && do {
            $log->debug(
                $input_value . ' is the default value, but thats ok!!!' );
            $form_data->{$item_v}{valid} = $YES;
            next VALIDATION_LOOP;
          };

        #---If the value can be validated against a key => value list
        #                                           'id' is the key

        if ( $form_data->{$item_v}{key_value_selection_list} ) {

            #------ If the selection matches the list of valid values.

            $log->debug( 'Validating '
                  . $input_value
                  . ' against a list of '
                  . $item_v
                  . 's' );
            ( first { $input_value == ( $_->{id} ) }
                @{ $form_data->{$item_v}{selection_list} } )
              && do {
                $form_data->{$item_v}{valid} = $YES;
                next VALIDATION_LOOP;
              };
        }

        #---If the value can be verified as being within a range of
        #   values(inclusive)
        if ( $form_data->{$item_v}{value_range} ) {
            $log->debug( 'Testing '
                  . $input_value
                  . ' against value range '
                  . dump $form_data->{$item_v}{value_range} );
            if (   ( $input_value >= $form_data->{$item_v}{value_range}->[0] )
                && ( $input_value <= $form_data->{$item_v}{value_range}->[1] ) )
            {

                $form_data->{$item_v}{valid} = $YES;
                next VALIDATION_LOOP;

            }
        }

        #--- Fall-Through
        $form_data->{$item_v}{valid} = $NO;
        $self->_set_is_valid($NO);
        $log->debug( 'INVALID: Defined but not valid; ' . $item_v . ' value!' );

    }

}

#-------------------------------------------------------------------------------
#  Individual Field Validation
#-------------------------------------------------------------------------------

=head2 photo_validation_sub 
  Validate the file type by first checking the file suffix,
  then validating the file type with File::LibMagic
  Also checks that the file is smaller than the maximum allowed 
  size from the config file.
  File Should be in Dancer2::Core::Request::Upload Object format.
  It has methods basename,  size and tempname that are used in the 
  validation.
  Returns (YES/NO, undef/MESSAGE). Only returns a message if the Image file is
  Invalid

  (gif|png|jpe?g);
=cut

$photo_validation_sub = sub {
    return unless $_[0];
    my $upload_file_obj               = shift;
    my $file_magic_image_file_type_rx = qr{image/(jpeg|gif|png)};
    my $message;

    $log->debug( 'Validating this file : ' . $upload_file_obj->basename );
    $log->debug( 'With this size: ' . $upload_file_obj->size );
    if ( not is_ImageFileName( lc( $upload_file_obj->basename ) ) ) {
        $message = 'File must be of type gif,  png,  jpg, jpeg';
        return ( $NO, $message );
    }

    if ( $upload_file_obj->size > $MAX_IMAGE_SIZE ) {
        $message =
          'File must be less than ' . $upload_file_obj->size . ' bytes!';
        return ( $NO, $message );
    }

    #------ Use File magic to validate the file if it is available.
    #-------If it is not available,  will have to accept that the file
    #       is really an image
    my $FileMagic = try {
        require File::LibMagic;
        File::LibMagic->new();
    }
    catch {
        $log->error( "Unable to Load File::LibeMagic because: \n"
              . ( $_ // '<no error message>' ) );
        return $FAIL;
    };

    #--- Assume File is a valid image as advertised
    return ( $YES, undef ) unless $FileMagic;

    #--- Final check with File::LibMagic
    if ( $FileMagic->checktype_filename( $upload_file_obj->tempname ) =~
        /$file_magic_image_file_type_rx/ )
    {
        return ( $YES, undef );
    }
    $log->debug( 'File magic said this image file is : '
          . $FileMagic->checktype_filename( $upload_file_obj->tempname ) );
    return ( $NO, q{This is not an image file!} );
};

#------------------------------------------------------------------------------
1;
