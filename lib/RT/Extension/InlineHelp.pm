use strict;
use warnings;
package RT::Extension::InlineHelp;

our $VERSION = '0.01';

RT->AddStyleSheets('inlinehelp.css');
RT->AddJavaScript('inlinehelp.js');

use RT::Config;
$RT::Config::META{ShowInlineHelp} = {
    Section         => 'General',
    Overridable     => 1,
    Description     => 'Show Inline Help',
    Widget          => '/Widgets/Form/Boolean',
    WidgetArguments => {
        Description => 'Show inline help?',                # loc
        Hints       => 'Displays icons for help topics'    # loc
    },
};

{
    use RT::Interface::Web;
    package HTML::Mason::Commands;

    # GetSystemHelpClass locales
    #
    # Given a list of locales, find the best article class that has been associated with the
    # 'RT Help System' custom field. Locales are searched in order. The first Class with an
    # 'RT Help System' custom field and matching 'Locale' custom field will be returned.

    sub GetSystemHelpClass {
        my $locales = shift || ['en'];

        # Find the custom field that indicates a Class is participating in the RT Help System
        my $cf = RT::CustomField->new( RT->SystemUser );
        my ( $ret, $msg ) = $cf->Load("RT Help System");
        unless ( $ret and $cf->Id ) {
            RT::Logger->warn("Could not find custom field for 'RT Help System' $msg");
            return;
        }

        # Loop over the supplied locales in order. Return the first Class that is participating
        # in the RT Help System that also has a matching Locale custom field value
        my $Classes = RT::Classes->new( RT->SystemUser );
        ( $ret, $msg ) = $Classes->LimitCustomField( CUSTOMFIELD => $cf->Id, OPERATOR => "=", VALUE => "yes" );
        if ($ret) {
            for my $locale (@$locales) {
                $Classes->GotoFirstItem;
                while ( my $class = $Classes->Next ) {
                    my $val = $class->FirstCustomFieldValue('Locale');
                    return $class if $val eq $locale;
                }
            }
        }
        else {
            RT::Logger->debug("Could not find a participating help Class $msg");
        }

        # none found
        RT::Logger->debug("Could not find a suitable help Class for locales: @$locales");
        return;
    }

    # GetHelpArticleTitle class_id, article_name
    #
    # Returns the value of the C<"Display Name"> Custom Field of an Article of the given Class.
    # Often, the class_id will come from GetSystemHelpClass, but it does not have to.

    sub GetHelpArticleTitle {
        my $class_id     = shift || return '';    # required
        my $article_name = shift || return '';    # required

        # find the article of the given class
        my $Article = RT::Article->new( RT->SystemUser );
        my ( $ret, $msg ) = $Article->LoadByCols( Name => $article_name, Class => $class_id, Disabled => 0 );
        if ( $Article and $Article->Id ) {
            return $Article->FirstCustomFieldValue('Display Name') || '';
        }

        # no match was found
        RT::Logger->debug("No help article found for '$article_name'");
        return '';
    }

    # GetHelpArticleContent class_id, article_name
    #
    # Returns the raw, unscrubbed and unescaped Content of an Article of the given Class.
    # Often, the class_id will come from GetSystemHelpClass, but it does not have to.

    sub GetHelpArticleContent {
        my $class_id     = shift || return '';    # required
        my $article_name = shift || return '';    # required

        # find the article of the given class
        my $Article = RT::Article->new( RT->SystemUser );
        my ( $ret, $msg ) = $Article->LoadByCols( Name => $article_name, Class => $class_id, Disabled => 0 );
        if ( $Article and $Article->Id ) {
            RT::Logger->debug( "Found help article id: " . $Article->Id );
            return $Article->FirstCustomFieldValue('Content');
        }

        # no match was found
        RT::Logger->debug("No help article found for '$article_name'");
        return '';
    }
}


1;

__END__

=head1 NAME

RT-Extension-InlineHelp - InlineHelp

=head1 DESCRIPTION

This extension supplies the ability to add inline help to RT web pages.

=head1 RT VERSION

Works with RT 5.0

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item C<make initdb>

Only run this the first time you install this module.

If you run this twice, you may end up with duplicate data
in your database.

If you are upgrading this module, check for upgrading instructions
in case changes need to be made to your database.

=item Edit your F</opt/rt5/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::InlineHelp');

To show InlineHelp by default:

    Set($ShowInlineHelp, 1);

=item Clear your mason cache

    rm -rf /opt/rt5/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

=for html <p>All bugs should be reported via email to <a
href="mailto:bug-RT-Extension-InlineHelp@rt.cpan.org">bug-RT-Extension-InlineHelp@rt.cpan.org</a>
or via the web at <a
href="http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-InlineHelp">rt.cpan.org</a>.</p>

=for text
    All bugs should be reported via email to
        bug-RT-Extension-InlineHelp@rt.cpan.org
    or via the web at
        http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-InlineHelp

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Best Practical Solutions, LLC

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
