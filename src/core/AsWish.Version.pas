{ ============================================================================
  AsWish.Version
  ---------------------------------------------------------------------------
  Single source of truth for AsWish application versioning.
  Both Desktop GUI and Headless CLI derive their version constants from here.
  ============================================================================ }

unit AsWish.Version;

interface

const
  ASWISH_VERSION = '0.1.0';
  ASWISH_NAME = 'AsWish';
  ASWISH_BANNER = 'AsWish v' + ASWISH_VERSION;

implementation

end.
