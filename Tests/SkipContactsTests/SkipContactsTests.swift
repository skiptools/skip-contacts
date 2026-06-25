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
        #expect(options.groupID == nil)
        #expect(options.phoneNumberFilter == nil)
        #expect(options.emailFilter == nil)
        #expect(options.pageSize == nil)
        #expect(options.pageOffset == nil)
        #expect(options.sortOrder == .none)
        // The default field set is `.all` (every field except the restricted note).
        #expect(options.fields.rawValue == ContactFields.all.rawValue)
        #expect(options.fields.contains(.image))
        #expect(!options.fields.contains(.note))
    }

    @Test func testFetchOptionsCustom() throws {
        let options = ContactFetchOptions(
            nameFilter: "John",
            pageSize: 20,
            pageOffset: 10,
            sortOrder: .givenName,
            fields: ContactFields.summary
        )
        #expect(options.nameFilter == "John")
        #expect(options.pageSize == 20)
        #expect(options.pageOffset == 10)
        #expect(options.sortOrder == .givenName)
        #expect(options.fields.rawValue == ContactFields.summary.rawValue)
    }

    @Test func testFetchOptionsGroupFilter() throws {
        let options = ContactFetchOptions(groupID: "group-42")
        #expect(options.groupID == "group-42")
        #expect(options.nameFilter == nil)
        #expect(options.contactIDs == nil)
    }

    @Test func testFetchOptionsPhoneFilter() throws {
        let options = ContactFetchOptions(phoneNumberFilter: "+1-555-0123")
        #expect(options.phoneNumberFilter == "+1-555-0123")
        #expect(options.emailFilter == nil)
        #expect(options.nameFilter == nil)
    }

    @Test func testFetchOptionsEmailFilter() throws {
        let options = ContactFetchOptions(emailFilter: "jane@example.com")
        #expect(options.emailFilter == "jane@example.com")
        #expect(options.phoneNumberFilter == nil)
        #expect(options.nameFilter == nil)
    }

    // MARK: - Contact Fields

    @Test func testContactFieldsContains() throws {
        let fields = ContactFields.name.union(.phoneNumbers)
        #expect(fields.contains(.name))
        #expect(fields.contains(.phoneNumbers))
        #expect(!fields.contains(.emailAddresses))
        #expect(!fields.contains(.note))
    }

    @Test func testContactFieldsSummary() throws {
        let summary = ContactFields.summary
        #expect(summary.contains(.name))
        #expect(summary.contains(.phoneNumbers))
        #expect(summary.contains(.emailAddresses))
        #expect(!summary.contains(.postalAddresses))
        #expect(!summary.contains(.image))
        #expect(!summary.contains(.note))
    }

    @Test func testContactFieldsAllExcludesNote() throws {
        // `.all` must include every flag except the entitlement-restricted note.
        #expect(ContactFields.all.contains(.name))
        #expect(ContactFields.all.contains(.image))
        #expect(ContactFields.all.contains(.relationships))
        #expect(!ContactFields.all.contains(.note))

        // `.everything` adds the note on top of `.all`.
        #expect(ContactFields.everything.contains(.note))
        #expect(ContactFields.everything.contains(.image))
    }

    @Test func testContactFieldsUnion() throws {
        let combined = ContactFields.all.union(.note)
        #expect(combined.contains(.note))
        #expect(combined.contains(.name))
        #expect(combined.rawValue == ContactFields.everything.rawValue)
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

    // MARK: - Batch (empty no-op)

    @Test func testBatchEmptyNoOp() throws {
        // Empty batches short-circuit before touching the contacts store, so they
        // are safe to run on any platform without permissions.
        let manager = ContactManager.shared
        let created = try manager.createContacts([])
        #expect(created.isEmpty)
        try manager.updateContacts([])
        try manager.deleteContacts(ids: [])
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

/// Returns true only when running on a real Android device or emulator.
///
/// These integration tests are disabled on all Apple platforms because the
/// XCTest host process cannot communicate with the `contactsd` XPC service
/// — even on the iOS simulator where the Contacts entitlement is nominally
/// granted, every CNContactStore call fails with `CNErrorDomain Code=1
/// "Communication Error"`.  On macOS the test process similarly lacks the
/// required entitlements.
///
/// On Android the tests are disabled under Robolectric (no real
/// ContentProvider) but run on a connected emulator or device when
/// ANDROID_SERIAL is set.
private func isLiveDevice() -> Bool {
    #if SKIP
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
            let fetched = try #require(try ContactManager.shared.getContact(id: id, fields: ContactFields.everything))
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

    @Test func testQueryByPhoneNumber() throws {
        guard isLiveDevice() else { return }

        let suffix = Int.random(in: 1000000..<9999999)
        let phoneNumber = "+1555\(suffix)"
        let contact = Contact(givenName: "SkipPhone\(suffix)", familyName: "PhoneQuery")
        contact.phoneNumbers = [ContactPhoneNumber(label: .mobile, value: phoneNumber)]

        try withTestContact(contact) { id in
            let matches = try ContactManager.shared.getContacts(matchingPhoneNumber: phoneNumber)
            #expect(matches.contains { $0.id == id })

            // The same query is reachable through the options API.
            let viaOptions = try ContactManager.shared.getContacts(options: ContactFetchOptions(phoneNumberFilter: phoneNumber))
            #expect(viaOptions.contacts.contains { $0.id == id })
        }
    }

    @Test func testQueryByEmail() throws {
        guard isLiveDevice() else { return }

        let suffix = Int.random(in: 10000..<99999)
        let email = "skipemail\(suffix)@example.test"
        let contact = Contact(givenName: "SkipEmail\(suffix)", familyName: "EmailQuery")
        contact.emailAddresses = [ContactEmailAddress(label: .work, value: email)]

        try withTestContact(contact) { id in
            let matches = try ContactManager.shared.getContacts(matchingEmail: email)
            #expect(matches.contains { $0.id == id })

            let viaOptions = try ContactManager.shared.getContacts(options: ContactFetchOptions(emailFilter: email))
            #expect(viaOptions.contacts.contains { $0.id == id })
        }
    }

    @Test func testQueryByPhoneNumberNoMatch() throws {
        guard isLiveDevice() else { return }

        // A number that should not match any real contact in the test database.
        let matches = try ContactManager.shared.getContacts(matchingPhoneNumber: "+19995550000000")
        #expect(matches.isEmpty)
    }

    // MARK: - Selective Fields

    @Test func testFetchWithSelectiveFields() throws {
        guard isLiveDevice() else { return }

        let manager = ContactManager.shared
        let unique = "SkipFields\(Int.random(in: 10000..<99999))"
        let contact = Contact(givenName: unique, familyName: "Selective", organizationName: "Acme Inc")
        contact.phoneNumbers = [ContactPhoneNumber(label: .mobile, value: "+15557654321")]
        contact.emailAddresses = [ContactEmailAddress(label: .work, value: "\(unique)@example.test")]
        contact.postalAddresses = [ContactPostalAddress(label: .home, street: "1 Test Way", city: "Testville")]

        try withTestContact(contact) { id in
            // Summary: name + phone + email only — postal/organization must be empty.
            let summary = try #require(try manager.getContact(id: id, fields: ContactFields.summary))
            #expect(summary.givenName == unique)
            #expect(summary.phoneNumbers.count >= 1)
            #expect(summary.emailAddresses.count >= 1)
            #expect(summary.postalAddresses.isEmpty)
            #expect(summary.organizationName == "")

            // Just the organization — name should not be populated.
            let orgOnly = try #require(try manager.getContact(id: id, fields: ContactFields.organization))
            #expect(orgOnly.organizationName == "Acme Inc")
            #expect(orgOnly.givenName == "")
            #expect(orgOnly.phoneNumbers.isEmpty)

            // The full default set includes everything except the restricted note.
            let full = try #require(try manager.getContact(id: id))
            #expect(full.givenName == unique)
            #expect(full.postalAddresses.count >= 1)
            #expect(full.organizationName == "Acme Inc")
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

    // MARK: - Batch Create / Update / Delete

    @Test func testBatchCreateAndDelete() throws {
        guard isLiveDevice() else { return }

        let manager = ContactManager.shared
        let tag = "SkipBatch\(Int.random(in: 10000..<99999))"
        let contacts = [
            Contact(givenName: "\(tag)A", familyName: "BatchCreate"),
            Contact(givenName: "\(tag)B", familyName: "BatchCreate"),
            Contact(givenName: "\(tag)C", familyName: "BatchCreate")
        ]

        let ids = try manager.createContacts(contacts)
        do {
            #expect(ids.count == 3)
            for id in ids {
                let fetched = try manager.getContact(id: id)
                #expect(fetched != nil)
            }
        } catch {
            try? manager.deleteContacts(ids: ids)
            throw error
        }

        // Delete them all in one batch and confirm they are gone.
        try manager.deleteContacts(ids: ids)
        for id in ids {
            let after = try manager.getContact(id: id)
            #expect(after == nil)
        }
    }

    @Test func testBatchUpdate() throws {
        guard isLiveDevice() else { return }

        let manager = ContactManager.shared
        let tagA = "SkipBUpdA\(Int.random(in: 10000..<99999))"
        let tagB = "SkipBUpdB\(Int.random(in: 10000..<99999))"
        let ids = try manager.createContacts([
            Contact(givenName: tagA, familyName: "Before"),
            Contact(givenName: tagB, familyName: "Before")
        ])

        var caught: Error? = nil
        do {
            try manager.updateContacts([
                Contact(id: ids[0], givenName: tagA, familyName: "After"),
                Contact(id: ids[1], givenName: tagB, familyName: "After")
            ])

            // Android's update changes IDs, so look up by the unique given names.
            for tag in [tagA, tagB] {
                let result = try manager.getContacts(options: ContactFetchOptions(nameFilter: tag))
                let match = result.contacts.first { $0.givenName == tag }
                #expect(match?.familyName == "After")
            }
        } catch {
            caught = error
        }

        // Clean up by current name, since IDs may have changed on Android.
        for tag in [tagA, tagB] {
            if let result = try? manager.getContacts(options: ContactFetchOptions(nameFilter: tag)) {
                for c in result.contacts where c.givenName == tag {
                    if let cid = c.id {
                        try? manager.deleteContact(id: cid)
                    }
                }
            }
        }

        if let caught = caught {
            throw caught
        }
    }

    // MARK: - Round-trip parity & in-place update

    @Test func testUpdatePreservesIDAndGroupMembership() throws {
        guard isLiveDevice() else { return }

        let manager = ContactManager.shared
        let unique = "SkipUpdId\(Int.random(in: 10000..<99999))"
        let contact = Contact(givenName: unique, familyName: "Before")
        contact.phoneNumbers = [ContactPhoneNumber(label: .mobile, value: "+15550112233")]
        let id = try manager.createContact(contact)
        let groupName = "SkipUpdGrp\(Int.random(in: 10000..<99999))"
        let groupID = try manager.createGroup(name: groupName)

        var caught: Error? = nil
        do {
            try manager.addContactToGroup(contactID: id, groupID: groupID)

            let edit = Contact(id: id, givenName: unique, familyName: "After")
            edit.phoneNumbers = [ContactPhoneNumber(label: .mobile, value: "+15550112233")]
            try manager.updateContact(edit)

            // The update is in place, so the identifier is preserved on both platforms.
            let fetched = try #require(try manager.getContact(id: id))
            #expect(fetched.id == id)
            #expect(fetched.familyName == "After")

            // Group membership (a row the Contact model does not carry) must survive the update.
            let members = try manager.getContacts(inGroup: groupID)
            #expect(members.contains { $0.id == id })
        } catch {
            caught = error
        }
        try? manager.deleteContact(id: id)
        try? manager.deleteGroup(id: groupID)
        if let caught = caught { throw caught }
    }

    @Test func testImageRoundTrip() throws {
        guard isLiveDevice() else { return }

        // A valid 96×96 PNG (the provider's default thumbnail size; a degenerate
        // 1×1 image is rejected by Android's PhotoProcessor). The platform may
        // re-encode/downscale it, but it must round-trip as available.
        let png = try #require(Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAIAAABt+uBvAAAAxElEQVR42u3ZsQ2AMAwEQIexoWZuM4Ip4Ivovo5SnOzi5dXdNWVd45Pqu7b85ygBBAgQIECAAAESQIA+z6pz7mK79qw3/5ggQIAAAQIECBAgAQTojy7mLmaCrBggQIAAAQIkgAAByncxdzETZMUAAQIECBAgAQQIUL6LuYuZICsGCBAgQIAACSBAgPJdzF3MBFkxQIAAAQIESAABApTvYu5iJsiKAQIECBAgQAIIEKB8F3MXM0FWDBAgQIAAARJAgADF8wBXmUqRQejrQAAAAABJRU5ErkJggg=="))
        let contact = Contact(givenName: "SkipImage\(Int.random(in: 10000..<99999))", familyName: "Photo")
        contact.image = ContactImage(imageData: png)

        try withTestContact(contact) { id in
            let fetched = try #require(try ContactManager.shared.getContact(id: id, fields: ContactFields.all))
            #expect(fetched.image?.isAvailable == true)
        }
    }

    @Test func testInstantMessageRoundTrip() throws {
        guard isLiveDevice() else { return }

        let contact = Contact(givenName: "SkipIM\(Int.random(in: 10000..<99999))", familyName: "Messenger")
        contact.instantMessageAddresses = [ContactInstantMessageAddress(username: "skipper", service: "Skype")]

        try withTestContact(contact) { id in
            let fetched = try #require(try ContactManager.shared.getContact(id: id))
            #expect(fetched.instantMessageAddresses.contains { $0.username == "skipper" })
        }
    }

    @Test func testAnniversaryRoundTrip() throws {
        guard isLiveDevice() else { return }

        let contact = Contact(givenName: "SkipAnniv\(Int.random(in: 10000..<99999))", familyName: "Dates")
        contact.dates = [ContactDate(label: .anniversary, day: 14, month: 2, year: 2010)]

        try withTestContact(contact) { id in
            let fetched = try #require(try ContactManager.shared.getContact(id: id))
            let anniv = fetched.dates.first { $0.day == 14 && $0.month == 2 }
            #expect(anniv != nil)
        }
    }

    @Test func testCustomLabelRoundTrip() throws {
        guard isLiveDevice() else { return }

        let contact = Contact(givenName: "SkipCustom\(Int.random(in: 10000..<99999))", familyName: "Label")
        contact.phoneNumbers = [ContactPhoneNumber(label: .other, customLabel: "Emergency", value: "+15550199999")]

        try withTestContact(contact) { id in
            let fetched = try #require(try ContactManager.shared.getContact(id: id))
            let phone = fetched.phoneNumbers.first { $0.value.contains("0199999") }
            #expect(phone?.customLabel == "Emergency")
        }
    }

    @Test func testOrganizationContactTypeRoundTrip() throws {
        guard isLiveDevice() else { return }

        let contact = Contact(contactType: .organization, organizationName: "SkipOrg\(Int.random(in: 10000..<99999))")

        try withTestContact(contact) { id in
            let fetched = try #require(try ContactManager.shared.getContact(id: id))
            #expect(fetched.contactType == .organization)
        }
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

    @Test func testFetchContactsInGroup() throws {
        guard isLiveDevice() else { return }

        let manager = ContactManager.shared
        let memberName = "SkipGrpMember\(Int.random(in: 10000..<99999))"
        let member = Contact(givenName: memberName, familyName: "InGroup")
        let nonMember = Contact(givenName: "SkipGrpOutsider\(Int.random(in: 10000..<99999))", familyName: "NotInGroup")
        let memberID = try manager.createContact(member)
        let nonMemberID = try manager.createContact(nonMember)
        let groupName = "SkipFetchGrp\(Int.random(in: 10000..<99999))"
        let groupID = try manager.createGroup(name: groupName)

        func cleanup() {
            try? manager.deleteContact(id: memberID)
            try? manager.deleteContact(id: nonMemberID)
            try? manager.deleteGroup(id: groupID)
        }

        do {
            // An empty group should yield no members.
            let empty = try manager.getContacts(inGroup: groupID)
            #expect(empty.isEmpty)

            try manager.addContactToGroup(contactID: memberID, groupID: groupID)

            // The group should now contain exactly the member, not the outsider.
            let members = try manager.getContacts(inGroup: groupID)
            #expect(members.contains { $0.givenName == memberName })
            #expect(!members.contains { $0.familyName == "NotInGroup" })

            // The same query is also reachable via the options API.
            let viaOptions = try manager.getContacts(options: ContactFetchOptions(groupID: groupID))
            #expect(viaOptions.contacts.contains { $0.givenName == memberName })

            try manager.removeContactFromGroup(contactID: memberID, groupID: groupID)

            // After removal the group is empty again.
            let afterRemoval = try manager.getContacts(inGroup: groupID)
            #expect(!afterRemoval.contains { $0.givenName == memberName })
        } catch {
            cleanup()
            throw error
        }

        cleanup()
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
            ContactURLAddress(label: .homepage, value: "https://skip.dev")
        ]
        contact.note = "Integration test complex contact"

        try withTestContact(contact) { id in
            let fetched = try #require(try ContactManager.shared.getContact(id: id, fields: ContactFields.everything))
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
