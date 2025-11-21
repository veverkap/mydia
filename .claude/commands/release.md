---
allowed-tools: Bash(git*,gh*), Read, Edit
argument-hint: [major|minor|patch|beta|rc (optional - auto-detected)]
description: Create and publish a new release with version bump and release notes
---

# Release Process

Create a new release by:

1. **Analyze changes since last release**

   - Get the latest tag using `git describe --tags --abbrev=0` or `git tag --sort=-version:refname | head -n1`
   - Use `git log <last-tag>..HEAD --oneline` to see all commits since last release
   - Look at the git diff and commit messages to understand the nature of changes

2. **Determine version increment** (unless specified as $1)

   - **PREFER patch (0.0.X)** for bugfixes, small improvements, or unclear changes
   - Use **minor (0.X.0)** ONLY for significant new features or major functionality additions
   - Use **major (X.0.0)** ONLY if explicitly instructed with `$ARGUMENTS` containing "major"
   - Use **beta** to create a pre-release version with `-beta.N` suffix (e.g., v1.2.3-beta.1)
   - Use **rc** to create a release candidate with `-rc.N` suffix (e.g., v1.2.3-rc.1)
   - Current version is in mix.exs on line 7
   - Parse current version, increment appropriately

3. **Categorize changes** for release notes:

   - 🎉 **New Features** - Significant new functionality
   - 🐛 **Bug Fixes** - Fixes for bugs or issues
   - 🔧 **Technical Changes** - Refactoring, dependencies, configuration
   - 🚀 **Deployment Notes** - Important deployment-related changes (migrations, config changes)
   - Skip empty sections

4. **Update version in mix.exs**

   - Read the file, update line 7: `version: "X.Y.Z",` (or `version: "X.Y.Z-beta.N",` for pre-releases)
   - Use the Edit tool to make the change
   - **For beta/rc releases**: Do NOT update mix.exs, keep the base version

5. **Create release commit and tag**

   - **For stable releases**:
     - Stage mix.exs: `git add mix.exs`
     - Commit: `git commit -m "chore: bump version to vX.Y.Z"`
     - Tag: `git tag -a vX.Y.Z -m "Release vX.Y.Z"`
     - Push: `git push && git push --tags`
   - **For beta/rc releases**:
     - DO NOT commit or update mix.exs
     - Tag: `git tag -a vX.Y.Z-beta.N -m "Release vX.Y.Z-beta.N"`
     - Push: `git push --tags`

6. **Create GitHub release with gh CLI**
   - Generate release notes with sections identified above
   - Keep it concise - short bullet points (one line each)
   - Add link to full changelog: `**Full Changelog**: https://github.com/OWNER/REPO/compare/vOLD...vNEW`
   - **For stable releases**: `gh release create vX.Y.Z --title "vX.Y.Z" --notes "..."`
   - **For beta/rc releases**: `gh release create vX.Y.Z-beta.N --title "vX.Y.Z-beta.N" --notes "..." --prerelease`

## Important Notes

- Always verify you're on the correct branch (usually main/master)
- Ensure working directory is clean before starting (except for beta/rc releases)
- If $1 is provided (major/minor/patch/beta/rc), use that instead of auto-detection
- Be conservative: when in doubt, use patch version
- **Beta/RC releases**: These are for testing unreleased versions without affecting stable production
  - Docker images are tagged with 'beta' (not 'latest')
  - Mix.exs version is NOT updated (keeps base version)
  - No commit is made, only a Git tag
  - GitHub release is marked as pre-release
  - To create beta.N, find existing beta tags and increment N (e.g., if v1.2.3-beta.1 exists, create v1.2.3-beta.2)
