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
