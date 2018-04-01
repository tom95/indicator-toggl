
public class NoTokenPage : Gtk.Grid
{
    public signal void finished (string token);

    const string PROFILE_LINK = "https://toggl.com/app/profile";

    Gtk.Entry token_entry;
    Gtk.Label message_label;

    construct
    {
	row_spacing = 12;
	margin = 12;
	orientation = Gtk.Orientation.VERTICAL;

	var link_button = new Gtk.Button.with_label (_("Open Token Page ..."));
	link_button.clicked.connect (() => {
	    Granite.Services.System.open_uri (PROFILE_LINK);
	});

	token_entry = new Gtk.Entry ();
	token_entry.placeholder_text = _("The token ...");
	token_entry.secondary_icon_name = "check-active-symbolic";
	token_entry.secondary_icon_tooltip_text = _("Confirm token");
	token_entry.icon_press.connect (confirm_token);
	token_entry.activate.connect (confirm_token);
	token_entry.text = TogglSettings.get_default ().toggl_api_token;

	var label = new Gtk.Label (_("Please find your Toggl API token via the link below and paste it here."));
	label.wrap = true;
	label.max_width_chars = 40;

	message_label = new Gtk.Label ("");
	message_label.wrap = true;
	message_label.no_show_all = true;
	label.max_width_chars = 40;

	add (new Gtk.Image.from_icon_name ("appointment-symbolic", Gtk.IconSize.DIALOG));
	add (label);
	add (link_button);
	add (token_entry);
	add (message_label);
    }

    void confirm_token ()
    {
	TogglSettings.get_default ().toggl_api_token = token_entry.text;
	finished (token_entry.text);
    }

    public void set_message (string? message)
    {
	message_label.visible = message != null;
	message_label.label = message;
    }
}
