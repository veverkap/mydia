# FileParser Architecture Analysis & Recommendations

## Executive Summary

The current `FileParser` implementation uses a **list-based pattern matching** approach that requires exhaustive enumeration of quality markers. This leads to brittle code that breaks when encountering new codec variants (e.g., DDP5.1) and requires constant maintenance.

**Recommendation**: Adopt a **regex-based sequential extraction** approach similar to PTN (Parse Torrent Name) and GuessIt, which are battle-tested parsers used in production by major media management systems.

---

## Current Architecture Analysis

### How It Works

```elixir
# Current approach in FileParser
@audio_codecs ~w(DTS-HD DTS-X DTS TrueHD DDP5.1 DD5.1 DD+ Atmos AAC AC3 DD DDP)

1. Normalize filename (dots → spaces)
2. Extract quality info by matching against lists
3. Remove matched patterns from text
4. Clean remaining text as title
```

### Core Problems

#### 1. **Exhaustive List Maintenance**
```elixir
# Must add every variant manually
@audio_codecs ~w(... DDP5.1 DD5.1 DD+ ...)
# Miss DDP7.1? Broken. New codec? Broken.
```

#### 2. **Dot Normalization Issues**
```elixir
# "DDP5.1" becomes "DDP5 1" after normalization
# Now need separate handling for normalized versions
normalized_pattern = String.replace(pattern, ".", " ")
```

#### 3. **Order Dependencies**
- Patterns must be removed in correct order
- Release groups without hyphens don't get caught
- Edge cases multiply as more patterns are added

#### 4. **No Pattern Flexibility**
```elixir
# Can't handle variations like:
# - "DD5.1" vs "DD51" vs "DD5 1"
# - "x264" vs "x.264" vs "x 264"
# - "DDP5.1" vs "DDP51" vs "EAC3" (same codec, different names)
```

---

## Industry Standard Approach: PTN/GuessIt

### Algorithm Overview

```python
# PTN/GuessIt approach (pseudocode)
patterns = [
    {regex: /(?:DD|DDP|EAC3)(?P<channels>\d\.?\d)?/,
     type: :audio,
     handler: standardize_audio},
    {regex: /[hx]\.?26[45]/,
     type: :codec,
     handler: standardize_codec},
    # ... more patterns
]

for pattern in patterns:
    if match = pattern.regex.match(filename):
        extract_info(match, pattern.type, pattern.handler)
        filename = filename.replace(match, "")  # Remove matched part

title = clean(filename)  # What remains is the title
```

### Key Advantages

#### 1. **Flexible Regex Patterns**
```python
# Single pattern handles all variations
audio: /(?:DD|DDP|EAC3)(?P<channels>\d\.?\d)?/

Matches:
- DD5.1
- DD51
- DDP5.1
- DDP51
- DDP7.1
- EAC3
- DD+ (via standardization)
```

#### 2. **Sequential Extraction**
- Apply pattern → Extract info → Remove from string → Repeat
- What remains after all patterns is the title
- No order dependencies (patterns are self-contained)

#### 3. **Standardization Layer**
```python
def standardize_audio(raw_match):
    # Convert variants to canonical forms
    mapping = {
        'DDP5.1': 'Dolby Digital Plus 5.1',
        'DD51': 'Dolby Digital 5.1',
        'EAC3': 'Dolby Digital Plus',
        'DD+': 'Dolby Digital Plus'
    }
    return mapping.get(raw_match, raw_match)
```

#### 4. **Maintainability**
- New codec variant? Update regex, not lists
- Handles unknown patterns gracefully
- Tested on millions of real-world filenames

---

## Comparison: Current vs PTN Approach

| Aspect | Current (List-Based) | PTN (Regex-Based) |
|--------|---------------------|-------------------|
| **Audio Codecs** | `~w(DTS-HD DTS-X DTS TrueHD DDP5.1 DD5.1 ...)` | `(?:DTS(?:-HD|-X)?|DD(?:P)?(?:\d\.?\d)?|TrueHD|Atmos)` |
| **Handles Variations** | ❌ Must add each variant | ✅ Pattern handles all |
| **Dot Normalization** | ⚠️ Complex workarounds | ✅ Regex handles it |
| **Maintenance** | ❌ Add to list for each new case | ✅ Pattern often covers it |
| **Edge Cases** | ❌ Multiplies over time | ✅ Gracefully degrades |
| **Title Extraction** | Remove patterns, clean result | Remove patterns, what remains is title |

### Example: Audio Codec Handling

**Current Approach:**
```elixir
@audio_codecs ~w(DTS-HD DTS-X DTS TrueHD DDP5.1 DD5.1 DD+ Atmos AAC AC3 DD DDP)

# Must handle normalization separately
normalized_pattern = String.replace(pattern, ".", " ")
acc
|> String.replace(~r/\b#{Regex.escape(pattern)}\b/i, " ")
|> String.replace(~r/\b#{Regex.escape(normalized_pattern)}\b/i, " ")
```

**PTN Approach:**
```elixir
@audio_pattern ~r/
  \b
  (?:
    DTS(?:-HD\.MA|-HD|-X)?      # DTS variants
    |DD(?:P)?(?:\d+\.?\d*)?      # DD/DDP with optional channels
    |EAC3                         # E-AC3 (same as DDP)
    |TrueHD
    |Atmos
    |AAC(?:-LC)?(?:\d\.\d)?       # AAC variants
    |AC3
  )
  \b
/xi

def extract_audio(text) do
  case Regex.run(@audio_pattern, text) do
    [match | _] ->
      {standardize_audio(match), String.replace(text, match, " ")}
    nil ->
      {nil, text}
  end
end
```

---

## Real-World Example: Black Phone 2

**Filename:** `Black Phone 2. 2025 1080P WEB-DL DDP5.1 Atmos. X265. POOLTED.mkv`

### Current Behavior
```
1. Normalize: "Black Phone 2  2025 1080P WEB-DL DDP5 1 Atmos  X265  POOLTED"
2. Try to match "DDP5.1" → ❌ Doesn't exist in list
3. Match "DD5.1" → ❌ Filename has "DDP5 1"
4. Title extracted: "Black Phone 2 Ddp5 1 Poolted" ❌
```

### PTN Approach
```
1. Normalize: "Black Phone 2  2025 1080P WEB-DL DDP5.1 Atmos  X265  POOLTED"
2. Apply patterns sequentially:
   - Year pattern: Match "2025" → Remove → year=2025
   - Resolution: Match "1080P" → Remove → resolution=1080p
   - Source: Match "WEB-DL" → Remove → source="WEB-DL"
   - Audio: Match "DDP5.1" → Remove → audio="Dolby Digital Plus 5.1"
   - Audio: Match "Atmos" → Remove → audio_format="Atmos"
   - Codec: Match "X265" → Remove → codec="x265"
   - Release group: Match "POOLTED" (end word) → Remove → group="POOLTED"
3. Remaining: "Black Phone 2" ✅
```

---

## Recommended Implementation Strategy

### Phase 1: Add Flexible Patterns (Quick Win)

**Goal:** Fix immediate issues without full rewrite

```elixir
# lib/mydia/library/file_parser.ex

# Replace static lists with regex patterns
@audio_pattern ~r/
  \b
  (?:
    DTS(?:-HD\.MA|-HD|-X)?           # DTS, DTS-HD, DTS-X
    |DD(?:P)?(?:\d+\.?\d*)?           # DD5.1, DDP5.1, DD, DDP
    |EAC3                             # E-AC3
    |TrueHD(?:\d\.?\d*)?              # TrueHD 7.1, etc.
    |Atmos
    |AAC(?:-LC)?(?:\d\.?\d*)?         # AAC, AAC-LC, AAC 2.0
    |AC3
  )
  \b
/xi

@codec_pattern ~r/\b(?:[hx]\.?26[45]|HEVC|AVC|XviD|DivX|VP9|AV1|NVENC)\b/i
@resolution_pattern ~r/\b(?:\d{3,4}p|4K|8K|UHD)\b/i

# Use patterns instead of string matching
defp extract_audio(text) do
  case Regex.run(@audio_pattern, text, return: :index) do
    [{start, length} | _] ->
      match = String.slice(text, start, length)
      {match, String.replace(text, match, " ")}
    nil ->
      {nil, text}
  end
end
```

**Effort:** ~2-4 hours
**Impact:** Fixes most codec variation issues
**Risk:** Low (can coexist with current code)

### Phase 2: Sequential Extraction (Medium Term)

**Goal:** Adopt PTN-style sequential extraction

```elixir
defmodule Mydia.Library.FileParser.V2 do
  @patterns [
    %{name: :year, regex: ~r/[\(\[]?(19\d{2}|20\d{2})[\)\]]?/, handler: &parse_year/1},
    %{name: :resolution, regex: @resolution_pattern, handler: &parse_resolution/1},
    %{name: :source, regex: @source_pattern, handler: &parse_source/1},
    %{name: :codec, regex: @codec_pattern, handler: &parse_codec/1},
    %{name: :audio, regex: @audio_pattern, handler: &parse_audio/1},
    %{name: :hdr, regex: @hdr_pattern, handler: &parse_hdr/1},
    %{name: :release_group, regex: ~r/-([A-Z0-9]+)$/i, handler: &parse_group/1}
  ]

  def parse(filename) do
    normalized = normalize_filename(filename)

    {metadata, remaining_text} =
      Enum.reduce(@patterns, {%{}, normalized}, fn pattern, {meta, text} ->
        extract_pattern(pattern, meta, text)
      end)

    Map.put(metadata, :title, clean_title(remaining_text))
  end

  defp extract_pattern(pattern, metadata, text) do
    case Regex.run(pattern.regex, text, return: :index) do
      [{start, length} | captures] ->
        match = String.slice(text, start, length)
        value = pattern.handler.(match, captures, text)
        new_text = String.replace(text, match, " ", global: false)
        {Map.put(metadata, pattern.name, value), new_text}

      nil ->
        {metadata, text}
    end
  end
end
```

**Effort:** ~1-2 days
**Impact:** Robust, maintainable solution
**Risk:** Medium (requires thorough testing)

### Phase 3: Standardization & Quality Improvements (Long Term)

**Goal:** Match PTN/GuessIt quality

- Add standardization layer (DDP5.1 → "Dolby Digital Plus 5.1")
- Handle multi-episode ranges (S01E01-E03)
- Improve confidence scoring
- Add fuzzy matching for edge cases
- Build comprehensive test suite from real-world data

**Effort:** ~1 week
**Impact:** Production-grade parser
**Risk:** Low (builds on Phase 2)

---

## Recommendations Summary

### Immediate Action (This Task - Phase 1)
1. ✅ **Fixed:** Add DDP5.1 to audio codecs list (band-aid)
2. **Next:** Replace audio codec list with flexible regex pattern
3. **Document:** Current limitations (release groups, etc.)

### Short Term (Next Sprint)
1. Implement Phase 1 improvements (regex patterns)
2. Add more comprehensive test cases from real-world filenames
3. Benchmark against PTN for common cases

### Medium Term (Q1 2025)
1. Implement Phase 2 (sequential extraction)
2. Create migration path from V1 to V2 parser
3. A/B test with real library data

### Long Term (Q2 2025)
1. Achieve parity with PTN/GuessIt
2. Consider contributing improvements back to Elixir ecosystem
3. Build standardization layer for better TMDB matching

---

## Decision Framework

### When to Use List-Based Approach
- ✅ Stable, well-defined set of values (max 10-20 items)
- ✅ No variations expected
- ✅ Exact matching is sufficient

### When to Use Regex-Based Approach
- ✅ Multiple variations of same concept (DD/DDP/EAC3)
- ✅ Pattern has structure (e.g., "codec" + optional "version")
- ✅ New variants appear regularly
- ✅ Need to extract structured information (e.g., channel count from "5.1")

**Audio codecs, video codecs, and release patterns should all use regex.**

---

## Testing Strategy

### Test Cases to Add
```elixir
# Audio codec variations
"Movie.2024.1080p.DDP5.1.mkv"      # With dot
"Movie.2024.1080p.DDP51.mkv"       # Without dot
"Movie.2024.1080p.EAC3.mkv"        # Alternative name
"Movie.2024.1080p.DD+.mkv"         # Short form
"Movie.2024.1080p.TrueHD.7.1.mkv"  # With channels

# Codec variations
"Movie.2024.1080p.x264.mkv"
"Movie.2024.1080p.x.264.mkv"
"Movie.2024.1080p.H264.mkv"
"Movie.2024.1080p.h.264.mkv"

# Complex real-world examples
"The.Matrix.1999.1080p.BluRay.x264.DTS-HD.MA.5.1-GROUP.mkv"
"Dune.Part.Two.2024.2160p.WEB-DL.DDP5.1.Atmos.HDR.HEVC-GROUP.mkv"
"Show.Name.S01E05.1080p.AMZN.WEB-DL.DDP5.1.H.264-GROUP.mkv"
```

### Integration Testing
- Test against real library of 1000+ files
- Compare results with PTN/GuessIt
- Measure accuracy improvement
- Track false positives/negatives

---

## References

- [PTN (Parse Torrent Name)](https://github.com/divijbindlish/parse-torrent-name) - Python implementation
- [parse-torrent-title](https://github.com/platelminto/parse-torrent-title) - Alternative Python parser
- [GuessIt](https://github.com/guessit-io/guessit) - Industry standard parser
- [Scene Release Rules](https://scenerules.org/) - Naming conventions reference
- [MediaInfo](https://mediaarea.net/en/MediaInfo) - For validating codec information

---

## Conclusion

The current list-based approach served well initially but has reached its limits. The DDP5.1 bug is a symptom of a systemic issue: **we're playing whack-a-mole with codec variations**.

**Adopting a regex-based sequential extraction approach** will:
- ✅ Fix current and future codec variation issues
- ✅ Reduce maintenance burden
- ✅ Improve match accuracy
- ✅ Align with industry best practices
- ✅ Make the codebase more maintainable

The phased approach allows us to:
1. **Quick fix** the immediate issue (Phase 1)
2. **Incrementally improve** without breaking existing functionality
3. **Eventually achieve** production-grade parsing quality

**Recommended next steps:**
1. Complete current task with quick fix + documentation
2. Create backlog task for Phase 1 improvements
3. Schedule Phase 2 for next sprint
