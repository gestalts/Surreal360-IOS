//
//  TVOPreflightDelegate.h
//  TwilioVoice
//
//  Copyright © 2024 Twilio, Inc. All rights reserved.
//

@class TVOPreflightTest;
@class TVOPreflightReport;
@class TVOPreflightStatsSample;

/**
 *  `TVOPreflightDelegate` provides callbacks when important changes to a `TVOPreflightTest` occur.
 */
NS_SWIFT_NAME(PreflightDelegate)
@protocol TVOPreflightDelegate <NSObject>

/**
 * @brief Notifies the delegate that the preflight test is completed successfully.
 *
 * @param preflightTest The `<TVOPreflightTest>`.
 * @param report The `<TVOPreflightReport>`.
 *
 * @discussion The state of the `<TVOPreflightTest>` will be `TVOPreflightTestStatusCompleted` at this point.
 */
- (void)preflight:(nonnull TVOPreflightTest *)preflightTest didCompleteWithReport:(nonnull TVOPreflightReport *)report
NS_SWIFT_NAME(preflightDidComplete(preflightTest:report:));

/**
 * @brief Notifies the delegate that the preflight test has failed.
 *
 * @param preflightTest The `<TVOPreflightTest>` that failed.
 * @param error The `<NSError>` that occurred.
 *
 * @discussion The state of the `<TVOPreflightTest>` will be `TVOPreflightTestStatusFailed` at this point.
 */
- (void)preflight:(nonnull TVOPreflightTest *)preflightTest didFailWithError:(nonnull NSError *)error
NS_SWIFT_NAME(preflightDidFail(preflightTest:error:));

/**
 * @brief Notifies the delegate that the preflight test call has successfully connected to Twilio.
 *
 * @param preflightTest The `<TVOPreflightTest>`.
 *
 * @discussion The state of the `<TVOPreflightTest>` will be `TVOPreflightTestStatusConnected` at this point.
 */
- (void)preflightDidConnect:(nonnull TVOPreflightTest *)preflightTest
NS_SWIFT_NAME(preflightDidConnect(preflightTest:));

@optional

/**
 * @brief Notifies the delegate that network quality warnings have changed for the preflight test.
 *
 * @param preflightTest The `<TVOPreflightTest>` that received quality warning updates.
 * @param currentWarnings An `<NSSet>` that contains the warnings at the instant of receiving this callback. Values in the `<NSSet`> are `<NSNumber>` with values of `<TVOCallQualityWarning>`.
 * @param previousWarnings An `<NSSet>` that contains the warnings before receiving this callback. Values in the `<NSSet`> are `<NSNumber>` with values of `<TVOCallQualityWarning>`.
 *
 * @discussion The two sets will help the delegate find out what warnings have changed since the last callback was received.
 *
 * @see TVOCall for more detail about `<TVOCallQualityWarning>`.
 */
- (void)preflight:(nonnull TVOPreflightTest *)preflightTest
didReceiveQualityWarnings:(nonnull NSSet<NSNumber *> *)currentWarnings
previousWarnings:(nonnull NSSet<NSNumber *> *)previousWarnings
NS_SWIFT_NAME(preflightDidReceiveQualityWarnings(preflightTest:currentWarnings:previousWarnings:));

/**
 * @brief Notifies the delegate that a new stats sample has been received.
 *
 * @param preflightTest The `<TVOPreflightTest>` that received the stats sample.
 * @param statsSample The `<TVOPreflightStatsSample>`.
 *
 * @discussion This callback will be raised every second once the preflight test has connected.
 */
- (void)preflight:(nonnull TVOPreflightTest *)preflightTest didReceiveStatsSample:(nonnull TVOPreflightStatsSample *)statsSample
NS_SWIFT_NAME(preflightDidReceiveStatsSample(preflightTest:statsSample:));

@end
