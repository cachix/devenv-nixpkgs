<!-- TEST_RESULTS_START -->
**Status**: {{STATUS}}

**Nixpkgs revision**: [`{{NIXPKGS_SHORT}}`](https://github.com/NixOS/nixpkgs/commit/{{NIXPKGS_COMMIT}})

**Test run**: [View detailed results]({{RUN_URL}})

**Last updated**: {{TIMESTAMP}}

### Platform Results

| Platform | Tests Failed/Total | Success Rate |
|----------|-------------------|--------------|
| aarch64-linux | {{AARCH64_LINUX_COUNT}} | {{AARCH64_LINUX_SUCCESS_RATE}}% |
| x86_64-linux | {{X86_64_LINUX_COUNT}} | {{X86_64_LINUX_SUCCESS_RATE}}% |
| aarch64-darwin | {{AARCH64_DARWIN_COUNT}} | {{AARCH64_DARWIN_SUCCESS_RATE}}% |
| x86_64-darwin | {{X86_64_DARWIN_COUNT}} | {{X86_64_DARWIN_SUCCESS_RATE}}% |

### Summary

- **Total test jobs**: {{TOTAL_JOBS}}
- **Successful**: {{SUCCESSFUL_JOBS}} ✅
- **Failed**: {{FAILED_JOBS}} ❌
- **Success rate**: {{SUCCESS_RATE}}%

<!-- TEST_RESULTS_END -->

