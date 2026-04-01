// Copyright 2025–2026 Skip
// SPDX-License-Identifier: MPL-2.0

#if !SKIP_BRIDGE
import Foundation
import OSLog
#if canImport(SwiftUI)
import SwiftUI
#endif

#if !SKIP
#if canImport(ContactsUI)
import Contacts
import ContactsUI
#endif
#endif

private let uiLogger: Logger = Logger(subsystem: "skip.contacts", category: "ContactUI")

// MARK: - Contact Picker

#if canImport(SwiftUI)

extension View {
    /// Present the native contact picker.
    ///
    /// On iOS, this presents a `CNContactPickerViewController` in a sheet.
    /// On Android, this launches the system contact picker via `ACTION_PICK`.
    ///
    /// - Parameters:
    ///   - isPresented: Binding that controls picker visibility.
    ///   - multipleSelection: Whether multiple contacts can be selected (iOS only).
    ///   - onSelectContact: Called with the selected contact's ID.
    ///   - onSelectContacts: Called with multiple selected contact IDs (iOS only).
    ///   - onCancel: Called when the user cancels.
    @ViewBuilder public func withContactPicker(
        isPresented: Binding<Bool>,
        multipleSelection: Bool = false,
        onSelectContact: ((String) -> Void)? = nil,
        onSelectContacts: (([String]) -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) -> some View {
        #if SKIP
        self.onChange(of: isPresented.wrappedValue) { _, newValue in
            if newValue {
                launchAndroidContactPicker(onSelectContact: onSelectContact, onCancel: onCancel)
                isPresented.wrappedValue = false
            }
        }
        #elseif os(iOS)
        self.sheet(isPresented: isPresented) {
            ContactPickerRepresentable(
                multipleSelection: multipleSelection,
                onSelectContact: { contactID in
                    isPresented.wrappedValue = false
                    onSelectContact?(contactID)
                },
                onSelectContacts: { contactIDs in
                    isPresented.wrappedValue = false
                    onSelectContacts?(contactIDs)
                },
                onCancel: {
                    isPresented.wrappedValue = false
                    onCancel?()
                }
            )
        }
        #else
        self
        #endif
    }

    /// Present the native contact viewer for an existing contact.
    ///
    /// On iOS, this presents a `CNContactViewController` in a sheet.
    /// On Android, this launches the system contact viewer via `ACTION_VIEW`.
    ///
    /// - Parameters:
    ///   - isPresented: Binding that controls viewer visibility.
    ///   - contactID: The ID of the contact to view.
    @ViewBuilder public func withContactViewer(
        isPresented: Binding<Bool>,
        contactID: String
    ) -> some View {
        #if SKIP
        self.onChange(of: isPresented.wrappedValue) { _, newValue in
            if newValue {
                launchAndroidContactViewer(contactID: contactID)
                isPresented.wrappedValue = false
            }
        }
        #elseif os(iOS)
        self.sheet(isPresented: isPresented) {
            ContactViewRepresentable(contactID: contactID, onDismiss: {
                isPresented.wrappedValue = false
            })
        }
        #else
        self
        #endif
    }

    /// Present the native contact editor for creating or editing a contact.
    ///
    /// On iOS, this presents a `CNContactViewController` in a sheet.
    /// On Android, this launches the system contact editor via `ACTION_INSERT` or `ACTION_EDIT`.
    ///
    /// - Parameters:
    ///   - isPresented: Binding that controls editor visibility.
    ///   - options: Options for the editor (existing contact to edit or defaults for new contact).
    ///   - onComplete: Called with the result of the editor operation.
    @ViewBuilder public func withContactEditor(
        isPresented: Binding<Bool>,
        options: ContactEditorOptions = ContactEditorOptions(),
        onComplete: ((ContactEditorResult) -> Void)? = nil
    ) -> some View {
        #if SKIP
        self.onChange(of: isPresented.wrappedValue) { _, newValue in
            if newValue {
                launchAndroidContactEditor(options: options)
                isPresented.wrappedValue = false
                onComplete?(.unknown)
            }
        }
        #elseif os(iOS)
        self.sheet(isPresented: isPresented) {
            ContactEditRepresentable(
                options: options,
                onComplete: { result in
                    isPresented.wrappedValue = false
                    onComplete?(result)
                }
            )
        }
        #else
        self
        #endif
    }
}

#endif

// MARK: - Android Intent Launchers

#if SKIP

private func launchAndroidContactPicker(onSelectContact: ((String) -> Void)?, onCancel: (() -> Void)?) {
    let context = ProcessInfo.processInfo.androidContext
    let intent = android.content.Intent(android.content.Intent.ACTION_PICK, android.provider.ContactsContract.Contacts.CONTENT_URI)
    if let activity = context as? android.app.Activity {
        activity.startActivity(intent)
    } else {
        intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }
}

private func launchAndroidContactViewer(contactID: String) {
    let context = ProcessInfo.processInfo.androidContext
    let contactUri = android.content.ContentUris.withAppendedId(android.provider.ContactsContract.Contacts.CONTENT_URI, java.lang.Long.parseLong(contactID))
    let intent = android.content.Intent(android.content.Intent.ACTION_VIEW, contactUri)
    if let activity = context as? android.app.Activity {
        activity.startActivity(intent)
    } else {
        intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }
}

private func launchAndroidContactEditor(options: ContactEditorOptions) {
    let context = ProcessInfo.processInfo.androidContext
    let intent: android.content.Intent

    if let contact = options.contact, let contactID = contact.id {
        // Edit existing
        let contactUri = android.content.ContentUris.withAppendedId(android.provider.ContactsContract.Contacts.CONTENT_URI, java.lang.Long.parseLong(contactID))
        intent = android.content.Intent(android.content.Intent.ACTION_EDIT, contactUri)
    } else {
        // Create new
        intent = android.content.Intent(android.content.Intent.ACTION_INSERT, android.provider.ContactsContract.Contacts.CONTENT_URI)

        let givenName = options.defaultGivenName ?? ""
        let familyName = options.defaultFamilyName ?? ""
        if !givenName.isEmpty || !familyName.isEmpty {
            let fullName = [givenName, familyName].filter { !$0.isEmpty }.joined(separator: " ")
            intent.putExtra(android.provider.ContactsContract.Intents.Insert.NAME, fullName)
        }
        if let org = options.defaultOrganizationName, !org.isEmpty {
            intent.putExtra(android.provider.ContactsContract.Intents.Insert.COMPANY, org)
        }
        if let phone = options.defaultPhoneNumber, !phone.isEmpty {
            intent.putExtra(android.provider.ContactsContract.Intents.Insert.PHONE, phone)
        }
        if let email = options.defaultEmailAddress, !email.isEmpty {
            intent.putExtra(android.provider.ContactsContract.Intents.Insert.EMAIL, email)
        }
        if let note = options.defaultNote, !note.isEmpty {
            intent.putExtra(android.provider.ContactsContract.Intents.Insert.NOTES, note)
        }
    }

    if let activity = context as? android.app.Activity {
        activity.startActivity(intent)
    } else {
        intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }
}

#endif

// MARK: - iOS UIKit Representables

#if !SKIP && os(iOS)
#if canImport(ContactsUI)

struct ContactPickerRepresentable: UIViewControllerRepresentable {
    let multipleSelection: Bool
    let onSelectContact: (String) -> Void
    let onSelectContacts: ([String]) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    @MainActor class Coordinator: NSObject, CNContactPickerDelegate {
        let parent: ContactPickerRepresentable

        init(_ parent: ContactPickerRepresentable) {
            self.parent = parent
        }

        nonisolated func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            MainActor.assumeIsolated {
                parent.onCancel()
            }
        }

        nonisolated func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            let id = contact.identifier
            MainActor.assumeIsolated {
                parent.onSelectContact(id)
            }
        }

        nonisolated func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
            let ids = contacts.map { $0.identifier }
            MainActor.assumeIsolated {
                parent.onSelectContacts(ids)
            }
        }
    }
}

struct ContactViewRepresentable: UIViewControllerRepresentable {
    let contactID: String
    let onDismiss: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        let store = CNContactStore()
        let keys: [CNKeyDescriptor] = [
            CNContactViewController.descriptorForRequiredKeys()
        ]
        do {
            let contact = try store.unifiedContact(withIdentifier: contactID, keysToFetch: keys)
            let vc = CNContactViewController(for: contact)
            vc.delegate = context.coordinator
            let nav = UINavigationController(rootViewController: vc)
            nav.navigationBar.topItem?.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: context.coordinator, action: #selector(Coordinator.done))
            return nav
        } catch {
            uiLogger.error("Failed to load contact for viewer: \(error)")
            let nav = UINavigationController()
            return nav
        }
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    @MainActor class Coordinator: NSObject, CNContactViewControllerDelegate {
        let parent: ContactViewRepresentable

        init(_ parent: ContactViewRepresentable) {
            self.parent = parent
        }

        nonisolated func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
            MainActor.assumeIsolated {
                parent.onDismiss()
            }
        }

        @objc func done() {
            parent.onDismiss()
        }
    }
}

struct ContactEditRepresentable: UIViewControllerRepresentable {
    let options: ContactEditorOptions
    let onComplete: (ContactEditorResult) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        let store = CNContactStore()

        if let existingContact = options.contact, let contactID = existingContact.id {
            // Edit existing contact
            let keys: [CNKeyDescriptor] = [
                CNContactViewController.descriptorForRequiredKeys()
            ]
            do {
                let contact = try store.unifiedContact(withIdentifier: contactID, keysToFetch: keys)
                let vc = CNContactViewController(for: contact)
                vc.delegate = context.coordinator
                vc.allowsEditing = true
                let nav = UINavigationController(rootViewController: vc)
                return nav
            } catch {
                uiLogger.error("Failed to load contact for editing: \(error)")
                let nav = UINavigationController()
                return nav
            }
        } else {
            // Create new contact
            let mutable = CNMutableContact()
            if let given = options.defaultGivenName { mutable.givenName = given }
            if let family = options.defaultFamilyName { mutable.familyName = family }
            if let org = options.defaultOrganizationName { mutable.organizationName = org }
            if let phone = options.defaultPhoneNumber {
                mutable.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: phone))]
            }
            if let email = options.defaultEmailAddress {
                mutable.emailAddresses = [CNLabeledValue(label: CNLabelHome, value: email as NSString)]
            }
            if let note = options.defaultNote { mutable.note = note }

            let vc = CNContactViewController(forNewContact: mutable)
            vc.delegate = context.coordinator
            vc.contactStore = store
            let nav = UINavigationController(rootViewController: vc)
            return nav
        }
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    @MainActor class Coordinator: NSObject, CNContactViewControllerDelegate {
        let parent: ContactEditRepresentable

        init(_ parent: ContactEditRepresentable) {
            self.parent = parent
        }

        nonisolated func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
            let didSave = contact != nil
            MainActor.assumeIsolated {
                parent.onComplete(didSave ? .saved : .canceled)
            }
        }
    }
}

#endif
#endif

#endif
