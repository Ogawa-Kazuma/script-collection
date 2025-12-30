#!/usr/bin/env python3
"""
Ubuntu Mirror Speed Tester (APT-Accurate)
Tests the download speed of Ubuntu mirrors using APT-realistic methods.
- Auto-detects Ubuntu release
- Tests both metadata (/dists/) and packages (/pool/)
- Multiple passes with median calculation
- Weighted scoring matching real APT behavior
"""

import urllib.request
import urllib.error
import time
import sys
import argparse
import subprocess
import os
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import List, Tuple, Optional, Set, Dict
import json
import re
import statistics

# Common Ubuntu mirrors to test
DEFAULT_MIRRORS = [
    "http://archive.ubuntu.com/ubuntu/",
    "http://us.archive.ubuntu.com/ubuntu/",
    "http://mirror.ubuntu.com/ubuntu/",
    "http://mirrors.kernel.org/ubuntu/",
    "http://mirror.csclub.uwaterloo.ca/ubuntu/",
    "http://ubuntu.mirror.constant.com/ubuntu/",
    "http://mirror.genesisadaptive.com/ubuntu/",
    "http://mirror.math.princeton.edu/pub/ubuntu/",
    "http://mirror.its.sfu.ca/mirror/ubuntu/ubuntu/",
    "http://ubuntu.mirror.iweb.ca/ubuntu/",
    "http://mirror.cs.ubc.ca/ubuntu/ubuntu/",
    "http://mirror.ubiquityserving.com/ubuntu/",
    "http://mirror.team-cymru.com/ubuntu/",
    "http://mirror.steadfastnet.com/ubuntu/",
    "http://mirror.ancl.hawaii.edu/linux/ubuntu/",
    "http://mirror.pit.teraswitch.com/ubuntu/",
    "http://mirror.raystedman.org/ubuntu/",
    "http://mirror.steadfast.net/ubuntu/",
    "http://mirror.cc.columbia.edu/pub/linux/ubuntu/ubuntu/",
    "http://mirror.umd.edu/ubuntu/",
]

# Default test sizes (APT-realistic)
METADATA_TEST_SIZE = 2_000_000  # 2 MB - lets TCP stabilize
POOL_TEST_SIZE = 2_000_000     # 2 MB - typical small package size


def detect_ubuntu_release() -> str:
    """
    Auto-detect the Ubuntu release codename (e.g., jammy, focal, noble).
    Falls back to 'jammy' if detection fails.
    """
    try:
        # Try lsb_release first
        result = subprocess.run(
            ['lsb_release', '-cs'],
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.returncode == 0:
            return result.stdout.strip().lower()
    except (subprocess.TimeoutExpired, FileNotFoundError, subprocess.SubprocessError):
        pass
    
    try:
        # Fallback: read /etc/os-release
        with open('/etc/os-release', 'r') as f:
            for line in f:
                if line.startswith('VERSION_CODENAME='):
                    return line.split('=', 1)[1].strip().strip('"').lower()
    except (FileNotFoundError, IOError):
        pass
    
    # Final fallback
    return 'jammy'


def find_pool_test_file(release: str) -> Optional[str]:
    """
    Find a real package file in /pool/ for testing.
    Returns a common small package path like pool/main/z/zlib/...
    """
    # Common small packages that exist in most releases
    candidates = [
        f"pool/main/z/zlib/zlib1g_1.2.11.dfsg-2ubuntu9.2_amd64.deb",  # jammy
        f"pool/main/z/zlib/zlib1g_1.2.11.dfsg-2ubuntu1.3_amd64.deb",  # focal
        f"pool/main/z/zlib/zlib1g_1.2.11.dfsg-2ubuntu10_amd64.deb",   # noble
        f"pool/main/z/zlib/zlib1g_1.2.11.dfsg-2ubuntu9_amd64.deb",   # generic
    ]
    
    # Try to find a real file by testing archive.ubuntu.com
    test_mirror = "http://archive.ubuntu.com/ubuntu/"
    for candidate in candidates:
        test_url = test_mirror + candidate
        try:
            req = urllib.request.Request(test_url, method='HEAD')
            with urllib.request.urlopen(req, timeout=5) as response:
                if response.status == 200:
                    return candidate
        except:
            continue
    
    # Return first candidate as fallback
    return candidates[0]


class MirrorTester:
    def __init__(self, timeout: int = 15, release: Optional[str] = None, passes: int = 3):
        self.timeout = timeout
        self.passes = passes
        self.release = release or detect_ubuntu_release()
        self.metadata_file = f"dists/{self.release}/InRelease"
        self.pool_file = find_pool_test_file(self.release)
        self.results: List[Tuple[str, float, float, float, Optional[str]]] = []  # (url, pool_speed, metadata_speed, final_score, error)
        
        print(f"Detected Ubuntu release: {self.release}")
        if self.pool_file:
            print(f"Using pool test file: {self.pool_file}")

    def download_test(self, url: str, size: int) -> Tuple[float, Optional[str]]:
        """
        Download a file and measure speed.
        Returns: (speed_mbps, error_message)
        """
        try:
            start_time = time.time()
            with urllib.request.urlopen(url, timeout=self.timeout) as response:
                data = response.read(size)
                elapsed_time = time.time() - start_time
            
            if elapsed_time == 0:
                elapsed_time = 0.001
            
            bytes_downloaded = len(data)
            speed_mbps = (bytes_downloaded * 8) / (elapsed_time * 1_000_000)
            return (speed_mbps, None)
            
        except urllib.error.URLError as e:
            return (0.0, f"Connection error: {str(e)}")
        except Exception as e:
            return (0.0, f"Error: {str(e)}")

    def test_mirror(self, mirror_url: str) -> Tuple[str, float, float, float, Optional[str]]:
        """
        Test a mirror with multiple passes on both metadata and pool files.
        Returns: (mirror_url, pool_speed_median, metadata_speed_median, final_score, error)
        """
        base_url = mirror_url.rstrip('/')
        metadata_url = f"{base_url}/{self.metadata_file}"
        pool_url = f"{base_url}/{self.pool_file}" if self.pool_file else None
        
        # Test metadata (InRelease) - multiple passes
        metadata_speeds = []
        for i in range(self.passes):
            speed, error = self.download_test(metadata_url, METADATA_TEST_SIZE)
            if error:
                return (mirror_url, 0.0, 0.0, 0.0, error)
            metadata_speeds.append(speed)
            time.sleep(0.5)  # Small delay between passes
        
        metadata_median = statistics.median(metadata_speeds)
        
        # Test pool file (real package) - multiple passes
        pool_median = 0.0
        if pool_url:
            pool_speeds = []
            for i in range(self.passes):
                speed, error = self.download_test(pool_url, POOL_TEST_SIZE)
                if error:
                    # Pool file might not exist, but that's okay - use metadata only
                    break
                pool_speeds.append(speed)
                time.sleep(0.5)
            
            if pool_speeds:
                pool_median = statistics.median(pool_speeds)
            else:
                # If pool test fails, weight metadata more heavily
                pool_median = metadata_median * 0.8  # Assume pool is slightly slower
        
        # Calculate final score: 60% pool, 30% metadata, 10% failure penalty
        # This matches real APT behavior where package downloads dominate
        if pool_median > 0:
            final_score = (0.6 * pool_median) + (0.3 * metadata_median)
        else:
            # Fallback if pool test completely fails
            final_score = metadata_median * 0.7  # Penalize for missing pool
        
        return (mirror_url, pool_median, metadata_median, final_score, None)

    def test_mirrors(self, mirrors: List[str], max_workers: int = 10) -> List[Tuple[str, float, float, float, Optional[str]]]:
        """
        Test multiple mirrors concurrently.
        """
        print(f"\nTesting {len(mirrors)} mirrors...")
        print(f"Each mirror: {self.passes} passes on metadata + {self.passes} passes on pool file")
        print("This will take several minutes...\n")
        
        results = []
        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            future_to_mirror = {executor.submit(self.test_mirror, mirror): mirror 
                               for mirror in mirrors}
            
            completed = 0
            for future in as_completed(future_to_mirror):
                completed += 1
                result = future.result()
                results.append(result)
                
                mirror_url, pool_speed, metadata_speed, final_score, error = result
                if error:
                    print(f"[{completed}/{len(mirrors)}] {mirror_url}: FAILED - {error}")
                else:
                    print(f"[{completed}/{len(mirrors)}] {mirror_url[:50]:50s} "
                          f"Score: {final_score:6.2f} Mbps (pool: {pool_speed:5.2f}, meta: {metadata_speed:5.2f})")
        
        return results

    def print_results(self, results: List[Tuple[str, float, float, float, Optional[str]]], top_n: int = 10):
        """
        Print sorted results with detailed breakdown.
        """
        # Sort by final score (descending)
        sorted_results = sorted(results, key=lambda x: x[3], reverse=True)
        
        print("\n" + "="*90)
        print("APT-ACCURATE MIRROR SPEED TEST RESULTS")
        print("="*90)
        print(f"\nTop {min(top_n, len(sorted_results))} fastest mirrors (sorted by APT-weighted score):\n")
        print(f"{'Rank':<6} {'Mirror URL':<50} {'Score':<10} {'Pool':<10} {'Metadata':<10}")
        print("-" * 90)
        
        successful = [r for r in sorted_results if r[3] > 0]
        failed = [r for r in sorted_results if r[3] == 0]
        
        for i, (mirror, pool_speed, metadata_speed, final_score, error) in enumerate(successful[:top_n], 1):
            print(f"{i:2d}.   {mirror:50s} {final_score:8.2f}   {pool_speed:8.2f}   {metadata_speed:8.2f}")
        
        if failed:
            print(f"\nFailed mirrors ({len(failed)}):")
            for mirror, _, _, _, error in failed:
                print(f"    {mirror:50s} {error or 'Unknown error'}")
        
        if successful:
            best = successful[0]
            print(f"\n{'='*90}")
            print(f"RECOMMENDED MIRROR: {best[0]}")
            print(f"  Final Score: {best[3]:.2f} Mbps (60% pool + 30% metadata)")
            print(f"  Pool Speed:  {best[1]:.2f} Mbps (package downloads)")
            print(f"  Meta Speed:  {best[2]:.2f} Mbps (index downloads)")
            print(f"{'='*90}")


def get_mirrors_from_file(filepath: str) -> List[str]:
    """Read mirrors from a text file (one per line)."""
    try:
        with open(filepath, 'r') as f:
            mirrors = [line.strip() for line in f if line.strip() and not line.startswith('#')]
        return mirrors
    except FileNotFoundError:
        print(f"Error: File '{filepath}' not found.")
        sys.exit(1)
    except Exception as e:
        print(f"Error reading file '{filepath}': {e}")
        sys.exit(1)


def fetch_mirrors_from_launchpad(country: Optional[str] = None, limit: int = 10000) -> List[str]:
    """
    Fetch Ubuntu mirrors from Launchpad's archive mirrors page.
    Returns a list of HTTP/HTTPS mirror URLs.
    
    Args:
        country: Optional country code to filter mirrors (e.g., 'US', 'GB', 'DE')
        limit: Maximum number of mirrors to fetch (default: 100)
    """
    mirrors: Set[str] = set()
    
    try:
        print("Fetching mirrors from Launchpad...")
        url = "https://launchpad.net/ubuntu/+archivemirrors"
        
        with urllib.request.urlopen(url, timeout=30) as response:
            html_content = response.read().decode('utf-8', errors='ignore')
        
        # Extract HTTP and HTTPS mirror URLs
        # Pattern 1: Markdown-style links [http](http://mirror.example.com/ubuntu/)
        http_pattern = r'\[http\]\(http://([^\)]+)/ubuntu/\)'
        https_pattern = r'\[https\]\(https://([^\)]+)/ubuntu/\)'
        
        # Find all HTTP mirrors
        for match in re.finditer(http_pattern, html_content):
            mirror_host = match.group(1)
            mirrors.add(f"http://{mirror_host}/ubuntu/")
        
        # Find all HTTPS mirrors
        for match in re.finditer(https_pattern, html_content):
            mirror_host = match.group(1)
            mirrors.add(f"https://{mirror_host}/ubuntu/")
        
        # Pattern 2: Direct URLs in href attributes or plain text
        # Look for http:// or https:// followed by domain and /ubuntu/
        url_patterns = [
            r'https?://[a-zA-Z0-9][a-zA-Z0-9\-\.]*[a-zA-Z0-9]\.(?:[a-zA-Z]{2,}|[a-zA-Z]{2,}\.[a-zA-Z]{2,})/ubuntu/',
            r'https?://[a-zA-Z0-9][a-zA-Z0-9\-\.]*[a-zA-Z0-9]\.(?:[a-zA-Z]{2,}|[a-zA-Z]{2,}\.[a-zA-Z]{2,})/pub/ubuntu/',
            r'https?://[a-zA-Z0-9][a-zA-Z0-9\-\.]*[a-zA-Z0-9]\.(?:[a-zA-Z]{2,}|[a-zA-Z]{2,}\.[a-zA-Z]{2,})/mirror/ubuntu/',
        ]
        
        for pattern in url_patterns:
            for match in re.finditer(pattern, html_content):
                mirror_url = match.group(0)
                # Normalize URL
                if not mirror_url.endswith('/'):
                    mirror_url += '/'
                mirrors.add(mirror_url)
        
        mirrors_list = list(mirrors)
        
        # Filter by country if specified
        if country:
            country_upper = country.upper()
            country_lower = country.lower()
            # Country codes in domain (e.g., .us, .uk, .de, .ca)
            # Or country name in domain (e.g., usa, unitedstates)
            filtered = []
            for m in mirrors_list:
                # Check for country code in domain
                if (f".{country_lower}" in m.lower() or 
                    f".{country_upper}" in m.upper() or
                    country_upper in m.upper()):
                    filtered.append(m)
            
            if filtered:
                mirrors_list = filtered
            else:
                print(f"Warning: No mirrors found for country '{country}', using all mirrors.")
        
        # Limit the number of mirrors
        if len(mirrors_list) > limit:
            print(f"Found {len(mirrors_list)} mirrors, limiting to {limit} for testing...")
            mirrors_list = mirrors_list[:limit]
        
        print(f"Found {len(mirrors_list)} mirrors from Launchpad.")
        return mirrors_list
        
    except urllib.error.URLError as e:
        print(f"Warning: Could not fetch mirrors from Launchpad: {e}")
        print("Falling back to default mirrors.")
        return []
    except Exception as e:
        print(f"Warning: Error parsing Launchpad mirrors: {e}")
        print("Falling back to default mirrors.")
        return []


def main():
    parser = argparse.ArgumentParser(
        description='Test Ubuntu mirror speeds to find the fastest one.',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s                          # Test default mirrors
  %(prog)s --fetch-launchpad        # Fetch and test mirrors from Launchpad
  %(prog)s --fetch-launchpad --country US  # Fetch US mirrors only
  %(prog)s --mirrors-file mirrors.txt  # Test mirrors from file
  %(prog)s --top 5                  # Show top 5 results
  %(prog)s --timeout 15             # Set timeout to 15 seconds
        """
    )
    
    parser.add_argument(
        '--mirrors-file',
        type=str,
        help='Path to file containing mirror URLs (one per line)'
    )
    
    parser.add_argument(
        '--top',
        type=int,
        default=10,
        help='Number of top results to display (default: 10)'
    )
    
    parser.add_argument(
        '--timeout',
        type=int,
        default=15,
        help='Timeout in seconds for each mirror test (default: 15)'
    )
    
    parser.add_argument(
        '--workers',
        type=int,
        default=10,
        help='Number of concurrent workers (default: 10)'
    )
    
    parser.add_argument(
        '--release',
        type=str,
        help='Ubuntu release codename (e.g., jammy, focal, noble). Auto-detected if not specified.'
    )
    
    parser.add_argument(
        '--passes',
        type=int,
        default=3,
        help='Number of test passes per mirror (default: 3, uses median)'
    )
    
    parser.add_argument(
        '--json',
        action='store_true',
        help='Output results in JSON format'
    )
    
    parser.add_argument(
        '--fetch-launchpad',
        action='store_true',
        help='Fetch mirrors from Launchpad (https://launchpad.net/ubuntu/+archivemirrors)'
    )
    
    parser.add_argument(
        '--country',
        type=str,
        help='Filter mirrors by country code (e.g., US, GB, DE, CA). Only works with --fetch-launchpad'
    )
    
    parser.add_argument(
        '--max-mirrors',
        type=int,
        default=10000,
        help='Maximum number of mirrors to fetch from Launchpad (default: 100)'
    )
    
    args = parser.parse_args()
    
    # Get mirrors to test
    if args.mirrors_file:
        mirrors = get_mirrors_from_file(args.mirrors_file)
    elif args.fetch_launchpad:
        mirrors = fetch_mirrors_from_launchpad(country=args.country, limit=args.max_mirrors)
        if not mirrors:
            print("No mirrors fetched from Launchpad, using default mirrors.")
            mirrors = DEFAULT_MIRRORS
    else:
        mirrors = DEFAULT_MIRRORS
    
    if not mirrors:
        print("Error: No mirrors to test.")
        sys.exit(1)
    
    # Test mirrors
    tester = MirrorTester(timeout=args.timeout, release=args.release, passes=args.passes)
    results = tester.test_mirrors(mirrors, max_workers=args.workers)
    
    # Output results
    if args.json:
        output = []
        for mirror, pool_speed, metadata_speed, final_score, error in sorted(results, key=lambda x: x[3], reverse=True):
            output.append({
                'mirror': mirror,
                'final_score_mbps': round(final_score, 2),
                'pool_speed_mbps': round(pool_speed, 2),
                'metadata_speed_mbps': round(metadata_speed, 2),
                'error': error
            })
        print(json.dumps(output, indent=2))
    else:
        tester.print_results(results, top_n=args.top)


if __name__ == '__main__':
    main()

