/* Copyright 2011-2012 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution. 
 */

public abstract class Geary.Conversation : BaseObject {
    public enum Ordering {
        NONE,
        DATE_ASCENDING,
        DATE_DESCENDING,
    }
    
    protected Conversation() {
    }
    
    /**
     * Returns the number of emails in the conversation.
     */
    public abstract int get_count(bool folder_email_ids_only = false);
    
    /**
     * Returns all the email in the conversation sorted according to the specifier.
     */
    public abstract Gee.List<Geary.Email> get_emails(Ordering ordering);
    
    /**
     * Returns the email associated with the EmailIdentifier, if present in this conversation.
     */
    public abstract Geary.Email? get_email_by_id(Geary.EmailIdentifier id);
    
    /**
     * Returns all EmailIdentifiers in the conversation (or optionally only
     * folder email ids, ignoring account email ids), unsorted.
     */
    public abstract Gee.Collection<Geary.EmailIdentifier> get_email_ids(
        bool folder_email_ids_only = false);
    
    /**
     * Returns true if *any* message in the conversation is unread.
     */
    public bool is_unread() {
        return has_flag(Geary.EmailFlags.UNREAD);
    }

    /**
     * Returns true if any message in the conversation is not unread.
     */
    public bool has_any_read_message() {
        return is_missing_flag(Geary.EmailFlags.UNREAD);
    }

    /**
     * Returns true if *any* message in the conversation is flagged.
     */
    public bool is_flagged() {
        return has_flag(Geary.EmailFlags.FLAGGED);
    }
    
    /**
     * Returns true if this Conversation's earliest (first sent) email is earlier than
     * the supplied Conversation's earliest email.  An empty Conversation is defined as being
     * earlier than a non-empty conversation.  Comparing two empty Conversations or two Conversations
     * with the same earliest date is undefined.
     */
    public bool is_earlier(Geary.Conversation other) {
        Email? this_earliest = get_earliest_email();
        Email? other_earliest = other.get_earliest_email();
        
        if (this_earliest == null)
            return true;
        
        // this_earliest != null
        if (other_earliest == null)
            return false;
        
        return this_earliest.date.value.compare(other_earliest.date.value) < 0;
    }
    
    /**
     * Returns true if this Conversation's latest (most recently sent) email is more recent than
     * the supplied Conversation's latest email.  An empty Conversation is defined as being
     * earlier than a non-empty conversation.  Comparing two empty Conversations or two
     * Conversations with the same latest date is undefined.
     */
    public bool is_later(Geary.Conversation other) {
        Email? this_latest = get_latest_email();
        Email? other_latest = other.get_latest_email();
        
        if (this_latest == null)
            return (other_latest != null);
        
        // this_latest != null
        if (other_latest == null)
            return true;
        
        return this_latest.date.value.compare(other_latest.date.value) > 0;
    }
    
    /**
     * Returns the earliest (first sent) email in the Conversation.
     */
    public Geary.Email? get_earliest_email(bool folder_email_ids_only = false) {
        return get_single_email(Geary.Conversation.Ordering.DATE_ASCENDING, folder_email_ids_only);
   }
    
    /**
     * Returns the latest (most recently sent) email in the Conversation.
     */
    public Geary.Email? get_latest_email(bool folder_email_ids_only = false) {
        return get_single_email(Geary.Conversation.Ordering.DATE_DESCENDING, folder_email_ids_only);
    }
    
    private Geary.Email? get_single_email(Geary.Conversation.Ordering ordering,
        bool folder_email_ids_only) {
        foreach (Geary.Email email in get_emails(ordering)) {
            if (!folder_email_ids_only || email.id.get_folder_path() != null)
                return email;
        }
        return null;
    }
    
    /**
     * Return the EmailIdentifier with the lowest value.  Ignore Geary.ImapDB.
     * EmailIdentifiers, because they aren't useful to order in this sense.
     */
    public abstract Geary.EmailIdentifier? get_lowest_email_id();
    
    private bool check_flag(Geary.EmailFlag flag, bool contains) {
        foreach (Geary.Email email in get_emails(Ordering.NONE)) {
            if (email.email_flags != null && email.email_flags.contains(flag) == contains)
                return true;
        }
        
        return false;
    }

    private bool has_flag(Geary.EmailFlag flag) {
        return check_flag(flag, true);
    }

    private bool is_missing_flag(Geary.EmailFlag flag) {
        return check_flag(flag, false);
    }
}

