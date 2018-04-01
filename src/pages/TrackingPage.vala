
public class TrackingPage : Gtk.Grid
{
    public signal void authorization_required (string? message);
    public signal void tracking_changed (bool tracking);
    public signal void request_refresh ();

    Gtk.Revealer duration_revealer;
    Gtk.Label duration;
    Gtk.Entry description;
    Gtk.Button toggle_button;
    Gtk.ComboBoxText projects;
    Gtk.ComboBoxText workspaces;
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
	row_spacing = 6;
	margin = 12;
	orientation = Gtk.Orientation.VERTICAL;

	description = new Gtk.Entry ();
	description.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
	description.placeholder_text = _("What's the task?");
	description.hexpand = true;

	projects = new Gtk.ComboBoxText ();
	projects.popup_fixed_width = false;

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
	most_recent_entries.column_spacing = 6;
	most_recent_entries.orientation = Gtk.Orientation.VERTICAL;

	var scroll = new Wingpanel.Widgets.AutomaticScrollBox ();
	scroll.max_height = 200;
	scroll.add (most_recent_entries);

	attach (scroll, 0, 4, 2, 1);

	var bottom_bar = new Gtk.Grid ();
	bottom_bar.column_spacing = 12;
	bottom_bar.orientation = Gtk.Orientation.HORIZONTAL;

	workspaces = new Gtk.ComboBoxText ();
	workspaces.changed.connect (() => {
	    switch_to_workspace (int64.parse (workspaces.active_id));
	});

	var refresh = new Gtk.Button.from_icon_name ("view-refresh-symbolic");
	refresh.hexpand = true;
	refresh.halign = Gtk.Align.END;
	refresh.tooltip_text = _("Refresh data from Toggl");
	refresh.clicked.connect (() => request_refresh ());

	bottom_bar.add (workspaces);
	bottom_bar.add (refresh);

	attach (new Wingpanel.Widgets.Separator (), 0, 5, 2, 1);
	attach (bottom_bar, 0, 6, 2, 1);
    }

    void switch_to_workspace (int64 workspace_id)
    {
	set_projects (user.projects, workspace_id);
	workspaces.active_id = workspace_id.to_string ();
    }

    public void start_tracking ()
    {
	var api = TogglApi.get_default ();
	var project = get_current_project ();
	var workspace = project != null ? project.workspace_id : user.default_workspace_id;

	api.start_time_entry.begin (description.text,
				    {},
				    workspace,
				    int64.parse (projects.active_id), (obj, res) => {
					TogglApi.TimeEntry entry = api.start_time_entry.end (res);
					set_tracking (true);
					set_current_time_entry (entry);
				    });
    }

    public void stop_tracking ()
    {
	description.text = "";
	if (current_time_entry != null)
	    TogglApi.get_default ().stop_time_entry.begin (current_time_entry);
	prepend_most_recent_entry (current_time_entry);
	set_tracking (false);
    }

    void set_tracking (bool _tracking) {
	tracking = _tracking;
	duration_revealer.reveal_child = tracking;
	duration_revealer.visible = tracking;
	toggle_button.set_image (new Gtk.Image.from_icon_name (tracking ? "media-playback-stop" : "media-playback-start", Gtk.IconSize.DIALOG));
	toggle_button.hexpand = !tracking;
	tracking_changed (tracking);
    }

    void set_projects (TogglApi.Project[] _projects, int64 filter_by_workspace = 0)
    {
	projects.remove_all ();
	projects.append ("0", _("- No Project -"));
	projects.active_id = "0";

	foreach (var project in _projects) {
	    if (filter_by_workspace == 0 || filter_by_workspace == project.workspace_id) {
		projects.append (project.id.to_string (), project.name);
	    }
	}
    }

    void set_workspaces (TogglApi.Workspace[] _workspaces, int64 default_workspace_id)
    {
	workspaces.remove_all ();

	foreach (var workspace in _workspaces)
	    workspaces.append (workspace.id.to_string (), workspace.name);

	workspaces.active_id = default_workspace_id.to_string ();
	workspaces.visible = _workspaces.length > 1;
    }

    void prepend_most_recent_entry (TogglApi.TimeEntry entry)
    {
	var label = new Gtk.Label ("%s (%s)".printf (entry.description, format_duration (entry.duration, true)));
	label.use_markup = true;
	label.hexpand = true;
	label.xalign = 0.0f;
	label.ellipsize = Pango.EllipsizeMode.END;

	var resume = new Gtk.Button.from_icon_name ("media-playback-start-symbolic", Gtk.IconSize.MENU);
	resume.relief = Gtk.ReliefStyle.NONE;
	resume.tooltip_text = _("Resume tracking for this entry");
	resume.clicked.connect (() => {
	    resume_time_entry.begin (entry);
	});

	most_recent_entries.insert_row (0);
	most_recent_entries.attach (label, 0, 0, 1, 1);
	most_recent_entries.attach (resume, 1, 0, 1, 1);
	most_recent_entries.show_all ();
    }

    void set_most_recent_entries (TogglApi.TimeEntry[] entries)
    {
	foreach (var child in most_recent_entries.get_children ())
	    child.destroy ();

	foreach (var entry in entries) {
	    // check if this is the current entry
	    if (entry.duration < 0)
		continue;

	    prepend_most_recent_entry (entry);
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
	if (TogglSettings.get_default ().toggl_api_token == "") {
	    authorization_required (null);
	    return false;
	}

	try {
	    user = yield TogglApi.get_default ().me ();
	    set_projects (user.projects, user.default_workspace_id);
	    set_workspaces (user.workspaces, user.default_workspace_id);
	    set_most_recent_entries (user.time_entries);

	    var entry = yield TogglApi.get_default ().current_time_entry ();
	    if (entry != null)
		set_current_time_entry (entry);
	    else
		set_tracking (false);
	} catch (TogglError.AUTHORIZATION_FAILED error) {
	    authorization_required (_("The token appears to be wrong."));
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
	projects.active_id = entry.project_id.to_string ();
	switch_to_workspace (entry.workspace_id);
	set_current_time_entry (new_entry);
    }
}
