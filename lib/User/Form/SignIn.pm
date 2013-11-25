#ABSTRACT : SignIn form framework and validation
#===============================================================================
#
#         FILE: User/Forms/SignIn.pm
#
#  DESCRIPTION:  Build and Validate SignIn Form.
#
#       AUTHOR: Austin Kenny (), aibistin.cionnaith@gmail.com
# ORGANIZATION: Carry On Coding
#      VERSION: 1.0
#      CREATED: 11/11/2013 02:48:38 PM
#     REVISION: ---
#===============================================================================
package User::Form::SignIn;
use Moo;
extends 'Form';
use autodie;
use Log::Any qw{$log};

use Types::Standard qw{Bool Maybe Object Str Undef };
use MyTypes qw{ Email EmptyStr PositiveOrZeroInt ShortStrRange SimpleStr};

use Carp qw{croak};
use Data::Dump qw/dump/;

#--- My utility files
use MyUtil qw { full_chomp is_str_alpha  make_str_alpha };
use MyConstant qw/$FAIL $NO $YES/;

my $USERNAME_LABEL            = q{Email Address:};
my $USERNAME                  = q{username};
my $PASSWORD_LABEL            = q{Password:};
my $PASSWORD                  = q{password};
my $REMEMBER_ME_LABEL         = q{Remember Me};
my $REMEMBER_ME               = q{remember_me};
my $REMEMBER_ME_DEFAULT_VALUE = q{};

my @FORM_FIELDS = ( $USERNAME, $PASSWORD, $REMEMBER_ME );

my $MIN_PASSWORD_LENGTH  = 5;
my $MAX_PASSWORD_LENGTH  = 30;

my $is_pasword_length_ok = sub {
    ( length($_[0]) >= $MIN_PASSWORD_LENGTH ) && ( length($_[0]) <= $MAX_PASSWORD_LENGTH );
};

#-------------------------------------------------------------------------------
#  Attributes
#-------------------------------------------------------------------------------
has username => (
    is     => 'rw',
    isa    => Maybe [Email],
    coerce => Email->coercion
);

has password => (
    is     => 'rw',
    isa    => Maybe [ShortStrRange],
    coerce => SimpleStr->coercion
);

has remember_me => (
    is      => 'rw',
    isa     => Bool,
    coerce  => Bool->coercion,
    default => 0
);

#-------------------------------------------------------------------------------
#                      BUILD FORM DATA
#-------------------------------------------------------------------------------
#---
#---

=head2 BUILD
    Build a data sructure to contain all necessary form data for Signing In
    'bootstrap_validation_state' : "has_success" "has_warning" "has_success"
=cut

sub BUILD {
    my $self = shift;

    $self->form_data(
        {
            #--- Will be an email address
            username => {
                label     => $USERNAME_LABEL,
                name      => $USERNAME,
                value     => $self->username(),
                required  => $YES,
                group_req => [],
                valid     => $NO,

                # stick with attribute validation for now
                validation_sub => sub { $YES, undef },
                message => 'You need to enter a valid username!',
            },

            #--- Will be an integer
            password => {
                label     => $PASSWORD_LABEL,
                name      => $PASSWORD,
                value     => $self->password(),
                required  => $YES,
                group_req => [],

                # stick with attribute validation for now
                #                validation_sub => sub { ( $YES, undef ) },
                validation_sub => sub {
                    $log->debug('Calling test password length with : ' . $_[0]);
                    return (
                        $NO, "Password must be longer than $MIN_PASSWORD_LENGTH
                            and less than $MAX_PASSWORD_LENGTH!"
                    ) unless $is_pasword_length_ok->($_[0]);
                },
                valid     => $NO,
                message => 'You need to enter a valid password!',
            },

            #--- Check Box
            remember_me => {
                label          => $REMEMBER_ME_LABEL,
                name           => $REMEMBER_ME,
                value          => $self->remember_me(),
                required       => $NO,
                group_req      => [qw/username password/],
                default_value  => $REMEMBER_ME_DEFAULT_VALUE,
                validation_sub => sub {
                    $_ //= 0;
                        $_ == 0 ? ( $YES, undef )
                      : $_ == 1 ? ( $YES, undef )
                      :           ( $NO,  'Must be either 1 or 0 !' );
                },
                valid => $NO,
            },
        }
    );

}

=head2 get_form_field_values
    Reurns a HahRef of form fields with their values.
=cut

sub get_form_field_values {
    my $self = shift;
    my %fields = map { $_ => $self->{$_} } @FORM_FIELDS;
    return \%fields;
}

#------------------------------------------------------------------------------
1;
