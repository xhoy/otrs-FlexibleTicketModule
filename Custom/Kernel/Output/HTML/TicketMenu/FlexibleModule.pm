# --
# Kernel/Output/HTML/TicketMenu/FlexibleModule.pm
# Copyright (C) 2015 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::TicketMenu::FlexibleModule;

use strict;
use warnings;

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::Log
    Kernel::System::Ticket
    Kernel::System::Group
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $GroupObject  = $Kernel::OM->Get('Kernel::System::Group');

    my $Action = 'AgentFlexibleTicketDialog';

    # check needed stuff
    if ( !$Param{Ticket} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need Ticket!'
        );

        return;
    }

    # check if frontend module registered, if not, do not show action
    if ( $Param{Config}->{Action} ) {
        my $Module = $ConfigObject->Get('Frontend::Module')->{ $Action };
        return if !$Module;
    }

    my $Dialogs = $ConfigObject->Get('FlexibleTicketModule::Menu')   || {};
    my $Configs = $ConfigObject->Get('FlexibleTicketModule::Dialog') || {};
    my $Ticket  = $Param{Ticket};
    my $UserID  = $Self->{UserID};

    my @MenuItems;

    DIALOG:
    for my $MenuItemName ( sort keys %{$Dialogs} ) {

        my $MenuItem = $Dialogs->{$MenuItemName};
        my $Config   = $ConfigObject->Get( 'FlexibleTicketModule::Dialog' .  $MenuItem->{Config} ) || {};

        if ( $Config->{Permission} ) {
            my $AccessOk = $TicketObject->TicketPermission(
                Type     => $Config->{Permission},
                TicketID => $Ticket->{TicketID},
                UserID   => $Self->{UserID},
                LogNo    => 1,
            );

            next DIALOG if !$AccessOk;
        }

        if ( $Config->{RequiredLock} ) {
            if ( $TicketObject->TicketLockGet( TicketID => $Ticket->{TicketID} ) ) {
                my $AccessOk = $TicketObject->OwnerCheck(
                    TicketID => $Ticket->{TicketID},
                    OwnerID  => $Self->{UserID},
                );

                next DIALOG if !$AccessOk;
            }
        }
    
        # group check
        if ( $Config->{Group} ) {
            my @Items = split /;/, $Config->{Group};
            my $AccessOk;

            ITEM:
            for my $Item (@Items) {
                my ( $Permission, $Name ) = split /:/, $Item;
                if ( !$Permission || !$Name ) {
                    $LogObject->Log(
                        Priority => 'error',
                        Message  => "Invalid config for Key Group: '$Item'! "
                            . "Need something like '\$Permission:\$Group;'",
                    );
                }

                my @Groups = $GroupObject->GroupMemberList(
                    UserID => $Self->{UserID},
                    Type   => $Permission,
                    Result => 'Name',
                );

                next ITEM if !@Groups;
    
                GROUP:
                for my $Group (@Groups) {
                    if ( $Group eq $Name ) {
                        $AccessOk = 1;
                        last GROUP;
                    }
                }
            }

            next DIALOG if !$AccessOk;
        }
    
        # check acl
        my %ACLLookup = reverse( %{ $Param{ACL} || {} } );
        next DIALOG if ( !$ACLLookup{$Action} );

        $Config->{Link} = 'Action=' . $Action . '&TicketID=[% Data.TicketID | html %]&DialogName=' . $MenuItem->{Config};

        my $DialogItem = { %{$MenuItem}, %{ $Config }, %{ $Param{Ticket} }, %Param };
        push @MenuItems, $DialogItem;
    }

    # return item
    return @MenuItems;
}

1;
