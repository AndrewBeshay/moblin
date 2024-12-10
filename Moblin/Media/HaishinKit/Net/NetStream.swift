import AVFoundation
import UIKit

protocol NetStreamDelegate: AnyObject {
    func stream(
        _ stream: NetStream,
        audioLevel: Float,
        numberOfAudioChannels: Int,
        presentationTimestamp: Double
    )
    func streamVideo(_ stream: NetStream, presentationTimestamp: Double)
    func streamVideo(_ stream: NetStream, failedEffect: String?)
    func streamVideo(_ stream: NetStream, lowFpsImage: Data?, frameNumber: UInt64)
    func streamVideo(_ stream: NetStream, findVideoFormatError: String, activeFormat: String)
    func streamRecorderFinished()
    func streamRecorderError()
    func streamAudio(_ stream: NetStream, sampleBuffer: CMSampleBuffer)
    func streamNoTorch()
}

let netStreamLockQueue = DispatchQueue(label: "com.haishinkit.HaishinKit.NetStream.lock")

open class NetStream: NSObject {
    let mixer = Mixer()
    weak var delegate: (any NetStreamDelegate)?

    override init() {
        super.init()
        mixer.delegate = self
    }

    func setTorch(value: Bool) {
        netStreamLockQueue.async {
            self.mixer.video.torch = value
        }
    }

    func setFrameRate(value: Float64) {
        netStreamLockQueue.async {
            self.mixer.video.frameRate = value
        }
    }

    func setColorSpace(colorSpace: AVCaptureColorSpace, onComplete: @escaping () -> Void) {
        netStreamLockQueue.async {
            self.mixer.video.colorSpace = colorSpace
            onComplete()
        }
    }

    func setVideoSize(capture: CGSize, output: CGSize) {
        netStreamLockQueue.async {
            self.mixer.video.captureSize = capture
            self.mixer.video.outputSize = output
        }
    }

    func setVideoOrientation(value: AVCaptureVideoOrientation) {
        netStreamLockQueue.async {
            self.mixer.video.videoOrientation = value
        }
    }

    func setHasAudio(value: Bool) {
        netStreamLockQueue.async {
            self.mixer.audio.muted = !value
        }
    }

    func setAudioEncoderSettings(settings: AudioCodecOutputSettings) {
        netStreamLockQueue.async {
            self.mixer.audio.encoder.settings = settings
        }
    }

    func setVideoEncoderSettings(settings: VideoCodecSettings) {
        netStreamLockQueue.async {
            self.mixer.video.encoder.settings.mutate { $0 = settings }
        }
    }

    func attachCamera(
        _ device: AVCaptureDevice?,
        onError: ((_ error: Error) -> Void)? = nil,
        onSuccess: (() -> Void)? = nil,
        replaceVideoCameraId: UUID? = nil
    ) {
        netStreamLockQueue.async {
            do {
                try self.mixer.attachCamera(device, replaceVideoCameraId)
                onSuccess?()
            } catch {
                onError?(error)
            }
        }
    }

    func attachAudio(
        _ device: AVCaptureDevice?,
        onError: ((_ error: Error) -> Void)? = nil,
        replaceAudioId: UUID? = nil
    ) {
        netStreamLockQueue.async {
            do {
                try self.mixer.attachAudio(device, replaceAudioId)
            } catch {
                onError?(error)
            }
        }
    }

    func addReplaceVideo(cameraId: UUID, name: String, latency: Double) {
        mixer.video.addReplaceVideo(cameraId: cameraId, name: name, latency: latency)
    }

    func removeReplaceVideo(cameraId: UUID) {
        mixer.video.removeReplaceVideo(cameraId: cameraId)
    }

    func addReplaceVideoSampleBuffer(cameraId: UUID, _ sampleBuffer: CMSampleBuffer) {
        mixer.video.addReplaceVideoSampleBuffer(cameraId: cameraId, sampleBuffer)
    }

    func setReplaceVideoTargetLatency(cameraId: UUID, _ latency: Double) {
        mixer.video.setReplaceVideoTargetLatency(cameraId: cameraId, latency: latency)
    }

    func addReplaceAudio(cameraId: UUID, name: String, latency: Double) {
        mixer.audio.addReplaceAudio(cameraId: cameraId, name: name, latency: latency)
    }

    func removeReplaceAudio(cameraId: UUID) {
        mixer.audio.removeReplaceAudio(cameraId: cameraId)
    }

    func addReplaceAudioSampleBuffer(cameraId: UUID, _ sampleBuffer: CMSampleBuffer) {
        mixer.audio.addReplaceAudioSampleBuffer(cameraId: cameraId, sampleBuffer)
    }

    func setReplaceAudioTargetLatency(cameraId: UUID, _ latency: Double) {
        mixer.audio.setReplaceAudioTargetLatency(cameraId: cameraId, latency: latency)
    }

    func videoCapture() -> VideoUnit? {
        return mixer.video
    }

    func registerVideoEffect(_ effect: VideoEffect) {
        mixer.video.registerEffect(effect)
    }

    func unregisterVideoEffect(_ effect: VideoEffect) {
        mixer.video.unregisterEffect(effect)
    }

    func setPendingAfterAttachEffects(effects: [VideoEffect]) {
        mixer.video.setPendingAfterAttachEffects(effects: effects)
    }

    func usePendingAfterAttachEffects() {
        mixer.video.usePendingAfterAttachEffects()
    }

    func setLowFpsImage(fps: Float) {
        mixer.video.setLowFpsImage(fps: fps)
    }

    func takeSnapshot(age: Float, onComplete: @escaping (UIImage) -> Void) {
        mixer.video.takeSnapshot(age: age, onComplete: onComplete)
    }

    func setAudioChannelsMap(map: [Int: Int]) {
        mixer.recorder.setAudioChannelsMap(map: map)
    }

    func setSpeechToText(enabled: Bool) {
        mixer.audio.setSpeechToText(enabled: enabled)
    }

    func startRecording(
        url: URL,
        audioSettings: [String: Any],
        videoSettings: [String: Any]
    ) {
        mixer.recorder.url = url
        mixer.recorder.audioOutputSettings = audioSettings
        mixer.recorder.videoOutputSettings = videoSettings
        mixer.recorder.startRunning()
    }

    func stopRecording() {
        mixer.recorder.stopRunning()
    }

    func stopMixer() {
        netStreamLockQueue.async {
            self.mixer.stopRunning()
        }
    }
}

extension NetStream: MixerDelegate {
    func mixer(audioLevel: Float, numberOfAudioChannels: Int, presentationTimestamp: Double) {
        delegate?.stream(
            self,
            audioLevel: audioLevel,
            numberOfAudioChannels: numberOfAudioChannels,
            presentationTimestamp: presentationTimestamp
        )
    }

    func mixerVideo(presentationTimestamp: Double) {
        delegate?.streamVideo(self, presentationTimestamp: presentationTimestamp)
    }

    func mixerVideo(failedEffect: String?) {
        delegate?.streamVideo(self, failedEffect: failedEffect)
    }

    func mixerVideo(lowFpsImage: Data?, frameNumber: UInt64) {
        delegate?.streamVideo(self, lowFpsImage: lowFpsImage, frameNumber: frameNumber)
    }

    func mixer(findVideoFormatError: String, activeFormat: String) {
        delegate?.streamVideo(self, findVideoFormatError: findVideoFormatError, activeFormat: activeFormat)
    }

    func mixerRecorderFinished() {
        delegate?.streamRecorderFinished()
    }

    func mixerRecorderError() {
        delegate?.streamRecorderError()
    }

    func mixer(audioSampleBuffer: CMSampleBuffer) {
        delegate?.streamAudio(self, sampleBuffer: audioSampleBuffer)
    }

    func mixerNoTorch() {
        delegate?.streamNoTorch()
    }
}