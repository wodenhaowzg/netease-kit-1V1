//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEChatKit
import NIMSDK

@objc
public protocol PinMessageViewModelDelegate: NSObjectProtocol {
  func didNeedRefreshUI()
}

@objcMembers
public class PinMessageViewModel: NSObject, ChatExtendProviderDelegate, NIMChatManagerDelegate, NIMConversationManagerDelegate {
  public let chatRepo = ChatRepo()
  public var items = [PinMessageModel]()
  public var delegate: PinMessageViewModelDelegate?
  public var session: NIMSession?

  override public init() {
    super.init()
    chatRepo.addChatDelegate(delegate: self)
    chatRepo.addChatExtendDelegate(delegate: self)
    NIMSDK.shared().conversationManager.add(self)
  }

  public func onRecvMessagesDeleted(_ messages: [NIMMessage], exts: [String: String]?) {
    for message in messages {
      if message.session?.sessionId == session?.sessionId {
        delegate?.didNeedRefreshUI()
        break
      }
    }
  }

  public func getPinitems(session: NIMSession, _ completion: @escaping (Error?) -> Void) {
    weak var weakSelf = self
    self.session = session
    chatRepo.fetchPinMessage(session.sessionId, session.sessionType) { error, pinItems in
      if let pins = pinItems {
        if error == nil {
          weakSelf?.items.removeAll()
        }
        var remoteMessages = [NIMMessagePinItem]()
        var pinDic = [String: NIMMessagePinItem]()
        pins.forEach { item in
          if let message = ConversationProvider.shared.messagesInSession(item.session, messageIds: [item.messageId])?.first {
            let pinModel = PinMessageModel(message: message, item: item)
            weakSelf?.items.append(pinModel)
            weakSelf?.items.sort { model1, model2 in
              model1.message.timestamp > model2.message.timestamp
            }
          } else {
            remoteMessages.append(item)
            pinDic[item.messageServerID] = item
          }
        }
        if remoteMessages.count <= 0 {
          completion(error)
        } else {
          var infos = [NIMChatExtendBasicInfo]()
          remoteMessages.forEach { item in
            let info = NIMChatExtendBasicInfo()
            info.type = session.sessionType
            info.fromAccount = item.messageFromAccount
            info.toAccount = item.messageToAccount
            info.messageID = item.messageId
            info.serverID = item.messageServerID
            info.timestamp = item.messageTime
            infos.append(info)
          }
          weakSelf?.chatRepo.fetchHistoryMessages(infos, false) { err, mapTable in
            let enums = mapTable?.objectEnumerator()
            while let message = enums?.nextObject() as? NIMMessage {
              print("fetchHistoryMessages ", message.messageId)
              if let item = pinDic[message.serverID] {
                let pinModel = PinMessageModel(message: message, item: item)
                weakSelf?.items.append(pinModel)
                weakSelf?.items.sort { model1, model2 in
                  model1.message.timestamp > model2.message.timestamp
                }
              }
            }
            completion(err)
          }
        }

      } else {
        completion(error)
      }
    }
  }

  public func removePinMessage(_ message: NIMMessage,
                               _ completion: @escaping (Error?, NIMMessagePinItem?)
                                 -> Void) {
    NELog.infoLog("PinMessageViewModel", desc: #function + ", messageId: " + message.messageId)
    let item = NIMMessagePinItem(message: message)
    chatRepo.removeMessagePin(item) { error, pinItem in
      completion(error, pinItem)
    }
  }

  public func forwardUserMessage(_ message: NIMMessage, _ users: [NIMUser]) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId: " + message.messageId)
    users.forEach { user in
      if let uid = user.userId {
        let session = NIMSession(uid, type: .P2P)
        if let forwardMessage = chatRepo.makeForwardMessage(message) {
          clearForwardAtMark(forwardMessage)
          chatRepo.sendForwardMessage(forwardMessage, session)
        }
      }
    }
  }

  public func forwardTeamMessage(_ message: NIMMessage, _ team: NIMTeam) {
    NELog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId: " + message.messageId)
    if let tid = team.teamId {
      let session = NIMSession(tid, type: .team)
      if let forwardMessage = chatRepo.makeForwardMessage(message) {
        clearForwardAtMark(forwardMessage)
        chatRepo.sendForwardMessage(forwardMessage, session)
      }
    }
  }

  // MARK: NIMChatManagerDelegate

  public func onRecvRevokeMessageNotification(_ notification: NIMRevokeMessageNotification) {
//    items = [PinMessageModel]()
    delegate?.didNeedRefreshUI()
  }

  // MARK: ChatExtendProviderDelegate

  public func onNotifyAddMessagePin(pinItem: NIMMessagePinItem) {
//    items = [PinMessageModel]()
    delegate?.didNeedRefreshUI()
  }

  public func onNotifyRemoveMessagePin(pinItem: NIMMessagePinItem) {
//    items = [PinMessageModel]()
    delegate?.didNeedRefreshUI()
  }

  private func clearForwardAtMark(_ forwardMessage: NIMMessage) {
    forwardMessage.remoteExt?.removeValue(forKey: yxAtMsg)
    forwardMessage.remoteExt?.removeValue(forKey: keyReplyMsgKey)
    if forwardMessage.remoteExt?.count ?? 0 <= 0 {
      forwardMessage.remoteExt = nil
    }
  }
}
