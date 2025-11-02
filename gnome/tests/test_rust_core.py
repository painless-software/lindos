"""Tests for the rust_core module."""

import sys
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

# Add LindosTrayApp to the path for testing purposes.
# This allows tests to import the modules without requiring proper package structure.
# In production, LindosTrayApp would be properly structured as a package.
sys.path.insert(0, str(Path(__file__).parent.parent / "LindosTrayApp"))

# Import the actual classes to test
from rust_core import ProcessingError, RustCore, RustResult


class TestProcessingError:
    """Test the ProcessingError exception class."""

    def test_error_codes_defined(self):
        """Test that error codes are defined as class constants."""
        assert ProcessingError.NULL_POINTER == 1
        assert ProcessingError.INVALID_UTF8 == 2
        assert ProcessingError.EMPTY_MESSAGE == 3
        assert ProcessingError.PROCESSING_FAILURE == 4

    def test_error_with_code(self):
        """Test creating error with just an error code."""
        error = ProcessingError(ProcessingError.NULL_POINTER)
        assert error.error_code == 1
        assert error.message == "No message provided"
        assert str(error) == "No message provided"

    def test_error_with_custom_message(self):
        """Test creating error with custom message."""
        error = ProcessingError(ProcessingError.NULL_POINTER, "Custom message")
        assert error.error_code == 1
        assert error.message == "Custom message"

    def test_error_description_for_invalid_utf8(self):
        """Test error description for INVALID_UTF8."""
        error = ProcessingError(ProcessingError.INVALID_UTF8)
        assert error.message == "Message contains invalid characters"

    def test_error_description_for_empty_message(self):
        """Test error description for EMPTY_MESSAGE."""
        error = ProcessingError(ProcessingError.EMPTY_MESSAGE)
        assert error.message == "Message cannot be empty"

    def test_error_description_for_processing_failure(self):
        """Test error description for PROCESSING_FAILURE."""
        error = ProcessingError(ProcessingError.PROCESSING_FAILURE)
        assert error.message == "Failed to process message"

    def test_unknown_error_code(self):
        """Test error description for unknown error code."""
        error = ProcessingError(999)
        assert "Unknown error (code: 999)" in error.message


class TestRustResult:
    """Test the RustResult ctypes structure."""

    def test_structure_fields(self):
        """Test that RustResult has the correct fields."""
        result = RustResult()
        assert hasattr(result, "success")
        assert hasattr(result, "data")
        assert hasattr(result, "error_code")


class TestRustCore:
    """Test the RustCore class."""

    def test_validate_with_mock_library(self):
        """Test validate method with mocked library."""
        with patch.object(RustCore, "_load_library") as mock_load:
            mock_lib = MagicMock()
            mock_lib.lindos_validate_message.return_value = 0
            mock_load.return_value = mock_lib

            error = RustCore.validate("test message")
            assert error is None
            mock_lib.lindos_validate_message.assert_called_once()

    def test_validate_returns_error(self):
        """Test validate method when validation fails."""
        with patch.object(RustCore, "_load_library") as mock_load:
            mock_lib = MagicMock()
            mock_lib.lindos_validate_message.return_value = (
                ProcessingError.EMPTY_MESSAGE
            )
            mock_load.return_value = mock_lib

            error = RustCore.validate("test message")
            assert error is not None
            assert error.error_code == ProcessingError.EMPTY_MESSAGE

    def test_validate_unicode_error(self):
        """Test validate method with unicode encoding error."""
        # Since we can't mock str.encode directly, we'll test by passing
        # the validation through and ensuring the error path works correctly
        with patch.object(RustCore, "_load_library") as mock_load:
            mock_lib = MagicMock()
            # Simulate that the library returns an INVALID_UTF8 error
            mock_lib.lindos_validate_message.return_value = ProcessingError.INVALID_UTF8
            mock_load.return_value = mock_lib

            error = RustCore.validate("test message with unicode")
            assert error is not None
            assert error.error_code == ProcessingError.INVALID_UTF8

    def test_set_debug_enabled(self):
        """Test set_debug_enabled method."""
        with patch.object(RustCore, "_load_library") as mock_load:
            mock_lib = MagicMock()
            mock_load.return_value = mock_lib

            RustCore.set_debug_enabled(True)
            mock_lib.lindos_set_debug.assert_called_once_with(True)
            assert RustCore._debug_enabled is True

            RustCore.set_debug_enabled(False)
            assert RustCore._debug_enabled is False

    def test_process_with_result_success(self):
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

    def test_process_with_result_failure(self):
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

    def test_process_with_result_null_data_on_success(self):
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

    def test_process_legacy_interface(self):
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

    def test_get_error_message(self):
        """Test get_error_message method."""
        with patch.object(RustCore, "_load_library") as mock_load:
            mock_lib = MagicMock()
            mock_lib.lindos_error_message.return_value = b"Error message from Rust"
            mock_load.return_value = mock_lib

            message = RustCore.get_error_message(1)
            assert message == "Error message from Rust"
            mock_lib.lindos_string_free.assert_called_once()

    def test_get_error_message_null_pointer(self):
        """Test get_error_message when Rust returns null."""
        with patch.object(RustCore, "_load_library") as mock_load:
            mock_lib = MagicMock()
            mock_lib.lindos_error_message.return_value = None
            mock_load.return_value = mock_lib

            message = RustCore.get_error_message(999)
            assert message == "Unknown error"

    def test_library_not_found_error(self):
        """Test that appropriate error is raised when library is not found."""
        # Reset the class variable
        RustCore._lib = None

        with patch("pathlib.Path.exists", return_value=False):
            with pytest.raises(FileNotFoundError, match="Rust library not found"):
                RustCore._load_library()

    def test_library_loaded_once(self):
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
