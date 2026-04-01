// Copyright 2025–2026 Skip
// SPDX-License-Identifier: MPL-2.0

#if !SKIP_BRIDGE
import Foundation

// MARK: - Enums

/// The type of a contact record.
public enum ContactType: String {
    case person
    case organization
}

/// Sort order for contact queries.
public enum ContactSortOrder: String {
    case givenName
    case familyName
    case none
    case userDefault
}

/// Result of a contact editor or picker operation.
public enum ContactEditorResult: String {
    case saved
    case deleted
    case canceled
    case unknown
}

/// Errors that can occur during contact operations.
public enum ContactError: Error {
    case permissionDenied
    case contactNotFound
    case groupNotFound
    case saveFailed(String)
    case deleteFailed(String)
    case invalidData(String)
}

// MARK: - Label Types

/// Labels for phone numbers, following iOS CNLabel conventions.
public enum PhoneLabel: String {
    case main
    case home
    case work
    case mobile
    case iPhone
    case homeFax
    case workFax
    case pager
    case other

    #if !SKIP
    public var cnLabelValue: String {
        switch self {
        case .main: return CNLabelPhoneNumberMain
        case .home: return CNLabelHome
        case .work: return CNLabelWork
        case .mobile: return CNLabelPhoneNumberMobile
        case .iPhone: return CNLabelPhoneNumberiPhone
        case .homeFax: return CNLabelPhoneNumberHomeFax
        case .workFax: return CNLabelPhoneNumberWorkFax
        case .pager: return CNLabelPhoneNumberPager
        case .other: return CNLabelOther
        }
    }

    public static func fromCNLabel(_ label: String?) -> PhoneLabel {
        guard let label = label else { return .other }
        switch label {
        case CNLabelPhoneNumberMain: return .main
        case CNLabelHome: return .home
        case CNLabelWork: return .work
        case CNLabelPhoneNumberMobile: return .mobile
        case CNLabelPhoneNumberiPhone: return .iPhone
        case CNLabelPhoneNumberHomeFax: return .homeFax
        case CNLabelPhoneNumberWorkFax: return .workFax
        case CNLabelPhoneNumberPager: return .pager
        default: return .other
        }
    }
    #endif
}

/// Labels for email addresses.
public enum EmailLabel: String {
    case home
    case work
    case iCloud
    case other

    #if !SKIP
    public var cnLabelValue: String {
        switch self {
        case .home: return CNLabelHome
        case .work: return CNLabelWork
        case .iCloud: return CNLabelEmailiCloud
        case .other: return CNLabelOther
        }
    }

    public static func fromCNLabel(_ label: String?) -> EmailLabel {
        guard let label = label else { return .other }
        switch label {
        case CNLabelHome: return .home
        case CNLabelWork: return .work
        case CNLabelEmailiCloud: return .iCloud
        default: return .other
        }
    }
    #endif
}

/// Labels for postal addresses.
public enum AddressLabel: String {
    case home
    case work
    case other

    #if !SKIP
    public var cnLabelValue: String {
        switch self {
        case .home: return CNLabelHome
        case .work: return CNLabelWork
        case .other: return CNLabelOther
        }
    }

    public static func fromCNLabel(_ label: String?) -> AddressLabel {
        guard let label = label else { return .other }
        switch label {
        case CNLabelHome: return .home
        case CNLabelWork: return .work
        default: return .other
        }
    }
    #endif
}

/// Labels for dates associated with a contact.
public enum DateLabel: String {
    case birthday
    case anniversary
    case other

    #if !SKIP
    public var cnLabelValue: String {
        switch self {
        case .birthday: return CNLabelDateAnniversary // birthday handled specially
        case .anniversary: return CNLabelDateAnniversary
        case .other: return CNLabelOther
        }
    }

    public static func fromCNLabel(_ label: String?) -> DateLabel {
        guard let label = label else { return .other }
        switch label {
        case CNLabelDateAnniversary: return .anniversary
        default: return .other
        }
    }
    #endif
}

/// Labels for URL addresses.
public enum URLLabel: String {
    case home
    case work
    case homepage
    case other

    #if !SKIP
    public var cnLabelValue: String {
        switch self {
        case .home: return CNLabelHome
        case .work: return CNLabelWork
        case .homepage: return CNLabelURLAddressHomePage
        case .other: return CNLabelOther
        }
    }

    public static func fromCNLabel(_ label: String?) -> URLLabel {
        guard let label = label else { return .other }
        switch label {
        case CNLabelHome: return .home
        case CNLabelWork: return .work
        case CNLabelURLAddressHomePage: return .homepage
        default: return .other
        }
    }
    #endif
}

/// Labels for relationships.
public enum RelationshipLabel: String {
    case spouse
    case child
    case mother
    case father
    case parent
    case sibling
    case friend
    case manager
    case assistant
    case partner
    case other

    #if !SKIP
    public var cnLabelValue: String {
        switch self {
        case .spouse: return CNLabelContactRelationSpouse
        case .child: return CNLabelContactRelationChild
        case .mother: return CNLabelContactRelationMother
        case .father: return CNLabelContactRelationFather
        case .parent: return CNLabelContactRelationParent
        case .sibling: return CNLabelContactRelationSibling
        case .friend: return CNLabelContactRelationFriend
        case .manager: return CNLabelContactRelationManager
        case .assistant: return CNLabelContactRelationAssistant
        case .partner: return CNLabelContactRelationPartner
        case .other: return CNLabelOther
        }
    }

    public static func fromCNLabel(_ label: String?) -> RelationshipLabel {
        guard let label = label else { return .other }
        switch label {
        case CNLabelContactRelationSpouse: return .spouse
        case CNLabelContactRelationChild: return .child
        case CNLabelContactRelationMother: return .mother
        case CNLabelContactRelationFather: return .father
        case CNLabelContactRelationParent: return .parent
        case CNLabelContactRelationSibling: return .sibling
        case CNLabelContactRelationFriend: return .friend
        case CNLabelContactRelationManager: return .manager
        case CNLabelContactRelationAssistant: return .assistant
        case CNLabelContactRelationPartner: return .partner
        default: return .other
        }
    }
    #endif
}

/// Labels for instant message addresses.
public enum InstantMessageServiceLabel: String {
    case aim
    case facebook
    case skype
    case googleTalk
    case icq
    case jabber
    case msn
    case qq
    case yahoo
    case other
}

/// Labels for social profiles.
public enum SocialProfileServiceLabel: String {
    case twitter
    case facebook
    case linkedIn
    case flickr
    case mySpace
    case sinaWeibo
    case other
}

// MARK: - Data Types

/// A phone number associated with a contact.
public final class ContactPhoneNumber {
    public var label: PhoneLabel
    public var customLabel: String?
    public var value: String

    public init(label: PhoneLabel = .mobile, customLabel: String? = nil, value: String = "") {
        self.label = label
        self.customLabel = customLabel
        self.value = value
    }
}

/// An email address associated with a contact.
public final class ContactEmailAddress {
    public var label: EmailLabel
    public var customLabel: String?
    public var value: String

    public init(label: EmailLabel = .home, customLabel: String? = nil, value: String = "") {
        self.label = label
        self.customLabel = customLabel
        self.value = value
    }
}

/// A postal address associated with a contact.
public final class ContactPostalAddress {
    public var label: AddressLabel
    public var customLabel: String?
    public var street: String
    public var city: String
    public var state: String
    public var postalCode: String
    public var country: String
    public var isoCountryCode: String

    public init(
        label: AddressLabel = .home,
        customLabel: String? = nil,
        street: String = "",
        city: String = "",
        state: String = "",
        postalCode: String = "",
        country: String = "",
        isoCountryCode: String = ""
    ) {
        self.label = label
        self.customLabel = customLabel
        self.street = street
        self.city = city
        self.state = state
        self.postalCode = postalCode
        self.country = country
        self.isoCountryCode = isoCountryCode
    }

    /// The full formatted address as a single string.
    public var formattedAddress: String {
        var parts: [String] = []
        if !street.isEmpty { parts.append(street) }
        if !city.isEmpty { parts.append(city) }
        if !state.isEmpty { parts.append(state) }
        if !postalCode.isEmpty { parts.append(postalCode) }
        if !country.isEmpty { parts.append(country) }
        return parts.joined(separator: ", ")
    }
}

/// A date associated with a contact (e.g. birthday, anniversary).
public final class ContactDate {
    public var label: DateLabel
    public var customLabel: String?
    public var day: Int
    public var month: Int
    public var year: Int?

    public init(label: DateLabel = .birthday, customLabel: String? = nil, day: Int = 1, month: Int = 1, year: Int? = nil) {
        self.label = label
        self.customLabel = customLabel
        self.day = day
        self.month = month
        self.year = year
    }
}

/// A relationship associated with a contact.
public final class ContactRelationship {
    public var label: RelationshipLabel
    public var customLabel: String?
    public var name: String

    public init(label: RelationshipLabel = .other, customLabel: String? = nil, name: String = "") {
        self.label = label
        self.customLabel = customLabel
        self.name = name
    }
}

/// A URL associated with a contact.
public final class ContactURLAddress {
    public var label: URLLabel
    public var customLabel: String?
    public var value: String

    public init(label: URLLabel = .homepage, customLabel: String? = nil, value: String = "") {
        self.label = label
        self.customLabel = customLabel
        self.value = value
    }
}

/// An instant message address associated with a contact.
public final class ContactInstantMessageAddress {
    public var label: InstantMessageServiceLabel
    public var customLabel: String?
    public var username: String
    public var service: String

    public init(label: InstantMessageServiceLabel = .other, customLabel: String? = nil, username: String = "", service: String = "") {
        self.label = label
        self.customLabel = customLabel
        self.username = username
        self.service = service
    }
}

/// A social profile associated with a contact.
public final class ContactSocialProfile {
    public var label: SocialProfileServiceLabel
    public var customLabel: String?
    public var username: String
    public var service: String
    public var urlString: String
    public var userIdentifier: String

    public init(label: SocialProfileServiceLabel = .other, customLabel: String? = nil, username: String = "", service: String = "", urlString: String = "", userIdentifier: String = "") {
        self.label = label
        self.customLabel = customLabel
        self.username = username
        self.service = service
        self.urlString = urlString
        self.userIdentifier = userIdentifier
    }
}

/// Thumbnail and full-size image data for a contact.
public final class ContactImage {
    public var thumbnailData: Data?
    public var imageData: Data?

    public init(thumbnailData: Data? = nil, imageData: Data? = nil) {
        self.thumbnailData = thumbnailData
        self.imageData = imageData
    }

    /// Whether any image data is available.
    public var isAvailable: Bool {
        return thumbnailData != nil || imageData != nil
    }
}

// MARK: - Contact

/// A contact record with all associated properties.
public final class Contact {
    /// The unique identifier for this contact. Nil for new contacts.
    public var id: String?

    /// The type of contact (person or organization).
    public var contactType: ContactType

    // MARK: Name fields
    public var namePrefix: String
    public var givenName: String
    public var middleName: String
    public var familyName: String
    public var nameSuffix: String
    public var nickname: String
    public var phoneticGivenName: String
    public var phoneticMiddleName: String
    public var phoneticFamilyName: String
    public var previousFamilyName: String

    // MARK: Organization fields
    public var organizationName: String
    public var departmentName: String
    public var jobTitle: String

    // MARK: Contact info
    public var phoneNumbers: [ContactPhoneNumber]
    public var emailAddresses: [ContactEmailAddress]
    public var postalAddresses: [ContactPostalAddress]
    public var urlAddresses: [ContactURLAddress]
    public var instantMessageAddresses: [ContactInstantMessageAddress]
    public var socialProfiles: [ContactSocialProfile]

    // MARK: Associated data
    public var birthday: ContactDate?
    public var dates: [ContactDate]
    public var relationships: [ContactRelationship]
    public var note: String

    // MARK: Image
    public var image: ContactImage?

    /// The display name computed from available name fields.
    public var displayName: String {
        if contactType == .organization && !organizationName.isEmpty {
            return organizationName
        }
        var parts: [String] = []
        if !namePrefix.isEmpty { parts.append(namePrefix) }
        if !givenName.isEmpty { parts.append(givenName) }
        if !middleName.isEmpty { parts.append(middleName) }
        if !familyName.isEmpty { parts.append(familyName) }
        if !nameSuffix.isEmpty { parts.append(nameSuffix) }
        let fullName = parts.joined(separator: " ")
        if !fullName.isEmpty { return fullName }
        if !organizationName.isEmpty { return organizationName }
        if !nickname.isEmpty { return nickname }
        if let email = emailAddresses.first { return email.value }
        if let phone = phoneNumbers.first { return phone.value }
        return ""
    }

    public init(
        id: String? = nil,
        contactType: ContactType = .person,
        namePrefix: String = "",
        givenName: String = "",
        middleName: String = "",
        familyName: String = "",
        nameSuffix: String = "",
        nickname: String = "",
        phoneticGivenName: String = "",
        phoneticMiddleName: String = "",
        phoneticFamilyName: String = "",
        previousFamilyName: String = "",
        organizationName: String = "",
        departmentName: String = "",
        jobTitle: String = "",
        phoneNumbers: [ContactPhoneNumber] = [],
        emailAddresses: [ContactEmailAddress] = [],
        postalAddresses: [ContactPostalAddress] = [],
        urlAddresses: [ContactURLAddress] = [],
        instantMessageAddresses: [ContactInstantMessageAddress] = [],
        socialProfiles: [ContactSocialProfile] = [],
        birthday: ContactDate? = nil,
        dates: [ContactDate] = [],
        relationships: [ContactRelationship] = [],
        note: String = "",
        image: ContactImage? = nil
    ) {
        self.id = id
        self.contactType = contactType
        self.namePrefix = namePrefix
        self.givenName = givenName
        self.middleName = middleName
        self.familyName = familyName
        self.nameSuffix = nameSuffix
        self.nickname = nickname
        self.phoneticGivenName = phoneticGivenName
        self.phoneticMiddleName = phoneticMiddleName
        self.phoneticFamilyName = phoneticFamilyName
        self.previousFamilyName = previousFamilyName
        self.organizationName = organizationName
        self.departmentName = departmentName
        self.jobTitle = jobTitle
        self.phoneNumbers = phoneNumbers
        self.emailAddresses = emailAddresses
        self.postalAddresses = postalAddresses
        self.urlAddresses = urlAddresses
        self.instantMessageAddresses = instantMessageAddresses
        self.socialProfiles = socialProfiles
        self.birthday = birthday
        self.dates = dates
        self.relationships = relationships
        self.note = note
        self.image = image
    }
}

// MARK: - Contact Group

/// A group of contacts (e.g. "Friends", "Coworkers").
public final class ContactGroup {
    public var id: String?
    public var name: String

    public init(id: String? = nil, name: String = "") {
        self.id = id
        self.name = name
    }
}

// MARK: - Container

/// A contact container represents a source/account (e.g. iCloud, Google, Local).
public final class ContactContainer {
    public var id: String
    public var name: String
    public var type: ContainerType

    public init(id: String = "", name: String = "", type: ContainerType = .local) {
        self.id = id
        self.name = name
        self.type = type
    }
}

/// The type of a contact container.
public enum ContainerType: String {
    case local
    case exchange
    case cardDAV
    case unassigned
}

// MARK: - Query Options

/// Options for fetching contacts.
public final class ContactFetchOptions {
    /// Filter contacts by name.
    public var nameFilter: String?
    /// Filter contacts by specific IDs.
    public var contactIDs: [String]?
    /// Maximum number of results.
    public var pageSize: Int?
    /// Offset for pagination.
    public var pageOffset: Int?
    /// Sort order for results.
    public var sortOrder: ContactSortOrder
    /// Whether to include image data in results.
    public var includeImages: Bool
    /// Whether to include note field.
    public var includeNote: Bool

    public init(
        nameFilter: String? = nil,
        contactIDs: [String]? = nil,
        pageSize: Int? = nil,
        pageOffset: Int? = nil,
        sortOrder: ContactSortOrder = .none,
        includeImages: Bool = false,
        includeNote: Bool = true
    ) {
        self.nameFilter = nameFilter
        self.contactIDs = contactIDs
        self.pageSize = pageSize
        self.pageOffset = pageOffset
        self.sortOrder = sortOrder
        self.includeImages = includeImages
        self.includeNote = includeNote
    }
}

/// Result of a contact fetch operation.
public final class ContactFetchResult {
    public let contacts: [Contact]
    public let hasNextPage: Bool

    public init(contacts: [Contact], hasNextPage: Bool = false) {
        self.contacts = contacts
        self.hasNextPage = hasNextPage
    }
}

// MARK: - Contact Editor Options

/// Options for presenting the contact editor UI.
public final class ContactEditorOptions {
    /// An existing contact to edit (nil for creating a new contact).
    public var contact: Contact?
    /// Default values for a new contact.
    public var defaultGivenName: String?
    public var defaultFamilyName: String?
    public var defaultOrganizationName: String?
    public var defaultPhoneNumber: String?
    public var defaultEmailAddress: String?
    public var defaultNote: String?

    public init(
        contact: Contact? = nil,
        defaultGivenName: String? = nil,
        defaultFamilyName: String? = nil,
        defaultOrganizationName: String? = nil,
        defaultPhoneNumber: String? = nil,
        defaultEmailAddress: String? = nil,
        defaultNote: String? = nil
    ) {
        self.contact = contact
        self.defaultGivenName = defaultGivenName
        self.defaultFamilyName = defaultFamilyName
        self.defaultOrganizationName = defaultOrganizationName
        self.defaultPhoneNumber = defaultPhoneNumber
        self.defaultEmailAddress = defaultEmailAddress
        self.defaultNote = defaultNote
    }
}

#if !SKIP
import Contacts
#endif

#endif
