//
//  TVOPreflight.h
//  TwilioVoice
//
//  Copyright © 2024 Twilio, Inc. All rights reserved.
//

@class TVOPreflightReport;
@class TVOPreflightStatsSample;

/**
 * Enumeration indicating the state of the preflight test.
 */
typedef NS_ENUM(NSUInteger, TVOPreflightTestStatus) {
    TVOPreflightTestStatusConnecting = 0,
    TVOPreflightTestStatusConnected,
    TVOPreflightTestStatusCompleted,
    TVOPreflightTestStatusFailed
}
NS_SWIFT_NAME(PreflightTest.Status);

NS_SWIFT_NAME(PreflightTest)
@interface TVOPreflightTest : NSObject

/**
 * @name Properties
 */

/**
 * @brief The current state of the preflight test.
 */
@property (nonatomic, assign, readonly) TVOPreflightTestStatus status;

/**
 * @brief The call SID for the preflight test call.
 */
@property (nonatomic, strong, readonly, nonnull) NSString *callSid;

/**
 * @brief Preflight test start time. Unix timestamp in milliseconds.
 */
@property (nonatomic, assign, readonly) CFTimeInterval startTime;

/**
 * @brief Preflight test end time. Unix timestamp in milliseconds.
 */
@property (nonatomic, assign, readonly) CFTimeInterval endTime;

/** 
 * @brief The preflight test report.
 *
 * @discussion If accessed when the preflight status is anything other than `TVOPreflightTestStatusCompleted`,
 * an empty report object will be returned.
 */
@property (nonatomic, strong, readonly, nullable) TVOPreflightReport *preflightReport;

/**
 * @brief Returns the latest stats sample for the preflight test.
 */
@property (nonatomic, strong, readonly, nullable) TVOPreflightStatsSample *latestSample;

/**
 * @name Preflight Test Actions
 */

/**
 * @brief Stops the ongoing preflight test.
 * This will result in preflight test to be in `TVOPreflightTestStatusFailed` state.
 */
- (void)stop;

@end
