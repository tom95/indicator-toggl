
string[] json_array_to_string_array (Json.Array source)
{
    var dest = new string[source.get_length ()];
    for (var i = 0; i < source.get_length (); i++)
	dest[i] = source.get_string_element (i);
    return dest;
}

DateTime? json_date_to_date_time (string date)
{
    var tv = TimeVal ();
    tv.from_iso8601 (date);

    return new DateTime.from_timeval_local (tv);
}

string date_time_to_json (DateTime date_time) {
    TimeVal tv;
    date_time.to_timeval (out tv);

    return tv.to_iso8601 ();
}

TogglApi.Project[] json_array_to_project_array (Json.Array source) {
    var dest = new TogglApi.Project[source.get_length ()];
    for (var i = 0; i < source.get_length (); i++)
	dest[i] = new TogglApi.Project.from_json (source.get_object_element (i));
    return dest;
}

TogglApi.Tag[] json_array_to_tag_array (Json.Array source) {
    var dest = new TogglApi.Tag[source.get_length ()];
    for (var i = 0; i < source.get_length (); i++)
	dest[i] = new TogglApi.Tag.from_json (source.get_object_element (i));
    return dest;
}

TogglApi.Workspace[] json_array_to_workspace_array (Json.Array source) {
    var dest = new TogglApi.Workspace[source.get_length ()];
    for (var i = 0; i < source.get_length (); i++)
	dest[i] = new TogglApi.Workspace.from_json (source.get_object_element (i));
    return dest;
}

TogglApi.TimeEntry[] json_array_to_time_entry_array (Json.Array source) {
    var dest = new TogglApi.TimeEntry[source.get_length ()];
    for (var i = 0; i < source.get_length (); i++)
	dest[i] = new TogglApi.TimeEntry.from_json (source.get_object_element (i));
    return dest;
}

public errordomain TogglError {
    AUTHORIZATION_FAILED
}


public class TogglApi {
    public const string CLIENT_IDENTIFIER = "Toggl Indicator";

    public class TimeEntry {
	public string? description;
	public int64 id;
	public int64 workspace_id;
	public int64 project_id;
	public int64 task_id;
	public bool billable = false;
	public DateTime start;
	public DateTime? stop;
	public int64 duration;
	public string? created_with;
	public string[]? tags;
	public bool duration_only = false;
	public int64 last_update;

	public TimeEntry.from_json (Json.Object node)
	{
	    description = node.has_member ("description") ? node.get_string_member ("description") : null;
	    id = node.get_int_member ("id");
	    workspace_id = node.has_member ("wid") ? node.get_int_member ("wid") : 0;
	    project_id = node.has_member ("pid") ? node.get_int_member ("pid") : 0;
	    task_id = node.has_member ("tid") ? node.get_int_member ("tid") : 0;
	    billable = node.has_member ("billable") ? node.get_boolean_member ("billable") : false;
	    start = json_date_to_date_time (node.get_string_member ("start"));
	    stop = node.has_member ("stop") ? json_date_to_date_time (node.get_string_member ("stop")) : null;
	    duration = node.get_int_member ("duration");
	    created_with = node.has_member ("created_with") ? node.get_string_member ("created_with") : null;
	    tags = node.has_member ("tags") ? json_array_to_string_array (node.get_array_member ("tags")) : null;
	    duration_only = node.has_member ("duronly") ? node.get_boolean_member ("duronly") : false;
	    last_update = node.get_int_member ("at");
	}

	public TimeEntry (string _description, DateTime _start, int64 _workspace_id) {
	    description = _description;
	    start = _start;
	    workspace_id = _workspace_id;
	    created_with = CLIENT_IDENTIFIER;
	}

	public string to_json_string ()
	{
	    var generator = new Json.Generator ();
	    generator.set_root (to_json ());
	    return generator.to_data (null);
	}

	public Json.Node to_json ()
	{
	    var builder = new Json.Builder ()
		.begin_object ()
		.set_member_name ("time_entry")
		.begin_object ()
		.set_member_name ("id").add_int_value (id)
		.set_member_name ("billable").add_boolean_value (billable)
		.set_member_name ("start").add_string_value (date_time_to_json (start))
		.set_member_name ("duration").add_int_value (duration)
		.set_member_name ("duronly").add_boolean_value (duration_only)
		.set_member_name ("at").add_int_value (last_update);

	    if (description != null)
		builder.set_member_name ("description").add_string_value (description);
	    if (stop != null)
		builder.set_member_name ("stop").add_string_value (date_time_to_json (stop));
	    if (workspace_id != 0)
		builder.set_member_name ("wid").add_int_value (workspace_id);
	    if (project_id != 0)
		builder.set_member_name ("pid").add_int_value (project_id);
	    if (task_id != 0)
		builder.set_member_name ("tid").add_int_value (task_id);
	    if (created_with != null)
		builder.set_member_name ("created_with").add_string_value (created_with);
	    if (tags != null) {
		builder.set_member_name ("tags").begin_array ();
		foreach (var tag in tags)
		    builder.add_string_value (tag);
		builder.end_array ();
	    }

	    builder.end_object ().end_object ();

	    return builder.get_root ();
	}
    }

    public class User
    {
	public int64 default_workspace_id;
	public Project[] projects;
	public Tag[] tags;
	public Workspace[] workspaces;
	public TimeEntry[] time_entries;

	public User.from_json (Json.Object obj)
	{
	    default_workspace_id = obj.get_int_member ("default_wid");
	    projects = json_array_to_project_array (obj.get_array_member ("projects"));
	    workspaces = json_array_to_workspace_array (obj.get_array_member ("workspaces"));
	    tags = json_array_to_tag_array (obj.get_array_member ("tags"));
	    time_entries = json_array_to_time_entry_array (obj.get_array_member ("time_entries"));
	}

	public Workspace? get_default_workspace ()
	{
	    foreach (var workspace in workspaces)
		if (workspace.id == default_workspace_id)
		    return workspace;

	    if (workspaces.length > 0)
		return workspaces[0];

	    return null;
	}
    }

    public class Workspace
    {
	public int64 id;
	public string name;

	public Workspace.from_json (Json.Object obj)
	{
	    id = obj.get_int_member ("id");
	    name = obj.get_string_member ("name");
	}
    }

    public class Tag
    {
	public int64 id;
	public int64 workspace_id;
	public string name;

	public Tag.from_json (Json.Object obj)
	{
	    id = obj.get_int_member ("id");
	    workspace_id = obj.get_int_member ("wid");
	    name = obj.get_string_member ("name");
	}
    }

    public class Project
    {
	public int64 id;
	public int64 workspace_id;
	public string name;
	public bool active;
	public string color;

	public Project.from_json (Json.Object obj)
	{
	    id = obj.get_int_member ("id");
	    workspace_id = obj.get_int_member ("wid");
	    name = obj.get_string_member ("name");
	    color = obj.get_string_member ("color");
	    active = obj.get_boolean_member ("active");
	}
    }

    private static TogglApi? instance = null;

    public static TogglApi get_default ()
    {
	if (instance == null)
	    instance = new TogglApi ();
	return instance;
    }

    const string API_PREFIX = "https://www.toggl.com/api/v8";

    public async User? me () throws TogglError
    {
	var obj = yield authenticated_request ("GET", "/me?with_related_data=true");
	return obj != null ? new User.from_json (obj) : null;
    }

    public async TimeEntry? current_time_entry () throws TogglError
    {
	return yield authenticated_request_for_time_entry ("GET", "/time_entries/current");
    }

    public async TimeEntry? start_time_entry (string description, string[] tags, int64 workspace_id, int64 project_id) throws TogglError
    {
	var time_entry = new TimeEntry (description, new DateTime.now_local (), workspace_id);
	time_entry.tags = tags;
	time_entry.project_id = project_id;

	return yield authenticated_request_for_time_entry ("POST", "/time_entries/start", time_entry.to_json_string ());
    }

    public async TimeEntry? stop_time_entry (TimeEntry stop) throws TogglError
    {
	return yield authenticated_request_for_time_entry ("PUT", "/time_entries/" + stop.id.to_string () + "/stop");
    }

    private async TimeEntry? authenticated_request_for_time_entry (string method, string url, string? body = null) throws TogglError
    {
	var obj = yield authenticated_request (method, url, body);
	return obj != null ? new TimeEntry.from_json (obj) : null;
    }

    private async Json.Object? authenticated_request (string method, string url, string? body = null) throws TogglError
    {
	var session = new Soup.Session ();

	var auth = TogglSettings.get_default ().toggl_api_token + ":api_token";
	var message = new Soup.Message (method, API_PREFIX + url);
	message.request_headers.append ("Authorization", "Basic " + Base64.encode (auth.data));
	message.request_headers.append ("Content-Type", "application/json");
	if (body != null)
	    message.request_body.append_take (body.data);

	Json.Node? root = null;
	var auth_failed = false;

	session.queue_message (message, (session, res) => {
	    if (res.status_code == 403) {
		auth_failed = true;
		authenticated_request.callback ();
		return;
	    }

	    var parser = new Json.Parser ();
	    try {
		if (res.response_body.data != null) {
		    parser.load_from_data ((string) res.response_body.data);
		    root = parser.get_root ();
		}
	    } catch (Error e) {
		warning ("Failed to decode toggl answer: %s (%s)", e.message, (string) res.response_body.data);
	    }

	    authenticated_request.callback ();
	});

	yield;

	if (auth_failed) {
	    throw new TogglError.AUTHORIZATION_FAILED ("Authorization failed");
	}

	if (root != null)
	    return root.get_object ().get_object_member ("data");
	else
	    return null;
    }
}
