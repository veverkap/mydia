# HLS Transcoding Backends

Mydia supports two HLS transcoding backends: **FFmpeg** (default) and **Membrane Framework** (experimental).

## FFmpeg Backend (Recommended)

The FFmpeg backend uses FFmpeg directly to transcode video files to HLS format.

### Benefits

- **Universal codec support**: Works with any format FFmpeg supports
  - Video: H.264, HEVC/H.265, VP9, VP8, AV1, etc.
  - Audio: AAC, E-AC3, DTS, TrueHD, AC3, Opus, etc.
  - Containers: MKV, MP4, AVI, WebM, etc.
- **Production-ready**: Battle-tested and used by industry leaders
- **Simple implementation**: Single command vs complex pipeline management
- **Clear error messages**: FFmpeg provides detailed, actionable error output
- **Progress tracking**: Can parse FFmpeg output for real-time progress

### Limitations

- **External dependency**: Requires FFmpeg binary installed on the system
- **Process overhead**: Spawning external process vs in-process pipeline
- **Less granular control**: Can't customize individual pipeline elements

### When to Use

Use FFmpeg as your default backend. It provides the best compatibility and reliability for production use.

## Membrane Framework Backend (Experimental)

The Membrane Framework backend uses Elixir/BEAM-native transcoding with Membrane.

### Benefits

- **Elixir-native**: Runs in the BEAM VM using OTP principles
- **Granular control**: Can customize each element of the pipeline
- **No external dependencies**: Uses NIFs but no external binaries

### Limitations

- **Limited codec support**: Only supports:
  - Video: H.264, HEVC, VP8, VP9
  - Audio: AAC, Opus
  - **Does NOT support**: E-AC3, DTS, TrueHD, AC3, many others
- **Immature ecosystem**: Matroska plugin has bugs with real-world files
- **Parser issues**: Can crash on date parsing and metadata issues
- **Complex implementation**: Requires managing dynamic pad linking and pipeline state

### Known Issues

The Membrane Matroska plugin (`membrane_matroska_plugin`) has several production issues:

1. **Codec rejections**: Rejects common audio codecs like E-AC3, DTS, AC3
2. **Parser crashes**: Fails on date parsing in MKV metadata
3. **Limited testing**: Not thoroughly tested with diverse real-world media files

### When to Use

Only use Membrane if you:

- Need BEAM-native transcoding for specific architectural reasons
- Are willing to accept limited codec support
- Want to contribute to improving the Membrane ecosystem

## Configuration

Configure the backend in `config/config.exs`:

```elixir
# Use FFmpeg (default)
config :mydia, :streaming,
  hls_backend: :ffmpeg

# Or use Membrane (experimental)
config :mydia, :streaming,
  hls_backend: :membrane
```

## Implementation Details

### FFmpeg Backend

The FFmpeg backend (`Mydia.Streaming.FfmpegHlsTranscoder`) spawns an FFmpeg process using Elixir's Port system:

```elixir
ffmpeg -i input.mkv \
  -c:v libx264 -preset medium -crf 23 -profile:v high \
  -s 1280x720 -g 60 -bf 0 \
  -c:a aac -b:a 128k -ar 48000 -ac 2 \
  -f hls -hls_time 6 -hls_playlist_type event \
  -hls_segment_filename "segment_%03d.ts" \
  playlist.m3u8
```

The module monitors the FFmpeg process and parses its output for:

- Duration detection
- Progress tracking
- Error reporting

### Membrane Backend

The Membrane backend (`Mydia.Streaming.HlsPipeline`) builds a complex pipeline:

```
File.Source
  → Demuxer (MP4 or Matroska)
    → Video: Decoder → SWScale → H264 Encoder → Parser
    → Audio: Parser → Decoder → SWResample → AAC Encoder
      → HLS SinkBin
```

The pipeline uses dynamic pad linking to handle different track types discovered at runtime.

## Recommendation

**Use FFmpeg as your default backend** for production deployments. It provides:

- Better codec compatibility
- More reliable transcoding
- Clearer error messages
- Proven production stability

Consider Membrane only for development/testing or if you have specific requirements that justify its limitations.

## Future Improvements

### FFmpeg Backend

- [ ] Add adaptive bitrate streaming (multiple quality levels)
- [ ] Implement subtitle support
- [ ] Add more video quality presets (low, medium, high, ultra)
- [ ] Support for HDR content

### Membrane Backend

- [ ] Work with Membrane team to fix Matroska plugin issues
- [ ] Add support for more audio codecs (E-AC3, DTS, etc.)
- [ ] Improve error handling and recovery
- [ ] Better dynamic pad linking for complex files

## Related Files

- `lib/mydia/streaming/ffmpeg_hls_transcoder.ex` - FFmpeg backend implementation
- `lib/mydia/streaming/hls_pipeline.ex` - Membrane backend implementation
- `lib/mydia/streaming/hls_session.ex` - Session manager (supports both backends)
- `test/mydia/streaming/ffmpeg_hls_transcoder_test.exs` - FFmpeg tests
- `config/config.exs` - Backend configuration
