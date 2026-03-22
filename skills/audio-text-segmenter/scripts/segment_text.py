#!/usr/bin/env python3
"""
Audio Text Segmenter with Speaker Diarization
Segments transcribed text and identifies different speakers.
"""

import re
import argparse
import json
from typing import List, Dict, Tuple, Optional
from dataclasses import dataclass, field
from datetime import timedelta
from collections import defaultdict
import math


@dataclass
class Word:
    """Represents a word with timing."""
    text: str
    start_time: float
    end_time: float
    speaker: Optional[str] = None


@dataclass
class Segment:
    """Represents a subtitle segment."""
    text: str
    start_time: Optional[float] = None
    end_time: Optional[float] = None
    speaker: Optional[str] = None
    speaker_label: str = ""  # A, B, C, etc.
    
    def format_time(self, seconds: float) -> str:
        """Format seconds to SRT time format."""
        td = timedelta(seconds=seconds)
        hours, remainder = divmod(td.seconds, 3600)
        minutes, seconds = divmod(remainder, 60)
        milliseconds = int(td.microseconds / 1000)
        return f"{hours:02d}:{minutes:02d}:{seconds:02d},{milliseconds:03d}"
    
    def to_srt(self, index: int, show_speaker: bool = True) -> str:
        """Convert segment to SRT format."""
        start = self.format_time(self.start_time) if self.start_time else "00:00:00,000"
        end = self.format_time(self.end_time) if self.end_time else "00:00:00,000"
        
        text = self.text
        if show_speaker and self.speaker_label:
            text = f"{self.speaker_label}: {text}"
        
        return f"{index}\n{start} --> {end}\n{text}\n"
    
    def to_vtt(self, show_speaker: bool = True) -> str:
        """Convert segment to VTT format."""
        start = self.format_time(self.start_time).replace(',', '.') if self.start_time else "00:00:00.000"
        end = self.format_time(self.end_time).replace(',', '.') if self.end_time else "00:00:00.000"
        
        text = self.text
        if show_speaker and self.speaker_label:
            text = f"{self.speaker_label}: {text}"
        
        return f"{start} --> {end}\n{text}\n"


class SpeakerDiarizer:
    """Identifies different speakers based on audio characteristics."""
    
    def __init__(self, pause_threshold: float = 1.0, min_segment_duration: float = 0.5):
        self.pause_threshold = pause_threshold
        self.min_segment_duration = min_segment_duration
        self.speaker_counter = 0
        self.speaker_map = {}  # Maps internal speaker ID to A, B, C...
    
    def get_speaker_label(self, speaker_id: str) -> str:
        """Get letter label for speaker (A, B, C...)."""
        if speaker_id not in self.speaker_map:
            self.speaker_map[speaker_id] = chr(ord('A') + self.speaker_counter)
            self.speaker_counter += 1
        return self.speaker_map[speaker_id]
    
    def diarize_heuristic(self, words: List[Word]) -> List[Word]:
        """
        Heuristic speaker diarization based on pauses and timing patterns.
        This is a simplified approach - for production use, consider pyannote.audio.
        """
        if not words:
            return words
        
        # Strategy: Long pauses often indicate speaker turns
        current_speaker = "SPEAKER_0"
        last_end_time = words[0].start_time
        
        for i, word in enumerate(words):
            pause_duration = word.start_time - last_end_time
            
            # If pause is long enough, consider it a speaker change
            if pause_duration > self.pause_threshold and i > 0:
                # Alternate between speakers (simplified heuristic)
                if current_speaker == "SPEAKER_0":
                    current_speaker = "SPEAKER_1"
                else:
                    # Check if we should add a third speaker
                    current_speaker = f"SPEAKER_{self.speaker_counter}"
            
            word.speaker = current_speaker
            last_end_time = word.end_time
        
        # Post-process: merge short segments of the same speaker
        words = self._merge_same_speaker_words(words)
        
        return words
    
    def _merge_same_speaker_words(self, words: List[Word]) -> List[Word]:
        """Merge consecutive words from the same speaker."""
        if not words:
            return words
        
        merged = []
        current_group = [words[0]]
        
        for word in words[1:]:
            if word.speaker == current_group[0].speaker:
                current_group.append(word)
            else:
                # Save current group
                merged_word = Word(
                    text=" ".join(w.text for w in current_group),
                    start_time=current_group[0].start_time,
                    end_time=current_group[-1].end_time,
                    speaker=current_group[0].speaker
                )
                merged.append(merged_word)
                current_group = [word]
        
        # Don't forget the last group
        if current_group:
            merged_word = Word(
                text=" ".join(w.text for w in current_group),
                start_time=current_group[0].start_time,
                end_time=current_group[-1].end_time,
                speaker=current_group[0].speaker
            )
            merged.append(merged_word)
        
        return merged


class TextSegmenter:
    """Segments text into subtitle-friendly chunks with speaker identification."""
    
    def __init__(self, max_chars: int = 40, max_lines: int = 2, 
                 pause_threshold: float = 1.0, preserve_sentences: bool = True,
                 enable_diarization: bool = True):
        self.max_chars = max_chars
        self.max_lines = max_lines
        self.pause_threshold = pause_threshold
        self.preserve_sentences = preserve_sentences
        self.enable_diarization = enable_diarization
        self.max_total_chars = max_chars * max_lines
        
        self.diarizer = SpeakerDiarizer(pause_threshold=pause_threshold)
        
        # Split patterns
        self.sentence_endings = re.compile(r'[.!?]+\s+')
        self.clause_boundaries = re.compile(r'[,;:]\s+')
        self.conjunctions = re.compile(r'\s+(and|but|or|so|yet|however|therefore)\s+', re.IGNORECASE)
    
    def parse_whisper_json(self, data: Dict) -> List[Word]:
        """Parse Whisper JSON output into Word objects."""
        words = []
        
        if 'segments' in data:
            for segment in data['segments']:
                if 'words' in segment:
                    for word_data in segment['words']:
                        word = Word(
                            text=word_data.get('word', '').strip(),
                            start_time=word_data.get('start', 0),
                            end_time=word_data.get('end', 0)
                        )
                        words.append(word)
                else:
                    # Fallback: create word from segment text
                    text = segment.get('text', '').strip()
                    start = segment.get('start', 0)
                    end = segment.get('end', 0)
                    # Split into approximate words
                    word_list = text.split()
                    if word_list:
                        duration = end - start
                        word_duration = duration / len(word_list)
                        for i, w in enumerate(word_list):
                            word = Word(
                                text=w,
                                start_time=start + i * word_duration,
                                end_time=start + (i + 1) * word_duration
                            )
                            words.append(word)
        
        return words
    
    def find_split_point(self, text: str, target_length: int) -> int:
        """Find the best split point near target length."""
        if len(text) <= target_length:
            return len(text)
        
        min_search = int(target_length * 0.5)
        max_search = min(len(text), target_length + 20)
        search_text = text[min_search:max_search]
        
        # Priority 1: Sentence endings
        if self.preserve_sentences:
            for match in self.sentence_endings.finditer(search_text):
                return min_search + match.end()
        
        # Priority 2: Clause boundaries
        for match in self.clause_boundaries.finditer(search_text):
            return min_search + match.end()
        
        # Priority 3: Conjunctions
        for match in self.conjunctions.finditer(search_text):
            return min_search + match.start() + 1
        
        # Priority 4: Word boundary
        space_pos = text.rfind(' ', min_search, max_search)
        if space_pos != -1:
            return space_pos + 1
        
        return target_length
    
    def split_into_lines(self, text: str) -> List[str]:
        """Split text into lines respecting max_chars."""
        lines = []
        remaining = text.strip()
        
        while remaining:
            if len(remaining) <= self.max_chars:
                lines.append(remaining)
                break
            
            split_point = self.find_split_point(remaining, self.max_chars)
            line = remaining[:split_point].strip()
            if line:
                lines.append(line)
            remaining = remaining[split_point:].strip()
        
        return lines[:self.max_lines]
    
    def segment_with_speakers(self, words: List[Word]) -> List[Segment]:
        """Segment words into subtitle entries with speaker labels."""
        if not words:
            return []
        
        # Perform speaker diarization
        if self.enable_diarization:
            words = self.diarizer.diarize_heuristic(words)
        
        segments = []
        current_text = ""
        current_speaker = None
        current_start = None
        current_end = None
        
        for word in words:
            # Check if speaker changed
            if current_speaker is not None and word.speaker != current_speaker:
                # Save current segment
                if current_text:
                    lines = self.split_into_lines(current_text)
                    segment_text = '\n'.join(lines)
                    segment = Segment(
                        text=segment_text,
                        start_time=current_start,
                        end_time=current_end,
                        speaker=current_speaker,
                        speaker_label=self.diarizer.get_speaker_label(current_speaker)
                    )
                    segments.append(segment)
                
                # Start new segment
                current_text = word.text
                current_speaker = word.speaker
                current_start = word.start_time
                current_end = word.end_time
            else:
                # Continue current segment
                if not current_text:
                    current_text = word.text
                    current_speaker = word.speaker
                    current_start = word.start_time
                else:
                    current_text += " " + word.text
                current_end = word.end_time
                
                # Check if segment is getting too long
                test_lines = self.split_into_lines(current_text)
                total_chars = sum(len(line) for line in test_lines)
                
                if total_chars > self.max_total_chars:
                    # Find a good split point
                    lines = self.split_into_lines(current_text)
                    segment_text = '\n'.join(lines)
                    segment = Segment(
                        text=segment_text,
                        start_time=current_start,
                        end_time=current_end,
                        speaker=current_speaker,
                        speaker_label=self.diarizer.get_speaker_label(current_speaker)
                    )
                    segments.append(segment)
                    current_text = ""
                    current_start = None
        
        # Don't forget the last segment
        if current_text:
            lines = self.split_into_lines(current_text)
            segment_text = '\n'.join(lines)
            segment = Segment(
                text=segment_text,
                start_time=current_start,
                end_time=current_end,
                speaker=current_speaker,
                speaker_label=self.diarizer.get_speaker_label(current_speaker)
            )
            segments.append(segment)
        
        return segments
    
    def process_file(self, input_path: str, output_path: str, output_format: str = 'srt',
                     show_speaker: bool = True):
        """Process input file and generate segmented output with speakers."""
        # Read input
        with open(input_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Try to parse as JSON (Whisper output)
        try:
            data = json.loads(content)
            words = self.parse_whisper_json(data)
            segments = self.segment_with_speakers(words)
        except json.JSONDecodeError:
            # Treat as plain text - no speaker detection possible
            print("Warning: Plain text input detected. Speaker diarization requires Whisper JSON with timestamps.")
            print("Processing as single speaker...")
            segments = self._process_plain_text(content)
        
        # Generate output
        if output_format == 'srt':
            output = self._to_srt(segments, show_speaker)
        elif output_format == 'vtt':
            output = self._to_vtt(segments, show_speaker)
        elif output_format == 'txt':
            output = self._to_txt(segments, show_speaker)
        else:
            raise ValueError(f"Unknown format: {output_format}")
        
        # Write output
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(output)
        
        # Print summary
        speaker_counts = defaultdict(int)
        for seg in segments:
            if seg.speaker_label:
                speaker_counts[seg.speaker_label] += 1
        
        print(f"\n[OK] Generated {len(segments)} segments")
        print(f"[INFO] Detected speakers: {dict(speaker_counts)}")
        print(f"[SAVE] Output saved to: {output_path}")
    
    def _process_plain_text(self, text: str) -> List[Segment]:
        """Process plain text without timestamps."""
        segments = []
        sentences = self.sentence_endings.split(text)
        sentences = [s.strip() for s in sentences if s.strip()]
        
        for sentence in sentences:
            lines = self.split_into_lines(sentence)
            segment_text = '\n'.join(lines)
            segments.append(Segment(text=segment_text, speaker_label="A"))
        
        return segments
    
    def _to_srt(self, segments: List[Segment], show_speaker: bool) -> str:
        """Convert segments to SRT format."""
        return '\n'.join(seg.to_srt(i+1, show_speaker) for i, seg in enumerate(segments))
    
    def _to_vtt(self, segments: List[Segment], show_speaker: bool) -> str:
        """Convert segments to VTT format."""
        header = "WEBVTT\n\n"
        body = '\n'.join(seg.to_vtt(show_speaker) for seg in segments)
        return header + body
    
    def _to_txt(self, segments: List[Segment], show_speaker: bool) -> str:
        """Convert segments to plain text with timestamps."""
        lines = []
        for seg in segments:
            time_str = ""
            if seg.start_time is not None:
                minutes = int(seg.start_time // 60)
                seconds = int(seg.start_time % 60)
                time_str = f"[{minutes:02d}:{seconds:02d}] "
            
            text = seg.text.replace('\n', ' ')
            if show_speaker and seg.speaker_label:
                lines.append(f"{time_str}{seg.speaker_label}: {text}")
            else:
                lines.append(f"{time_str}{text}")
        return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(
        description='Segment text into subtitle-friendly chunks with speaker identification'
    )
    parser.add_argument('input', help='Input file path (Whisper JSON or plain text)')
    parser.add_argument('--output', '-o', required=True, help='Output file path')
    parser.add_argument('--format', '-f', default='srt', choices=['srt', 'vtt', 'txt'],
                        help='Output format (default: srt)')
    parser.add_argument('--max-chars', '-c', type=int, default=40,
                        help='Maximum characters per line (default: 40)')
    parser.add_argument('--max-lines', '-l', type=int, default=2,
                        help='Maximum lines per subtitle (default: 2)')
    parser.add_argument('--pause-threshold', '-p', type=float, default=1.0,
                        help='Pause threshold for speaker change in seconds (default: 1.0)')
    parser.add_argument('--preserve-sentences', '-s', action='store_true', default=True,
                        help='Preserve sentence boundaries (default: True)')
    parser.add_argument('--no-diarization', action='store_true',
                        help='Disable speaker diarization')
    parser.add_argument('--no-speaker-labels', action='store_true',
                        help='Hide speaker labels in output')
    
    args = parser.parse_args()
    
    segmenter = TextSegmenter(
        max_chars=args.max_chars,
        max_lines=args.max_lines,
        pause_threshold=args.pause_threshold,
        preserve_sentences=args.preserve_sentences,
        enable_diarization=not args.no_diarization
    )
    
    segmenter.process_file(
        args.input, 
        args.output, 
        args.format,
        show_speaker=not args.no_speaker_labels
    )


if __name__ == '__main__':
    main()
