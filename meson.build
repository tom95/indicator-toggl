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
schema_dir = join_paths(get_option('datadir'), 'glib-2.0', 'schemas')

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
        dependency('json-glib-1.0'),
        dependency('libsoup-2.4'),
        dependency('granite'),
        wingpanel_dep
    ],
    install: true,
    install_dir : get_option('libdir') + '/wingpanel'# wingpanel_dep.get_pkgconfig_variable('indicatorsdir')
)

install_data([
    'schemas/com.github.tom95.indicator-toggl.gschema.xml'
], install_dir: schema_dir)
meson.add_install_script('meson_post_install.py')

install_data([
  join_paths('data', 'icons', 'symbolic', 'com.github.tom95.indicator-toggl.time-tracker-symbolic.svg'),
  join_paths('data', 'icons', 'symbolic', 'com.github.tom95.indicator-toggl.time-tracker-active-symbolic.svg')
], install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', 'symbolic', 'apps'))

install_data(join_paths('data', 'icons', 'com.github.tom95.indicator-toggl.svg'),
    install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', '128x128', 'apps'))

install_data(join_paths('data', 'com.github.tom95.indicator-toggl.desktop'),
    install_dir: join_paths(get_option('datadir'), 'applications'))

install_data(join_paths('data', 'com.github.tom95.indicator-toggl'),
    install_dir: get_option('bindir'))

install_data(join_paths('data', 'com.github.tom95.indicator-toggl.appdata.xml'),
    install_dir: join_paths(get_option('datadir'), 'metainfo'))
