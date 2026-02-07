# FCDO Business Case Scraper

A polite web scraper to collect all business case and statement of need documents from FCDO (Foreign, Commonwealth and Development Office) programmes on the UK Development Tracker.

## Features

✅ **Polite Scraping**: 
- 2-second delays between requests
- Proper User-Agent headers
- Retry logic with exponential backoff
- Respects server load

✅ **Comprehensive Coverage**:
- Scrapes all 555+ FCDO programmes
- Handles pagination automatically
- Identifies business cases, addendums, and statements of need

✅ **Organized Output**:
- Downloads documents organized by programme ID
- Saves metadata in JSON format
- Generates summary statistics
- Creates detailed logs

✅ **Flexible Options**:
- Test mode for limited scraping
- Skip already-scraped programme lists
- Option to collect metadata without downloading

## Installation

### Prerequisites
- Python 3.7 or higher
- pip (Python package installer)

### Setup

1. **Clone or download this project**
   ```powershell
   cd C:\fcdo-business-case-scraper
   ```

2. **Install required packages**
   ```powershell
   pip install -r requirements.txt
   ```

## Usage

### Basic Usage (Scrape Everything)

```powershell
python main.py
```

This will:
1. Scrape the list of all FCDO programmes (~555 programmes)
2. Visit each programme's documents page
3. Identify and download all business case documents
4. Save metadata and generate a summary report

**Estimated time**: 30-60 minutes depending on your connection

### Command Line Options

#### Skip Programme List Scraping
If you've already scraped the programme list:
```powershell
python main.py --skip-programmes
```

#### Metadata Only (No Downloads)
To find business cases without downloading:
```powershell
python main.py --no-download
```

#### Include Annual Reviews
To also scrape annual review documents (linked to business cases):
```powershell
python main.py --include-annual-reviews
```

#### Test Mode
To test with just the first 10 programmes:
```powershell
python main.py --max-programmes 10
```

#### Combined Options
```powershell
python main.py --skip-programmes --max-programmes 50 --include-annual-reviews
```

### Help
```powershell
python main.py --help
```

## Output Structure

```
fcdo-business-case-scraper/
├── data/
│   ├── fcdo_programmes.json           # List of all FCDO programmes
│   ├── business_cases_metadata.json   # Metadata of all business cases found
│   ├── scraping_summary.json          # Summary statistics
│   └── scraper_YYYYMMDD_HHMMSS.log   # Detailed log file
├── documents/
│   ├── GB-1-204324/                   # Programme ID folder
│   │   ├── D0006484.odt              # Business case documents
│   │   └── 4221301.odt
│   ├── GB-GOV-1-300801/
│   │   └── ...
│   └── ...
└── ...
```

## Output Files

### 1. `fcdo_programmes.json`
Contains all FCDO programmes with their IDs, titles, and URLs.

Example:
```json
[
  {
    "id": "GB-1-204324",
    "title": "Raising Learning Outcomes (RLO)",
    "url": "https://devtracker.fcdo.gov.uk/projects/GB-1-204324/summary",
    "documents_url": "https://devtracker.fcdo.gov.uk/projects/GB-1-204324/documents"
  }
]
```

### 2. `business_cases_metadata.json`
Metadata for all business case documents found.

Example:
```json
[
  {
    "programme_id": "GB-1-204324",
    "title": "Addendum to the Business Case (D0006484) 204324",
    "url": "https://iati.fcdo.gov.uk/iati_documents/D0006484.odt",
    "filename": "D0006484.odt",
    "publication_date": "January 2025",
    "document_type": "Addendum to Business Case",
    "downloaded": true
  }
]
```

### 3. `scraping_summary.json`
Summary statistics of the scraping operation.

Example:
```json
{
  "total_documents": 487,
  "downloaded": 485,
  "documents_by_type": {
    "Business Case": 234,
    "Addendum to Business Case": 198,
    "Statement of Need": 55
  },
  "programmes_with_business_cases": 312,
  "avg_docs_per_programme": 1.56
}
```

## Document Types Identified

The scraper looks for the following types of documents:

### Business Case Documents (Before):
- **Business Case**: Original project approval documents
- **Addendum to Business Case**: Updates and amendments
- **Statement of Need**: Alternative format for project justification
- **Business Case and Summary**: Combined documentation

### Annual Review Documents (After) - Optional:
- **Annual Review**: Yearly progress assessments
- **Annual Report**: Annual monitoring reports
- **Project Completion Review**: Final project evaluations
- **Programme Review**: Comprehensive programme assessments

**Document Relationships**: Business cases represent the "before" state (project planning), while annual reviews represent the "after" state (project outcomes). Both are linked by the same programme ID.

## Polite Scraping Features

This scraper follows web scraping best practices:

1. **Rate Limiting**: 2-second delay between requests
2. **Proper User-Agent**: Identifies itself as a research bot
3. **Retry Logic**: Handles temporary failures gracefully
4. **Error Handling**: Logs errors and continues with remaining programmes
5. **Respectful**: Does not overwhelm the server

## Troubleshooting

### Import Errors
If you see import errors when running the script:
```powershell
pip install --upgrade requests beautifulsoup4
```

### Connection Errors
If you encounter frequent connection errors:
- Check your internet connection
- The FCDO server might be temporarily unavailable
- Try again later or use the `--skip-programmes` option if you already have the programme list

### Timeout Errors
If requests timeout frequently:
- Increase the delay by editing `self.delay` in the scraper files
- Check if you need to configure proxy settings

## Ethical Considerations

This tool is designed for:
- ✅ Academic research
- ✅ Transparency and accountability research
- ✅ Policy analysis
- ✅ Non-commercial use

Please ensure your use complies with:
- UK Government Open Data Licence
- FCDO website terms of use
- Ethical web scraping practices

## Technical Details

### Technologies Used
- **Python 3**: Core programming language
- **Requests**: HTTP library for making web requests
- **BeautifulSoup4**: HTML parsing and data extraction

### Scraping Strategy
1. First, scrape the FCDO department page to get all programme IDs
2. Handle pagination to collect all 555+ programmes
3. For each programme, visit its documents page
4. Extract links to business case documents using keyword matching
5. Download documents with proper error handling
6. Save metadata and generate reports

### Keywords for Business Case Detection
- "business case"
- "addendum to the business case"
- "statement of need"
- "business case and summary"
- "project business case"
- "programme business case"

## Examples

### Example 1: Quick Test Run
```powershell
# Test with 5 programmes to see how it works
python main.py --max-programmes 5
```

### Example 2: Full Scrape
```powershell
# Scrape everything (will take 30-60 minutes)
python main.py
```

### Example 3: Update Existing Data
```powershell
# If you already have programme list, just get new documents
python main.py --skip-programmes
```

### Example 4: Metadata Collection Only
```powershell
# Find all business cases but don't download
python main.py --no-download
```

## Support

For issues or questions:
1. Check the log files in `data/` directory
2. Review the `scraping_summary.json` for statistics
3. Look at the console output for error messages

## License

This tool is provided for research and educational purposes. All scraped data is subject to the UK Government's Open Government Licence v3.0.

The scraped documents remain Crown Copyright.

## Acknowledgments

Data source: [UK Development Tracker](https://devtracker.fcdo.gov.uk/) - FCDO

---

**Last Updated**: October 2025
