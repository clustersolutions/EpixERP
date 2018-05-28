#=================================================================
# Epix ERP
# Copyright (C) 2018
#
#  Author: Cluster Solutions
#     Web: http://www.clustersolutions.net
#
#======================================================================

package Form;

use parent SL::Form;
use strict;
use warnings;

sub header {
  my ($self, $endsession, $nocookie) = @_;

  return if $self->{header};

  #  my ($stylesheet, $favicon, $charset);
  #  $self->{favicon};
  #  $self->{charset};

  if ($ENV{HTTP_USER_AGENT}) {

    if ($self->{stylesheet} && (-f "ext/lipstick/css/$self->{stylesheet}")) {
      $self->{stylesheet} = qq|<LINK REL="stylesheet" HREF="ext/lipstick/css/$self->{stylesheet}" TYPE="text/css" TITLE="SQL-Ledger stylesheet">
  |;
    }

#    if ($self->{favicon} && (-f "$self->{favicon}")) {
#      $favicon = qq|<LINK REL="icon" HREF="$self->{favicon}" TYPE="image/x-icon">
#<LINK REL="shortcut icon" HREF="$self->{favicon}" TYPE="image/x-icon">
#  |;
#    }
#
#    if ($self->{charset}) {
#      $charset = qq|<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=$self->{charset}">
#  |;
#    }

#    $self->{stylesheet} .= qq|
#  <link href="css/jqx/jqx.base.css" rel="stylesheet">
#  <link href="css/jqx/jqx.bootstrap.css" rel="stylesheet">|;

    $self->{titlebar} = ($self->{title}) ? "$self->{title} - $self->{titlebar}" : $self->{titlebar};

    $self->{adminlte_template} = 'ext/adminlte/epixerp.html';

    $self->set_cookie($endsession) unless $nocookie;

    print qq|Content-Type: text/html

$self->{pre}
|;
  }
}

1;

