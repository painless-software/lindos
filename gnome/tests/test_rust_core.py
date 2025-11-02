"""Tests for the rust_core module."""

from unittest.mock import MagicMock, patch

import pytest

from LindosTrayApp.rust_core import ProcessingError, RustCore, RustResult


def test_processing_error_with_code():
    """Test creating error with just an error code."""
    error = ProcessingError(ProcessingError.NULL_POINTER)
    assert error.error_code == 1
    assert error.message == "No message provided"
    assert str(error) == "No message provided"


def test_processing_error_with_custom_message():
    """Test creating error with custom message."""
    error = ProcessingError(ProcessingError.NULL_POINTER, "Custom message")
    assert error.error_code == 1
    assert error.message == "Custom message"


def test_processing_error_description_for_invalid_utf8():
    """Test error description for INVALID_UTF8."""
    error = ProcessingError(ProcessingError.INVALID_UTF8)
    assert error.message == "Message contains invalid characters"


def test_processing_error_description_for_empty_message():
    """Test error description for EMPTY_MESSAGE."""
    error = ProcessingError(ProcessingError.EMPTY_MESSAGE)
    assert error.message == "Message cannot be empty"


def test_processing_error_description_for_processing_failure():
    """Test error description for PROCESSING_FAILURE."""
    error = ProcessingError(ProcessingError.PROCESSING_FAILURE)
    assert error.message == "Failed to process message"


def test_processing_error_unknown_code():
    """Test error description for unknown error code."""
    error = ProcessingError(999)
    assert "Unknown error (code: 999)" in error.message


def test_rust_result_structure_fields():
    """Test that RustResult has the correct fields."""
    result = RustResult()
    assert hasattr(result, "success")
    assert hasattr(result, "data")
    assert hasattr(result, "error_code")


def test_rust_core_validate_success():
    """Test validate method with successful validation."""
    with patch.object(RustCore, "_load_library") as mock_load:
        mock_lib = MagicMock()
        mock_lib.lindos_validate_message.return_value = 0
        mock_load.return_value = mock_lib

        error = RustCore.validate("test message")
        assert error is None
        mock_lib.lindos_validate_message.assert_called_once()


def test_rust_core_validate_returns_error():
    """Test validate method when validation fails."""
    with patch.object(RustCore, "_load_library") as mock_load:
        mock_lib = MagicMock()
        mock_lib.lindos_validate_message.return_value = ProcessingError.EMPTY_MESSAGE
        mock_load.return_value = mock_lib

        error = RustCore.validate("test message")
        assert error is not None
        assert error.error_code == ProcessingError.EMPTY_MESSAGE


def test_rust_core_validate_unicode_error():
    """Test validate method with unicode encoding error."""
    with patch.object(RustCore, "_load_library") as mock_load:
        mock_lib = MagicMock()
        mock_lib.lindos_validate_message.return_value = ProcessingError.INVALID_UTF8
        mock_load.return_value = mock_lib

        error = RustCore.validate("test message with unicode")
        assert error is not None
        assert error.error_code == ProcessingError.INVALID_UTF8


def test_rust_core_set_debug_enabled():
    """Test set_debug_enabled method."""
    with patch.object(RustCore, "_load_library") as mock_load:
        mock_lib = MagicMock()
        mock_load.return_value = mock_lib

        RustCore.set_debug_enabled(True)
        mock_lib.lindos_set_debug.assert_called_once_with(True)
        assert RustCore._debug_enabled is True

        RustCore.set_debug_enabled(False)
        assert RustCore._debug_enabled is False


def test_rust_core_process_with_result_success():
    """Test process_with_result with successful result."""
    with patch.object(RustCore, "_load_library") as mock_load:
        mock_lib = MagicMock()
        mock_result = RustResult()
        mock_result.success = True
        mock_result.data = b"processed result"
        mock_result.error_code = 0
        mock_lib.lindos_process_message_safe.return_value = mock_result
        mock_load.return_value = mock_lib

        result, error = RustCore.process_with_result("test message")
        assert result == "processed result"
        assert error is None
        mock_lib.lindos_result_free.assert_called_once()


def test_rust_core_process_with_result_failure():
    """Test process_with_result with failure result."""
    with patch.object(RustCore, "_load_library") as mock_load:
        mock_lib = MagicMock()
        mock_result = RustResult()
        mock_result.success = False
        mock_result.data = b"error message"
        mock_result.error_code = ProcessingError.EMPTY_MESSAGE
        mock_lib.lindos_process_message_safe.return_value = mock_result
        mock_load.return_value = mock_lib

        result, error = RustCore.process_with_result("test message")
        assert result is None
        assert error is not None
        assert error.error_code == ProcessingError.EMPTY_MESSAGE
        mock_lib.lindos_result_free.assert_called_once()


def test_rust_core_process_with_result_null_data_on_success():
    """Test process_with_result when success but data is null."""
    with patch.object(RustCore, "_load_library") as mock_load:
        mock_lib = MagicMock()
        mock_result = RustResult()
        mock_result.success = True
        mock_result.data = None
        mock_result.error_code = 0
        mock_lib.lindos_process_message_safe.return_value = mock_result
        mock_load.return_value = mock_lib

        result, error = RustCore.process_with_result("test message")
        assert result is None
        assert error is not None
        assert "null data pointer" in error.message


def test_rust_core_process_legacy_interface():
    """Test the legacy process method."""
    with patch.object(RustCore, "process_with_result") as mock_process:
        mock_process.return_value = ("result", None)
        result = RustCore.process("test message")
        assert result == "result"

        mock_process.return_value = (
            None,
            ProcessingError(ProcessingError.EMPTY_MESSAGE),
        )
        result = RustCore.process("test message")
        assert result == "Message cannot be empty"


def test_rust_core_get_error_message():
    """Test get_error_message method."""
    with patch.object(RustCore, "_load_library") as mock_load:
        mock_lib = MagicMock()
        mock_lib.lindos_error_message.return_value = b"Error message from Rust"
        mock_load.return_value = mock_lib

        message = RustCore.get_error_message(1)
        assert message == "Error message from Rust"
        mock_lib.lindos_string_free.assert_called_once()


def test_rust_core_get_error_message_null_pointer():
    """Test get_error_message when Rust returns null."""
    with patch.object(RustCore, "_load_library") as mock_load:
        mock_lib = MagicMock()
        mock_lib.lindos_error_message.return_value = None
        mock_load.return_value = mock_lib

        message = RustCore.get_error_message(999)
        assert message == "Unknown error"


def test_rust_core_library_not_found_error():
    """Test that appropriate error is raised when library is not found."""
    # Reset the class variable
    RustCore._lib = None

    with patch("pathlib.Path.exists", return_value=False):
        with pytest.raises(FileNotFoundError, match="Rust library not found"):
            RustCore._load_library()


def test_rust_core_library_loaded_once():
    """Test that library is only loaded once."""
    # Save the original state
    original_lib = RustCore._lib

    try:
        # Set a mock library
        mock_lib = MagicMock()
        RustCore._lib = mock_lib

        lib1 = RustCore._load_library()
        lib2 = RustCore._load_library()
        assert lib1 is lib2
        assert lib1 is mock_lib
    finally:
        # Restore original state
        RustCore._lib = original_lib
