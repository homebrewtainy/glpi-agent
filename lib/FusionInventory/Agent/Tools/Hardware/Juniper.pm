package FusionInventory::Agent::Tools::Hardware::Juniper;

use strict;
use warnings;

use FusionInventory::Agent::Tools::Hardware;

sub setConnectedDevicesMacAddresses {
    my (%params) = @_;

    my $snmp  = $params{snmp};
    my $model = $params{model};
    my $ports = $params{ports};

    my $dot1dTpFdbAddress    = $snmp->walk($model->{oids}->{dot1dTpFdbAddress});
    my $dot1dTpFdbPort       = $snmp->walk($model->{oids}->{dot1dTpFdbPort});
    my $dot1dBasePortIfIndex = $snmp->walk($model->{oids}->{dot1dBasePortIfIndex});


    foreach my $oid (sort keys %{$dot1dTpFdbAddress}) {
        my $suffix = $dot1dTpFdbAddress->{$oid};
        my $mac =
            sprintf "%02x:%02x:%02x:%02x:%02x:%02x", getElements($oid, -6, -1);
        next unless $mac;

        # get port key
        my $portKey = $suffix;

        # get interface key from port key
        my $ifKey = $dot1dTpFdbPort->{$portKey};
        next unless defined $ifKey;

        # get interface index
        my $ifIndex = $dot1dBasePortIfIndex->{$ifKey};
        next unless defined $ifIndex;

        my $port = $ports->{$ifIndex};

        # this device has already been processed through CDP/LLDP
        next if $port->{CONNECTIONS}->{CDP};

        # this is port own mac address
        next if $port->{MAC} eq $mac;

        # create a new connection with this mac address
        push
            @{$port->{CONNECTIONS}->{CONNECTION}->{MAC}},
            $mac;
    }
}

1;
__END__

=head1 NAME

FusionInventory::Agent::Tools::Hardware::Juniper - Juniper-specific functions

=head1 DESCRIPTION

This is a class defining some functions specific to Juniper hardware.

=head1 FUNCTIONS

=head2 setConnectedDevicesMacAddresses(%params)

Set mac addresses of connected devices.

=over

=item results raw values collected through SNMP

=item ports device ports list

=item model model

=back
