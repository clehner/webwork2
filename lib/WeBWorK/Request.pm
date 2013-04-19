################################################################################
# WeBWorK Online Homework Delivery System
# Copyright © 2000-2007 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: webwork2/lib/WeBWorK/Request.pm,v 1.10 2007/07/23 04:06:32 sh002i Exp $
# 
# This program is free software; you can redistribute it and/or modify it under
# the terms of either: (a) the GNU General Public License as published by the
# Free Software Foundation; either version 2, or (at your option) any later
# version, or (b) the "Artistic License" which comes with this package.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See either the GNU General Public License or the
# Artistic License for more details.
################################################################################

package WeBWorK::Request;

=head1 NAME

WeBWorK::Request - a request to the WeBWorK system, a subclass of
Apache::Request with additional WeBWorK-specific fields.

=cut

use strict;
use warnings;

use Nginx::Simple;
use WeBWorK::Localize;

# This class inherits from Apache::Request under mod_perl and Apache2::Request under mod_perl2 and Nginx::Simple under nginx
BEGIN {
    push @WeBWorK::Request::ISA, "WeBWorK::Localize";

	require Nginx::Simple;
	Nginx::Simple->import;
	push @WeBWorK::Request::ISA, "Nginx::Simple";
}

=head1 CONSTRUCTOR

=over

=item new(@args)

Creates an new WeBWorK::Request. All arguments are passed to Apache::Request's
constructor. You must specify at least an Apache request_rec object.

=for comment

From: http://search.cpan.org/~joesuf/libapreq-1.3/Request/Request.pm#SUBCLASSING_Apache::Request

If the instances of your subclass are hash references then you can actually
inherit from Apache::Request as long as the Apache::Request object is stored in
an attribute called "r" or "_r". (The Apache::Request class effectively does the
delegation for you automagically, as long as it knows where to find the
Apache::Request object to delegate to.)

=cut

sub new {
	my ($invocant, @args) = @_;
	my $class = ref $invocant || $invocant;
	# construct the appropriate superclass instance depending on mod_perl version
	return bless $args[0], $class;
	#return bless { r => $apreq_class->new(@args) }, $class;
}

=back

=cut

=head1 METHODS

=over

=item ce([$new])

Return the course environment (WeBWorK::CourseEnvironment) associated with this
request. If $new is specified, set the course environment to $new before
returning the value.

=cut

sub ce {
	my $self = shift;
	$self->{ce} = shift if @_;
	return $self->{ce};
}

=item db([$new])

Return the database (WeBWorK::DB) associated with this request. If $new is
specified, set the database to $new before returning the value.

=cut

sub db {
	my $self = shift;
	$self->{db} = shift if @_;
	return $self->{db};
}

=item authen([$new])

Return the authenticator (WeBWorK::Authen) associated with this request. If $new
is specified, set the authenticator to $new before returning the value.

=cut

sub authen {
	my $self = shift;
	$self->{authen} = shift if @_;
	return $self->{authen};
}

=item authz([$new])

Return the authorizer (WeBWorK::Authz) associated with this request. If $new is
specified, set the authorizer to $new before returning the value.

=cut

sub authz {
	my $self = shift;
	$self->{authz} = shift if @_;
	return $self->{authz};
}

=item urlpath([$new])

Return the URL path (WeBWorK::URLPath) associated with this request. If $new is
specified, set the URL path to $new before returning the value.

=cut

sub urlpath {
	my $self = shift;
	$self->{urlpath} = shift if @_;
	return $self->{urlpath};
}

sub language_handle {
	my $self = shift;
	$self->{language_handle} = shift if @_;
	return $self->{language_handle};
}

sub maketext {
	my $self = shift;
	# $self->{language_handle}->maketext(@_);
	&{ $self->{language_handle} }(@_);
}

=item location()

Overrides the location() method in Apache::Request (or Apache2::Request) so that
if the location is "/", the empty string is returned.

=cut

sub location {
	my $self = shift;
	#my $location = $self->SUPER::location;
	my $location = $self->uri;
	return $location eq "/" ? "" : $location;
}

=item dir_config()

Get config variables.
In Apache there are passed through from the config file.
In nginx I haven't figured out how to do that, so they are sitting here.

=cut

sub dir_config {
	#my $self = shift;
	return {
		webwork_url         => "/webwork",
		webwork_dir         => "/opt/webwork/webwork2",
		pg_dir              => "/opt/webwork/pg",
		webwork_htdocs_url  => "/webwork_files",
		webwork_htdocs_dir  => "/opt/webwork/webwork2/htdocs",
		webwork_courses_url => "/webwork_course_files",
		webwork_courses_dir => "/opt/webwork/courses",
	};
}

=item dir_config()

Get and set notes about the request. This is implemented in Apache::Request but
not in Nginx::Simple, so we have it here.

=cut

# based on code from mutable_param

sub notes {
	my $self = shift;
	
	if (not defined $self->{notescache}) {
		$self->{notescache} = {};
	}
	
	@_ or return keys %{$self->{notescache}};
	
	my $name = shift;
	if (@_) {
		my $val = shift;
		if (ref $val eq "ARRAY") {
			$self->{notescache}{$name} = [@$val]; # make a copy
		} else {
			$self->{notescache}{$name} = [$val];
		}
	}
	return unless exists $self->{notescache}{$name};
	return wantarray ? @{$self->{notescache}{$name}} : $self->{notescache}{$name}->[0];
}

=item post_connection([$arg])

Register a cleanup handler.
Currently only one handlers can be registered.

=cut

sub post_connection {
	my ($self, $code) = @_;
	#push @{$$self{'PerlCleanupHandler'}}, $code;
	#todo: allow multiple handlers
	$self->cleanup = \&code;
}


=back

=cut

1;

