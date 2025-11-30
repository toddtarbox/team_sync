# Player Self-Editing Feature

## Overview

Players can now edit their own profiles on the web platform using a 4-digit PIN for authentication. This feature allows players to manage their profile picture, action photo, video highlights, and awards/recognitions without requiring coach intervention.

## Features

### For Coaches

1. **Set Player PINs**
   - When creating or editing a player in the Players page, coaches can set a 4-digit PIN
   - The PIN field is optional - leave it blank if you don't want the player to have self-editing access
   - PINs should be shared privately with the respective player

2. **What Players Can Edit**
   - Profile picture (headshot photo)
   - Action photo (for player cards)
   - Video highlights (add, edit, delete)
   - Awards/recognitions (add, edit, delete with optional images)

### For Players (Web Only)

1. **Accessing Edit Mode**
   - Navigate to your player profile page
   - Click the edit icon (pencil) in the top-right corner
   - Enter your 4-digit PIN when prompted
   - Click "Unlock" to enter edit mode

2. **Editing Profile Pictures**
   - Click "Upload Image" or "Change Image" to select a new photo
   - Photos are automatically uploaded to Firebase Storage
   - Click "Remove Image" to delete the current photo

3. **Managing Highlights**
   - Click the "+" button in the Highlights section
   - Enter:
     - Title (required) - e.g., "Game-Winning Goal"
     - Description (optional)
     - Video URL (required) - YouTube, Vimeo, or other video links
     - Date
   - Edit or delete existing highlights using the icons

4. **Managing Awards**
   - Click the "+" button in the Awards section
   - Enter:
     - Award Title (required) - e.g., "MVP", "All-Star", "Top Scorer"
     - Description (optional)
     - Date
     - Award Image (optional) - Upload a photo of the trophy/certificate
   - Edit or delete existing awards using the icons

5. **Exiting Edit Mode**
   - Click "Exit Edit Mode" button to return to normal view
   - All changes are saved automatically

## Technical Implementation

### New Models

1. **PlayerAward** (`lib/models/player_award.dart`)
   - Stores player awards and recognitions
   - Fields: id, playerId, title, description, date, imageUrl

2. **Player Model Updates** (`lib/models/player.dart`)
   - Added `editPin` field for authentication
   - Added `toMap()` and `save()` methods

### New Widgets

1. **PinEntryDialog** (`lib/widgets/pin_entry_dialog.dart`)
   - Prompts for 4-digit PIN entry
   - Validates PIN against player's stored PIN
   - Shows error message if no PIN is set

2. **PlayerProfileEditor** (`lib/widgets/player_profile_editor.dart`)
   - Comprehensive editing interface
   - Image upload with preview
   - Highlight management with video URL support
   - Award management with image upload
   - Automatic saving to Firebase

### Updated Widgets

1. **PlayerProfilePage** (`lib/widgets/player_profile_page.dart`)
   - Added edit button (web only)
   - Integrated PIN authentication
   - Toggles between view and edit modes
   - Displays awards in profile view

2. **PlayersPage** (`lib/widgets/players_page.dart`)
   - Added PIN field to create/edit player dialogs
   - Saves PIN to database

### Database Schema

#### Players Table
```json
{
  "id": "number",
  "teamId": "number",
  "seasonId": "number",
  "firstName": "string",
  "lastName": "string",
  "number": "number",
  "profileImage": "string (URL)",
  "actionPhoto": "string (URL)",
  "editPin": "string (4 digits, optional)"
}
```

#### PlayerAwards Table
```json
{
  "id": "number",
  "playerId": "number",
  "title": "string",
  "description": "string (optional)",
  "date": "ISO 8601 date string",
  "imageUrl": "string (URL, optional)"
}
```

#### PlayerHighlights Table (Existing)
```json
{
  "id": "number",
  "playerId": "number",
  "title": "string",
  "description": "string (optional)",
  "videoUrl": "string",
  "date": "ISO 8601 date string"
}
```

## Security Considerations

1. **PIN Storage**
   - PINs are stored as plain text in the database
   - This is acceptable for this use case as they're meant to be simple access codes, not high-security passwords
   - PINs should be kept private and only shared with the intended player

2. **Web-Only Feature**
   - Edit mode is only available on web platform
   - Mobile apps continue to use coach-controlled editing

3. **Firebase Storage**
   - All images are uploaded to Firebase Storage
   - Old images are automatically deleted when replaced
   - Storage rules should be configured to allow authenticated uploads

## Localization

The feature is fully localized with English and Spanish translations:

- Edit Profile / Editar perfil
- Enter PIN to Edit Profile / Ingrese PIN para editar perfil
- Awards / Premios
- Upload Image / Subir imagen
- And many more...

## Future Enhancements

Possible improvements for future versions:

1. PIN recovery mechanism
2. Email notifications when profile is edited
3. Audit log of profile changes
4. More granular permissions (e.g., only highlights, not photos)
5. Two-factor authentication option
6. Player profile completeness indicator
7. Social media links
8. Custom profile sections

## Troubleshooting

### "No PIN has been set for this player"
- Contact your coach to set up a PIN in the Players management page

### Images not uploading
- Check internet connection
- Ensure Firebase Storage rules allow uploads
- Try a smaller image file
- Check browser console for errors

### PIN not working
- Ensure you're entering the correct 4-digit PIN
- PIN is case-sensitive (numbers only)
- Contact your coach if you've forgotten your PIN

### Changes not saving
- Check internet connection
- Ensure you have permission to edit
- Try refreshing the page and re-entering edit mode
- Check browser console for errors

