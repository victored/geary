/* Copyright 2013 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

public class GearyGraniteController : GearyController {
    protected override void on_about() {
        Granite.Widgets.show_about_dialog(main_window, 
                                          "program_name", GearyApplication.NAME,
                                          "version", GearyApplication.VERSION,
                                          "logo_icon_name", GearyApplication.NAME,
                                          "comments", _(GearyApplication.DESCRIPTION),
                                          "copyright", GearyApplication.COPYRIGHT,
                                          "website", GearyApplication.WEBSITE,
                                          "website_label", _(GearyApplication.WEBSITE_LABEL),
                                          "authors", GearyApplication.AUTHORS,
                                          "translator_credits", _("translator-credits"),
                                          "license", GearyApplication.LICENSE);
    }

    protected override MainWindow create_main_window() {
        return new GraniteMainWindow();
    }
}
