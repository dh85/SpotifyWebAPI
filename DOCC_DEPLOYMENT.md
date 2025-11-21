# DocC Documentation Deployment Guide

This guide explains how to deploy the SpotifyWebAPI documentation to GitHub Pages.

## What's Included

The documentation bundle includes:
- ✅ Main documentation catalog (`SpotifyWebAPI.docc`)
- ✅ Getting Started guide
- ✅ Authentication guide
- ✅ Pagination guide
- ✅ Automatic API reference generation
- ✅ GitHub Actions workflow for deployment

## Local Preview

Generate and preview documentation locally:

```bash
# Build the package
swift build

# Generate documentation
mkdir -p docs
xcrun docc convert Sources/SpotifyWebAPI/SpotifyWebAPI.docc \
  --fallback-display-name SpotifyWebAPI \
  --fallback-bundle-identifier com.spotify.webapi \
  --fallback-bundle-version 1.0.0 \
  --output-path docs \
  --transform-for-static-hosting \
  --hosting-base-path SpotifyWebAPI

# Preview locally (requires Python)
cd docs && python3 -m http.server 8000
# Open http://localhost:8000/documentation/spotifywebapi/
```

## GitHub Pages Deployment

### Step 1: Enable GitHub Pages

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Pages**
3. Under **Source**, select **GitHub Actions**

### Step 2: Push Your Code

The documentation will automatically build and deploy when you push to the `main` branch:

```bash
git add .
git commit -m "Add DocC documentation"
git push origin main
```

### Step 3: Access Documentation

After the workflow completes (2-3 minutes), your documentation will be available at:

```
https://yourusername.github.io/SpotifyWebAPI/documentation/spotifywebapi/
```

## Manual Deployment

If you prefer manual deployment:

```bash
# Generate documentation
swift build
mkdir -p docs
xcrun docc convert Sources/SpotifyWebAPI/SpotifyWebAPI.docc \
  --fallback-display-name SpotifyWebAPI \
  --fallback-bundle-identifier com.spotify.webapi \
  --fallback-bundle-version 1.0.0 \
  --output-path docs \
  --transform-for-static-hosting \
  --hosting-base-path SpotifyWebAPI

# Commit and push docs folder
git add docs
git commit -m "Update documentation"
git push origin main
```

Then configure GitHub Pages to serve from the `docs` folder on the `main` branch.

## Documentation Structure

```
Sources/SpotifyWebAPI/SpotifyWebAPI.docc/
├── SpotifyWebAPI.md          # Main landing page
├── GettingStarted.md          # Quick start guide
├── Authentication.md          # Auth flows guide
├── Pagination.md              # Pagination patterns
└── Resources/                 # Images and assets (optional)
```

## Customization

### Add More Guides

Create new `.md` files in the `.docc` folder:

```markdown
# My Guide

Content here...

## Topics

- ``RelatedType``
```

Then reference them in `SpotifyWebAPI.md`:

```markdown
### Guides

- <doc:MyGuide>
```

### Add Images

Place images in `Resources/` folder and reference them:

```markdown
![Description](image-name.png)
```

### Organize API Reference

Group related types in topics:

```markdown
### Playback

- ``PlayerService``
- ``PlaybackState``
- ``SpotifyDevice``
```

## Troubleshooting

### Documentation Not Building

Check the Actions tab for build errors:
- Ensure all symbol references use correct names
- Verify `.docc` folder structure
- Check for syntax errors in markdown files

### 404 on GitHub Pages

- Verify GitHub Pages is enabled in repository settings
- Check the workflow completed successfully
- Ensure the base path matches your repository name
- Wait a few minutes for DNS propagation

### Missing Symbols

If you see warnings about missing symbols:
- Use exact type names (case-sensitive)
- Ensure types are `public`
- Check for typos in symbol references

## Workflow Details

The GitHub Actions workflow:
1. Checks out the repository
2. Builds the Swift package
3. Generates DocC documentation
4. Transforms for static hosting
5. Uploads to GitHub Pages
6. Deploys automatically

Runs on:
- Every push to `main` branch
- Manual trigger via Actions tab

## Next Steps

After deployment:
1. ✅ Add documentation link to README
2. ✅ Share with users
3. ✅ Keep documentation updated with code changes
4. ✅ Add more guides as needed

## Resources

- [DocC Documentation](https://www.swift.org/documentation/docc/)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [Swift-DocC Plugin](https://github.com/apple/swift-docc-plugin)

---

**Status**: Ready for deployment 🚀  
**Estimated Build Time**: 2-3 minutes  
**Documentation URL**: `https://yourusername.github.io/SpotifyWebAPI/documentation/spotifywebapi/`
