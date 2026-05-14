# Jikan scripts

## generate_specification.py

Generates a Danish-language time specification (timespecifikation) as an HTML file from a Jikan backup JSON. The HTML can be printed or exported to PDF with WeasyPrint.

### Requirements

Python 3.12+ (no third-party dependencies). Uses [uv](https://github.com/astral-sh/uv) for environment management.

WeasyPrint for PDF export:

```
pip install weasyprint
```

### Usage

```
python generate_specification.py BACKUP.json [options]
```

Place generated output in the `output/` folder (gitignored).

### Options

| Flag | Default | Description |
|------|---------|-------------|
| `--client` | | Filter by client name |
| `--project` | | Filter by project name |
| `--month` | | Filter by month, format `YYYY-MM` |
| `--from` | | Start date `YYYY-MM-DD` |
| `--to` | | End date `YYYY-MM-DD` |
| `--consultant` | Thomas Ringling | Consultant name shown in the spec |
| `--seller` | Thomas Ringling | Sender / company name |
| `--seller-addr` | Nærum Hovedgade 15 st th D, 2850 Nærum | Sender address |
| `--seller-cvr` | 27 63 45 91 | Sender CVR number |
| `--client-name` | from data | Override client name |
| `--client-addr` | from data | Override client address |
| `--client-cvr` | from data | Override client CVR number |
| `--rate` | 925.0 | Hourly rate in DKK (for summary display) |
| `--invoice-no` | | Invoice number (shown as placeholder if omitted) |
| `--include-nonbillable` | | Include non-billable entries (default: billable only) |
| `--out` | timespecifikation.html | Output file path |

Client address and CVR are read automatically from the backup if the client was saved with those fields in Jikan.

### Example

```bash
python generate_specification.py output/backup.json \
    --client "PFA" \
    --project "Varslinger" \
    --month 2026-05 \
    --invoice-no 2026-05 \
    --out output/timespec-pfa-maj-2026.html
```

Export to PDF with WeasyPrint:

```bash
weasyprint output/timespec-pfa-maj-2026.html output/timespec-pfa-maj-2026.pdf
```
