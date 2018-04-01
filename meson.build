project('toggl', 'vala', 'c')

gettext_name = meson.project_name() + '-indicator'
gnome = import('gnome')
i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(gettext_name), language:'c')

#asresources = gnome.compile_resources(
    #'as-resources', 'data/com.github.tom95.indicator-toggl.gresource.xml',
    #source_dir: 'data',
    #c_name: 'as'
#)

wingpanel_dep = dependency('wingpanel-2.0')

add_project_arguments(['--vapidir', join_paths(meson.current_source_dir(), 'vapi')], language: 'vala')


schema_dir = join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
install_data([
    'schemas/com.github.tom95.indicator-toggl.gschema.xml'
], install_dir: schema_dir)
meson.add_install_script('meson_post_install.py')

shared_module(
    meson.project_name(),
    'src/TogglIndicator.vala',
    'src/TogglMenu.vala',

    'src/pages/NoTokenPage.vala',
    'src/pages/TrackingPage.vala',

    'src/services/TogglSettings.vala',
    'src/services/TogglApi.vala',

    #asresources,
    dependencies: [
        dependency('zeitgeist-2.0'),
        dependency('json-glib-1.0'),
        dependency('rest-0.7'),
        dependency('libnotify'),
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('granite'),
        dependency('gtk+-3.0'),
        dependency('gio-2.0'),
        dependency('gio-unix-2.0'),
        wingpanel_dep
    ],
    install: true,
    install_dir : get_option('libdir') + '/wingpanel' #'/usr/lib/x86_64-linux-gnu/wingpanel' #wingpanel_dep.get_pkgconfig_variable('indicatorsdir')
)

