
public class TrackingPage : Gtk.Grid
{
    public signal void authorization_required ();
    public signal void tracking_changed (bool tracking);

    Gtk.Revealer duration_revealer;
    Gtk.Label duration;
    Gtk.Entry description;
    Gtk.Button toggle_button;
    Gtk.ComboBoxText projects;
    Gtk.Grid most_recent_entries;

    TogglApi.TimeEntry? current_time_entry = null;
    TogglApi.User? user = null;

    bool tracking = false;

    bool _shown = false;
    public bool shown {
	get {
	    return _shown;
	}
	set {
	    if (value && value != _shown)
		Timeout.add (1000, () => {
		    update_duration_label ();
		    return _shown ? Source.CONTINUE : Source.REMOVE;
		});
	    _shown = value;
	}
    }

    construct
    {
	row_spacing = 12;
	margin = 12;
	orientation = Gtk.Orientation.VERTICAL;

	description = new Gtk.Entry ();
	description.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
	description.placeholder_text = _("What's the task?");
	description.hexpand = true;

	projects = new Gtk.ComboBoxText ();

	toggle_button = new Gtk.Button.from_icon_name ("media-playback-start", Gtk.IconSize.DIALOG);
	toggle_button.relief = Gtk.ReliefStyle.NONE;
	toggle_button.hexpand = true;
	toggle_button.halign = Gtk.Align.CENTER;

	duration = new Gtk.Label ("");
	duration.use_markup = true;
	duration.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
	duration.hexpand = true;
	duration.show ();

	duration_revealer = new Gtk.Revealer ();
	duration_revealer.no_show_all = true;
	duration_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
	duration_revealer.transition_duration = 600;
	duration_revealer.add (duration);

	toggle_button.clicked.connect (() => {
	    if (tracking) {
		stop_tracking ();
	    } else {
		start_tracking ();
	    }

	    set_tracking (!tracking);
	});

	attach (description, 0, 0, 2, 1);
	attach (projects, 0, 1, 2, 1);

	var duration_grid = new Gtk.Grid ();
	duration_grid.add (duration_revealer);
	duration_grid.add (toggle_button);
	attach (duration_grid, 0, 2, 1, 1);

	attach (new Wingpanel.Widgets.Separator (), 0, 3, 2, 1);

	most_recent_entries = new Gtk.Grid ();
	most_recent_entries.row_spacing = 6;
	most_recent_entries.orientation = Gtk.Orientation.VERTICAL;
	attach (most_recent_entries, 0, 4, 2, 1);
    }

    public void start_tracking ()
    {
	var api = TogglApi.get_default ();
	api.start_time_entry.begin (description.text,
				    {},
				    get_current_project ().workspace_id,
				    int64.parse (projects.active_id), (obj, res) => {
					TogglApi.TimeEntry entry = api.end (res);
					set_current_time_entry (entry);
				    });
    }

    public void stop_tracking ()
    {
	description.text = "";
	TogglApi.get_default ().stop_time_entry.begin (current_time_entry);
    }

    void set_tracking (bool _tracking) {
	tracking = _tracking;
	duration_revealer.reveal_child = tracking;
	duration_revealer.visible = tracking;
	toggle_button.set_image (new Gtk.Image.from_icon_name (tracking ? "media-playback-stop" : "media-playback-start", Gtk.IconSize.DIALOG));
	toggle_button.hexpand = !tracking;
	tracking_changed (tracking);
    }

    void set_projects (TogglApi.Project[] _projects)
    {
	projects.remove_all ();
	projects.append ("0", _("- No Project -"));

	foreach (var project in _projects)
	    projects.append (project.id.to_string (), project.name);
    }

    void set_most_recent_entries (TogglApi.TimeEntry[] entries)
    {
	foreach (var child in most_recent_entries.get_children ())
	    child.destroy ();

	var row = 0;
	for (var i = entries.length - 1; i >= 0; i--) {
	    var entry = entries[i];
	    // check if this is the current entry
	    if (entry.duration < 0)
		continue;

	    var label = new Gtk.Label ("%s (%s)".printf (entry.description, format_duration (entry.duration, true)));
	    label.use_markup = true;
	    label.hexpand = true;
	    label.xalign = 0.0f;
	    label.ellipsize = Pango.EllipsizeMode.END;

	    var resume = new Gtk.Button.from_icon_name ("media-playback-start-symbolic", Gtk.IconSize.MENU);
	    resume.clicked.connect (() => {
		resume_time_entry.begin (entry);
	    });

	    most_recent_entries.attach (label, 0, row, 1, 1);
	    most_recent_entries.attach (resume, 1, row, 1, 1);
	    row++;
	}

	most_recent_entries.show_all ();
    }

    void set_current_time_entry (TogglApi.TimeEntry entry)
    {
	current_time_entry = entry;

	description.text = entry.description;
	projects.active_id = entry.project_id.to_string ();
	update_duration_label ();

	set_tracking (true);
    }

    TogglApi.Project? get_current_project ()
    {
	var id = int64.parse (projects.active_id);
	foreach (var project in user.projects)
	    if (project.id == id)
		return project;
	return null;
    }

    public async bool populate ()
    {
	if (TogglSettings.get_default ().toggl_api_token == null) {
	    authorization_required ();
	    return false;
	}

	try {
	    user = yield TogglApi.get_default ().me ();
	    set_projects (user.projects);
	    set_most_recent_entries (user.time_entries);

	    var entry = yield TogglApi.get_default ().current_time_entry ();
	    if (entry != null)
		set_current_time_entry (entry);
	} catch (TogglError.AUTHORIZATION_FAILED error) {
	    authorization_required ();
	    return false;
	}

	return true;
    }

    void update_duration_label ()
    {
	if (current_time_entry != null)
	    duration.label = format_duration (current_time_entry.duration, true);
    }

    string format_duration (int64 duration, bool use_markup)
    {
	var total_seconds = duration < 0
	    ? new DateTime.now_local ().to_unix () + duration
	    : duration;

	var hours = (int) (total_seconds / (60 * 60));
	var minutes = (int) ((total_seconds - hours * 60 * 60) / 60);
	var seconds = (int) (total_seconds - hours * 60 * 60 - minutes * 60);

	if (use_markup) {
	    return "%s:%s:%s".printf (
		(hours > 0 ? "<b>%i</b>" : "%i").printf (hours),
		(hours == 0 && minutes > 0 ? "<b>%02i</b>" : "%02i").printf (minutes),
		(hours == 0 && minutes == 0 ? "<b>%02i</b>" : "%02i").printf (seconds));
	} else {
	    return "%i:%02i:%02i".printf ((int) hours, (int) minutes, (int) seconds);
	}
    }

    async void resume_time_entry (TogglApi.TimeEntry entry)
    {
	if (current_time_entry != null)
	    yield TogglApi.get_default ().stop_time_entry (current_time_entry);

	var new_entry = yield TogglApi.get_default ().start_time_entry (entry.description,
							entry.tags,
							entry.workspace_id,
							entry.project_id);
	set_current_time_entry (new_entry);
    }
}
