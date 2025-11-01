"""Python wrapper for Rust core functionality with enhanced error handling.

This module provides a Python interface to the Rust core library,
mirroring the Swift implementation's approach to FFI bindings.
"""

import ctypes
import os
from pathlib import Path
from typing import Optional, Tuple


class ProcessingError(Exception):
    """Errors that can occur during Rust processing."""
    
    NULL_POINTER = 1
    INVALID_UTF8 = 2
    EMPTY_MESSAGE = 3
    PROCESSING_FAILURE = 4
    
    def __init__(self, error_code: int, message: str = ""):
        self.error_code = error_code
        self.message = message or self._get_error_description(error_code)
        super().__init__(self.message)
    
    @staticmethod
    def _get_error_description(error_code: int) -> str:
        """Get a human-readable error message for an error code."""
        descriptions = {
            ProcessingError.NULL_POINTER: "No message provided",
            ProcessingError.INVALID_UTF8: "Message contains invalid characters",
            ProcessingError.EMPTY_MESSAGE: "Message cannot be empty",
            ProcessingError.PROCESSING_FAILURE: "Failed to process message",
        }
        return descriptions.get(error_code, f"Unknown error (code: {error_code})")


class RustResult(ctypes.Structure):
    """Result structure for FFI calls that need to return both success/failure and data."""
    _fields_ = [
        ("success", ctypes.c_bool),
        ("data", ctypes.c_char_p),
        ("error_code", ctypes.c_int32),
    ]


class RustCore:
    """Swift-like wrapper for Rust core functionality."""
    
    _lib = None
    _debug_enabled = False
    
    @classmethod
    def _load_library(cls):
        """Load the Rust library if not already loaded."""
        if cls._lib is not None:
            return cls._lib
        
        # Find the library in the rust-core target directory
        repo_root = Path(__file__).parent.parent.parent
        lib_path = repo_root / "rust-core" / "target" / "release" / "librust_core.so"
        
        if not lib_path.exists():
            raise FileNotFoundError(
                f"Rust library not found at {lib_path}. "
                "Please build it first with: cd rust-core && cargo build --release"
            )
        
        cls._lib = ctypes.CDLL(str(lib_path))
        
        # Define function signatures
        
        # lindos_process_message_safe
        cls._lib.lindos_process_message_safe.argtypes = [ctypes.c_char_p]
        cls._lib.lindos_process_message_safe.restype = RustResult
        
        # lindos_validate_message
        cls._lib.lindos_validate_message.argtypes = [ctypes.c_char_p]
        cls._lib.lindos_validate_message.restype = ctypes.c_int32
        
        # lindos_error_message
        cls._lib.lindos_error_message.argtypes = [ctypes.c_int32]
        cls._lib.lindos_error_message.restype = ctypes.c_char_p
        
        # lindos_string_free
        cls._lib.lindos_string_free.argtypes = [ctypes.c_char_p]
        cls._lib.lindos_string_free.restype = None
        
        # lindos_result_free
        cls._lib.lindos_result_free.argtypes = [RustResult]
        cls._lib.lindos_result_free.restype = None
        
        # lindos_set_debug
        cls._lib.lindos_set_debug.argtypes = [ctypes.c_bool]
        cls._lib.lindos_set_debug.restype = None
        
        return cls._lib
    
    @classmethod
    def set_debug_enabled(cls, enabled: bool):
        """Enable or disable debug logging in Rust."""
        lib = cls._load_library()
        lib.lindos_set_debug(enabled)
        cls._debug_enabled = enabled
    
    @classmethod
    def validate(cls, message: str) -> Optional[ProcessingError]:
        """Validate a message without processing it.
        
        Returns:
            ProcessingError if validation fails, None if valid.
        """
        lib = cls._load_library()
        
        try:
            c_string = message.encode('utf-8')
        except UnicodeEncodeError:
            return ProcessingError(ProcessingError.INVALID_UTF8)
        
        error_code = lib.lindos_validate_message(c_string)
        return ProcessingError(error_code) if error_code != 0 else None
    
    @classmethod
    def process(cls, message: str) -> str:
        """Process a message using the legacy interface (backwards compatible).
        
        This method never raises exceptions, instead returning error messages as strings.
        """
        result, error = cls.process_with_result(message)
        if error:
            return error.message
        return result
    
    @classmethod
    def process_with_result(cls, message: str) -> Tuple[Optional[str], Optional[ProcessingError]]:
        """Process a message with full error handling.
        
        Returns:
            A tuple of (result_string, error). If successful, error is None.
            If failed, result_string is None and error contains the ProcessingError.
        """
        lib = cls._load_library()
        
        if cls._debug_enabled:
            print(f"Processing message: {len(message)} characters")
        
        try:
            c_string = message.encode('utf-8')
        except UnicodeEncodeError:
            error = ProcessingError(ProcessingError.INVALID_UTF8)
            if cls._debug_enabled:
                print(f"Failed to convert message to UTF-8")
            return None, error
        
        rust_result = lib.lindos_process_message_safe(c_string)
        
        try:
            if rust_result.success:
                if not rust_result.data:
                    error = ProcessingError(-1, "Rust returned success but null data pointer")
                    if cls._debug_enabled:
                        print(error.message)
                    return None, error
                
                result_string = rust_result.data.decode('utf-8')
                if cls._debug_enabled:
                    print(f"Successfully processed message, result: {len(result_string)} characters")
                return result_string, None
            else:
                error = ProcessingError(rust_result.error_code)
                if cls._debug_enabled:
                    print(f"Rust processing failed with error code: {rust_result.error_code}")
                
                # Get the error message from Rust if available
                if rust_result.data:
                    error_message = rust_result.data.decode('utf-8')
                    if cls._debug_enabled:
                        print(f"Rust error message: {error_message}")
                
                return None, error
        finally:
            # Free the Rust-allocated memory
            lib.lindos_result_free(rust_result)
    
    @classmethod
    def get_error_message(cls, error_code: int) -> str:
        """Get a human-readable error message for an error code."""
        lib = cls._load_library()
        
        message_pointer = lib.lindos_error_message(error_code)
        if not message_pointer:
            return "Unknown error"
        
        try:
            return message_pointer.decode('utf-8')
        finally:
            lib.lindos_string_free(message_pointer)
