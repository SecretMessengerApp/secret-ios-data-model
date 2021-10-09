// 
// 


@import Foundation;


@class ZMConversation;


typedef NS_ENUM(int64_t, ZMInvitationStatus) {
    ZMInvitationStatusNone = 0,
    ZMInvitationStatusPending,  // is being sent by BE
    ZMInvitationStatusConnectionRequestSent,
    ZMInvitationStatusSent,     // is already sent by BE
    ZMInvitationStatusFailed,   // sending failed
};


NS_ASSUME_NONNULL_BEGIN
@interface ZMAddressBookContact : NSObject

@property (nonatomic, readonly) NSString *name;

@property (nonatomic, copy, nullable) NSString *firstName;
@property (nonatomic, copy, nullable) NSString *middleName;
@property (nonatomic, copy, nullable) NSString *lastName;
@property (nonatomic, copy, nullable) NSString *nickname;
@property (nonatomic, copy, nullable) NSString *organization;
@property (nonatomic, copy, nullable) NSString *localIdentifier;

@property (nonatomic, copy) NSArray<NSString *> *emailAddresses;
@property (nonatomic, copy) NSArray<NSString *> *rawPhoneNumbers;
@property (nonatomic, copy) NSArray<NSString *> *phoneNumbers;

/// a list of contact field to send invitation to (currently its both phone numbers and emails)
@property (nonatomic, readonly) NSArray *contactDetails;

@end

NS_ASSUME_NONNULL_END
