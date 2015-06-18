package SMS::Send::Telenor;
use HTTP::Tiny;
use strict;
use warnings;
our $VERSION = '0.03';
use base 'SMS::Send::Driver';
sub new {
    my ($class, @arg_arr) = @_;
    my $args;
    $args->{_login} = $arg_arr[1];
    $args->{_password} = $arg_arr[3];
    die "$class needs hash_ref with _login and password.\n" unless $args->{_login} && $args->{_password};
     my $self = bless {%$args}, $class;
     $self->{send_url} = 'http://sms-pro.net/services/' . $args->{_login} . '/sendsms';
     $self->{status_url} = 'http://sms-pro.net/services/' . $args->{_login} . '/status';
     return $self;
 }
 sub send_sms {
     my ($self, @arg_arr) = @_;
     my $args;
     $args->{customer_id} = $self->{_login};
     $args->{password} = $self->{_password};
      $args->{message} = $arg_arr[1];
      $args->{to_msisdn} = $arg_arr[3];
      my $xml = _build_sms_xml($args);
      my $response = _post($self->{send_url}, $xml);
      print $response;
      print "\n\n\nContent: \n";
      print $response->{content};
      my $rv =1;
      if (defined $response) {
          my $rv = _verify_response("$response->{content}");
      }
      return 1 if $rv eq '0';
      return 0;
  }
  sub sms_status {
      my ($self, $mobilectrl_id) = @_;
      my $args = {
          customer_id => $self->{_login},
          mobilectrl_id => $mobilectrl_id
      };
      my $xml = _build_status_xml($args);
      return _post($self->{status_url}, $xml);
  }
  sub _post {
      my ($url, $xml1) = @_;
      return HTTP::Tiny->new->post(
          $url => {
              content => $xml1,
              headers => {
                  "Content-Type" => "application/xml",
              },
          },
      );
  }
  sub _build_sms_xml {
      my $args = shift;
      my $xml2 = '<?xml version="1.0" encoding="ISO-8859-1"?>'
      . '<mobilectrl_sms>'
      . '<header>'
      . '<customer_id>'
      . $args->{customer_id}
      . '</customer_id>'
      . '<password>'
      . $args->{password}
      . '</password>'
      . '<from_alphanumeric>'
      . 'KOHA HYLTE'
      . '</from_alphanumeric>'
      . '</header>'
      . '<payload>'
      . '<sms account="71700">'
      . '<message><![CDATA['
      . $args->{message}
      . ']]></message>'
      . '<to_msisdn>'
      . $args->{to_msisdn}
      . '</to_msisdn>'
      . '</sms>'
      . '</payload>'
      . '</mobilectrl_sms>';
      print "\nMessage:\n$xml2\n";
      return $xml2;
  }
  sub _build_status_xml {
      my $args = shift;
      my $xml3 = '<?xml version="1.0" encoding="ISO-8859-1"?>'
      . '<mobilectrl_delivery_status_request>'
      . '<customer_id>'
      . $args->{customer_id}
      . '</customer_id>'
      . '<status_for type="mobilectrl_id">'
      . $args->{mobilectrl_id}
      . '</status_for>'
      . '</mobilectrl_delivery_status_request>';
      return $xml3;
  }
  sub _verify_response {
      my $content = shift;
      if ($content =~ /\<status\>(\d)\<\/status>/) {
          return $1;
      }
      return 1;
  }
  1;
