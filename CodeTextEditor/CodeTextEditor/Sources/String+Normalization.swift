/*
 
 String+Normalization.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2015-08-25.
 
 ------------------------------------------------------------------------------
 
 © 2015-2017 1024jp
 © 2015-2016 Yusuke Terada
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Foundation
import ICU

extension String {
    
    // MARK: Public Properties
    
    /// A string made by normalizing the receiver’s contents using the Unicode Normalization Form KC with Casefold.
    var precomposedStringWithCompatibilityMappingWithCasefold: String {
        
        var error = U_ZERO_ERROR
        let normalizer = unorm2_getInstance(nil, "nfkc_cf", UNORM2_COMPOSE, &error)
        
        guard u_success(error) else {
            debugPrint("unorm2_getInstance failed: ", u_errorName(error))
            return self
        }
        
        let source = Array(self.utf16)
        let sourceLength = Int32(source.count)
        var destination = [UChar](repeating: 0, count: Int(sourceLength))
        
        let destLength = unorm2_normalize(normalizer, source, sourceLength, &destination, sourceLength * 64, &error)
        
        guard u_success(error) else {
            debugPrint("unorm2_normalize failed: ", u_errorName(error))
            return self
        }
        
        return String(utf16CodeUnits: destination, count: Int(destLength))
    }
    
    
    /// A string made by normalizing the receiver’s contents using the normalization form adopted by HFS+, a.k.a. Apple Modified NFC.
    var precomposedStringWithHFSPlusMapping: String {
        
        var result = ""
        
        let exclusionCharacters = "\\x{0340}\\x{0341}\\x{0343}\\x{0344}\\x{0374}\\x{037E}\\x{0387}\\x{0958}-\\x{095F}\\x{09DC}\\x{09DD}\\x{09DF}\\x{0A33}\\x{0A36}\\x{0A59}-\\x{0A5B}\\x{0A5E}\\x{0B5C}\\x{0B5D}\\x{0F43}\\x{0F4D}\\x{0F52}\\x{0F57}\\x{0F5C}\\x{0F69}\\x{0F73}\\x{0F75}\\x{0F76}\\x{0F78}\\x{0F81}\\x{0F93}\\x{0F9D}\\x{0FA2}\\x{0FA7}\\x{0FAC}\\x{0FB9}\\x{1F71}\\x{1F73}\\x{1F75}\\x{1F77}\\x{1F79}\\x{1F7B}\\x{1F7D}\\x{1FBB}\\x{1FBE}\\x{1FC9}\\x{1FCB}\\x{1FD3}\\x{1FDB}\\x{1FE3}\\x{1FEB}\\x{1FEE}\\x{1FEF}\\x{1FF9}\\x{1FFB}\\x{1FFD}\\x{2000}\\x{2001}\\x{2126}\\x{212A}\\x{212B}\\x{2329}\\x{232A}\\x{2ADC}\\x{F900}-\\x{FA0D}\\x{FA10}\\x{FA12}\\x{FA15}-\\x{FA1E}\\x{FA20}\\x{FA22}\\x{FA25}\\x{FA26}\\x{FA2A}-\\x{FA6D}\\x{FA70}-\\x{FAD9}\\x{FB1D}\\x{FB1F}\\x{FB2A}-\\x{FB36}\\x{FB38}-\\x{FB3C}\\x{FB3E}\\x{FB40}\\x{FB41}\\x{FB43}\\x{FB44}\\x{FB46}-\\x{FB4E}\\x{1D15E}-\\x{1D164}\\x{1D1BB}-\\x{1D1C0}\\x{2F800}-\\x{2FA1D}"
        let pattern = "([" + exclusionCharacters + "]*)([^" + exclusionCharacters + "]+)([" + exclusionCharacters + "]*)"
        let regex = try! NSRegularExpression(pattern: pattern)
        let nsString = self as NSString
        
        regex.enumerateMatches(in: self, range: self.nsRange) { (match: NSTextCheckingResult?, flags, stop) in
            
            guard let match = match else { return }
            
            result += nsString.substring(with: match.range(at: 1))
            result += nsString.substring(with: match.range(at: 2)).precomposedStringWithCanonicalMapping
            result += nsString.substring(with: match.range(at: 3))
        }
        
        guard !result.isEmpty else { return self }
        
        return result
    }
    
    
    /// A string made by normalizing the receiver’s contents using the normalization form adopted by HFS+, a.k.a. Apple Modified NFD.
    var decomposedStringWithHFSPlusMapping: String {
        
        let source = self as CFString
        let length = CFStringGetMaximumSizeOfFileSystemRepresentation(source)
        var buffer = [CChar](repeating: 0, count: length)
        
        guard CFStringGetFileSystemRepresentation(source, &buffer, length) else { return self }
        
        return String(cString: buffer)
    }
    
}


// MARK: Private Functions

/// check succesion from UErrorCode
private func u_success(_ code: UErrorCode) -> Bool {
    
    return code.rawValue <= U_ZERO_ERROR.rawValue
}
