#!/usr/bin/perl
use Text::WordReturn;


#########################################################
# wordstest.pl						#
# 							#
# A simple script to test and demonstrate WordReturn.	#
#							#
#########################################################



$obj=WordReturn->new();
$file="../README";


$list=$obj->getWords("$file", "off","3","on", "off");
%h=%{$list};
 foreach $k(keys  %h){
	print "$k - $h{$k}\n";
}



