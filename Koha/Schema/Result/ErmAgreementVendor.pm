use utf8;
package Koha::Schema::Result::ErmAgreementVendor;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Koha::Schema::Result::ErmAgreementVendor

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<erm_agreement_vendors>

=cut

__PACKAGE__->table("erm_agreement_vendors");

=head1 ACCESSORS

=head2 agreement_vendor_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

primary key

=head2 agreement_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

link to the agreement

=head2 vendor_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

link to the license

=cut

__PACKAGE__->add_columns(
  "agreement_vendor_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "agreement_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "vendor_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</agreement_vendor_id>

=back

=cut

__PACKAGE__->set_primary_key("agreement_vendor_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<erm_agreement_vendors_uniq>

=over 4

=item * L</agreement_id>

=item * L</vendor_id>

=back

=cut

__PACKAGE__->add_unique_constraint("erm_agreement_vendors_uniq", ["agreement_id", "vendor_id"]);

=head1 RELATIONS

=head2 agreement

Type: belongs_to

Related object: L<Koha::Schema::Result::ErmAgreement>

=cut

__PACKAGE__->belongs_to(
  "agreement",
  "Koha::Schema::Result::ErmAgreement",
  { agreement_id => "agreement_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 vendor

Type: belongs_to

Related object: L<Koha::Schema::Result::Aqbookseller>

=cut

__PACKAGE__->belongs_to(
  "vendor",
  "Koha::Schema::Result::Aqbookseller",
  { id => "vendor_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2024-07-22 15:28:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vKotR7Ctr7xt/XNGlQyV3A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
