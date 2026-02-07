"""
FCDO Business Case Document Scraper
Scrapes business case and statement of need documents from FCDO programmes.
"""

import requests
from bs4 import BeautifulSoup
import time
import json
import os
from typing import List, Dict, Optional
import logging
from urllib.parse import urljoin
import re

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('data/scraper.log', mode='a'),
        logging.StreamHandler()
    ]
)

class BusinessCaseScraper:
    def __init__(self, include_annual_reviews: bool = False):
        self.base_url = "https://devtracker.fcdo.gov.uk"
        self.headers = {
            'User-Agent': 'Research Bot (Academic/Non-Commercial Use; Polite Scraper; Contact: researcher@example.com)',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-GB,en;q=0.5',
            'Accept-Encoding': 'gzip, deflate',
            'Connection': 'keep-alive',
        }
        self.delay = 2  # 2 seconds between requests (polite scraping)
        self.documents_dir = 'documents'
        self.include_annual_reviews = include_annual_reviews
        
        # Keywords to identify business case documents
        self.business_case_keywords = [
            'business case',
            'addendum to the business case',
            'statement of need',
            'business case and summary',
            'project business case',
            'programme business case'
        ]
        
        # Keywords to identify annual review documents
        self.annual_review_keywords = [
            'annual review',
            'annual report',
            'annual monitoring',
            'yearly review',
            'project completion review',
            'programme review'
        ]
        
    def get_page(self, url: str, retry_count: int = 3) -> Optional[requests.Response]:
        """Fetch a page with retry logic and polite delay."""
        for attempt in range(retry_count):
            try:
                logging.info(f"Fetching: {url} (attempt {attempt + 1}/{retry_count})")
                response = requests.get(url, headers=self.headers, timeout=30)
                response.raise_for_status()
                time.sleep(self.delay)  # Polite delay
                return response
            except requests.RequestException as e:
                logging.warning(f"Error fetching {url}: {e}")
                if attempt < retry_count - 1:
                    wait_time = (attempt + 1) * 5
                    logging.info(f"Retrying in {wait_time} seconds...")
                    time.sleep(wait_time)
                else:
                    logging.error(f"Failed to fetch {url} after {retry_count} attempts")
                    return None
    
    def is_business_case_document(self, title: str) -> bool:
        """Check if document title indicates it's a business case."""
        title_lower = title.lower()
        return any(keyword in title_lower for keyword in self.business_case_keywords)
    
    def is_annual_review_document(self, title: str) -> bool:
        """Check if document title indicates it's an annual review."""
        title_lower = title.lower()
        return any(keyword in title_lower for keyword in self.annual_review_keywords)
    
    def get_document_type(self, title: str) -> str:
        """Determine the type of document based on title."""
        if self.is_business_case_document(title):
            return 'business_case'
        elif self.is_annual_review_document(title):
            return 'annual_review'
        else:
            return 'other'
    
    def check_programme_completion_status(self, programme_id: str) -> Dict[str, bool]:
        """Check what types of documents are already downloaded for a programme."""
        programme_dir = os.path.join(self.documents_dir, programme_id)
        
        if not os.path.exists(programme_dir):
            return {'has_business_cases': False, 'has_annual_reviews': False, 'has_any': False}
        
        files = os.listdir(programme_dir)
        if not files:
            return {'has_business_cases': False, 'has_annual_reviews': False, 'has_any': False}
        
        # Try to determine document types from existing metadata if available
        has_business_cases = False
        has_annual_reviews = False
        
        # Check existing metadata first
        metadata_file = 'data/business_cases_metadata.json'
        # For testing, also check for test metadata
        if not os.path.exists(metadata_file) and os.path.exists('test_metadata.json'):
            metadata_file = 'test_metadata.json'
            
        if os.path.exists(metadata_file):
            try:
                with open(metadata_file, 'r', encoding='utf-8') as f:
                    existing_metadata = json.load(f)
                
                for doc in existing_metadata:
                    if doc.get('programme_id') == programme_id:
                        if doc.get('category') == 'business_case':
                            has_business_cases = True
                        elif doc.get('category') == 'annual_review':
                            has_annual_reviews = True
            except (json.JSONDecodeError, FileNotFoundError):
                pass
        
        # If no metadata, try to guess from filenames
        if not has_business_cases and not has_annual_reviews:
            for filename in files:
                filename_lower = filename.lower()
                if any(keyword in filename_lower for keyword in ['business', 'case', 'statement']):
                    has_business_cases = True
                elif any(keyword in filename_lower for keyword in ['annual', 'review', 'report']):
                    has_annual_reviews = True
            
            # If still can't determine, assume all existing files are business cases
            if not has_business_cases and not has_annual_reviews:
                has_business_cases = True
        
        return {
            'has_business_cases': has_business_cases,
            'has_annual_reviews': has_annual_reviews,
            'has_any': len(files) > 0
        }
    
    def should_process_programme(self, programme_id: str) -> bool:
        """Determine if a programme should be processed based on current settings and existing files."""
        status = self.check_programme_completion_status(programme_id)
        
        # If no files exist, always process
        if not status['has_any']:
            return True
        
        # If we want annual reviews but don't have them, process
        if self.include_annual_reviews and not status['has_annual_reviews']:
            return True
        
        # If we don't have business cases, process
        if not status['has_business_cases']:
            return True
        
        # If we only want business cases and have them, skip
        if not self.include_annual_reviews and status['has_business_cases']:
            return False
        
        # If we want both and have both, skip
        if self.include_annual_reviews and status['has_business_cases'] and status['has_annual_reviews']:
            return False
        
        return True
    
    def extract_documents_from_page(self, html: str, programme_id: str, include_annual_reviews: bool = False) -> List[Dict[str, str]]:
        """Extract business case and optionally annual review documents from a programme's documents page."""
        soup = BeautifulSoup(html, 'html.parser')
        documents = []
        
        # Find all document links - fix the lambda syntax issue
        doc_links = soup.find_all('a', href=True)
        doc_links = [link for link in doc_links if link.get('href') and 'iati.fcdo.gov.uk/iati_documents/' in str(link.get('href'))]
        
        for link in doc_links:
            href = link.get('href')
            title = link.get_text(strip=True)
            
            # Get document type
            doc_type = self.get_document_type(title)
            
            # Check if we should include this document
            should_include = False
            log_type = "unknown"
            if doc_type == 'business_case':
                should_include = True
                log_type = "business case"
            elif doc_type == 'annual_review' and include_annual_reviews:
                should_include = True
                log_type = "annual review"
            
            if should_include:
                # Extract document metadata
                href_str = str(href) if href else ''
                doc_id = href_str.split('/')[-1] if href_str else 'unknown'
                
                # Extract publication date if available
                date_match = re.search(r'\(Published - ([^)]+)\)', title)
                pub_date = date_match.group(1) if date_match else 'Unknown'
                
                # Clean title
                clean_title = re.sub(r'\(Published - [^)]+\)', '', title).strip()
                
                document = {
                    'programme_id': programme_id,
                    'title': clean_title,
                    'url': href,
                    'filename': doc_id,
                    'publication_date': pub_date,
                    'document_type': self._classify_document_type(title),
                    'category': doc_type,  # business_case or annual_review
                    'relationship': 'before' if doc_type == 'business_case' else 'after'
                }
                
                documents.append(document)
                logging.info(f"Found {log_type}: {clean_title[:60]}... ({pub_date})")
        
        return documents
    
    def _classify_document_type(self, title: str) -> str:
        """Classify the specific type of document."""
        title_lower = title.lower()
        
        # Annual review classifications
        if 'annual review' in title_lower:
            return 'Annual Review'
        elif 'annual report' in title_lower:
            return 'Annual Report'
        elif 'project completion review' in title_lower:
            return 'Project Completion Review'
        elif 'programme review' in title_lower:
            return 'Programme Review'
        
        # Business case classifications
        elif 'addendum' in title_lower:
            return 'Addendum to Business Case'
        elif 'statement of need' in title_lower:
            return 'Statement of Need'
        else:
            # Default for business cases or other documents
            return 'Business Case' if self.is_business_case_document(title) else 'Other Document'
    
    def download_document(self, doc: Dict[str, str]) -> bool:
        """Download a document to the documents directory."""
        try:
            url = doc['url']
            programme_id = doc['programme_id']
            filename = doc['filename']
            
            # Create subdirectory for programme
            programme_dir = os.path.join(self.documents_dir, programme_id)
            os.makedirs(programme_dir, exist_ok=True)
            
            # Download file
            filepath = os.path.join(programme_dir, filename)
            
            # Skip if already downloaded
            if os.path.exists(filepath):
                logging.info(f"Document already exists: {filepath}")
                return True
            
            logging.info(f"Downloading: {filename}")
            response = self.get_page(url)
            
            if response:
                with open(filepath, 'wb') as f:
                    f.write(response.content)
                logging.info(f"[OK] Downloaded: {filepath}")
                return True
            else:
                logging.error(f"[FAIL] Failed to download: {filename}")
                return False
                
        except Exception as e:
            logging.error(f"Error downloading {doc.get('filename', 'unknown')}: {e}")
            return False
    
    def scrape_programme_documents(self, programme: Dict[str, str]) -> List[Dict[str, str]]:
        """Scrape business case documents for a single programme."""
        programme_id = programme['id']
        documents_url = programme.get('documents_url', f"{self.base_url}/projects/{programme_id}/documents")
        
        # Show current status
        status = self.check_programme_completion_status(programme_id)
        status_msg = []
        if status['has_business_cases']:
            status_msg.append("has business cases")
        if status['has_annual_reviews']:
            status_msg.append("has annual reviews")
        
        if status_msg:
            logging.info(f"\nProcessing programme: {programme_id} - {programme.get('title', 'Unknown')[:50]}... ({', '.join(status_msg)})")
        else:
            logging.info(f"\nProcessing programme: {programme_id} - {programme.get('title', 'Unknown')[:50]}...")
        
        try:
            response = self.get_page(documents_url)
            if not response:
                return []
            
            documents = self.extract_documents_from_page(response.text, programme_id, self.include_annual_reviews)
            
            if documents:
                # Count by category
                business_cases = [d for d in documents if d.get('category') == 'business_case']
                annual_reviews = [d for d in documents if d.get('category') == 'annual_review']
                
                parts = []
                if business_cases:
                    parts.append(f"{len(business_cases)} business case(s)")
                if annual_reviews:
                    parts.append(f"{len(annual_reviews)} annual review(s)")
                
                logging.info(f"Found {' and '.join(parts)} for {programme_id}")
            else:
                doc_type = "documents" if self.include_annual_reviews else "business case documents"
                logging.info(f"No {doc_type} found for {programme_id}")
            
            return documents
            
        except Exception as e:
            logging.error(f"Error processing programme {programme_id}: {e}")
            return []
    
    def scrape_all_business_cases(self, programmes: List[Dict[str, str]], 
                                   download: bool = True,
                                   max_programmes: Optional[int] = None) -> List[Dict[str, str]]:
        """Scrape business case documents from all programmes."""
        all_documents = []
        
        programmes_to_process = programmes[:max_programmes] if max_programmes else programmes
        total = len(programmes_to_process)
        
        logging.info(f"\nStarting business case scraping for {total} programmes...")
        
        for idx, programme in enumerate(programmes_to_process, 1):
            logging.info(f"\n{'='*60}")
            logging.info(f"Progress: {idx}/{total} ({idx/total*100:.1f}%)")
            
            documents = self.scrape_programme_documents(programme)
            
            if documents and download:
                for doc in documents:
                    success = self.download_document(doc)
                    doc['downloaded'] = 'true' if success else 'false'
            
            all_documents.extend(documents)
            
            # Extra polite: add a small delay between programmes
            if idx < total:
                time.sleep(1)
        
        logging.info(f"\n{'='*60}")
        logging.info(f"[OK] Scraping complete!")
        logging.info(f"[OK] Total business case documents found: {len(all_documents)}")
        if download:
            downloaded_count = sum(1 for doc in all_documents if doc.get('downloaded', False))
            logging.info(f"[OK] Successfully downloaded: {downloaded_count}/{len(all_documents)}")
        
        return all_documents
    
    def save_metadata(self, documents: List[Dict[str, str]], filename: str = 'data/business_cases_metadata.json'):
        """Save document metadata to JSON file."""
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(documents, f, indent=2, ensure_ascii=False)
        logging.info(f"[OK] Saved metadata to {filename}")
    
    def generate_summary(self, documents: List[Dict[str, str]]):
        """Generate a summary report of scraped documents."""
        total = len(documents)
        downloaded = sum(1 for doc in documents if doc.get('downloaded', '') == 'true')
        
        # Count by document type and category
        type_counts = {}
        category_counts = {'business_case': 0, 'annual_review': 0, 'other': 0}
        for doc in documents:
            doc_type = doc.get('document_type', 'Unknown')
            type_counts[doc_type] = type_counts.get(doc_type, 0) + 1
            
            category = doc.get('category', 'other')
            if category in category_counts:
                category_counts[category] += 1
        
        # Count programme relationships
        programme_counts = {}
        programmes_with_both = 0
        for doc in documents:
            prog_id = doc.get('programme_id', 'Unknown')
            if prog_id not in programme_counts:
                programme_counts[prog_id] = {'business_case': 0, 'annual_review': 0}
            
            category = doc.get('category', 'other')
            if category in programme_counts[prog_id]:
                programme_counts[prog_id][category] += 1
        
        # Count programmes with both types
        programmes_with_both = sum(1 for counts in programme_counts.values() 
                                 if counts['business_case'] > 0 and counts['annual_review'] > 0)
        
        summary = {
            'total_documents': total,
            'downloaded': downloaded,
            'documents_by_type': type_counts,
            'documents_by_category': category_counts,
            'programmes_with_documents': len(programme_counts),
            'programmes_with_both_types': programmes_with_both,
            'avg_docs_per_programme': total / len(programme_counts) if programme_counts else 0
        }
        
        # Save summary
        with open('data/scraping_summary.json', 'w', encoding='utf-8') as f:
            json.dump(summary, f, indent=2, ensure_ascii=False)
        
        # Print summary
        print("\n" + "="*60)
        print("SCRAPING SUMMARY")
        print("="*60)
        print(f"Total documents found: {total}")
        print(f"Successfully downloaded: {downloaded}")
        print(f"\nDocuments by category:")
        print(f"  - Business Cases (before): {category_counts['business_case']}")
        print(f"  - Annual Reviews (after): {category_counts['annual_review']}")
        print(f"  - Other documents: {category_counts['other']}")
        print(f"\nDetailed document types:")
        for doc_type, count in type_counts.items():
            print(f"  - {doc_type}: {count}")
        print(f"\nProgrammes with documents: {len(programme_counts)}")
        print(f"Programmes with both business cases AND annual reviews: {programmes_with_both}")
        print(f"Average documents per programme: {summary['avg_docs_per_programme']:.2f}")
        print("="*60)


def main():
    # Load programmes list
    with open('data/fcdo_programmes.json', 'r', encoding='utf-8') as f:
        programmes = json.load(f)
    
    print(f"Loaded {len(programmes)} FCDO programmes")
    
    # Create scraper
    scraper = BusinessCaseScraper()
    
    # Scrape business cases (set max_programmes=10 for testing, None for all)
    documents = scraper.scrape_all_business_cases(
        programmes, 
        download=True,
        max_programmes=None  # Change to a number like 10 for testing
    )
    
    # Save metadata
    scraper.save_metadata(documents)
    
    # Generate summary
    scraper.generate_summary(documents)


if __name__ == "__main__":
    main()
