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
