# ABSTRACT: Base Form Class
#===============================================================================
#
#         FILE: Form.pm
#
#  DESCRIPTION:
#
#       AUTHOR: Austin Kenny (), aibistin.cionnaith@gmail.com
# ORGANIZATION: Carry On Coding
#      VERSION: 1.0
#      CREATED: 11/11/2013 05:03:25 PM
#     REVISION: ---
#===============================================================================
package Form;
use Moo;
use Types::Standard qw{Bool};

#------ GLOBALS
use MyConstant qw/$FAIL $NO  $TRUE $YES/;

#--- My utility files
use MyUtil qw { camelcase_str };

use Log::Any qw{$log};

#-------------------------------------------------------------------------------
#  Attributes
#-------------------------------------------------------------------------------

##------ form_data

=head2 form_data
    HashRef contiaining all the form attributes and validation flags;
=cut

has form_data => (
    is  => 'rw',
    isa => sub {
        croak("$_[0] is not a HashRef!")
          unless ( ref( $_[0] ) eq 'HASH' );
    },
);

##------ Has the form been submitted

=head2 submitted
    Bool,  
=cut

has submitted => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

##------ Is the form valid

=head2 is_valid
    Bool,  
    Read Only.
=cut

has is_valid => (
    is      => 'rw',
    isa     => Bool,
    default => 1,
    writer  => '_set_is_valid'
);

#-------------------------------------------------------------------------------
#        Populate Template With The Form Data
#-------------------------------------------------------------------------------
#---
#--- Create A Template Attributes Hash
#---

=head2 create_form_template
    Create a Template data structure using the form_data Hash.
    Generate error messages array.
    Set Bootstrap validation state flags;
    Set the overall validation status of the form. 
    Returns the form_data with additions.
    return 
    {
        bootstrap_validation_state => $form_bootstrap_validation_state,
        #--- Function CallBack
        camelcase_str  => sub { camelcase_str(@_) },
        is_valid       => $self->is_valid(),
        error_messages => \@error_messages,
        %$form_data
    };

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

#-------------------------------------------------------------------------------
#                      V A L I D A T I O N
#-------------------------------------------------------------------------------

sub validate {
    my $self      = shift;
    my $form_data = $self->form_data();
    $self->_set_is_valid($YES);

  VALIDATION_LOOP:
    for my $item_v ( keys(%$form_data) ) {

        my $input_value = $self->$item_v();
        $log->debug( "Testing $item_v with value : "
              . ( $input_value // q{undefined} ) );

        #------ Not defined field,  but the field is NOT required.
        ( ( not $input_value ) && ( $form_data->{$item_v}{required} == $NO ) )
          && do {
            $form_data->{$item_v}{valid} = $YES;
            $log->debug('No Input value, and none required,  so all OK!');
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
        ( defined $form_data->{$item_v}{validation_sub} )
          && do {
            my $field_validation_sub = $form_data->{$item_v}{validation_sub};

            #----- Validation Sub returns (yes/no,  $message/undef)
            my ( $field_is_valid, $message ) =
              $field_validation_sub->($input_value);
            $log->debug( 'Validation subroutine got this rc: '
                  . ( $field_is_valid // '<invalid rc, fix it>' )
                  . ' and this message : '
                  . ( $message // '<no message,  all must be good>' )
                  . ' ! when testing this value : '
                  . $input_value );
            $form_data->{$item_v}{valid} = $field_is_valid;

            #--- Will only have a message if the field is invalid
            $form_data->{$item_v}{message} = $message if ($message);
            $self->_set_is_valid($NO) unless $field_is_valid;
            next VALIDATION_LOOP;
          };

       #------ If Input Value is ==  the "Default Selection Value" (placeholder)
       #       and No Input is OK
        (        ( $form_data->{$item_v}{default_value} )
              && ( $input_value eq lc $form_data->{$item_v}{default_value} )
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

    return $self->is_valid();
}

=head2 invalidate_field
    Sets form field to invalid. Sets the Form to invalid also.
    Use this when the form has been validated, but subsequently if a field
    does not match a datatabase value, etc.,  it must be invalidated.
    Pass the form field name to be invalidated.
    Pass an optional message to override the original error message.
=cut

sub invalidate_field {
    my $self       = shift;
    my $form_field = shift
      // croak('invalidate_field() needs a form field to invalidate!');
    my $error_message = shift;

    croak('invalidate_field() could not find this field, $form_field!')
      unless $self->form_data()->{$form_field};
    $self->form_data()->{$form_field}{valid}   = $NO;
    $self->form_data()->{$form_field}{message} = $error_message
      if $error_message;
    $log->debug( '*** Achtung, Achtung!! Invalidated the form field: '
          . $form_field
          . ' !**' );
    $self->_set_is_valid($NO);
}

#------------------------------------------------------------------------------
1;

