//
//  Copyright © 2017년 INKA ENTWORKS INC. All rights reserved.
//
//  PallyCon Team (http://www.pallycon.com)
//
//  FPSContent struct for FPS contents.
//

import AVFoundation
#if os(iOS)
import PallyConFPSSDK
#else
import PallyConFPSSDKTV
#endif


struct FPSContent {
    var contentId: String
    
    var optionalId: String
    
    var token: String
    
    var liveKeyRotation: Bool
    
    var contentName: String
    
    var urlAsset: AVURLAsset
    
    var chromcastPlayUrlPath: String
    
    var downloadDelegate: Any?
    
    init(_ contentId: String,
         _ token: String,
         _ contentName: String,
         _ urlAsset: AVURLAsset
         ) {
        self.init(contentId, "", token, false, contentName, urlAsset, "", nil)
    }
    
    
    init(_ contentId: String,
         _ token: String,
         _ optionalId: String,
         _ contentName: String,
         _ urlAsset: AVURLAsset
         ) {
        self.init(contentId, optionalId, token, false, contentName, urlAsset, "", nil)
    }
    
    init(_ contentId: String,
         _ optionalId: String,
         _ token: String,
         _ liveKeyRotation: Bool,
         _ contentName: String,
         _ urlAsset: AVURLAsset,
         _ chromcastPlayUrlPath: String,
         _ downloadDelegate: Any?) {
        self.contentId = contentId
        self.optionalId = optionalId
        self.token = token
        self.liveKeyRotation = liveKeyRotation
        self.contentName = contentName
        self.urlAsset = urlAsset
        self.chromcastPlayUrlPath = chromcastPlayUrlPath
        self.downloadDelegate = downloadDelegate
    }
}

/// Extends `FPSContent` to conform to the `Equatable` protocol.
extension FPSContent: Equatable {}

func ==(lhs: FPSContent, rhs: FPSContent) -> Bool {
    return (lhs.contentId == rhs.contentId) && (lhs.urlAsset == rhs.urlAsset)
}

extension FPSContent {
    enum DownloadState: String {
        case notDownloaded
        
        case downloading
        
        case downloaded
        
        case pause
    }
}

extension FPSContent {
    struct Keys {
        
        static let cId = "FPSCidKey"
        
        static let optionalId = "FPSOptionalId"
        
        static let token = "FPSToken"
        
        static let liveKeyRotation = "FPSLiveKeyRotation"
        
        static let avUrlAsset = "FPSAVURLAsset"
        
        static let downloadState = "FPSDownloadStateKey"
        
        static let percentDownloaded = "FPSPercentDownloadedKey"
        
        static let acquireLicenseFail = "FPSAcquireLicenseFail"
        
        static let chromcastPlayUrlPath = "ChromcastPlayUrlPath"
        
        static let mainm3u8Scheme = "mainm3u8Scheme"
    }
}
