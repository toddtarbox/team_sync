# TappableImage Component

A reusable Flutter widget that wraps images and makes them tappable to show a full-screen, zoomable view.

## Features

✅ **Tap to View Full Screen**: Any image can be tapped to show in full-screen photo viewer  
✅ **Pinch to Zoom**: Full-screen view supports pinch-to-zoom gestures  
✅ **Hero Animations**: Smooth transitions with optional Hero tags  
✅ **Loading States**: Shows progress indicator while loading  
✅ **Error Handling**: Displays error widget when image fails to load  
✅ **Flexible**: Supports network images, assets, and custom ImageProviders  
✅ **Customizable**: Border radius, size, fit, placeholders  
✅ **Close Button**: Easy-to-access close button in full-screen view  

## Usage

### Basic Network Image

```dart
TappableImage.network(
  imageUrl: 'https://example.com/image.jpg',
  width: 100,
  height: 100,
  fit: BoxFit.cover,
)
```

### With Border Radius

```dart
TappableImage.network(
  imageUrl: 'https://example.com/image.jpg',
  width: 200,
  height: 150,
  fit: BoxFit.cover,
  borderRadius: BorderRadius.circular(12),
)
```

### With Hero Animation

```dart
TappableImage.network(
  imageUrl: 'https://example.com/image.jpg',
  width: 100,
  height: 100,
  heroTag: 'unique_hero_tag',
)
```

### Asset Image

```dart
TappableImage.asset(
  assetPath: 'assets/images/logo.png',
  width: 80,
  height: 80,
)
```

### Custom ImageProvider

```dart
TappableImage(
  imageProvider: FileImage(File('/path/to/image.jpg')),
  width: 150,
  height: 150,
  fit: BoxFit.cover,
)
```

### With Custom Error Widget

```dart
TappableImage.network(
  imageUrl: 'https://example.com/image.jpg',
  width: 100,
  height: 100,
  errorWidget: Container(
    color: Colors.red,
    child: Icon(Icons.error),
  ),
)
```

## Image Gallery

For displaying multiple images horizontally:

```dart
TappableImageGallery(
  imageUrls: [
    'https://example.com/image1.jpg',
    'https://example.com/image2.jpg',
    'https://example.com/image3.jpg',
  ],
  imageHeight: 120,
  imageWidth: 120,
  borderRadius: BorderRadius.circular(8),
)
```

## Parameters

### TappableImage

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `imageProvider` | `ImageProvider` | The image to display | Required |
| `width` | `double?` | Width of the image | null (flexible) |
| `height` | `double?` | Height of the image | null (flexible) |
| `fit` | `BoxFit?` | How to fit the image | `BoxFit.cover` |
| `borderRadius` | `BorderRadius?` | Border radius for rounded corners | null |
| `placeholder` | `Widget?` | Widget to show while loading | CircularProgressIndicator |
| `errorWidget` | `Widget?` | Widget to show on error | Broken image icon |
| `heroTag` | `String?` | Tag for Hero animation | null |

### TappableImageGallery

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `imageUrls` | `List<String>` | List of image URLs | Required |
| `imageHeight` | `double` | Height of each image | 120 |
| `imageWidth` | `double` | Width of each image | 120 |
| `fit` | `BoxFit` | How to fit the images | `BoxFit.cover` |
| `borderRadius` | `BorderRadius?` | Border radius for images | null |

## Full-Screen View Features

When an image is tapped, it opens a full-screen view with:

- **Pinch to Zoom**: Use two fingers to zoom in/out
- **Pan to Navigate**: Drag to move around zoomed images
- **Dark Background**: Black semi-transparent background for focus
- **Close Button**: White close button in top-right corner
- **Hero Animation**: Smooth transition if heroTag is provided
- **Min/Max Scale**: Constrained zoom levels for best UX

## Examples

### Accomplishment Images

```dart
// Single image
TappableImage.network(
  imageUrl: accomplishment.imageUrl,
  fit: BoxFit.cover,
  borderRadius: BorderRadius.circular(12),
  heroTag: 'accomplishment_image',
  errorWidget: Container(
    height: 200,
    color: Colors.grey,
    child: Icon(Icons.emoji_events, size: 64),
  ),
)

// Multiple images in carousel
CarouselSlider(
  items: accomplishment.imageUrls.asMap().entries.map((entry) {
    return TappableImage.network(
      imageUrl: entry.value,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(12),
      heroTag: 'accomplishment_image_${entry.key}',
    );
  }).toList(),
)
```

### Player Avatar

```dart
CircleAvatar(
  radius: 30,
  child: ClipOval(
    child: TappableImage.network(
      imageUrl: player.profileImage,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      heroTag: 'player_${player.id}',
    ),
  ),
)
```

### Team Logo

```dart
TappableImage.network(
  imageUrl: team.logoUrl,
  width: 80,
  height: 80,
  borderRadius: BorderRadius.circular(40),
  heroTag: 'team_logo_${team.id}',
)
```

## Benefits

1. **Consistent UX**: All images in the app have the same tap-to-view behavior
2. **Better User Experience**: Users expect to be able to view images larger
3. **Less Code**: No need to write custom full-screen logic for each image
4. **Accessibility**: Large images easier to see for users with vision issues
5. **Professional**: Matches behavior of popular apps like Photos, Instagram, etc.

## Migration Guide

### Before (Old Code)

```dart
Image.network(
  imageUrl,
  width: 100,
  height: 100,
  fit: BoxFit.cover,
)
```

### After (New Code)

```dart
TappableImage.network(
  imageUrl: imageUrl,
  width: 100,
  height: 100,
  fit: BoxFit.cover,
)
```

Just wrap your existing images with `TappableImage` and they become tappable!

## Future Enhancements

Potential improvements:

- [ ] Swipe between images in gallery view
- [ ] Download image button
- [ ] Share image button
- [ ] Image metadata display (date, location, etc.)
- [ ] Double-tap to zoom
- [ ] Rotation support
- [ ] Image filters/editing

## Notes

- Requires `photo_view` package (already included in project)
- Works on iOS, Android, and Web
- Supports all image types (network, asset, file, memory)
- Gracefully handles errors and loading states
- Optimized for performance with proper image caching

