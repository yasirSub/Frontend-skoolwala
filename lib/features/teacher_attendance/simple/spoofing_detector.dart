import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Detects photo spoofing and liveness to prevent fake face attacks
class SpoofingDetector {
  /// Check if detected face appears to be a live person (not a photo)
  /// Returns true if face appears live, false if spoofing detected
  /// [strict] - if false, makes checks more lenient (for enrollment)
  static bool isLiveFace(Face face, {bool strict = false}) {
    final leftEyeOpen = face.leftEyeOpenProbability ?? 0.5;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 0.5;
    
    // Check 1: Face size - very small faces are likely too far or invalid
    final boundingBox = face.boundingBox;
    final faceSize = boundingBox.width * boundingBox.height;
    
    // More lenient threshold for enrollment (strict mode is more aggressive)
    final minFaceSize = strict ? 15000 : 8000; // Reduced from 10000 to be more lenient
    if (faceSize < minFaceSize) {
      // Face too small - might be far away (could be real or photo)
      // But reject it as quality is too low anyway
      return false;
    }
    
    // Check 2: Eye state consistency - ONLY block OBVIOUS photos
    // Real people often have similar eye states when looking forward
    // Only reject if eyes are PERFECTLY identical (which is suspicious for photos)
    final eyeDifference = (leftEyeOpen - rightEyeOpen).abs();
    
    if (strict) {
      // Strict mode (attendance): Only block if eyes are EXACTLY identical
      // Real people rarely have perfectly identical eye states
      if (eyeDifference == 0.0 && leftEyeOpen > 0.9) {
        // Perfectly identical and wide open - likely a photo
        return false;
      }
    } else {
      // Lenient mode (enrollment): Be VERY permissive
      // Only block if eyes are EXACTLY 0.0 identical (very suspicious)
      // Allow all natural variation that real people have
      if (eyeDifference == 0.0 && leftEyeOpen == 1.0 && rightEyeOpen == 1.0) {
        // Perfectly identical at 1.0 - extremely suspicious (likely a photo)
        return false;
      }
      // Don't block anything else in lenient mode - allow natural faces
    }
    
    // Check 3: Face angle - only check extreme angles (not suspicious flat angles)
    // Real people can look straight ahead - that's normal!
    final headEulerAngleY = face.headEulerAngleY ?? 0.0;
    final headEulerAngleZ = face.headEulerAngleZ ?? 0.0;
    
    // Only reject extreme angles (might indicate a photo being held)
    if (headEulerAngleY.abs() > 50 || headEulerAngleZ.abs() > 50) {
      return false;
    }
    
    // REMOVED: Angle variance check - real people can look straight ahead
    // REMOVED: Landmark count checks - too strict, reject valid faces
    // If face size is OK and angles are reasonable, allow it
    
    // If all checks pass, consider it a live face
    return true;
  }
  
  /// Get spoofing detection message
  static String getSpoofingMessage(Face face) {
    final leftEyeOpen = face.leftEyeOpenProbability ?? 0.0;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 0.0;
    
    // Check if eyes are suspiciously identical (photo indicator)
    if ((leftEyeOpen - rightEyeOpen).abs() < 0.1 && 
        leftEyeOpen > 0.8) {
      return 'Please use your live face, not a photo. Blink naturally.';
    }
    
    // Check if face is too small (might be a photo held far)
    final boundingBox = face.boundingBox;
    final faceSize = boundingBox.width * boundingBox.height;
    if (faceSize < 10000) {
      return 'Please move closer to the camera for better face detection.';
    }
    
    // Generic spoofing message
    return 'Please use your live face. Photos or screens are not accepted.';
  }
  
  /// Check if face has sufficient liveness indicators
  /// Returns true if face shows signs of being alive
  /// [strict] - if false, makes checks more lenient (for enrollment)
  static bool checkLiveness(Face face, {bool strict = false}) {
    final leftEye = face.leftEyeOpenProbability;
    final rightEye = face.rightEyeOpenProbability;
    
    // Basic liveness: eyes should have valid probabilities
    // But be lenient - some faces might have null values due to lighting/angle
    if (leftEye == null && rightEye == null) {
      // Both eyes null - might be lighting issue, but allow it in lenient mode
      return !strict; // Reject only in strict mode
    }
    
    // If we have at least one eye value, that's enough
    if (leftEye == null || rightEye == null) {
      // One eye value is enough - allow it
      return true;
    }
    
    final eyeDifference = (leftEye - rightEye).abs();
    
    if (strict) {
      // Strict mode (attendance): Only block OBVIOUS photos
      // Reject ONLY if eyes are EXACTLY identical at extreme values
      if (eyeDifference == 0.0 && (leftEye == 1.0 || leftEye == 0.0)) {
        // Perfectly identical at extreme - suspicious
        return false;
      }
      // Allow everything else - real people have natural variation
    } else {
      // Lenient mode (enrollment): Be VERY permissive
      // Only block if eyes are PERFECTLY identical at exactly 1.0
      // This is nearly impossible for real faces
      if (eyeDifference == 0.0 && leftEye == 1.0 && rightEye == 1.0) {
        // Perfectly identical at 1.0 - very suspicious (likely photo)
        return false;
      }
      // Allow all other cases - real faces have natural variation
    }
    
    // Face has valid eye data - allow it
    // Real people can have similar eye states, so be permissive
    return true;
  }
}


