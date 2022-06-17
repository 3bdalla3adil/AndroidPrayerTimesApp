package com.example.target;

import com.example.target.internal.ShadowLength;

/**
 * Madhab for determining how Asr is calculated
 */
public enum Madhab {
  /**
   * Shafi Madhab
   */
  SHAFI,

  /**
   * Hanafi Madhab
   */
  HANAFI;

  ShadowLength getShadowLength() {
    switch (this) {
      case SHAFI: {
        return ShadowLength.SINGLE;
      }
      case HANAFI: {
        return ShadowLength.DOUBLE;
      }
      default: {
        throw new IllegalArgumentException("Invalid Madhab");
      }
    }
  }
}
