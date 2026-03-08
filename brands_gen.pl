#!/usr/bin/perl

use strict;
use warnings;
use v5.10;

# @file brands_gen.pl
# @author Chris Stone
# @version 1.2.0
# @description Generates SpamAssassin rules for Brands, Subjects, and Brand+Lure combinations.

# --- Configuration ---
my $input_brands = 'brands.txt';
my $input_lures  = 'lures.txt';
my $output_file  = 'local_brands.cf';
my $spam_score   = '5.0';
my $subj_score   = '3.0';
my $lure_score   = '2.5';
my $rule_prefix  = 'L_WK_'; # Shortened prefix to prevent >40 char names
# ---

say "Reading '$input_brands'...";
open(my $br_fh, '<', $input_brands) or die "Error: Cannot open '$input_brands': $!\n";
open(my $out_fh, '>', $output_file) or die "Error: Cannot open '$output_file': $!\n";

# Load Lures into an array for cross-referencing
my @lures;
if (-e $input_lures) {
    say "Reading '$input_lures'...";
    open(my $lu_fh, '<', $input_lures);
    while (<$lu_fh>) {
        chomp;
        next if /^\s*(#.*)?$/;
        push @lures, $_;
    }
    close($lu_fh);
}

# --- Generate Global Lure Rules First ---
say "Writing Lures section...";
my $lures_regex = join('|', @lures);
printf $out_fh "# Single rule for all lures\n";
printf $out_fh "header __%sLUREs\tSubject =~ /\\b(%s)\\b/i\n\n", $rule_prefix, $lures_regex;

# --- Process Brands ---
say "Writing Brands section...";
while (my $line = <$br_fh>) {
    chomp $line;
    next if $line =~ /^\s*(#.*)?$/;

    my @fields = split(/\t/, $line);
    my $domain_regex  = $fields[0];
    my $display_regex = defined $fields[1] ? $fields[1] : $domain_regex;

    my $identifier = $domain_regex;
    $identifier =~ s/\\W\?//g;
    $identifier =~ s/\.\?//g;
    $identifier =~ s/\\s\*//g;
    $identifier =~ s/[^a-zA-Z0-9]+//g;
    $identifier = uc($identifier);

    # Truncate brand identifier to 12 chars to keep total rule length safe
    $identifier = substr($identifier, 0, 12);

    if (length($identifier) == 0) { next; }

    # Standard Brand Rules (Name, Addr, Subject)
    printf $out_fh "# Rules for: %s\n", $identifier;
    printf $out_fh "header __%s%sa\tFrom:name =~ /\\b%s\\b/i\n", $rule_prefix, $identifier, $display_regex;
    printf $out_fh "header __%s%sb\tFrom:addr =~ /%s\\./\n", $rule_prefix, $identifier, $domain_regex;
    printf $out_fh "header __%s%ss\tSubject =~ /\\b%s\\b/i\n", $rule_prefix, $identifier, $display_regex;

    # Standard Meta Rules
    printf $out_fh "meta   %s%s\t(__%s%sa && !__%s%sb)\n", $rule_prefix, $identifier, $rule_prefix, $identifier, $rule_prefix, $identifier;
    printf $out_fh "score  %s%s\t%s\n", $rule_prefix, $identifier, $spam_score;

    printf $out_fh "meta   %s%ss\t(__%s%ss && !__%s%sb)\n", $rule_prefix, $identifier, $rule_prefix, $identifier, $rule_prefix, $identifier;
    printf $out_fh "score  %s%ss\t%s\n", $rule_prefix, $identifier, $subj_score;

    # Brand + Lure Logic
    printf $out_fh "meta   %s%sl\t((__%s%sa || __%s%ss) && __%sLUREs && !__%s%sb)\n",
        $rule_prefix, $identifier, $rule_prefix, $identifier, $rule_prefix, $identifier, $rule_prefix, $rule_prefix, $identifier;
    printf $out_fh "score  %s%sl\t%s\n", $rule_prefix, $identifier, $lure_score;

    print $out_fh "\n";
}

close($br_fh);
close($out_fh);

say "Complete. Version 1.2.0 generated.";