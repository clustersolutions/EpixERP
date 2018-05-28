#=====================================================================
# Epix ERP
# Copyright (c) Cluster Solutions
#
#  Author: Cluster Solutions
#     Web: http://www.clustersolutions.net
#
#======================================================================
#
# Customized print_from routine to update Epixcommerce order status.
#
#======================================================================

1;
# end of main

sub print_form {
  my ($oldform) = @_;

  $inv = "inv";
  $due = "due";

  $numberfld = "sinumber";

  $display_form = ($form->{display_form}) ? $form->{display_form} : "display_form";

  if (! ($form->{copies} = abs($form->{copies}))) {
    $form->{copies} = 1;
  }

  for (qw(name email)) { $form->{"user$_"} = $myconfig{$_} }

  if ($form->{formname} eq 'invoice') {
    $form->{label} = $locale->text('Invoice');
  }
  if ($form->{formname} eq 'vendor_invoice') {
    $form->{label} = $locale->text('Invoice');
    $numberfld = "vinumber";
  }
  if ($form->{formname} eq 'debit_invoice') {
    $form->{label} = $locale->text('Debit Invoice');
  }
  if ($form->{formname} eq 'credit_invoice') {
    $form->{label} = $locale->text('Credit Invoice');
  }
  if ($form->{formname} eq 'sales_order') {
    $inv = "ord";
    $due = "req";
    $form->{label} = $locale->text('Sales Order');
    $numberfld = "sonumber";
    $order = 1;
  }
  if ($form->{formname} eq 'work_order') {
    $inv = "ord";
    $due = "req";
    $form->{label} = $locale->text('Work Order');
    $numberfld = "sonumber";
    $order = 1;
  }
  if ($form->{formname} eq 'packing_list') {
    # we use the same packing list as from an invoice
    $form->{label} = $locale->text('Packing List');

    # Update oscommere order no. to process statu for shipping. Sales invoice packing list only...
    if ($form->{type} =~ /invoice/ && $form->{vc} eq 'customer') {
      ($sb, $sb_ordnumber) = split('-', $form->{ordnumber});
        if ($sb eq 'SB') {
          system("/usr/bin/ssh localhost /home/epix/local/bin/update_to_process $sb_ordnumber");
        }
    }

    if ($form->{type} =~ /invoice/) {
      $numberfld = "vinumber" if $form->{vc} eq 'vendor';
    } else {
      $inv = "ord";
      $due = "req";
      $numberfld = "sonumber";
      $order = 1;
    }
  }
  if ($form->{formname} eq 'pick_list') {
    $form->{label} = $locale->text('Pick List');
    if ($form->{type} =~ /invoice/) {
      $numberfld = "vinumber" if $form->{vc} eq 'vendor';
    } else {
      $inv = "ord";
      $due = "req";
      $order = 1;
      $numberfld = "sonumber";
    }
  }
  if ($form->{formname} eq 'purchase_order') {
    $inv = "ord";
    $due = "req";
    $form->{label} = $locale->text('Purchase Order');
    $numberfld = "ponumber";
    $order = 1;
  }
  if ($form->{formname} eq 'barcode') {
    if ($form->{type} =~ /invoice/) {
      $numberfld = "vinumber" if $form->{vc} eq 'vendor';
    } elsif ($form->{type} =~ /order/) {
      $inv = "ord";
      $due = "req";
      $form->{label} = $locale->text('Barcode');
      $numberfld = "ponumber";
      $order = 1;
    }
  }
  if ($form->{formname} eq 'bin_list') {
    $form->{label} = $locale->text('Bin List');
    if ($form->{type} =~ /invoice/) {
      $numberfld = "vinumber" if $form->{vc} eq 'vendor';
    } else {
      $inv = "ord";
      $due = "req";
      $numberfld = "ponumber";
      $order = 1;
    }
  }
  if ($form->{formname} eq 'sales_quotation') {
    $inv = "quo";
    $due = "req";
    $form->{label} = $locale->text('Quotation');
    $numberfld = "sqnumber";
    $order = 1;
  }
  if ($form->{formname} eq 'request_quotation') {
    $inv = "quo";
    $due = "req";
    $form->{label} = $locale->text('Quotation');
    $numberfld = "rfqnumber";
    $order = 1;
  }

  $form->{"${inv}date"} = $form->{transdate};

  $form->isblank("email", "$form->{$form->{vc}} : ".$locale->text('E-mail address missing!')) if ($form->{media} eq 'email');
  $form->isblank("${inv}date", $locale->text($form->{label} .' Date missing!'));

  # get next number
  if (! $form->{"${inv}number"}) {
    $form->{"${inv}number"} ||= '-';
    if ($form->{media} ne 'screen') {
      $form->{"${inv}number"} = $form->update_defaults(\%myconfig, $numberfld);
    }
  }


# $locale->text('Invoice Number missing!')
# $locale->text('Invoice Date missing!')
# $locale->text('Packing List Number missing!')
# $locale->text('Packing List Date missing!')
# $locale->text('Order Number missing!')
# $locale->text('Order Date missing!')
# $locale->text('Quotation Number missing!')
# $locale->text('Quotation Date missing!')

  AA->company_details(\%myconfig, \%$form);

  @f = ();
  foreach $i (1 .. $form->{rowcount}) {
    push @f, map { "${_}_$i" } qw(partnumber description projectnumber partsgroup partsgroupcode serialnumber ordernumber customerponumber bin unit itemnotes package);
  }
  for (split / /, $form->{taxaccounts}) { push @f, "${_}_description" }

  $ARAP = ($form->{vc} eq 'customer') ? "AR" : "AP";
  push @f, $ARAP;

  # format payment dates
  for $i (1 .. $form->{paidaccounts} - 1) {
    if (exists $form->{longformat}) {
      $form->{"datepaid_$i"} = $locale->date(\%myconfig, $form->{"datepaid_$i"}, $form->{longformat});
    }

    push @f, "${ARAP}_paid_$i", "source_$i", "memo_$i";
  }
  $form->format_string(@f);

  for (qw(employee warehouse paymentmethod)) { ($form->{$_}, $form->{"${_}_id"}) = split /--/, $form->{$_} };

  # this is a label for the subtotals
  $form->{groupsubtotaldescription} = $locale->text('Subtotal') if not exists $form->{groupsubtotaldescription};
  delete $form->{groupsubtotaldescription} if $form->{deletegroupsubtotal};

  $duedate = $form->{"${due}date"};

  # create the form variables
  if ($order) {
    OE->order_details(\%myconfig, \%$form);
  } else {
    if ($form->{vc} eq 'customer') {
      IS->invoice_details(\%myconfig, \%$form);
    } else {
      IR->invoice_details(\%myconfig, \%$form);
    }
  }

  if ($form->{formname} eq 'remittance_voucher') {
    $form->isblank("dcn", qq|$form->{"${ARAP}_paid_$form->{paidaccounts}"} : |.$locale->text('DCN missing!'));
    $form->isblank("rvc", qq|$form->{"${ARAP}_paid_$form->{paidaccounts}"} : |.$locale->text('RVC missing!'));
  }

  $form->fdld(\%myconfig, \%$locale);

  if (exists $form->{longformat}) {
    for ("${inv}date", "${due}date", "shippingdate", "transdate") { $form->{$_} = $locale->date(\%myconfig, $form->{$_}, $form->{longformat}) }
  }

  @f = qw(email name address1 address2 city state zipcode country contact phone fax);

  $fillshipto = 1;
  # check for shipto
  foreach $item (@f) {
    if ($form->{"shipto$item"}) {
      $fillshipto = 0;
      last;
    }
  }

  if ($fillshipto) {
    $fillshipto = 0;
    $fillshipto = 1 if $form->{formname} =~ /(credit_invoice|purchase_order|request_quotation|bin_list)/;
    $fillshipto = 1 if ($form->{type} eq 'invoice' && $form->{vc} eq 'vendor');

    $form->{shiptophone} = $form->{tel};
    $form->{shiptofax} = $form->{fax};
    $form->{shiptocontact} = $form->{employee};

    if ($fillshipto) {
      if ($form->{warehouse}) {
	$form->{shiptoname} = $form->{company};
	for (qw(address1 address2 city state zipcode country)) {
	  $form->{"shipto$_"} = $form->{"warehouse$_"};
	}
      } else {
	# fill in company address
	$form->{shiptoname} = $form->{company};
	$form->{shiptoaddress1} = $form->{address};
      }
    } else {
      for (@f) { $form->{"shipto$_"} = $form->{$_} }
      for (qw(phone fax)) { $form->{"shipto$_"} = $form->{"$form->{vc}$_"} }
    }
  }

  # remove email
  shift @f;

  # some of the stuff could have umlauts so we translate them
  push @f, qw(contact shippingpoint shipvia notes intnotes employee warehouse paymentmethod);
  push @f, map { "shipto$_" } qw(name address1 address2 city state zipcode country contact email phone fax);
  push @f, qw(firstname lastname salutation contacttitle occupation mobile);

  push @f, ("${inv}number", "${inv}date", "${due}date", "${inv}description");

  push @f, qw(company address tel fax businessnumber username useremail);

  for (qw(notes intnotes)) { $form->{$_} =~ s/^\s+//g }

  # before we format replace <%var%>
  for ("${inv}description", "notes", "intnotes", "message") { $form->{$_} =~ s/<%(.*?)%>/$fld = lc $1; $form->{$fld}/ge }

  $form->format_string(@f);

  $form->{templates} = "$templates/$myconfig{dbname}";
  $form->{IN} = "$form->{formname}.$form->{format}";

  if ($form->{format} =~ /(ps|pdf)/) {
    $form->{IN} =~ s/$&$/tex/;
  }

  $form->{pre} = "<body bgcolor=#ffffff>\n<pre>" if $form->{format} eq 'txt';

  if ($form->{media} !~ /(screen|queue|email)/) {
    $form->{OUT} = qq~| $form->{"$form->{media}_printer"}~;

    $form->{OUT} =~ s/<%(fax)%>/<%$form->{vc}$1%>/;
    $form->{OUT} =~ s/<%(.*?)%>/$form->{$1}/g;

    if ($form->{printed} !~ /$form->{formname}/) {

      $form->{printed} .= " $form->{formname}";
      $form->{printed} =~ s/^ //;

      $form->update_status(\%myconfig);
    }

    %audittrail = ( tablename	=> ($order) ? 'oe' : lc $ARAP,
                    reference	=> $form->{"${inv}number"},
		    formname	=> $form->{formname},
		    action	=> 'printed',
		    id		=> $form->{id} );

    if (%$oldform) {
      $oldform->{printed} = $form->{printed};
      $oldform->{audittrail} .= $form->audittrail("", \%myconfig, \%audittrail);
    }

  }

  if ($form->{media} eq 'email') {

    $form->{subject} = qq|$form->{label} $form->{"${inv}number"}| unless $form->{subject};

    $form->{plainpaper} = 1;
    $form->{OUT} = "$sendmail";

    if ($form->{emailed} !~ /$form->{formname}/) {
      $form->{emailed} .= " $form->{formname}";
      $form->{emailed} =~ s/^ //;

      # save status
      $form->update_status(\%myconfig);
    }

    $now = scalar localtime;
    $cc = $locale->text('Cc').qq|: $form->{cc}\n| if $form->{cc};
    $bcc = $locale->text('Bcc').qq|: $form->{bcc}\n| if $form->{bcc};

    %audittrail = ( tablename	=> ($order) ? 'oe' : lc $ARAP,
                    reference	=> $form->{"${inv}number"},
		    formname	=> $form->{formname},
		    action	=> 'emailed',
		    id		=> $form->{id} );

    if (%$oldform) {
      $oldform->{intnotes} = qq|$oldform->{intnotes}\n\n| if $oldform->{intnotes};
      $oldform->{intnotes} .= qq|[email]\n|
      .$locale->text('Date').qq|: $now\n|
      .$locale->text('To').qq|: $form->{email}\n${cc}${bcc}|
      .$locale->text('Subject').qq|: $form->{subject}\n|;

      $oldform->{intnotes} .= qq|\n|.$locale->text('Message').qq|: |;
      $oldform->{intnotes} .= ($form->{message}) ? $form->{message} : $locale->text('sent');

      $oldform->{message} = $form->{message};
      $oldform->{emailed} = $form->{emailed};

      $oldform->save_intnotes(\%myconfig, ($order) ? 'oe' : lc $ARAP);

      $oldform->{audittrail} .= $form->audittrail("", \%myconfig, \%audittrail);
    }

  }


  if ($form->{media} eq 'queue') {

    %queued = split / /, $form->{queued};

    if ($filename = $queued{$form->{formname}}) {
      $form->{queued} =~ s/$form->{formname} $filename//;
      unlink "$spool/$myconfig{dbname}/$filename";
      $filename =~ s/\..*$//g;
    } else {
      $filename = time;
      $filename .= int rand 10000;
    }

    $filename .= ".$form->{format}";
    $form->{OUT} = ">$spool/$myconfig{dbname}/$filename";

    $form->{queued} .= " $form->{formname} $filename";
    $form->{queued} =~ s/^ //;

    # save status
    $form->update_status(\%myconfig);

    %audittrail = ( tablename   => ($order) ? 'oe' : lc $ARAP,
		    reference   => $form->{"${inv}number"},
		    formname    => $form->{formname},
		    action      => 'queued',
		    id          => $form->{id} );

    if (%$oldform) {
      $oldform->{queued} = $form->{queued};
      $oldform->{audittrail} .= $form->audittrail("", \%myconfig, \%audittrail);
    }

  }

  $form->{fileid} = $form->{"${inv}number"};
  $form->{fileid} =~ s/(\s|\W)+//g;

  $form->format_string(qw(email cc bcc));

  $form->parse_template(\%myconfig, $userspath) if $form->{copies};


  # if we got back here restore the previous form
  if (%$oldform) {

    $oldform->{"${inv}number"} = $form->{"${inv}number"};
    $oldform->{dcn} = $form->{dcn};

    # restore and display form
    for (keys %$oldform) { $form->{$_} = $oldform->{$_} }
    delete $form->{pre};

    $form->{rowcount}--;

    &{ "$display_form" };

  }

}
