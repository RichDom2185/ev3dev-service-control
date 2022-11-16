// Manual build:
// valac --pkg linux --pkg posix --pkg ev3devkit-0.5 --pkg gio-unix-2.0 --pkg grx-3.0 --pkg glib-2.0 --pkg gudev-1.0 main.vala -o bin
using Ev3devKit.Ui;

static int main (string[] args)
{
    try {
        var app = new Ev3devKit.ConsoleApp ();
        bool enable_ssh = Posix.system ("sudo systemctl status ssh | head -3 | tail -1 | grep running") == 0;
        bool enable_webserver = Posix.system ("test \"$(cat /srv/www/cgi-bin/.enable)\" -eq 1") == 0;

        var activate_id = app.activate.connect (() => {
            app.hold ();

            var main_window = new Window ();
            var main_menu = new Ev3devKit.Ui.Menu ();
            var ssh_toggle = new CheckboxMenuItem ("SSH");
            ssh_toggle.checkbox.checked = enable_ssh;
            ssh_toggle.button.pressed.connect (() => {
                enable_ssh = !enable_ssh;
                if (enable_ssh) {
                    Posix.system ("sudo systemctl enable ssh && sudo systemctl start ssh");
                } else {
                    Posix.system ("sudo systemctl disable ssh && sudo systemctl stop ssh");
                }
                ssh_toggle.checkbox.checked = enable_ssh;
            });
            main_menu.add_menu_item (ssh_toggle);

            var webserver_toggle = new CheckboxMenuItem ("Webserver");
            webserver_toggle.checkbox.checked = enable_webserver;
            webserver_toggle.button.pressed.connect (() => {
                enable_webserver = !enable_webserver;
                if (enable_webserver) {
                    Posix.system ("sudo sed -i -e 's/0/1/' /srv/www/cgi-bin/.enable");
                } else {
                    Posix.system ("sudo sed -i -e 's/1/0/' /srv/www/cgi-bin/.enable");
                }
                webserver_toggle.checkbox.checked = enable_webserver;
            });
            main_menu.add_menu_item (webserver_toggle);

            main_window.add (main_menu);
            main_window.show ();
        });

        app.run ();
        app.disconnect (activate_id);

        return 0;
    } catch (GLib.Error err) {
        critical ("%s", err.message);
        Process.exit (err.code);
    }
}