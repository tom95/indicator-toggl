/*
 * Copyright (C) 2018 Tom Beckmann <tomjonabc@gmail>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by Tom Beckmann <tomjonabc@gmail>
 *
 */

public class TogglIndicator : Wingpanel.Indicator
{
    private Wingpanel.Widgets.OverlayIcon? indicator_icon = null;
    private TogglMenu? popover_widget = null;

    const string CODE_NAME = "com.github.tom95.indicator-toggl";

    public TogglIndicator (Wingpanel.IndicatorManager.ServerType server_type) {
	Object (code_name: CODE_NAME,
		display_name: _("Toggl"),
		description: _("Toggl Indicator"));

	indicator_icon = new Wingpanel.Widgets.OverlayIcon ("appointment-symbolic");
	indicator_icon.button_press_event.connect (e => {
	    if (e.button == Gdk.BUTTON_MIDDLE && popover_widget != null) {
		popover_widget.maybe_stop_tracking ();
		return Gdk.EVENT_STOP;
	    }
	    return Gdk.EVENT_PROPAGATE;
	});
    }

    public override Gtk.Widget get_display_widget () {
	return indicator_icon;
    }

    public override Gtk.Widget? get_widget () {
	if (popover_widget == null) {
	    popover_widget = new TogglMenu ();
	    popover_widget.tracking_changed.connect ((tracking) => {
		indicator_icon.set_main_icon_name (tracking
						   ? "appointment-missed-symbolic"
						   : "appointment-symbolic");
	    });
	}

	visible = true;

	return popover_widget;
    }

    public override void opened () {
	if (popover_widget != null) {
	    popover_widget.focused ();
	}
    }

    public override void closed () {
	if (popover_widget != null) {
	    popover_widget.hidden ();
	}
    }
}

public Wingpanel.Indicator? get_indicator (Module module, Wingpanel.IndicatorManager.ServerType server_type) {
    debug ("Activating Toggl Indicator");

    var indicator = new TogglIndicator (server_type);
    return indicator;
}

