# SkipContacts

A cross-platform contacts framework for [Skip](https://skip.dev) apps, providing a unified API for querying, creating, updating, and deleting contacts on both iOS and Android.

On iOS, SkipContacts wraps Apple's [Contacts](https://developer.apple.com/documentation/contacts) and [ContactsUI](https://developer.apple.com/documentation/contactsui) frameworks. On Android, it uses the [ContactsContract](https://developer.android.com/reference/android/provider/ContactsContract) content provider.

## Setup

To use SkipContacts in your project, add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://source.skip.tools/skip-contacts.git", "0.0.0"..<"2.0.0")
]
```

And add `SkipContacts` as a dependency of your target:

```swift
.target(name: "MyApp", dependencies: [
    .product(name: "SkipContacts", package: "skip-contacts")
])
```

## Prerequisites

### iOS

Add the following usage description to your app's `Info.plist` or `.xcconfig`:

```xml
<key>NSContactsUsageDescription</key>
<string>This app needs access to your contacts.</string>
```

Or in your `.xcconfig`:

```
INFOPLIST_KEY_NSContactsUsageDescription = This app needs access to your contacts.
```

#### Reading contact notes (restricted)

The contact **note** field is restricted by Apple. Reading it requires the special
`com.apple.developer.contacts.notes` entitlement, which you must
[request from and be approved by Apple](https://developer.apple.com/contact/request/contact-note-field).
Fetching a contact with the note key in `keysToFetch` while the app lacks this
entitlement will fail.

Because most apps do not have this entitlement, the `note` field is **excluded
from the default field set** (`.all`) so fetches work out of the box. Notes are
only read when you explicitly request the `.note` field (see
[Selecting fields to fetch](#selecting-fields-to-fetch)):

```swift
// Default (.all) — does not touch the restricted note field, no entitlement needed
let contact = try manager.getContact(id: contactID)

// Opt in — only works if your app has the com.apple.developer.contacts.notes entitlement
let withNote = try manager.getContact(id: contactID, fields: .everything)
```

Writing the note field (setting `Contact.note` to a non-empty value before
`createContact`/`updateContact`) likewise requires the entitlement. If your app
does not have it, leave `Contact.note` empty. This restriction is iOS-only; on
Android the note is read and written normally.

### Android

Add the following permissions to your `AndroidManifest.xml` (or the test target's `Skip/AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.READ_CONTACTS" />
<uses-permission android:name="android.permission.WRITE_CONTACTS" />
```

## Permissions

Always check and request contacts permission before performing operations:

```swift
import SkipContacts

// Check current permission status (synchronous, no prompt)
let status = ContactManager.queryContactsPermission()

switch status {
case .authorized:
    // Full access granted
    break
case .limited:
    // Limited access (iOS 18+)
    break
case .denied:
    // User denied access
    break
case .restricted:
    // Access restricted by policy
    break
case .unknown:
    // Not yet determined - request permission
    let result = await ContactManager.requestContactsPermission()
    if result == .authorized {
        // Access granted
    }
}
```

## Fetching Contacts

### Fetch all contacts

```swift
let manager = ContactManager.shared
let result = try manager.getContacts()
for contact in result.contacts {
    print("\(contact.displayName): \(contact.phoneNumbers.first?.value ?? "")")
}
```

### Fetch with options

```swift
let options = ContactFetchOptions(
    nameFilter: "John",
    pageSize: 20,
    pageOffset: 0,
    sortOrder: .givenName,
    fields: .all // every field except the restricted note; see "Selecting fields to fetch"
)
let result = try manager.getContacts(options: options)

// Check if there are more results
if result.hasNextPage {
    // Fetch next page
    let nextOptions = ContactFetchOptions(
        nameFilter: "John",
        pageSize: 20,
        pageOffset: 20
    )
    let nextResult = try manager.getContacts(options: nextOptions)
}
```

### Fetch a single contact by ID

```swift
if let contact = try manager.getContact(id: contactID) {
    print(contact.displayName)
    print(contact.givenName)
    print(contact.familyName)
}

// Fetch only the fields you need (see "Selecting fields to fetch")
let light = try manager.getContact(id: contactID, fields: .summary)
```

### Fetch all contacts in a group

Pass a group identifier (see [Contact Groups](#contact-groups)) to retrieve every
contact that is a member of that group:

```swift
let contacts = try manager.getContacts(inGroup: groupID)
for contact in contacts {
    print(contact.displayName)
}
```

The same filter is available on `ContactFetchOptions` via `groupID`, so it can be
combined with sorting, pagination, and field selection:

```swift
let options = ContactFetchOptions(
    groupID: groupID,
    sortOrder: .familyName,
    fields: .summary
)
let result = try manager.getContacts(options: options)
```

### Find contacts by phone number or email

Look up contacts by a phone number or email address. Matching is performed by the
platform using its own normalization rules, so formatting differences (spaces,
dashes, parentheses, and — on Android — country-code variations) are generally
ignored:

```swift
// By phone number
let byPhone = try manager.getContacts(matchingPhoneNumber: "+1 (555) 012-3456")

// By email address
let byEmail = try manager.getContacts(matchingEmail: "jane@example.com")
```

The same filters are available on `ContactFetchOptions` via `phoneNumberFilter` and
`emailFilter`, so they compose with sorting, pagination, and field selection:

```swift
let options = ContactFetchOptions(phoneNumberFilter: "+15550123456", fields: .summary)
let result = try manager.getContacts(options: options)
```

> Note: when more than one filter is set, only the most specific one is applied.
> The precedence is `contactIDs` → `groupID` → `phoneNumberFilter` → `emailFilter`
> → `nameFilter`. To combine filters, fetch with one and filter the results in
> Swift.

### Check if contacts exist

```swift
let hasAny = try manager.hasContacts()
```

### Selecting fields to fetch

By default, fetches populate every field except the entitlement-restricted note.
When you only need some of the data — for example, name and phone number for a
list row — request a narrower set of fields with the `ContactFields` option set.
The platform then loads only the requested keys, which can substantially improve
performance and reduce memory use on large address books.

```swift
// Lightweight fetch for a list: name, phone numbers, and email addresses
let people = try manager.getContacts(options: ContactFetchOptions(fields: .summary))

// A custom set: just names and images
let withPhotos = try manager.getContacts(options: ContactFetchOptions(fields: ContactFields.name.union(.image)))

// Combine the convenience presets with extra fields
let everythingPlusNote = ContactFields.all.union(.note) // == .everything
```

Available fields and presets:

| Field | Contents |
|-------|----------|
| `.name` | Prefix, given, middle, family, suffix, nickname, phonetic names |
| `.phoneNumbers` | Phone numbers |
| `.emailAddresses` | Email addresses |
| `.postalAddresses` | Postal addresses |
| `.organization` | Organization, department, job title |
| `.urlAddresses` | URL addresses |
| `.instantMessageAddresses` | Instant message addresses |
| `.socialProfiles` | Social profiles (read support is iOS-only) |
| `.dates` | Birthday and other dates |
| `.relationships` | Relationships |
| `.image` | Thumbnail and full-size image data |
| `.note` | Note field — requires the iOS notes entitlement (see above) |
| `.summary` | `.name`, `.phoneNumbers`, `.emailAddresses` |
| `.all` | Every field **except** `.note` (the default) |
| `.everything` | Every field **including** `.note` |

> Note: Unrequested fields are left at their empty defaults on the returned
> `Contact` (e.g. `postalAddresses` is `[]`, `organizationName` is `""`). On iOS,
> requesting only the fields you need also avoids fetching keys you may not be
> entitled to.

## Creating Contacts

```swift
let contact = Contact(
    contactType: .person,
    givenName: "Jane",
    familyName: "Doe",
    organizationName: "Acme Corp",
    jobTitle: "Engineer"
)

contact.phoneNumbers = [
    ContactPhoneNumber(label: .mobile, value: "+1-555-0123"),
    ContactPhoneNumber(label: .work, value: "+1-555-0456")
]

contact.emailAddresses = [
    ContactEmailAddress(label: .work, value: "jane@acme.com"),
    ContactEmailAddress(label: .home, value: "jane@example.com")
]

contact.postalAddresses = [
    ContactPostalAddress(
        label: .home,
        street: "123 Main St",
        city: "Springfield",
        state: "IL",
        postalCode: "62701",
        country: "USA"
    )
]

contact.birthday = ContactDate(label: .birthday, day: 15, month: 6, year: 1990)

contact.relationships = [
    ContactRelationship(label: .spouse, name: "John Doe")
]

contact.note = "Met at conference"

let newID = try manager.createContact(contact)
```

## Updating Contacts

Always fetch the full contact first, mutate it, then write it back. The update is
performed in place (the identifier and unmanaged data like group membership are
preserved), and it replaces the contact's managed fields with what the model
carries — see [Updating contacts](#updating-contacts) for the full semantics.

```swift
// Fetch the contact first (default `.all` fetches every field except the note)
if let contact = try manager.getContact(id: contactID) {
    contact.jobTitle = "Senior Engineer"
    contact.phoneNumbers.append(
        ContactPhoneNumber(label: .home, value: "+1-555-9999")
    )
    try manager.updateContact(contact)
}
```

## Deleting Contacts

```swift
try manager.deleteContact(id: contactID)
```

## Batch Operations

Create, update, or delete many contacts at once. This is far more efficient than
issuing one call per contact: on iOS the whole batch is committed as a single
`CNSaveRequest`, and on Android as a single `ContentResolver.applyBatch`
transaction.

```swift
// Create many contacts; returns the new identifiers in input order
let newIDs = try manager.createContacts([
    Contact(givenName: "Ada", familyName: "Lovelace"),
    Contact(givenName: "Alan", familyName: "Turing"),
    Contact(givenName: "Grace", familyName: "Hopper")
])

// Update many contacts (each must have a valid `id`)
let edits = newIDs.map { id in
    let c = Contact(id: id, givenName: "Updated", familyName: "Name")
    return c
}
try manager.updateContacts(edits)

// Delete many contacts by ID
try manager.deleteContacts(ids: newIDs)
```

Empty arrays are a no-op (and don't require contacts permission). The return value
of `createContacts` is `@discardableResult`, so it can be ignored when the new
identifiers aren't needed.

> Note: All three batch operations are committed as a single transaction on both
> platforms (one `CNSaveRequest` on iOS, one `ContentResolver.applyBatch` on
> Android), so a failure rolls the whole batch back. Updates are applied in place
> and preserve each contact's identifier. See [Updating contacts](#updating-contacts)
> for the field-replacement semantics that apply to both single and batch updates.

## Contact Groups

```swift
// List groups
let groups = try manager.getGroups()
for group in groups {
    print("\(group.name) (\(group.id ?? ""))")
}

// Create a group
let groupID = try manager.createGroup(name: "Book Club")

// Add a contact to a group
try manager.addContactToGroup(contactID: contactID, groupID: groupID)

// List all contacts in a group
let members = try manager.getContacts(inGroup: groupID)

// Remove a contact from a group
try manager.removeContactFromGroup(contactID: contactID, groupID: groupID)

// Delete a group
try manager.deleteGroup(id: groupID)
```

## Containers / Accounts

```swift
// List containers (accounts)
let containers = try manager.getContainers()
for container in containers {
    print("\(container.name) - \(container.type)")
}

// Get default container
let defaultID = try manager.getDefaultContainerID()
```

## Contact UI

SkipContacts provides SwiftUI view modifiers for presenting native contact interfaces.

### Contact Picker

Present the system contact picker to let the user select a contact:

```swift
struct MyView: View {
    @State var showPicker = false
    @State var selectedContactID: String?

    var body: some View {
        Button("Pick Contact") {
            showPicker = true
        }
        .withContactPicker(
            isPresented: $showPicker,
            onSelectContact: { contactID in
                selectedContactID = contactID
                // Fetch full contact details
                if let contact = try? ContactManager.shared.getContact(id: contactID) {
                    print("Selected: \(contact.displayName)")
                }
            },
            onCancel: {
                print("Picker cancelled")
            }
        )
    }
}
```

### Contact Viewer

Display a contact's details using the native viewer:

```swift
struct ContactDetailView: View {
    @State var showViewer = false
    let contactID: String

    var body: some View {
        Button("View Contact") {
            showViewer = true
        }
        .withContactViewer(
            isPresented: $showViewer,
            contactID: contactID
        )
    }
}
```

### Contact Editor

Present the native editor for creating or editing contacts:

```swift
// Create a new contact with defaults
struct CreateContactView: View {
    @State var showEditor = false

    var body: some View {
        Button("New Contact") {
            showEditor = true
        }
        .withContactEditor(
            isPresented: $showEditor,
            options: ContactEditorOptions(
                defaultGivenName: "Jane",
                defaultFamilyName: "Doe",
                defaultPhoneNumber: "+1-555-0123",
                defaultEmailAddress: "jane@example.com"
            ),
            onComplete: { result in
                switch result {
                case .saved: print("Contact saved")
                case .deleted: print("Contact deleted")
                case .canceled: print("Cancelled")
                case .unknown: print("Unknown result")
                }
            }
        )
    }
}

// Edit an existing contact
struct EditContactView: View {
    @State var showEditor = false
    let contact: Contact

    var body: some View {
        Button("Edit Contact") {
            showEditor = true
        }
        .withContactEditor(
            isPresented: $showEditor,
            options: ContactEditorOptions(contact: contact),
            onComplete: { result in
                print("Editor result: \(result)")
            }
        )
    }
}
```

## Contact Data Types

### Contact

The `Contact` class contains all fields for a contact record:

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String?` | Unique identifier (nil for new contacts) |
| `contactType` | `ContactType` | `.person` or `.organization` |
| `namePrefix` | `String` | e.g., "Dr.", "Mr." |
| `givenName` | `String` | First name |
| `middleName` | `String` | Middle name |
| `familyName` | `String` | Last name |
| `nameSuffix` | `String` | e.g., "Jr.", "PhD" |
| `nickname` | `String` | Nickname |
| `phoneticGivenName` | `String` | Phonetic first name |
| `phoneticMiddleName` | `String` | Phonetic middle name |
| `phoneticFamilyName` | `String` | Phonetic last name |
| `previousFamilyName` | `String` | Maiden name |
| `organizationName` | `String` | Company name |
| `departmentName` | `String` | Department |
| `jobTitle` | `String` | Job title |
| `phoneNumbers` | `[ContactPhoneNumber]` | Phone numbers |
| `emailAddresses` | `[ContactEmailAddress]` | Email addresses |
| `postalAddresses` | `[ContactPostalAddress]` | Postal addresses |
| `urlAddresses` | `[ContactURLAddress]` | URL addresses |
| `instantMessageAddresses` | `[ContactInstantMessageAddress]` | IM addresses |
| `socialProfiles` | `[ContactSocialProfile]` | Social profiles (iOS only) |
| `birthday` | `ContactDate?` | Birthday |
| `dates` | `[ContactDate]` | Other dates (anniversary, etc.) |
| `relationships` | `[ContactRelationship]` | Relationships |
| `note` | `String` | Notes |
| `image` | `ContactImage?` | Contact photo |
| `displayName` | `String` | Computed display name |

### Labels

All labeled values (phone, email, address, etc.) support standard labels and custom labels:

**Phone labels:** `main`, `home`, `work`, `mobile`, `iPhone`, `homeFax`, `workFax`, `pager`, `other`

**Email labels:** `home`, `work`, `iCloud`, `other`

**Address labels:** `home`, `work`, `other`

**Date labels:** `birthday`, `anniversary`, `other`

**Relationship labels:** `spouse`, `child`, `mother`, `father`, `parent`, `sibling`, `friend`, `manager`, `assistant`, `partner`, `other`

**URL labels:** `home`, `work`, `homepage`, `other`

### ContactPostalAddress

```swift
let address = ContactPostalAddress(
    label: .home,
    street: "123 Main St",
    city: "Springfield",
    state: "IL",
    postalCode: "62701",
    country: "USA",
    isoCountryCode: "US"
)
print(address.formattedAddress) // "123 Main St, Springfield, IL, 62701, USA"
```

### ContactDate

Dates support year-less values for recurring events like birthdays:

```swift
let birthday = ContactDate(label: .birthday, day: 15, month: 6, year: 1990)
let anniversary = ContactDate(label: .anniversary, day: 20, month: 9) // no year
```

### ContactImage

```swift
if let image = contact.image {
    if let thumbnail = image.thumbnailData {
        // Use thumbnail data
    }
    if let fullImage = image.imageData {
        // Use full-size image data
    }
}
```

## Platform-Specific Access

### iOS

Access the underlying `CNContactStore` for advanced operations not covered by the cross-platform API:

```swift
#if !SKIP
import Contacts

let store = ContactManager.shared.contactStore

// Use CNContactStore directly
let predicate = CNContact.predicateForContacts(matchingEmailAddress: "test@example.com")
let keys: [CNKeyDescriptor] = [CNContactGivenNameKey as CNKeyDescriptor]
let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keys)
#endif
```

### Android

In `#if SKIP` blocks, you can use Android's `ContactsContract` directly:

```swift
#if SKIP
let context = ProcessInfo.processInfo.androidContext
let resolver = context.getContentResolver()

let cursor = resolver.query(
    android.provider.ContactsContract.Contacts.CONTENT_URI,
    nil, nil, nil, nil
)
// Process cursor...
cursor?.close()
#endif
```

## Platform Differences

| Feature | iOS | Android |
|---------|-----|---------|
| Social profiles | Read + write | Not available (silently ignored) |
| Instant messages | Read + write | Read + write |
| Image data | Read + write (thumbnail + full-size) | Read + write (provider may downscale) |
| Notes | Read + write (needs entitlement) | Read + write |
| Custom labels | Read + write | Read + write |
| Contact type (person/org) | Reported by the system | Inferred (company set, no personal name) |
| Contact groups | Full support | Full support |
| Containers/Accounts | Full support (iCloud, Exchange, CardDAV) | Approximate (via RawContacts accounts) |
| Contact picker | CNContactPickerViewController | ACTION_PICK intent |
| Contact viewer | CNContactViewController | ACTION_VIEW intent |
| Contact editor | CNContactViewController | ACTION_INSERT/EDIT intent |
| Multiple selection | Supported | Not supported (single pick) |
| Previous family name | Supported | Not available (no column) |
| Postal ISO country code | Supported | Not available (no column) |
| Phonetic names | Supported | Supported |

### Updating contacts

`updateContact`/`updateContacts` update in place on both platforms: the contact's
identifier is preserved, and rows the library does not manage (notably group
membership and account binding) are left intact.

Update **replaces** the contact's managed fields with what the supplied `Contact`
carries, so **fetch the full contact before updating** (the default `.all` field
set), mutate it, and write it back. Updating a contact obtained from a *narrowed*
fetch (e.g. `.summary`) will clear the fields that were not fetched. The note and
photo are the exception: they are only replaced when the model actually carries a
value, so an unfetched note (notes are excluded from `.all`) or photo is preserved
rather than cleared.

## Building

This project is a Swift Package Manager module that uses the
[Skip](https://skip.dev) plugin to build the package for both iOS and Android.

## Testing

The module can be tested using the standard `swift test` command
or by running the test target for the macOS destination in Xcode,
which will run the Swift tests as well as the transpiled
Kotlin JUnit tests in the Robolectric Android simulation environment.

Parity testing can be performed with `skip test`,
which will output a table of the test results for both platforms.

## License

This software is licensed under the
[Mozilla Public License 2.0](https://www.mozilla.org/MPL/).
