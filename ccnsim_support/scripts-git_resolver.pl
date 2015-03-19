#! usr/bin/perl
$filename=@ARGV[0];

$result_folder = "~/software/ccnsim/results";
$grep_command = "grep -r \"HEAD\" $result_folder";
$filename_filer = "cut -f1 -d':'";
@grep_output = `$grep_command > /tmp/grep_output.log`;
@files = `cat /tmp/grep_output.log | $filename_filer`;

foreach (@files){
	purify($_);
}




sub purify{
	$filename = $_[0];

	open(FILE, $filename) or die $!;
	open(TEMP_FILE,"> /tmp/pure.sca");

	if($@) {
		print $@;
	}

	$print_it = 1;
	foreach $line (<FILE>)  
	{ 
		if ($line eq "<<<<<<< HEAD\n")
		{
			$print_it = 0;
		}

		if ($print_it == 1){
			print TEMP_FILE "$line"; 
		}

		if ($line eq "=======\n"){
			$print_it = 1;
		}
	}
	close(FILE);
	close(TEMP_FILE);

	system( "cp /tmp/pure.sca $filename");
}

