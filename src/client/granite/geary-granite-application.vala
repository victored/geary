/* Copyright 2013 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

public class GearyGraniteApplication : GearyApplication {
    public GearyGraniteApplication() {
        // ...
    }

    protected override GearyController create_controller() {
        return new GearyGraniteController();
    }
}

