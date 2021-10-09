// 
// 


/* Secure level can change only the following way:
 
 NotSecure -> Secure
     ^          ^
      \         |
       \        v
        \---- PartialSecureWithIgnored
 
 Initially conversation is not secured. If user goes and trust all current participants' clients
 it goes to secure state. If new client is added it goes to partial secure state.
 When user trust this new client conversation goes back to secure state.
 If the user chooses to send the messages anyway, conversation goes to not secure state
 */
typedef NS_CLOSED_ENUM(int16_t, ZMConversationSecurityLevel) {
    /// Conversation is not secured
    ZMConversationSecurityLevelNotSecure = 0,
    
    /// All of participants' clients are trusted or ignored
    /// (messages will not be sent until the conversation becomes secure or not secure)
    ZMConversationSecurityLevelSecureWithIgnored,
    
    /// All of participants' clients are trusted
    ZMConversationSecurityLevelSecure
};
