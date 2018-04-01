
public class TogglMenu : Gtk.Stack
{
    public signal void tracking_changed (bool tracking);

    const string NO_TOKEN_PAGE = "no-token";
    const string TRACKING_PAGE = "tracking";
    const string LOADING_PAGE = "loading";

    TrackingPage tracking_page;
    NoTokenPage no_token_page;

    bool first_open = true;

    construct
    {
	tracking_page = new TrackingPage ();
	tracking_page.tracking_changed.connect (tracking => tracking_changed (tracking));
	tracking_page.authorization_required.connect (message => {
	    show_no_token_page (message);
	});

	no_token_page = new NoTokenPage ();
	no_token_page.finished.connect (() => {
	    try_show_tracking_page ();
	});

	var loading = new Gtk.Spinner ();
	loading.active = true;
	loading.expand = true;
	loading.halign = loading.valign = Gtk.Align.CENTER;

	add_named (no_token_page, NO_TOKEN_PAGE);
	add_named (loading, LOADING_PAGE);
	add_named (tracking_page, TRACKING_PAGE);
    }

    void try_show_tracking_page ()
    {
	visible_child_name = LOADING_PAGE;
	tracking_page.populate.begin ((obj, res) => {
	    bool success = tracking_page.populate.end (res);
	    if (success)
		visible_child_name = TRACKING_PAGE;
	});
    }

    public void maybe_stop_tracking ()
    {
	if (visible_child_name == TRACKING_PAGE)
	    tracking_page.stop_tracking ();
    }

    public void focused ()
    {
	if (first_open) {
	    first_open = false;
	    try_show_tracking_page ();
	}

	tracking_page.shown = true;
    }

    public void hidden ()
    {
	tracking_page.shown = false;
    }

    void show_no_token_page (string? message)
    {
	visible_child_name = NO_TOKEN_PAGE;
	no_token_page.set_message (message);
    }
}
