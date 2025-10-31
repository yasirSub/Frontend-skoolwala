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
    final minFaceSize = strict ? 15000 : 8000;
    if (faceSize < minFaceSize) {
      // Face too small - might be far away or a photo
      return false;
    }
    
    // Check 2: Eye state consistency (only check if strict mode)
    // During enrollment, allow similar eye states as people naturally have both eyes open
    if (strict) {
      // Only check for suspiciously perfect identical states (very unlikely in real faces)
      final eyeDifference = (leftEyeOpen - rightEyeOpen).abs();
      
      // Only reject if eyes are EXACTLY identical (0.0 difference) and both wide open
      // This is extremely unlikely in real faces due to natural asymmetry
      if (eyeDifference == 0.0 && leftEyeOpen > 0.95 && rightEyeOpen > 0.95) {
        // Suspiciously perfect - likely a photo
        return false;
      }
      
      // Also check for both eyes perfectly closed (unlikely natural state)
      if (eyeDifference == 0.0 && leftEyeOpen < 0.05 && rightEyeOpen < 0.05) {
        return false;
      }
    }
    
    // Check 3: Face angle - only check extreme angles
    final headEulerAngleY = face.headEulerAngleY ?? 0.0;
    final headEulerAngleZ = face.headEulerAngleZ ?? 0.0;
    
    // Only reject if face is at extreme angle (likely a photo being held)
    // Allow reasonable angles during enrollment (people turn their heads)
    if (strict && (headEulerAngleY.abs() > 45 || headEulerAngleZ.abs() > 45)) {
      return false;
    }
    
    // If all checks pass, consider it a live face
    // Default to allowing the face (be lenient)
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
    if (leftEye == null || rightEye == null) {
      // During enrollment, be more lenient - allow if data is available
      // Only reject if we truly can't determine anything
      return !strict; // Allow in lenient mode, reject in strict mode
    }
    
    // In lenient mode (enrollment), accept any valid eye probabilities
    // People naturally have similar eye states when both eyes are open
    if (!strict) {
      return true; // Be lenient during enrollment
    }
    
    // In strict mode (attendance), check for suspiciously perfect states
    final eyeDifference = (leftEye - rightEye).abs();
    
    // Only reject if eyes are EXACTLY identical (0.0) and wide open
    // This is extremely rare in real faces
    if (eyeDifference == 0.0 && leftEye > 0.95 && rightEye > 0.95) {
      // Suspiciously perfect - likely a photo
      return false;
    }
    
    // Face has valid eye data - likely live
    return true;
  }
}

