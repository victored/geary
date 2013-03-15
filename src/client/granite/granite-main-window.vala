/* Copyright 2011-2012 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution. 
 */

public class GraniteMainWindow : MainWindow {
    protected override void create_panes () {
        folder_paned = new Granite.Widgets.ThinPaned();
        conversations_paned = new Granite.Widgets.ThinPaned();
    }
}

