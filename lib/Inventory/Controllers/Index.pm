# Abstract: Index module for Inventory App Controllers
package Inventory::Controllers::Index;
use Dancer2;
prefix undef;


get '/' => sub {
    template 'welcome';
};

#-------------------------------------------------------------------------------
true;
