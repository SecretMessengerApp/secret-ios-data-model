//
//


import Foundation
import WireUtilities

public extension String {
    
    static func randomChar() -> UnicodeScalar {
        let string = "abcdefghijklmnopqrstuvxyz"
        let chars = Array(string.unicodeScalars)
        let random = UInt.secureRandomNumber(upperBound: UInt(chars.count))
        // in this case we know random will fit inside int
        return chars[Int(random)]
    }
    
    func obfuscated() -> String {
        var obfuscatedVersion = UnicodeScalarView()
        for char in self.unicodeScalars {
            if NSCharacterSet.whitespacesAndNewlines.contains(char) {
                obfuscatedVersion.append(char)
            } else {
                obfuscatedVersion.append(String.randomChar())
            }
        }
        return String(obfuscatedVersion)
    }
}


public extension ZMGenericMessage {

    @objc func obfuscatedMessage() -> ZMGenericMessage? {
        guard let messageID = (messageId as String?).flatMap(UUID.init) else { return nil }
        guard hasEphemeral() else { return nil }
        
        if let someText = textData {
            if let content = someText.content {
                let obfuscatedContent = content.obfuscated()
                var obfuscatedLinkPreviews : [ZMLinkPreview] = []
                if linkPreviews.count > 0 {
                    let offset = linkPreviews.first!.urlOffset
                    let offsetIndex = obfuscatedContent.index(obfuscatedContent.startIndex, offsetBy: Int(offset), limitedBy: obfuscatedContent.endIndex) ?? obfuscatedContent.startIndex
                    let originalURL = obfuscatedContent[offsetIndex...]
                    obfuscatedLinkPreviews = linkPreviews.map{$0.obfuscated(originalURL: String(originalURL))}
                }
                let obfuscatedText = ZMText.text(with: obfuscatedContent, mentions: [], linkPreviews: obfuscatedLinkPreviews)
                return ZMGenericMessage.message(content: obfuscatedText, nonce: messageID)
            }
        }
        if let someAsset = assetData {
            let obfuscatedAsset = someAsset.obfuscated()
            return ZMGenericMessage.message(content: obfuscatedAsset, nonce: messageID)
        }
        if locationData != nil {
            let obfuscatedLocation = ZMLocation.location(withLatitude: 0.0, longitude: 0.0)
             return ZMGenericMessage.message(content: obfuscatedLocation, nonce: messageID)
        }
        if let imageAsset = imageAssetData {
            let obfuscatedImage = imageAsset.obfuscated()
            return ZMGenericMessage.message(content: obfuscatedImage, nonce: messageID)
        }
        return nil
    }
}

extension ZMLinkPreview {

    func obfuscated(originalURL: String) -> ZMLinkPreview {
        let obfTitle = hasTitle() ? title?.obfuscated() : nil
        let obfSummary = hasSummary() ? summary?.obfuscated() : nil
        let obfImage = hasImage() ? image?.obfuscated() : nil
        let obfTweet = hasTweet() ? tweet?.obfuscated() : nil
        return ZMLinkPreview.linkPreview(withOriginalURL: originalURL, permanentURL: permanentUrl.obfuscated(), offset: urlOffset, title: obfTitle, summary: obfSummary, imageAsset: obfImage, tweet: obfTweet)
    }
}

extension ZMTweet {
    func obfuscated() -> ZMTweet {
        let obfAuthorName = hasAuthor() ? author?.obfuscated() : nil
        let obfUserName = hasUsername() ? username?.obfuscated() : nil
        return ZMTweet.tweet(withAuthor: obfAuthorName, username: obfUserName)
    }
}


extension ZMAsset {

    func obfuscated() -> ZMAsset {
        var originalBuilder : ZMAssetOriginalBuilder? = nil
        var previewBuilder : ZMAssetPreviewBuilder? = nil
        if hasOriginal(), let original = original {
            originalBuilder = ZMAssetOriginal.builder()
            if original.hasRasterImage, let image = original.image {
                let imageBuilder = ZMAssetImageMetaData.builder()!
                imageBuilder.setTag(image.tag)
                imageBuilder.setWidth(image.width)
                imageBuilder.setHeight(image.height)
                originalBuilder!.setImage(imageBuilder.build())
            }
            if original.hasName(), let name = original.name {
                let obfName = name.obfuscated()
                originalBuilder!.setName(obfName)
            }
            if original.hasAudio() {
                let audioBuilder = ZMAssetAudioMetaData.builder()!
                originalBuilder!.setAudio(audioBuilder.build())
            }
            if original.hasVideo() {
                let videoBuilder = ZMAssetVideoMetaData.builder()!
                originalBuilder!.setVideo(videoBuilder.build())
            }
            originalBuilder!.setSize(10)
            originalBuilder!.setMimeType(original.mimeType)
        }
        if hasPreview(), let preview = preview {
            previewBuilder = ZMAssetPreview.builder()
            if preview.hasImage(), let previewImage = preview.image {
                let imageBuilder = ZMAssetImageMetaData.builder()!
                imageBuilder.setTag(previewImage.tag)
                imageBuilder.setWidth(previewImage.width)
                imageBuilder.setHeight(previewImage.height)
                previewBuilder!.setImage(imageBuilder.build())
            }
            previewBuilder!.setSize(10)
            previewBuilder!.setMimeType(preview.mimeType)
        }
        return ZMAsset.asset(withOriginal: originalBuilder?.build(), preview: previewBuilder?.build())
    }
}

extension ZMImageAsset {

    func obfuscated() -> ZMImageAsset {
        let imageAssetBuilder = ZMImageAsset.builder()!
        imageAssetBuilder.setTag(tag)
        imageAssetBuilder.setWidth(width)
        imageAssetBuilder.setHeight(height)
        imageAssetBuilder.setOriginalWidth(originalWidth)
        imageAssetBuilder.setOriginalHeight(originalHeight)
        imageAssetBuilder.setMimeType(mimeType)
        imageAssetBuilder.setSize(1)
        return imageAssetBuilder.build()
    }
}


