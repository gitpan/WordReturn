package WordReturn;
use strict;
use vars qw($file $st $content $VERSION @tags);
$VERSION='0.01';

sub new{
    my $class = ref($_[0]) || $_[0];      # Works as object or class method
    my $self={ @_ };
    #my $self->{args} ={};
    return(bless($self, $class));
}



# getWords						
# This subroutine returns a hash reference		
# containing a list of words in a documnet and the 	
# number of times that word appears within the document.			
######################################################

sub getWords{

my $self = shift;
my %tmpwords="";
my %words="";
my $num=""; #number of times the word must appear

 if (@_) { @{ $self->{args} } = @_ }   

$file=$self->{args}[0]; #file name



my $html=$self->{args}[1]; #html, on or off
unless($html eq "on"){$html="";}


unless ($self->{args}[2]){ $num=1; } #if blank, use default
else{
    $num=$self->{args}[2];
}

    #is it a url?
    if ($file=~m/http\:\/\//){
	&getWebPage($content);
    }
    #Then it is a file
    else{
	&getFileContents;
    }
    
    &makeString;
    
#Do we need to strip the HTML?  Not the best way, will change in a future release   
   if ($html eq ""){
   &stripHTML;
   }

#apply stop words
    if ($self->{args}[3] eq "off"){}
    elsif (($self->{args}[3] eq "")||($self->{args}[3] eq "on")){
	&stopWords("",$content);
    }
    else{
	&stopWords($self->{args}[3],$content);
    }

  #split at the word boundries
   my @line= split /\b \b/, $content;

    #build a temp hash and count    
	foreach my $line(@line){
	    $tmpwords{$line}++;
	}
    
    #build the final hash containing only those words that are >= $num
    foreach my $k (keys %tmpwords){
	
	if( $tmpwords{$k} >= $num){
	$words{$k} =$tmpwords{$k};
	}
	else{
	}
	}	

return \%words;


} #end getWords

# weightWords
# give more value to a word if it is contained between user-supplied tags
#
# ! todo - add meta and possible searching within tags between tags(needed ?)
###########################################################################

sub weightWords{

my $self = shift;
my %tmpwords="";
my %words="";
my $num=""; #number of times the word must appear
my %tagged="";
 if (@_) { @{ $self->{args} } = @_ }   

$file=$self->{args}[0]; #file name



my $html=$self->{args}[1]; #html, on or off
unless($html eq "on"){$html="";}


unless ($self->{args}[2]){ $num=1; } #if blank, use default
else{
$num=$self->{args}[2];
}

    #is it a url?
    if ($file=~m/http\:\/\//){
	&getWebPage($content);
    }
    #Then it is a file
    else{
	&getFileContents;
    }

    &makeString;
# get the "weighted word tags
#! I don't like this at all, something to work on....
@tags=split /,/,$self->{args}[4];

my $tagcontent = $content;

foreach my $tag(@tags){
    # Need to re-work this, it does the job for now though.
    
    $tagcontent =~m/<$tag.*?>([\w\W]{1,})<\/$tag>/;
	my @wt = split / /, $1;
	    foreach my $w(@wt){
		#why is it that the <b> keeps coming back in the test?
		$w=~s/<.*?>//g; #kills anything within an html tag within the specified tags
		$tagged{$w}++;
		}
    }	    


#Do we need to strip the HTML?  Not the best way, will change in a future release   
   if (($html eq "") || ($html eq "on")){
   &stripHTML;
   }

#apply stop words
    if ($self->{args}[3] eq "off"){} #no stop words
    elsif (($self->{args}[3] eq "")||($self->{args}[3] eq "on")){ #use the built in
	&stopWords("",$content);
    }
    else{	#use a user supplied file
	&stopWords($self->{args}[3],$content);
    }

  #split at the word boundries
   my @line= split /\b \b/, $content;
    my %firstwords; # the first 100 words get weighted too.
	for(my $i = 0; $i <= 100;$i++){
    	    $firstwords{$line[$i]}++;
	}

    #build a temp hash and count    
	foreach my $line(@line){
		#1 provided tags
		if (exists $tagged{$line}){
		    $tmpwords{$line}=$tmpwords{$line}+1.2;
		    }
		#2 first 100
		elsif (exists $firstwords{$line}){
		    $tmpwords{$line}=$tmpwords{$line}+1.1;
		    }
		#then the rest - non weighted
		else{
		    $tmpwords{$line}++;
		}
	}
    
    #build the final hash containing only those words that are >= $num
    foreach my $k (keys %tmpwords){
	
	if( $tmpwords{$k} >= $num){
	$words{$k} =$tmpwords{$k};
	}
	else{
	}
    }	

return \%words;


} # end of weightWords




# getPhrases						
# Read the document, split at the punctuation, analyize each sentence
#######################################################################

sub getPhrases{

my $self = shift;
$file=$self->{args}[0];
my $num="";
my $phrasewords;
my %tmpwords;
my %words;
if (@_) { @{ $self->{args} } = @_ }   

$file=$self->{args}[0];
my $html=$self->{args}[1];
unless($html eq "on"){$html="";}

unless($self->{args}[2]){ $num=1; }
else{
$num=$self->{args}[2];
}
if($self->{args}[3]){
$phrasewords=$self->{args}[3]-1; #remember, it starts at 0, not 1

}else{
 $phrasewords=1; }


if ($file=~m/http\:\/\//){
    &getWebPage;

    }
    else{
    &getFileContents($content);
    }

    &makeString;
   
   if ($html eq ""){
    &stripHTML;
   }

#apply stop words
if ($self->{args}[4] eq "off"){
}
elsif (($self->{args}[4] eq "")||($self->{args}[4] eq "on")){
    &stopWords("",$content);
    }
    else{
    &stopWords($self->{args}[4],$content);
    }

#split each sentence at the punctuation.  I don't think a phrase would cross a sentence.
$content =~ s/\s+/ /g;
my @lines= split /[\.!?]/, $content;
my $line;
my %phrase;

# analyize each sentence
foreach $line(@lines){
	my @words=split /\b \b/, $line;
	my $end=$#words;    
	my $x=1;
	    while ($x <= $end){
		my $a=0;
		my $shortphrase;
		    while ($a <= $phrasewords){
			$shortphrase= "$shortphrase $words[$a]";
			$a++;
		    }
		$phrase{$shortphrase}++;
		undef $shortphrase;
		$x++;
	    }

    
    }


#filter out anything that appears only once
foreach my $k(keys %phrase){
#if ($k >= $num){   
    if ($phrase{$k} >= $num){ 
	    $words{$k} = $phrase{$k};
    }
                       }
return \%words;
}#end of getPhrases


#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#
# helper subs

sub makeString{

#put the entier document into a string.
    $content=lc($content); #make it all lowercase
    $content=~s/\n/ /g; #remove  the newlines
    $content =~ s/\r/ /g;
    $content=~s/[.\"\?\'\!\,\:\|]/ /g;
    $content =~ s/\s-\s/ /g;
    $content =~ s/\s+/ /g; # and make it all one string
    return $content;

}


sub stripHTML{

#remove all the html (quick and dirty)
    $content =~s/<style.*?>.*?<\/style>//;   
    $content =~s/<script.*?>.*?<\/script>//;    
    $content =~ s/<.*?>/ /g;
    $content =~ s/-->/ /g;
    $content =~ s/\s+/ /g;
    $content =~s/\&[A-Za-z1-9#]{1,}\;/ /g;    
    return $content;
    
    }

sub stopWords($st, $content){
my @stopwords;
my $stop;
my $list;

    if ($words::st){
	open(STOPW, "$st");
	while(<STOPW>){
	    $list=$list.$_;
	}
	close STOPW;
	
	$list=~s/\n/ /;
	$list=~s/,/ /g;
	$list =~ s/s+/ /g;

	print $list;
	@stopwords = split / /, $list;
    }
	
    else{
    #will change in future release, quick and dirty, serves my purpose
	@stopwords=qw(all had up want need more above no i'd should probably me us will from meta any anyone try when linux but which nbsp; like would are get go one then two three nothing do to into how just really use don't you on have content and my know been wrote at using than problem problems the can not is was as it with an were for in a of or this that these them their was were be to too also i by);
    }

    foreach $stop (@stopwords){
	$content=~s/\b$stop\b//g;
    }
    $content =~ s/\s+/ /g; #one long string
    return $content;
}# end sub stopwords

#########################################################
# getWebPage						#
# the subroutine to get the text of a WWW page using	#
# LWP::Simple						#
#########################################################

sub getWebPage{
    if (eval "require LWP::Simple"){
	LWP::Simple->import();
	$content=get($file);
	return $content;
    }
    else{
	print "LWP::Simple was not found, you will not be able to fetch $file\n";
    }
} #end of sub getWebPage

#########################################################
# getFileContents					#
# the sub-routine to get the contents of the specified	#
# file and put it into a string.			#
# 							#
#########################################################

sub getFileContents($content){
    open(FILE, "$file");
    while (<FILE>){
	$content=$content.$_;
    }
    return $content;
} #end of sub getFileContents

1;

__END__

=head1 NAME

Text::WordReturn - A Perl module that quickly identifies words and phrases in a document and returns the number of times they appear within that document.

=head1 SYNOPSIS

    use Text::WordReturn;
    
    $n= new->WordReturn();
    $n->getWords("file", "on", "2");
    
    # or
    
    $n->weightWords("file.txt", "on", "3", "on", "title,h2");
     
    # or
    
    $n->getPhrases("file", "on", "2", "3");
    
    # or if LWP is installed
    
    $n->getWords("http://some.url.com", "on", "3");
    
=head1 INSTALLATION
 
Just follow the usual procedure:
 
   perl Makefile.PL
   make
   make test
   make install      

=head1 PREREQUISITES

    WordReturn can analyze a document via a URL if LWP is installed.

=head1 DESCRIPTION

    WordReturn provides a quick and easy way to retrieve a list of words or phrases in a document and
    returns the number of times each word or phrase appears within that document. The ability to weigh words based on their location in the document (or between specified XML/HTML tags).
    This module can be useful for search and "more like this" type of applications, such as Web based Usenet archives.


=head1 METHODS

=head2 getWords("file", "html", "number of times", "stopwords")

getWords returns a reference to a hash containing the 
words in a document and the number of times each word appears within the document.

getWords takes the following arguments:

B<file> - Either the name of a file, or a URL (IF LWP is installed).

B<html> - 'on' or 'off' - off (default if left blank) or on.  On strips the HTML from a document, off leaves the HTML there.

B<number of times> the word needs to appear to be returned.  The default is 2.

B<stopwords> - 'on','off' or 'filename'  - use built-in, use none, or supply a file (words should be separated by spaces or one word per line)  Default is on.

=head2 Example:

$list=getWords("file.txt", "on", "3", "on");

$list is a reference to a hash that contains the words in file.txt that appear 3 times or more, any html is 
stripped, and the built-in stop words are used.

=head2 weightWords("file", "html", "number of times", "stopwords", "tag,tag,tag")

weightWords returns a reference to a hash containing the 
words in a document and the weighted value for that word.

weightWords takes the following arguments:

B<file> - Either the name of a file, or a URL (IF LWP is installed)

B<html> - 'on' or 'off' - off (default if left blank) or on.  'on' strips the HTML from a document, 'off' leaves the HTML there.

B<number of times> the word needs to appear to be returned.  The default is 2.

B<stopwords> - 'on','off' or 'filename'  - use built-in, use none, or supply a file (words should be separated by spaces or one word per line)  Default is on.

B<tag> - words appearing between these specified tags (tag names should not include <> and should be separated with a comma) will get a higher value (1.2).

The top 100 words of a document are also given a higher value (1.1).

=head2 Example:

$list=weightWords("file.txt", "on", "3", "on", "title,h2");

$list is a reference to a hash that contains the words in file.txt that appear 3 times or more, any html is 
stripped, and the built-in stop words are used.

=head2 getPhrases("file", "html", "number of times", "number of words", "meta")

getPhrases returns a reference to a hash containing the 
phrases in a document and the number of times each phrase appears within the document.

getPhrases takes the following arguments:

B<file> - Either the name of a file, or a URL (if LWP is installed).

B<html> - 'on' or 'off' - off (default if left blank) or on.  'on' strips the HTML from a document, 'off' leaves the HTML there.

B<number of times> the phrase needs to appear to be returned.  The default is 2.

B<number of words> in a phrase, default is 2.

B<stopwords> - 'on','off' or 'filename'  - use built-in, use none, or supply a file (words should be separated by spaces or one word per line)  Default is on.

=head2 Example:

$list=getPhrases("file.txt", "on", "3", "2", "on");

$list is a reference to a hash that contains the phrases in file.txt that appear 3 times or more, contain a minimum of 2 words and any html is 
stripped, and built-in stop words are used. 

=head1 MORE EXAMPLES

Retrieve any word that appears 3 more more times from www.linux.org.

use Text::WordReturn;
$n=WordReturn->new();
$list=$n->getWords("http://www.linux.org", "off","3");

%h=%{$list};
foreach $k(keys  %h){
        print "$k - $h{$k}\n";
}                    

=head1 COPYRIGHT

2001 Mark Griskey <mark@linuxhardware.net>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
=cut
