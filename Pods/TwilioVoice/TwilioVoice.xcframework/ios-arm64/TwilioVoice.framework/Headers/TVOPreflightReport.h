//
//  TVOPreflightReport.h
//  TwilioVoice
//
//  Copyright © 2024 Twilio, Inc. All rights reserved.
//

/**
 * Enumeration indicating the quality based on the preflight test report.
 * Call quality is based on mean opinion score (mos) that is computed by the SDK.
 */
typedef NS_ENUM(NSUInteger, TVOPreflightCallQuality) {
    TVOPreflightCallQualityExcellent = 0, ///< The average mos is above 4.2
    TVOPreflightCallQualityGreat,         ///< The average mos is >= 4.1 and <= 4.2
    TVOPreflightCallQualityGood,          ///< The average mos is >= 3.7 and < 4.1
    TVOPreflightCallQualityFair,          ///< The average mos is >= 3.1 and < 3.7
    TVOPreflightCallQualityDegraded       ///< average mos is below 3.1
}
NS_SWIFT_NAME(PreflightReport.CallQuality);


/**
 * `TVOPreflightTimeMeasurement` is used to keep track of signaling connection time,
 * peer connection time, ice connection time and preflight test time.
 */
NS_SWIFT_NAME(PreflightTimeMeasurement)
@interface TVOPreflightTimeMeasurement: NSObject

/**
 * @brief Preflight test start time. Unix timestamp in milliseconds.
 */
@property (nonatomic, assign, readonly) CFTimeInterval startTime;

/**
 * @brief Preflight test end time. Unix timestamp in milliseconds.
 */
@property (nonatomic, assign, readonly) CFTimeInterval endTime;

/**
 * @brief Duration of the preflight test. Unix timestamp in milliseconds.
 */
@property (nonatomic, assign, readonly) CFTimeInterval duration;

/**
 *  @brief Developers shouldn't initialize this class directly.
 */
- (null_unspecified instancetype)init __attribute__((unavailable("Developers shouldn't initialize this class directly.")));

@end

/**
 * `TVOPreflightNetworkTiming` is used to keep track of start time, end time, and duration
 * of signaling connection time, peer connection time, ice connection time and preflight test time.
 */
NS_SWIFT_NAME(PreflightNetworkTiming)
@interface TVOPreflightNetworkTiming: NSObject

/**
 * @brief Time measurement for the signaling connection.
 */
@property (nonatomic, strong, readonly, nonnull) TVOPreflightTimeMeasurement *signalingTimeMeasurement;

/**
 * @brief Time measurement for the ICE connection.
 */
@property (nonatomic, strong, readonly, nonnull) TVOPreflightTimeMeasurement *iceConnectionTimeMeasurement;

/**
 * @brief Time measurement for the peer connection.
 */
@property (nonatomic, strong, readonly, nonnull) TVOPreflightTimeMeasurement *peerConnectTimeMeasurement;

/**
 * @brief Time measurement for the preflight test.
 */
@property (nonatomic, strong, readonly, nonnull) TVOPreflightTimeMeasurement *preflightTestTimeMeasurement;

@end


/**
 * `TVOPreflightStatsSample`  stores a subset of relevant stats data from WebRTC
 * provided stats.
 */
NS_SWIFT_NAME(PreflightStatsSample)
@interface TVOPreflightStatsSample: NSObject

/**
 * @brief Codec used to encode the audio track.
 */
@property (nonatomic, strong, readonly, nonnull) NSString *codec;

/**
 * @brief Input audio level from the microphone.
 */
@property (nonatomic, assign, readonly) NSUInteger audioInputLevel;

/**
 * @brief Output audio level of the remote audio track.
 */
@property (nonatomic, assign, readonly) NSUInteger audioOutputLevel;

/**
 * @brief Total bytes received.
 */
@property (nonatomic, assign, readonly) unsigned long long bytesReceived;

/**
 * @brief Total bytes sent.
 */
@property (nonatomic, assign, readonly) unsigned long long bytesSent;

/**
 * @brief Total audio packets received.
 */
@property (nonatomic, assign, readonly) unsigned long long packetsReceived;

/**
 * @brief Total audio packets sent.
 */
@property (nonatomic, assign, readonly) unsigned long long packetsSent;

/**
 * @brief Total audio packets lost.
 */
@property (nonatomic, assign, readonly) unsigned long long packetsLost;

/**
 * @brief Total audio packets lost fraction.
 */
@property (nonatomic, assign, readonly) double packetsLostFraction;

/**
 * @brief Current jitter value.
 */
@property (nonatomic, assign, readonly) NSUInteger jitter;

/**
 * @brief Current MOS value.
 */
@property (nonatomic, assign, readonly) double mos;

/**
 * @brief Current round trip time value.
 */
@property (nonatomic, assign, readonly) NSUInteger rtt;

/**
 * @brief Timestamp when the stats was collected.
 */
@property (nonatomic, strong, readonly, nonnull) NSString *timestamp;

/**
 *  @brief Developers shouldn't initialize this class directly.
 */
- (null_unspecified instancetype)init __attribute__((unavailable("Developers shouldn't initialize this class directly.")));

@end


/**
 * `TVOPreflightAggregateStats` stores the minimum, maximum, and average
 * value of stats parameters.
 */
NS_SWIFT_NAME(PreflightAggregateStats)
@interface TVOPreflightAggregateStats : NSObject

/**
 * @brief Average value of the parameter during the test.
 */
@property (nonatomic, assign, readonly) double average;

/**
 * @brief Minimum value of the parameter during the test.
 */
@property (nonatomic, assign, readonly) double min;

/**
 * @brief Maximum value of the parameter during the test.
 */
@property (nonatomic, assign, readonly) double max;

/**
 *  @brief Developers shouldn't initialize this class directly.
 */
- (null_unspecified instancetype)init __attribute__((unavailable("Developers shouldn't initialize this class directly.")));

@end

/**
 * `TVOPreflightNetworkStats`  stores the minimum, maximum, and average
 *  value of jitter, mos, and rtt as `TVOPreflightAggregateStats` objects.
 */
NS_SWIFT_NAME(PreflightNetworkStats)
@interface TVOPreflightNetworkStats : NSObject

/**
 * @brief Aggregated values for jitter during the test.
 */
@property (nonatomic, strong, readonly, nonnull) TVOPreflightAggregateStats *jitter;

/**
 * @brief Aggregated values for mos during the test.
 */
@property (nonatomic, strong, readonly, nonnull) TVOPreflightAggregateStats *mos;

/**
 * @brief Aggregated values for rtt during the test.
 */
@property (nonatomic, strong, readonly, nonnull) TVOPreflightAggregateStats *rtt;

/**
 *  @brief Developers shouldn't initialize this class directly.
 */
- (null_unspecified instancetype)init __attribute__((unavailable("Developers shouldn't initialize this class directly.")));

@end


/**
 * `TVOPreflightWarning` stores the call quality warning or audio level warning
 * parameters received during the test.
 */
NS_SWIFT_NAME(PreflightWarning)
@interface TVOPreflightWarning : NSObject

/**
 * @brief Name of the warning received.
 */
@property (nonatomic, strong, readonly, nonnull) NSString *name;

/**
 * @brief Threshold value at which the warning was triggered.
 */
@property (nonatomic, strong, readonly, nonnull) NSString *threshold;

/**
 * @brief Set of values of the underlying parameter that triggered the warning.
 */
@property (nonatomic, strong, readonly, nonnull) NSString *values;

/**
 * @brief Time when the warning was triggered. Unix timestamp in milliseconds.
 */
@property (nonatomic, assign, readonly) CFTimeInterval timestamp;

/**
 *  @brief Developers shouldn't initialize this class directly.
 */
- (null_unspecified instancetype)init __attribute__((unavailable("Developers shouldn't initialize this class directly.")));

@end


/**
 * `TVOPreflightWarningCleared` stores the name of the call quality warning or audio
 * level warning that was raised during the test and subsequently cleared.
 */
NS_SWIFT_NAME(PreflightWarningCleared)
@interface TVOPreflightWarningCleared : NSObject

/**
 * @brief Name of the warning that was cleared.
 */
@property (nonatomic, strong, readonly, nonnull) NSString *name;

/**
 * @brief Time when the warning was cleared. Unix timestamp in milliseconds.
 */
@property (nonatomic, assign, readonly) CFTimeInterval timestamp;

/**
 *  @brief Developers shouldn't initialize this class directly.
 */
- (null_unspecified instancetype)init __attribute__((unavailable("Developers shouldn't initialize this class directly.")));

@end


/**
 * `TVOPreflightIceCandidate` stores the ICE candidates gathered during ice negotiation.
 */
NS_SWIFT_NAME(PreflightIceCandidate)
@interface TVOPreflightIceCandidate : NSObject

/**
 * @brief Transport ID of the ice candidate.
 */
@property (nonatomic, strong, readonly, nonnull) NSString *transportId;

/**
 * @brief Boolean showing if this is a remote candidate.
 */
@property (nonatomic, assign, readonly) BOOL isRemote;

/**
 * @brief IP address of the ice candidate.
 */
@property (nonatomic, strong, readonly, nonnull) NSString *ip;

/**
 * @brief Port of the ice candidate.
 */
@property (nonatomic, assign, readonly) NSUInteger port;

/**
 * @brief Protocol used by the ICE candidate.
 */
@property (nonatomic, strong, readonly, nonnull) NSString *protocol;

/**
 * @brief ICE candidate type like local, host, etc.
 */
@property (nonatomic, strong, readonly, nonnull) NSString *candidateType;

/**
 * @brief Priority of the ICE candidate.
 */
@property (nonatomic, assign, readonly) NSUInteger priority;

/**
 * @brief URL of the ice candidate.
 */
@property (nonatomic, strong, readonly, nonnull) NSString *url;

/**
 * @brief Boolean showing if the ICE candidate is deleted.
 */
@property (nonatomic, assign, readonly) BOOL deleted;

/**
 * @brief Network cost of the ICE candidate.
 */
@property (nonatomic, assign, readonly) NSUInteger networkCost;

/**
 * @brief Network ID of the ICE candidate.
 */
@property (nonatomic, assign, readonly) NSUInteger networkId;

/**
 * @brief Network type used by the ICE candidate like WiFi, LTE, etc.
 */
@property (nonatomic, strong, readonly, nonnull) NSString *networkType;

/**
 * @brief Related address of the ICE candidate, if any.
 */
@property (nonatomic, strong, readonly, nonnull) NSString *relatedAddress;

/**
 * @brief Related port of the ICE candidate, if any.
 */
@property (nonatomic, assign, readonly) NSUInteger relatedPort;

/**
 * @brief TCP type of the ICE candidate.
 */
@property (nonatomic, strong, readonly, nonnull) NSString *tcpType;

/**
 *  @brief Developers shouldn't initialize this class directly.
 */
- (null_unspecified instancetype)init __attribute__((unavailable("Developers shouldn't initialize this class directly.")));

@end


/**
 * `TVOPreflightSelectedIceCandidatePair` stores the selected local and remote ICE
 * candidates used during the test. The values are stored as `TVOPreflightIceCandidate` objects.
 */
NS_SWIFT_NAME(PreflightSelectedIceCandidatePair)
@interface TVOPreflightSelectedIceCandidatePair : NSObject

/**
 * @brief The selected local ICE candidate.
 */
@property (nonatomic, strong, readonly, nonnull) TVOPreflightIceCandidate *localCandidate;

/**
 * @brief The selected remote ICE candidate.
 */
@property (nonatomic, strong, readonly, nonnull) TVOPreflightIceCandidate *remoteCandidate;

/**
 *  @brief Developers shouldn't initialize this class directly.
 */
- (null_unspecified instancetype)init __attribute__((unavailable("Developers shouldn't initialize this class directly.")));

@end


/**
 * `TVOPreflightReport` contains the detailed report of the preflight test. This object is returned in the
 * `[TVOPreflightDelegate preflight:didCompleteWithReport:]` callback when the preflight test
 * is successfully completed.
 */
NS_SWIFT_NAME(PreflightReport)
@interface TVOPreflightReport : NSObject

/**
 * @brief The call SID for the preflight test call.
 */
@property (nonatomic, strong, readonly, nonnull) NSString *callSid;

/**
 * @brief The edge used during the preflight test.
 */
@property (nonatomic, strong, readonly, nonnull) NSString *edge;

/**
 * @brief The edge set by the application.
 */
@property (nonatomic, strong, readonly, nonnull) NSString *selectedEdge;

/**
 * @brief An array of gathered ICE candidates during the preflight test.
 */
@property (nonatomic, strong, readonly, nonnull) NSArray<TVOPreflightIceCandidate *> *iceCandidates;

/**
 * @brief Network timings for the signaling connection, ice connection, peer connection and preflight tes
 */
@property (nonatomic, strong, readonly, nonnull) TVOPreflightNetworkTiming *networkTimings;

/**
 * @brief An array of stats samples obtained from webRTC periodically during the preflight test.
 */
@property (nonatomic, strong, readonly, nonnull) NSArray<TVOPreflightStatsSample *> *samples;

/**
 * @brief Network stats such as jitter, mos, and rtt.
 */
@property (nonatomic, strong, readonly, nonnull) TVOPreflightNetworkStats *networkStats;

/**
 * @brief Returns `true` in `NSNumber` if TURN server was used during the preflight test, otherwise`false`.
 * Returns `nil` if no ICE candidates were selected.
 */
@property (nonatomic, strong, readonly, nullable) NSNumber *isTurnRequired;

/**
 * @brief The `TVOPreflightCallQuality` value in `NSNumber` based on the average mos
 * obtained during the preflight test. `Nil` indicates that call quality metric is not available for
 * the preflight test.
 */
@property (nonatomic, strong, readonly, nullable) NSNumber *callQuality;

/**
 * @brief An array of call quality or audio level warnings received during the preflight test.
 */
@property (nonatomic, strong, readonly, nonnull) NSArray<TVOPreflightWarning *> *warnings;

/**
 * @brief An array of call quality or audio level warnings cleared during the preflight test.
 */
@property (nonatomic, strong, readonly, nonnull) NSArray<TVOPreflightWarningCleared *> *warningsCleared;

/**
 * @brief The selected local and remote ice candidate used by the preflight test.
 */
@property (nonatomic, strong, readonly, nonnull) TVOPreflightSelectedIceCandidatePair *selectedIceCandidatePair;

/**
 * @brief Returns a dictionary representation of the detailed report of the preflight test.
 */
- (nonnull NSDictionary *)dictionaryReport;

/**
 *  @brief Developers shouldn't initialize this class directly.
 */
- (null_unspecified instancetype)init __attribute__((unavailable("Developers shouldn't initialize this class directly.")));

@end
