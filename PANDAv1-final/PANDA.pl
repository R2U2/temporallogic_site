#!/usr/bin/perl
#
#by Kristin Y. Rozier
#released: 06/20/2011
#
#There are 3 possible types of test formulas:
#(All benchmark formulas are from the paper "LTL Satisfiability Checking" by Rozier and Vardi.)
# 1) Random formulas: The program generates a test set of LTL formulas using the methods based on those described in "Improved automata generation for linear temporal logic" by Daniele, Guinchiglia, and Vardi. The formulas are first generated in SPIN syntax and then in other, tool-specific syntaxes.
# 2) Counter formulas: c, cl, cc, ccl
# 3) Scaleable pattern formulas: E U R U2 C1 C2 Q S R2
#
#The data files are created by:
# - recording the time spent generating the symbolic automaton
# - running some SMV (or SAL: untested code) with the symbolic automaton to determine the processing time
# - checking the output to determine satisfiable or not
#
# Supported LTL Symbolic Model Checking tools:
# - NuSMV
# - Cadence SMV
# - SALsmc
# - PANDA (Portfolio Approach to Navigate the Design of Automata) which uses NuSMV, CadenceSMV, and SAL as back-ends
# - ltl2smv (distributed with NuSMV)
#
# Inputs: parameter file required
#      example: PANDA.pl -r parameter_file
#      where -r stands for restart and the parameter_file contains some reasonable combination of the lines as follows:
#      
#      Random formulas:
#         P = $P  //probability of chosing a temporal operator
#         N = $n  //number of propositional variables
#         L = $L  //length of the formula (propositions + operators)
#         F = $F  //number of formulas in set
# OR
#      Counter formulas:
#         N = $counterN        //number of propositions: 2 for c, cl; 3 for cc, ccl
#         counter = $class     //class in {c cl cc ccl}
#         run number = $letter //run number allows labeling multiple runs of the same formula
# OR
#      Pattern formulas:
#         N = $scaleableN      //number of propositions: >= 2 for U, R, U2, R2, Q patterns; >= 1 for all others
#         pattern = $class     //class in {E U R U2 C1 C2 Q S R2}
#         run number = $letter //run number allows labeling multiple runs of the same formula
# AND
#      All formulas:
#         stools = __  //options: {NuSMV CadenceSMV SALsmc}
#       OR
#         mytools = __ //Basically, this just specifies a front-end now from {PANDA, ltl2smv}
#       AND
#         flags = __   //Must accompany a mytools command; supplies all flags. See PANDA and ltl2smv documentation for available flags
#      All formulas:
#         start = __   //what formula to start on? >=1 for random; >= 0 for counter/pattern
# OR
#      --help will produce a usage message
#
# Outputs: (INCOMPLETE: FIX)
#
# Usage: PANDA.pl -r parameter_file
#
################################
# Example input parameter files
################################
#
# Running CadenceSMV on Random formulas:
# P = 0.5
# N = 1
# L = 5
# F = 500
# stools = CadenceSMV
# start = 0
#
# Running PANDA on Random formulas:
# P = 0.5
# N = 1
# L = 5
# F = 500
# flags =  -c -nnf -sloppy -tgba   -lexp
# mytools = PANDA
# start = 0
#
# Running CadenceSMV on Counter formulas: 
# N = 3
# counter = ccl
# run number = 01
# stools = CadenceSMV
# start = 1
#
# Running PANDA on Counter formulas: 
# N = 3
# counter = ccl
# run number = 01
# flags =  -c -nnf -sloppy -tgba   -lexp
# mytools = PANDA
# start = 1
#
# Running CadenceSMV on Pattern formulas:
# N = 2
# pattern = U2
# run number = 01
# stools = CadenceSMV
# start = 2
#
# Running PANDA on U2 Pattern formulas:
# N = 2
# pattern = U2
# run number = 01
# flags =  -c -nnf -sloppy -tgba -lexp
# mytools = PANDA
# start = 2


use FileHandle;      #for open() 
use Benchmark;       #for timethis()


#For the sug@r cluster: make sure we start in the correct directory
$pwd = `pwd`; #save the running path for use with input files
chomp($pwd); $pwd = "$pwd/"; #clean up running path
$path = "/users/kyrozier/research/";
chdir "$path";
$mydir = "";
$mypath = "${path}${mydir}/";
$data_dir = "data";
$SHARED_SCRATCH = $ENV{SHARED_SCRATCH}; #get $SHARED_SCRATCH environment variable
$output_path = "$SHARED_SCRATCH/kyrozier/";    #path for overflow output
$data_path = "${output_path}${data_dir}/";  #$data_path on $SHARED_SCRATCH for bigger files
$NuSMV_command = "/users/kyrozier/local/NuSMV-zchaff-2.4.3-x86_64-linux-gnu/bin/NuSMV"; #sug@r
$uname = `uname -a`; #check location for location-sensitive code


#################### Argument Setup #################### 

#Check for correct number and type of command line arguments
if (($ARGV[0] =~ /--help/) || #(@ARGV != 2)) {
    ( (!((@ARGV == 3) && (($ARGV[0] =~ /^r$/) || ($ARGV[0] =~ /^c$/) || ($ARGV[0] =~ /^p$/))))
      )  ) {
    die "Usage: PANDA.pl formula_type -r parameter_file
\twhere 
\t  formula type is r (random) c (counter) p (pattern).
\t  and the restart_parameter_file contains some reasonable combination of the lines:\nP = __\nN = __\nL = __\nF = __\nstools = __\nmytools = __\nflags = __\ncounter = __\npattern = __\n\nrun number =__\nstart = __\n\n";
} #end if

$formula_type = $ARGV[0];      #save the formula type (r, c, or p)

if ($ARGV[1] =~ /^-r$/) { #Check for Restart Mode
    $restart = 1; #we are doing a restart, not a normal run
    $restart_file = $ARGV[2];
    $rank = 0;
    $num_instances = 2;
} #end if
else { #No other running mode for now
    die "Usage: PANDA.pl formula_type -r parameter_file\n";
} #end else

if ($formula_type eq "r") { #random formulas
    $F = 500; #number of formulas to generate in one test set
    $LMAX = 65; #start here for now
} #end if
elsif ($formula_type eq "c") { #counter formulas
    $counter_formula = 1; #do counter formulas instead of random ones
    @counter_class = qw(c cl cc ccl);
    $run_number = "01"; #for multiple runs, change the run number to avoid overwriting
    $scalemax = 20; #don't run counters past 20 bits/patterns past 20 iterations
} #end if
elsif ($formula_type eq "p") { #scaleable pattern formulas
    $scaleable_formula = 1; #do scaleable pattern formulas instead of random ones
    @scaleable_class = qw(E U R U2 C1 C2 Q S R2);
    $scaleable_class = $scaleable_class[0]; #Which class of scaleable formulas do we do?
    $scaleableN = 1; #N-value to use to start these scaleable formulas
    if (($scaleable_class eq "U")
	|| ($scaleable_class eq "R")
	|| ($scaleable_class eq "U2")
	|| ($scaleable_class eq "R2")
	|| ($scaleable_class eq "Q")) {
	$scaleableN = 2;
    } #end if
    $run_number = "01"; #for multiple runs, change the run number to avoid overwriting
    
    $scalemax = 1000000000; #don't run past a million variables :)
} #end elsif


#################### Generation of Formulas ####################

### Set up the generation variables

@N = qw(a b c); #array of variables

@stools = qw();
@mytools = qw();

$PANDAflag = "-c"; #Use CadenceSMV
#$PANDAflag = "-n"; #Use NuSMV
#$PANDAflag = "-s"; #Use SALsmc

$NuSMVflag = ""; #default: no special flags sent to NuSMV
$CadenceSMVflag = ""; #default: no special flags sent to CadenceSMV
$printReachableStates = 0; #default: don't calculate the number of reachable states for SMV
$modelFlags = ""; #default: don't change the standard SMV models

$varOrder = 0; #Use a specified variable ordering
$titleString = "";

@operators = qw(! X && || U V); #array of operators: 
#order is very important here: unary then binary then temporal:
#not, next time, and, or, (strong) until, and V = not(not u1 U not u2)

#################### Set Restart Variables ####################

#Empty variables possibly set by reset file
$restartF = -1;
$restartP = -1;
$restartN = -1;
$restartL = -1;
$restartFlags = ""; #default is to feed no flags to the tools
$restartStart = -1;
if ($restart == 1) {
    @stools = qw();
    @mytools = qw();
    
    #Open the restart parameters file
    open(RESTART, "<${path}${restart_file}") or die "Could not open ${path}${restart_file}: $!";
    
    while (<RESTART>) {
	$line = $_; #save the current line
	
	if ($line =~ /^\s*F\s*=\s*(\d+)\s*$/) {
	    #check for the correct value range
	    if (($1 < 1) || ($1 > 500)) {
		die "ERROR: restart F-value of $1 is outside acceptable range of 1..500\n";
	    } #end if
	    $restartF = $1;
	    print "Setting F = $restartF...\n";
	    $F = $restartF; #Maybe there's a better place for this
	} #end if
	elsif ($line =~ /^\s*P\s*=\s*([\d\.]+)\s*$/) {
	    #check for the correct value range
	    if (($1 != 0.5) && ($1 != 1/3) && ($1 != 0.7) && ($1 != 0.95)) {
		die "ERROR: restart P-value of $1 is outside acceptable value set of {1/3, 0.5, 0.7, 0.95}\n";
	    } #end if
	    $restartP = $1;
	    print "Setting P = $restartP...\n";
	} #end elsif
	elsif ($line =~ /^\s*N\s*=\s*(\d+)\s*$/) {
	    #check for the correct value range
	    if (($1 < 1) || (($1 > 3) && ($formula_type ne "p"))) {
		die "ERROR: restart N-value of $1 is outside acceptable range of 1..3\n";
	    } #end if
	    $restartN = $1;
	    print STDERR "Setting N = $restartN...\n";
	} #end elsif
	elsif ($line =~ /^\s*L\s*=\s*(\d+)\s*$/) {
	    #check for the correct value range
	    if ($1 < 5) {
		die "ERROR: restart L-value of $1 is outside acceptable range of 5+\n";
	    } #end if
	    $restartL = $1;
	    print "Setting L = $restartL...\n";
	} #end elsif
	elsif ($line =~ /^\s*start\s*=\s*(\d+)\s*$/) {
	    #check for the correct value range
	    if (($1 < 0) || (($1 > 499) && ($formula_type ne "p"))) {
		die "ERROR: restart start-value of $1 is outside acceptable range of 0..499\n";
	    } #end if
	    $restartStart = $1;
	    print "Setting start = $restartStart...\n";
	    if ($formula_type eq "c") {
		$F = $restartStart; #for counter formulas
		$restartF = $restartStart; #for counter formulas
	    } #end if
	} #end elsif
	elsif ($line =~ /^\s*stools\s*=\s*([\w\s]*)\s*$/) {
	    $_ = $1;
	    @stools = split();
	    print "Running stools: @stools\n";
	    $LMAX = 200; #FIX: check this line (in r but not in c)
	} #end elsif
	elsif ($line =~ /^\s*mytools\s*=\s*([-\w\s]*)\s*$/) {
	    $_ = $1;
	    #These will contain flags, so parse carefully...
	    s/\s+P/ ,/g; #put a , before each new 'PANDA'

	    @mytools = split(/,/); #split on the newly-inserted ,'s
	    foreach $tool (@mytools) {
		$tool =~ s/,//g; #get rid of any ,'s
	    } #end foreach
	    
	    print "Running mytools: @mytools\n";
	    $LMAX = 200; #FIX: check this line (in r but not in c)
	} #end elsif
	elsif ($line =~ /^\s*flags\s*=\s*(.+)\s*$/) {
	    #Warning: These flags will be fed to *all* restarted tools!
	    $restartFlags .= $1;
	    print "Setting flags = $restartFlags...\n";
	} #end elsif
	elsif ($line =~ /^\s*counter\s*=\s*(\w+)\s*$/) { #for counter formulas
	    $counter_formula = 1;
	    $counter_class = $1; #Warning: this only allows ONE class
	    if ($F == 0) {$F = 1;} #counters start at 1
	    print "Running counter class $counter_class\n";
	} #end elsif
	elsif ($line =~ /^\s*pattern\s*=\s*(\w+)\s*$/) { #for pattern formulas
	    $scaleable_formula = 1;
	    $scaleable_class = $1; #Warning: this only allows ONE class
	    print "Running scaleable pattern class $scaleable_class\n";
	} #end elsif
	elsif ($line =~ /^\s*run\s*number\s*=\s*(\w+)\s*$/) { #for counter + pattern formulas
	    $run_number = "$1";
	} #end elsif
	#DEFAULT:
	elsif ($line !~ /^\s*$/) { #if line is not blank
	    die "ERROR: invalid line in restart file:\n$line";
	} #end elsif
    } #end while
    
    close(RESTART) or die "Could not close ${path}${restart_file}: $!";

    $F = $restartF;
    $start = $restartStart;
    if ($formula_type eq "p") {
	#A little (scaleable) error checking
	if ($scaleable_formula == 1) {
	    if (($restartN <= 0) && ($restartF <= 0)) {
		die "ERROR: Scaleable formulas cannot start below 1\n";
	    } #end if
	    
	    #Allow only one of N or F to be set, since they're the same here
	    if ($restartF > $restartN) {$restartN = $restartF;}
	    if ($restartN > $restartF) {$restartF = $restartN;}
	    
	    $scaleableN = $restartN;
	    
	    if (($scaleable_class eq "U")
		|| ($scaleable_class eq "R")
		|| ($scaleable_class eq "U2")
		|| ($scaleable_class eq "R2")
		|| ($scaleable_class eq "Q")) {
		if ($scaleableN < 2) {
		    die "ERROR: Scaleable class $scaleable_class must have at least N=2!\n";
		} #end if
	    } #end if
	    elsif (($scaleable_class eq "E")
		   || ($scaleable_class eq "C1")
		   || ($scaleable_class eq "C2")
		   || ($scaleable_class eq "S")) {
		if ($scaleableN < 1) {
		    die "ERROR: Scaleable class $scaleable_class must have at least N=1!\n";
		} #end if
	    } #end if
	    else {
		die "ERROR: invalid scaleable formula class $scaleable_class not in \{E U R U2 C1 C2 Q S R2\}\n";
	    } #end else
	} #end if
    } #end if 'p'

} #end if

if (@mytools == 1) { #if we're dealing with a mytool, take the flags
    $mytools[0] =~ /^\s*(\w[^\s]+)\s*(.*)$/;
    $restartFlags .= $2;
    $mytools[0] = $1; #save mytool name w/out flags
} #end if

#Set PANDA titleString
$newFlags = "";
if ($restartFlags !~ /^\s*$/) {
    $_ = $restartFlags;
    @restartFlags = split();
    if ($restart == 1) {
	$PANDAflag = ""; #default
	$NuSMVflag = ""; #default
    } #end if
    foreach $flag (@restartFlags) {
	if ($flag eq "-a") {
	    $titleString .= " Automatic Encoding";
	    $newFlags .= "-a ";
	} #end if
	elsif ($flag eq "-c") {
	    if ($restart == 1) {
		$PANDAflag = "-c"; #Using CadenceSMV
		$newFlags .= "-c ";
	    } #end if
	} #end if
	elsif ($flag eq "-n") {
	    if ($restart == 1) {
		$PANDAflag = "-n"; #Using NuSMV
		$newFlags .= "-n ";
	    } #end if
	} #end if
	elsif ($flag eq "-s") {
	    if ($restart == 1) {
		$PANDAflag = "-s"; #Using SALsmc
		$newFlags .= "-s ";
	    } #end if
	} #end if	
	elsif ($flag eq "-reachable_states") {
	    $printReachableStates = 1;
	} #end if
	elsif ($flag eq "-fussy") {
	    $titleString .= " Fussy Encoding";
	    $newFlags .= "-fussy ";
	} #end if
	elsif ($flag eq "-sloppy") {
	    $titleString .= " Sloppy Encoding";
	    $newFlags .= "-sloppy ";
	} #end if
	elsif ($flag eq "-nnf") {
	    $titleString .= " NNF";
	    $newFlags .= "-nnf ";
	} #end if
	elsif ($flag eq "-bnf") {
	    $titleString .= " BNF";
	    $newFlags .= "-bnf ";
	} #end if
	elsif ($flag eq "-gba") {
	    $titleString .= " GBA";
	    $newFlags .= "-gba ";
	} #end if
	elsif ($flag eq "-tgba") {
	    $titleString .= " TGBA";
	    $newFlags .= "-tgba ";
	} #end if
	elsif ($flag eq "-mcs") {
	    $titleString .= " MCS Variable Order";
	    $newFlags .= "-mcs ";
	    $varOrder = 1; #Using a variable order
	} #end if
	elsif ($flag eq "-lexm") {
	    $titleString .= " LEXM Variable Order";
	    $newFlags .= "-lexm ";
	    $varOrder = 1; #Using a variable order
	} #end if
	elsif ($flag eq "-lexp") {
	    $titleString .= " LEXP Variable Order";
	    $newFlags .= "-lexp ";
	    $varOrder = 1; #Using a variable order
	} #end if
	elsif ($flag eq "-linear") {
	    $titleString .= " Linear Variable Order";
	    $newFlags .= "-linear ";
	    $varOrder = 1; #Using a variable order
	} #end if
	elsif ($flag eq "-max") {
	    $titleString .= " MCS Starting at Max";
	    $newFlags .= "-max ";
	} #end if
	elsif ($flag eq "-min") {
	    $titleString .= " MCS Starting at Min";
	    $newFlags .= "-min ";
	} #end if
	elsif ($flag eq "-zero") {
	    $titleString .= " MCS Starting at Zero";
	    $newFlags .= "-zero ";
	} #end if
	elsif ($flag eq "-random") {
	    $titleString .= " MCS Starting at Random";
	    $newFlags .= "-random ";
	} #end if
	elsif ($flag eq "-reverse") {
	    $titleString .= " Reverse Variable Order";
	    $newFlags .= "-reverse ";
	    #print STDERR "Reverse Variable Order";
	} #end if
	elsif ($flag eq "-noinit") {
	    $titleString .= " without INIT statement";
	    $modelFlags .= "-noinit"; #flag for the SMV model, not for the call
	} #end if
	elsif ($flag eq "-flt") {
	    $titleString .= " with ltl_tableau_forward_search";
	    $NuSMVflag .= "-flt"; #Using NuSMV
	} #end if
	elsif ($flag eq "-df") {
	    $titleString .= " without reachable state computation";
	    $NuSMVflag .= "-df"; #Using NuSMV
	} #end elsif
	elsif ($flag eq "-mono") {
	    $titleString .= " with monolithic";
	    $NuSMVflag .= "-mono"; #Using NuSMV
	} #end elsif
    } #end foreach
} #end if
$restartFlags = $newFlags;


#Set ltl2smv stuff
if ($mytools[0] =~ /ltl2smv(.*)$/) {
    $newFlags = "";
    $restartFlags .= $1; #add any PANDA flags to restartFlags
    $_ = $restartFlags;
    @restartFlags = split();
    if ($restart == 1) {
	$PANDAflag = ""; #default
	$NuSMVflag = ""; #default
    } #end if
    foreach $flag (@restartFlags) {
	if ($flag eq "-c") {
	    $PANDAflag = "-c"; #Using CadenceSMV
	    $newFlags .= "-c ";
	} #end if
	elsif ($flag eq "-n") {
	    $PANDAflag = "-n"; #Using NuSMV
	    $newFlags .= "-n ";
	} #end if
	elsif ($flag eq "-s") {
	    $PANDAflag = "-s"; #Using SALsmc
	    $newFlags .= "-s ";
	} #end if	
    } #end foreach
} #end if

#A little flag error checking...
if (($modelFlags =~ /-bnf/) && ($modelFlags =~ /-sloppy/)) {
    die "ERROR: sloppy encoding cannot be used with bnf formulas\n";
} #end if


if ($formula_type eq "c") {
    #Set the formula command and title string based on the type of counter we're using
    if ($counter_class eq "c") {
	$title_string = "2-variable Counter Formulas";
	$formula_command = "LTLcounter.pl";
    } #end if
    elsif ($counter_class eq "cl") {
	$title_string = "2-variable Linear Counter Formulas";
	$formula_command = "LTLcounterLinear.pl";
    } #end if
    elsif ($counter_class eq "cc") {
	$title_string = "3-variable Counter Formulas";
	$formula_command = "LTLcounterCarry.pl";
    } #end if
    elsif ($counter_class eq "ccl") {
	$title_string = "3-variable Linear Counter Formulas";
	$formula_command = "LTLcounterCarryLinear.pl";
    } #end if
    else {
	die "Unrecognized counter formula type: $counter_class\nExpecting one of \{c cl cc ccl\}\n";
    } #end else

     if (! (-x "${path}${formula_command}") ) {
	die "Can't find ${path}${formula_command}\n";
    } #end if
} #end if


#################### Formula Setup ####################

if ($formula_type eq "r") {
    #Set the directory where all of the formulas will be stored

    if ((@stools == 1) #assume we can only have one tool
	&& ($stools[0] =~ /CadenceSMV/)) { #WARNING!!! This breaks for multiple tools!!!
	$formula_dir = "${path}formulasNoR";
    } #end if
    else {
	$formula_dir = "${path}formulas";
    } #end else
    
    #If the data directory doesn't exist, create it
    if (! (-d $formula_dir) ) {
	die "Can't find ${path}formulas\n";
	$error = `${path}generateRandomFormulas.pl`; #generate formulas for this directiory 
	
	#if the directory still doesn't exist; die
	if (! (-d $formula_dir) ) {
	    die "Cannot mkdir $formula_dir using ${path}generateRandomFormulas.pl: $error\n";
	} #end if
    } #end if
    elsif (! (-r $formula_dir) ) { #check for read permission
	die "ERROR: formula directory $formula_dir is not readable!";
    } #end elseif
} #end if 'r'
elsif ($formula_type eq "c") {
    #None needed -- we generate counter formulas here
} #end elsif 'c'
elsif ($formula_type eq "p") {
    #None needed -- we generate scaleable formulas here
} #end elsif 'p;
else { #error checking
    die "ERROR: invalid formula type \"$formula_type\" -- choose either r, c, or p.";
} #end else


#################### My Directory Setup ####################

#Take precautions to enable mutex of tools
if ($num_instances > 1) {
    #get the machine we're running on
    $where = `hostname`; #get the machine name
    chomp($where);

    #unique id is the machine plus the process ID
    $unique_id = "${where}_$$";
    #print STDERR "I am running here: ${where}\nand my unique id is: ${unique_id}\n"; #debug
    $mydir = "run${unique_id}";
    $temp = "temp${unique_id}";

    #If the run directory exists, complain
    if (-d "${output_path}${mydir}")  {
	die "ERROR: \"unique\" directory $mydir already exists!!!\n";
    } #end if
    else {
	mkdir("${output_path}${mydir}", 0755) or die "Cannot mkdir ${output_path}${mydir}: $!";
    } #end if
    $mypath = "${output_path}${mydir}/";  #sug@r $SHARED_SCRATCH path   
    chdir "$mypath";
} #end if
else {
    $rank = 0;
    $unique_id = "";
    $mydir = "";
    $mypath = $output_path;  #sug@r $SHARED_SCRATCH path   
    chdir "$mypath";         #sug@r $SHARED_SCRATCH path
} #end else


#################### Data Directory Setup ####################

#Set the directory where all of the data will be stored
$data_path = "${mypath}${data_dir}/";

#If the data directory doesn't exist, create it
if (! (-d $data_path) ) {
    mkdir("$data_path", 0755) or die "Cannot mkdir $data_path: $!";
} #end if
elsif (! (-w $data_path) ) { #check for write permission
    die "ERROR: data directory $data_path is not writable!";
} #end elseif


#################### Create the Master Data Output File  ####################

$outfile = "${data_path}benchmark${rank}.out";
if (-e $outfile) {
    @now = localtime;
    $now[4] += 1;   #fix the month (numbered 0..11)
    $now[5] -= 100; #fix the year (add a 0 below)
    `mv "$outfile" "${outfile}.replaced$now[4]-$now[3]-0$now[5].$now[2].$now[1]"`;
} #end if
open(OUT, ">$outfile") or die "Could not open $outfile";


##################################################################
#
# Functions: 
# 
# NuSMV
# CadenceSMV
# SALsmc
# PANDA
# ltl2smv
# run_tools: Run each tool on each of the formulas generated
#                      from the given parameters
#
# The run_tools function runs the selected tool function (except PANDA) on a series of formulas until time-out in order to gather data to compare to PANDA. The PANDA function is run only once and then terminates. This is because the PBS parallel run script is checking for the termination of the first successful run of a given formula by a PANDA encoding in order to terminate all other PANDA jobs.
##################################################################


#NuSMV
#To run: NuSMV program.smv
#   output: 
#Notes:
# - requires different formula syntax:
#     &&    &
#     ||    |
#     a     a=1
#     b     b=1
#     c     c=1
sub NuSMV {

    my $formula = $_[0];
    my $n = $_[1];

    #Modify the formula syntax:
    $formula =~ s/&&/&/g;      #AND is &
    $formula =~ s/\|\|/\|/g;   #OR  is |
    $formula =~ s/R/V/g;       #R is V
    $formula =~ s/a/a=1/g;
    $formula =~ s/b/b=1/g;
    $formula =~ s/c/c=1/g;
    $formula =~ s/(p\d+)/${1}=1/g;

    $thisfile = "NuSMVTEC";
    print OUT "NuSMV\t";

    ### Generate the model ###
    $time_cmd = `which time`; #capture the time cmd; override bash default
    chomp($time_cmd);

    #create a file to input the LTL model:
    $tempModel = "${temp}.smv";
    open(MFILE, ">$tempModel") or die "Could not open $tempModel: $!";
    print MFILE "MODULE main\n";
    print MFILE "  VAR\n";
    for ($i = 0; $i < $n; $i++) {
	if ($scaleable_formula == 0) { #random and counter formulas
	    print MFILE "    $N[$i] : boolean;\n";
	} #end if
	else { #pattern formulas
	    $iplus1 = $i + 1;
	    print MFILE "    p${iplus1} : boolean;\n";
	} #end else
    } #end for
    print MFILE "  LTLSPEC !($formula)\n";
    print MFILE "  FAIRNESS\n";
    print MFILE "    1\n";
    close(MFILE) or die "Could not close $tempModel: $!";
     
    if ($varOrder == 1) {
	if ($printReachableStates == 1) {
	    $analysis = `$time_cmd -f \"\%U\" $NuSMV_command $NuSMVflag -r -i tableau.var $tempModel 2>&1`;
	} #end if
	else {
	    $analysis = `$time_cmd -f \"\%U\" $NuSMV_command $NuSMVflag -i tableau.var $tempModel 2>&1`;
	} #end else
    } #end if
    else {
	if ($printReachableStates == 1) {
	    $analysis = `$time_cmd -f \"\%U\" $NuSMV_command $NuSMVflag -r $tempModel 2>&1`;
	} #end if
	else {
	    $analysis = `$time_cmd -f \"\%U\" $NuSMV_command $NuSMVflag $tempModel 2>&1`;
	} #end else
    } #end else

    #Quick check for warnings:
    if ($uname =~ /sugar.rice.edu/) { #Sug@r includes 9 WARNINGS for ZCHAFF
	$warning_count = ($analysis =~ s/WARNING/WARNING/g);
	if ($warning_count > 9) {
	    $warning = 1;
	} #end if
    } #end if
    elsif ($analysis =~ /WARNING/) { #for non-Sug@r machines
	$warning = 1;
    } #end if

    chomp($analysis);
    @analysis = split/^/, $analysis; #split into lines 
    $time_info = $analysis[$#analysis]; #get the last line of output, which is the timing info
    print $thisfile "$time_info\t";
    print OUT "$time_info\t";

    ### Parse output looking for satisfiability
    foreach $line (@analysis) {
	if ($line =~ /^.*specification\s*.*is\s+([\S]+)\s+.*$/) {
	    $analysis = $1; #get "true" or "false"
	    if ($printReachableStates == 0) {last;}
	    else {next;}
	} #end if
	if ($line =~ /reachable states:\s*([\d\.e\+]+).* out of ([\d\.e\+]+).+$/) {
	    print $thisfile "$1\t$2\t";
	    last; #reachable states comes after specification truth
	} #end if
    } #end foreach

    #record claim validity
    print "NuSMV: ";
    if ($analysis =~ /false/) {

	#the violation means satisfiable
	if ($warning) { print $thisfile "1W\n"; $warning = 0; }
	else { print $thisfile "1\n"; }
	print OUT "satisfiable\n";
	return 1;
    } #end if
    elsif ($analysis =~ /true/) {
	if ($warning) { print $thisfile "0W\n"; $warning = 0; }
	    else { print $thisfile "0\n"; }
	print OUT "NOT_satisfiable\n";
	return 0;
    } #end elsif
    else {
	print "ERROR: No readable output from NuSMV\n";
	print $thisfile "ERROR\n";
	print OUT "ERROR: No readable output from NuSMV\n";

	$cattemp = `cat $tempModel`;
	print OUT "TEMP.SMV:\n$cattemp";

	if ($counter_formula == 1) {die;} #don't continue scaling past errors
	if ($scaleable_formula == 1) {die;} #don't continue scaling past errors

	return -1;
    } #end else
} #end NuSMV


#CadenceSMV
#To run:  program.smv
#   output: 
#Notes:
# - requires different formula syntax:
#     !     ~     (not)
#     &&    &
#     ||    |
sub CadenceSMV {

    my $formula = $_[0];
    my $n = $_[1];

    #Modify the formula syntax:
    $formula =~ s/!/~/g;       #NOT is ~
    $formula =~ s/&&/&/g;      #AND is &
    $formula =~ s/\|\|/\|/g;   #OR  is |

    $thisfile = "CadenceSMVTEC";
    print OUT "Cadence SMV\t";

    ### Generate the model ###
    $time_cmd = `which time`; #capture the time cmd; override bash default
    chomp($time_cmd);

    #create a file to input the LTL model:
    $tempModel = "${temp}.smv";
    open(MFILE, ">$tempModel") or die "Could not open $tempModel: $!";
    print MFILE "module main () {\n";
    for ($i = 0; $i < $n; $i++) {
	if ($scaleable_formula == 0) {
	    print MFILE "    $N[$i] : boolean;\n";
	} #end if
	else {
	    $iplus1 = $i + 1;
	    print MFILE "    p${iplus1} : boolean;\n";
	} #end else
    } #end for
    print MFILE "  assert ~($formula);\n";
    print MFILE "  FAIRNESS    TRUE;\n";
    print MFILE "}\n";
    close(MFILE) or die "Could not close $tempModel: $!";
     
    $analysis = `$time_cmd -f \"\%U\" smv -force -v 0 $tempModel 2>&1`;
    chomp($analysis);
    @analysis = split/^/, $analysis; #split into lines 
    $time_info = $analysis[$#analysis]; #get the last line of output, which is the timing info
    print $thisfile "$time_info\t";
    print OUT "$time_info\t";


    ### Parse output looking for satisfiability
    if ($analysis =~ /false/) {
	#print "satisfiable\n";
	print $thisfile "1\n";
	print OUT "satisfiable\n";
	return 1;
    } #end if
    elsif ($analysis =~ /true/) {
	print $thisfile "0\n";
	print OUT "NOT_satisfiable\n";
	return 0;
    } #end elsif
    else {
	print $thisfile "ERROR\n";
	print OUT "ERROR: No readable output from Cadence SMV\n";
	print OUT "ANALYSIS: \"$analysis\"\n";

	$cattemp = `cat $tempModel`;
	print OUT "TEMP.SMV:\n$cattemp";

	if ($counter_formula) {die;} #don't continue scaling past errors
	if ($scaleable_formula) {die;} #don't continue scaling past errors

	return -1;
    } #end else

} #end CadenceSMV


#SALsmc
#To run:  program.smv
#   output: 
#Notes:
# - requires different formula syntax:
#     !     NOT
#     &&    AND
#     ||    OR
#     ->    =>
#SAL uses a generic file named "temp.sal" instead of unique filenames
#  because the context name and file name must match.
sub SALsmc {

    my $formula = $_[0];
    my $n = $_[1];

    #Modify the formula syntax:
    if (($formula_type eq "p")
	&& ($scaleable_class eq "U")) {$formula = `${path}UformulaSAL.pl $n`;}
    elsif ($formula_type eq "c") {
	if ($counter_class eq "c") {
	    $formula = `${path}LTLcounterSAL.pl $f`;
	} #end if
	elsif ($counter_class eq "cl") {
	    $formula = `${path}LTLcounterLinearSAL.pl $f`;
	} #end if
    } #end elsif
    chomp($formula); #remove the trailing '\n'
    $formula = "($formula)"; #add extra outer parens, just to be through
    $formula =~ s/\s*!\s*/ NOT /g;     #NOT is NOT
    $formula =~ s/\s*&&\s*/ AND /g;    #AND is AND
    $formula =~ s/\s*\|\|\s*/ OR /g;   #OR  is OR
    $formula =~ s/->/=>/g;             #IMPLIES is =>

    #SAL-SMC won't allow numbers in variable names
    @alphabet = qw(0 a b c d e f g h i j k l m n o p q r s t u v w x y z);
    $formula =~ s/p(\d+)/$alphabet[$1]/g;

    $thisfile = "SALsmcTEC";
    print OUT "SAL-SMC\t";

    ### Generate the model ###
    $time_cmd = `which time`; #capture the time cmd; override bash default
    chomp($time_cmd);

    #create a file to input the LTL model:
    $tempModel = "temp.sal"; #Important: do not change this! It must match the context name.
    open(MFILE, ">$tempModel") or die "Could not open $tempModel: $!";
    print MFILE "temp: CONTEXT =\nBEGIN\n\n";
    print MFILE "   main: MODULE =\n   BEGIN\n";
    print MFILE "     OUTPUT\n";
    for ($i = 0; $i < $n - 1; $i++) {
	if ($scaleable_formula == 0) {
	    print MFILE "       $N[$i] : boolean,\n";
	} #end if
	else {
	    $iplus1 = $i + 1;
	    print MFILE "       $alphabet[$iplus1] : boolean,\n";
	} #end else
    } #end for
    if ($scaleable_formula == 0) {
	print MFILE "       $N[$i] : boolean\n\n";
    } #end if
    else {
	$iplus1 = $i + 1;
	print MFILE "       $alphabet[$iplus1] : boolean\n\n";	
    } #end else
    print MFILE "     INITIALIZATION\n";
    for ($i = 0; $i < $n; $i++) {
	if ($scaleable_formula == 0) {
	    print MFILE "       $N[$i] IN {TRUE,FALSE};\n";
	} #end if
	else {
	    $iplus1 = $i + 1;
	    print MFILE "       $alphabet[$iplus1] IN {TRUE,FALSE};\n";
	} #end else
    } #end for
    print MFILE "\n     TRANSITION\n       [  TRUE -->\n";
    for ($i = 0; $i < $n; $i++) {
	if ($scaleable_formula == 0) {
	    print MFILE "            $N[$i]' IN {TRUE,FALSE}; %next time $N[$i] is in true or false\n";
	} #end if
	else {
	    $iplus1 = $i + 1;
	    print MFILE "            $alphabet[$iplus1]' IN {TRUE,FALSE}; %next time $alphabet[$iplus1] is in true or false\n";
	} #end else
    } #end for
    print MFILE "       ]\n\n";
    print MFILE "   END; %MODULE\n\n";
    print MFILE "   formula: THEOREM main |- ((((G(F(TRUE))))) => (NOT($formula)));\n\n";    
    print MFILE "END %CONTEXT\n";
    close(MFILE) or die "Could not close $tempModel: $!";
    
    $analysis = `$time_cmd -f \"\%U\" sal-smc $tempModel formula 2>&1`;
    chomp($analysis);
    @analysis = split/^/, $analysis; #split into lines 
    $time_info = $analysis[$#analysis]; #get the last line of output, which is the timing info
    print $thisfile "$time_info\t";


    ### Parse output looking for satisfiability
    print "SALsmc: ";
   if ($analysis =~ /Counterexample/) {
	print "satisfiable\n";
	print $thisfile "1\n";
	print OUT "satisfiable\n";
	return 1;
    } #end if
    elsif ($analysis =~ /proved/) {
	print "NOT_satisfiable\n";
	print $thisfile "0\n";
	print OUT "NOT_satisfiable\n";
	return 0;
    } #end elsif
    else {
	print "ERROR: No readable output from SAL-SMC\n";
	print $thisfile "ERROR\n";
	print OUT "ERROR: No readable output from SAL-SMC\n";
	print OUT "ANALYSIS: \"$analysis\"\n";
	if ($counter_formula) {die;} #don't continue scaling past errors
	if ($scaleable_formula) {die;} #don't continue scaling past errors
	return -1;
    } #end else

} #end SALsmc


#PANDA
#To run: PANDA LTL_formula_file
#   output:
#Notes:
# - requires different formula syntax:
#     !     ~     (not)
#     &&    &
#     ||    |
sub PANDA {

    my $formula = $_[0];
    my $n = $_[1];

    #Modify the formula syntax:
    $formula =~ s/!/~/g;       #NOT is ~
    $formula =~ s/&&/&/g;      #AND is &
    $formula =~ s/\|\|/\|/g;   #OR  is |

    $thisfile = "PANDATEC";
    print OUT "PANDA\t";

    ### Generate the model ###
    $time_cmd = `which time`; #capture the time cmd; override bash default
    chomp($time_cmd);

    #create a file to input the LTL formula:
    $tempFile = "${temp}.form";
    open(FFILE, ">$tempFile") or die "Could not open $tempFile: $!";
    print FFILE "$formula";
    close(FFILE) or die "Could not close $tempFile: $!";

    #The $restartFlags var contains all flags now, whether we're restarting or not
    $analysis = `$time_cmd -f \"\%U\" ${path}mytool/PANDA $restartFlags $tempFile 2>&1`;
    
    chomp($analysis);
    @analysis = split/^/, $analysis; #split into lines
    $time_info = $analysis[$#analysis]; #get the last line of output, which is the timing info
    print $thisfile "$time_info\t";
    print OUT "$time_info\t";
  
    if ($PANDAflag eq "-c") {
	# clean up
	if (-e "tableau.out") { `rm -f tableau.out`; }

	### Call CadencsSMV on the newly created symbolic automaton ###
	if ($varOrder == 1) {
	    $analysis = `$time_cmd -f \"\%U\" smv -force -v 0 -- -i tableau.var tableau.smv 2>&1`;
	} #end if
	else {
	    $analysis = `$time_cmd -f \"\%U\" smv -force -v 0 tableau.smv 2>&1`;
	} #end else
	chomp($analysis);
	@analysis = split/^/, $analysis; #split into lines
	$time_info = $analysis[$#analysis]; #get the last line of output, which is the timing info
	print $thisfile "$time_info\t";
	print OUT "$time_info\t";
	
	@num_states = 0;
	if (-e "tableau.out") {
	    @num_states = `grep "\/\* state" tableau.out`;
	} #end if
	if (@num_states > 0) {
	    for ($i = $#num_states; $i >= 0; $i--) {
		if ($num_states[$i] =~ /^.*\/\*\s*state\s*(\d+)\s*\*\/{.*$/) {
		    $last_state = $1; #print "last_state is $last_state\n";
		    last;
		} #end if
	    } #end for
		
	    if (($i == 0) && ($last_state !~ /^\d+$/)) {
		print $thisfile "statecount_error\t";
	    } #end if
	    else {
		print $thisfile "$last_state\t";
	    } #end else
	    `rm -f tableau.out`;
	} #end if
	else { #there is no counterexample
	    print $thisfile "0\t";
	} #end else

	### Parse output looking for satisfiability
	if ($analysis =~ /false/) {
	    #Do we need this next line? Where is $warning set?
	    if ($warning) { print $thisfile "1W\n"; $warning = 0; }
	    else { print $thisfile "1\n"; }
	    print OUT "satisfiable\n";
	    return 1;
	} #end if
	elsif ($analysis =~ /true/) {
	    #Do we need this next line? Where is $warning set?
	    if ($warning) { print $thisfile "0W\n"; $warning = 0; }
	    else { print $thisfile "0\n"; }
	    print OUT "NOT_satisfiable\n";
	    return 0;
	} #end elsif
	else {
	    print $thisfile "ERROR\n";
	    print OUT "ERROR: No readable output from Cadence SMV on PANDA:\n${analysis}\n";
	    print OUT "COMMAND: $time_cmd -f \"\%U\" smv -force -v 0 tableau.smv\n";
	    print OUT "ANALYSIS: \"$analysis\"\n";
	    return -1;
	} #end else

    } #end CadenceSMV mode
    elsif ($PANDAflag eq "-n") {

        ### Call NuSMV on the newly created tableau ###
	if ($varOrder == 1) {
	    if ($printReachableStates == 1) {
		$analysis = `$time_cmd -f \"\%U\" $NuSMV_command $NuSMVflag -r -i tableau.var tableau.smv 2>&1`;
	    } #end if
	    else {
		$analysis = `$time_cmd -f \"\%U\" $NuSMV_command $NuSMVflag -i tableau.var tableau.smv 2>&1`;
	    } #end else
	} #end if
	else {
	    if ($printReachableStates == 1) {
		$analysis = `$time_cmd -f \"\%U\" $NuSMV_command $NuSMVflag -r tableau.smv 2>&1`;
	    } #end if
	    else {
		$analysis = `$time_cmd -f \"\%U\" $NuSMV_command $NuSMVflag tableau.smv 2>&1`;
	    } #end else
	} #end else
	chomp($analysis);

	#Quick check for warnings:
	if ($uname =~ /sugar.rice.edu/) { #Sug@r includes 9 WARNINGS for ZCHAFF
	    $warning_count = ($analysis =~ s/WARNING/WARNING/g);
	    if ($warning_count > 9) {
		$warning = 1;
	    } #end if
	} #end if
	elsif ($analysis =~ /WARNING/) {
	    $warning = 1;
	} #end if

	@analysis = split/^/, $analysis; #split into lines
	$time_info = $analysis[$#analysis]; #get the last line of output, which is the timing info
	print $thisfile "$time_info\t";
	print OUT "$time_info\t";

        if (-e "tableau.out") {
            `rm -f tableau.out`;
        } #end if

	### Parse output looking for satisfiability
	foreach $line (@analysis) {
	    if ($line =~ /^.*specification\s*.*is\s+([\S]+)\s+.*$/) {
		$analysis = $1; #get "true" or "false"
		if ($printReachableStates == 0) {last;}
		else {next;}
	    } #end if
	    #if ($line =~ /reachable states:\s+(\d+)\s*\(.+\) out of (\d+).+$/) {
	    if ($line =~ /reachable states:\s*([\d\.e\+]+).* out of ([\d\.e\+]+).+$/) {

		print $thisfile "$1\t$2\t";
		last; #reachable states comes after specification truth
	    } #end if
	} #end foreach

        #record claim validity
        print "NuSMV on PANDA: ";
        if ($analysis =~ /false/) {
	    #Look for number of counterexample states
	    for ($i = $#analysis; $i >= 0; $i--) {
		if ($analysis[$i] =~ /-> State: 1.(\d+) <-/) {
		    $last_state = $1; 
		    last;
		} #end if
	    } #end for
		
	    if (($i == 0) && ($last_state !~ /^\d+$/)) {
		print $thisfile "statecount_error\t";
	    } #end if
	    else {
		print $thisfile "$last_state\t";
	    } #end else

	    #Record satisfiability results
            print "satisfiable\n";
            #the violation means satisfiable
	    if ($warning) { print $thisfile "1W\n"; $warning = 0; }
	    else { print $thisfile "1\n"; }
            print OUT "satisfiable\n";
            return 1;
        } #end if
        elsif ($analysis =~ /true/) {
	    #Record number of counterexample states
	    print $thisfile "0\t";

	    #Record satisfiability results
            print "NOT_satisfiable\n";
            if ($warning) { print $thisfile "0W\n"; $warning = 0; }
	    else { print $thisfile "0\n"; }
            print OUT "NOT_satisfiable\n";
            return 0;
        } #end elsif
        else {
            print STDERR "ERROR: No readable output from NuSMV on PANDA\n";
            print $thisfile "ERROR\n";
            print OUT "ERROR: No readable output from NuSMV on PANDA:\n${analysis}\n";
	    print OUT "COMMAND: $time_cmd -f \"\%U\" $NuSMV_command $NuSMVflag tableau.smv\n";
	    print OUT "ANALYSIS: \"$analysis\"\n";
	    
	    if ($counter_formula) {die;} #don't continue scaling past errors
	    if ($scaleable_formula) {die;} #don't continue scaling past errors

            return -1;
        } #end else

    } #end elsif NuSMV mode
    elsif ($PANDAflag eq "-s") {

	### Call sal-wmc on the newly created symbolic automaton ###
	
	$analysis = `$time_cmd -f \"\%U\" sal-wmc tableau.sal spec 2>&1`;
	chomp($analysis);
	@analysis = split/^/, $analysis; #split into lines
	$time_info = $analysis[$#analysis]; #get the last line of output, which is the timing info
	print $thisfile "$time_info\t";
	print OUT "$time_info\t";

	### Parse output looking for satisfiability
	print "SAL-WMC on PANDA: ";
	if ($analysis =~ /false/) {
	    print "satisfiable\n";
	    if ($warning) { print $thisfile "1W\n"; $warning = 0; }
	    else { print $thisfile "1\n"; }
	    print OUT "satisfiable\n";
	    return 1;
	} #end if
	elsif ($analysis =~ /true/) {
	    print "NOT_satisfiable\n";
	    if ($warning) { print $thisfile "10\n"; $warning = 0; }
	    else { print $thisfile "0\n"; }
	    print OUT "NOT_satisfiable\n";
	    return 0;
	} #end elsif
	else {
	    print "ERROR: No readable output from SAL-WMC on PANDA\n";
	    print $thisfile "ERROR\n";
	    print OUT "ERROR: No readable output from SAL-WMC on PANDA\n";

	    if ($counter_formula) {die;} #don't continue scaling past errors
	    if ($scaleable_formula) {die;} #don't continue scaling past errors

	    return -1;
	} #end else
	
    } #end SAL-WMC mode
    else {
        die "Unrecognized PANDAflag: $PANDAflag\n";
    } #end else
  
} #end PANDA


#ltl2smv
#To run: ltl2smv 1 LTL_formula_file
#  
sub ltl2smv {

    my $formula = $_[0];
    my $n = $_[1];

    #Modify the formula syntax:
    $formula =~ s/&&/&/g;      #AND is &
    $formula =~ s/\|\|/\|/g;   #OR  is |

    $thisfile = "ltl2smvTEC";
    print OUT "LTL2SMV\t";

    ### Generate the model ###
    $time_cmd = `which time`; #capture the time cmd; override bash default
    chomp($time_cmd);

    #create a file to input the LTL formula:
    $tempFile = "${temp}.form";
    open(FFILE, ">$tempFile") or die "Could not open $tempFile: $!";
    print FFILE "$formula";
    close(FFILE) or die "Could not close $tempFile: $!";

    #create a file to input the LTL model:
    $tempModel = "${temp}.smv";
    open(MFILE, ">$tempModel") or die "Could not open $tempModel: $!";
    print MFILE "MODULE main\n";
    print MFILE "  VAR\n";
    for ($i = 0; $i < $n; $i++) {
	if ($scaleable_formula == 0) {
	    print MFILE "    $N[$i] : boolean;\n";
	} #end if
	else { #random and counter formulas
	    $iplus1 = $i + 1;
	    print MFILE "    p${iplus1} : boolean;\n";
	} #end else
	
    } #end for
    print MFILE "\n";
    close(MFILE) or die "Could not close $tempModel: $!";
    
    $time_info = `$time_cmd -f \"\%U\" $ltl2smv_command 1 $tempFile 1>> $tempModel 2> $temp`;

    $time_info = `cat $temp`;
    chomp($time_info);
    `rm $temp`; #clean up

    print $thisfile "$time_info\t";
    print OUT "$time_info\t";

    #modify the ltl2smv model to add the SPEC statement
    open(MFILE, "<$tempModel") or die "Could not open $tempModel: $!";
    open(TFILE, ">$temp") or die "Could not open $temp: $!";
    $specVar = "";
    $getSpecVar = 0;
    foreach $line (<MFILE>) {

	#delete the "MODULE ltl_spec_1" line
	if ($line =~ /MODULE ltl_spec_1/) {
	    next; #skip to the next line w/out printing this one
	} #end if

	#save the initialized SPEC var
	if ($line =~ /INIT/) {
	    $getSpecVar = 1;

	    if ($modelFlags =~ /-noinit/) {
		next; #skip to the next line w/out printing this one
	    } #end if
	} #end if
	elsif ($getSpecVar == 1) { #if we are in the line after "INIT\n"
	    $specVar = $line;
	    chomp ($specVar);
	    $getSpecVar = 0;

	    if ($modelFlags =~ /-noinit/) {
		next; #skip to the next line w/out printing this one
	    } #end if
	} #end if
	#adjust the code for CadenceSMV if necessary
	elsif (($line =~ /JUSTICE/) && ($PANDAflag eq "-c")) {
	    $line =~ s/JUSTICE/FAIRNESS/g;
	} #end elsif

	print TFILE "$line";

    } #end while
    close(MFILE) or die "Could not close $tempModel: $!";
    close(TFILE) or die "Could not close $temp: $!";
    `rm -f $tempModel`;
    `mv $temp $tempModel`;

    if ($specVar eq "") { print OUT "ERROR: couldn't find INIT/SPEC var!"; 
			  die "ERROR: couldn't find INIT/SPEC var!"; }    
    
    `echo "SPEC \t !($specVar & EG TRUE)" >> $tempModel`;

    if ($PANDAflag eq "-c") {
	
	### Call CadenceSMV on the newly created symbolic automaton ###
	
	if ($varOrder == 1) {
	    die "ERROR: code not written for ltl2smv/Cadence SMV and variable orderings\n";
	} #end if#
	else {
	    $analysis = `$time_cmd -f \"\%U\" smv -force -v 0 $tempModel 2>&1`;
	} #end else
	chomp($analysis);
	@analysis = split/^/, $analysis; #split into lines
	$time_info = $analysis[$#analysis]; #get the last line of output, which is the timing info
	print $thisfile "$time_info\t";
	print OUT "$time_info\t";

	@num_states = 0;
	if (-e "${temp}.out") {
	    @num_states = `grep "\/\* state" ${temp}.out`;
	} #end if
	if (@num_states > 0) {
	    for ($i = $#num_states; $i >= 0; $i--) {
		if ($num_states[$i] =~ /^.*\/\*\s*state\s*(\d+)\s*\*\/{.*$/) {
		    $last_state = $1; 
		    last;
		} #end if
	    } #end for
		
	    if (($i == 0) && ($last_state !~ /^\d+$/)) {
		print $thisfile "statecount_error\t";
	    } #end if
	    else {
		print $thisfile "$last_state\t";
	    } #end else
	    `rm -f ${temp}.out`;
	} #end if
	else { #there is no counterexample
	    print $thisfile "0\t";
	} #end else
	    
	### Parse output looking for satisfiability
	print "CadenceSMV on ltl2smv: ";
	if ($analysis =~ /false/) {
	    print "satisfiable\n";
	    if ($warning) { print $thisfile "1W\n"; $warning = 0; }
	    else { print $thisfile "1\n"; }
	    print OUT "satisfiable\n";
	    return 1;
	} #end if
	elsif ($analysis =~ /true/) {
	    print "NOT_satisfiable\n";
	    if ($warning) { print $thisfile "0W\n"; $warning = 0; }
	    else { print $thisfile "0\n"; }
	    print OUT "NOT_satisfiable\n";
	    return 0;
	} #end elsif
	else {
	    print "ERROR: No readable output from Cadence SMV on ltl2smv\n";
	    print $thisfile "ERROR\n";
	    print OUT "ERROR: No readable output from Cadence SMV on ltl2smv:\n${analysis}\n";
	    print OUT "COMMAND: $time_cmd -f \"\%U\" smv -force -v 0 $tempModel\n";
	    print OUT "ANALYSIS: \"$analysis\"\n";
	    return -1;
	} #end else

    } #end CadenceSMV mode
    elsif ($PANDAflag eq "-n") {
	
	### Call NuSMV on the newly created symbolic automaton ###
	#WARNING: -- necessary to take var order: must disable default options
	if ($varOrder == 1) {
	    if ($printReachableStates == 1) {
		### FIX: compute tableau.var here!
		$analysis = `$time_cmd -f \"\%U\" $NuSMV_command $NuSMVflag -r -i tableau.var $tempModel 2>&1`;
	    } #end if
	    else {
		### FIX: compute tableau.var here!
		$analysis = `$time_cmd -f \"\%U\" $NuSMV_command $NuSMVflag -i tableau.var $tempModel 2>&1`;
	    } #end else
	} #end if
	else {
	    if ($printReachableStates == 1) {
		$analysis = `$time_cmd -f \"\%U\" $NuSMV_command $NuSMVflag -r $tempModel 2>&1`;
	    } #end if
	    else {
		$analysis = `$time_cmd -f \"\%U\" $NuSMV_command $NuSMVflag $tempModel 2>&1`;
	    } #end else
	} #end else

	chomp($analysis);

	#Quick check for warnings:
	if ($uname =~ /sugar.rice.edu/) { #Sug@r includes 9 WARNINGS for ZCHAFF
	    $warning_count = ($analysis =~ s/WARNING/WARNING/g);
	    if ($warning_count > 9) {
		$warning = 1;
	    } #end if
	} #end if
	elsif ($analysis =~ /WARNING/) { #for non-Sug@r machines
	    $warning = 1;
	} #end if

	@analysis = split/^/, $analysis; #split into lines
	$time_info = $analysis[$#analysis]; #get the last line of output, which is the timing info
	print $thisfile "$time_info\t";
	print OUT "$time_info\t";
	
	### Parse output looking for satisfiability
	foreach $line (@analysis) {
	    if ($line =~ /^.*specification\s*.*is\s+([\S]+)\s+.*$/) {
		$analysis = $1; #get "true" or "false"
		if ($printReachableStates == 0) {last;}
		else {next;}
	    } #end if
	    if ($line =~ /reachable states:\s+(\d+)\s*\(.+\) out of (\d+).+$/) {
		print $thisfile "$1\t$2\t";
		#print "line: $line\n";
		last; #reachable states comes after specification truth
	    } #end if
	} #end foreach
	
	#record claim validity
	print "NuSMV on ltl2smv: ";
	if ($analysis =~ /false/) {
	    #Look for number of counterexample states
	    for ($i = $#analysis; $i >= 0; $i--) {
		#print "looking at \"$analysis[$i]\"";
		if ($analysis[$i] =~ /-> State: 1.(\d+) <-/) {
		    $last_state = $1; #print "last_state is $last_state\n";
		    last;
		} #end if
	    } #end for
		
	    if (($i == 0) && ($last_state !~ /^\d+$/)) {
		print $thisfile "statecount_error\t";
	    } #end if
	    else {
		print $thisfile "$last_state\t";
	    } #end else

	    #Record satisfiability results
            print "satisfiable\n";
            #the violation means satisfiable
	    if ($warning) { print $thisfile "1W\n"; $warning = 0; }
	    else { print $thisfile "1\n"; }
            print OUT "satisfiable\n";
            return 1;
	} #end if
        elsif ($analysis =~ /true/) {
	    #Record number of counterexample states
	    print $thisfile "0\t";

	    #Record satisfiability results
            print "NOT_satisfiable\n";
            if ($warning) { print $thisfile "0W\n"; $warning = 0; }
	    else { print $thisfile "0\n"; }
            print OUT "NOT_satisfiable\n";
            return 0;
        } #end elsif
	else {
	    print "ERROR: No readable output from NuSMV on ltl2smv\n";
	    print $thisfile "ERROR\n";
	    print OUT "ERROR: No readable output from NuSMV on ltl2smv:\n${analysis}\n";
	    print OUT "COMMAND: $time_cmd -f \"\%U\" $NuSMV_command $NuSMVflag $tempModel\n";
	    print OUT "ANALYSIS: \"$analysis\"\n";
	    
	    if ($counter_formula) {die;} #don't continue scaling past errors
	    if ($scaleable_formula) {die;} #don't continue scaling past errors

	    return -1;
	} #end else
    } #end NuSMV mode

} #end ltl2smv


sub Nothing {
    print "Nothing here!!!\n";
    $thisfile = "NothingTEC";
    print $thisfile "No data\n";
}


#Run each tool on each of the formulas generated from the given parameters
sub run_tools {

    my $P = $_[0];
    my $n = $_[1];
    my $L = $_[2];

    
    if ($formula_type eq "c") {
	$counter_formula = 1; #do counter formulas instead of random ones
    } #end if
    elsif($formula_type eq "p") {
	$scaleable_formula = 1; #do scaleable formulas instead of random ones
    } #end elsif

    #Create a Tecplot output file for each tool's data
    
    #Symbolic-Approach model checkers
    foreach $tool (@stools) {

	#eliminate spaces from tool name for filename
	if ($tool eq "NuSMV") {
	    $tool_abbrev = "${tool}${NuSMVflag}";
	    $tool_abbrev =~ s/\s*//g;
	} #end if
	else {
	    $tool_abbrev = $tool;
	} #end else

	if ( ($scaleable_formula == 1) 
	     && (($n == $scaleableN)
		 || (($restart == 1) && ($n == $restartStart)) ) ) {
            $tecfile = "${data_path}${tool_abbrev}_${scaleable_class}_pattern${run_number}.tec";

	    $thisfile = "${tool}TEC";
	    open($thisfile, ">$tecfile") or die "Could not open $tecfile: $!";

	    if (($restart == 0) 
		|| ( ($restart == 1) && ($restartStart == 0) )
		|| ( ($scaleable_class eq "E") && ($n == 1) )
		|| (($scaleable_class eq "U") && ($n == 2)) 
		|| (($scaleable_class eq "R") && ($n == 2)) 
		|| (($scaleable_class eq "U2") && ($n == 2)) 
		|| (($scaleable_class eq "R2") && ($n == 2)) 
		|| (($scaleable_class eq "C1") && ($n == 1)) 
		|| (($scaleable_class eq "C2") && ($n == 1)) 
		|| (($scaleable_class eq "Q") && ($n == 2)) 
		|| (($scaleable_class eq "S") && ($n == 1)) ) {

		print $thisfile "TITLE=\"Analysis: ${tool_abbrev} on ${scaleable_class}-class scaleable pattern formulas\"\n";
		if ($printReachableStates == 0) {
		    print $thisfile "VARIABLES=\"formula number\", \"model analysis time\", \"claim validity (1=valid)\"\n";
		} #end if
		else {
		    print $thisfile "VARIABLES=\"formula number\", \"model analysis time\", \"reachable states\", \"total states\", \"claim validity (1=valid)\"\n";
		} #end else
		print $thisfile "ZONE F=POINT\n\n";	
	    } #end if
	} #end if
	elsif ( ($counter_formula == 1) 
		&& (($f == 1)
		    || (($restart == 1) && ($f == $restartStart)) ) ) {
	    $tecfile = "${data_path}${tool_abbrev}_${counter_class}_counter${run_number}.tec"; #FIX THIS: make filenames reflect type of counter
	    
	    $thisfile = "${tool}TEC";
	    open($thisfile, ">$tecfile") or die "Could not open $tecfile: $!";

	    if (($restart == 0) 
		|| ( ($restart == 1) && ($restartStart == 1) ) ) {
		
		print $thisfile "TITLE=\"Analysis: ${tool_abbrev} on ${title_string}\"\n";
		if ($printReachableStates == 0) {
		    print $thisfile "VARIABLES=\"formula number\", \"model analysis time\", \"claim validity (1=valid)\"\n";
		} #end if
		else {
		    print $thisfile "VARIABLES=\"formula number\", \"model analysis time\", \"reachable states\", \"total states\", \"claim validity (1=valid)\"\n";
		} #end else
		print $thisfile "ZONE F=POINT\n\n";	
	    } #end if
	    
	} #end if counter_formula
	elsif (($scaleable_formula == 0) && ($counter_formula == 0)) { #random
	    $tecfile = "${data_path}${tool}_P${P}N${n}L${L}.tec";
	    $thisfile = "${tool}TEC";
	    open($thisfile, ">$tecfile") or die "Could not open $tecfile: $!";

	    if (($restart == 0) || ( ($restart == 1) && ($restartStart == 0) )) {
		print $thisfile "TITLE=\"Analysis: ${tool} with P=${P}, N=${n}, L=${L}\"\n";
		if (printReachableStates == 0) {
		    print $thisfile "VARIABLES=\"formula number\", \"model analysis time\", \"claim validity (1=valid)\"\n";
		} #end if
		else {
		    print $thisfile "VARIABLES=\"formula number\", \"model analysis time\", \"reachable states\", \"total states\", \"claim validity (1=valid)\"\n";
		} #end else
		print $thisfile "ZONE F=POINT\n\n";
	    } #end if
	} #end else
    } #end for each stool

    #My Symbolic-Approach Tools
    foreach $tool (@mytools) {
	#eliminate spaces from tool name for filename
	if ($restart == 1) {
	    if ($tool =~ /ltl2smv/) {
		#fix possible double flags for -n and -c
		$tool =~ s/-c//;
		$tool =~ s/-n//;
	    } #end if
	    $tool_abbrev = "${tool}${restartFlags}${modelFlags}${NuSMVflag}";
	} #end if
	$tool_abbrev =~ s/\s+//g;

	$_ = $tool;
	@tool_parts = split();
	$tool_name = $tool_parts[0];

	#Set the data file name according to formula type
        if ($counter_formula == 1) {
            $tecfile = "${data_path}${tool_abbrev}_${counter_class}_counter${run_number}.tec";
        } #end if
	elsif ($scaleable_formula == 1) {
            $tecfile = "${data_path}${tool_abbrev}_${scaleable_class}_pattern${run_number}.tec";
	} #end elsif
        else {
	    $tecfile = "${data_path}${tool_abbrev}_P${P}N${n}L${L}.tec";
	} #end else

	if ( (($scaleable_formula == 1) 
	     && (($n == $scaleableN)
		 || (($restart == 1) && ($n == $restartStart)) ) )
	     || ($scaleable_formula != 1) ) { #check this

	    #Open the data file
	    $thisfile = "${tool_name}TEC";
	    open($thisfile, ">$tecfile") or die "Could not open $tecfile: $!";
	} #end if	    
	elsif (($scaleable_formula == 1)  #inefficient: fix (combine with if above)
	       && ($scaleableN > $n)) {
	    #Open the data file
	    $thisfile = "${tool_name}TEC";
	    open($thisfile, ">$tecfile") or die "Could not open $tecfile: $!";
	} #end elsif

	#Print title/variables/zone information if necessary
	if ( (($counter_formula == 1) 
	      && (($f == 1)
		  || (($restart == 1) && ($f == $restartStart)) ) )
	     || (($counter_formula != 1) 
		 && ($scaleable_formula != 1)
		 && ($restart == 1) && ($restartStart == 0))
	     || ($restart == 0) 
	     || (($scaleable_formula == 1) #may not need this OR
		 && (($n == $scaleableN)
		     || (($restart == 1) && ($n == $restartStart)) ) )
	     || (($scaleable_formula != 1) && ($restart == 1) && ($restartStart == 0))
	     || (($scaleable_class eq "E") && ($n == 1))
	     || (($scaleable_class eq "U") && ($n == 2)) 
	     || (($scaleable_class eq "R") && ($n == 2)) 
	     || (($scaleable_class eq "U2") && ($n == 2)) 
	     || (($scaleable_class eq "R2") && ($n == 2)) 
	     || (($scaleable_class eq "C1") && ($n == 1)) 
	     || (($scaleable_class eq "C2") && ($n == 1)) 
	     || (($scaleable_class eq "Q") && ($n == 2)) 
	     || (($scaleable_class eq "S") && ($n == 1)) ) {

	    if ($PANDAflag eq "-c") #&& ($tool !~ /ltl2smv/)) 
	    {
		if ($counter_formula == 1) {
		    print $thisfile "TITLE=\"Analysis: ${tool_name}/CadenceSMV${titleString} on ${title_string}\"\n";
		} #end if
		elsif ($scaleable_formula == 1) {
		    print $thisfile "TITLE=\"Analysis: ${tool_name}/CadenceSMV${titleString} on ${scaleable_class}-class scaleable pattern formulas\"\n";
		} #end elsif
		else { #random formulas
		    print $thisfile "TITLE=\"Analysis: ${tool_name}/CadenceSMV${titleString} with P=${P}, N=${n}, L=${L}\"\n";
		} #end else
	    } #end if
	    elsif ($PANDAflag eq "-n") #|| ($tool =~ /ltl2smv/)) 
	    { #random formulas
		if ($counter_formula == 1) {
		    print $thisfile "TITLE=\"Analysis: ${tool_name}/NuSMV${titleString} on ${title_string}\"\n";
		} #end if
		elsif ($scaleable_formula == 1) {
		    print $thisfile "TITLE=\"Analysis: ${tool_name}/NuSMV${titleString} on ${scaleable_class}-class scaleable pattern formulas\"\n";

		} #end if
		else {
		    print $thisfile "TITLE=\"Analysis: ${tool_name}/NuSMV${titleString} with P=${P}, N=${n}, L=${L}\"\n";
		} #end else
	    } #end elsif
	    elsif ($PANDAflag eq "-s") {
		if ($counter_formula == 1) {
		    print $thisfile "TITLE=\"Analysis: ${tool_name}/SAL${titleString} on ${title_string}\"\n";
		} #end if
		elsif ($scaleable_formula == 1) {
		    print $thisfile "TITLE=\"Analysis: ${tool_name}/SAL${titleString} on ${scaleable_class}-class scaleable pattern formulas\"\n";
		} #end elsif
		else {
		    print $thisfile "TITLE=\"Analysis: ${tool_name}/SAL${titleString} with P=${P}, N=${n}, L=${L}\"\n";
		} #end else
	    } #end elsif
	    else {
		if ($counter_formula == 1) {
		    print $thisfile "TITLE=\"Analysis: ${tool_name}${titleString} on ${title_string}\"\n";
		} #end if
		elsif ($scaleable_formula == 1) {
		    print $thisfile "TITLE=\"Analysis: ${tool_name}${titleString} on ${scaleable_class}-class scaleable pattern formulas\"\n";
		} #end if
		else {
		    print $thisfile "TITLE=\"Analysis: ${tool_name}${titleString} with P=${P}, N=${n}, L=${L}\"\n";
		} #end else
	    } #end else
	    if ($printReachableStates == 0) {
		print $thisfile "VARIABLES=\"formula number\", \"model generation time\", \"model analysis time\", \"counterexample length\", \"claim validity (1=valid)\"\n";
	    } #end if
	    else {
		print $thisfile "VARIABLES=\"formula number\", \"model generation time\", \"model analysis time\", \"reachable states\", \"total states\", \"counterexample length\", \"claim validity (1=valid)\"\n";
	    } #end else
	    print $thisfile "ZONE F=POINT\n\n";
	} #end if
    } #end for each mytool
    
    $start = 0;
    if (($restart == 1) && ($formula_type ne "r")) {
	$start = $restartStart;
	$restartStart = 0; #reset for next round
    } #end if
    if ($formula_type eq "r") {
	$scalemax = $F;
    } #end if

    for ($f = $start; $f < $scalemax; $f++) { #generate $F formulas !!!!!
	if ($formula_type eq "r") { #random formulas
	    
	    if ($f < $restartStart) { #advance the formula file
		for ($i = 0; $i < $restartStart; $i++) {
		    $formula = <FORMULAS>; #get one line from the formula file
		} #end for
		$f = $restartStart;
		$restartStart = 0; #reset for next round ???
	    } #end if
	    
	    $formula = <FORMULAS>; #get one line from the formula file
	} #end if
        elsif ($counter_formula == 1) {
	    if ($counter_class !~ /cc/) { #if there's no carry
		$n = 2;
	    } #end if
	    else {
		$n = 3;
	    } #end else
            $formula = `${path}${formula_command} $f`;
        } #end elsif
	elsif ($scaleable_formula == 1) {
	    $n = $f;
	    if ((@stools == 1)
		&& ($stools[0] =~ /CadenceSMV/) #WARNING!!! This breaks for multiple tools!!!
		&& ($scaleable_class eq "R2")) {
		#CadenceSMV can't handle R operators, so call something different for it
		$formula = `${path}R2bformula.pl $n`;
	    } #end if CadenceSMV and R2
	    else {
		$formula = `${path}${scaleable_class}formula.pl $n`;
	    } #end else
        } #end else

	chomp($formula); #remove the trailing '\n'
	$formula = "($formula)"; #add extra outer parens, just to be through


	#Keep track of the results for this formula
	@formula_validity = (); #clear the array


	### Symbolic Model Checking Section ###
	foreach $tool (@stools) {
	    $_ = $tool;
	    @tool_parts = split();

	    $tool_name = $tool_parts[0];

	    #DEBUG
	    $thisfile = "${tool_name}TEC";
	    print $thisfile "$f\t"; #print the formula number

	    #generate the model with this tool
	    $validity = &{$tool_name}($formula, $n); 
	    push(@formula_validity, $validity); #add validity to the array
	} #end foreach symbolic tool

        ### My Tool's Symbolic Model Checking Section ###
        foreach $tool (@mytools) {
	    $_ = $tool;
	    @tool_parts = split();

	    $tool_name = $tool_parts[0];
            #print "Working on my symbolic tool: $tool_name\n";

            #DEBUG
            #print "n = $n\n";
            $thisfile = "${tool_name}TEC";
	    print $thisfile "$f\t"; #print the formula number

            #generate the model with this tool
            $validity = &{$tool_name}($formula, $n);
            push(@formula_validity, $validity); #add validity to the array
        } #end foreach symbolic tool


	#Check the results for consistency
	$ones = 0;
	$zeros = 0;
	foreach $f (@formula_validity) {
	    if ($f == 1) { $ones++; }
	    elsif ($f == 0) {$zeros++; }
	} #end foreach
	if (($ones == 0) || ($zeros == 0)) {
	    #print "All tools agree on the formula validity.\n";
	    #print OUT "All tools agree on the formula validity.\n";
	} #end if
	elsif ($ones > $zeros) {
	    print "ERROR: Most tools agree this formula is satisfiable. The following disagree:\n";
	    print OUT "ERROR: Most tools agree this formula is satisfiable. The following disagree:\n";
	    for ($i = 0; $i < @formula_validity; $i++) {
		if ($formula_validity[$i] == 0) {
		    if ($i < @stools) {
			print "$stools[$i]\n";
			print OUT "$stools[$i]\n";
		    } #end if
		    else {
			$ii = $i - @stools;
                        print "$mytools[$ii]\n";
                        print OUT "$mytools[$ii]\n";
		    } #end else
		} #end if
	    } #end for
	} #end elsif more ones
	else { #more zeros than ones
	    print "ERROR: Most tools agree this formula is NOT satisfiable. The following disagree:\n";
	    print OUT "ERROR: Most tools agree this formula is NOT satisfiable. The following disagree:\n";
	    for ($i = 0; $i < @formula_validity; $i++) {
		if ($formula_validity[$i] == 1) {
		    if ($i < @stools) {
			print "$stools[$i]\n";
			print OUT "$stools[$i]\n";
		    } #end if
		    else {
			$ii = $i - @stools;
			print "$mytools[$ii]\n";
			print OUT "$mytools[$ii]\n";
		    } #end else
		} #end if
	    } #end for
	} #end elsif more zeros

        if (($f == 20) && (($counter_formula == 1))) { # || ($scaleable_formula == 1))) {
            #return;
            die "counter/scaleable test over";
        } #end if

    } #end for $F formulas

    #Close each tool's data file
    # (but leave open counter and scaleable files b/c those just time out
    if ($formula_type eq "r") {
	foreach $tool (@stools, @mytools) {
	    $tecfile = "${data_path}${tool}_P${P}N${n}L${L}.tec";
	    $thisfile = "${tool}TEC";
	    close($thisfile) or die "Could not close $tecfile: $!";
	} #end foreach
    } #end if

} #end run_tools



##################################################################
#
# Main Program: 
# 
#    For a statistical analysis, run getStatistics.pl on the 
#       generated data files.
#
##################################################################


# P = probability of temporal operators (random formulas only)
# N = number of variables (all formulas)
# L = length of formula in characters (random formulas only)
# F = number of formulas to test (all formulas)

#################### Generate the sets of formulas ####################

if (! $P) { $P = 0.5; } #default: average-behavior analysis, there is a 50% chance 
#                                 of choosing temporal operators

$turnvar = $rank; 

$n = 1;

if ($counter_formula == 1) {
    if ($counter_class !~ /cc/) { #if there's no carry
	$n = 2;
    } #end if
    else {
	$n = 3;
    } #end else
} #end if
elsif (($restart == 1) & ($formula_type eq "r")) { #RESTART
    $n = $restartN; #for regular restarts
} #end elsif
elsif ($formula_type eq "p") { #RESTART
    if ($restart == 1) {
	$nstart = $restartStart; #for scaleable formulas only
    } #end if
    else {
	$nstart = $scaleableN;
    } #end else

    if ( ($scaleable_class eq "E")
	 || ($scaleable_class eq "C1")
	 || ($scaleable_class eq "C2")
	 || ($scaleable_class eq "S") ) {
	$n = 1;
    } #end if
    elsif ( ($scaleable_class eq "U")
	    || ($scaleable_class eq "R") 
	    || ($scaleable_class eq "U2")
	    || ($scaleable_class eq "R2")
	    || ($scaleable_class eq "Q") ) {
	$n = 2;
    } #end elsif

} #end elsif
else {
    $n = 1;
} #end elsif
 

if ($counter_formula == 1) {
    
    $L = $n; #who cares what this is?
    
    $f = $restartStart; #this is absolutely necessary before the call to run_tools
    
    &run_tools($P, $n, $L);
    
} #end if counter
elsif ($scaleable_formula == 1) {
    $nsize = $scalemax;
       	
    $L = $n; #who cares what this is?
    
    &run_tools($P, $n, $L);
	
} #end if pattern
else { #random formulas
    $nstart = $n;
    $nsize = @N;
    if ($restart == 1) { #RESTART
	$nstart = $restartN;
    } #end if
    
    for ($n = $nstart; $n <= $nsize; $n++) { #for n variables

	#RESTART: make sure we only do one file, unless benchmarking mytools
	if ( ($restart == 1) && (@mytools == 0) ) {
	    if ($n > $nstart) {last;}
	} #end if

	$Lstart = 5;
	if (($restart == 1) && ($n == $nstart)) {
	    $Lstart = $restartL;
	} #end if
	
	for ($L = $Lstart; $L <= $LMAX; $L += 5) { #for each length
	    
	    #RESTART: make sure we only do one file
	    if (($restart == 1) && (@mytools == 0)) {
	    } #end if
	    
	    if ($turnvar == 0) { #it's our turn!
		$turnvar = $num_instances - 1; #reset
	    } #end if
	    elsif ($restart == 0) { #not our turn; skip to the next loop
		$turnvar--;
		next;
	    } #end else
	    
	    print "\nN = $n, L = $L:\n";
	    print OUT "\nN = $n, L = $L:\n";
	    
	    $FormFile = "${formula_dir}/P${P}N${n}L${L}.form";
	    if (! -e $FormFile) {
		#Shouldn't get here anymore...
		die "Tried to cd ${path}; generateRandomFormulas.pl $L $n 0.5";
		$error = `cd ${path}; generateRandomFormulas.pl $L $n 0.5`;
		chdir "${path}${mydir}"; #just in case
	    } #end if
	    if (! -r $FormFile) {
		die "Cannot create formula file $FormFile: $error\n";
	    } #end if
	    open(FORMULAS, "<$FormFile") or die "Could not open $FormFile: $!";
	    
	    &run_tools($P, $n, $L);

	    close(FORMULAS) or die "Could not close $FormFile: $!";
	    
	} #end for each length
    
    } #end for n variables
} #end else random formulas

#close the master data output file
close(OUT) or die "Could not close $outfile: $!";
