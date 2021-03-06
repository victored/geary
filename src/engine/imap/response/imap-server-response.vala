/* Copyright 2011-2012 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution. 
 */

public abstract class Geary.Imap.ServerResponse : RootParameters {
    public enum Type {
        STATUS_RESPONSE,
        SERVER_DATA,
        CONTINUATION_RESPONSE
    }
    
    public Tag tag { get; private set; }
    
    public ServerResponse(Tag tag) {
        this.tag = tag;
    }
    
    public ServerResponse.migrate(RootParameters root) throws ImapError {
        base.migrate(root);
        
        tag = new Tag.from_parameter((StringParameter) get_as(0, typeof(StringParameter)));
    }
    
    // The RootParameters are migrated and will be stripped upon exit.
    public static ServerResponse migrate_from_server(RootParameters root, out Type response_type)
        throws ImapError {
        Tag tag = new Tag.from_parameter(root.get_as_string(0));
        if (tag.is_tagged()) {
            // Attempt to decode second parameter for predefined status codes (piggyback on
            // Status.decode's exception if this is invalid)
            StringParameter? statusparam = root.get_if_string(1);
            if (statusparam != null)
                Status.decode(statusparam.value);
            
            // tagged and has proper status, so it's a status response
            response_type = Type.STATUS_RESPONSE;
            
            return new StatusResponse.migrate(root);
        } else if (tag.is_continuation()) {
            // nothing to decode; everything after the tag is human-readable stuff
            response_type = Type.CONTINUATION_RESPONSE;
            
            return new ContinuationResponse.migrate(root);
        }
        
        response_type = Type.SERVER_DATA;
        
        return new ServerData.migrate(root);
    }
}

