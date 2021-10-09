//
//


private var AssociateHasRasterImageKey: String = "AssociateHasRasterImageKey"

public extension ZMAssetOriginal {
    var hasRasterImage: Bool {
        get {
            if let hasRasterImage = objc_getAssociatedObject(self, &AssociateHasRasterImageKey) as? Bool {
                return hasRasterImage
            } else {
                let hasRasterImage = hasImage() && UTType(mimeType: mimeType)?.isSVG == false
                objc_setAssociatedObject(self, &AssociateHasRasterImageKey, hasRasterImage, .OBJC_ASSOCIATION_RETAIN)
                return hasRasterImage
            }
        }
    }
}

fileprivate extension ZMImageAsset {
    var isRaster: Bool {
        return UTType(mimeType: mimeType)?.isSVG == false
    }
}

public extension ZMGenericMessage {
    var hasRasterImage: Bool {
        return hasImage() && image.isRaster
    }
}

public extension ZMEphemeral {
    var hasRasterImage: Bool {
        return hasImage() && image.isRaster
    }
}

