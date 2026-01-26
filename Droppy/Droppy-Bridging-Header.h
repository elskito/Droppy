//
//  Droppy-Bridging-Header.h
//  Droppy
//
//  Bridging header for private CoreGraphics (CGS) APIs
//  Used for menu bar item discovery
//

#ifndef Droppy_Bridging_Header_h
#define Droppy_Bridging_Header_h

#include <CoreGraphics/CoreGraphics.h>

// CGS Connection types
typedef int CGSConnectionID;
typedef uint64_t CGSSpaceID;
typedef int CGSSpaceMask;

// Error type
typedef int32_t CGSError;

// Space masks
static const CGSSpaceMask kCGSSpaceAll = -1;
static const CGSSpaceMask kCGSSpaceAllVisible = 1;

// Connection functions
extern CGSConnectionID CGSMainConnectionID(void);

// Window functions
extern CGSError CGSGetScreenRectForWindow(CGSConnectionID cid, uint32_t wid, CGRect *outRect);
extern CGSError CGSGetWindowCount(CGSConnectionID cid, int pid, int32_t *outCount);
extern CGSError CGSGetWindowList(CGSConnectionID cid, int pid, int32_t capacity, uint32_t *list, int32_t *outCount);
extern CGSError CGSGetOnScreenWindowCount(CGSConnectionID cid, int pid, int32_t *outCount);
extern CGSError CGSGetOnScreenWindowList(CGSConnectionID cid, int pid, int32_t capacity, uint32_t *list, int32_t *outCount);

// Menu bar window functions
extern CGSError CGSGetProcessMenuBarWindowList(CGSConnectionID cid, int pid, int32_t capacity, uint32_t *list, int32_t *outCount);

// Space functions
extern CGSSpaceID CGSGetActiveSpace(CGSConnectionID cid);
extern CFArrayRef CGSCopySpacesForWindows(CGSConnectionID cid, CGSSpaceMask mask, CFArrayRef windows);

// Window properties
extern CGSError CGSSetWindowProperty(CGSConnectionID cid, uint32_t wid, CFStringRef key, CFTypeRef value);
extern CGSError CGSGetWindowProperty(CGSConnectionID cid, uint32_t wid, CFStringRef key, CFTypeRef *outValue);

// Connection properties
extern CGSError CGSSetConnectionProperty(CGSConnectionID cid, CGSConnectionID targetCid, CFStringRef key, CFTypeRef value);
extern CGSError CGSCopyConnectionProperty(CGSConnectionID cid, CGSConnectionID targetCid, CFStringRef key, CFTypeRef *outValue);

#endif /* Droppy_Bridging_Header_h */
