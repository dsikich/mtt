#!/usr/bin/env perl
#
# Copyright (c) 2005-2006 The Trustees of Indiana University.
#                         All rights reserved.
# $COPYRIGHT$
# 
# Additional copyrights may follow
# 
# $HEADER$
#

########################################################################

package MTT::MPI;

use strict;
use XML::Simple qw(:strict);
use MTT::MPI::Get;
use MTT::MPI::Install;
use Data::Dumper;

#--------------------------------------------------------------------------

# Exported MPI sources handle
our $sources;

# Exported MPI install handle
our $installs;

#--------------------------------------------------------------------------

# Filename where list of MPI sources is kept
my $sources_data_filename = "mpi_sources.xml";

# XML options for the MPI sources
my $sources_xs;

# Filename where list of MPI installs is kept
my $installs_data_filename = "mpi_installs.xml";

# XML options for the MPI installs
my $installs_xs;

#--------------------------------------------------------------------------

# This function exists solely so that we don't have to invoke
# MTT::MPI::Get::Get in the top level
sub Get {
    return MTT::MPI::Get::Get(@_);
}

#--------------------------------------------------------------------------

# This function exists solely so that we don't have to invoke
# MTT::MPI::Install::Install in the top level
sub Install {
    return MTT::MPI::Install::Install(@_);
}

#--------------------------------------------------------------------------

sub _setup_sources_xml {
    $sources_xs = new XML::Simple(KeyAttr => { mpi_get => "name",
                                           },
                                  ForceArray => [ "mpi_get", 
                                                  ],
                                  AttrIndent => 1,
                                  RootName => "mpi_sources",
                                  );
}

#--------------------------------------------------------------------------

sub LoadSources {
    my ($dir) = @_;

    # Explicitly delete anything that was there
    $MTT::MPI::sources = undef;

    _setup_sources_xml()
        if (!$sources_xs);
    
    # If the file exists, read it in
    if (-f "$dir/$sources_data_filename") {
        my $in = $sources_xs->XMLin("$dir/$sources_data_filename");

        # Now transform this to the form suitable for
        # $MTT::MPI::sources (see comment in SaveSources)

        # For each MPI get section
        foreach my $mpi_get_key (keys(%{$in->{mpi_get}})) {
            my $mpi_get = $in->{mpi_get}->{$mpi_get_key};

            $MTT::MPI::sources->{$mpi_get_key} = $mpi_get;
        }
    }
}

#--------------------------------------------------------------------------

sub SaveSources {
    my ($dir) = @_;

    _setup_sources_xml()
        if (!$sources_xs);

    # Transform $MTT::MPI::sources to something XML::Simple can write
    # into valid XML (since our values can [and will] contain :'s,
    # which are the namespace identifiers in XML)
    my $transformed;

    # For each MPI get section
    foreach my $mpi_get_key (keys(%$MTT::MPI::sources)) {
        my $mpi_get = $MTT::MPI::sources->{$mpi_get_key};

        $transformed->{mpi_get}->{$mpi_get_key} = $mpi_get;
    }

    # Write out the file
    my $xml = $sources_xs->XMLout($transformed);
    my $file = "$dir/$sources_data_filename";
    open(FILE, ">$file.new");
    print FILE $xml;
    close(FILE);
    system("mv $file.new $file");
}

#--------------------------------------------------------------------------

sub _setup_installs_xml {
    $installs_xs = new XML::Simple(KeyAttr => { mpi_get => "name",
                                                mpi_install => "name",
                                            },
                                   ForceArray => [ "mpi_get", 
                                                   "mpi_install",
                                                   ],
                                   AttrIndent => 1,
                                   RootName => "mpi_installs",
                                   );
}

#--------------------------------------------------------------------------

sub LoadInstalls {
    my ($dir) = @_;

    # Explicitly delete anything that was there
    $MTT::MPI::installs = undef;

    _setup_installs_xml()
        if (!$installs_xs);
    
    # If the file exists, read it in
    if (-f "$dir/$installs_data_filename") {
        my $in = $installs_xs->XMLin("$dir/$installs_data_filename");

        # Now transform this to the form suitable for
        # $MTT::MPI::installs (see comment in SaveSources).  Wow.

        # For each MPI get section
        foreach my $mpi_get_key (keys(%{$in->{mpi_get}})) {
            my $mpi_get = $in->{mpi_get}->{$mpi_get_key};

            # For each MPI install section
            foreach my $mpi_install_key (keys(%{$mpi_get->{mpi_install}})) {
                $MTT::MPI::installs->{$mpi_get_key}->{$mpi_install_key} = 
                    $in->{mpi_get}->{$mpi_get_key}->{mpi_install}->{$mpi_install_key};
            }
        }
    }
}

#--------------------------------------------------------------------------

sub SaveInstalls {
    my ($dir) = @_;

    _setup_installs_xml()
        if (!$installs_xs);

    # Transform $MTT::MPI::installs to something XML::Simple can write
    # into valid XML (see comment in SaveSources).  Wow.
    my $transformed;

    # For each MPI get section
    foreach my $mpi_get_key (keys(%{$MTT::MPI::installs})) {
        my $mpi_get = $MTT::MPI::installs->{$mpi_get_key};

        # For each MPI install action
        foreach my $mpi_install_key (keys(%{$mpi_get})) {
            my $mpi_install = $mpi_get->{$mpi_install_key};

            $transformed->{mpi_get}->{$mpi_get_key}->{mpi_install}->{$mpi_install_key} = 
                $mpi_get->{$mpi_install_key};
        }
    }

    # Write out the file
    my $xml = $installs_xs->XMLout($transformed);
    my $file = "$dir/$installs_data_filename";
    open(FILE, ">$file.new");
    print FILE $xml;
    close(FILE);
    system("mv $file.new $file");
}

1;