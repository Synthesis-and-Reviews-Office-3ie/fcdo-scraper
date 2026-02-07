"""
Main FCDO Business Case Scraper
Complete workflow to scrape all business cases from FCDO programmes.
"""

import os
import sys
import json
import logging
from datetime import datetime
import argparse

# Add current directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from scrape_programmes_selenium import FCDOSeleniumScraper
from scrape_business_cases import BusinessCaseScraper

# Configure logging
log_filename = f'data/scraper_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log'
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(log_filename, encoding='utf-8'),
        logging.StreamHandler()
    ]
)

def check_dependencies():
    """Check if required packages are installed."""
    required = ['requests', 'beautifulsoup4', 'selenium']
    missing = []
    
    for package in required:
        try:
            __import__(package if package != 'beautifulsoup4' else 'bs4')
        except ImportError:
            missing.append(package)
    
    if missing:
        print(f"ERROR: Missing required packages: {', '.join(missing)}")
        print(f"Please install with: pip install {' '.join(missing)}")
        return False
    
    # Check for ChromeDriver
    try:
        from selenium import webdriver
        from selenium.webdriver.chrome.options import Options
        options = Options()
        options.add_argument("--headless")
        options.add_argument("--no-sandbox")
        driver = webdriver.Chrome(options=options)
        driver.quit()
        print("[OK] ChromeDriver is available")
    except Exception as e:
        print(f"WARNING: ChromeDriver not found or not working: {e}")
        print("Please install ChromeDriver:")
        print("  1. Download from: https://chromedriver.chromium.org/")
        print("  2. Add to PATH or place in project directory")
        print("  3. Or install via: pip install webdriver-manager")
        return False
    
    return True

def setup_directories():
    """Ensure all required directories exist."""
    dirs = ['data', 'documents']
    for d in dirs:
        os.makedirs(d, exist_ok=True)
        logging.info(f"[OK] Directory ready: {d}/")

def main():
    parser = argparse.ArgumentParser(
        description='Scrape business case documents from all FCDO programmes',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  # Scrape all programmes and download all business cases
  python main.py
  
  # Include annual review documents (linked to business cases)
  python main.py --include-annual-reviews
  
  # Test pagination - scrape only first 3 pages
  python main.py --max-pages 3 --no-download
  
  # See the browser in action (for debugging)
  python main.py --show-browser --max-pages 2 --no-download
  
  # Scrape only the programme list (no document download)
  python main.py --no-download
  
  # Test with first 10 programmes including annual reviews
  python main.py --max-programmes 10 --include-annual-reviews
  
  # Skip programme list scraping if already done
  python main.py --skip-programmes
        '''
    )
    
    parser.add_argument(
        '--skip-programmes',
        action='store_true',
        help='Skip scraping programme list (use existing data/fcdo_programmes.json)'
    )
    
    parser.add_argument(
        '--no-download',
        action='store_true',
        help='Find business cases but do not download documents'
    )
    
    parser.add_argument(
        '--max-programmes',
        type=int,
        default=None,
        help='Maximum number of programmes to process (for testing)'
    )
    
    parser.add_argument(
        '--show-browser',
        action='store_true',
        help='Show browser window during scraping (useful for debugging)'
    )
    
    parser.add_argument(
        '--max-pages',
        type=int,
        default=None,
        help='Maximum number of pages to scrape (for testing pagination)'
    )
    
    parser.add_argument(
        '--skip-existing',
        action='store_true',
        help='Skip programmes that already have downloaded documents (resume mode)'
    )
    
    parser.add_argument(
        '--include-annual-reviews',
        action='store_true',
        help='Also scrape annual review documents (linked to business cases as "after" documents)'
    )
    
    args = parser.parse_args()
    
    print("\n" + "="*60)
    print("FCDO BUSINESS CASE SCRAPER")
    print("="*60)
    print("This tool uses browser automation (Selenium) to scrape")
    print("business case documents from all FCDO programmes on")
    print("devtracker.fcdo.gov.uk (handles JavaScript pagination)")
    print("="*60 + "\n")
    
    # Check dependencies
    if not check_dependencies():
        return 1
    
    # Setup directories
    setup_directories()
    
    # Step 1: Scrape programme list
    programmes = []
    programmes_file = 'data/fcdo_programmes.json'
    
    if args.skip_programmes and os.path.exists(programmes_file):
        print(f"\n[OK] Loading existing programme list from {programmes_file}")
        with open(programmes_file, 'r', encoding='utf-8') as f:
            programmes = json.load(f)
        print(f"[OK] Loaded {len(programmes)} programmes\n")
    else:
        print("\n" + "-"*60)
        print("STEP 1: Scraping Programme List")
        print("-"*60)
        
        programme_scraper = FCDOSeleniumScraper(headless=not args.show_browser)
        programmes = programme_scraper.scrape_all_programmes(max_pages=args.max_pages)
        programme_scraper.save_programmes(programmes)
        
        print(f"\n[OK] Successfully scraped {len(programmes)} FCDO programmes")
        print(f"[OK] Programme list saved to {programmes_file}\n")
    
    # Step 2: Scrape business case documents
    print("\n" + "-"*60)
    print("STEP 2: Scraping Business Case Documents")
    print("-"*60)
    
    if args.max_programmes:
        print(f"\n[!] Testing mode: Processing only {args.max_programmes} programmes")
        programmes = programmes[:args.max_programmes]
    
    print(f"\nTotal programmes to process: {len(programmes)}")
    print(f"Download documents: {'No' if args.no_download else 'Yes'}")
    print(f"Include annual reviews: {'Yes' if args.include_annual_reviews else 'No'}")
    print(f"Polite delay between requests: 2 seconds")
    print("\nThis may take a while. Please be patient...\n")
    
    business_case_scraper = BusinessCaseScraper(include_annual_reviews=args.include_annual_reviews)
    
    # Filter out already processed programmes if --skip-existing is set
    if args.skip_existing:
        original_count = len(programmes)
        programmes_to_process = []
        skipped = 0
        skipped_business_only = 0
        skipped_complete = 0
        
        for prog in programmes:
            should_process = business_case_scraper.should_process_programme(prog['id'])
            if should_process:
                programmes_to_process.append(prog)
            else:
                skipped += 1
                # Get detailed skip reason
                status = business_case_scraper.check_programme_completion_status(prog['id'])
                if args.include_annual_reviews and status['has_business_cases'] and status['has_annual_reviews']:
                    skipped_complete += 1
                elif not args.include_annual_reviews and status['has_business_cases']:
                    skipped_business_only += 1
        
        programmes = programmes_to_process
        print(f"\n[OK] Smart resume mode: Skipped {skipped} programmes")
        if skipped_business_only > 0:
            print(f"    - {skipped_business_only} with business cases (annual reviews not requested)")
        if skipped_complete > 0:
            print(f"    - {skipped_complete} with both business cases and annual reviews")
        print(f"[OK] Will process {len(programmes)} remaining programmes\n")
    
    documents = business_case_scraper.scrape_all_business_cases(
        programmes,
        download=not args.no_download,
        max_programmes=None  # Already sliced above
    )
    
    # Step 3: Save results
    print("\n" + "-"*60)
    print("STEP 3: Saving Results")
    print("-"*60 + "\n")
    
    business_case_scraper.save_metadata(documents)
    business_case_scraper.generate_summary(documents)
    
    print(f"\n[OK] Log file saved to: {log_filename}")
    print(f"[OK] Document metadata saved to: data/business_cases_metadata.json")
    print(f"[OK] Summary saved to: data/scraping_summary.json")
    
    if not args.no_download and documents:
        print(f"[OK] Downloaded documents are in: documents/")
    
    print("\n" + "="*60)
    print("SCRAPING COMPLETE!")
    print("="*60 + "\n")
    
    return 0

if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\n\n[!] Scraping interrupted by user")
        sys.exit(1)
    except Exception as e:
        logging.error(f"Fatal error: {e}", exc_info=True)
        print(f"\n[ERROR] Error: {e}")
        sys.exit(1)
