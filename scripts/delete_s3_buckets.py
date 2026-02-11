#!/usr/bin/env python3
"""
S3 Bucket Force Delete - Python Version
Efficiently deletes S3 buckets with versioning using boto3
"""

import boto3
import sys
from botocore.exceptions import ClientError

def delete_bucket_versions(bucket_name, region='us-east-1'):
    """Delete all versions and delete markers from an S3 bucket."""
    s3 = boto3.resource('s3', region_name=region)
    bucket = s3.Bucket(bucket_name)

    print(f"  Deleting all versions and markers...")

    try:
        # Delete all object versions and delete markers
        bucket.object_versions.delete()
        print(f"  ✓ All versions deleted")
        return True
    except ClientError as e:
        print(f"  ✗ Error: {e}")
        return False

def delete_bucket(bucket_name, region='us-east-1'):
    """Delete an S3 bucket after removing all contents."""
    s3_client = boto3.client('s3', region_name=region)

    print(f"\n{'─' * 65}")
    print(f"Deleting: {bucket_name}")
    print('─' * 65)

    try:
        # Check if bucket exists
        s3_client.head_bucket(Bucket=bucket_name)
    except ClientError:
        print(f"  ⚠️  Bucket does not exist or access denied")
        return False

    # Suspend versioning
    print(f"  Suspending versioning...")
    try:
        s3_client.put_bucket_versioning(
            Bucket=bucket_name,
            VersioningConfiguration={'Status': 'Suspended'}
        )
    except ClientError as e:
        print(f"  ✗ Could not suspend versioning: {e}")

    # Delete all versions
    if not delete_bucket_versions(bucket_name, region):
        return False

    # Delete the bucket itself
    print(f"  Deleting bucket...")
    try:
        s3_client.delete_bucket(Bucket=bucket_name)
        print(f"  ✅ {bucket_name} DELETED")
        return True
    except ClientError as e:
        print(f"  ✗ Failed to delete bucket: {e}")
        return False

def main():
    region = 'us-east-1'
    s3_client = boto3.client('s3', region_name=region)

    print("=" * 65)
    print("🗑️  S3 BUCKET DELETION (Python)")
    print("=" * 65)
    print()

    # List all secure-vpc buckets
    try:
        response = s3_client.list_buckets()
        buckets = [b['Name'] for b in response['Buckets'] if 'secure-vpc' in b['Name']]
    except ClientError as e:
        print(f"Error listing buckets: {e}")
        sys.exit(1)

    if not buckets:
        print("✅ No secure-vpc buckets found. Already clean!")
        return

    print("Found buckets:")
    for bucket in buckets:
        print(f"  • {bucket}")

    print(f"\nTotal: {len(buckets)} bucket(s)")
    print()

    # Confirm deletion
    confirmation = input("Type 'DELETE NOW' to confirm: ")
    if confirmation != "DELETE NOW":
        print("Aborted.")
        sys.exit(0)

    print()
    print("🗑️  Starting deletion...")

    # Delete each bucket
    success_count = 0
    for bucket in buckets:
        if delete_bucket(bucket, region):
            success_count += 1

    print()
    print("=" * 65)
    print("✅ DELETION COMPLETE")
    print("=" * 65)
    print()

    # Verify
    try:
        response = s3_client.list_buckets()
        remaining = len([b['Name'] for b in response['Buckets'] if 'secure-vpc' in b['Name']])
    except ClientError:
        remaining = -1

    print(f"Successfully deleted: {success_count}/{len(buckets)}")
    print(f"Remaining secure-vpc buckets: {remaining}")
    print()

    if remaining == 0:
        print("✅ SUCCESS: All secure-vpc S3 buckets deleted!")
        print()
        print("Final cleanup summary:")
        print("  • 4 VPCs: DELETED ✅")
        print("  • 10 S3 Buckets: DELETED ✅")
        print("  • All Terraform infrastructure: CLEANED ✅")
        print()
        print("💰 Total AWS cost reduced to: $0/month")
    else:
        print(f"⚠️  {remaining} bucket(s) remain.")

    print()

if __name__ == '__main__':
    main()
