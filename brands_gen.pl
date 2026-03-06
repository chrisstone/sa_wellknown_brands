#!/usr/bin/perl

use strict;
use warnings;
use v5.10;

# @file brands_gen.pl
# @author Chris Stone
# @version 1.1.4
# @description Generates SpamAssassin rules for Brands, Subjects, and Brand+Lure combinations.

# --- Configuration ---
my $input_brands = 'brands.txt';
my $input_lures  = 'lures.txt';
my $output_file  = 'local_brands.cf';
my $spam_score   = '5.0';
my $lure_score   = '2.5'; 
my $rule_prefix  = 'L_WK_'; # Shortened prefix to prevent >40 char names
# ---

open(my $br_fh, '<', $input_brands) or die "Error: Cannot open '$input_brands': $!\n";
open(my $out_fh, '>', $output_file) or die "Error: Cannot open '$output_file': $!\n";

# Load Lures into an array for cross-referencing
my @lures;
if (-e $input_lures) {
    open(my $lu_fh, '<', $input_lures);
    while (<$lu_fh>) {
        chomp;
        next if /^\s*(#.*)?$/;
        push @lures, $_;
    }
    close($lu_fh);
}

say "Processing brands and lures to generate '$output_file'...";

# --- Generate Global Lure Rules First ---
foreach my $lure (@lures) {
    my $l_id = uc($lure);
    $l_id =~ s/[^A-Z0-9]//g;
    # Truncate lure ID if necessary
    $l_id = substr($l_id, 0, 10);
    printf $out_fh "header __%sLU_%s\tSubject =~ /\\b%s\\b/i\n", $rule_prefix, $l_id, $lure;
}
print $out_fh "\n";

# --- Process Brands ---
while (my $brand_regex = <$br_fh>) {
    chomp $brand_regex;
    next if $brand_regex =~ /^\s*(#.*)?$/;

    my $identifier = $brand_regex;
    $identifier =~ s/\\W\?//g; 
    $identifier =~ s/\.\?//g;  
    $identifier =~ s/\\s\*//g; 
    $identifier =~ s/[^a-zA-Z0-9]+//g;
    $identifier = uc($identifier);
    
    # Truncate brand identifier to 15 chars to keep total rule length safe
    $identifier = substr($identifier, 0, 15);

    if (length($identifier) == 0) { next; }

    # Standard Brand Rules (Name, Addr, Subject)
    printf $out_fh "# Rules for: %s\n", $identifier;
    printf $out_fh "header __%s%sa\tFrom:name =~ /\\b%s\\b/i\n", $rule_prefix, $identifier, $brand_regex;
    printf $out_fh "header __%s%sb\tFrom:addr =~ /%s\\./\n", $rule_prefix, $identifier, $brand_regex;
    printf $out_fh "header __%s%ss\tSubject =~ /\\b%s\\b/i\n", $rule_prefix, $identifier, $brand_regex;

    # Standard Meta Rules
    printf $out_fh "meta   %s%s\t(__%s%sa && !__%s%sb)\n", $rule_prefix, $identifier, $rule_prefix, $identifier, $rule_prefix, $identifier;
    printf $out_fh "score  %s%s\t%s\n", $rule_prefix, $identifier, $spam_score;

    printf $out_fh "meta   %s%ss\t(__%s%ss && !__%s%sb)\n", $rule_prefix, $identifier, $rule_prefix, $identifier, $rule_prefix, $identifier;
    printf $out_fh "score  %s%ss\t%s\n", $rule_prefix, $identifier, $spam_score;

    # Brand + Lure Logic
    foreach my $lure (@lures) {
        my $l_id = uc($lure);
        $l_id =~ s/[^A-Z0-9]//g;
        $l_id = substr($l_id, 0, 10);
        
        # Meta name structure: L_WK_BRAND_LURE (e.g., L_WK_AMAZON_REWARD)
        printf $out_fh "meta   %s%s_%s\t((__%s%sa || __%s%ss) && __%sLU_%s && !__%s%sb)\n",
            $rule_prefix, $identifier, $l_id, $rule_prefix, $identifier, $rule_prefix, $identifier, $rule_prefix, $l_id, $rule_prefix, $identifier;
        printf $out_fh "score  %s%s_%s\t%s\n", $rule_prefix, $identifier, $l_id, $lure_score;
    }

    print $out_fh "\n";
}

close($br_fh);
close($out_fh);

say "Complete. Version 1.1.4 generated.";