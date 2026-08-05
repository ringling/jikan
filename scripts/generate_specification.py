#!/usr/bin/env python3
"""
Generér en timespecifikation (HTML) ud fra et Jikan backup-JSON.

Brug:
    python3 generate_specifikation.py BACKUP.json [valgmuligheder]

Eksempel:
    python3 generate_specifikation.py jikan_backup.json \
        --client PFA --project Varslinger --month 2026-04 \
        --consultant "Thomas Ringling" --rate 925 \
        --out timespecifikation-pfa-april.html

Scriptet:
  - læser alle poster fra Jikan-backuppen
  - filtrerer på klient, projekt og/eller måned (alle valgfrie)
  - omregner start/sluttider fra UTC (Zulu) til dansk tid (Europe/Copenhagen)
  - beregner arbejdstid som (slut - start - pause)
  - grupperer dagene på ISO-ugenummer med delsum pr. uge
  - skriver en færdig HTML-fil med samme layout som den oprindelige spec

Beløb pr. dag tages fra Jikan-feltet 'total_amount' (uændret).
"""

import argparse
import datetime
import html
import json
import sys
from collections import defaultdict
from zoneinfo import ZoneInfo

CPH = ZoneInfo("Europe/Copenhagen")

DA_WEEKDAYS = ["man.", "tir.", "ons.", "tor.", "fre.", "lør.", "søn."]
DA_MONTHS = [
    "", "jan.", "feb.", "mar.", "apr.", "maj", "jun.",
    "jul.", "aug.", "sep.", "okt.", "nov.", "dec.",
]
DA_MONTHS_LONG = [
    "", "januar", "februar", "marts", "april", "maj", "juni",
    "juli", "august", "september", "oktober", "november", "december",
]


# ---------------------------------------------------------------- helpers

def dkk(value: float) -> str:
    """Formatér et tal som dansk valuta: 1234567.5 -> '1.234.567,50'."""
    s = f"{value:,.2f}"
    return s.replace(",", "X").replace(".", ",").replace("X", ".")


def hours(value: float) -> str:
    """Formatér timer med komma som decimaltegn: 7.75 -> '7,75'."""
    return f"{value:.2f}".replace(".", ",")


def hm(minutes: int) -> str:
    """Minutter -> 'H:MM'."""
    return f"{minutes // 60}:{minutes % 60:02d}"


def da_date(d: datetime.date) -> str:
    """date -> 'man. 7. apr.'"""
    return f"{DA_WEEKDAYS[d.weekday()]} {d.day}. {DA_MONTHS[d.month]}"


def parse_entry(raw: dict) -> dict:
    """Udtræk og beregn de felter vi har brug for fra en Jikan-post.

    Håndterer det nye Jikan-format:
      - poster der krydser midnat (sluttid < starttid) -> +24 t
      - hourly_rate / total_amount kan være null
      - client kan indeholde address / cvr / contact_email
    """
    date = datetime.date.fromisoformat(raw["date"])

    # Start/slut er klokkeslæt i UTC. Kombinér med datoen og omregn til CPH.
    start_utc = datetime.datetime.fromisoformat(
        f"{raw['date']}T{raw['start_time']}+00:00"
    )
    end_utc = datetime.datetime.fromisoformat(
        f"{raw['date']}T{raw['end_time']}+00:00"
    )

    # Natpost: hvis sluttid ligger før eller på starttid, fortsætter arbejdet
    # ind i næste døgn -> læg 24 timer til sluttidspunktet.
    crosses_midnight = end_utc <= start_utc
    if crosses_midnight:
        end_utc += datetime.timedelta(days=1)

    start_cph = start_utc.astimezone(CPH)
    end_cph = end_utc.astimezone(CPH)

    span_min = int((end_utc - start_utc).total_seconds() // 60)
    pause_min = int(raw.get("pause_duration_minutes", 0) or 0)
    work_min = span_min - pause_min

    # total_amount / hourly_rate kan være null i det nye format.
    raw_amount = raw.get("total_amount")
    amount = float(raw_amount) if raw_amount is not None else 0.0
    amount_missing = raw_amount is None

    raw_rate = raw.get("hourly_rate")
    rate = float(raw_rate) if raw_rate is not None else None

    client = raw.get("client", {})

    return {
        "date": date,
        "iso_week": date.isocalendar()[1],
        "start": start_cph.strftime("%H:%M"),
        "end": end_cph.strftime("%H:%M"),
        "pause_min": pause_min,
        "work_min": work_min,
        "work_hours": work_min / 60,
        "amount": amount,
        "amount_missing": amount_missing,
        "crosses_midnight": crosses_midnight,
        "billable": bool(raw.get("billable", True)),
        "client": client.get("name", ""),
        "client_address": client.get("address"),
        "client_cvr": client.get("cvr"),
        "project": raw.get("project", {}).get("name", ""),
        "rate": rate,
    }


# ---------------------------------------------------------------- html

CSS = """
  :root {
    --ink: #1E1E1E; --muted: #5f6b6b; --line: #d8dede;
    --accent: #016168; --soft: #F8F8F8; --tint: #eef3f3;
  }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  html, body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
    color: var(--ink); background: #fff; font-size: 15px; line-height: 1.6;
  }
  .page {
    max-width: 880px; margin: 32px auto; background: #fff;
    padding: 56px 60px;
  }
  .head {
    display: flex; justify-content: space-between; align-items: flex-start;
    border-bottom: 3px solid var(--accent); padding-bottom: 24px;
  }
  .seller h1 { font-size: 20px; font-weight: 700; letter-spacing: .2px; }
  .seller p { color: var(--muted); font-size: 14px; }
  .doc-title { text-align: right; }
  .doc-title .word {
    font-size: 26px; font-weight: 700; color: var(--accent); letter-spacing: .5px;
  }
  .doc-title .num { color: var(--muted); font-size: 14px; margin-top: 4px; }
  .meta { display: flex; justify-content: space-between; gap: 40px; margin: 34px 0 10px; }
  .meta .block { flex: 1; }
  .meta h2 {
    font-size: 11px; text-transform: uppercase; letter-spacing: 1.2px;
    color: var(--muted); margin-bottom: 8px;
  }
  .meta .block p { font-size: 14px; }
  .meta .block strong { font-weight: 700; }
  .summary {
    display: flex; margin: 18px 0 30px; background: var(--soft);
    border-radius: 6px; overflow: hidden;
  }
  .summary div { flex: 1; padding: 16px 20px; border-right: 1px solid var(--line); }
  .summary div:last-child { border-right: none; }
  .summary span {
    display: block; text-transform: uppercase; letter-spacing: 1px;
    color: var(--muted); font-size: 10px; margin-bottom: 2px;
  }
  .summary strong { font-size: 17px; font-weight: 700; }
  table { width: 100%; border-collapse: collapse; margin-top: 8px; }
  thead th {
    text-align: left; font-size: 11px; text-transform: uppercase;
    letter-spacing: .6px; color: #fff; background: var(--accent); padding: 11px 12px;
  }
  thead th.num, tbody td.num, tfoot td.num { text-align: right; }
  tbody td { padding: 9px 12px; border-bottom: 1px solid var(--line); font-size: 13.5px; }
  tbody tr:nth-child(even) { background: var(--soft); }
  tfoot td {
    font-weight: 700; border-top: 2px solid var(--accent);
    padding: 12px; font-size: 13.5px;
  }
  tr.week-head td {
    background: var(--tint); font-weight: 700; font-size: 11px;
    text-transform: uppercase; letter-spacing: 1px; color: var(--accent); padding: 8px 12px;
  }
  tr.week-sub td {
    border-bottom: 2px solid var(--accent); font-weight: 700;
    font-size: 12.5px; color: var(--muted); padding: 8px 12px;
  }
  tr.week-sub td.num { text-align: right; }
  footer {
    margin-top: 40px; padding-top: 18px; border-top: 1px solid var(--line);
    text-align: center; font-size: 12px; color: var(--muted);
  }
  .ph {
    background: #fff3cd; border-bottom: 1px dashed #d0a000;
    padding: 0 3px; font-style: italic;
  }
  .tag {
    display: inline-block; margin-left: 6px; font-size: 11px;
    color: #b45309; background: #fef3c7; padding: 1px 6px; border-radius: 3px;
  }
  .actions { max-width: 880px; margin: 0 auto 0; text-align: right; }
  .actions button {
    font: inherit; font-weight: 600; color: #fff; background: var(--accent);
    border: none; padding: 10px 22px; border-radius: 6px; cursor: pointer;
  }
  .actions button:hover { background: #014c52; }
  @media print {
    .actions { display: none; }
    .page { margin: 0; max-width: none; padding: 0; }
  }
"""


def esc(text: str) -> str:
    return html.escape(str(text))


def build_html(entries, *, seller, seller_addr, seller_cvr, consultant,
               client_name, client_addr, client_cvr, project, period_label,
               rate_label, invoice_no):
    """Saml den færdige HTML-streng."""
    entries = sorted(entries, key=lambda e: e["date"])

    # Gruppér på ISO-ugenummer
    weeks = defaultdict(list)
    for e in entries:
        weeks[e["iso_week"]].append(e)

    total_work_min = sum(e["work_min"] for e in entries)
    total_pause_min = sum(e["pause_min"] for e in entries)
    total_amount = sum(e["amount"] for e in entries)
    n_days = len(entries)

    rows = []
    for wk in sorted(weeks):
        wk_entries = sorted(weeks[wk], key=lambda e: e["date"])
        first, last = wk_entries[0]["date"], wk_entries[-1]["date"]
        wk_label = (
            f"Uge {wk} &middot; {first.day}. {DA_MONTHS_LONG[first.month]} "
            f"&ndash; {last.day}. {DA_MONTHS_LONG[last.month]}"
        )
        rows.append(f'      <tr class="week-head"><td colspan="6">{wk_label}</td></tr>')

        for e in wk_entries:
            tags = ""
            if e["crosses_midnight"]:
                tags += '<span class="tag">natpost +24t</span>'
            if e["amount_missing"]:
                tags += '<span class="tag">beløb mangler</span>'
            rows.append(
                f'      <tr><td>{esc(da_date(e["date"]))}{tags}</td>'
                f'<td>{e["start"]}</td><td>{e["end"]}</td>'
                f'<td class="num">{hm(e["pause_min"])}</td>'
                f'<td class="num">{hours(e["work_hours"])}</td>'
                f'<td class="num">{dkk(e["amount"])}</td></tr>'
            )

        wk_work = sum(e["work_min"] for e in wk_entries)
        wk_pause = sum(e["pause_min"] for e in wk_entries)
        wk_amt = sum(e["amount"] for e in wk_entries)
        rows.append(
            f'      <tr class="week-sub"><td colspan="3">Uge {wk} i alt '
            f'&mdash; {len(wk_entries)} dage</td>'
            f'<td class="num">{hm(wk_pause)}</td>'
            f'<td class="num">{hours(wk_work / 60)}</td>'
            f'<td class="num">{dkk(wk_amt)}</td></tr>'
        )
        rows.append("")  # blank line between weeks

    table_body = "\n".join(rows).rstrip()

    invoice_ref = (
        esc(invoice_no) if invoice_no
        else '<span class="ph">[FAKTURANUMMER]</span>'
    )
    client_block = (
        f"<strong>{esc(client_name)}</strong><br>{esc(client_addr)}<br>"
        f"CVR: {esc(client_cvr)}"
    )

    return f"""<!DOCTYPE html>
<html lang="da">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Timespecifikation &mdash; {esc(client_name)} / {esc(project)} &mdash; {esc(period_label)}</title>
<style>{CSS}</style>
</head>
<body>

<div class="actions">
  <button onclick="window.print()">Print / Gem som PDF</button>
</div>

<div class="page">

  <div class="head">
    <div class="seller">
      <h1>{esc(seller)}</h1>
      <p>{esc(seller_addr).replace(chr(10), '<br>')}<br>CVR: {esc(seller_cvr)}</p>
    </div>
    <div class="doc-title">
      <div class="word">TIMESPECIFIKATION</div>
      <div class="num">Bilag til faktura {invoice_ref}</div>
    </div>
  </div>

  <div class="meta">
    <div class="block">
      <h2>Kunde</h2>
      <p>{client_block}</p>
    </div>
    <div class="block">
      <h2>Opgave</h2>
      <p>
        Projekt: <strong>{esc(project)}</strong><br>
        Periode: {esc(period_label)}<br>
        Konsulent: {esc(consultant)}
      </p>
    </div>
  </div>

  <div class="summary">
    <div><span>Arbejdsdage</span><strong>{n_days}</strong></div>
    <div><span>Arbejdstimer</span><strong>{hours(total_work_min / 60)}</strong></div>
    <div><span>Timesats</span><strong>{esc(rate_label)}</strong></div>
    <div><span>I alt ekskl. moms</span><strong>{dkk(total_amount)} kr</strong></div>
  </div>

  <table>
    <thead>
      <tr>
        <th>Dato</th>
        <th>Start</th>
        <th>Slut</th>
        <th class="num">Pause</th>
        <th class="num">Arbejdstid</th>
        <th class="num">Beløb (DKK)</th>
      </tr>
    </thead>
    <tbody>
{table_body}
    </tbody>
    <tfoot>
      <tr>
        <td colspan="3">I alt &mdash; {n_days} dage</td>
        <td class="num">{hm(total_pause_min)}</td>
        <td class="num">{hours(total_work_min / 60)}</td>
        <td class="num">{dkk(total_amount)}</td>
      </tr>
    </tfoot>
  </table>

  <footer>
    {esc(seller)} &middot; {esc(seller_addr).replace(chr(10), ' &middot; ')} &middot; CVR {esc(seller_cvr)}
  </footer>

</div>

</body>
</html>
"""


# ---------------------------------------------------------------- main

def main(argv=None):
    p = argparse.ArgumentParser(
        description="Generér en timespecifikation (HTML) fra et Jikan backup-JSON."
    )
    p.add_argument("backup", help="Sti til Jikan backup-JSON")
    p.add_argument("--client", help="Filtrér på klientnavn (fx PFA)")
    p.add_argument("--project", help="Filtrér på projektnavn (fx Varslinger)")
    p.add_argument("--month", help="Filtrér på måned, format ÅÅÅÅ-MM (fx 2026-04)")
    p.add_argument("--from", dest="date_from", help="Startdato ÅÅÅÅ-MM-DD (valgfri)")
    p.add_argument("--to", dest="date_to", help="Slutdato ÅÅÅÅ-MM-DD (valgfri)")
    p.add_argument("--consultant", default="Thomas Ringling", help="Konsulentens navn")
    p.add_argument("--seller", default="Thomas Ringling", help="Afsender / firmanavn")
    p.add_argument("--seller-addr", default="Nærum Hovedgade 15 st th D\n2850 Nærum",
                   help="Afsenderadresse (brug \\n for linjeskift)")
    p.add_argument("--seller-cvr", default="27 63 45 91", help="Afsenders CVR-nummer")
    p.add_argument("--client-name", default=None,
                   help="Kundens juridiske navn (ellers fra data)")
    p.add_argument("--client-addr", default=None,
                   help="Kundens adresse (ellers fra data)")
    p.add_argument("--client-cvr", default=None,
                   help="Kundens CVR-nummer (ellers fra data)")
    p.add_argument("--rate", type=float, default=925.0, help="Timesats i kr")
    p.add_argument("--invoice-no", default="", help="Fakturanummer (valgfrit)")
    p.add_argument("--include-nonbillable", action="store_true",
                   help="Tag også ikke-fakturerbare poster med (default: kun billable=true)")
    p.add_argument("--out", default="timespecifikation.html", help="Outputfil")
    args = p.parse_args(argv)

    try:
        with open(args.backup, encoding="utf-8") as fh:
            raw_data = json.load(fh)
    except (OSError, json.JSONDecodeError) as exc:
        print(f"Kunne ikke læse backup-filen: {exc}", file=sys.stderr)
        return 1

    entries = [parse_entry(r) for r in raw_data]

    # Kun fakturerbare poster, medmindre --include-nonbillable er angivet.
    n_total = len(entries)
    if not args.include_nonbillable:
        entries = [e for e in entries if e["billable"]]
        n_dropped = n_total - len(entries)
        if n_dropped:
            print(f"Info: {n_dropped} ikke-fakturerbare poster udeladt "
                  f"(brug --include-nonbillable for at tage dem med).",
                  file=sys.stderr)

    # Filtrér
    if args.client:
        entries = [e for e in entries if e["client"].lower() == args.client.lower()]
    if args.project:
        entries = [e for e in entries if e["project"].lower() == args.project.lower()]
    if args.month:
        entries = [e for e in entries if e["date"].strftime("%Y-%m") == args.month]
    if args.date_from:
        d0 = datetime.date.fromisoformat(args.date_from)
        entries = [e for e in entries if e["date"] >= d0]
    if args.date_to:
        d1 = datetime.date.fromisoformat(args.date_to)
        entries = [e for e in entries if e["date"] <= d1]

    if not entries:
        print("Ingen poster matchede filtrene — tjek --client/--project/--month.",
              file=sys.stderr)
        return 1

    # Kundens oplysninger: brug --client-* hvis angivet, ellers fra data.
    client_name = args.client_name or entries[0]["client"] or "[Kundenavn]"
    client_addr = (args.client_addr or entries[0]["client_address"]
                   or "[Kundeadresse]")
    client_cvr = (args.client_cvr or entries[0]["client_cvr"] or "[CVR-nr.]")

    # Advarsel hvis posterne har forskellige kunder.
    distinct_clients = {e["client"] for e in entries if e["client"]}
    if len(distinct_clients) > 1:
        print(f"Advarsel: posterne dækker flere kunder ({sorted(distinct_clients)}). "
              f"Brug --client for at vælge én.", file=sys.stderr)

    # Periodelabel
    if args.month:
        y, m = args.month.split("-")
        period_label = f"{DA_MONTHS_LONG[int(m)]} {y}"
    else:
        d0 = min(e["date"] for e in entries)
        d1 = max(e["date"] for e in entries)
        period_label = f"{da_date(d0)} – {da_date(d1)}"

    # Timesats-label: brug --rate (brugerens angivne sats).
    # Advarsler til stderr hvis poster afviger fra den angivne sats.
    rate_label = f"{dkk(args.rate)} kr"
    mismatched = [
        e for e in entries
        if e["rate"] is not None and abs(e["rate"] - args.rate) > 0.01
    ]
    if mismatched:
        print(f"Advarsel: {len(mismatched)} poster har en anden timesats end {dkk(args.rate)} kr:",
              file=sys.stderr)
        for e in mismatched:
            print(f"  {da_date(e['date'])}  {dkk(e['rate'])} kr", file=sys.stderr)

    # Advarsel hvis nogle poster mangler beløb.
    n_missing = sum(1 for e in entries if e["amount_missing"])
    if n_missing:
        print(f"Advarsel: {n_missing} poster mangler total_amount og vises "
              f"med 0,00 (markeret i tabellen).", file=sys.stderr)

    output = build_html(
        entries,
        seller=args.seller,
        seller_addr=args.seller_addr,
        seller_cvr=args.seller_cvr,
        consultant=args.consultant,
        client_name=client_name,
        client_addr=client_addr,
        client_cvr=client_cvr,
        project=args.project or entries[0]["project"],
        period_label=period_label,
        rate_label=rate_label,
        invoice_no=args.invoice_no,
    )

    try:
        with open(args.out, "w", encoding="utf-8") as fh:
            fh.write(output)
    except OSError as exc:
        print(f"Kunne ikke skrive outputfilen: {exc}", file=sys.stderr)
        return 1

    total_work = sum(e["work_min"] for e in entries) / 60
    total_amt = sum(e["amount"] for e in entries)
    print(f"OK: {args.out}")
    print(f"  {len(entries)} dage, {hours(total_work)} arbejdstimer, "
          f"{dkk(total_amt)} kr ekskl. moms")
    return 0


if __name__ == "__main__":
    sys.exit(main())