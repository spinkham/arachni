
# ChangeLog

## Version 0.2

- Improved output.
  - Increased context awareness.
  - Extensive debugging output capabilities.
  - Added simple stats at the end of scans.
- Rewritten HTTP interface.
  - High-performance asynchronous HTTP requests.
  - Adjustable HTTP request concurrency limit.
  - Adjustable HTTP response harvests.
  - Custom 404 page detection.
- Optimized Trainer subsystem.
  - Invoked when it is most likely to detect new vectors.
  - Can be invoked by individual modules on-demand,
      forcing Arachni to learn from the HTTP responses they will cause -- a great asset to Fuzzers.
- Refactored and improved Auditor.
  - No redundant requests, except when required by modules.
  - Better parameter handling.
  - Speed optimizations.
  - Added differential analysis to determine whether a vulnerability needs manual verification.
- Refactored and improved module API.
  - Major API clean up.
  - With facilities providing more control and power over the audit process.
  - Significantly increased ease of development.
  - Modules have total flexibility and control over input combinations,
      injection values and their formating -- if they need to.
  - Modules can opt for sync or async HTTP requests (Default: async)
- Improved interrupt handling
  - Scans can be paused/resumed at any time.
  - In the event of a system exit or user cancellation reports will still be created
      using whatever data were gathered during runtime.
  - When the scan is paused the user will be presented with the results gathered thus far.
- Improved configuration profile handling
  - Added pre-configured profiles
  - Multiple profiles can be loaded at once
  - Ability to show running profiles as CLI arguments
- Overall module improvements and optimizations.
- New modules for:
  - Blind SQL Injection, using reverse-diff analysis.
  - Trainer, probes all inputs of a given page, in order to uncover new input vectors, and forces Arachni to learn from the responses.
  - Unvalidated redirects.
  - Forms that transmit passwords in clear text.
  - CSRF, implementing 4-pass rDiff analysis to drastically reduce noise.
- Overall report improvements and optimizations.
- New reports
  - Plain text report
  - XML report
