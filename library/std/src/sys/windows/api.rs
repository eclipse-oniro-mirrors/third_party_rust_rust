/// Creates a UTF-16 string from a str without null termination.
pub macro utf16($str:expr) {{
    const UTF8: &str = $str;
    const UTF16_LEN: usize = crate::sys::windows::api::utf16_len(UTF8);
    const UTF16: [u16; UTF16_LEN] = crate::sys::windows::api::to_utf16(UTF8);
    &UTF16
}}

/// Gets the UTF-16 length of a UTF-8 string, for use in the wide_str macro.
pub const fn utf16_len(s: &str) -> usize {
    let s = s.as_bytes();
    let mut i = 0;
    let mut len = 0;
    while i < s.len() {
        // the length of a UTF-8 encoded code-point is given by the number of
        // leading ones, except in the case of ASCII.
        let utf8_len = match s[i].leading_ones() {
            0 => 1,
            n => n as usize,
        };
        i += utf8_len;
        // Note that UTF-16 surrogates (U+D800 to U+DFFF) are not encodable as UTF-8,
        // so (unlike with WTF-8) we don't have to worry about how they'll get re-encoded.
        len += if utf8_len < 4 { 1 } else { 2 };
    }
    len
}

/// Const convert UTF-8 to UTF-16, for use in the wide_str macro.
///
/// Note that this is designed for use in const contexts so is not optimized.
pub const fn to_utf16<const UTF16_LEN: usize>(s: &str) -> [u16; UTF16_LEN] {
    let mut output = [0_u16; UTF16_LEN];
    let mut pos = 0;
    let s = s.as_bytes();
    let mut i = 0;
    while i < s.len() {
        match s[i].leading_ones() {
            // Decode UTF-8 based on its length.
            // See https://en.wikipedia.org/wiki/UTF-8
            0 => {
                // ASCII is the same in both encodings
                output[pos] = s[i] as u16;
                i += 1;
                pos += 1;
            }
            2 => {
                // Bits: 110xxxxx 10xxxxxx
                output[pos] = ((s[i] as u16 & 0b11111) << 6) | (s[i + 1] as u16 & 0b111111);
                i += 2;
                pos += 1;
            }
            3 => {
                // Bits: 1110xxxx 10xxxxxx 10xxxxxx
                output[pos] = ((s[i] as u16 & 0b1111) << 12)
                    | ((s[i + 1] as u16 & 0b111111) << 6)
                    | (s[i + 2] as u16 & 0b111111);
                i += 3;
                pos += 1;
            }
            4 => {
                // Bits: 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
                let mut c = ((s[i] as u32 & 0b111) << 18)
                    | ((s[i + 1] as u32 & 0b111111) << 12)
                    | ((s[i + 2] as u32 & 0b111111) << 6)
                    | (s[i + 3] as u32 & 0b111111);
                // re-encode as UTF-16 (see https://en.wikipedia.org/wiki/UTF-16)
                // - Subtract 0x10000 from the code point
                // - For the high surrogate, shift right by 10 then add 0xD800
                // - For the low surrogate, take the low 10 bits then add 0xDC00
                c -= 0x10000;
                output[pos] = ((c >> 10) + 0xD800) as u16;
                output[pos + 1] = ((c & 0b1111111111) + 0xDC00) as u16;
                i += 4;
                pos += 2;
            }
            // valid UTF-8 cannot have any other values
            _ => unreachable!(),
        }
    }
    output
}
