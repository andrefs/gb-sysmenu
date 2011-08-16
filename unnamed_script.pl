#!/usr/bin/env perl 
use strict; use warnings;
use File::Basename;
use YAML::XS;
use Data::Dumper;

my ($repi_client_config, $themes_root, $site_files) = @ARGV;

$themes_root =~ s!/$!!;
$site_files =~ s!/$!!;

my $client_theme = get_theme_from_config($repi_client_config);
my $rept_client_config = "$themes_root/Instances/".$client_theme."/config.yml";
my $generic_theme = get_theme_from_config($rept_client_config);
my $rept_generic_config = "$themes_root/Generic/".$generic_theme."/config.yml";

copy_overrides($themes_root, $generic_theme, $site_files);
generate_saas();
generate_config($repi_client_config, $rept_client_config, $rept_generic_config);

sub copy_overrides {
	my $shared_or = "$themes_root/Shared/Overrides";
	qx{cp -r '$shared_or'/* '$site_files/'} if -e $shared_or;

	my $generic_or = "$themes_root/Generic/$generic_theme/Overrides";
	qx{cp -r '$generic_or'/* '$site_files/'} if -e $generic_or;
		
	my $client_or = "$themes_root/Instances/$client_theme/Overrides";
	qx{cp -r '$client_or'/* '$site_files/'} if -e $client_or;
}

sub generate_saas {
	my $sass_folder = "$themes_root/Instancies/$client_theme";
	foreach my $sass (<$sass_folder/*.sass>){
		next if $sass eq 'config.sass';
		my $css = basename($sass);
		$css =~ s/sass$/css/;
		$css = "$site_files/public/stylesheets/";
		qx{sass --update '$sass':'$css' --style compressed};
	}
}

sub generate_config {
	my ($repi_client_config, $rept_client_config, $rept_generic_config) = @_;
	my $local_conf = "$site_files/config/config.yml";
	qx{merge_yaml.pl '$repi_client_config' '$rept_client_config' '$rept_generic_config' > '$local_conf'};
}

sub get_theme_from_config {
	my $config_file = shift;
	my $config = YAML::XS::LoadFile($config_file);
	print Dumper $config;
	return $config->{theme};
}

