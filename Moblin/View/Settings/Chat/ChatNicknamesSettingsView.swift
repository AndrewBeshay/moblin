import SwiftUI

private struct NicknameView: View {
    let model: Model
    @ObservedObject var nickname: SettingsChatNickname

    var body: some View {
        NavigationLink {
            Form {
                Section {
                    TextEditNavigationView(title: "User",
                                           value: nickname.user,
                                           onChange: { _ in nil },
                                           onSubmit: { value in
                                               nickname.user = value
                                               model.reloadChatMessages()
                                           })
                    TextEditNavigationView(title: "Nickname", value: nickname.nickname, onChange: { _ in
                        nil
                    }, onSubmit: { value in
                        nickname.nickname = value
                        model.reloadChatMessages()
                    })
                }
                Section {
                    Button {
                        model.previewTextToSpeech(username: nickname.nickname, message: "This is a test message")
                    } label: {
                        HCenter {
                            Text("Test")
                        }
                    }
                    .disabled(nickname.nickname.isEmpty)
                }
            }
            .navigationTitle("Nickname")
        } label: {
            HStack {
                DraggableItemPrefixView()
                Text(nickname.user)
                Spacer()
                Text(nickname.nickname)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct ChatNicknamesSettingsView: View {
    let model: Model
    @ObservedObject var nicknames: SettingsChatNicknames

    var body: some View {
        NavigationLink {
            Form {
                Section {
                    List {
                        ForEach(nicknames.nicknames) { nickname in
                            NicknameView(model: model, nickname: nickname)
                        }
                        .onMove { froms, to in
                            nicknames.nicknames.move(fromOffsets: froms, toOffset: to)
                        }
                        .onDelete { offsets in
                            nicknames.nicknames.remove(atOffsets: offsets)
                            model.reloadChatMessages()
                        }
                    }
                    CreateButtonView {
                        nicknames.nicknames.append(SettingsChatNickname())
                    }
                } footer: {
                    SwipeLeftToDeleteHelpView(kind: String(localized: "a nickname"))
                }
            }
            .navigationTitle("Nicknames")
        } label: {
            HStack {
                Text("Nicknames")
                Spacer()
                Text(String(nicknames.nicknames.count))
                    .foregroundColor(.gray)
            }
        }
    }
}
