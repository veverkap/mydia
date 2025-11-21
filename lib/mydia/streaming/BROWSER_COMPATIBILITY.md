# Browser Codec & Container Compatibility Matrix (2025)

This document provides a comprehensive overview of actual browser support for video/audio codecs and container formats as of 2025, based on research conducted for intelligent streaming decisions.

## Summary

Our current `Mydia.Streaming.Compatibility` module is **already well-aligned** with 2025 browser support. The key findings:

- **MKV container**: Not suitable for direct streaming (only Firefox Nightly has support as of Oct 2025)
- **Current codec support**: H.264, VP9, AV1 for video; AAC, MP3, Opus, Vorbis for audio
- **Optimization opportunities**: Safari HEVC support, client-side capability detection

## Container Format Support

| Container | Chrome  | Firefox         | Safari  | Edge    | Status            | Notes                                       |
| --------- | ------- | --------------- | ------- | ------- | ----------------- | ------------------------------------------- |
| **MP4**   | ✅ Full | ✅ Full         | ✅ Full | ✅ Full | **Universal**     | Industry standard, best compatibility       |
| **WebM**  | ✅ Full | ✅ Full         | ✅ Full | ✅ Full | **Universal**     | Based on Matroska, royalty-free codecs only |
| **MKV**   | ❌ No   | ⚠️ Nightly only | ❌ No   | ❌ No   | **Not Supported** | Firefox Nightly 145+ only (Oct 2025)        |
| **M4V**   | ✅ Full | ✅ Full         | ✅ Full | ✅ Full | **Universal**     | Apple variant of MP4                        |

### MKV Investigation Conclusion

**MKV is NOT suitable for direct streaming in production (2025):**

- Only Firefox Nightly 145+ has support (not stable release)
- Chrome, Safari, Edge have no support
- Must continue remuxing MKV → MP4 for browser compatibility

Even when MKV contains browser-compatible codecs (H.264 + AAC), browsers refuse to play the container format.

## Video Codec Support

| Codec            | Chrome  | Firefox | Safari          | Edge    | Containers | Notes                                                        |
| ---------------- | ------- | ------- | --------------- | ------- | ---------- | ------------------------------------------------------------ |
| **H.264 (AVC)**  | ✅ Full | ✅ Full | ✅ Full         | ✅ Full | MP4, WebM  | Universal baseline codec                                     |
| **H.265 (HEVC)** | ❌ No   | ❌ No   | ✅ Full\*       | ❌ No   | MP4        | Safari only (Safari 11+, macOS High Sierra+, iOS 11+)        |
| **VP9**          | ✅ Full | ✅ Full | ⚠️ Inconsistent | ✅ Full | WebM       | Safari 14+ support, possibly removed in Safari 18            |
| **AV1**          | ✅ Full | ✅ Full | ⚠️ Limited      | ✅ Full | MP4, WebM  | Safari: hardware-dependent (M3+ Macs, iPhone 15+, macOS 16+) |
| **VP8**          | ✅ Full | ✅ Full | ✅ Full         | ✅ Full | WebM       | Older codec, superseded by VP9                               |

\*HEVC in Safari is hardware-dependent. Safari intelligently chooses H.264 over HEVC when both are available to optimize battery life.

### Video Codec Versions

- **Chrome VP9**: Since version 29 (2013)
- **Chrome AV1**: Since version 70
- **Safari HEVC**: Since Safari 11 (macOS High Sierra, iOS 11)
- **Safari VP9**: Added Safari 14, potentially removed Safari 18
- **Safari AV1**: macOS 16+, iOS 16+, hardware-dependent

## Audio Codec Support

| Codec         | Chrome  | Firefox | Safari     | Edge    | Compatibility | Notes                                            |
| ------------- | ------- | ------- | ---------- | ------- | ------------- | ------------------------------------------------ |
| **AAC**       | ✅ Full | ✅ Full | ✅ Full    | ✅ Full | 100%          | Universal standard                               |
| **MP3**       | ✅ Full | ✅ Full | ✅ Full    | ✅ Full | 100%          | Universal standard                               |
| **Opus**      | ✅ Full | ✅ Full | ⚠️ Partial | ✅ Full | 92%           | Chrome v33+, Firefox v15+, Safari v11+ (partial) |
| **Vorbis**    | ✅ Full | ✅ Full | ✅ Full    | ✅ Full | High          | Commonly used in WebM                            |
| **AC3/E-AC3** | ❌ No   | ❌ No   | ❌ No      | ❌ No   | 0%            | No browser support                               |
| **DTS**       | ❌ No   | ❌ No   | ❌ No      | ❌ No   | 0%            | No browser support                               |

### Audio Codec Notes

- **Opus**: Best for WebM containers, excellent quality/compression
- **AAC**: Best for MP4 containers, universal compatibility
- **AC3/DTS**: Require transcoding to AAC or Opus for browser playback

## Current Implementation Analysis

### What We Support Today (`lib/mydia/streaming/compatibility.ex`)

**Containers:** ✅

- MP4, WebM, M4V

**Video Codecs:** ✅

- H.264, VP9, AV1

**Audio Codecs:** ✅

- AAC, MP3, Opus, Vorbis

**Container Exclusions:** ✅

- MKV correctly marked as incompatible

### Alignment with 2025 Reality

Our current compatibility module is **already accurate** for 2025 browser support:

✅ **Correct exclusions:**

- MKV not supported (correct decision)
- HEVC not included (Safari-only, not universal)

✅ **Correct inclusions:**

- H.264, VP9, AV1 all have broad support
- AAC, MP3, Opus, Vorbis all widely supported
- MP4 and WebM containers universal

## Optimization Opportunities

### 1. Safari HEVC Support (Optional Enhancement)

**Opportunity:**

- Safari users with HEVC files could direct play instead of transcode
- Requires browser detection

**Implementation:**

```elixir
defp browser_compatible?(container, video_codec, audio_codec, browser_info) do
  # Existing checks...

  # Special case: Safari supports HEVC
  if safari_browser?(browser_info) and video_codec == "hevc" do
    compatible_container?(container) and compatible_audio_codec?(audio_codec)
  else
    # Normal compatibility checks
  end
end
```

**Trade-offs:**

- Adds complexity (browser detection required)
- Limited benefit (HEVC files less common, only helps Safari users)
- Safari may choose H.264 over HEVC anyway for battery optimization

### 2. Client-Side Capability Detection

**Opportunity:**

- Detect actual browser capabilities at runtime
- More future-proof than hardcoded lists
- Support new codecs automatically as browsers add them

**Implementation:**

```javascript
// In video player hook or app.js
function detectBrowserCapabilities() {
  const video = document.createElement("video");

  return {
    h264: video.canPlayType('video/mp4; codecs="avc1.42E01E"'),
    hevc: video.canPlayType('video/mp4; codecs="hev1.1.6.L93.B0"'),
    vp9: video.canPlayType('video/webm; codecs="vp9"'),
    av1: video.canPlayType('video/mp4; codecs="av01.0.05M.08"'),
    aac: video.canPlayType('audio/mp4; codecs="mp4a.40.2"'),
    opus: video.canPlayType('audio/webm; codecs="opus"'),
    mkv: video.canPlayType('video/x-matroska; codecs="avc1.42E01E, mp4a.40.2"'),
  };
}

// Send to server on session init
```

**Trade-offs:**

- Adds JavaScript complexity
- Requires session/cookie storage
- More flexible and future-proof
- Could enable per-user optimizations

### 3. Intelligent Streaming Tiers

Based on detected capabilities, route to optimal streaming mode:

**Tier 1: Direct Play (fastest)**

- Browser supports file's container + codecs natively
- Serve via HTTP Range requests (current implementation)
- No processing needed

**Tier 2: Stream Copy Remux (fast)**

- Browser supports codecs but not container (e.g., MKV→MP4)
- FFmpeg stream copy remux (current optimization in task-129)
- 10-100x faster than transcoding

**Tier 3: Partial Transcode (moderate)**

- Copy compatible stream, transcode incompatible one
- E.g., copy H.264 video, transcode DTS→AAC audio
- Future enhancement

**Tier 4: Full Transcode (slow)**

- Transcode both video and audio streams
- Current HLS transcoding fallback
- Slowest but most compatible

## Recommendations

### Short Term (Current State)

**Keep current implementation** - it's already well-aligned with 2025 browser reality:

- ✅ Correct codec support (H.264, VP9, AV1 / AAC, MP3, Opus, Vorbis)
- ✅ Correct container support (MP4, WebM)
- ✅ MKV correctly excluded

### Medium Term Enhancements

1. **Optimize stream copy remux** (task-129) - High impact, already in progress
2. **Add client capability detection** - Future-proof, enables per-user optimization
3. **Consider Safari HEVC** - Low priority, limited benefit

### Long Term Vision

1. **Runtime capability detection** - Auto-adapt to new browser features
2. **Intelligent codec selection** - Choose best codec for each user's browser
3. **Partial transcode support** - Copy compatible streams, transcode only what's needed

## Testing Verification

To verify browser support claims, use the following test in browser console:

```javascript
const video = document.createElement("video");

console.log({
  "H.264 in MP4": video.canPlayType('video/mp4; codecs="avc1.42E01E"'),
  "HEVC in MP4": video.canPlayType('video/mp4; codecs="hev1.1.6.L93.B0"'),
  "VP9 in WebM": video.canPlayType('video/webm; codecs="vp9"'),
  "AV1 in MP4": video.canPlayType('video/mp4; codecs="av01.0.05M.08"'),
  "AAC in MP4": video.canPlayType('audio/mp4; codecs="mp4a.40.2"'),
  "Opus in WebM": video.canPlayType('audio/webm; codecs="opus"'),
  "MKV H.264+AAC": video.canPlayType(
    'video/x-matroska; codecs="avc1.42E01E, mp4a.40.2"',
  ),
});

// Returns: '' (no), 'maybe', or 'probably' (yes)
```

## References

- [MDN: Media formats for HTML audio/video](https://developer.mozilla.org/en-US/docs/Web/Media/Formats)
- [Can I Use: Video format support](https://caniuse.com/?search=video)
- [Can I Use: Opus audio format](https://caniuse.com/opus)
- [Media Source Extensions API](https://developer.mozilla.org/en-US/docs/Web/API/Media_Source_Extensions_API)
- Firefox MKV support announcement (Oct 2025, Nightly 145+)
- Safari HEVC support documentation (Safari 11+, macOS High Sierra+)

## Conclusion

**Our current compatibility module is already accurate for 2025.** The main finding is that **MKV direct streaming is not viable** - we must continue remuxing to MP4.

The best optimization opportunity is **stream copy remux** (task-129), which is already being implemented. This provides 10-100x speedup over transcoding while maintaining universal browser compatibility.

Client-side capability detection would be a nice future enhancement for per-user optimization, but is not critical given our current accurate hardcoded compatibility matrix.
