package SMS::Send::Telenor;

# SMS::Send driver for sending SMS with Telenor SMS Pro API
# (c) Eivin Giske Skaaren 2015
# This module is developed on GitHub

use HTTP::Tiny;
use strict;
use warnings;
our $VERSION = '0.03';
use base 'SMS::Send::Driver';

sub new {
	my ($class, $args) = @_;
	die "$class needs hash_ref with _login and password.\n" unless $args->{_login} && $args->{_password}; 
	my $self = bless {%$args}, $class;
	$self->{send_url} = 'http://http://sms-pro.net/services/' . $args->{_login} . '/sendsms';
	$self->{status_url} = 'http://http://sms-pro.net/services/' . $args->{_login} . '/status';
	return $self;
}

sub send_sms {
	my ($self, $args) = @_;
	$args->{customer_id} = $self->{_login};
	$args->{password} = $self->{_password};
	$args->{message} = $args->{text};
	$args->{to_msisdn} = $args->{to};
	my $xml = _build_sms_xml($args);

	my $response = _post($self->{send_url}, $xml);
	my $rv = _verify_response($response);

	# Telenor return value for OK is 0, but we want true as OK value
	return 1 if $rv eq '0';
	return 0;
}

sub sms_status {
	my ($self, $mobilectrl_id) = @_;
	my $args = {
		customer_id 	=> $self->{_login};
		mobilectrl_id	=> $mobilectrl_id;
	};
	my $xml = _build_status_xml($args);

	#For now returning the xml response
	return _post($self->{status_url}, $xml);
}

# Private functions under here
sub _post {
	my ($url, $xml) = @_;

	return HTTP::Tiny->new->post(
				$url => {
        			content => $xml,
        			headers => {
            			"Content-Type" => "application/xml",
          			},
       			},
    		);
}

sub _build_sms_xml {
	my $args = shift;

	my $xml = '<?xml version="1.0" encoding="ISO-8859-1"?>'
				. '<mobilectrl_sms>'
 				. '<header>'
 				. '<customer_id>' 
 				. $args->{customer_id}
 				. '</customer_id>'
 				. '<password>'
 				. $args->{password}
 				. '</password>'
 				. '<payload>'
				. '<message><![CDATA['
				. $args->{message}
				. ']]></message>'
 				. '<to_msisdn>'
 				. $args->{to_msisdn}
 				. '</to_msisdn>'
 				. '</sms>'
 				. '</payload>'
				. '</mobilectrl_sms>';

	return $xml;
}

sub _build_status_xml {
	my $args = shift;

	my $xml = '<?xml version="1.0" encoding="ISO-8859-1"?>'
				. '<mobilectrl_delivery_status_request>'
 				. '<customer_id>' 
 				. $args->{customer_id}
 				. '</customer_id>'
 				. '<status_for type="mobilectrl_id">'
 				. $args->{mobilectrl_id}
 				. '</status_for>'
				. '</mobilectrl_delivery_status_request>';

	return $xml;
}

sub _verify_response {
	if (/\<status\>(\d)\<\/status\>/) {
		return $1;
	}
	return 1;
}

1;

__END__
 
=pod
  
=head1 NAME
 
SMS::Send::Telenor - SMS::Send driver to send messages via Telenor SMS Pro (https://www.smspro.se/)
 
=head1 VERSION
 
version 0.02

=cut
