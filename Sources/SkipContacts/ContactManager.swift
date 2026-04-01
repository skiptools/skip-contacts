// Copyright 2025–2026 Skip
// SPDX-License-Identifier: MPL-2.0

#if !SKIP_BRIDGE
import Foundation
import OSLog
#if !SKIP
import Contacts
#endif
import SkipKit

private let logger: Logger = Logger(subsystem: "skip.contacts", category: "ContactManager")

/// Primary API for querying, creating, updating, and deleting contacts on both iOS and Android.
///
/// Use the shared singleton instance `ContactManager.shared` for all operations.
/// Always check and request permissions before performing contact operations.
///
/// ## iOS
/// Uses `CNContactStore` from the Contacts framework.
/// Access the underlying store via `contactStore` for advanced operations.
///
/// ## Android
/// Uses `ContactsContract` via `ContentResolver` to query and modify the contacts database.
public final class ContactManager {
    /// Shared singleton instance.
    public nonisolated(unsafe) static let shared = ContactManager()

    #if !SKIP
    /// The underlying CNContactStore (iOS/macOS). Use for advanced platform-specific operations.
    public let contactStore = CNContactStore()
    #endif

    private init() {}

    // MARK: - Permissions

    /// Query the current contacts permission status without prompting the user.
    public static func queryContactsPermission() -> PermissionAuthorization {
        #if !SKIP
        let status = CNContactStore.authorizationStatus(for: .contacts)
        switch status {
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .unknown
        case .limited: return .limited
        @unknown default: return .unknown
        }
        #else
        return PermissionManager.queryPermission(PermissionType.READ_CONTACTS)
        #endif
    }

    /// Request contacts permission from the user. Returns the resulting authorization status.
    /* SKIP @nobridge */ public static func requestContactsPermission() async -> PermissionAuthorization {
        #if !SKIP
        do {
            let granted = try await ContactManager.shared.contactStore.requestAccess(for: .contacts)
            return granted ? .authorized : .denied
        } catch {
            logger.error("Failed to request contacts permission: \(error)")
            return .denied
        }
        #else
        let readAuth = await PermissionManager.requestPermission(PermissionType.READ_CONTACTS)
        if readAuth == .authorized {
            let writeAuth = await PermissionManager.requestPermission(PermissionType.WRITE_CONTACTS)
            return writeAuth
        }
        return readAuth
        #endif
    }

    // MARK: - Fetch Contacts

    /// Fetch contacts matching the given options.
    public func getContacts(options: ContactFetchOptions = ContactFetchOptions()) throws -> ContactFetchResult {
        #if !SKIP
        return try getAppleContacts(options: options)
        #else
        return try getAndroidContacts(options: options)
        #endif
    }

    /// Fetch a single contact by ID.
    public func getContact(id: String, includeImages: Bool = false, includeNote: Bool = true) throws -> Contact? {
        let options = ContactFetchOptions(contactIDs: [id], includeImages: includeImages, includeNote: includeNote)
        let result = try getContacts(options: options)
        return result.contacts.first
    }

    /// Check whether any contacts exist in the database.
    public func hasContacts() throws -> Bool {
        let result = try getContacts(options: ContactFetchOptions(pageSize: 1))
        return !result.contacts.isEmpty
    }

    // MARK: - Create, Update, Delete

    /// Create a new contact. Returns the new contact's identifier.
    public func createContact(_ contact: Contact) throws -> String {
        #if !SKIP
        return try createAppleContact(contact)
        #else
        return try createAndroidContact(contact)
        #endif
    }

    /// Update an existing contact. The contact must have a valid `id`.
    public func updateContact(_ contact: Contact) throws {
        guard contact.id != nil else {
            throw ContactError.invalidData("Contact must have an id to update")
        }
        #if !SKIP
        try updateAppleContact(contact)
        #else
        try updateAndroidContact(contact)
        #endif
    }

    /// Delete a contact by ID.
    public func deleteContact(id: String) throws {
        #if !SKIP
        try deleteAppleContact(id: id)
        #else
        try deleteAndroidContact(id: id)
        #endif
    }

    // MARK: - Groups

    /// Get all contact groups.
    public func getGroups() throws -> [ContactGroup] {
        #if !SKIP
        return try getAppleGroups()
        #else
        return try getAndroidGroups()
        #endif
    }

    /// Create a new contact group. Returns the group identifier.
    public func createGroup(name: String) throws -> String {
        #if !SKIP
        return try createAppleGroup(name: name)
        #else
        return try createAndroidGroup(name: name)
        #endif
    }

    /// Delete a contact group by ID.
    public func deleteGroup(id: String) throws {
        #if !SKIP
        try deleteAppleGroup(id: id)
        #else
        try deleteAndroidGroup(id: id)
        #endif
    }

    /// Add a contact to a group.
    public func addContactToGroup(contactID: String, groupID: String) throws {
        #if !SKIP
        try addAppleContactToGroup(contactID: contactID, groupID: groupID)
        #else
        try addAndroidContactToGroup(contactID: contactID, groupID: groupID)
        #endif
    }

    /// Remove a contact from a group.
    public func removeContactFromGroup(contactID: String, groupID: String) throws {
        #if !SKIP
        try removeAppleContactFromGroup(contactID: contactID, groupID: groupID)
        #else
        try removeAndroidContactFromGroup(contactID: contactID, groupID: groupID)
        #endif
    }

    // MARK: - Containers

    /// Get all contact containers/accounts.
    public func getContainers() throws -> [ContactContainer] {
        #if !SKIP
        return try getAppleContainers()
        #else
        return try getAndroidContainers()
        #endif
    }

    /// Get the default container ID for new contacts.
    public func getDefaultContainerID() throws -> String {
        #if !SKIP
        return contactStore.defaultContainerIdentifier()
        #else
        return try getAndroidDefaultContainerID()
        #endif
    }
}

// MARK: - iOS/macOS Implementation

#if !SKIP

extension ContactManager {

    private func keysToFetch(options: ContactFetchOptions) -> [CNKeyDescriptor] {
        var keys: [CNKeyDescriptor] = [
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactTypeKey as CNKeyDescriptor,
            CNContactNamePrefixKey as CNKeyDescriptor,
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactMiddleNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactNameSuffixKey as CNKeyDescriptor,
            CNContactNicknameKey as CNKeyDescriptor,
            CNContactPhoneticGivenNameKey as CNKeyDescriptor,
            CNContactPhoneticMiddleNameKey as CNKeyDescriptor,
            CNContactPhoneticFamilyNameKey as CNKeyDescriptor,
            CNContactPreviousFamilyNameKey as CNKeyDescriptor,
            CNContactOrganizationNameKey as CNKeyDescriptor,
            CNContactDepartmentNameKey as CNKeyDescriptor,
            CNContactJobTitleKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactPostalAddressesKey as CNKeyDescriptor,
            CNContactUrlAddressesKey as CNKeyDescriptor,
            CNContactInstantMessageAddressesKey as CNKeyDescriptor,
            CNContactSocialProfilesKey as CNKeyDescriptor,
            CNContactBirthdayKey as CNKeyDescriptor,
            CNContactDatesKey as CNKeyDescriptor,
            CNContactRelationsKey as CNKeyDescriptor,
        ]
        if options.includeNote {
            keys.append(CNContactNoteKey as CNKeyDescriptor)
        }
        if options.includeImages {
            keys.append(CNContactThumbnailImageDataKey as CNKeyDescriptor)
            keys.append(CNContactImageDataKey as CNKeyDescriptor)
            keys.append(CNContactImageDataAvailableKey as CNKeyDescriptor)
        }
        return keys
    }

    private func getAppleContacts(options: ContactFetchOptions) throws -> ContactFetchResult {
        let keys = keysToFetch(options: options)
        var contacts: [Contact] = []

        if let ids = options.contactIDs {
            let predicate = CNContact.predicateForContacts(withIdentifiers: ids)
            let cnContacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: keys)
            contacts = cnContacts.map { contactFromCN($0, includeImages: options.includeImages, includeNote: options.includeNote) }
        } else if let name = options.nameFilter, !name.isEmpty {
            let predicate = CNContact.predicateForContacts(matchingName: name)
            let cnContacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: keys)
            contacts = cnContacts.map { contactFromCN($0, includeImages: options.includeImages, includeNote: options.includeNote) }
        } else {
            let request = CNContactFetchRequest(keysToFetch: keys)
            switch options.sortOrder {
            case .givenName:
                request.sortOrder = .givenName
            case .familyName:
                request.sortOrder = .familyName
            case .none, .userDefault:
                request.sortOrder = .userDefault
            }
            try contactStore.enumerateContacts(with: request) { cnContact, _ in
                contacts.append(contactFromCN(cnContact, includeImages: options.includeImages, includeNote: options.includeNote))
            }
        }

        // Apply pagination
        let offset = options.pageOffset ?? 0
        let totalCount = contacts.count
        if offset > 0 && offset < totalCount {
            contacts = Array(contacts.dropFirst(offset))
        } else if offset >= totalCount {
            contacts = []
        }

        var hasNextPage = false
        if let pageSize = options.pageSize, pageSize > 0 && contacts.count > pageSize {
            contacts = Array(contacts.prefix(pageSize))
            hasNextPage = true
        }

        return ContactFetchResult(contacts: contacts, hasNextPage: hasNextPage)
    }

    private func contactFromCN(_ cn: CNContact, includeImages: Bool, includeNote: Bool) -> Contact {
        let contact = Contact()
        contact.id = cn.identifier
        contact.contactType = cn.contactType == .organization ? .organization : .person

        contact.namePrefix = cn.namePrefix
        contact.givenName = cn.givenName
        contact.middleName = cn.middleName
        contact.familyName = cn.familyName
        contact.nameSuffix = cn.nameSuffix
        contact.nickname = cn.nickname
        contact.phoneticGivenName = cn.phoneticGivenName
        contact.phoneticMiddleName = cn.phoneticMiddleName
        contact.phoneticFamilyName = cn.phoneticFamilyName
        contact.previousFamilyName = cn.previousFamilyName

        contact.organizationName = cn.organizationName
        contact.departmentName = cn.departmentName
        contact.jobTitle = cn.jobTitle

        contact.phoneNumbers = cn.phoneNumbers.map { labeled in
            ContactPhoneNumber(
                label: PhoneLabel.fromCNLabel(labeled.label),
                value: labeled.value.stringValue
            )
        }

        contact.emailAddresses = cn.emailAddresses.map { labeled in
            ContactEmailAddress(
                label: EmailLabel.fromCNLabel(labeled.label),
                value: labeled.value as String
            )
        }

        contact.postalAddresses = cn.postalAddresses.map { labeled in
            let addr = labeled.value
            return ContactPostalAddress(
                label: AddressLabel.fromCNLabel(labeled.label),
                street: addr.street,
                city: addr.city,
                state: addr.state,
                postalCode: addr.postalCode,
                country: addr.country,
                isoCountryCode: addr.isoCountryCode
            )
        }

        contact.urlAddresses = cn.urlAddresses.map { labeled in
            ContactURLAddress(
                label: URLLabel.fromCNLabel(labeled.label),
                value: labeled.value as String
            )
        }

        contact.instantMessageAddresses = cn.instantMessageAddresses.map { labeled in
            let im = labeled.value
            return ContactInstantMessageAddress(
                username: im.username,
                service: im.service
            )
        }

        contact.socialProfiles = cn.socialProfiles.map { labeled in
            let sp = labeled.value
            return ContactSocialProfile(
                username: sp.username,
                service: sp.service,
                urlString: sp.urlString,
                userIdentifier: sp.userIdentifier
            )
        }

        if let bday = cn.birthday {
            contact.birthday = ContactDate(
                label: .birthday,
                day: bday.day ?? 1,
                month: bday.month ?? 1,
                year: bday.year
            )
        }

        contact.dates = cn.dates.map { labeled in
            let dc = labeled.value
            return ContactDate(
                label: DateLabel.fromCNLabel(labeled.label),
                day: dc.day as Int,
                month: dc.month as Int,
                year: dc.year
            )
        }

        contact.relationships = cn.contactRelations.map { labeled in
            ContactRelationship(
                label: RelationshipLabel.fromCNLabel(labeled.label),
                name: labeled.value.name
            )
        }

        if includeNote {
            contact.note = cn.note
        }

        if includeImages {
            let img = ContactImage()
            img.thumbnailData = cn.thumbnailImageData
            img.imageData = cn.imageData
            if img.isAvailable {
                contact.image = img
            }
        }

        return contact
    }

    private func applyCNContactProperties(_ contact: Contact, to mutable: CNMutableContact) {
        mutable.contactType = contact.contactType == .organization ? .organization : .person
        mutable.namePrefix = contact.namePrefix
        mutable.givenName = contact.givenName
        mutable.middleName = contact.middleName
        mutable.familyName = contact.familyName
        mutable.nameSuffix = contact.nameSuffix
        mutable.nickname = contact.nickname
        mutable.phoneticGivenName = contact.phoneticGivenName
        mutable.phoneticMiddleName = contact.phoneticMiddleName
        mutable.phoneticFamilyName = contact.phoneticFamilyName
        mutable.previousFamilyName = contact.previousFamilyName
        mutable.organizationName = contact.organizationName
        mutable.departmentName = contact.departmentName
        mutable.jobTitle = contact.jobTitle

        mutable.phoneNumbers = contact.phoneNumbers.map { ph in
            CNLabeledValue(label: ph.customLabel ?? ph.label.cnLabelValue, value: CNPhoneNumber(stringValue: ph.value))
        }

        mutable.emailAddresses = contact.emailAddresses.map { em in
            CNLabeledValue(label: em.customLabel ?? em.label.cnLabelValue, value: em.value as NSString)
        }

        mutable.postalAddresses = contact.postalAddresses.map { addr in
            let postal = CNMutablePostalAddress()
            postal.street = addr.street
            postal.city = addr.city
            postal.state = addr.state
            postal.postalCode = addr.postalCode
            postal.country = addr.country
            postal.isoCountryCode = addr.isoCountryCode
            return CNLabeledValue(label: addr.customLabel ?? addr.label.cnLabelValue, value: postal)
        }

        mutable.urlAddresses = contact.urlAddresses.map { url in
            CNLabeledValue(label: url.customLabel ?? url.label.cnLabelValue, value: url.value as NSString)
        }

        mutable.instantMessageAddresses = contact.instantMessageAddresses.map { im in
            let value = CNInstantMessageAddress(username: im.username, service: im.service)
            return CNLabeledValue(label: im.customLabel ?? CNLabelOther, value: value)
        }

        mutable.socialProfiles = contact.socialProfiles.map { sp in
            let value = CNSocialProfile(urlString: sp.urlString, username: sp.username, userIdentifier: sp.userIdentifier, service: sp.service)
            return CNLabeledValue(label: sp.customLabel ?? CNLabelOther, value: value)
        }

        if let bday = contact.birthday {
            var dc = DateComponents()
            dc.day = bday.day
            dc.month = bday.month
            if let year = bday.year {
                dc.year = year
            }
            mutable.birthday = dc
        } else {
            mutable.birthday = nil
        }

        mutable.dates = contact.dates.map { d in
            var dc = DateComponents()
            dc.day = d.day
            dc.month = d.month
            if let year = d.year {
                dc.year = year
            }
            return CNLabeledValue(label: d.customLabel ?? d.label.cnLabelValue, value: dc as NSDateComponents)
        }

        mutable.contactRelations = contact.relationships.map { rel in
            CNLabeledValue(label: rel.customLabel ?? rel.label.cnLabelValue, value: CNContactRelation(name: rel.name))
        }

        mutable.note = contact.note

        if let img = contact.image {
            mutable.imageData = img.imageData
        }
    }

    private func createAppleContact(_ contact: Contact) throws -> String {
        let mutable = CNMutableContact()
        applyCNContactProperties(contact, to: mutable)

        let request = CNSaveRequest()
        request.add(mutable, toContainerWithIdentifier: nil)
        try contactStore.execute(request)
        return mutable.identifier
    }

    private func updateAppleContact(_ contact: Contact) throws {
        guard let contactID = contact.id else {
            throw ContactError.invalidData("Contact must have an id to update")
        }
        let keys = keysToFetch(options: ContactFetchOptions(includeImages: true, includeNote: true))
        let cnContact = try contactStore.unifiedContact(withIdentifier: contactID, keysToFetch: keys)
        let mutable = cnContact.mutableCopy() as! CNMutableContact
        applyCNContactProperties(contact, to: mutable)

        let request = CNSaveRequest()
        request.update(mutable)
        try contactStore.execute(request)
    }

    private func deleteAppleContact(id: String) throws {
        let keys: [CNKeyDescriptor] = [CNContactIdentifierKey as CNKeyDescriptor]
        let cnContact = try contactStore.unifiedContact(withIdentifier: id, keysToFetch: keys)
        let mutable = cnContact.mutableCopy() as! CNMutableContact

        let request = CNSaveRequest()
        request.delete(mutable)
        try contactStore.execute(request)
    }

    private func getAppleGroups() throws -> [ContactGroup] {
        let groups = try contactStore.groups(matching: nil)
        return groups.map { g in
            ContactGroup(id: g.identifier, name: g.name)
        }
    }

    private func createAppleGroup(name: String) throws -> String {
        let group = CNMutableGroup()
        group.name = name
        let request = CNSaveRequest()
        request.add(group, toContainerWithIdentifier: nil)
        try contactStore.execute(request)
        return group.identifier
    }

    private func deleteAppleGroup(id: String) throws {
        let groups = try contactStore.groups(matching: CNGroup.predicateForGroups(withIdentifiers: [id]))
        guard let group = groups.first else {
            throw ContactError.groupNotFound
        }
        let mutable = group.mutableCopy() as! CNMutableGroup
        let request = CNSaveRequest()
        request.delete(mutable)
        try contactStore.execute(request)
    }

    private func addAppleContactToGroup(contactID: String, groupID: String) throws {
        let keys: [CNKeyDescriptor] = [CNContactIdentifierKey as CNKeyDescriptor]
        let contact = try contactStore.unifiedContact(withIdentifier: contactID, keysToFetch: keys)
        let groups = try contactStore.groups(matching: CNGroup.predicateForGroups(withIdentifiers: [groupID]))
        guard let group = groups.first else {
            throw ContactError.groupNotFound
        }
        let request = CNSaveRequest()
        request.addMember(contact, to: group)
        try contactStore.execute(request)
    }

    private func removeAppleContactFromGroup(contactID: String, groupID: String) throws {
        let keys: [CNKeyDescriptor] = [CNContactIdentifierKey as CNKeyDescriptor]
        let contact = try contactStore.unifiedContact(withIdentifier: contactID, keysToFetch: keys)
        let groups = try contactStore.groups(matching: CNGroup.predicateForGroups(withIdentifiers: [groupID]))
        guard let group = groups.first else {
            throw ContactError.groupNotFound
        }
        let request = CNSaveRequest()
        request.removeMember(contact, from: group)
        try contactStore.execute(request)
    }

    private func getAppleContainers() throws -> [ContactContainer] {
        let containers = try contactStore.containers(matching: nil)
        return containers.map { c in
            let type: ContainerType
            switch c.type {
            case .local: type = .local
            case .exchange: type = .exchange
            case .cardDAV: type = .cardDAV
            default: type = .unassigned
            }
            return ContactContainer(id: c.identifier, name: c.name, type: type)
        }
    }
}

#endif

// MARK: - Android Implementation

#if SKIP

extension ContactManager {

    private func getAndroidContacts(options: ContactFetchOptions) throws -> ContactFetchResult {
        let context = ProcessInfo.processInfo.androidContext
        let resolver = context.getContentResolver()

        var selection: String? = nil
        var selectionArgs: [String]? = nil
        var sortOrderStr: String? = nil

        if let ids = options.contactIDs, !ids.isEmpty {
            let placeholders = ids.map { _ in "?" }.joined(separator: ",")
            selection = "\(android.provider.ContactsContract.Contacts._ID) IN (\(placeholders))"
            selectionArgs = ids
        } else if let name = options.nameFilter, !name.isEmpty {
            selection = "\(android.provider.ContactsContract.Contacts.DISPLAY_NAME_PRIMARY) LIKE ?"
            selectionArgs = ["%\(name)%"]
        }

        switch options.sortOrder {
        case .givenName:
            sortOrderStr = "\(android.provider.ContactsContract.Contacts.DISPLAY_NAME_PRIMARY) ASC"
        case .familyName:
            sortOrderStr = "\(android.provider.ContactsContract.Contacts.DISPLAY_NAME_PRIMARY) ASC"
        case .userDefault, .none:
            sortOrderStr = nil
        }

        let uri = android.provider.ContactsContract.Contacts.CONTENT_URI
        let projection: [String] = [
            android.provider.ContactsContract.Contacts._ID,
            android.provider.ContactsContract.Contacts.DISPLAY_NAME_PRIMARY,
            android.provider.ContactsContract.Contacts.HAS_PHONE_NUMBER,
            android.provider.ContactsContract.Contacts.PHOTO_THUMBNAIL_URI
        ]

        let cursor = resolver.query(uri, projection.toList().toTypedArray(), selection, selectionArgs?.toList()?.toTypedArray(), sortOrderStr)
        var contacts: [Contact] = []

        if let cursor = cursor {
            let idIndex = cursor.getColumnIndex(android.provider.ContactsContract.Contacts._ID)
            let nameIndex = cursor.getColumnIndex(android.provider.ContactsContract.Contacts.DISPLAY_NAME_PRIMARY)

            // Apply offset
            let offset = options.pageOffset ?? 0
            if offset > 0 {
                var skipped = 0
                while skipped < offset && cursor.moveToNext() {
                    skipped = skipped + 1
                }
            }

            let limit = options.pageSize ?? Int.max
            var count = 0
            var hasMore = false

            while cursor.moveToNext() {
                if count >= limit {
                    hasMore = true
                    break
                }
                let contactID = cursor.getString(idIndex) ?? ""
                let contact = Contact()
                contact.id = contactID

                // Load name from display name
                let displayName = cursor.getString(nameIndex) ?? ""
                contact.givenName = displayName

                // Load detailed data
                loadAndroidContactDetails(resolver: resolver, contact: contact, contactID: contactID, includeImages: options.includeImages, includeNote: options.includeNote)

                contacts.append(contact)
                count = count + 1
            }
            cursor.close()
            return ContactFetchResult(contacts: contacts, hasNextPage: hasMore)
        }

        return ContactFetchResult(contacts: contacts, hasNextPage: false)
    }

    private func loadAndroidContactDetails(resolver: android.content.ContentResolver, contact: Contact, contactID: String, includeImages: Bool, includeNote: Bool) {
        let dataUri = android.provider.ContactsContract.Data.CONTENT_URI
        let dataSelection = "\(android.provider.ContactsContract.Data.CONTACT_ID) = ?"
        let dataArgs = [contactID]

        let dataCursor = resolver.query(dataUri, nil, dataSelection, dataArgs.toList().toTypedArray(), nil)

        if let dataCursor = dataCursor {
            let mimeIndex = dataCursor.getColumnIndex(android.provider.ContactsContract.Data.MIMETYPE)

            while dataCursor.moveToNext() {
                let mimeType = dataCursor.getString(mimeIndex) ?? ""

                switch mimeType {
                case android.provider.ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE:
                    contact.namePrefix = dataCursor.getString(dataCursor.getColumnIndex(android.provider.ContactsContract.CommonDataKinds.StructuredName.PREFIX)) ?? ""
                    contact.givenName = dataCursor.getString(dataCursor.getColumnIndex(android.provider.ContactsContract.CommonDataKinds.StructuredName.GIVEN_NAME)) ?? ""
                    contact.middleName = dataCursor.getString(dataCursor.getColumnIndex(android.provider.ContactsContract.CommonDataKinds.StructuredName.MIDDLE_NAME)) ?? ""
                    contact.familyName = dataCursor.getString(dataCursor.getColumnIndex(android.provider.ContactsContract.CommonDataKinds.StructuredName.FAMILY_NAME)) ?? ""
                    contact.nameSuffix = dataCursor.getString(dataCursor.getColumnIndex(android.provider.ContactsContract.CommonDataKinds.StructuredName.SUFFIX)) ?? ""
                    contact.phoneticGivenName = dataCursor.getString(dataCursor.getColumnIndex(android.provider.ContactsContract.CommonDataKinds.StructuredName.PHONETIC_GIVEN_NAME)) ?? ""
                    contact.phoneticMiddleName = dataCursor.getString(dataCursor.getColumnIndex(android.provider.ContactsContract.CommonDataKinds.StructuredName.PHONETIC_MIDDLE_NAME)) ?? ""
                    contact.phoneticFamilyName = dataCursor.getString(dataCursor.getColumnIndex(android.provider.ContactsContract.CommonDataKinds.StructuredName.PHONETIC_FAMILY_NAME)) ?? ""

                case android.provider.ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE:
                    let number = dataCursor.getString(dataCursor.getColumnIndex(android.provider.ContactsContract.CommonDataKinds.Phone.NUMBER)) ?? ""
                    let typeInt = dataCursor.getInt(dataCursor.getColumnIndex(android.provider.ContactsContract.CommonDataKinds.Phone.TYPE))
                    let label = androidPhoneTypeToLabel(typeInt)
                    contact.phoneNumbers.append(ContactPhoneNumber(label: label, value: number))

                case android.provider.ContactsContract.CommonDataKinds.Email.CONTENT_ITEM_TYPE:
                    let email = dataCursor.getString(dataCursor.getColumnIndex(android.provider.ContactsContract.CommonDataKinds.Email.ADDRESS)) ?? ""
                    let typeInt = dataCursor.getInt(dataCursor.getColumnIndex(android.provider.ContactsContract.CommonDataKinds.Email.TYPE))
                    let label = androidEmailTypeToLabel(typeInt)
                    contact.emailAddresses.append(ContactEmailAddress(label: label, value: email))

                case android.provider.ContactsContract.CommonDataKinds.StructuredPostal.CONTENT_ITEM_TYPE:
                    let street = dataCursor.getString(dataCursor.getColumnIndex(android.provider.ContactsContract.CommonDataKinds.StructuredPostal.STREET)) ?? ""
                    let city = dataCursor.getString(dataCursor.getColumnIndex(android.provider.ContactsContract.CommonDataKinds.StructuredPostal.CITY)) ?? ""
                    let state = dataCursor.getString(dataCursor.getColumnIndex(android.provider.ContactsContract.CommonDataKinds.StructuredPostal.REGION)) ?? ""
                    let postalCode = dataCursor.getString(dataCursor.getColumnIndex(android.provider.ContactsContract.CommonDataKinds.StructuredPostal.POSTCODE)) ?? ""
                    let country = dataCursor.getString(dataCursor.getColumnIndex(android.provider.ContactsContract.CommonDataKinds.StructuredPostal.COUNTRY)) ?? ""
                    let typeInt = dataCursor.getInt(dataCursor.getColumnIndex(android.provider.ContactsContract.CommonDataKinds.StructuredPostal.TYPE))
                    let label = androidAddressTypeToLabel(typeInt)
                    contact.postalAddresses.append(ContactPostalAddress(label: label, street: street, city: city, state: state, postalCode: postalCode, country: country))

                case android.provider.ContactsContract.CommonDataKinds.Organization.CONTENT_ITEM_TYPE:
                    contact.organizationName = dataCursor.getString(dataCursor.getColumnIndex(android.provider.ContactsContract.CommonDataKinds.Organization.COMPANY)) ?? ""
                    contact.departmentName = dataCursor.getString(dataCursor.getColumnIndex(android.provider.ContactsContract.CommonDataKinds.Organization.DEPARTMENT)) ?? ""
                    contact.jobTitle = dataCursor.getString(dataCursor.getColumnIndex(android.provider.ContactsContract.CommonDataKinds.Organization.TITLE)) ?? ""

                case android.provider.ContactsContract.CommonDataKinds.Website.CONTENT_ITEM_TYPE:
                    let url = dataCursor.getString(dataCursor.getColumnIndex(android.provider.ContactsContract.CommonDataKinds.Website.URL)) ?? ""
                    contact.urlAddresses.append(ContactURLAddress(label: .homepage, value: url))

                case android.provider.ContactsContract.CommonDataKinds.Event.CONTENT_ITEM_TYPE:
                    let dateStr = dataCursor.getString(dataCursor.getColumnIndex(android.provider.ContactsContract.CommonDataKinds.Event.START_DATE)) ?? ""
                    let typeInt = dataCursor.getInt(dataCursor.getColumnIndex(android.provider.ContactsContract.CommonDataKinds.Event.TYPE))
                    let parsed = parseAndroidDateString(dateStr)
                    if typeInt == android.provider.ContactsContract.CommonDataKinds.Event.TYPE_BIRTHDAY {
                        contact.birthday = ContactDate(label: .birthday, day: parsed.day, month: parsed.month, year: parsed.year)
                    } else if typeInt == android.provider.ContactsContract.CommonDataKinds.Event.TYPE_ANNIVERSARY {
                        contact.dates.append(ContactDate(label: .anniversary, day: parsed.day, month: parsed.month, year: parsed.year))
                    } else {
                        contact.dates.append(ContactDate(label: .other, day: parsed.day, month: parsed.month, year: parsed.year))
                    }

                case android.provider.ContactsContract.CommonDataKinds.Relation.CONTENT_ITEM_TYPE:
                    let name = dataCursor.getString(dataCursor.getColumnIndex(android.provider.ContactsContract.CommonDataKinds.Relation.NAME)) ?? ""
                    let typeInt = dataCursor.getInt(dataCursor.getColumnIndex(android.provider.ContactsContract.CommonDataKinds.Relation.TYPE))
                    let label = androidRelationTypeToLabel(typeInt)
                    contact.relationships.append(ContactRelationship(label: label, name: name))

                case android.provider.ContactsContract.CommonDataKinds.Im.CONTENT_ITEM_TYPE:
                    let username = dataCursor.getString(dataCursor.getColumnIndex(android.provider.ContactsContract.CommonDataKinds.Im.DATA)) ?? ""
                    let protocolInt = dataCursor.getInt(dataCursor.getColumnIndex(android.provider.ContactsContract.CommonDataKinds.Im.PROTOCOL))
                    let service = androidIMProtocolToString(protocolInt)
                    contact.instantMessageAddresses.append(ContactInstantMessageAddress(username: username, service: service))

                case android.provider.ContactsContract.CommonDataKinds.Nickname.CONTENT_ITEM_TYPE:
                    contact.nickname = dataCursor.getString(dataCursor.getColumnIndex(android.provider.ContactsContract.CommonDataKinds.Nickname.NAME)) ?? ""

                case android.provider.ContactsContract.CommonDataKinds.Note.CONTENT_ITEM_TYPE:
                    if includeNote {
                        contact.note = dataCursor.getString(dataCursor.getColumnIndex(android.provider.ContactsContract.CommonDataKinds.Note.NOTE)) ?? ""
                    }

                default:
                    break
                }
            }
            dataCursor.close()
        }

        // Load photo if requested
        if includeImages {
            loadAndroidContactImage(resolver: resolver, contact: contact, contactID: contactID)
        }
    }

    private func loadAndroidContactImage(resolver: android.content.ContentResolver, contact: Contact, contactID: String) {
        let contactUri = android.content.ContentUris.withAppendedId(android.provider.ContactsContract.Contacts.CONTENT_URI, java.lang.Long.parseLong(contactID))
        let photoInputStream = android.provider.ContactsContract.Contacts.openContactPhotoInputStream(resolver, contactUri, true)
        if let photoInputStream = photoInputStream {
            let bytes = photoInputStream.readBytes()
            let img = ContactImage()
            img.imageData = Data(platformValue: bytes)
            contact.image = img
            photoInputStream.close()
        }
        let thumbInputStream = android.provider.ContactsContract.Contacts.openContactPhotoInputStream(resolver, contactUri, false)
        if let thumbInputStream = thumbInputStream {
            let bytes = thumbInputStream.readBytes()
            if contact.image == nil {
                contact.image = ContactImage()
            }
            contact.image?.thumbnailData = Data(platformValue: bytes)
            thumbInputStream.close()
        }
    }

    private func createAndroidContact(_ contact: Contact) throws -> String {
        let context = ProcessInfo.processInfo.androidContext
        let resolver = context.getContentResolver()

        let ops = java.util.ArrayList<android.content.ContentProviderOperation>()

        // Insert raw contact
        ops.add(
            android.content.ContentProviderOperation.newInsert(android.provider.ContactsContract.RawContacts.CONTENT_URI)
                .withValue(android.provider.ContactsContract.RawContacts.ACCOUNT_TYPE, nil)
                .withValue(android.provider.ContactsContract.RawContacts.ACCOUNT_NAME, nil)
                .build()
        )

        // Name
        let nameOp = android.content.ContentProviderOperation.newInsert(android.provider.ContactsContract.Data.CONTENT_URI)
            .withValueBackReference(android.provider.ContactsContract.Data.RAW_CONTACT_ID, 0)
            .withValue(android.provider.ContactsContract.Data.MIMETYPE, android.provider.ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE)
            .withValue(android.provider.ContactsContract.CommonDataKinds.StructuredName.PREFIX, contact.namePrefix)
            .withValue(android.provider.ContactsContract.CommonDataKinds.StructuredName.GIVEN_NAME, contact.givenName)
            .withValue(android.provider.ContactsContract.CommonDataKinds.StructuredName.MIDDLE_NAME, contact.middleName)
            .withValue(android.provider.ContactsContract.CommonDataKinds.StructuredName.FAMILY_NAME, contact.familyName)
            .withValue(android.provider.ContactsContract.CommonDataKinds.StructuredName.SUFFIX, contact.nameSuffix)
            .withValue(android.provider.ContactsContract.CommonDataKinds.StructuredName.PHONETIC_GIVEN_NAME, contact.phoneticGivenName)
            .withValue(android.provider.ContactsContract.CommonDataKinds.StructuredName.PHONETIC_MIDDLE_NAME, contact.phoneticMiddleName)
            .withValue(android.provider.ContactsContract.CommonDataKinds.StructuredName.PHONETIC_FAMILY_NAME, contact.phoneticFamilyName)
            .build()
        ops.add(nameOp)

        // Phone numbers
        for phone in contact.phoneNumbers {
            ops.add(
                android.content.ContentProviderOperation.newInsert(android.provider.ContactsContract.Data.CONTENT_URI)
                    .withValueBackReference(android.provider.ContactsContract.Data.RAW_CONTACT_ID, 0)
                    .withValue(android.provider.ContactsContract.Data.MIMETYPE, android.provider.ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE)
                    .withValue(android.provider.ContactsContract.CommonDataKinds.Phone.NUMBER, phone.value)
                    .withValue(android.provider.ContactsContract.CommonDataKinds.Phone.TYPE, labelToAndroidPhoneType(phone.label))
                    .build()
            )
        }

        // Emails
        for email in contact.emailAddresses {
            ops.add(
                android.content.ContentProviderOperation.newInsert(android.provider.ContactsContract.Data.CONTENT_URI)
                    .withValueBackReference(android.provider.ContactsContract.Data.RAW_CONTACT_ID, 0)
                    .withValue(android.provider.ContactsContract.Data.MIMETYPE, android.provider.ContactsContract.CommonDataKinds.Email.CONTENT_ITEM_TYPE)
                    .withValue(android.provider.ContactsContract.CommonDataKinds.Email.ADDRESS, email.value)
                    .withValue(android.provider.ContactsContract.CommonDataKinds.Email.TYPE, labelToAndroidEmailType(email.label))
                    .build()
            )
        }

        // Postal addresses
        for addr in contact.postalAddresses {
            ops.add(
                android.content.ContentProviderOperation.newInsert(android.provider.ContactsContract.Data.CONTENT_URI)
                    .withValueBackReference(android.provider.ContactsContract.Data.RAW_CONTACT_ID, 0)
                    .withValue(android.provider.ContactsContract.Data.MIMETYPE, android.provider.ContactsContract.CommonDataKinds.StructuredPostal.CONTENT_ITEM_TYPE)
                    .withValue(android.provider.ContactsContract.CommonDataKinds.StructuredPostal.STREET, addr.street)
                    .withValue(android.provider.ContactsContract.CommonDataKinds.StructuredPostal.CITY, addr.city)
                    .withValue(android.provider.ContactsContract.CommonDataKinds.StructuredPostal.REGION, addr.state)
                    .withValue(android.provider.ContactsContract.CommonDataKinds.StructuredPostal.POSTCODE, addr.postalCode)
                    .withValue(android.provider.ContactsContract.CommonDataKinds.StructuredPostal.COUNTRY, addr.country)
                    .withValue(android.provider.ContactsContract.CommonDataKinds.StructuredPostal.TYPE, labelToAndroidAddressType(addr.label))
                    .build()
            )
        }

        // Organization
        if !contact.organizationName.isEmpty || !contact.jobTitle.isEmpty || !contact.departmentName.isEmpty {
            ops.add(
                android.content.ContentProviderOperation.newInsert(android.provider.ContactsContract.Data.CONTENT_URI)
                    .withValueBackReference(android.provider.ContactsContract.Data.RAW_CONTACT_ID, 0)
                    .withValue(android.provider.ContactsContract.Data.MIMETYPE, android.provider.ContactsContract.CommonDataKinds.Organization.CONTENT_ITEM_TYPE)
                    .withValue(android.provider.ContactsContract.CommonDataKinds.Organization.COMPANY, contact.organizationName)
                    .withValue(android.provider.ContactsContract.CommonDataKinds.Organization.DEPARTMENT, contact.departmentName)
                    .withValue(android.provider.ContactsContract.CommonDataKinds.Organization.TITLE, contact.jobTitle)
                    .build()
            )
        }

        // URLs
        for url in contact.urlAddresses {
            ops.add(
                android.content.ContentProviderOperation.newInsert(android.provider.ContactsContract.Data.CONTENT_URI)
                    .withValueBackReference(android.provider.ContactsContract.Data.RAW_CONTACT_ID, 0)
                    .withValue(android.provider.ContactsContract.Data.MIMETYPE, android.provider.ContactsContract.CommonDataKinds.Website.CONTENT_ITEM_TYPE)
                    .withValue(android.provider.ContactsContract.CommonDataKinds.Website.URL, url.value)
                    .build()
            )
        }

        // Note
        if !contact.note.isEmpty {
            ops.add(
                android.content.ContentProviderOperation.newInsert(android.provider.ContactsContract.Data.CONTENT_URI)
                    .withValueBackReference(android.provider.ContactsContract.Data.RAW_CONTACT_ID, 0)
                    .withValue(android.provider.ContactsContract.Data.MIMETYPE, android.provider.ContactsContract.CommonDataKinds.Note.CONTENT_ITEM_TYPE)
                    .withValue(android.provider.ContactsContract.CommonDataKinds.Note.NOTE, contact.note)
                    .build()
            )
        }

        // Birthday
        if let bday = contact.birthday {
            let dateStr = formatAndroidDateString(day: bday.day, month: bday.month, year: bday.year)
            ops.add(
                android.content.ContentProviderOperation.newInsert(android.provider.ContactsContract.Data.CONTENT_URI)
                    .withValueBackReference(android.provider.ContactsContract.Data.RAW_CONTACT_ID, 0)
                    .withValue(android.provider.ContactsContract.Data.MIMETYPE, android.provider.ContactsContract.CommonDataKinds.Event.CONTENT_ITEM_TYPE)
                    .withValue(android.provider.ContactsContract.CommonDataKinds.Event.START_DATE, dateStr)
                    .withValue(android.provider.ContactsContract.CommonDataKinds.Event.TYPE, android.provider.ContactsContract.CommonDataKinds.Event.TYPE_BIRTHDAY)
                    .build()
            )
        }

        // Relationships
        for rel in contact.relationships {
            ops.add(
                android.content.ContentProviderOperation.newInsert(android.provider.ContactsContract.Data.CONTENT_URI)
                    .withValueBackReference(android.provider.ContactsContract.Data.RAW_CONTACT_ID, 0)
                    .withValue(android.provider.ContactsContract.Data.MIMETYPE, android.provider.ContactsContract.CommonDataKinds.Relation.CONTENT_ITEM_TYPE)
                    .withValue(android.provider.ContactsContract.CommonDataKinds.Relation.NAME, rel.name)
                    .withValue(android.provider.ContactsContract.CommonDataKinds.Relation.TYPE, labelToAndroidRelationType(rel.label))
                    .build()
            )
        }

        // Nickname
        if !contact.nickname.isEmpty {
            ops.add(
                android.content.ContentProviderOperation.newInsert(android.provider.ContactsContract.Data.CONTENT_URI)
                    .withValueBackReference(android.provider.ContactsContract.Data.RAW_CONTACT_ID, 0)
                    .withValue(android.provider.ContactsContract.Data.MIMETYPE, android.provider.ContactsContract.CommonDataKinds.Nickname.CONTENT_ITEM_TYPE)
                    .withValue(android.provider.ContactsContract.CommonDataKinds.Nickname.NAME, contact.nickname)
                    .build()
            )
        }

        let results = resolver.applyBatch(android.provider.ContactsContract.AUTHORITY, ops)
        let rawContactUri = results[0].uri
        if let rawContactUri = rawContactUri {
            let rawContactID = android.content.ContentUris.parseId(rawContactUri)
            // Look up the aggregate contact ID from the raw contact
            let contactIDCursor = resolver.query(
                android.provider.ContactsContract.RawContacts.CONTENT_URI,
                [android.provider.ContactsContract.RawContacts.CONTACT_ID].toList().toTypedArray(),
                "\(android.provider.ContactsContract.RawContacts._ID) = ?",
                ["\(rawContactID)"].toList().toTypedArray(),
                nil
            )
            if let contactIDCursor = contactIDCursor {
                if contactIDCursor.moveToFirst() {
                    let contactID = contactIDCursor.getString(0) ?? "\(rawContactID)"
                    contactIDCursor.close()
                    return contactID
                }
                contactIDCursor.close()
            }
            return "\(rawContactID)"
        }
        throw ContactError.saveFailed("Failed to create contact")
    }

    private func updateAndroidContact(_ contact: Contact) throws {
        guard let contactID = contact.id else {
            throw ContactError.invalidData("Contact must have an id to update")
        }

        // Delete and recreate is the simplest reliable approach for Android
        try deleteAndroidContact(id: contactID)
        let newContact = Contact(
            contactType: contact.contactType,
            namePrefix: contact.namePrefix,
            givenName: contact.givenName,
            middleName: contact.middleName,
            familyName: contact.familyName,
            nameSuffix: contact.nameSuffix,
            nickname: contact.nickname,
            phoneticGivenName: contact.phoneticGivenName,
            phoneticMiddleName: contact.phoneticMiddleName,
            phoneticFamilyName: contact.phoneticFamilyName,
            previousFamilyName: contact.previousFamilyName,
            organizationName: contact.organizationName,
            departmentName: contact.departmentName,
            jobTitle: contact.jobTitle,
            phoneNumbers: contact.phoneNumbers,
            emailAddresses: contact.emailAddresses,
            postalAddresses: contact.postalAddresses,
            urlAddresses: contact.urlAddresses,
            instantMessageAddresses: contact.instantMessageAddresses,
            socialProfiles: contact.socialProfiles,
            birthday: contact.birthday,
            dates: contact.dates,
            relationships: contact.relationships,
            note: contact.note,
            image: contact.image
        )
        let _ = try createAndroidContact(newContact)
    }

    private func deleteAndroidContact(id: String) throws {
        let context = ProcessInfo.processInfo.androidContext
        let resolver = context.getContentResolver()

        // Look up raw contact IDs for this contact
        let rawCursor = resolver.query(
            android.provider.ContactsContract.RawContacts.CONTENT_URI,
            [android.provider.ContactsContract.RawContacts._ID].toList().toTypedArray(),
            "\(android.provider.ContactsContract.RawContacts.CONTACT_ID) = ?",
            [id].toList().toTypedArray(),
            nil
        )

        var deleted = false
        if let rawCursor = rawCursor {
            while rawCursor.moveToNext() {
                let rawID = rawCursor.getString(0) ?? ""
                let rawUri = android.content.ContentUris.withAppendedId(android.provider.ContactsContract.RawContacts.CONTENT_URI, java.lang.Long.parseLong(rawID))
                resolver.delete(rawUri, nil, nil)
                deleted = true
            }
            rawCursor.close()
        }

        if !deleted {
            throw ContactError.contactNotFound
        }
    }

    private func getAndroidGroups() throws -> [ContactGroup] {
        let context = ProcessInfo.processInfo.androidContext
        let resolver = context.getContentResolver()
        let cursor = resolver.query(
            android.provider.ContactsContract.Groups.CONTENT_URI,
            [android.provider.ContactsContract.Groups._ID, android.provider.ContactsContract.Groups.TITLE].toList().toTypedArray(),
            nil, nil, nil
        )

        var groups: [ContactGroup] = []
        if let cursor = cursor {
            while cursor.moveToNext() {
                let id = cursor.getString(0) ?? ""
                let name = cursor.getString(1) ?? ""
                groups.append(ContactGroup(id: id, name: name))
            }
            cursor.close()
        }
        return groups
    }

    private func createAndroidGroup(name: String) throws -> String {
        let context = ProcessInfo.processInfo.androidContext
        let resolver = context.getContentResolver()
        let values = android.content.ContentValues()
        values.put(android.provider.ContactsContract.Groups.TITLE, name)
        let uri = resolver.insert(android.provider.ContactsContract.Groups.CONTENT_URI, values)
        if let uri = uri {
            return "\(android.content.ContentUris.parseId(uri))"
        }
        throw ContactError.saveFailed("Failed to create group")
    }

    private func deleteAndroidGroup(id: String) throws {
        let context = ProcessInfo.processInfo.androidContext
        let resolver = context.getContentResolver()
        let uri = android.content.ContentUris.withAppendedId(android.provider.ContactsContract.Groups.CONTENT_URI, java.lang.Long.parseLong(id))
        let deleted = resolver.delete(uri, nil, nil)
        if deleted == 0 {
            throw ContactError.groupNotFound
        }
    }

    private func addAndroidContactToGroup(contactID: String, groupID: String) throws {
        let context = ProcessInfo.processInfo.androidContext
        let resolver = context.getContentResolver()

        // Find raw contact ID
        let rawCursor = resolver.query(
            android.provider.ContactsContract.RawContacts.CONTENT_URI,
            [android.provider.ContactsContract.RawContacts._ID].toList().toTypedArray(),
            "\(android.provider.ContactsContract.RawContacts.CONTACT_ID) = ?",
            [contactID].toList().toTypedArray(),
            nil
        )
        guard let rawCursor = rawCursor, rawCursor.moveToFirst() else {
            throw ContactError.contactNotFound
        }
        let rawContactID = rawCursor.getString(0) ?? ""
        rawCursor.close()

        let values = android.content.ContentValues()
        values.put(android.provider.ContactsContract.Data.RAW_CONTACT_ID, rawContactID)
        values.put(android.provider.ContactsContract.Data.MIMETYPE, android.provider.ContactsContract.CommonDataKinds.GroupMembership.CONTENT_ITEM_TYPE)
        values.put(android.provider.ContactsContract.CommonDataKinds.GroupMembership.GROUP_ROW_ID, groupID)
        resolver.insert(android.provider.ContactsContract.Data.CONTENT_URI, values)
    }

    private func removeAndroidContactFromGroup(contactID: String, groupID: String) throws {
        let context = ProcessInfo.processInfo.androidContext
        let resolver = context.getContentResolver()

        let rawCursor = resolver.query(
            android.provider.ContactsContract.RawContacts.CONTENT_URI,
            [android.provider.ContactsContract.RawContacts._ID].toList().toTypedArray(),
            "\(android.provider.ContactsContract.RawContacts.CONTACT_ID) = ?",
            [contactID].toList().toTypedArray(),
            nil
        )
        guard let rawCursor = rawCursor, rawCursor.moveToFirst() else {
            throw ContactError.contactNotFound
        }
        let rawContactID = rawCursor.getString(0) ?? ""
        rawCursor.close()

        let selection = "\(android.provider.ContactsContract.Data.RAW_CONTACT_ID) = ? AND \(android.provider.ContactsContract.Data.MIMETYPE) = ? AND \(android.provider.ContactsContract.CommonDataKinds.GroupMembership.GROUP_ROW_ID) = ?"
        resolver.delete(android.provider.ContactsContract.Data.CONTENT_URI, selection, [rawContactID, android.provider.ContactsContract.CommonDataKinds.GroupMembership.CONTENT_ITEM_TYPE, groupID].toList().toTypedArray())
    }

    private func getAndroidContainers() throws -> [ContactContainer] {
        let context = ProcessInfo.processInfo.androidContext
        let resolver = context.getContentResolver()
        let cursor = resolver.query(
            android.provider.ContactsContract.RawContacts.CONTENT_URI,
            [android.provider.ContactsContract.RawContacts.ACCOUNT_NAME, android.provider.ContactsContract.RawContacts.ACCOUNT_TYPE].toList().toTypedArray(),
            nil, nil,
            "\(android.provider.ContactsContract.RawContacts.ACCOUNT_NAME) ASC"
        )

        var seen = Set<String>()
        var containers: [ContactContainer] = []
        if let cursor = cursor {
            while cursor.moveToNext() {
                let name = cursor.getString(0) ?? "Local"
                let type = cursor.getString(1) ?? "local"
                let key = "\(name):\(type)"
                if !seen.contains(key) {
                    seen.insert(key)
                    let containerType: ContainerType
                    if type.contains("exchange") {
                        containerType = .exchange
                    } else if type.contains("carddav") || type.contains("google") {
                        containerType = .cardDAV
                    } else if type == "local" || name == "Local" {
                        containerType = .local
                    } else {
                        containerType = .unassigned
                    }
                    containers.append(ContactContainer(id: key, name: name, type: containerType))
                }
            }
            cursor.close()
        }

        if containers.isEmpty {
            containers.append(ContactContainer(id: "local", name: "Local", type: .local))
        }
        return containers
    }

    private func getAndroidDefaultContainerID() throws -> String {
        let containers = try getAndroidContainers()
        return containers.first?.id ?? "local"
    }

    // MARK: - Android Type Conversion Helpers

    private func androidPhoneTypeToLabel(_ type: Int) -> PhoneLabel {
        switch type {
        case android.provider.ContactsContract.CommonDataKinds.Phone.TYPE_HOME: return .home
        case android.provider.ContactsContract.CommonDataKinds.Phone.TYPE_WORK: return .work
        case android.provider.ContactsContract.CommonDataKinds.Phone.TYPE_MOBILE: return .mobile
        case android.provider.ContactsContract.CommonDataKinds.Phone.TYPE_MAIN: return .main
        case android.provider.ContactsContract.CommonDataKinds.Phone.TYPE_FAX_HOME: return .homeFax
        case android.provider.ContactsContract.CommonDataKinds.Phone.TYPE_FAX_WORK: return .workFax
        case android.provider.ContactsContract.CommonDataKinds.Phone.TYPE_PAGER: return .pager
        default: return .other
        }
    }

    private func labelToAndroidPhoneType(_ label: PhoneLabel) -> Int {
        switch label {
        case .home: return android.provider.ContactsContract.CommonDataKinds.Phone.TYPE_HOME
        case .work: return android.provider.ContactsContract.CommonDataKinds.Phone.TYPE_WORK
        case .mobile: return android.provider.ContactsContract.CommonDataKinds.Phone.TYPE_MOBILE
        case .main: return android.provider.ContactsContract.CommonDataKinds.Phone.TYPE_MAIN
        case .iPhone: return android.provider.ContactsContract.CommonDataKinds.Phone.TYPE_MOBILE
        case .homeFax: return android.provider.ContactsContract.CommonDataKinds.Phone.TYPE_FAX_HOME
        case .workFax: return android.provider.ContactsContract.CommonDataKinds.Phone.TYPE_FAX_WORK
        case .pager: return android.provider.ContactsContract.CommonDataKinds.Phone.TYPE_PAGER
        case .other: return android.provider.ContactsContract.CommonDataKinds.Phone.TYPE_OTHER
        }
    }

    private func androidEmailTypeToLabel(_ type: Int) -> EmailLabel {
        switch type {
        case android.provider.ContactsContract.CommonDataKinds.Email.TYPE_HOME: return .home
        case android.provider.ContactsContract.CommonDataKinds.Email.TYPE_WORK: return .work
        default: return .other
        }
    }

    private func labelToAndroidEmailType(_ label: EmailLabel) -> Int {
        switch label {
        case .home: return android.provider.ContactsContract.CommonDataKinds.Email.TYPE_HOME
        case .work: return android.provider.ContactsContract.CommonDataKinds.Email.TYPE_WORK
        case .iCloud: return android.provider.ContactsContract.CommonDataKinds.Email.TYPE_OTHER
        case .other: return android.provider.ContactsContract.CommonDataKinds.Email.TYPE_OTHER
        }
    }

    private func androidAddressTypeToLabel(_ type: Int) -> AddressLabel {
        switch type {
        case android.provider.ContactsContract.CommonDataKinds.StructuredPostal.TYPE_HOME: return .home
        case android.provider.ContactsContract.CommonDataKinds.StructuredPostal.TYPE_WORK: return .work
        default: return .other
        }
    }

    private func labelToAndroidAddressType(_ label: AddressLabel) -> Int {
        switch label {
        case .home: return android.provider.ContactsContract.CommonDataKinds.StructuredPostal.TYPE_HOME
        case .work: return android.provider.ContactsContract.CommonDataKinds.StructuredPostal.TYPE_WORK
        case .other: return android.provider.ContactsContract.CommonDataKinds.StructuredPostal.TYPE_OTHER
        }
    }

    private func androidRelationTypeToLabel(_ type: Int) -> RelationshipLabel {
        switch type {
        case android.provider.ContactsContract.CommonDataKinds.Relation.TYPE_SPOUSE: return .spouse
        case android.provider.ContactsContract.CommonDataKinds.Relation.TYPE_CHILD: return .child
        case android.provider.ContactsContract.CommonDataKinds.Relation.TYPE_MOTHER: return .mother
        case android.provider.ContactsContract.CommonDataKinds.Relation.TYPE_FATHER: return .father
        case android.provider.ContactsContract.CommonDataKinds.Relation.TYPE_PARENT: return .parent
        case android.provider.ContactsContract.CommonDataKinds.Relation.TYPE_BROTHER: return .sibling
        case android.provider.ContactsContract.CommonDataKinds.Relation.TYPE_SISTER: return .sibling
        case android.provider.ContactsContract.CommonDataKinds.Relation.TYPE_FRIEND: return .friend
        case android.provider.ContactsContract.CommonDataKinds.Relation.TYPE_MANAGER: return .manager
        case android.provider.ContactsContract.CommonDataKinds.Relation.TYPE_ASSISTANT: return .assistant
        case android.provider.ContactsContract.CommonDataKinds.Relation.TYPE_DOMESTIC_PARTNER: return .partner
        default: return .other
        }
    }

    private func labelToAndroidRelationType(_ label: RelationshipLabel) -> Int {
        switch label {
        case .spouse: return android.provider.ContactsContract.CommonDataKinds.Relation.TYPE_SPOUSE
        case .child: return android.provider.ContactsContract.CommonDataKinds.Relation.TYPE_CHILD
        case .mother: return android.provider.ContactsContract.CommonDataKinds.Relation.TYPE_MOTHER
        case .father: return android.provider.ContactsContract.CommonDataKinds.Relation.TYPE_FATHER
        case .parent: return android.provider.ContactsContract.CommonDataKinds.Relation.TYPE_PARENT
        case .sibling: return android.provider.ContactsContract.CommonDataKinds.Relation.TYPE_BROTHER
        case .friend: return android.provider.ContactsContract.CommonDataKinds.Relation.TYPE_FRIEND
        case .manager: return android.provider.ContactsContract.CommonDataKinds.Relation.TYPE_MANAGER
        case .assistant: return android.provider.ContactsContract.CommonDataKinds.Relation.TYPE_ASSISTANT
        case .partner: return android.provider.ContactsContract.CommonDataKinds.Relation.TYPE_DOMESTIC_PARTNER
        case .other: return android.provider.ContactsContract.CommonDataKinds.Relation.TYPE_CUSTOM
        }
    }

    private func androidIMProtocolToString(_ protocol_: Int) -> String {
        switch protocol_ {
        case android.provider.ContactsContract.CommonDataKinds.Im.PROTOCOL_AIM: return "AIM"
        case android.provider.ContactsContract.CommonDataKinds.Im.PROTOCOL_MSN: return "MSN"
        case android.provider.ContactsContract.CommonDataKinds.Im.PROTOCOL_YAHOO: return "Yahoo"
        case android.provider.ContactsContract.CommonDataKinds.Im.PROTOCOL_SKYPE: return "Skype"
        case android.provider.ContactsContract.CommonDataKinds.Im.PROTOCOL_QQ: return "QQ"
        case android.provider.ContactsContract.CommonDataKinds.Im.PROTOCOL_GOOGLE_TALK: return "Google Talk"
        case android.provider.ContactsContract.CommonDataKinds.Im.PROTOCOL_ICQ: return "ICQ"
        case android.provider.ContactsContract.CommonDataKinds.Im.PROTOCOL_JABBER: return "Jabber"
        default: return "Other"
        }
    }

    private func parseAndroidDateString(_ dateStr: String) -> (day: Int, month: Int, year: Int?) {
        // Android dates are in format "YYYY-MM-DD" or "--MM-DD" (no year)
        let parts = dateStr.split(separator: "-").map { String($0) }
        if dateStr.hasPrefix("--") && parts.count >= 2 {
            let month = Int(parts[0]) ?? 1
            let day = Int(parts[1]) ?? 1
            return (day: day, month: month, year: nil)
        } else if parts.count >= 3 {
            let year = Int(parts[0])
            let month = Int(parts[1]) ?? 1
            let day = Int(parts[2]) ?? 1
            return (day: day, month: month, year: year)
        }
        return (day: 1, month: 1, year: nil)
    }

    private func formatAndroidDateString(day: Int, month: Int, year: Int?) -> String {
        if let year = year {
            return String(format: "%04d-%02d-%02d", year, month, day)
        } else {
            return String(format: "--%02d-%02d", month, day)
        }
    }
}

#endif

#endif
