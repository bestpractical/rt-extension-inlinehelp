// a list of entries to process for the page
var pagePopupHelpItems = [
    { selector: "[data-help]" }  // by default, anything with data-help attributes gets processed
];

if ( RT.CurrentUser.InlineHelp ) {
    pagePopupHelpItems = pagePopupHelpItems.concat(RT.CurrentUser.InlineHelp);
}

// add one or more items to the list of help entries to process for the page
function addPopupHelpItems() {
    pagePopupHelpItems = pagePopupHelpItems.concat([].slice.call(arguments));
}

function helpify($els, item={}, options={}) {
    $els.each(function(index) {
        const $el = jQuery(this);
        const action = $el.data("action") || item.action || options.action;
        const title = $el.data("help") || $el.data("title") || item.title;
        const content = $el.data("content") || item.content;
        switch(action) {
            case "before":
                $el.before( buildPopupHelpHtml( title, content ) );
                break;
            case "after":
                $el.after( buildPopupHelpHtml( title, content ) );
                break;
            case "prepend":
                $el.prepend( buildPopupHelpHtml( title, content ) );
                break;
            case "replace":
                $el.replaceWith( buildPopupHelpHtml( title, content ) );
                break;
            case "append":
            default:
                $el.append( buildPopupHelpHtml( title, content ) );
        }
    })
}

function buildPopupHelpHtml(title, content) {
    const contentAttr = content ? ' data-content="' + content + '" ' : '';
    return '<span class="popup-help" tabindex="0" role="button" data-toggle="popover" title="' + title + '" data-trigger="hover" ' + contentAttr + '><span class="far fa-question-circle"></span></span>';
}

// Dynamically load the help topic corresponding to a DOM element using AJAX
// Should be called with the DOM element as the 'this' context of the function,
// making it directly compatible with the 'content' property of the popper.js
// popover() method, which is its primary purpose
const popupHelpAjax = function() {
    const $el = jQuery(this);
    var content = $el.data("content");
    if (content) {
        return content;
    } else {
        const buildUrl = function(title) { return RT.Config.WebHomePath + "/Helpers/HelpTopic?title=" + encodeURIComponent(title) };
        const title = $el.data("help") || $el.data("title") || $el.data("original-title");
        jQuery.ajax({
            url: buildUrl(title),
            dataType: "json",
            success: function(response, statusText, xhr) {
                $el.data('content', response.content);
                $el.popover('show');
            },
            error: function(e) {
                return "<div class='text-danger'>Error loading help for '" + title + "': " + e + "</div>";
            }
        })
        return RT.I18N.Catalog.loading;
    }
}

// render all the help icons and popover-ify them
function renderPopupHelpItems( list ) {
    list = list || pagePopupHelpItems;
    if (list && Array.isArray(list) && list.length) {
        list.forEach(function(entry) {
            helpify(jQuery(entry.selector), entry);
        });
        jQuery('[data-toggle="popover"]').popover({
            trigger: 'hover',
            html: true,
            content: popupHelpAjax
        });
    }
}
