//
//  TVOAudioOptions.h
//  TwilioVoice
//
//  Copyright © 2016-2017 Twilio, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  `TVOAudioOptionsBuilder` constructs `TVOAudioOptions`.
 */
NS_SWIFT_NAME(AudioOptionsBuilder)
@interface TVOAudioOptionsBuilder : NSObject

/**
 *  @brief Audio processing to filter out background noise. Defaults to `NO`. WebRTC relies on built-in iOS noise cancellation.
 */
@property (nonatomic, assign) BOOL noiseSuppression;

/**
 *  @brief Audio receiver jitter buffer minimum target delay in milliseconds.. Defaults to `0`.
 */
@property (nonatomic, assign) int audioJitterBufferMinDelayMs;

/**
 *  @brief Audio receiver jitter buffer max capacity in number of packets. Minimum allowed value is `20`. Default value is `50`.
 */
@property (nonatomic, assign) int audioJitterBufferMaxPackets;

/**
 *  @brief Audio processing to remove background noise of lower frequencies. Defaults to `YES`.
 */
@property (nonatomic, assign) BOOL highpassFilter;

/**
 *  @brief You should not initialize `TVOAudioOptionsBuilder` directly, use a TVOAudioOptionsBuilderBlock instead.
 */
- (null_unspecified instancetype)init __attribute__((unavailable("Use a TVOAudioOptionsBuilderBlock instead.")));

@end

/**
 *  `TVOAudioOptionsBuilderBlock` allows you to construct `TVOAudioOptions` using the builder pattern.
 *
 *  @param builder The builder
 */
typedef void (^TVOAudioOptionsBuilderBlock)(TVOAudioOptionsBuilder * _Nonnull builder)
NS_SWIFT_NAME(AudioOptionsBuilder.Block);

/**
 *  `TVOAudioOptions` specifies options for `TVOLocalAudioTrack`.
 */
NS_SWIFT_NAME(AudioOptions)
@interface TVOAudioOptions : NSObject
/**
 *  @brief Audio processing to filter out background noise. Defaults to `NO`. WebRTC relies on built-in iOS noise cancellation.
 */
@property (nonatomic, assign, readonly) BOOL noiseSuppression;

/**
 *  @brief Audio receiver jitter buffer minimum target delay in milliseconds. Defaults to `0`.
 */
@property (nonatomic, assign, readonly) int audioJitterBufferMinDelayMs;

/**
 *  @brief Audio receiver jitter buffer max capacity in number of packets. Defaults to `50`.
 */
@property (nonatomic, assign, readonly) int audioJitterBufferMaxPackets;

/**
 *  @brief Audio processing to remove background noise of lower frequencies. Defaults to `YES`.
 */
@property (nonatomic, assign, readonly) BOOL highpassFilter;

/**
 *  @brief Constructs `TVOAudioOptions` using the builder pattern.
 *
 *  @param block You can pass audio options to the builder using this block. The builder will construct a
 *  `TVOAudioOptions` object using the options provided.
 *
 *  @return An instance of `TVOAudioOptions`.
 */
+ (null_unspecified instancetype)optionsWithBlock:(nonnull TVOAudioOptionsBuilderBlock)block;

@end
