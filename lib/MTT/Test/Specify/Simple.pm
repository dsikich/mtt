#!/usr/bin/env perl
#
# Copyright (c) 2005-2006 The Trustees of Indiana University.
#                         All rights reserved.
# Copyright (c) 2006      Cisco Systems, Inc.  All rights reserved.
# $COPYRIGHT$
# 
# Additional copyrights may follow
# 
# $HEADER$
#

package MTT::Test::Specify::Simple;

use strict;
use Cwd;
use MTT::Messages;
use MTT::Values;
use MTT::Defaults;
use Data::Dumper;

#--------------------------------------------------------------------------

sub Specify {
    my ($ini, $section, $build_dir, $mpi_install, $config) = @_;
    my $ret;

    $ret->{test_result} = 0;

    # Loop through all the parameters from the INI file and put them
    # in a hash that is easy for us to traverse
    my $params;
    foreach my $field ($ini->Parameters($section)) {
        if ($field =~ /^simple_/) {
            $field =~ m/^simple_(\w+):(.+)/;
            $params->{$1}->{$2} = $ini->val($section, $field);
        }
    }

    # First, go through an make lists of the executables
    foreach my $group (keys %$params) {
        # Look up the tests value.  Skip it if we didn't get one for
        # this group.
        my $tests = $params->{$group}->{tests};
        if (!$tests) {
            Warning("No tests specified for group \"$group\" -- skipped\n");
            delete $params->{$group};
            next;
        }

        # Evaluate it to get the full list of tests
        $tests = MTT::Values::EvaluateString($tests);

        # Split it up if it's a string
        if (ref($tests) eq "") {
            my @tests = split(/\s/, $tests);
            $tests = \@tests;
        }
        $params->{$group}->{tests} = $tests;
    }

    # Now go through and see if any of the tests are marked as
    # "exclusive". If they are, remove those tests from all other
    # groups.
    foreach my $group (keys %$params) {
        # If this group is marked as exclusive, remove each of its
        # tests from all other groups
        if ($params->{$group}->{exclusive}) {
            foreach my $t (@{$params->{$group}->{tests}}) {
                foreach my $g2 (keys %$params) {
                    next 
                        if ($g2 eq $group);

                    my @to_delete;
                    my $i = 0;
                    foreach my $t2 (@{$params->{$g2}->{tests}}) {
                        if ($t eq $t2) {
                            push(@to_delete, $i);
                        }
                        ++$i;
                    }
                    foreach my $t2 (@to_delete) {
                        delete $params->{$g2}->{tests}[$t2];
                    }
                }
            }
        }
    }

    # Now go through those groups and make the final list of tests to pass
    # upwards
    foreach my $group (keys %$params) {

        # Go through the list of tests and create an entry for each
        foreach my $t (@{$params->{$group}->{tests}}) {
            # If it's good, add a hash with all the values into the
            # list of tests
            if (-x $t) {
                my $one;
                # Do a deep copy of the defaults
                %{$one} = %{$config};

                # Set the test name
                $one->{executable} = $t;
                Debug("   Adding test: $t (group: $group)\n");

                # Set all the other names that were specified for this
                # group
                foreach my $key (keys %{$params->{$group}}) {
                    next
                        if ($key eq "tests");
                    $one->{$key} = $params->{$group}->{$key};
                }

                # Save it on the final list of tests
                push(@{$ret->{tests}}, $one);
            }
        }
    }

    # All done
    $ret->{test_result} = 1;
    return $ret;
} 

1;