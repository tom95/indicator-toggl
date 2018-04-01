
public class TogglSettings : Granite.Services.Settings
{
    private static TogglSettings? instance = null;

    public static TogglSettings get_default ()
    {
	if (instance == null)
	    instance = new TogglSettings ();
	return instance;
    }

    public string toggl_api_token { get; set; }

    private TogglSettings ()
    {
	base ("com.github.tom95.indicator-toggl");
    }
}
