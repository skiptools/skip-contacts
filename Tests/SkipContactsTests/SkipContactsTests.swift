// Copyright 2025–2026 Skip
// SPDX-License-Identifier: MPL-2.0

import Testing
import OSLog
import Foundation
@testable import SkipContacts

let logger: Logger = Logger(subsystem: "SkipContacts", category: "Tests")

@Suite struct SkipContactsTests {

    // MARK: - Contact Construction

    @Test func testContactConstruction() throws {
        let contact = Contact()
        #expect(contact.id == nil)
        #expect(contact.contactType == .person)
        #expect(contact.givenName == "")
        #expect(contact.familyName == "")
        #expect(contact.phoneNumbers.isEmpty)
        #expect(contact.emailAddresses.isEmpty)
        #expect(contact.postalAddresses.isEmpty)
    }

    @Test func testContactWithValues() throws {
        let contact = Contact(
            contactType: .person,
            givenName: "John",
            middleName: "M",
            familyName: "Doe",
            nickname: "Johnny",
            organizationName: "Acme Corp",
            jobTitle: "Engineer"
        )
        #expect(contact.givenName == "John")
        #expect(contact.middleName == "M")
        #expect(contact.familyName == "Doe")
        #expect(contact.nickname == "Johnny")
        #expect(contact.organizationName == "Acme Corp")
        #expect(contact.jobTitle == "Engineer")
    }

    @Test func testOrganizationContact() throws {
        let contact = Contact(
            contactType: .organization,
            organizationName: "Skip Tools"
        )
        #expect(contact.contactType == .organization)
        #expect(contact.organizationName == "Skip Tools")
    }

    // MARK: - Display Name

    @Test func testDisplayNamePerson() throws {
        let contact = Contact(givenName: "Jane", familyName: "Smith")
        #expect(contact.displayName == "Jane Smith")
    }

    @Test func testDisplayNameWithPrefix() throws {
        let contact = Contact(namePrefix: "Dr.", givenName: "Jane", familyName: "Smith")
        #expect(contact.displayName == "Dr. Jane Smith")
    }

    @Test func testDisplayNameOrganization() throws {
        let contact = Contact(contactType: .organization, organizationName: "Acme Corp")
        #expect(contact.displayName == "Acme Corp")
    }

    @Test func testDisplayNameFallbackToEmail() throws {
        let contact = Contact()
        contact.emailAddresses = [ContactEmailAddress(value: "test@example.com")]
        #expect(contact.displayName == "test@example.com")
    }

    @Test func testDisplayNameFallbackToPhone() throws {
        let contact = Contact()
        contact.phoneNumbers = [ContactPhoneNumber(value: "+1234567890")]
        #expect(contact.displayName == "+1234567890")
    }

    @Test func testDisplayNameEmpty() throws {
        let contact = Contact()
        #expect(contact.displayName == "")
    }

    // MARK: - Phone Numbers

    @Test func testPhoneNumber() throws {
        let phone = ContactPhoneNumber(label: .mobile, value: "+1-555-0123")
        #expect(phone.label == .mobile)
        #expect(phone.value == "+1-555-0123")
        #expect(phone.customLabel == nil)
    }

    @Test func testPhoneNumberWithCustomLabel() throws {
        let phone = ContactPhoneNumber(label: .other, customLabel: "Emergency", value: "911")
        #expect(phone.customLabel == "Emergency")
    }

    @Test func testPhoneLabels() throws {
        #expect(PhoneLabel.main.rawValue == "main")
        #expect(PhoneLabel.home.rawValue == "home")
        #expect(PhoneLabel.work.rawValue == "work")
        #expect(PhoneLabel.mobile.rawValue == "mobile")
        #expect(PhoneLabel.iPhone.rawValue == "iPhone")
        #expect(PhoneLabel.homeFax.rawValue == "homeFax")
        #expect(PhoneLabel.workFax.rawValue == "workFax")
        #expect(PhoneLabel.pager.rawValue == "pager")
        #expect(PhoneLabel.other.rawValue == "other")
    }

    // MARK: - Email Addresses

    @Test func testEmailAddress() throws {
        let email = ContactEmailAddress(label: .work, value: "jane@acme.com")
        #expect(email.label == .work)
        #expect(email.value == "jane@acme.com")
    }

    @Test func testEmailLabels() throws {
        #expect(EmailLabel.home.rawValue == "home")
        #expect(EmailLabel.work.rawValue == "work")
        #expect(EmailLabel.iCloud.rawValue == "iCloud")
        #expect(EmailLabel.other.rawValue == "other")
    }

    // MARK: - Postal Addresses

    @Test func testPostalAddress() throws {
        let addr = ContactPostalAddress(
            label: .home,
            street: "123 Main St",
            city: "Springfield",
            state: "IL",
            postalCode: "62701",
            country: "USA"
        )
        #expect(addr.label == .home)
        #expect(addr.street == "123 Main St")
        #expect(addr.city == "Springfield")
        #expect(addr.state == "IL")
        #expect(addr.postalCode == "62701")
        #expect(addr.country == "USA")
    }

    @Test func testFormattedAddress() throws {
        let addr = ContactPostalAddress(
            street: "123 Main St",
            city: "Springfield",
            state: "IL",
            postalCode: "62701",
            country: "USA"
        )
        #expect(addr.formattedAddress == "123 Main St, Springfield, IL, 62701, USA")
    }

    @Test func testFormattedAddressPartial() throws {
        let addr = ContactPostalAddress(city: "Springfield", state: "IL")
        #expect(addr.formattedAddress == "Springfield, IL")
    }

    @Test func testFormattedAddressEmpty() throws {
        let addr = ContactPostalAddress()
        #expect(addr.formattedAddress == "")
    }

    // MARK: - Contact Dates

    @Test func testContactDate() throws {
        let date = ContactDate(label: .birthday, day: 15, month: 6, year: 1990)
        #expect(date.label == .birthday)
        #expect(date.day == 15)
        #expect(date.month == 6)
        #expect(date.year == 1990)
    }

    @Test func testContactDateWithoutYear() throws {
        let date = ContactDate(label: .birthday, day: 25, month: 12)
        #expect(date.day == 25)
        #expect(date.month == 12)
        #expect(date.year == nil)
    }

    // MARK: - Relationships

    @Test func testRelationship() throws {
        let rel = ContactRelationship(label: .spouse, name: "Jane Doe")
        #expect(rel.label == .spouse)
        #expect(rel.name == "Jane Doe")
    }

    @Test func testRelationshipLabels() throws {
        #expect(RelationshipLabel.spouse.rawValue == "spouse")
        #expect(RelationshipLabel.child.rawValue == "child")
        #expect(RelationshipLabel.mother.rawValue == "mother")
        #expect(RelationshipLabel.father.rawValue == "father")
        #expect(RelationshipLabel.parent.rawValue == "parent")
        #expect(RelationshipLabel.sibling.rawValue == "sibling")
        #expect(RelationshipLabel.friend.rawValue == "friend")
        #expect(RelationshipLabel.manager.rawValue == "manager")
        #expect(RelationshipLabel.assistant.rawValue == "assistant")
        #expect(RelationshipLabel.partner.rawValue == "partner")
        #expect(RelationshipLabel.other.rawValue == "other")
    }

    // MARK: - URL Addresses

    @Test func testURLAddress() throws {
        let url = ContactURLAddress(label: .homepage, value: "https://example.com")
        #expect(url.label == .homepage)
        #expect(url.value == "https://example.com")
    }

    // MARK: - Instant Message Addresses

    @Test func testInstantMessageAddress() throws {
        let im = ContactInstantMessageAddress(label: .skype, username: "john.doe", service: "Skype")
        #expect(im.label == .skype)
        #expect(im.username == "john.doe")
        #expect(im.service == "Skype")
    }

    // MARK: - Social Profiles

    @Test func testSocialProfile() throws {
        let sp = ContactSocialProfile(label: .twitter, username: "johndoe", service: "Twitter", urlString: "https://twitter.com/johndoe")
        #expect(sp.label == .twitter)
        #expect(sp.username == "johndoe")
        #expect(sp.service == "Twitter")
        #expect(sp.urlString == "https://twitter.com/johndoe")
    }

    // MARK: - Contact Image

    @Test func testContactImage() throws {
        let img = ContactImage()
        #expect(!img.isAvailable)

        let imgWithData = ContactImage(thumbnailData: "AB".data(using: .utf8))
        #expect(imgWithData.isAvailable)
    }

    // MARK: - Contact Group

    @Test func testContactGroup() throws {
        let group = ContactGroup(id: "group-1", name: "Friends")
        #expect(group.id == "group-1")
        #expect(group.name == "Friends")
    }

    // MARK: - Contact Container

    @Test func testContactContainer() throws {
        let container = ContactContainer(id: "container-1", name: "iCloud", type: .cardDAV)
        #expect(container.id == "container-1")
        #expect(container.name == "iCloud")
        #expect(container.type == .cardDAV)
    }

    @Test func testContainerTypes() throws {
        #expect(ContainerType.local.rawValue == "local")
        #expect(ContainerType.exchange.rawValue == "exchange")
        #expect(ContainerType.cardDAV.rawValue == "cardDAV")
        #expect(ContainerType.unassigned.rawValue == "unassigned")
    }

    // MARK: - Fetch Options

    @Test func testFetchOptionsDefaults() throws {
        let options = ContactFetchOptions()
        #expect(options.nameFilter == nil)
        #expect(options.contactIDs == nil)
        #expect(options.pageSize == nil)
        #expect(options.pageOffset == nil)
        #expect(options.sortOrder == .none)
        #expect(options.includeImages == false)
        #expect(options.includeNote == true)
    }

    @Test func testFetchOptionsCustom() throws {
        let options = ContactFetchOptions(
            nameFilter: "John",
            pageSize: 20,
            pageOffset: 10,
            sortOrder: .givenName,
            includeImages: true,
            includeNote: false
        )
        #expect(options.nameFilter == "John")
        #expect(options.pageSize == 20)
        #expect(options.pageOffset == 10)
        #expect(options.sortOrder == .givenName)
        #expect(options.includeImages == true)
        #expect(options.includeNote == false)
    }

    // MARK: - Fetch Result

    @Test func testFetchResult() throws {
        let contacts = [Contact(givenName: "Alice"), Contact(givenName: "Bob")]
        let result = ContactFetchResult(contacts: contacts, hasNextPage: true)
        #expect(result.contacts.count == 2)
        #expect(result.hasNextPage == true)
    }

    @Test func testFetchResultEmpty() throws {
        let result = ContactFetchResult(contacts: [])
        #expect(result.contacts.isEmpty)
        #expect(result.hasNextPage == false)
    }

    // MARK: - Editor Options

    @Test func testEditorOptionsDefaults() throws {
        let options = ContactEditorOptions()
        #expect(options.contact == nil)
        #expect(options.defaultGivenName == nil)
        #expect(options.defaultFamilyName == nil)
        #expect(options.defaultOrganizationName == nil)
        #expect(options.defaultPhoneNumber == nil)
        #expect(options.defaultEmailAddress == nil)
        #expect(options.defaultNote == nil)
    }

    @Test func testEditorOptionsCustom() throws {
        let options = ContactEditorOptions(
            defaultGivenName: "Jane",
            defaultFamilyName: "Doe",
            defaultPhoneNumber: "+1234567890",
            defaultEmailAddress: "jane@example.com"
        )
        #expect(options.defaultGivenName == "Jane")
        #expect(options.defaultFamilyName == "Doe")
        #expect(options.defaultPhoneNumber == "+1234567890")
        #expect(options.defaultEmailAddress == "jane@example.com")
    }

    // MARK: - Enums

    @Test func testContactType() throws {
        #expect(ContactType.person.rawValue == "person")
        #expect(ContactType.organization.rawValue == "organization")
    }

    @Test func testContactSortOrder() throws {
        #expect(ContactSortOrder.givenName.rawValue == "givenName")
        #expect(ContactSortOrder.familyName.rawValue == "familyName")
        #expect(ContactSortOrder.none.rawValue == "none")
        #expect(ContactSortOrder.userDefault.rawValue == "userDefault")
    }

    @Test func testContactEditorResult() throws {
        #expect(ContactEditorResult.saved.rawValue == "saved")
        #expect(ContactEditorResult.deleted.rawValue == "deleted")
        #expect(ContactEditorResult.canceled.rawValue == "canceled")
        #expect(ContactEditorResult.unknown.rawValue == "unknown")
    }

    // MARK: - Complex Contact

    @Test func testComplexContact() throws {
        let contact = Contact(
            contactType: .person,
            namePrefix: "Dr.",
            givenName: "Jane",
            middleName: "M",
            familyName: "Smith",
            nameSuffix: "PhD",
            nickname: "Janey",
            organizationName: "University",
            departmentName: "Computer Science",
            jobTitle: "Professor"
        )

        contact.phoneNumbers = [
            ContactPhoneNumber(label: .mobile, value: "+1-555-0123"),
            ContactPhoneNumber(label: .work, value: "+1-555-0456")
        ]

        contact.emailAddresses = [
            ContactEmailAddress(label: .work, value: "jane.smith@university.edu"),
            ContactEmailAddress(label: .home, value: "jane@example.com")
        ]

        contact.postalAddresses = [
            ContactPostalAddress(
                label: .work,
                street: "100 University Ave",
                city: "Cambridge",
                state: "MA",
                postalCode: "02139",
                country: "USA"
            )
        ]

        contact.birthday = ContactDate(label: .birthday, day: 15, month: 3, year: 1980)

        contact.relationships = [
            ContactRelationship(label: .spouse, name: "John Smith"),
            ContactRelationship(label: .child, name: "Emily Smith")
        ]

        contact.urlAddresses = [
            ContactURLAddress(label: .homepage, value: "https://jane.example.com")
        ]

        contact.note = "Department chair"

        #expect(contact.displayName == "Dr. Jane M Smith PhD")
        #expect(contact.phoneNumbers.count == 2)
        #expect(contact.emailAddresses.count == 2)
        #expect(contact.postalAddresses.count == 1)
        #expect(contact.birthday?.day == 15)
        #expect(contact.birthday?.month == 3)
        #expect(contact.birthday?.year == 1980)
        #expect(contact.relationships.count == 2)
        #expect(contact.urlAddresses.count == 1)
        #expect(contact.note == "Department chair")
    }

    // MARK: - Contact Manager Singleton

    @Test func testContactManagerSingleton() throws {
        let manager1 = ContactManager.shared
        let manager2 = ContactManager.shared
        // Both should reference the same instance
        #expect(manager1 === manager2)
    }

    // MARK: - Resource Loading

    @Test func decodeType() throws {
        let resourceURL: URL = try #require(Bundle.module.url(forResource: "TestData", withExtension: "json"))
        let testData = try JSONDecoder().decode(TestData.self, from: Data(contentsOf: resourceURL))
        #expect(testData.testModuleName == "SkipContacts")
    }
}

struct TestData: Codable, Hashable {
    var testModuleName: String
}

// MARK: - Integration Tests (real contacts database)

/// Returns true when running on a real device or emulator (not Robolectric or macOS).
/// macOS test processes lack contacts entitlements; iOS simulator auto-grants them.
private func isLiveDevice() -> Bool {
    #if os(iOS)
    return true
    #elseif SKIP
    return android.os.Build.FINGERPRINT != nil && "robolectric" != android.os.Build.FINGERPRINT
    #else
    return false
    #endif
}

/// Helper that creates a contact and returns its ID, always cleaning it up
/// after `body` returns (even on throw).
private func withTestContact(_ contact: Contact, body: (String) throws -> Void) throws {
    let manager = ContactManager.shared
    let id = try manager.createContact(contact)
    do {
        try body(id)
        try manager.deleteContact(id: id)
    } catch {
        // best-effort cleanup
        try? manager.deleteContact(id: id)
        throw error
    }
}

@Suite struct ContactIntegrationTests {

    // SKIP INSERT:
    // @get:org.junit.Rule
    // val grantPermissionRule: androidx.test.rule.GrantPermissionRule = androidx.test.rule.GrantPermissionRule.grant(android.Manifest.permission.READ_CONTACTS, android.Manifest.permission.WRITE_CONTACTS)

    // MARK: - Create & Fetch

    @Test func testCreateAndFetchContact() throws {
        guard isLiveDevice() else { return }

        let contact = Contact(givenName: "SkipTest", familyName: "CreateFetch")
        contact.phoneNumbers = [ContactPhoneNumber(label: .mobile, value: "+15550001111")]
        contact.emailAddresses = [ContactEmailAddress(label: .work, value: "skiptest@example.test")]

        try withTestContact(contact) { id in
            let fetched = try #require(try ContactManager.shared.getContact(id: id))
            #expect(fetched.givenName == "SkipTest")
            #expect(fetched.familyName == "CreateFetch")
            #expect(fetched.phoneNumbers.count >= 1)
            #expect(fetched.emailAddresses.count >= 1)

            let phone = try #require(fetched.phoneNumbers.first)
            // Phone number formats may vary by platform; just check it contains the digits
            #expect(phone.value.contains("5550001111"))

            let email = try #require(fetched.emailAddresses.first)
            #expect(email.value == "skiptest@example.test")
        }
    }

    @Test func testCreateContactWithFullName() throws {
        guard isLiveDevice() else { return }

        let contact = Contact(
            namePrefix: "Dr.",
            givenName: "SkipInteg",
            middleName: "M",
            familyName: "FullName",
            nameSuffix: "Jr."
        )

        try withTestContact(contact) { id in
            let fetched = try #require(try ContactManager.shared.getContact(id: id))
            #expect(fetched.givenName == "SkipInteg")
            #expect(fetched.middleName == "M")
            #expect(fetched.familyName == "FullName")
            #expect(fetched.namePrefix == "Dr.")
            #expect(fetched.nameSuffix == "Jr.")
        }
    }

    @Test func testCreateOrganizationContact() throws {
        guard isLiveDevice() else { return }

        let contact = Contact(
            contactType: .organization,
            organizationName: "SkipTest Corp",
            departmentName: "Engineering",
            jobTitle: "Tester"
        )

        try withTestContact(contact) { id in
            let fetched = try #require(try ContactManager.shared.getContact(id: id))
            #expect(fetched.organizationName == "SkipTest Corp")
            #expect(fetched.departmentName == "Engineering")
            #expect(fetched.jobTitle == "Tester")
        }
    }

    @Test func testCreateContactWithPostalAddress() throws {
        guard isLiveDevice() else { return }

        let contact = Contact(givenName: "SkipTest", familyName: "Address")
        contact.postalAddresses = [
            ContactPostalAddress(
                label: .home,
                street: "123 Test Street",
                city: "Testville",
                state: "TS",
                postalCode: "99999",
                country: "US"
            )
        ]

        try withTestContact(contact) { id in
            let fetched = try #require(try ContactManager.shared.getContact(id: id))
            #expect(fetched.postalAddresses.count >= 1)
            let addr = try #require(fetched.postalAddresses.first)
            #expect(addr.street == "123 Test Street")
            #expect(addr.city == "Testville")
            #expect(addr.state == "TS")
            #expect(addr.postalCode == "99999")
        }
    }

    @Test func testCreateContactWithMultiplePhones() throws {
        guard isLiveDevice() else { return }

        let contact = Contact(givenName: "SkipTest", familyName: "MultiPhone")
        contact.phoneNumbers = [
            ContactPhoneNumber(label: .mobile, value: "+15550002222"),
            ContactPhoneNumber(label: .work, value: "+15550003333"),
            ContactPhoneNumber(label: .home, value: "+15550004444")
        ]

        try withTestContact(contact) { id in
            let fetched = try #require(try ContactManager.shared.getContact(id: id))
            #expect(fetched.phoneNumbers.count == 3)
        }
    }

    @Test func testCreateContactWithNote() throws {
        guard isLiveDevice() else { return }

        let contact = Contact(givenName: "SkipTest", familyName: "WithNote")
        contact.note = "This is a test note from skip-contacts integration tests"

        try withTestContact(contact) { id in
            let fetched = try #require(try ContactManager.shared.getContact(id: id, includeNote: true))
            #expect(fetched.note == "This is a test note from skip-contacts integration tests")
        }
    }

    // MARK: - Query / Filter

    @Test func testQueryByName() throws {
        guard isLiveDevice() else { return }

        let contact = Contact(givenName: "SkipUnique\(Int.random(in: 10000..<99999))", familyName: "QueryTest")

        try withTestContact(contact) { _ in
            let options = ContactFetchOptions(nameFilter: contact.givenName)
            let result = try ContactManager.shared.getContacts(options: options)
            #expect(result.contacts.count >= 1)
            let match = result.contacts.first { $0.givenName == contact.givenName }
            #expect(match != nil)
        }
    }

    @Test func testQueryByID() throws {
        guard isLiveDevice() else { return }

        let contact = Contact(givenName: "SkipTest", familyName: "QueryByID")

        try withTestContact(contact) { id in
            let options = ContactFetchOptions(contactIDs: [id])
            let result = try ContactManager.shared.getContacts(options: options)
            #expect(result.contacts.count == 1)
            #expect(result.contacts.first?.givenName == "SkipTest")
        }
    }

    @Test func testHasContacts() throws {
        guard isLiveDevice() else { return }

        let contact = Contact(givenName: "SkipTest", familyName: "HasContacts")

        try withTestContact(contact) { _ in
            let has = try ContactManager.shared.hasContacts()
            #expect(has == true)
        }
    }

    // MARK: - Update

    @Test func testUpdateContact() throws {
        guard isLiveDevice() else { return }

        let manager = ContactManager.shared
        let uniqueName = "SkipUpd\(Int.random(in: 10000..<99999))"
        let contact = Contact(givenName: uniqueName, familyName: "BeforeUpdate")
        let id = try manager.createContact(contact)

        let toUpdate = Contact(id: id, givenName: uniqueName, familyName: "AfterUpdate")
        toUpdate.emailAddresses = [ContactEmailAddress(label: .work, value: "updated@example.test")]
        try manager.updateContact(toUpdate)

        // Android's update does delete+recreate which changes the ID,
        // so query by name instead of the original ID.
        let result = try manager.getContacts(options: ContactFetchOptions(nameFilter: uniqueName))
        let fetched = try #require(result.contacts.first { $0.givenName == uniqueName })
        #expect(fetched.familyName == "AfterUpdate")
        #expect(fetched.emailAddresses.count >= 1)
        let email = try #require(fetched.emailAddresses.first)
        #expect(email.value == "updated@example.test")

        // Clean up using the (potentially new) ID
        if let newID = fetched.id {
            try? manager.deleteContact(id: newID)
        }
    }

    // MARK: - Delete

    @Test func testDeleteContact() throws {
        guard isLiveDevice() else { return }

        let manager = ContactManager.shared
        let contact = Contact(givenName: "SkipTest", familyName: "ToDelete")
        let id = try manager.createContact(contact)

        // Verify it exists
        let before = try manager.getContact(id: id)
        #expect(before != nil)

        // Delete
        try manager.deleteContact(id: id)

        // Verify it no longer exists
        let after = try manager.getContact(id: id)
        #expect(after == nil)
    }

    // MARK: - Groups

    @Test func testCreateAndDeleteGroup() throws {
        guard isLiveDevice() else { return }

        let manager = ContactManager.shared
        let groupName = "SkipTestGroup\(Int.random(in: 10000..<99999))"
        let groupID = try manager.createGroup(name: groupName)

        // Verify the group was created and can be found
        let groups = try manager.getGroups()
        let found = groups.first { $0.name == groupName }
        #expect(found != nil)

        // Delete should succeed without throwing
        try manager.deleteGroup(id: groupID)
    }

    @Test func testAddContactToGroup() throws {
        guard isLiveDevice() else { return }

        let manager = ContactManager.shared
        let contact = Contact(givenName: "SkipTest", familyName: "GroupMember")
        let contactID = try manager.createContact(contact)
        let groupName = "SkipTestGrp\(Int.random(in: 10000..<99999))"
        let groupID = try manager.createGroup(name: groupName)

        do {
            try manager.addContactToGroup(contactID: contactID, groupID: groupID)
            try manager.removeContactFromGroup(contactID: contactID, groupID: groupID)
        } catch {
            try? manager.deleteContact(id: contactID)
            try? manager.deleteGroup(id: groupID)
            throw error
        }

        try manager.deleteContact(id: contactID)
        try manager.deleteGroup(id: groupID)
    }

    // MARK: - Containers

    @Test func testGetContainers() throws {
        guard isLiveDevice() else { return }

        let containers = try ContactManager.shared.getContainers()
        #expect(containers.count >= 1)
    }

    @Test func testGetDefaultContainerID() throws {
        guard isLiveDevice() else { return }

        let defaultID = try ContactManager.shared.getDefaultContainerID()
        #expect(!defaultID.isEmpty)
    }

    // MARK: - Pagination

    @Test func testPagination() throws {
        guard isLiveDevice() else { return }

        let manager = ContactManager.shared
        // Create a few contacts
        var createdIDs: [String] = []
        for i in 0..<3 {
            let c = Contact(givenName: "SkipPage\(i)", familyName: "PaginationTest")
            let id = try manager.createContact(c)
            createdIDs.append(id)
        }

        do {
            // Fetch with page size 2
            let page1 = try manager.getContacts(options: ContactFetchOptions(nameFilter: "SkipPage", pageSize: 2))
            #expect(page1.contacts.count <= 2)

            // Clean up
            for id in createdIDs {
                try manager.deleteContact(id: id)
            }
        } catch {
            for id in createdIDs {
                try? manager.deleteContact(id: id)
            }
            throw error
        }
    }

    // MARK: - Complex contact round-trip

    @Test func testComplexContactRoundTrip() throws {
        guard isLiveDevice() else { return }

        let contact = Contact(
            givenName: "SkipComplex",
            familyName: "RoundTrip",
            nickname: "Skipper",
            organizationName: "Skip Tools",
            departmentName: "QA",
            jobTitle: "Test Engineer"
        )
        contact.phoneNumbers = [
            ContactPhoneNumber(label: .mobile, value: "+15550009999"),
            ContactPhoneNumber(label: .work, value: "+15550008888")
        ]
        contact.emailAddresses = [
            ContactEmailAddress(label: .home, value: "skipper@example.test"),
            ContactEmailAddress(label: .work, value: "skipper.work@example.test")
        ]
        contact.postalAddresses = [
            ContactPostalAddress(
                label: .work,
                street: "1 Skip Way",
                city: "Skiptown",
                state: "SK",
                postalCode: "00001",
                country: "US"
            )
        ]
        contact.urlAddresses = [
            ContactURLAddress(label: .homepage, value: "https://skip.tools")
        ]
        contact.note = "Integration test complex contact"

        try withTestContact(contact) { id in
            let fetched = try #require(try ContactManager.shared.getContact(id: id, includeNote: true))
            #expect(fetched.givenName == "SkipComplex")
            #expect(fetched.familyName == "RoundTrip")
            #expect(fetched.organizationName == "Skip Tools")
            #expect(fetched.jobTitle == "Test Engineer")
            #expect(fetched.phoneNumbers.count == 2)
            #expect(fetched.emailAddresses.count == 2)
            #expect(fetched.postalAddresses.count >= 1)
            #expect(fetched.note == "Integration test complex contact")
        }
    }
}
