# Swift SDK Demo

Demonstrations based on [LeanCloud Swift SDK](https://github.com/leancloud/swift-sdk) .

| Demo Project Name | description |
| ------ | ------ |
| [Chat](#Chat) | Instant Messaging App |
| [VoIP](#VoIP) | Sample for receiving APNs message and VoIP notification |

## Chat

Chat is a [LeanCloud](https://leancloud.cn) based instant messaging application on iOS.

### Features

* Basic Chatting
* Group Chatting
* Rich Media Messaging
* Open Chat Room
* Channels and Bots
* Temporary Conversation

### How to Run

* `$ git checkout master`
* [CocoaPods](https://cocoapods.org) adding Package Dependencies
	* `$ cd swift-sdk-demo/`
	* `$ pod update`
* `$ open swift-sdk-demo.xcworkspace/`
* [Xcode](https://developer.apple.com/xcode/) run **Chat** target

> **Note**: Before running the target, maybe you should change the **Bundle identifier** and setup your own **Apple Developer Account**.

## VoIP

VoIP is is a [LeanCloud](https://leancloud.cn) based Sample Project for receiving message and VoIP notification on iOS.

### How to Run

* `$ git checkout master`
* [CocoaPods](https://cocoapods.org) adding Package Dependencies
	* `$ cd swift-sdk-demo/`
	* `$ pod update`
* `$ open swift-sdk-demo.xcworkspace/`
* [Xcode](https://developer.apple.com/xcode/) run **VoIP** target

> **Note**: Before running the target, maybe you should change the **Bundle identifier** and setup your own **Apple Developer Account**.
