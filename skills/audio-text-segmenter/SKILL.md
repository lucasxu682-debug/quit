---
name: audio-text-segmenter
description: Segment transcribed text into subtitle-friendly chunks with automatic speaker identification (A, B, C...). Detects different speakers based on pause patterns and timing. Use when: (1) Creating subtitles for multi-speaker videos, (2) Converting Whisper transcription into dialogue format with speaker labels, (3) Preparing interview or conversation transcripts for subtitling, (4) Automatically identifying speakers in audio without manual labeling.
---

# Audio Text Segmenter with Speaker Diarization

Segment long transcribed text into subtitle-friendly chunks with automatic speaker identification.

## Overview

This skill takes transcribed text (from Whisper or other sources) and intelligently segments it into subtitle-ready chunks with speaker labels (A, B, C...):
- **Automatic Speaker Detection**: Identifies different speakers based on pauses and timing
- **Smart Segmentation**: Detects natural pauses and sentence boundaries
- **Speaker Labels**: Automatically assigns A, B, C... to different speakers
- **Subtitle Formats**: Export to SRT, VTT, or TXT with speaker annotations

## Speaker Diarization Methods

### Method 1: Heuristic (Built-in) ⭐
Uses pause duration and timing patterns to detect speaker changes.
- **Pros**: No additional installation, fast, works offline
- **Cons**: Based on assumptions (long pauses = speaker change)
- **Best for**: Dialogues with clear turn-taking, interviews

### Method 2: AI-Powered (Advanced)
Use `pyannote.audio` or `whisperx` for accurate speaker recognition.
- **Pros**: High accuracy, real voice fingerprinting
- **Cons**: Requires additional installation, GPU recommended
- **Best for**: Production use, noisy audio, many speakers

**To install advanced diarization:**
```bash
pip install pyannote.audio
# or
pip install whisperx
```

## Quick Start

### Step 1: Transcribe with Word-Level Timestamps

```bash
# Export with word timestamps (required for speaker detection)
whisper audio.mp3 --output_format json --word_timestamps True
```

### Step 2: Segment with Speaker Detection

```bash
# Auto-detect speakers and generate subtitles
python scripts/segment_text.py audio.json --output subtitles.srt --format srt
```

**Output Example:**
```srt
1
00:00:01,000 --> 00:00:03,500
A: Hello how are you
 doing today

2
00:00:03,800 --> 00:00:06,200
B: I'm doing great
thanks for asking

3
00:00:06,500 --> 00:00:08,800
A: That's wonderful
to hear
```

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--max-chars` | 40 | Maximum characters per subtitle line |
| `--max-lines` | 2 | Maximum lines per subtitle entry |
| `--format` | srt | Output format: srt, vtt, or txt |
| `--pause-threshold` | 1.0 | Pause duration (seconds) to trigger speaker change |
| `--preserve-sentences` | true | Keep sentences together when possible |
| `--no-diarization` | false | Disable speaker detection |
| `--no-speaker-labels` | false | Hide speaker labels in output |

## How Speaker Detection Works

### Heuristic Method (Default)

The built-in speaker detection uses these signals:

1. **Long Pauses**: Pauses > `--pause-threshold` seconds (default 1.0s) often indicate speaker turns
2. **Timing Patterns**: Analyzes speech rhythm and gaps
3. **Segment Boundaries**: Respects natural sentence and clause boundaries

**Limitations:**
- Assumes clear turn-taking (not overlapping speech)
- May misidentify if one speaker has long pauses
- Works best with 2-3 speakers

### Improving Accuracy

1. **Adjust pause threshold**:
   ```bash
   # For fast dialogue
   python segment_text.py input.json -o output.srt --pause-threshold 0.5
   
   # For slow, deliberate speech
   python segment_text.py input.json -o output.srt --pause-threshold 1.5
   ```

2. **Manual correction**: Review and adjust speaker labels in output file

3. **Use AI diarization**: For critical applications, install `pyannote.audio`

## Segmentation Rules

1. **Primary split points** (highest priority):
   - Speaker changes (detected by pause analysis)
   - Sentence endings (., !, ?)
   - Long pauses (> pause-threshold)

2. **Secondary split points**:
   - Clause boundaries (, ; :)
   - Conjunctions (and, but, or, so)
   - Natural breathing pauses

3. **Constraints**:
   - Never exceed max-chars per line
   - Never exceed max-lines per entry
   - Keep same speaker's words together
   - Maintain chronological flow

## Output Formats

### SRT (SubRip)
```
1
00:00:01,000 --> 00:00:04,500
This is the first subtitle
spanning two lines

2
00:00:04,800 --> 00:00:07,200
Here's the second one
```

### VTT (WebVTT)
```webvtt
WEBVTT

00:00:01.000 --> 00:00:04.500
This is the first subtitle
spanning two lines

00:00:04.800 --> 00:00:07.200
Here's the second one
```

### Plain Text (for manual timing)
```
[00:00:01] This is the first subtitle
[00:00:04] Here's the second one
[00:00:07] And the third
```

## Usage Examples

### Basic Speaker Detection

```bash
# Transcribe with word timestamps
whisper interview.mp3 --output_format json --word_timestamps True

# Generate subtitles with speakers
python scripts/segment_text.py interview.json -o subtitles.srt
```

### Custom Settings

```bash
# Longer lines for YouTube
python scripts/segment_text.py input.json -o output.srt --max-chars 42

# More sensitive speaker detection
python scripts/segment_text.py input.json -o output.srt --pause-threshold 0.8

# No speaker labels (clean output)
python scripts/segment_text.py input.json -o output.srt --no-speaker-labels

# Disable speaker detection entirely
python scripts/segment_text.py input.json -o output.srt --no-diarization
```

### Different Output Formats

```bash
# SRT with speakers (default)
python scripts/segment_text.py input.json -o output.srt

# WebVTT format
python scripts/segment_text.py input.json -o output.vtt --format vtt

# Plain text with speaker labels
python scripts/segment_text.py input.json -o output.txt --format txt
```

## Examples

### Example 1: Interview with Two Speakers

**Input:** Whisper JSON with word timestamps

**Command:**
```bash
python scripts/segment_text.py interview.json -o output.srt
```

**Output:**
```srt
1
00:00:01,200 --> 00:00:03,800
A: Hello and welcome to
our show today

2
00:00:04,100 --> 00:00:06,500
B: Thank you for having
me here

3
00:00:06,900 --> 00:00:09,200
A: Let's start with your
background

4
00:00:09,600 --> 00:00:12,400
B: Sure I graduated from
MIT in 2015
```

### Example 2: Three-Person Discussion

**Output:**
```srt
1
00:00:00,500 --> 00:00:02,800
A: What do you think about
this proposal

2
00:00:03,200 --> 00:00:05,600
B: I think it has merit
but needs work

3
00:00:06,100 --> 00:00:08,400
C: I agree with B on this
point specifically

4
00:00:08,900 --> 00:00:11,200
A: Okay let's discuss the
budget then
```

### Example 3: Plain Text (No Timestamps)

**Input:**
```
Hello how are you doing today I'm doing great thanks for asking That's wonderful to hear
```

**Command:**
```bash
python scripts/segment_text.py input.txt -o output.srt --no-diarization
```

**Output:**
```srt
1
00:00:00,000 --> 00:00:00,000
A: Hello how are you
 doing today

2
00:00:00,000 --> 00:00:00,000
A: I'm doing great thanks
for asking

3
00:00:00,000 --> 00:00:00,000
A: That's wonderful to hear
```

## Tips for Best Results

### Speaker Detection

1. **Clear audio**: Background noise can affect pause detection accuracy
2. **Adjust threshold**: Tune `--pause-threshold` based on speaking pace
3. **Review output**: Always check speaker labels and correct if needed
4. **Consistent volume**: Large volume changes between speakers may help detection

### Subtitle Quality

1. **Pre-process text**: Remove filler words ("um", "uh") if desired
2. **Adjust max-chars**: YouTube allows 42 chars/line, Netflix 32-40
3. **Review timing**: Automatic timing is approximate; adjust for readability
4. **Test readability**: Read subtitles aloud to check pacing

## Common Issues

| Issue | Solution |
|-------|----------|
| Wrong speaker assigned | Adjust `--pause-threshold` or manually correct |
| Too many speakers detected | Increase `--pause-threshold` |
| Speakers merged into one | Decrease `--pause-threshold` |
| Segments too long | Reduce `--max-chars` or increase `--max-lines` |
| Segments too short | Increase `--max-chars` |
| Poor split points | Use `--preserve-sentences=true` |
| No speaker detection | Ensure Whisper JSON has word timestamps |
