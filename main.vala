// Manual build:
// valac --pkg linux --pkg posix --pkg ev3devkit-0.5 --pkg gio-unix-2.0 --pkg grx-3.0 --pkg glib-2.0 --pkg gudev-1.0 main.vala -o bin
using Ev3devKit.Ui;

// Adapted from https://www.kuikie.com/snippet/79/vala-generate-random-string
string string_random(int length = 6, string charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890"){
    string random = "";

    for(int i=0;i<length;i++){
        int random_index = Random.int_range(0,charset.length);
        string ch = charset.get_char(charset.index_of_nth_char(random_index)).to_string();
        random += ch;
    }
	
    return random;
}

const string BOT_SECRET_FILE = "/var/lib/sling/secret_b62";
const string BOT_QRCODE_FILE = "/var/lib/sling/secret_image.png";

static int main (string[] args)
{
    try {
        var app = new Ev3devKit.ConsoleApp ();
        //  Set initial checkbox statuses
        bool enable_ssh = Posix.system ("sudo systemctl status ssh | head -3 | tail -1 | grep running") == 0;
        bool enable_webserver = Posix.system ("test \"$(cat /srv/www/cgi-bin/.enable)\" -eq 1") == 0;

        var activate_id = app.activate.connect (() => {
            app.hold ();

            var main_window = new Window ();
            var main_menu = new Ev3devKit.Ui.Menu ();

            var token_reset = new Ev3devKit.Ui.MenuItem ("Invalidate Bot Token");
            token_reset.button.pressed.connect(() => {
                var dialog = new MessageDialog ("Token Reset", "Token regenerated! Check QR Code to view and add to Source Academy.");
                // TODO: Don't use shell commands
                Posix.system ("rm -f " + BOT_QRCODE_FILE);
                Posix.system ("rm -f " + BOT_SECRET_FILE);
                Posix.system ("sudo systemctl restart sling");
                dialog.show();
            });
            main_menu.add_menu_item (token_reset);

            // Menu item to enable/disable SSH access
            var ssh_toggle = new CheckboxMenuItem ("Enable SSH");
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

            var ssh_reset = new Ev3devKit.Ui.MenuItem ("Reset SSH Password");
            ssh_reset.button.pressed.connect(() => {
                var random_string = string_random ();
                var dialog = new MessageDialog ("Password Reset", "Username: robot\nNew password: " + random_string);
                // TODO: Refactor ugly code
                var command = """echo "%s
%s" | sudo passwd robot""".printf (random_string, random_string);
                Posix.system (command);
                dialog.show();
            });
            main_menu.add_menu_item (ssh_reset);

            // Menu item to enable/disable webserver
            var webserver_toggle = new CheckboxMenuItem ("Enable Webserver");
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

            // Set up main layout
            var main_vbox = new Box.vertical ();
            var app_title = new Label ("Source Academy Settings") {
                border_bottom = 1
            };
            main_vbox.add (app_title);
            main_vbox.add (main_menu);

            // Button to quit app
            var quit_button = new Button.with_label ("Quit Settings") {
                padding = 0,
                border = 0,
                border_radius = 0,
                border_top = 1
            };
            quit_button.pressed.connect (() => {
                app.quit ();
            });
            main_vbox.add (quit_button);

            main_window.add (main_vbox);
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