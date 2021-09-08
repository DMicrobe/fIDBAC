#This package contains the most frequently used subroutines

package  GACP;
use strict qw(subs refs);
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(  
 parse_config
);


##parse the software.config file, and check the existence of each software
####################################################
sub parse_config{
        my $config_file = shift;
        my $config_name = shift;
        my $config_path;

        open IN,$config_file || die "fail open: $config_file";
        while (<IN>) {
                next if(/^\s*\#/);
				if (/(\S+)\s*=\s*(\S+)/) {
					my ($software_name,$software_address) = ($1,$2);
                    if ($config_name eq $1) {
						$config_path = $2;
						last;
					}  
                }
        }
        close IN;
	return $config_path;
	
}


1;

__END__


