#!/usr/bin/perl
#
#CST:xwrona00
#####
#Jan Wrona, xwrona00@stud.fit.vutbr.cz
#Projekt 1 pro predmet IPP
#####

use strict;
use warnings;
#use common::sense;
use 5.8.8;
use Cwd;
use Cwd 'abs_path';

#pole klicovych slov - podle C99
my @keywords = (
    "auto",     "break",    "case",     "char",   "const",   "continue",
    "default",  "do",       "double",   "else",   "enum",    "extern",
    "float",    "for",      "goto",     "if",     "inline",  "int",
    "long",     "register", "restrict", "return", "short",   "signed",
    "sizeof",   "static",   "struct",   "switch", "typedef", "union",
    "unsigned", "void",     "volatile", "while",  "_Bool",   "_Complex",
    "_Imaginary"
);

#text napovedy
my $helptext = "--help - vypise tuto napovedu
--input=fileordir - vstupni soubor nebo adresar
--nosubdir - neprohledavaji se podadresare
--output=filename - vystupni soubor\n
-k - pocet vyskytu klicovbych slov
-o - pocet vyskytu operatoru
-i - pocet vyskytu identifikatoru
-w=pattern - pocet vyskytu textoveho retezce pattern
-c - pocet znaku v komentarich
-p - vypis souboru bez absolutni cesty";

#definice navratovych kodu
my $retok       = 0;
my $retparam    = 1;
my $retinput    = 2;
my $retoutput   = 3;
my $retdirinput = 21;

#definice ostatnich promennych
my @pattern = ();
my $action  = "undef";

my $nosubdir  = 0;
my $noabspath = 0;

my @inputf  = ();
my @outputf = ();

my $INFD;
my $dir;
my $OUTFD;

my @results = ();

########## zacatek programu ##########
makeParam();
io_open();

if ($dir) {
    chdir $dir or die "Nelze zmenit slozku na '$dir': $!\n";
    goThroughDirs();
    printResults();
}
else {
    $inputf[0] = abs_path( $inputf[0] ) if !$noabspath;
    push @results, { path => "$inputf[0]", result => doAction() };
    printResults();
    io_close();
}
exit $retok;

########## subrutiny ##########

###vypis vysledku
#seradi pole vysledku, spocita celkovy pocet
#se spravnym odsazenim vypisuje
sub printResults {

    @results = sort { $a->{path} cmp $b->{path} } @results;

    my $total = 0;
    $total += $_->{result} foreach @results;

    my $longestPath = length("CELKEM:");
    my $longestRes  = length($total);
    for ( my $i = 0 ; $i < scalar @results ; $i++ ) {
        $longestPath = length( $results[$i]->{path} )
          if length( $results[$i]->{path} ) > $longestPath;
        $longestRes = length( $results[$i]->{result} )
          if length( $results[$i]->{result} ) > $longestRes;
    }

    for ( my $i = 0 ; $i < scalar @results ; $i++ ) {
        print $OUTFD $results[$i]->{path},
          spacePad( $longestPath - length( $results[$i]->{path} ) ), " ",
		  spacePad( $longestRes  - length( $results[$i]->{result} )), 
          $results[$i]->{result}, "\n";
    }
    print $OUTFD "CELKEM:", spacePad( $longestPath - length("CELKEM:") ), " ", $total, "\n";
}

#subrutina vraci takovy pocet mezer, jaky dostane argumentem
sub spacePad {
    my $count = shift;
    return " " x $count;
}

#subrutina volajici funkce dle detekovaneho argumentu na prikazove radce
sub doAction {

    use Switch;
    my $res = 0;

    switch ($action) {
        case "keywords"    { $res = countKeywords() }
        case "operators"   { $res = countOperators() }
        case "identifiers" { $res = countIdentifiers() }
        case "comments"    { $res = countComments() }
        case "pattern"     { $res = countPattern( $pattern[0] ) }
        case "undef"       { die "Nedefinovana akce!\n" }
    }
    return $res;
}

###pruchod vsemi zanorenymi adresari
#rekurzivne implementovana, prochazi adresare a hleda soubory s korektni priponou
#pokusi se soubor otevrit a vykonat nad nim pozadovanou akci
my $level = -1;
sub goThroughDirs {
    $level++;

    if ( !$nosubdir ) {
        my @list = glob("*");
        foreach my $item (@list) {
            if ( -d $item ) {
                chdir $item or die "Nelze zmenit slozku na '$item': $!\n";
                goThroughDirs();
            }
        }
    }

    my @chfiles = glob("*.c *.h");
    foreach (@chfiles) {
        i_open($_);

        $_ = abs_path($_) if !$noabspath;
        push @results, { path => "$_", result => doAction() };

        i_close();
    }

    die "Prilis hluboka adresarova struktura!\n" if $level > 100;
    if ( $level-- ) {
        chdir ".." or die "Nelze se vynorit z adresare: $!\n";
    }
}

###pocitani znaku v komentarich, vcetne koncu radku
#pruchod souborem po radcich, vyuziti regularnich vyrazu pro ostraneni nepotrebnych
#informaci ze stringu i pro samotne pocitani znaku
#$mlcomm = 1 pri viceradkovem komentari
sub countComments {
    my $charCount = 0;
    my $mlcomm    = 0;

    while (<$INFD>) {
        s/\r\n/\n/;    #nahrazeni CRLF za LF
        if ($mlcomm)   #handling viceradkoveho komentare
        {
            if (s/(.*?\*\/)(.*)/$2/) {
                $mlcomm = 0;
                $charCount += ( length $1 );
            }
            else {
                $charCount += length $_;
                next;
            }
        }

        $charCount += ( length $2 ) while s/(.*?)(\/\*.*?\*\/)/$1/;    #/*neco*/
        $charCount += ( length $2 ) + ( length $3 ) if s/(.*?)(\/\/.*)(\n{0,1})/$1/;    #//neco
        if (s/^(.*?)(\/\*.*)(\n{0,1})$/$1/)    #detekce pocatku viceradkoveho komentare
        {
            $charCount += ( length $2 ) + ( length $3 );
            $mlcomm = 1;
        }
    }
    return $charCount;
}

#pocitani nalezenych patternu v souboru
sub countPattern {
    my $pattern      = quotemeta shift;
    my $patternCount = 0;

    while (<$INFD>) {
        $patternCount++ while s/$pattern//;
    }
    return $patternCount;
}

###pocitani identifikatoru
#pruchod souborem po radcich, vyuziti regularnich vyrazu pro ostraneni nepotrebnych
#informaci ze stringu i pro samotne pocitani identifikatoru
#$mlcomm = 1 pri viceradkovem komentari, $mlmacro = 1 pri viceradkovem makru
sub countIdentifiers {
    my $mlmacro    = 0;
    my $mlcomm     = 0;
    my $identCount = 0;

    while (<$INFD>) {
        next if removeComments( \$mlcomm);
        next if removeMacros( \$mlmacro);
        removeStrChar();
        foreach my $word (@keywords) {
            s/\b$word\b//g;
        }
        next if /^$/;    #prazdne radky

        $identCount++ while s/(\b[_a-zA-Z][_a-zA-Z0-9]*\b)//;
    }
    return $identCount;
}

###pocitani klicovych slov definovanych v poli @keywords
#pruchod po radcich, odstraneni nepotrebnych informaci
#nasledny cyklus s regularnim vyrazem, pocitajici vyskyty
sub countKeywords {

    my $mlmacro   = 0;
    my $mlcomm    = 0;
    my $wordCount = 0;

    while (<$INFD>) {
        next if removeComments( \$mlcomm);
        next if removeMacros( \$mlmacro);
        removeStrChar();
        next if /^$/;    #prazdne radky

        foreach my $word (@keywords) {
            $wordCount++ while s/\b$word\b//;
        }
    }
    return $wordCount;
}

###pocitani operatoru definovanych v poli @operators
#pruchod po radcich, odstraneni nepotrebnych informaci
#operatory jsou osetreny escape sekvencemi fci quotemeta(), sezareny od nejdelsiho
#v cyklu jsou nahrazovany prazdnym mistem a inktementovan counter
sub countOperators {

    my $mlmacro = 0;
    my $mlcomm  = 0;
    my $opCount = 0;

    my @operators = (
        ( ">>=", "<<=" ),
        (
            "++", "--", "==", "!=", ">=", "<=", "&&", "||", ">>", "<<",
            "+=", "-=", "*=", "/=", "%=", "&=", "|=", "^=", "->"
        ),
        ( "=", "+", "-", "*", "/", "%", ">", "<", "!", "~", "&", "|", "^", ".", )
    );
    foreach my $op (@operators) { $op = quotemeta $op; }

    while (<$INFD>) {
        next if removeComments( \$mlcomm);
        next if removeMacros( \$mlmacro);
        removeStrChar();
        s/[0-9]\.|\.[0-9]|\.\.\.//g;

        next if /^$/;            #prazdne radky
        foreach my $op (@operators) { $opCount++ while s/$op//; }
    }
    return $opCount;
}

#pomocna rutina pro odstraneni komentaru, vse pomoci regexu
#ostraneni == nahrazeni prazdnym retezcem
sub removeComments {
    my $mlc = shift;

	#osetreni pripadu, kdy je znacka pro komentar v retezci
	removeStrChar() if /\".*(\/\/||\/\*||\*\/)/;

    if ($$mlc)                   #handling viceradkoveho komentare
    {
        if (/\*\/(.*)/) {
            $$mlc = 0;
            $_    = $1 . "\n";
        }
        else { return 1; }
    }

    s/(.*?)\/\*.*?\*\//$1/g;     #ostraneni /* */ z jednoho radku
    s/^(.*?)\/\/.*$/$1/;         #odstraneni jenoradkovych komentaru
    $$mlc = 1 if s/^(.*?)\/\*.*$/$1/;    #detekce pocatku viceradkoveho komentare
    return 0;
}

#pomocna rutina pro odstraneni maker, jedno i viceradkovych
sub removeMacros {
    my $mlm = shift;

    if ($$mlm)                           #handling viceradkoveho makra
    {
        $$mlm = 0 if ( !/\\$/ );
        return 1;
    }
    $$mlm = 1 if /^\#.*\\$/;               #detekce viceradkoveho makra
    return 1 if /^\#/;                   #prazdne radky a makra
    return 0;
}

#pomocna rutina pro odstraneni retezcu a znakovych literalu
sub removeStrChar {
    s/\\\\|\\\"|\\\'//g;                 #ostraneni nekterych escape sekvenci

    s/(.*?)\".*?\"/$1/g;                 #odstraneni retezcu
    s/(.*?)\'.*?\'/$1/g;                 #odstraneni znakovych literalu
}

#zpracovani parametru prikazove radky
sub makeParam {                              
    my $key     = 0;
    my $oper    = 0;
    my $ident   = 0;
    my $comment = 0;
    use Getopt::Long;
    Getopt::Long::Configure("no_auto_abbrev");

    my $help = 0;

    if (    #GetOptions pri chybe vraci false
        !GetOptions(
            "help+"    => \$help,
            "input=s"  => \@inputf,
            "output=s" => \@outputf,
            "w=s"      => \@pattern,
            "nosubdir" => \$nosubdir,
            "k+"       => \$key,
            "o+"       => \$oper,
            "i+"       => \$ident,
            "c+"       => \$comment,
            "p+"       => \$noabspath
        )
      )
    {
        exit $retparam;    #chyba pri zpracovani parametru
    }

    if ( $help != 0 ) {

        #kontrola, zda je help jediny parametr
        if (   @inputf
            || @outputf
            || @pattern
            || $key
            || $nosubdir
            || $oper
            || $ident
            || $comment
            || $noabspath
            || @ARGV )
        {
            warn "$0: --help nemuze byt kombinovany s jinymi parametry\n";
            exit $retparam;
        }

        #pokud se help vyskytuje vicekrat
        elsif ( $help > 1 ) {
            warn "$0: --help parametr vice nez jednou", "\n";
            exit $retparam;
        }

        #tisk napovedy
        print STDOUT "$0: \n$helptext\n";
        exit $retok;
    }

    #kontrola jedinecneho vyskytu parametru
    if (   scalar @inputf > 1
        || scalar @outputf > 1
        || scalar @pattern > 1
        || $nosubdir > 1
        || $key > 1
        || $oper > 1
        || $ident > 1
        || $comment > 1
        || $noabspath > 1 )
    {
        warn "$0: vicenasobne zadani parametru je nepovolene\n";
        exit $retparam;
    }

    #prave jeden z techto parametru musi byt zadan
    if ( ( $key + $oper + $ident + $comment + scalar @pattern ) != 1 ) {
        warn "$0: prave jeden z parametru -k -o -i -w -c je pozadovan\n";
        exit $retparam;
    }

    if ( scalar @inputf > 0 && $nosubdir > 0 ) {
        if ( !-d $inputf[0] ) {
            warn "$0: kombinace vstupniho souboru a --nosubdir nepovolena\n";
            exit $retparam;
        }
    }

    #kontrola prebyvajicich argumentu
    if (@ARGV) {
        warn "$0: nezname parametry\n";
        exit $retparam;
    }

    if    ($key)              { $action = "keywords"; }
    elsif ($oper)             { $action = "operators"; }
    elsif ($ident)            { $action = "identifiers"; }
    elsif ($comment)          { $action = "comments"; }
    elsif ( scalar @pattern ) { $action = "pattern"; }
    else                      { $action = "undef" }
}

#otevreni vstupnich a vystupnich souboru
sub io_open {    

    #vstup
    if ( scalar @inputf == 0 ) {
        $dir = ".";    #aktualni adresar, pri nezadanem --input
    }
    elsif ( -f $inputf[0] ) {    #test na plain file
        if ( !open $INFD, '<', $inputf[0] ) {
            warn "$0 : failed to open  input file '$inputf[0]' : $!\n";
            exit $retinput;
        }
    }
    elsif ( -d $inputf[0] ) {    #test na adresar
        $dir = $inputf[0];
    }
    else {                       #pokud to neni ani plain file ani adresar
        warn "$0 : failed to open  input file '$inputf[0]' : $!\n";
        exit $retinput;
    }

    #vystup
    if ( scalar @outputf == 0 ) {
        $OUTFD = *STDOUT;        #standardni vystup, pri nezadanem --output
    }
    else {
        if ( !open $OUTFD, '>', $outputf[0] ) {
            warn "$0 : failed to open  output file '$outputf[0]' : $!\n";
            exit $retoutput;
        }
    }
}

#korektni zavreni vstupniho a vystupniho souboru
sub io_close {
    if ($INFD) {
        close $INFD or warn "$0 : failed to close input file '$inputf[0]' : $!\n";
    }
    if ($OUTFD) {
        close $OUTFD or warn "$0 : failed to close output file '$outputf[0]' : $!\n";
    }
}

#rutina provadejici test na soubor, pokud je uspesny tak ho otevre
sub i_open {
    my $fname = shift;

    if ( -f $fname ) {
        if ( !open $INFD, '<', $fname ) {
            warn "$0 : failed to open  input file '$fname' : $!\n";
            exit $retdirinput;
        }
    }
}

#uzavreni souboru
sub i_close {

    if ($INFD) {
        close $INFD or warn "$0 : failed to close input file: $!\n";
    }
}
