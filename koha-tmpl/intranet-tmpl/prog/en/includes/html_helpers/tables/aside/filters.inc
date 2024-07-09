[% USE Koha %]
[% USE html %]

[% BLOCK filter_search %]
    <form id="[% ( form_id || form_name || 'search_form' ) | html %]" name="[% ( form_name || form_id || 'search_form' ) | html %]" action="[% ( form_action || '?' ) | html %]" method="[% ( form_method || 'GET' ) | html %]">
        <fieldset class="brief">
            <h3>[% ( form_title || 'Search facets' ) | html %]</h3>
            <ol>
                <li>
                    <label for="[% ( search_input_id || search_input_name || 'search_input' ) | html %]">[% ( search_label || 'Search' ) | html %]</label>
                    <input type="text" id="[% ( search_input_id || search_input_name || 'search_input' ) | html %]" name="[% ( search_input_name || search_id || 'search_input' ) | html %]" placeholder="[% ( search_input_placeholder || '' ) | html %]" value="">
                </li>
                [% content %]
            </ol>
            <fieldset class="action">
                <input type="submit" class="btn btn-primary" id="search_submit" name="[% ( search_submit_name || 'search_submit' ) | html %]" value="[% ( search_submit_value || 'Search' ) | html %]">
                [% IF search_clear_visible %]
                    <input type="reset" class="btn btn-default clear_search" id="search_clear" name="[% ( search_clear_name || 'search_clear' ) | html %]" value="[% ( search_clear_value || 'Clear' ) | html %]">
                [% END %]
            </fieldset>
        </fieldset>
    </form>
[% END %]

[% BLOCK filter_facets %]
    <form id="[% ( form_id || form_name || 'facets_form' ) | html %]" name="[% ( form_name || form_id || 'facets_form' ) | html %]">
        <fieldset class="brief">
            <h3>[% ( form_title || 'Filter results' ) | html %]</h3>
            <ol>
                [% content %]
            </ol>
        </fieldset>
        [% IF facets_clear_visible %]
            <fieldset class="action">
                <input type="reset" class="btn btn-default clear_search" id="facets_clear" name="[% ( facets_clear_name || 'facets_clear' ) | html %]" value="[% ( facets_clear_value || 'Clear' ) | html %]">
            </fieldset>
        [% END %]
    </form>
[% END %]

[% BLOCK filter_select %]
    <li>
        <label for="[% ( id || 'filter_search_select' ) | html %]">[% ( label || 'Unlabelled' ) | html %]</label>
        <select id="[% ( id || 'filter_search_select' ) | html %]">
            [% content %]
        </select>
    </li>
[% END %]
