/* Copyright 2011-2012 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution. 
 */

public delegate void Geary.EmailCallback(Gee.List<Geary.Email>? emails, Error? err);

public interface Geary.Folder : BaseObject {
    public enum OpenState {
        CLOSED,
        OPENING,
        REMOTE,
        LOCAL,
        BOTH
    }
    
    public enum OpenFailed {
        LOCAL_FAILED,
        REMOTE_FAILED
    }
    
    /**
     * The "closed" signal will be fired multiple times after a Folder is opened.  It is fired
     * after the remote and local sessions close for various reasons, and fires once and only
     * once when the folder is completely closed.
     *
     * LOCAL_CLOSE or LOCAL_ERROR is only called once, depending on the situation determining the
     * value.  The same is true for REMOTE_CLOSE and REMOTE_ERROR.  A REMOTE_ERROR can trigger
     * a LOCAL_CLOSE and vice-versa.  The values may be called in any order.
     *
     * When the local and remote stores have closed (either normally or due to errors, FOLDER_CLOSED
     * will be sent.
     */
    public enum CloseReason {
        LOCAL_CLOSE,
        LOCAL_ERROR,
        REMOTE_CLOSE,
        REMOTE_ERROR,
        FOLDER_CLOSED;
        
        public bool is_error() {
            return (this == LOCAL_ERROR) || (this == REMOTE_ERROR);
        }
    }
    
    public enum CountChangeReason {
        ADDED,
        REMOVED
    }
    
    /**
     * Flags used for retrieving email.
     *   LOCAL_ONLY:   fetch from the local store only
     *   FORCE_UPDATE: fetch from remote only (results merged into local store)
     *   EXCLUDING_ID: exclude the provided ID
     */
    [Flags]
    public enum ListFlags {
        NONE = 0,
        LOCAL_ONLY,
        FORCE_UPDATE,
        EXCLUDING_ID;
        
        public bool is_any_set(ListFlags flags) {
            return (this & flags) != 0;
        }
        
        public bool is_all_set(ListFlags flags) {
            return (this & flags) == flags;
        }
    }
    
    public abstract Geary.Account account { get; }
    
    /**
     * This is fired when the Folder is successfully opened by a caller.  It will only fire once
     * until the Folder is closed, with the OpenState indicating what has been opened and the count
     * indicating the number of messages in the folder (in the case of OpenState.BOTH or
     * OpenState.REMOTE, it refers to the authoritative number).
     *
     * OpenState.REMOTE will only fire if there's no local store, indicating that it's not a
     * synchronized folder but rather one entirely backed by a network server.  Geary currently
     * has no such folder implemented like this.
     *
     * This signal will never fire with Geary.OpenState.CLOSED as a parameter.
     */
    public signal void opened(OpenState state, int count);
    
    /**
     * This is fired when open_async() fails for one or more reasons.
     *
     * See open_async() and "opened" for more information on how opening a Folder works, in particular
     * how open_async() may return immediately although the remote has not completely opened.
     * This signal may be called in the context of, or after completion of, open_async().  It will
     * *not* be called after close_async() has completed, however.
     *
     * Note that this signal may be fired *and* open_async() throw an Error.
     *
     * This signal may be fired more than once before the Folder is closed.  It will only fire once
     * for each type of failure, however.
     */
    public signal void open_failed(OpenFailed failure, Error? err);
    
    /**
     * This is fired when the Folder is closed, either by the caller or due to errors in the local
     * or remote store(s).  It will fire three times: to report how the local store closed
     * (gracefully or due to error), how the remote closed (similarly) and finally with
     * FOLDER_CLOSED.  The first two may come in either order; the third is always the last.
     */
    public signal void closed(CloseReason reason);
    
    /**
     * "email-appended" is fired when new messages have been appended to the list of messages in
     * the folder (and therefore old message position numbers remain valid, but the total count of
     * the messages in the folder has changed).
     */
    public signal void email_appended(Gee.Collection<Geary.EmailIdentifier> ids);
    
    /**
     * "email-locally-appended" is fired when previously unknown messages have been appended to the
     * list of messages in the folder.  This is similar to "email-appended", but that signal
     * lists all messages appended to the folder.  "email-locally-appended" only reports emails that
     * have not been seen prior.  Hence, an email that is removed from the folder and returned
     * later will not be listed here (unless it was removed from the local store in the meantime).
     *
     * Note that these messages were appended as well, hence their positional addressing may have
     * changed since last seen in this folder.  However, it's important to realize that this list
     * does *not* represent all newly appended messages.
     */
    public signal void email_locally_appended(Gee.Collection<Geary.EmailIdentifier> ids);
    
    /**
     * "email-removed" is fired when a message has been removed (deleted or moved) from the
     * folder (and therefore old message position numbers may no longer be valid, i.e. those after
     * the removed message).
     *
     * NOTE: It's possible for the remote server to report a message has been removed that is not
     * known locally (and therefore the caller could not have record of).  If this happens, this
     * signal will *not* fire, although "email-count-changed" will.
     */
    public signal void email_removed(Gee.Collection<Geary.EmailIdentifier> ids);
    
    /**
     * "email-count-changed" is fired when the total count of email in a folder has changed in any way.
     *
     * Note that this signal will be fired alongside "messages-appended" or "message-removed".
     * That is, do not use both signals to process email count changes; one will suffice.
     * This signal will fire after those (although see the note at "messages-removed").
     */
    public signal void email_count_changed(int new_count, CountChangeReason reason);
    
    /**
     * "email-flags-changed" is fired when an email's flag changed.
     *
     * This signal will be fired both when changes occur on the client side via the
     * mark_email_async() method as well as changes occur remotely.
     */
    public signal void email_flags_changed(Gee.Map<Geary.EmailIdentifier, Geary.EmailFlags> map);

    /**
    * "special-folder-type-changed" is fired when the special folder type has changed.
    *
    * This will usually happen when the local account object has been updated with data
    * from the remote account.
    */
    public signal void special_folder_type_changed(Geary.SpecialFolderType old_type,
        Geary.SpecialFolderType new_type);
    
    protected abstract void notify_opened(OpenState state, int count);
    
    protected abstract void notify_open_failed(OpenFailed failure, Error? err);
    
    protected abstract void notify_closed(CloseReason reason);
    
    protected abstract void notify_email_appended(Gee.Collection<Geary.EmailIdentifier> ids);
    
    protected abstract void notify_email_locally_appended(Gee.Collection<Geary.EmailIdentifier> ids);
    
    protected abstract void notify_email_removed(Gee.Collection<Geary.EmailIdentifier> ids);
    
    protected abstract void notify_email_count_changed(int new_count, CountChangeReason reason);
    
    protected abstract void notify_email_flags_changed(Gee.Map<Geary.EmailIdentifier,
        Geary.EmailFlags> flag_map);
    
    protected abstract void notify_special_folder_type_changed(Geary.SpecialFolderType old_type,
        Geary.SpecialFolderType new_type);
    
    public abstract Geary.FolderPath get_path();
    
    /**
     * Returns a FolderProperties that represents, if fully open, accurate values for this Folder,
     * and if not, values that represent the last time the Folder was opened or examined by the
     * Engine.
     *
     * The returned object is not guaranteed to be long-lived.  If the Folder's state changes, it's
     * possible a new FolderProperties will be set in its place.  Instead of monitoring the fields
     * of the FolderProperties for changes, use Account.folders_contents_changed() to be notified
     * of changes and use the (potentially new) FolderProperties returned by this method at that
     * point.
     */
    public abstract Geary.FolderProperties get_properties();
    
    /**
     * Returns the special folder type of the folder.
     */
    public abstract Geary.SpecialFolderType get_special_folder_type();
    
    /**
     * Returns a name suitable for displaying to the user.
     */
    public abstract string get_display_name();
    
    /**
     * Returns the state of the Folder's connections to the local and remote stores.
     */
    public abstract OpenState get_open_state();
    
    /**
     * The Folder must be opened before most operations may be performed on it.  Depending on the
     * implementation this might entail opening a network connection or setting the connection to
     * a particular state, opening a file or database, and so on.
     *
     * In the case of a Folder that is aggregating the contents of synchronized folder, it's possible
     * for this method to complete even though all internal opens haven't completed.  The "opened"
     * signal is the final say on when a Folder is fully opened with its OpenState parameter
     * indicating how open it really is.  In general, a Folder's local store will open immediately
     * while it may take time (if ever) for the remote state to open.  Thus, it's possible for
     * the "opened" signal to fire some time *after* this method completes.
     *
     * However, even if the method returns before the Folder's OpenState is BOTH, this Folder is
     * ready for operation if this method returns without error.  The messages the folder returns
     * may not reflect the full state of the Folder, however, and returned emails may subsequently
     * have their state changed (such as their position).  Making a call that requires
     * accessing the remote store before OpenState.BOTH has been signalled will result in that
     * call blocking until the remote is open or an error state has occurred.  It's also possible for
     * the command to return early without waiting, depending on prior information of the folder.
     * See list_email_async() for special notes on its operation.  Also see wait_for_open_async().
     *
     * If there's an error while opening, "open-failed" will be fired.  (See that signal for more
     * information on how many times it may fire, and when.)  To prevent the Folder from going into
     * a halfway state, it will immediately schedule a close_async() to cleanup, and those
     * associated signals will be fired as well.
     *
     * If the Folder has been opened previously, an internal open count is incremented and the
     * method returns.  There are no other side-effects.
     *
     * A Folder may be reopened after it has been closed.  This allows for Folder objects to be
     * emitted by the Account object cheaply, but the client should only have a few open at a time,
     * as each may represent an expensive resource (such as a network connection).
     */
    public abstract async void open_async(bool readonly, Cancellable? cancellable = null) throws Error;
    
    /**
     * Wait for the Folder to become fully open or fails to open due to error.  If not opened
     * due to error, throws EngineError.ALREADY_CLOSED.
     *
     * NOTE: The current implementation requirements are only that should be work after an
     * open_async() call has completed (i.e. an open is in progress).  Calling this method
     * otherwise will throw an EngineError.OPEN_REQUIRED.
     */
    public abstract async void wait_for_open_async(Cancellable? cancellable = null) throws Error;
    
    /**
     * The Folder should be closed when operations on it are concluded.  Depending on the
     * implementation this might entail closing a network connection or reverting it to another
     * state, or closing file handles or database connections.
     *
     * If the Folder is open, an internal open count is decremented.  If it remains above zero, the
     * method returns with no other side-effects.  If it decrements to zero, the Folder is closed,
     * tearing down network connections, closing files, and so forth.  See "closed" for signals
     * indicating the closing states.
     *
     * If the Folder is already closed, the method silently returns.
     */
    public abstract async void close_async(Cancellable? cancellable = null) throws Error;
    
    /**
     * Returns a list of messages that fulfill the required_fields flags starting at the low
     * position and moving up to (low + count).  If count is -1, the returned list starts at low
     * and proceeds to all available emails.  If low is -1, the *last* (most recent) 'count' emails
     * are returned.  If both low and count are -1, it's no different than calling with low as
     * 1 and count -1, that is, all emails are returned.  (See normalize_span_specifiers() for
     * a utility function that handles all aspects of these requirements.)  low is one-based, unless
     * -1 is specified, as explained above.
     *
     * The returned list is not guaranteed to be in any particular order.  The position index
     * (starting from low) *is* ordered, however, from oldest to newest (in terms of receipt by the 
     * SMTP server, not necessarily the Sent: field), so if the caller wants the latest emails,
     * they should calculate low by subtracting from get_email_count() or set low to -1 and use
     * count to fetch the last n emails.
     *
     * If any position in low to (low + count) are out of range, only the email within range are
     * reported.  No error is thrown.  This allows callers to blindly request the first or last n
     * emails in a folder without determining the count first.
     *
     * If the caller would prefer the Folder return emails it has immediately available rather than
     * make an expensive network call to "properly" fetch the emails, it should pass ListFlags.LOCAL_ONLY.
     * However, this also means avoiding a full synchronization, so it's possible the fetched
     * emails do not correspond to what's actually available on the server.  The best use of this
     * method is to quickly retrieve a block of email for display or processing purposes,
     * immediately followed by a non-fast list operation and then merging the two results.
     *
     * Likewise, if this is called while Folder is in an OPENING or LOCAL state (that is, the remote
     * server is not yet available), only local mail will be returned.  This is to avoid two poor
     * situations: (a) waiting to connect to the server to ensure that positional addressing is
     * correctly calculated (and potentially missing the opportunity to return available local data)
     * and (b) fetching locally, waiting, then fetching remotely, which means the returned emails
     * could potentially mix stale and fresh data.  A ListFlag may be offered in the future to allow
     * the caller to force the engine to wait for a server connection before continuing.  See
     * get_open_state() and "opened" for more information.
     *
     * Note that LOCAL_ONLY only returns the emails with the required fields that are available in
     * the Folder's local store.  It may have fewer or incomplete messages, meaning that this will
     * return an incomplete list.
     *
     * Similarly, if the caller wants the Folder to always go out to the network to retrieve the
     * information (even if it is already present in the local store), use ListFlags.FORCE_UPDATE.
     *
     * The Folder must be opened prior to attempting this operation.
     */
    public abstract async Gee.List<Geary.Email>? list_email_async(int low, int count,
        Geary.Email.Field required_fields, ListFlags flags, Cancellable? cancellable = null)
        throws Error;
    
    /**
     * Similar in contract to list_email_async(), however instead of the emails being returned all
     * at once at completion time, the emails are delivered to the caller in chunks via the
     * EmailCallback.  The method indicates when all the message have been fetched by passing a null
     * for the first parameter.  If an Error occurs while processing, it will be passed as the
     * second parameter.  There's no guarantess of the order the messages will be delivered to the
     * caller.
     *
     * The Folder must be opened prior to attempting this operation.
     */
    public abstract void lazy_list_email(int low, int count, Geary.Email.Field required_fields,
        ListFlags flags, EmailCallback cb, Cancellable? cancellable = null);
    
    /**
     * Similar in contract to list_email_async(), but uses Geary.EmailIdentifier rather than
     * positional addressing.  This allows for a batch of messages to be listed from a starting
     * identifier, going up and down the stack depending on the count parameter.
     *
     * The count parameter is exclusive of the Email at initial_id.  That is, if count is one,
     * two Emails may be returned: the one for initial_id and the next one.  If count is zero,
     * only the Email with the specified initial_id will be listed, making this method operate
     * like fetch_email_async().
     *
     * If count is positive, initial_id is the *lowest* identifier and the returned list is going
     * up the stack (toward the most recently added).  If the count is negative, initial_id is
     * the *highest* identifier and the returned list is going down the stack (toward the earliest
     * added).
     *
     * To fetch all available messages in one direction or another, use int.MIN or int.MAX.
     *
     * initial_id *must* be an EmailIdentifier available to the Folder for this to work, as listing
     * a range inevitably requires positional addressing under the covers.  However, since it's
     * some times desirable to list messages excluding the specified EmailIdentifier, callers may
     * use ListFlags.EXCLUDING_ID (which is a flag only recognized by this method and
     * lazy_list_email_by_id()).  If the count is zero or one (or the number of messages remaining
     * on the stack from the initial ID's position is zero or one) *and* this flag is set, no
     * messages will be returned.
     *
     * There's no guarantee of the returned messages' order.
     *
     * There is (currently) no sparse version of list_email_by_id_async().
     *
     * The Folder must be opened prior to attempting this operation.
     */
    public abstract async Gee.List<Geary.Email>? list_email_by_id_async(Geary.EmailIdentifier initial_id,
        int count, Geary.Email.Field required_fields, ListFlags flags, Cancellable? cancellable = null)
        throws Error;
    
    /**
     * Similar in contract to lazy_list_email_async(), but uses Geary.EmailIdentifier rather than
     * positional addressing, much like list_email_by_id_async().  See that method for more
     * information on its contract and how the count and flags parameters work.
     *
     * Like the other "lazy" methods, this method will call EmailCallback while the operation is
     * processing.  This method does not block.
     *
     * The Folder must be opened prior to attempting this operation.
     */
    public abstract void lazy_list_email_by_id(Geary.EmailIdentifier initial_id, int count,
        Geary.Email.Field required_fields, ListFlags flags, EmailCallback cb,
        Cancellable? cancellable = null);
    
    /**
     * Similar in contract to list_email_async(), but uses a list of Geary.EmailIdentifiers rather
     * than positional addressing, much like list_email_by_id_async().  See that method for more
     * information on its contract and how the flags parameter works.
     *
     * Any Gee.Collection is accepted for EmailIdentifiers, but the returned list will only contain
     * one email for each requested; duplicates are ignored.  ListFlags.EXCLUDING_ID is ignored
     * for this call and lazy_list_email_by_sparse_id().
     *
     * The Folder must be opened prior to attempting this operation.
     */
    public abstract async Gee.List<Geary.Email>? list_email_by_sparse_id_async(
        Gee.Collection<Geary.EmailIdentifier> ids, Geary.Email.Field required_fields, ListFlags flags,
        Cancellable? cancellable = null) throws Error;
    
    /**
     * Similar in contract to lazy_list_email(), but uses a list of Geary.EmailIdentifiers rather
     * than positional addressing.  See list_email_by_id_async() and list_email_by_sparse_id_async()
     * for more information on their contracts and how the flags and callback parameter works.
     *
     * Like the other "lazy" methods, this method will call EmailCallback while the operation is
     * processing.  This method does not block.
     *
     * The Folder must be opened prior to attempting this operation.
     */
    public abstract void lazy_list_email_by_sparse_id(Gee.Collection<Geary.EmailIdentifier> ids,
        Geary.Email.Field required_fields, ListFlags flags, EmailCallback cb,
        Cancellable? cancellable = null);
    
    /**
     * Returns the locally available Geary.Email.Field fields for the specified emails.  If a
     * list or fetch operation occurs on the emails that specifies a field not returned here,
     * the Engine will either have to go out to the remote server to get it, or (if
     * ListFlags.LOCAL_ONLY is specified) not return it to the caller.
     *
     * If the EmailIdentifier is unknown locally, it will not be present in the returned Map.
     *
     * The Folder must be opened prior to attempting this operation.
     */
    public abstract async Gee.Map<Geary.EmailIdentifier, Geary.Email.Field>? list_local_email_fields_async(
        Gee.Collection<Geary.EmailIdentifier> ids, Cancellable? cancellable = null) throws Error;
    
    /**
     * Returns a single email that fulfills the required_fields flag at the ordered position in
     * the folder.  If the email_id is invalid for the folder's contents, an EngineError.NOT_FOUND
     * error is thrown.  If the requested fields are not available, EngineError.INCOMPLETE_MESSAGE
     * is thrown.
     *
     * Because fetch_email_async() is a form of listing (listing exactly one email), it takes
     * ListFlags as a parameter.  See list_email_async() for more information.  Note that one
     * flag (ListFlags.EXCLUDING_ID) makes no sense in this context.
     *
     * This method also works like the list variants in that it will not wait for the server to
     * connect if called in the OPENING state.  A ListFlag option may be offered in the future to
     * force waiting for the server to connect.  Unlike the list variants, if in the OPENING state
     * and the message is not found locally, EngineError.NOT_FOUND is thrown.
     *
     * The Folder must be opened prior to attempting this operation.
     */
    public abstract async Geary.Email fetch_email_async(Geary.EmailIdentifier email_id,
        Geary.Email.Field required_fields, ListFlags flags, Cancellable? cancellable = null) throws Error;
    
    /**
     * check_span_specifiers() verifies that the span specifiers match the requirements set by
     * list_email_async() and lazy_list_email_async().  If not, this method throws
     * EngineError.BAD_PARAMETERS.
     */
    protected static void check_span_specifiers(int low, int count) throws EngineError {
        if ((low < 1 && low != -1) || (count < 0 && count != -1))
            throw new EngineError.BAD_PARAMETERS("low=%d count=%d", low, count);
    }
    
    /**
     * normalize_span_specifiers() deals with the varieties of span specifiers that can be passed
     * to list_email_async() and lazy_list_email_async().  Note that this function is for
     * implementations to convert 'low' and 'count' into positive values (1-based in the case of
     * low) that are within an appropriate range.
     *
     * If total is zero, low and count will return as zero as well.
     *
     * The caller should plug in 'low' and 'count' passed from the user as well as the total
     * number of emails available (i.e. the complete span is 1..total).
     */
    internal static void normalize_span_specifiers(ref int low, ref int count, int total) 
        throws EngineError {
        check_span_specifiers(low, count);
        
        if (total < 0)
            throw new EngineError.BAD_PARAMETERS("total=%d", total);
        
        if (total == 0) {
            low = 0;
            count = 0;
            
            return;
        }
        
        // if both are -1, it's no different than low=1 count=-1 (that is, return all email)
        if (low == -1 && count == -1)
            low = 1;
        
        // if count is -1, it's like a globbed star (return everything starting at low)
        if (count == -1)
            count = total;
        
        if (low == -1)
            low = ((total - count) + 1).clamp(1, total);
        
        if ((low + (count - 1)) > total)
            count = ((total - low) + 1).clamp(1, total);
    }
    
    /**
     * Used for debugging.  Should not be used for user-visible labels.
     */
    public abstract string to_string();
}

