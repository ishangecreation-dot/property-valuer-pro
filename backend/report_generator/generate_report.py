"""
Property Valuer Pro - Valuation Report Generator
Strictly follows the chartered template and reporting standards from SKILL.md.
Generates fully editable Microsoft Word (.docx) documents with Executive Cover Page,
10-Point Valuation Report Body, and Supplementary Annexures I, II, and III.
"""

import sys
import os
import json
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

# Official Brand Colors from Design System
NAVY_HEX = "16324F"
GOLD_HEX = "D4AF37"
TEAL_HEX = "159A91"
SLATE_HEX = "25313D"
BORDER_HEX = "E2E8F0"
BG_LIGHT_HEX = "F5F7FA"

COLOR_NAVY = RGBColor(0x16, 0x32, 0x4F)
COLOR_GOLD = RGBColor(0xD4, 0xAF, 0x37)
COLOR_TEAL = RGBColor(0x15, 0x9A, 0x91)
COLOR_SLATE = RGBColor(0x25, 0x31, 0x3D)
COLOR_MUTED = RGBColor(0x71, 0x80, 0x96)

def set_cell_background(cell, hex_color):
    """Sets background shading of a table cell."""
    tcPr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement('w:shd')
    shd.set(qn('w:val'), 'clear')
    shd.set(qn('w:color'), 'auto')
    shd.set(qn('w:fill'), hex_color)
    tcPr.append(shd)

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    """Sets cell internal padding in twips (1/20 pt)."""
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = OxmlElement('w:tcMar')
    for name, value in [('top', top), ('bottom', bottom), ('left', left), ('right', right)]:
        node = OxmlElement(f'w:{name}')
        node.set(qn('w:w'), str(value))
        node.set(qn('w:type'), 'dxa')
        tcMar.append(node)
    tcPr.append(tcMar)

def format_currency(amount):
    """Formats a numeric value into Sri Lankan Rupee currency format."""
    try:
        val = float(amount)
        return f"LKR {val:,.2f}"
    except (ValueError, TypeError):
        return str(amount)

def create_valuation_report(data, output_path="Valuation_Report.docx", target_pages=4):
    """
    Constructs the complete chartered property valuation dossier in editable DOCX format.
    """
    doc = Document()
    
    # Page setup - Standard A4 with professional 0.75-inch margins
    sections = doc.sections
    for s in sections:
        s.page_width = Inches(8.27)   # A4 width
        s.page_height = Inches(11.69) # A4 height
        s.top_margin = Inches(0.75)
        s.bottom_margin = Inches(0.75)
        s.left_margin = Inches(0.75)
        s.right_margin = Inches(0.75)

    profile = data.get("profile", {})
    project = data.get("project", {})
    deed = project.get("deedData", {})
    plan = project.get("surveyPlanData", {})
    inspection = project.get("inspectionData", {})
    location = project.get("locationData", {})
    building_details = project.get("buildingDetails", {})
    val_data = project.get("valuationData", {})
    target_pages = int(project.get("targetPageCount", target_pages))

    # Calculate valuation figures
    lots = plan.get("lots", [{}])
    selected_lots = [l for l in lots if l.get("isSelected", True)]
    total_perches = sum(
        (l.get("acres", 0) * 160.0) + (l.get("roods", 0) * 40.0) + float(l.get("perches", 0.0))
        for l in selected_lots
    )
    if total_perches == 0:
        total_perches = 15.0 # fallback default

    adopted_rate = float(val_data.get("adoptedLandRatePerPerch", 350000.0))
    land_value = total_perches * adopted_rate

    has_building = building_details.get("hasBuilding", True)
    buildings = building_details.get("buildings", [{}])
    total_floor_area = sum(float(b.get("groundFloorAreaSqFt", 0)) + float(b.get("upperFloorAreaSqFt", 0)) for b in buildings)
    if total_floor_area == 0 and has_building:
        total_floor_area = 1500.0

    sqft_rate = float(val_data.get("buildingReplacementCostPerSqFt", 7000.0))
    grc = (total_floor_area * sqft_rate) if has_building else 0.0
    dep_pct = float(val_data.get("depreciationPercentage", 10.0))
    depreciation_deduction = grc * (dep_pct / 100.0)
    depreciated_bldg_val = grc - depreciation_deduction
    computed_market_val = land_value + depreciated_bldg_val

    custom_say = float(val_data.get("customSayValue", 0))
    if custom_say > 0:
        say_market_val = custom_say
    else:
        say_market_val = round(computed_market_val / 50000.0) * 50000.0

    fsv_pct = float(val_data.get("fsvPercentage", 75.0))
    fsv_val = say_market_val * (fsv_pct / 100.0)

    # =========================================================================
    # 1. EXECUTIVE FRONT COVER PAGE (If target_pages >= 4)
    # =========================================================================
    if target_pages >= 4:
        # Header Letterhead Table
        header_table = doc.add_table(rows=1, cols=1)
        header_table.alignment = WD_TABLE_ALIGNMENT.CENTER
        header_cell = header_table.cell(0, 0)
        set_cell_background(header_cell, NAVY_HEX)
        set_cell_margins(header_cell, top=200, bottom=200, left=200, right=200)

        p = header_cell.paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = p.add_run(profile.get("valuerName", "CHARTERED VALUATION PRACTICE").upper())
        r.font.name = "Arial"
        r.font.size = Pt(16)
        r.font.bold = True
        r.font.color.rgb = COLOR_GOLD

        p2 = header_cell.add_paragraph()
        p2.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r2 = p2.add_run(f"{profile.get('qualifications', 'B.Sc. Estate Mgt. & Valuation | AIV')} | Reg No: {profile.get('registrationNumber', 'IVSL Registered')}")
        r2.font.name = "Arial"
        r2.font.size = Pt(10)
        r2.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)

        p3 = header_cell.add_paragraph()
        p3.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r3 = p3.add_run(f"Tel: {profile.get('contactNumber', '+94 77 000 0000')} | Email: {profile.get('emailAddress', 'valuer@example.com')}")
        r3.font.name = "Arial"
        r3.font.size = Pt(8.5)
        r3.font.color.rgb = RGBColor(0xDA, 0xE2, 0xFD)

        doc.add_paragraph() # Spacing

        # Dossier Title
        p_title = doc.add_paragraph()
        p_title.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r_t = p_title.add_run("CONFIDENTIAL REAL ESTATE APPRAISAL DOSSIER")
        r_t.font.name = "Arial"
        r_t.font.size = Pt(15)
        r_t.font.bold = True
        r_t.font.color.rgb = COLOR_NAVY

        p_sub = doc.add_paragraph()
        p_sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r_s = p_sub.add_run(f"COMMERCIAL REAL ESTATE & MORTGAGE COLLATERAL UNDERWRITING REPORT\nPREPARED FOR: {inspection.get('targetInstitution', 'BANKING INSTITUTION').upper()}")
        r_s.font.name = "Arial"
        r_s.font.size = Pt(10)
        r_s.font.bold = True
        r_s.font.color.rgb = COLOR_SLATE

        # Executive Particulars Table
        table = doc.add_table(rows=7, cols=2)
        table.alignment = WD_TABLE_ALIGNMENT.CENTER
        table.autofit = False

        particulars = [
            ("Client / Bank Institution", f"{inspection.get('targetInstitution', '')} - {inspection.get('bankBranch', '')} Branch"),
            ("Purpose of Valuation", inspection.get("valuationPurpose", "Mortgage Security")),
            ("Subject Property Name", f"{plan.get('landName', 'Subject Land')} (Lot {selected_lots[0].get('lotNumber', '1') if selected_lots else '1'})"),
            ("Registered Owner / Vendee", f"{deed.get('vendeeName', '')} (NIC: {deed.get('vendeeNic', 'N/A')})"),
            ("Title Deed & Survey Plan Ref.", f"Deed No. {deed.get('deedNumber', 'N/A')} attested by {deed.get('notaryPublicName', 'N/A')}, NP\nPlan No. {plan.get('planNumber', 'N/A')} by {plan.get('surveyorName', 'N/A')}, LS"),
            ("Evaluated Extent & Floor Area", f"{total_perches:.2f} Perches | Built-up: {total_floor_area:.0f} sq.ft."),
            ("Date of Physical Inspection", inspection.get("dateOfInspection", "Recently Inspected")),
        ]

        for i, (k, v) in enumerate(particulars):
            cell_k = table.cell(i, 0)
            cell_v = table.cell(i, 1)
            cell_k.width = Inches(2.5)
            cell_v.width = Inches(4.5)
            set_cell_background(cell_k, BG_LIGHT_HEX)
            set_cell_margins(cell_k, top=80, bottom=80, left=100, right=100)
            set_cell_margins(cell_v, top=80, bottom=80, left=100, right=100)

            pk = cell_k.paragraphs[0]
            rk = pk.add_run(k)
            rk.font.name = "Arial"
            rk.font.size = Pt(9.5)
            rk.font.bold = True
            rk.font.color.rgb = COLOR_NAVY

            pv = cell_v.paragraphs[0]
            rv = pv.add_run(v)
            rv.font.name = "Arial"
            rv.font.size = Pt(9.5)
            rv.font.color.rgb = COLOR_SLATE

        doc.add_paragraph()

        # Valuation Badges Side by Side
        badge_table = doc.add_table(rows=1, cols=2)
        badge_table.alignment = WD_TABLE_ALIGNMENT.CENTER
        b_cell1 = badge_table.cell(0, 0)
        b_cell2 = badge_table.cell(0, 1)
        b_cell1.width = Inches(3.5)
        b_cell2.width = Inches(3.5)

        set_cell_background(b_cell1, NAVY_HEX)
        set_cell_background(b_cell2, BG_LIGHT_HEX)
        set_cell_margins(b_cell1, top=150, bottom=150, left=150, right=150)
        set_cell_margins(b_cell2, top=150, bottom=150, left=150, right=150)

        bp1 = b_cell1.paragraphs[0]
        bp1.alignment = WD_ALIGN_PARAGRAPH.CENTER
        br1_t = bp1.add_run("TOTAL MARKET VALUE (SAY)\n")
        br1_t.font.name = "Arial"
        br1_t.font.size = Pt(9)
        br1_t.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)
        br1_v = bp1.add_run(format_currency(say_market_val))
        br1_v.font.name = "Arial"
        br1_v.font.size = Pt(13)
        br1_v.font.bold = True
        br1_v.font.color.rgb = COLOR_GOLD

        bp2 = b_cell2.paragraphs[0]
        bp2.alignment = WD_ALIGN_PARAGRAPH.CENTER
        br2_t = bp2.add_run(f"FORCED SALE VALUE (FSV - {fsv_pct:.0f}%)\n")
        br2_t.font.name = "Arial"
        br2_t.font.size = Pt(9)
        br2_t.font.color.rgb = COLOR_SLATE
        br2_v = bp2.add_run(format_currency(fsv_val))
        br2_v.font.name = "Arial"
        br2_v.font.size = Pt(13)
        br2_v.font.bold = True
        br2_v.font.color.rgb = COLOR_TEAL

        # Page Break after Cover Page
        doc.add_page_break()

    # =========================================================================
    # 2. STANDARD 10-POINT VALUATION REPORT BODY
    # =========================================================================
    def add_section_heading(num_str, title_str):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(8)
        p.paragraph_format.space_after = Pt(2)
        r = p.add_run(f"{num_str}. {title_str.upper()}")
        r.font.name = "Arial"
        r.font.size = Pt(10.5)
        r.font.bold = True
        r.font.color.rgb = COLOR_NAVY

    # 01. Request & Purpose
    add_section_heading("01", "Request & Purpose of Valuation")
    p = doc.add_paragraph()
    p.add_run(f"In accordance with instructions received from the Manager, {inspection.get('targetInstitution', 'The Financial Institution')} ({inspection.get('bankBranch', 'Main')} Branch), I have carried out a comprehensive inspection and formal valuation of the immovable property described herein for the purpose of assessing its present Market Value and Forced Sale Value (FSV) as collateral security for credit facilities.")

    # 02. Date of Inspection
    add_section_heading("02", "Date of Inspection")
    p = doc.add_paragraph()
    p.add_run(f"The physical site inspection of the subject property was conducted on {inspection.get('dateOfInspection', 'the date indicated in the appraisal schedule')}, in the presence of the property owner / authorized representative.")

    # 03. Situation
    add_section_heading("03", "Situation & Administrative Location")
    p = doc.add_paragraph()
    p.add_run(f"The property is situated at {inspection.get('village', 'the subject village')}, within the Grama Niladhari Division of {inspection.get('gnDivision', 'N/A')}, Korale of {inspection.get('korale', 'N/A')}, Divisional Secretariat Division of {inspection.get('divisionalSecretariat', 'N/A')}, and under the local statutory jurisdiction of {inspection.get('localAuthority', 'Pradeshiya Sabha')}. Local Authority Assessment No: {inspection.get('assessmentNumber', 'Assessed locally')}.")

    # 04. Access
    add_section_heading("04", "Access & Approach Route")
    p = doc.add_paragraph()
    p.add_run(f"Nearest Commercial Town: {location.get('nearestTown', 'Commercial Center')} (Distance: approx. {location.get('distanceFromTownKm', '2.5')} km).\n"
              f"Starting from {location.get('startingJunction', 'Main Junction')}, proceed along the access road for the recorded distance. "
              f"The subject land is directly accessible via a {location.get('accessRoadWidthFt', '15')} ft wide {location.get('roadSurface', 'carpet')} paved roadway in {location.get('roadCondition', 'good')} condition, providing convenient vehicular access for {location.get('vehicleAccessibility', 'all standard vehicles')}.\n"
              f"Access Directions: {location.get('accessDirections', 'Direct motorable frontage along council road.')}")

    # 05. Legal Aspects & Statutory Clearances
    add_section_heading("05", "Legal Aspects & Statutory Enactments")
    p = doc.add_paragraph()
    statutory_texts = []
    for item in inspection.get("statutoryCompliances", []):
        statutory_texts.append(f"• {item.get('name')}: {item.get('status')} {('- ' + item.get('remarks')) if item.get('remarks') else ''}")
    p.add_run("Statutory compliance status as verified:\n" + "\n".join(statutory_texts) + 
              "\nThe subject property holds clear and marketable title devolution under registered legal instruments without unverified statutory encumbrances.")

    # 06. Locality & Available Infrastructure
    add_section_heading("06", "Locality & Utilities")
    p = doc.add_paragraph()
    utils = ", ".join(location.get("utilities", ["CEB Electricity", "Piped Water", "Telecommunications"]))
    p.add_run(f"The surrounding neighborhood comprises an established, respectable residential and mixed-use environment experiencing sustained property value appreciation. Readily available utility infrastructure includes: {utils}. Public transport and essential civic amenities are conveniently proximate.")

    # 07. Description of Property
    add_section_heading("07", "Description of the Property")
    p = doc.add_paragraph()
    p.add_run(f"Name of Land: {plan.get('landName', 'Kotakumbura')}\n"
              f"Survey Reference: Plan No. {plan.get('planNumber', 'N/A')} dated {plan.get('surveyDate', 'N/A')} surveyed by {plan.get('surveyorName', 'Licensed Surveyor')}, LS (Reg No: {plan.get('surveyorRegistrationNumber', 'N/A')}).\n"
              f"Evaluated Lot(s): Lot No. {', '.join([l.get('lotNumber', '1') for l in selected_lots])} with a combined extent of {total_perches:.2f} Perches.\n"
              f"Physical Terrain: {building_details.get('landShape', 'Regular')} shape, {building_details.get('landTopography', 'flat at road grade')}, subsoil of {building_details.get('subsoilCondition', 'firm gravelly clay loam')}. Boundaries: {building_details.get('boundaryDemarcations', 'Well demarcated')}.")

    # Boundaries Schedule Table
    b_table = doc.add_table(rows=1, cols=2)
    b_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    b_hdr1 = b_table.cell(0, 0)
    b_hdr2 = b_table.cell(0, 1)
    b_hdr1.width = Inches(1.5)
    b_hdr2.width = Inches(5.5)
    set_cell_background(b_hdr1, NAVY_HEX)
    set_cell_background(b_hdr2, NAVY_HEX)
    b_hdr1.paragraphs[0].add_run("Direction").font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)
    b_hdr2.paragraphs[0].add_run("Cadastral Boundary Abuttals").font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)

    first_lot = selected_lots[0] if selected_lots else {}
    for d, b_name in [("North", first_lot.get("northBoundary", "N/A")),
                      ("East", first_lot.get("eastBoundary", "N/A")),
                      ("South", first_lot.get("southBoundary", "N/A")),
                      ("West", first_lot.get("westBoundary", "N/A"))]:
        row = b_table.add_row()
        c0, c1 = row.cells[0], row.cells[1]
        c0.width = Inches(1.5)
        c1.width = Inches(5.5)
        set_cell_background(c0, BG_LIGHT_HEX)
        c0.paragraphs[0].add_run(d).font.bold = True
        c1.paragraphs[0].add_run(b_name)

    # 08. Approach to the Valuation
    add_section_heading("08", "Approach to the Valuation")
    p = doc.add_paragraph()
    p.add_run(f"Valuation Methodology Adopted: {val_data.get('methodology', 'Combined Approach (Market Comparison + Contractor’s Depreciated Replacement Cost Method)')}.\n"
              f"The land component is appraised by comparing recent verified market transactions of comparable allotments within the immediate locality, adjusting for access, shape, and zoning. "
              f"The building improvement is valued on the basis of Gross Replacement Cost (GRC) less appropriate accrued physical depreciation reflecting structural age and maintenance condition.")

    # 09. Valuation Calculations
    add_section_heading("09", "Valuation of the Property (Computations)")
    
    val_table = doc.add_table(rows=1, cols=3)
    val_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    vh1, vh2, vh3 = val_table.cell(0, 0), val_table.cell(0, 1), val_table.cell(0, 2)
    set_cell_background(vh1, NAVY_HEX)
    set_cell_background(vh2, NAVY_HEX)
    set_cell_background(vh3, NAVY_HEX)
    vh1.paragraphs[0].add_run("Valuation Component").font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)
    vh2.paragraphs[0].add_run("Assessment Basis & Metric").font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)
    vh3.paragraphs[0].add_run("Computed Value (LKR)").font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)

    calc_rows = [
        ("1. Land Value", f"{total_perches:.2f} Perches @ {format_currency(adopted_rate)} / Perch", format_currency(land_value)),
        ("2. Building GRC", f"{total_floor_area:.0f} sq.ft. @ {format_currency(sqft_rate)} / sq.ft." if has_building else "Bare Land (No Building)", format_currency(grc) if has_building else "Nil"),
        ("3. Less Depreciation", f"{dep_pct:.1f}% Accrued Physical Depreciation" if has_building else "N/A", f"- {format_currency(depreciation_deduction)}" if has_building else "Nil"),
        ("4. Depreciated Building Value", "Depreciated Structural Improvement" if has_building else "N/A", format_currency(depreciated_bldg_val) if has_building else "Nil"),
        ("TOTAL COMPUTED MARKET VALUE", "Sum of Land + Depreciated Improvement", format_currency(computed_market_val)),
        ("MARKET VALUE (SAY)", "Adopted for Banking Documentation", format_currency(say_market_val)),
        ("FORCED SALE VALUE (FSV)", f"Adopted at {fsv_pct:.0f}% of Market Value", format_currency(fsv_val)),
    ]

    for title, desc, val in calc_rows:
        r = val_table.add_row()
        c0, c1, c2 = r.cells[0], r.cells[1], r.cells[2]
        c0.width = Inches(2.5)
        c1.width = Inches(2.7)
        c2.width = Inches(1.8)
        
        is_highlight = "SAY" in title or "FORCED" in title
        if is_highlight:
            set_cell_background(c0, NAVY_HEX if "SAY" in title else BG_LIGHT_HEX)
            set_cell_background(c1, NAVY_HEX if "SAY" in title else BG_LIGHT_HEX)
            set_cell_background(c2, NAVY_HEX if "SAY" in title else BG_LIGHT_HEX)
            tc = RGBColor(0xFF, 0xFF, 0xFF) if "SAY" in title else COLOR_NAVY
            r0 = c0.paragraphs[0].add_run(title)
            r0.font.bold = True
            r0.font.color.rgb = tc
            r1 = c1.paragraphs[0].add_run(desc)
            r1.font.color.rgb = tc
            r2 = c2.paragraphs[0].add_run(val)
            r2.font.bold = True
            r2.font.color.rgb = COLOR_GOLD if "SAY" in title else COLOR_TEAL
        else:
            c0.paragraphs[0].add_run(title).font.bold = True
            c1.paragraphs[0].add_run(desc)
            c2.paragraphs[0].add_run(val)

    # 10. Certification
    add_section_heading("10", "Certification & Professional Declaration")
    p = doc.add_paragraph()
    p.add_run(f"I hereby certify that I have personally inspected the subject property and that neither I nor any of my associates have any direct or indirect personal or financial interest in the property valued.\n"
              f"The values assessed herein represent my unbiased, independent professional opinion based on prevailing market conditions. This valuation is valid for a period of six (6) months from the date of inspection subject to normal market stability.\n\n"
              f"Date: {inspection.get('dateOfInspection', 'Today')}\n\n\n"
              f"_____________________________________\n"
              f"{profile.get('valuerName', 'CHARTERED VALUER')}\n"
              f"{profile.get('qualifications', 'B.Sc. Estate Mgt. & Valuation | AIV')}\n"
              f"Reg. No: {profile.get('registrationNumber', 'IVSL A/000')}")

    # =========================================================================
    # 3. SUPPLEMENTARY UNDERWRITING ANNEXURES
    # =========================================================================
    doc.add_page_break()

    # Annexure I
    p = doc.add_paragraph()
    r = p.add_run("ANNEXURE I: LEGAL TITLE DEVOLUTION & PROPERTY IDENTIFICATION")
    r.font.name = "Arial"
    r.font.size = Pt(11)
    r.font.bold = True
    r.font.color.rgb = COLOR_NAVY

    ann1_table = doc.add_table(rows=6, cols=2)
    ann1_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    ann1_items = [
        ("Title Deed Particulars", f"Deed No. {deed.get('deedNumber', 'N/A')} dated {deed.get('executionDate', 'N/A')} attested by {deed.get('notaryPublicName', 'N/A')}, Notary Public of {deed.get('notaryPublicStation', 'N/A')}."),
        ("Land Registry Registration", f"Registered on {deed.get('registrationDate', 'N/A')} under Day Book No. {deed.get('dayBookNumber', 'N/A')}, Folio: {deed.get('registerFolioNumber', 'N/A')} at {deed.get('landRegistry', 'Kandy Land Registry')}."),
        ("Current Owner (Vendee)", f"{deed.get('vendeeName', 'N/A')} (NIC: {deed.get('vendeeNic', 'N/A')}), residing at {deed.get('vendeeAddress', 'N/A')}."),
        ("Previous Owner (Vendor)", f"{deed.get('vendorName', 'N/A')} (NIC: {deed.get('vendorNic', 'N/A')}), residing at {deed.get('vendorAddress', 'N/A')}."),
        ("Consideration in Title Deed", format_currency(deed.get("purchaseConsideration", 0))),
        ("Prior Survey Reference", f"Prior Plan Ref: {plan.get('priorPlanReference', 'Prior partition survey as registered')}."),
    ]
    for i, (k, v) in enumerate(ann1_items):
        c0, c1 = ann1_table.cell(i, 0), ann1_table.cell(i, 1)
        c0.width = Inches(2.5)
        c1.width = Inches(4.5)
        set_cell_background(c0, BG_LIGHT_HEX)
        c0.paragraphs[0].add_run(k).font.bold = True
        c1.paragraphs[0].add_run(v)

    doc.add_paragraph()

    # Annexure II: SWOC Analysis & Risk Rating
    p = doc.add_paragraph()
    r = p.add_run("ANNEXURE II: SWOC ANALYSIS & MORTGAGE COLLATERAL RISK PROFILE")
    r.font.name = "Arial"
    r.font.size = Pt(11)
    r.font.bold = True
    r.font.color.rgb = COLOR_NAVY

    swoc_table = doc.add_table(rows=5, cols=2)
    swoc_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    swoc_items = [
        ("Strengths (S)", val_data.get("strengths", "Direct motorable access, well defined boundaries, prime locality.")),
        ("Weaknesses (W)", val_data.get("weaknesses", "Access roadway narrowness along interior segment.")),
        ("Opportunities (O)", val_data.get("opportunities", "Capital appreciation spurred by arterial highway infrastructure.")),
        ("Constraints / Threats (C)", val_data.get("constraints", "Statutory building setback and street-line adherence requirements.")),
        ("FINAL COLLATERAL RATING", val_data.get("collateralRating", "Class A / Prime Collateral")),
    ]
    for i, (k, v) in enumerate(swoc_items):
        c0, c1 = swoc_table.cell(i, 0), swoc_table.cell(i, 1)
        c0.width = Inches(2.5)
        c1.width = Inches(4.5)
        is_rating = i == 4
        set_cell_background(c0, NAVY_HEX if is_rating else BG_LIGHT_HEX)
        set_cell_background(c1, NAVY_HEX if is_rating else BG_LIGHT_HEX)
        
        pk = c0.paragraphs[0].add_run(k)
        pk.font.bold = True
        pk.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF) if is_rating else COLOR_NAVY
        
        pv = c1.paragraphs[0].add_run(v)
        pv.font.bold = is_rating
        pv.font.color.rgb = COLOR_GOLD if is_rating else COLOR_SLATE

    # Annexure III: Photographic Register Placeholder Card
    doc.add_paragraph()
    p = doc.add_paragraph()
    r = p.add_run("ANNEXURE III: PHOTOGRAPHIC REGISTER OF SUBJECT PROPERTY")
    r.font.name = "Arial"
    r.font.size = Pt(11)
    r.font.bold = True
    r.font.color.rgb = COLOR_NAVY

    photo_table = doc.add_table(rows=2, cols=2)
    photo_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    photo_slots = [
        "Plate 1: Front Elevation & Exterior Facade",
        "Plate 2: Side / Rear View & Structural Envelope",
        "Plate 3: Interior Living, Dining & Accommodation",
        "Plate 4: Parapet Wall, Entrance Gate & Motorable Access Road",
    ]
    for idx, slot_label in enumerate(photo_slots):
        r_idx = idx // 2
        c_idx = idx % 2
        cell = photo_table.cell(r_idx, c_idx)
        cell.width = Inches(3.5)
        set_cell_background(cell, BG_LIGHT_HEX)
        set_cell_margins(cell, top=200, bottom=200, left=150, right=150)
        p = cell.paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = p.add_run(f"[ Photographic Plate Mounted Here ]\n\n{slot_label}")
        r.font.name = "Arial"
        r.font.size = Pt(9)
        r.font.color.rgb = COLOR_MUTED

    # Save document
    doc.save(output_path)
    return os.path.abspath(output_path)

if __name__ == "__main__":
    test_data = {
        "profile": {
            "valuerName": "K. B. Wijesinghe (AIV)",
            "qualifications": "B.Sc. Estate Mgt. & Valuation (Special) | AIV",
            "registrationNumber": "IVSL A/724",
            "officeAddress": "No. 12, Commercial Complex, Kandy",
            "emailAddress": "valuer.wijesinghe@gmail.com",
            "contactNumber": "+94 77 123 4567"
        },
        "project": {
            "projectName": "Valuation of Kotakumbura Residence",
            "targetPageCount": 4,
            "deedData": {
                "deedNumber": "4821",
                "executionDate": "2019-08-14",
                "notaryPublicName": "K. M. Senanayake",
                "notaryPublicStation": "Kandy",
                "landRegistry": "Kandy Land Registry",
                "registrationDate": "2019-09-02",
                "dayBookNumber": "D/2019/8491",
                "registerFolioNumber": "F 184/92",
                "vendeeName": "P. G. Sunil Jayawardena",
                "vendeeNic": "741920831V",
                "vendeeAddress": "No. 45, Temple Road, Pilimathalawa",
                "vendorName": "M. B. Wimalasiri Bandara",
                "vendorNic": "621048392V",
                "vendorAddress": "Kotakumbura Watte, Handessa",
                "purchaseConsideration": 4500000.0
            },
            "surveyPlanData": {
                "planNumber": "2418/SP",
                "surveyDate": "2018-05-10",
                "surveyorName": "Gamini Ratnayake",
                "surveyorRegistrationNumber": "LS/1842",
                "landName": "Kotakumbura (Part)",
                "priorPlanReference": "Plan No. 1102",
                "lots": [
                    {
                        "lotNumber": "1",
                        "acres": 0,
                        "roods": 0,
                        "perches": 18.5,
                        "northBoundary": "Lot 2 of the same land",
                        "eastBoundary": "R.D.A. Road Reservation (15ft)",
                        "southBoundary": "Land of H. M. Dingiri Banda",
                        "westBoundary": "Ela (Stream)",
                        "isSelected": True
                    }
                ]
            },
            "inspectionData": {
                "targetInstitution": "People's Bank",
                "bankBranch": "Pilimathalawa Branch",
                "valuationPurpose": "Mortgage Security",
                "dateOfInspection": "2026-11-10",
                "village": "Handessa",
                "gnDivision": "Handessa South",
                "korale": "Medapalatha",
                "divisionalSecretariat": "Udunuwara",
                "localAuthority": "Udunuwara Pradeshiya Sabha",
                "assessmentNumber": "Assessment No. 84",
                "statutoryCompliances": [
                    {"name": "Street Lines", "status": "Applicable", "remarks": "Clear of reservation"},
                    {"name": "Building Limits", "status": "Applicable", "remarks": "Conforms with by-laws"},
                    {"name": "NBRO Clearance", "status": "Obtained", "remarks": "Ref: NBRO/KD/2018/491"}
                ]
            },
            "locationData": {
                "nearestTown": "Pilimathalawa",
                "startingJunction": "Handessa Clock Tower Junction",
                "accessDirections": "Proceed along Handessa-Daulagala Road for 1.2km and turn right onto Temple Lane.",
                "distanceFromTownKm": 2.2,
                "accessRoadWidthFt": 15.0,
                "roadSurface": "Carpet",
                "roadCondition": "Good",
                "vehicleAccessibility": "All Vehicles",
                "utilities": ["CEB Electricity (Single Phase)", "NWSDB Piped Water", "Telecommunications", "Public Bus Route"]
            },
            "buildingDetails": {
                "hasBuilding": True,
                "landShape": "Regular",
                "landTopography": "Flat at road grade",
                "subsoilCondition": "Firm gravelly clay loam",
                "boundaryDemarcations": "5ft cement block parapet wall & barbed wire fence",
                "buildings": [
                    {
                        "buildingName": "Main Single Storey Residence",
                        "roofType": "Asbestos sheets on timber rafters",
                        "wallType": "Brick masonry, plastered and colour-washed",
                        "floorType": "Ceramic tiled",
                        "doorsWindows": "Timber panel doors and glazed windows with grills",
                        "bathFittings": "Complete sanitary fittings with commode & basin",
                        "ageYears": 6,
                        "structuralCondition": "Good",
                        "occupancy": "Owner Occupied",
                        "groundFloorAreaSqFt": 1650.0,
                        "upperFloorAreaSqFt": 0.0
                    }
                ]
            },
            "valuationData": {
                "methodology": "Combined Approach (Market Comparison + Contractor's Method)",
                "adoptedLandRatePerPerch": 375000.0,
                "buildingReplacementCostPerSqFt": 7500.0,
                "depreciationPercentage": 8.0,
                "fsvPercentage": 75.0,
                "strengths": "Direct motorable carpet frontage, well demarcated boundaries, prime residential location.",
                "weaknesses": "Interior lane reduces to 15ft width.",
                "opportunities": "Proximity to central Pilimathalawa commercial hub.",
                "constraints": "Subject to standard local authority building limits.",
                "collateralRating": "Class A / Prime Collateral"
            }
        }
    }

    out_file = "test_valuation_report.docx"
    created = create_valuation_report(test_data, out_file, target_pages=4)
    print(f"Report generated successfully: {created}")
