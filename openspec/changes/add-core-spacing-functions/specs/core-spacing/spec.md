# Core Spacing Functions Specification

## ADDED Requirements

### Core Functions
**REQ-CORE-001**: The plugin MUST provide a `remove` function that removes text while maintaining proper spacing.

**REQ-CORE-002**: The plugin MUST provide an `insert` function that inserts text while maintaining proper spacing.

**REQ-CORE-003**: Both functions MUST accept text range parameters (start line, start column, end line, end column).

**REQ-CORE-004**: Both functions MUST return success/failure status and any error messages.

### Spacing Rules
**REQ-SPACE-001**: When removing text, the function MUST ensure exactly one space remains between words.

**REQ-SPACE-002**: When inserting text, the function MUST ensure exactly one space exists between the inserted text and surrounding words.

**REQ-SPACE-003**: The functions MUST handle punctuation correctly (no space before punctuation, one space after).

**REQ-SPACE-004**: The functions MUST preserve existing newlines and paragraph breaks.

**REQ-SPACE-005**: The functions MUST handle empty strings and single characters correctly.

### Context Awareness
**REQ-CTX-001**: The functions MUST handle text at the beginning of a line (no leading space added).

**REQ-CTX-002**: The functions MUST handle text at the end of a line (no trailing space added).

**REQ-CTX-003**: The functions MUST handle text in the middle of a line (maintain single spaces on both sides).

**REQ-CTX-004**: The functions MUST handle consecutive spaces (collapse to single space).

### Performance
**REQ-PERF-001**: The functions MUST complete within 10ms for typical editing operations.

**REQ-PERF-002**: The functions MUST not block Neovim UI during execution.

**REQ-PERF-003**: Memory usage MUST be minimal and proportional to text size.

## Scenarios

### Scenario: Basic Text Removal
**Given** a buffer containing "this is text I want to change"
**When** `remove` is called on the word "text"
**Then** the result should be "this is I want to change"
**And** exactly one space should remain between "is" and "I"

#### Scenario: Removal with Multiple Spaces
**Given** a buffer containing "this  is   text    I want"
**When** `remove` is called on the word "text"
**Then** the result should be "this is I want"
**And** all extra spaces should be collapsed to single spaces

#### Scenario: Removal at Line Beginning
**Given** a buffer containing "text at the beginning"
**When** `remove` is called on the word "text"
**Then** the result should be "at the beginning"
**And** no leading space should be added

#### Scenario: Removal at Line End
**Given** a buffer containing "remove the last word"
**When** `remove` is called on the word "word"
**Then** the result should be "remove the last"
**And** no trailing space should remain

### Scenario: Basic Text Insertion
**Given** a buffer containing "this is I want to change"
**When** `insert` is called to add "text" between "is" and "I"
**Then** the result should be "this is text I want to change"
**And** exactly one space should exist on both sides of "text"

#### Scenario: Insertion with Existing Spaces
**Given** a buffer containing "this is  I want"
**When** `insert` is called to add "text" between "is" and "I"
**Then** the result should be "this is text I want"
**And** extra spaces should be collapsed to single space

#### Scenario: Insertion at Line Beginning
**Given** a buffer containing "at the beginning"
**When** `insert` is called to add "text" at the beginning
**Then** the result should be "text at the beginning"
**And** no leading space should be added before "text"

#### Scenario: Insertion at Line End
**Given** a buffer containing "add to the"
**When** `insert` is called to add "end" at the end
**Then** the result should be "add to the end"
**And** exactly one space should exist before "end"

### Scenario: Punctuation Handling
**Given** a buffer containing "this is text, I want"
**When** `remove` is called on the word "text"
**Then** the result should be "this is, I want"
**And** no space should exist before the comma

#### Scenario: Multiple Punctuation
**Given** a buffer containing "hello! how are you?"
**When** `insert` is called to add "world" after "hello"
**Then** the result should be "hello world! how are you?"
**And** exactly one space should exist between "hello" and "world"

### Scenario: Empty String Handling
**Given** a buffer containing "normal text"
**When** `remove` is called on an empty range
**Then** the buffer should remain unchanged
**And** the function should return success

#### Scenario: Single Character
**Given** a buffer containing "a b c"
**When** `remove` is called on the character "b"
**Then** the result should be "a c"
**And** exactly one space should remain between "a" and "c"

## API Specification

### `remove(start_line, start_col, end_line, end_col)`
Removes text in the specified range and adjusts spacing.

**Parameters:**
- `start_line` (number): Starting line number (1-indexed)
- `start_col` (number): Starting column number (0-indexed)
- `end_line` (number): Ending line number (1-indexed)
- `end_col` (number): Ending column number (0-indexed)

**Returns:**
- `success` (boolean): True if operation succeeded
- `error` (string|nil): Error message if operation failed

### `insert(line, col, text)`
Inserts text at the specified position and adjusts spacing.

**Parameters:**
- `line` (number): Line number (1-indexed)
- `col` (number): Column number (0-indexed)
- `text` (string): Text to insert

**Returns:**
- `success` (boolean): True if operation succeeded
- `error` (string|nil): Error message if operation failed

## Error Conditions

### Invalid Range
- If start position is after end position
- If line numbers are out of buffer bounds
- If column numbers are out of line bounds

### Buffer State
- If buffer is read-only
- If buffer is modified by another process during operation

### Memory Limits
- If operation would exceed memory limits (very large text)

## Configuration Options

### Spacing Behavior
- `aggressive_spacing` (boolean): Whether to always ensure single spaces (default: true)
- `preserve_tabs` (boolean): Whether to preserve tab characters (default: false)
- `punctuation_rules` (table): Custom punctuation spacing rules

### Performance
- `max_operation_size` (number): Maximum text size for automatic spacing (default: 100KB)
- `timeout_ms` (number): Operation timeout in milliseconds (default: 100)