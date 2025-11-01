use ffi_support::rust_string_to_c;
use std::ffi::{c_char, CStr, CString};

/// Error types that can occur during message processing
#[derive(Debug, PartialEq)]
pub enum ProcessingError {
    NullPointer,
    InvalidUtf8(std::str::Utf8Error),
    EmptyMessage,
    ProcessingFailure(String),
}

impl ProcessingError {
    fn to_user_message(&self) -> &'static str {
        match self {
            ProcessingError::NullPointer => "Error: No message provided",
            ProcessingError::InvalidUtf8(_) => "Error: Message contains invalid characters",
            ProcessingError::EmptyMessage => "Error: Message cannot be empty",
            ProcessingError::ProcessingFailure(_) => "Error: Failed to process message",
        }
    }
}

/// Result structure for FFI calls that need to return both success/failure and data
#[repr(C)]
pub struct RustResult {
    pub success: bool,
    pub data: *mut c_char,
    pub error_code: i32,
}

impl RustResult {
    fn success(data: String) -> Self {
        RustResult {
            success: true,
            data: rust_string_to_c(data),
            error_code: 0,
        }
    }

    fn error(error: ProcessingError) -> Self {
        let error_message = error.to_user_message();
        RustResult {
            success: false,
            data: rust_string_to_c(error_message.to_string()),
            error_code: match error {
                ProcessingError::NullPointer => 1,
                ProcessingError::InvalidUtf8(_) => 2,
                ProcessingError::EmptyMessage => 3,
                ProcessingError::ProcessingFailure(_) => 4,
            },
        }
    }
}

/// Internal function to generate replies with error handling
fn generate_reply(input: &str) -> Result<String, ProcessingError> {
    if input.trim().is_empty() {
        return Ok("Hello from Rust core!".to_owned());
    }

    // Simulate potential processing errors for demonstration
    if input.len() > 1000 {
        return Err(ProcessingError::ProcessingFailure(
            "Message too long".to_string(),
        ));
    }

    let mut output = String::from("You said: ");
    output.push_str(input);
    Ok(output)
}

/// Safe wrapper for string conversion from C
fn safe_str_from_ptr(ptr: *const c_char) -> Result<&'static str, ProcessingError> {
    if ptr.is_null() {
        return Err(ProcessingError::NullPointer);
    }

    unsafe {
        CStr::from_ptr(ptr)
            .to_str()
            .map_err(ProcessingError::InvalidUtf8)
    }
}

/// Process an inbound chat message and return a response owned by Rust.
/// Callers must free the returned string with `lindos_string_free` once done.
///
/// # Safety
/// This function is safe to call from C/Swift as long as:
/// - The message pointer is either null or points to a valid null-terminated C string
/// - The returned pointer is freed exactly once using `lindos_string_free`
#[no_mangle]
pub extern "C" fn lindos_process_message(message: *const c_char) -> *mut c_char {
    let result = match safe_str_from_ptr(message) {
        Ok(input) => match generate_reply(input) {
            Ok(reply) => reply,
            Err(error) => {
                eprintln!("Processing error: {:?}", error);
                error.to_user_message().to_string()
            }
        },
        Err(error) => {
            eprintln!("Input conversion error: {:?}", error);
            error.to_user_message().to_string()
        }
    };

    rust_string_to_c(result)
}

/// Enhanced version that returns structured results with error information.
/// Callers must free both data and error_message with `lindos_string_free`.
///
/// # Safety
/// This function is safe to call from C/Swift as long as:
/// - The message pointer is either null or points to a valid null-terminated C string
/// - The returned RustResult's data pointer is freed exactly once using `lindos_string_free`
#[no_mangle]
pub extern "C" fn lindos_process_message_safe(message: *const c_char) -> RustResult {
    let input_result = safe_str_from_ptr(message);

    match input_result {
        Ok(input) => match generate_reply(input) {
            Ok(reply) => {
                println!("Successfully processed message: {} chars", input.len());
                RustResult::success(reply)
            }
            Err(error) => {
                eprintln!("Processing failed: {:?}", error);
                RustResult::error(error)
            }
        },
        Err(error) => {
            eprintln!("Input validation failed: {:?}", error);
            RustResult::error(error)
        }
    }
}

/// Check if a message would be valid without processing it
#[no_mangle]
pub extern "C" fn lindos_validate_message(message: *const c_char) -> i32 {
    match safe_str_from_ptr(message) {
        Ok(input) => {
            if input.len() > 1000 {
                4 // ProcessingFailure error code
            } else {
                0 // Success
            }
        }
        Err(error) => match error {
            ProcessingError::NullPointer => 1,
            ProcessingError::InvalidUtf8(_) => 2,
            ProcessingError::EmptyMessage => 3,
            ProcessingError::ProcessingFailure(_) => 4,
        },
    }
}

/// Get a human-readable error message for an error code
#[no_mangle]
pub extern "C" fn lindos_error_message(error_code: i32) -> *mut c_char {
    let message = match error_code {
        1 => "No message provided",
        2 => "Message contains invalid characters",
        3 => "Message cannot be empty",
        4 => "Failed to process message",
        _ => "Unknown error",
    };

    rust_string_to_c(message.to_string())
}

/// Frees strings that originated from this library.
///
/// # Safety
/// This function is safe to call as long as:
/// - The pointer was returned by a function from this library
/// - The pointer is freed exactly once
/// - The pointer is not used after being freed
#[no_mangle]
pub unsafe extern "C" fn lindos_string_free(ptr: *mut c_char) {
    if ptr.is_null() {
        eprintln!("Warning: Attempted to free null pointer");
        return;
    }

    let _ = CString::from_raw(ptr);
    // CString will be dropped here, freeing the memory
}

/// Free a RustResult structure and its associated memory
///
/// # Safety
/// This function is safe to call as long as:
/// - The result was returned by a function from this library
/// - The result is freed exactly once
#[no_mangle]
pub unsafe extern "C" fn lindos_result_free(result: RustResult) {
    if !result.data.is_null() {
        lindos_string_free(result.data);
    }
}

/// Enable or disable debug logging
static mut DEBUG_ENABLED: bool = false;

#[no_mangle]
pub extern "C" fn lindos_set_debug(enabled: bool) {
    unsafe {
        DEBUG_ENABLED = enabled;
    }
    println!(
        "Debug logging {}",
        if enabled { "enabled" } else { "disabled" }
    );
}

/// Internal logging function
#[allow(dead_code)]
fn debug_log(message: &str) {
    unsafe {
        if DEBUG_ENABLED {
            println!("[LINDOS DEBUG] {}", message);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CString;

    // Helper functions to make unsafe FFI calls safer and more convenient in tests
    fn free_string(ptr: *mut c_char) {
        unsafe { lindos_string_free(ptr) }
    }

    fn free_result(result: RustResult) {
        unsafe { lindos_result_free(result) }
    }

    #[test]
    fn test_generate_reply() {
        assert_eq!(generate_reply("hi").unwrap(), "You said: hi");
        assert_eq!(generate_reply("   ").unwrap(), "Hello from Rust core!");

        // Test error case
        let long_message = "a".repeat(1001);
        assert!(generate_reply(&long_message).is_err());
    }

    #[test]
    fn test_safe_str_from_ptr() {
        // Test null pointer
        assert!(matches!(
            safe_str_from_ptr(std::ptr::null()),
            Err(ProcessingError::NullPointer)
        ));

        // Test valid string
        let test_str = CString::new("test").unwrap();
        let result = safe_str_from_ptr(test_str.as_ptr());
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), "test");
    }

    #[test]
    fn test_process_message_safe() {
        // Test null input
        let result = lindos_process_message_safe(std::ptr::null());
        assert!(!result.success);
        assert_eq!(result.error_code, 1);

        // Clean up
        free_result(result);

        // Test valid input
        let test_str = CString::new("hello").unwrap();
        let result = lindos_process_message_safe(test_str.as_ptr());
        assert!(result.success);
        assert_eq!(result.error_code, 0);

        // Convert result back to string to verify
        let response = unsafe { CStr::from_ptr(result.data).to_str().unwrap() };
        assert_eq!(response, "You said: hello");

        // Clean up
        free_result(result);
    }

    #[test]
    fn test_validate_message() {
        // Test null pointer
        assert_eq!(lindos_validate_message(std::ptr::null()), 1);

        // Test valid message
        let test_str = CString::new("hello").unwrap();
        assert_eq!(lindos_validate_message(test_str.as_ptr()), 0);

        // Test too long message
        let long_str = CString::new("a".repeat(1001)).unwrap();
        assert_eq!(lindos_validate_message(long_str.as_ptr()), 4);
    }

    #[test]
    fn test_error_codes() {
        assert_eq!(
            ProcessingError::NullPointer.to_user_message(),
            "Error: No message provided"
        );
        assert_eq!(
            ProcessingError::EmptyMessage.to_user_message(),
            "Error: Message cannot be empty"
        );
    }

    #[test]
    fn test_memory_safety() {
        // Test that we can safely free null pointers
        free_string(std::ptr::null_mut());

        // Test normal string creation and freeing
        let test_str = CString::new("test").unwrap();
        let result = lindos_process_message(test_str.as_ptr());
        assert!(!result.is_null());

        // This should not crash
        free_string(result);
    }

    #[test]
    fn test_error_message_function() {
        // Test all error codes
        let msg1 = lindos_error_message(1);
        let response1 = unsafe { CStr::from_ptr(msg1).to_str().unwrap() };
        assert_eq!(response1, "No message provided");
        free_string(msg1);

        let msg2 = lindos_error_message(2);
        let response2 = unsafe { CStr::from_ptr(msg2).to_str().unwrap() };
        assert_eq!(response2, "Message contains invalid characters");
        free_string(msg2);

        let msg_unknown = lindos_error_message(999);
        let response_unknown = unsafe { CStr::from_ptr(msg_unknown).to_str().unwrap() };
        assert_eq!(response_unknown, "Unknown error");
        free_string(msg_unknown);
    }

    #[test]
    fn test_debug_logging() {
        // Test debug enable/disable
        lindos_set_debug(true);
        lindos_set_debug(false);
        // This test mainly ensures the function doesn't crash
    }

    #[test]
    fn test_edge_cases() {
        // Test empty string (not null, but empty)
        let empty_str = CString::new("").unwrap();
        let result = lindos_process_message_safe(empty_str.as_ptr());
        assert!(result.success);
        let response = unsafe { CStr::from_ptr(result.data).to_str().unwrap() };
        assert_eq!(response, "Hello from Rust core!");
        free_result(result);

        // Test whitespace-only string
        let whitespace_str = CString::new("   \n\t  ").unwrap();
        let result = lindos_process_message_safe(whitespace_str.as_ptr());
        assert!(result.success);
        let response = unsafe { CStr::from_ptr(result.data).to_str().unwrap() };
        assert_eq!(response, "Hello from Rust core!");
        free_result(result);

        // Test exactly at limit (1000 characters)
        let limit_str = CString::new("a".repeat(1000)).unwrap();
        let result = lindos_process_message_safe(limit_str.as_ptr());
        assert!(result.success);
        free_result(result);

        // Test just over limit (1001 characters)
        let over_limit_str = CString::new("a".repeat(1001)).unwrap();
        let result = lindos_process_message_safe(over_limit_str.as_ptr());
        assert!(!result.success);
        assert_eq!(result.error_code, 4);
        free_result(result);
    }

    #[test]
    fn test_unicode_handling() {
        // Test various Unicode characters
        let unicode_str = CString::new("Hello 🌍 世界 🚀").unwrap();
        let result = lindos_process_message_safe(unicode_str.as_ptr());
        assert!(result.success);
        let response = unsafe { CStr::from_ptr(result.data).to_str().unwrap() };
        assert!(response.contains("Hello 🌍 世界 🚀"));
        free_result(result);

        // Test emoji-heavy string
        let emoji_str = CString::new("🎉🎈🎊🎁🎀").unwrap();
        let result = lindos_process_message_safe(emoji_str.as_ptr());
        assert!(result.success);
        free_result(result);
    }

    #[test]
    fn test_concurrent_safety() {
        use std::thread;

        // Test multiple threads calling functions simultaneously
        let handles: Vec<_> = (0..10)
            .map(|i| {
                thread::spawn(move || {
                    let test_str = CString::new(format!("test message {}", i)).unwrap();
                    let result = lindos_process_message_safe(test_str.as_ptr());
                    assert!(result.success);
                    free_result(result);
                })
            })
            .collect();

        for handle in handles {
            handle.join().unwrap();
        }
    }

    #[test]
    fn test_legacy_compatibility() {
        // Test that legacy function still works
        let test_str = CString::new("legacy test").unwrap();
        let result = lindos_process_message(test_str.as_ptr());
        assert!(!result.is_null());

        let response = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(response, "You said: legacy test");

        free_string(result);
    }

    #[test]
    fn test_result_structure_integrity() {
        let test_str = CString::new("structure test").unwrap();
        let result = lindos_process_message_safe(test_str.as_ptr());

        // Verify all fields are properly set
        assert!(result.success);
        assert!(!result.data.is_null());
        assert_eq!(result.error_code, 0);

        free_result(result);

        // Test error case structure
        let result_error = lindos_process_message_safe(std::ptr::null());
        assert!(!result_error.success);
        assert!(!result_error.data.is_null()); // Should contain error message
        assert_eq!(result_error.error_code, 1);

        free_result(result_error);
    }
}
