#use strict;
#use warnings;
use common::sense;
use 5.8.8;
use Cwd;
use Cwd 'abs_path';

#TODO navratove kody pri pristupu do slozky

my @keywords = (
    "auto",     "break",    "case",     "char",   "const",   "continue",
    "default",  "do",       "double",   "else",   "enum",    "extern",
    "float",    "for",      "goto",     "if",     "inline",  "int",
    "long",     "register", "restrict", "return", "short",   "signed",
    "sizeof",   "static",   "struct",   "switch", "typedef", "union",
    "unsigned", "void",     "volatile", "while",  "_Bool",   "_Complex",
    "_Imaginary"
);

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

###############################################################################

sub printResults {

    @results = sort { $a->{path} cmp $b->{path} } @results;

    my $total = 0;
    $total += $_->{result} foreach @results;

    my $longestPath = 0;
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

sub spacePad {
    my $count = shift;
    return " " x $count;
}

sub doAction {

    use Switch;
    my $res = 0;

    switch ($action) {
        case "keywords"    { $res = countKeywords() }
        case "operators"   { $res = countOperators() }
        case "identifiers" { $res = countIdentifiers() }
        case "comments"    { $res = countComments() }
        case "pattern"     { $res = countPattern( $pattern[0] ) }
        case "undef"       { print "UNDEF\n" }
    }
    return $res;
}

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

    if ( $level-- ) {
        chdir ".." or die "Nelze se vynorit z adresare: $!\n";
    }
}

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

sub countPattern {
    my $pattern      = quotemeta shift;
    my $patternCount = 0;

    while (<$INFD>) {
        $patternCount++ while s/$pattern//;

        #print $_;
    }
    return $patternCount;
}

sub countIdentifiers {
    my $mlmacro    = 0;
    my $mlcomm     = 0;
    my $identCount = 0;

    while (<$INFD>) {
        next if removeComments( \$mlcomm, $_ );
        next if removeMacros( \$mlmacro, $_ );
        removeStrChar($_);
        foreach my $word (@keywords) {
            s/\b$word\b//g;
        }
        next if /^$/;    #prazdne radky

        $identCount++ while s/(\b[_a-zA-Z][_a-zA-Z0-9]*\b)//;

        #print "$1\n" while s/(\b[_a-zA-Z][_a-zA-Z0-9]*\b)//;
    }
    return $identCount;
}

sub countKeywords {

    my $mlmacro   = 0;
    my $mlcomm    = 0;
    my $wordCount = 0;

    while (<$INFD>) {
        next if removeComments( \$mlcomm, $_ );
        next if removeMacros( \$mlmacro, $_ );
        removeStrChar($_);
        next if /^$/;    #prazdne radky

        #print $_;
        foreach my $word (@keywords) {
            $wordCount++ while s/\b$word\b//;
        }
    }
    return $wordCount;
}

sub countOperators {

    my $mlmacro = 0;
    my $mlcomm  = 0;
    my $opCount = 0;

    #TODO na * a & pozor! v soucasti deklarace funkci to pry neni operator!!!
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
        next if removeComments( \$mlcomm, $_ );
        next if removeMacros( \$mlmacro, $_ );
        removeStrChar($_);
        s/[0-9]\.|\.[0-9]//g;    #TODO tohle jeste odladit

        next if /^$/;            #prazdne radky
        foreach my $op (@operators) { $opCount++ while s/$op//; }

        #foreach my $op (@operators) { print "$1\n" while s/($op)//; }
    }
    return $opCount;
}

sub removeComments {
    my $mlc = shift;
    $_ = shift;

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

sub removeMacros {
    my $mlm = shift;
    $_ = shift;

    if ($$mlm)                           #handling viceradkoveho makra
    {
        $$mlm = 0 if ( !/\\/ );
        return 1;
    }
    $$mlm = 1 if /\#.*\\/;               #detekce viceradkoveho makra
    return 1 if /^\#/;                   #prazdne radky a makra
    return 0;
}

sub removeStrChar {
    $_ = shift;

    s/(.*?)\".*?\"/$1/g;                 #odstraneni retezcu
    s/(.*?)\'.*?\'/$1/g;                 #odstraneni znakovych literalu
}

sub makeParam {                          #zpracovani parametru prikazove radky
    my $key     = 0;
    my $oper    = 0;
    my $ident   = 0;
    my $comment = 0;
    use Getopt::Long;
    Getopt::Long::Configure("no_auto_abbrev");

    #Getopt::Long::Configure( "no_auto_abbrev", "bundling" );
    #TODO zkusit to premluvit, aby to POZADOVALO = pri parametrech prepinacu

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

sub io_open {    #otevreni vstupne vystupnich souboru, pokud je to treba

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

sub io_close {
    if ($INFD) {
        close $INFD or warn "$0 : failed to close input file '$inputf[0]' : $!\n";
    }
    if ($OUTFD) {
        close $OUTFD or warn "$0 : failed to close output file '$outputf[0]' : $!\n";
    }
}

sub i_open {
    my $fname = shift;

    if ( -f $fname ) {
        if ( !open $INFD, '<', $fname ) {
            warn "$0 : failed to open  input file '$fname' : $!\n";
            exit $retdirinput;
        }
    }
}

sub i_close {

    if ($INFD) {
        close $INFD or warn "$0 : failed to close input file: $!\n";
    }
}
