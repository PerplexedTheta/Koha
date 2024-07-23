    use Modern::Perl;
    
    return {
        bug_number  => "36352",
        description => "Allow agreements to have multiple vendors",
        up          => sub {
            my ($args) = @_;
            my ( $dbh, $out ) = @$args{qw(dbh out)};

            unless ( TableExists('erm_agreement_vendors') ) {
                $dbh->do(q{
                    CREATE TABLE `erm_agreement_vendors` (
                        `agreement_vendor_id` INT(11) NOT NULL AUTO_INCREMENT COMMENT 'primary key',
                        `agreement_id` INT(11) NOT NULL COMMENT 'link to the agreement',
                        `vendor_id` INT(11) NOT NULL COMMENT 'link to the license',
                        CONSTRAINT `erm_agreement_vendors_ibfk_1` FOREIGN KEY (`agreement_id`) REFERENCES `erm_agreements` (`agreement_id`) ON DELETE CASCADE ON UPDATE CASCADE,
                        CONSTRAINT `erm_agreement_vendors_ibfk_2` FOREIGN KEY (`vendor_id`) REFERENCES `aqbooksellers` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,                        PRIMARY KEY(`agreement_vendor_id`),
                        UNIQUE KEY `erm_agreement_vendors_uniq` (`agreement_id`, `vendor_id`)
                    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
                });
                say $out "Added new table 'erm_agreement_vendors'";
            }

            $dbh->do(q{
                INSERT IGNORE INTO `erm_agreement_vendors` (`agreement_id`, `vendor_id`) SELECT `agreement_id`, `vendor_id` FROM `erm_agreements`;
            });
            say $out "Copied vendors from 'erm_agreements' into 'erm_agreement_vendors'";

            $dbh->do(q{
                ALTER TABLE `erm_agreements` DROP FOREIGN KEY IF EXISTS `erm_agreements_ibfk_1`;
            });
            say $out "Dropped foreign key 'erm_agreements_ibfk_1'";

            $dbh->do(q{
                ALTER TABLE `erm_agreements` DROP COLUMN IF EXISTS `vendor_id`;
            });
            say $out "Dropped column 'vendor_id` from `erm_agreements`";
        },
}
