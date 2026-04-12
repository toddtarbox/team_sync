#!/bin/bash
# Deploy mobile builds to TestFlight (iOS) and Google Play Internal Test Track (Android)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${BLUE}🚀 TeamSync Mobile Deployment${NC}"
echo "================================================"

# Determine what to deploy (default to both)
DEPLOY_TARGET=${1:-"all"}
FLAVOR=${2:-"soccer"}

# Function to deploy to TestFlight
deploy_testflight() {
  echo -e "${BLUE}📱 Deploying to TestFlight...${NC}"

  # Check if IPA exists
  IPA_PATH="$PROJECT_ROOT/build/ios/ipa/team_sync.ipa"
  if [ ! -f "$IPA_PATH" ]; then
    echo -e "${RED}❌ Error: IPA file not found at $IPA_PATH${NC}"
    echo "   Run a build first with: ./scripts/build.sh ios $FLAVOR"
    return 1
  fi

  # Use xcrun altool to upload to TestFlight
  # Note: Requires App Store Connect credentials
  # You can use app-specific password stored in keychain or pass via environment variables

  echo -e "${YELLOW}ℹ️  Uploading IPA to TestFlight...${NC}"
  echo "   This may take several minutes..."

  # Option 1: Using xcrun altool (deprecated but still works)
  # Note: You'll need to set these environment variables:
  # - APPLE_ID: Your Apple ID email
  # - APPLE_APP_SPECIFIC_PASSWORD: App-specific password from appleid.apple.com

  if [ -z "$APPLE_ID" ] || [ -z "$APPLE_APP_SPECIFIC_PASSWORD" ]; then
    echo -e "${YELLOW}⚠️  Apple credentials not found in environment${NC}"
    echo "   Set APPLE_ID and APPLE_APP_SPECIFIC_PASSWORD environment variables"
    echo "   Or use: export APPLE_ID='your@email.com'"
    echo "          export APPLE_APP_SPECIFIC_PASSWORD='xxxx-xxxx-xxxx-xxxx'"
    echo ""
    read -p "$(echo -e ${YELLOW}Enter Apple ID email: ${NC})" APPLE_ID
    read -p "$(echo -e ${YELLOW}Enter app-specific password: ${NC})" -s APPLE_APP_SPECIFIC_PASSWORD
    echo ""
  fi

  # Upload using xcrun altool
  if xcrun altool --upload-app \
    --type ios \
    --file "$IPA_PATH" \
    --username "$APPLE_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" \
    --verbose; then
    echo -e "${GREEN}✅ Successfully uploaded to TestFlight${NC}"
    echo "   Build will be available for testing once it's processed by Apple"
    echo "   Check status at: https://appstoreconnect.apple.com"
    return 0
  else
    echo -e "${RED}❌ TestFlight upload failed${NC}"
    return 1
  fi
}

# Function to deploy to Google Play Internal Test Track
deploy_google_play() {
  echo -e "${BLUE}🤖 Deploying to Google Play Internal Test Track...${NC}"

  # Check if AAB exists
  AAB_PATH="$PROJECT_ROOT/build/app/outputs/bundle/${FLAVOR}Release/app-${FLAVOR}-release.aab"
  if [ ! -f "$AAB_PATH" ]; then
    echo -e "${RED}❌ Error: AAB file not found at $AAB_PATH${NC}"
    echo "   Run a build first with: ./scripts/build.sh android $FLAVOR"
    return 1
  fi

  # Check if service account JSON exists
  SERVICE_ACCOUNT_JSON="${GOOGLE_PLAY_SERVICE_ACCOUNT_JSON:-$PROJECT_ROOT/android/play-service-account.json}"

  if [ ! -f "$SERVICE_ACCOUNT_JSON" ]; then
    echo -e "${YELLOW}⚠️  Google Play service account JSON not found${NC}"
    echo "   Expected location: $SERVICE_ACCOUNT_JSON"
    echo ""
    echo "   To set up automated deployment:"
    echo "   1. Go to Google Cloud Console"
    echo "   2. Create a service account (no specific IAM role needed in GCP)"
    echo "   3. Download the JSON key"
    echo "   4. Go to Google Play Console → Settings (gear icon) → API access"
    echo "   5. Link your Google Cloud project"
    echo "   6. Grant the service account 'Release Manager' permission"
    echo "   7. Save the JSON key as android/play-service-account.json"
    echo "   8. Add android/play-service-account.json to .gitignore"
    echo ""
    echo "   For manual upload, visit:"
    echo "   https://play.google.com/console"
    return 1
  fi

  # Check if bundletool is available
  if ! command -v bundletool &> /dev/null; then
    echo -e "${YELLOW}⚠️  bundletool not found, installing...${NC}"
    brew install bundletool || {
      echo -e "${RED}❌ Failed to install bundletool${NC}"
      echo "   Install manually: brew install bundletool"
      return 1
    }
  fi

  # Use Google Play API to upload
  # This requires the google-api-python-client
  UPLOAD_SCRIPT="$SCRIPT_DIR/google-play-upload.py"

  if [ ! -f "$UPLOAD_SCRIPT" ]; then
    echo -e "${YELLOW}⚠️  Creating Google Play upload script...${NC}"
    create_google_play_upload_script "$UPLOAD_SCRIPT"
  fi

  # Check if Python and required packages are available
  if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python 3 is required but not found${NC}"
    return 1
  fi

  # Install required Python packages if needed
  if ! python3 -c "import googleapiclient" &> /dev/null; then
    echo -e "${YELLOW}⚠️  Installing Google API Python client...${NC}"
    pip3 install --upgrade google-api-python-client google-auth-httplib2 google-auth-oauthlib || {
      echo -e "${RED}❌ Failed to install required Python packages${NC}"
      return 1
    }
  fi

  echo -e "${YELLOW}ℹ️  Uploading AAB to Google Play Internal Test Track...${NC}"

  # Upload using the Python script
  if python3 "$UPLOAD_SCRIPT" \
    --package_name "com.tsquared.team_sync.$FLAVOR" \
    --aab_file "$AAB_PATH" \
    --service_account_json "$SERVICE_ACCOUNT_JSON" \
    --track "internal"; then
    echo -e "${GREEN}✅ Successfully uploaded to Google Play Internal Test Track${NC}"
    echo "   Build will be available for internal testers shortly"
    echo "   Check status at: https://play.google.com/console"
    return 0
  else
    echo -e "${RED}❌ Google Play upload failed${NC}"
    echo ""
    echo "   You can upload manually:"
    echo "   1. Go to https://play.google.com/console"
    echo "   2. Select your app"
    echo "   3. Go to 'Release' > 'Testing' > 'Internal testing'"
    echo "   4. Create a new release and upload: $AAB_PATH"
    return 1
  fi
}

# Function to create the Google Play upload Python script
create_google_play_upload_script() {
  local script_path=$1
  cat > "$script_path" << 'PYTHON_SCRIPT'
#!/usr/bin/env python3
"""Upload Android App Bundle to Google Play Console"""

import argparse
import sys
from googleapiclient.discovery import build
from google.oauth2 import service_account
from googleapiclient.http import MediaFileUpload

def upload_to_play_store(package_name, aab_file, service_account_json, track):
    """Upload AAB to Google Play Store"""

    # Define the scope
    SCOPES = ['https://www.googleapis.com/auth/androidpublisher']

    try:
        # Authenticate using service account
        credentials = service_account.Credentials.from_service_account_file(
            service_account_json, scopes=SCOPES)

        # Build the service
        service = build('androidpublisher', 'v3', credentials=credentials)

        # Create an edit
        edit_request = service.edits().insert(packageName=package_name)
        edit_response = edit_request.execute()
        edit_id = edit_response['id']

        print(f"Created edit with ID: {edit_id}")

        # Upload the AAB
        print(f"Uploading {aab_file}...")
        media = MediaFileUpload(aab_file, mimetype='application/octet-stream')
        upload_request = service.edits().bundles().upload(
            packageName=package_name,
            editId=edit_id,
            media_body=media
        )
        upload_response = upload_request.execute()
        version_code = upload_response['versionCode']

        print(f"Uploaded version code: {version_code}")

        # Assign to track
        print(f"Assigning to {track} track...")
        track_request = service.edits().tracks().update(
            packageName=package_name,
            editId=edit_id,
            track=track,
            body={
                'track': track,
                'releases': [{
                    'versionCodes': [version_code],
                    'status': 'completed'
                }]
            }
        )
        track_response = track_request.execute()

        print(f"Assigned to track: {track_response['track']}")

        # Commit the edit
        commit_request = service.edits().commit(
            packageName=package_name,
            editId=edit_id
        )
        commit_response = commit_request.execute()

        print(f"✅ Successfully published to {track} track!")
        print(f"Edit ID: {commit_response['id']}")
        return True

    except Exception as e:
        print(f"❌ Error: {e}", file=sys.stderr)
        return False

def main():
    parser = argparse.ArgumentParser(description='Upload AAB to Google Play Store')
    parser.add_argument('--package_name', required=True, help='Package name (e.g., com.example.app)')
    parser.add_argument('--aab_file', required=True, help='Path to AAB file')
    parser.add_argument('--service_account_json', required=True, help='Path to service account JSON')
    parser.add_argument('--track', default='internal', help='Track (internal, alpha, beta, production)')

    args = parser.parse_args()

    success = upload_to_play_store(
        args.package_name,
        args.aab_file,
        args.service_account_json,
        args.track
    )

    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()
PYTHON_SCRIPT

  chmod +x "$script_path"
  echo -e "${GREEN}✅ Created Google Play upload script${NC}"
}

# Main deployment logic
case $DEPLOY_TARGET in
  ios)
    deploy_testflight
    EXIT_CODE=$?
    ;;

  android)
    deploy_google_play
    EXIT_CODE=$?
    ;;

  all)
    echo -e "${YELLOW}Deploying to both TestFlight and Google Play...${NC}"
    echo ""

    IOS_SUCCESS=0
    ANDROID_SUCCESS=0

    if deploy_testflight; then
      IOS_SUCCESS=1
    fi

    echo ""

    if deploy_google_play; then
      ANDROID_SUCCESS=1
    fi

    echo ""
    echo "================================================"
    echo -e "${BLUE}📊 Deployment Summary${NC}"
    echo "================================================"

    if [ $IOS_SUCCESS -eq 1 ]; then
      echo -e "TestFlight (iOS):     ${GREEN}✅ SUCCESS${NC}"
    else
      echo -e "TestFlight (iOS):     ${RED}❌ FAILED${NC}"
    fi

    if [ $ANDROID_SUCCESS -eq 1 ]; then
      echo -e "Google Play (Android): ${GREEN}✅ SUCCESS${NC}"
    else
      echo -e "Google Play (Android): ${RED}❌ FAILED${NC}"
    fi

    echo ""

    if [ $IOS_SUCCESS -eq 1 ] && [ $ANDROID_SUCCESS -eq 1 ]; then
      echo -e "${GREEN}🎉 All deployments completed successfully!${NC}"
      EXIT_CODE=0
    else
      echo -e "${YELLOW}⚠️  Some deployments failed${NC}"
      EXIT_CODE=1
    fi
    ;;

  *)
    echo -e "${RED}❌ Invalid deployment target: $DEPLOY_TARGET${NC}"
    echo "Usage: $0 [ios|android|all]"
    exit 1
    ;;
esac

exit $EXIT_CODE

