#!/usr/bin/env python3
"""
Create LeaseBase MVP Jira Backlog
Creates 15 Epics and ~150 Stories using Jira Cloud REST API v3.

Usage:
    export JIRA_API_TOKEN="your-token"
    export JIRA_EMAIL="you@example.com"
    export JIRA_DOMAIN="yourorg.atlassian.net"
    export JIRA_PROJECT_KEY="LB"
    python create_leasebase_jira_backlog.py
"""

import base64
import json
import logging
import os
import sys
import time

import requests

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
log = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Configuration (from environment)
# ---------------------------------------------------------------------------
JIRA_API_TOKEN = os.environ.get("JIRA_API_TOKEN")
JIRA_EMAIL = os.environ.get("JIRA_EMAIL")
JIRA_DOMAIN = os.environ.get("JIRA_DOMAIN")
JIRA_PROJECT_KEY = os.environ.get("JIRA_PROJECT_KEY")

for var in ("JIRA_API_TOKEN", "JIRA_EMAIL", "JIRA_DOMAIN", "JIRA_PROJECT_KEY"):
    if not os.environ.get(var):
        log.error("Missing required environment variable: %s", var)
        sys.exit(1)

BASE_URL = f"https://{JIRA_DOMAIN}/rest/api/3"
AUTH_STR = base64.b64encode(f"{JIRA_EMAIL}:{JIRA_API_TOKEN}".encode()).decode()
HEADERS = {
    "Authorization": f"Basic {AUTH_STR}",
    "Content-Type": "application/json",
    "Accept": "application/json",
}
LABELS = ["leasebase", "mvp"]

# ---------------------------------------------------------------------------
# Backlog definition
# ---------------------------------------------------------------------------
BACKLOG: dict[str, list[dict]] = {
    "Authentication & User Management": [
        {
            "summary": "User Registration",
            "description": "Allow new users to register an account with email and password.",
            "acceptance": "User can register, receives confirmation email, and can log in.",
        },
        {
            "summary": "User Login",
            "description": "Authenticate users via email/password with JWT tokens.",
            "acceptance": "User can log in and receive a valid JWT; invalid credentials show error.",
        },
        {
            "summary": "Password Reset",
            "description": "Allow users to reset their password via email link.",
            "acceptance": "User receives reset email, can set new password, and log in with it.",
        },
        {
            "summary": "Multi-Factor Authentication",
            "description": "Add optional MFA via TOTP for user accounts.",
            "acceptance": "User can enable MFA, is prompted on login, and can disable it.",
        },
        {
            "summary": "Session Management",
            "description": "Manage active sessions and allow users to revoke them.",
            "acceptance": "User can view active sessions and revoke any session.",
        },
        {
            "summary": "OAuth2 Social Login",
            "description": "Support Google and Microsoft OAuth2 login.",
            "acceptance": "User can sign in with Google or Microsoft and account is linked.",
        },
        {
            "summary": "User Profile Management",
            "description": "Allow users to view and update their profile information.",
            "acceptance": "User can edit name, phone, avatar, and save changes.",
        },
        {
            "summary": "Account Deactivation",
            "description": "Allow users to deactivate their own account.",
            "acceptance": "User can deactivate; login is blocked; data is retained for 30 days.",
        },
        {
            "summary": "Audit Log for Auth Events",
            "description": "Log all authentication events (login, logout, password change).",
            "acceptance": "Admin can view auth event log with timestamps and IP addresses.",
        },
        {
            "summary": "API Key Management",
            "description": "Allow users to create and manage API keys for integrations.",
            "acceptance": "User can create, rotate, and revoke API keys.",
        },
    ],
    "Organization & Roles": [
        {
            "summary": "Create Organization",
            "description": "Allow account owner to create an organization (property management company).",
            "acceptance": "Organization is created with name, address, and billing info.",
        },
        {
            "summary": "Edit Organization",
            "description": "Allow admins to update organization details.",
            "acceptance": "Admin can change org name, address, logo, and contact info.",
        },
        {
            "summary": "Invite Team Members",
            "description": "Allow admins to invite users to the organization via email.",
            "acceptance": "Invite email is sent; user can accept and join the org.",
        },
        {
            "summary": "Role-Based Access Control",
            "description": "Implement roles: Owner, Admin, Property Manager, Maintenance Staff, Read-Only.",
            "acceptance": "Each role has correct permissions enforced on API and UI.",
        },
        {
            "summary": "Custom Roles",
            "description": "Allow admins to create custom roles with fine-grained permissions.",
            "acceptance": "Admin can create a role, assign permissions, and assign it to users.",
        },
        {
            "summary": "Remove Team Member",
            "description": "Allow admins to remove a user from the organization.",
            "acceptance": "Removed user loses access immediately; data ownership transfers.",
        },
        {
            "summary": "Organization Billing Settings",
            "description": "Manage subscription plan, payment method, and invoices.",
            "acceptance": "Admin can view plan, update card, and download invoices.",
        },
        {
            "summary": "Organization Activity Log",
            "description": "Track all changes made within the organization.",
            "acceptance": "Admin can filter activity log by user, action type, and date range.",
        },
        {
            "summary": "Team Member Directory",
            "description": "List all team members with roles and contact info.",
            "acceptance": "Directory shows name, role, email, phone; supports search and filter.",
        },
        {
            "summary": "Permission Inheritance",
            "description": "Child entities inherit permissions from parent (org → property → unit).",
            "acceptance": "Property manager assigned at org level has access to all properties.",
        },
    ],
    "Property Management": [
        {
            "summary": "Create Property",
            "description": "Allow property managers to add a new property with address and details.",
            "acceptance": "Property is created with address, type, photo, and appears in the list.",
        },
        {
            "summary": "Edit Property",
            "description": "Allow editing of property details such as name, address, and amenities.",
            "acceptance": "Changes are saved and reflected on the property detail page.",
        },
        {
            "summary": "Delete Property",
            "description": "Allow soft-deletion of a property that has no active leases.",
            "acceptance": "Property is archived; active lease check prevents accidental deletion.",
        },
        {
            "summary": "Property Details Page",
            "description": "Display property info, units, occupancy, financials, and documents.",
            "acceptance": "Page loads in < 2s and shows all sections with correct data.",
        },
        {
            "summary": "Property Owner Assignment",
            "description": "Link a property to one or more owners for reporting.",
            "acceptance": "Owner can be assigned/removed; owner statements reflect ownership.",
        },
        {
            "summary": "Property Photo Gallery",
            "description": "Upload and manage photos for a property listing.",
            "acceptance": "User can upload, reorder, and delete photos; thumbnails are generated.",
        },
        {
            "summary": "Property Search & Filters",
            "description": "Search properties by name, address, type, and status.",
            "acceptance": "Results update in real-time; filters combine with AND logic.",
        },
        {
            "summary": "Property Map View",
            "description": "Display properties on an interactive map.",
            "acceptance": "Map pins show property name; clicking a pin navigates to detail page.",
        },
        {
            "summary": "Property Financial Summary",
            "description": "Show revenue, expenses, NOI, and vacancy rate per property.",
            "acceptance": "Summary matches ledger totals; date range filter works correctly.",
        },
        {
            "summary": "Bulk Property Import",
            "description": "Import properties from CSV/Excel file.",
            "acceptance": "Import handles 500+ rows; validation errors are reported per row.",
        },
    ],
    "Unit Management": [
        {
            "summary": "Create Unit",
            "description": "Add a new unit to a property with details (number, beds, baths, sqft, rent).",
            "acceptance": "Unit is created and appears under the parent property.",
        },
        {
            "summary": "Edit Unit",
            "description": "Update unit details including rent amount and amenities.",
            "acceptance": "Changes are saved; if rent changes, future invoices reflect new amount.",
        },
        {
            "summary": "Assign Tenant to Unit",
            "description": "Link a tenant to a unit via a lease.",
            "acceptance": "Tenant appears on unit detail; unit shows as occupied.",
        },
        {
            "summary": "Unit Availability Tracking",
            "description": "Track and display unit availability with move-in dates.",
            "acceptance": "Available units are listed with expected availability date.",
        },
        {
            "summary": "Unit Status Tracking",
            "description": "Track unit statuses: Occupied, Vacant, Maintenance, Ready.",
            "acceptance": "Status changes are logged; dashboard reflects current statuses.",
        },
        {
            "summary": "Unit Floor Plan Upload",
            "description": "Upload floor plan images or PDFs for a unit.",
            "acceptance": "Floor plan is viewable on unit detail page.",
        },
        {
            "summary": "Unit Amenities Management",
            "description": "Tag units with amenities (washer/dryer, parking, pet-friendly).",
            "acceptance": "Amenities are filterable in search; displayed on unit detail.",
        },
        {
            "summary": "Unit Inspection Checklist",
            "description": "Create and complete move-in/move-out inspection checklists.",
            "acceptance": "Checklist can be filled out with notes and photos; PDF export works.",
        },
        {
            "summary": "Unit Turnover Workflow",
            "description": "Track tasks needed to prepare a unit for a new tenant.",
            "acceptance": "Workflow shows task list, assignments, and completion status.",
        },
        {
            "summary": "Bulk Unit Creation",
            "description": "Create multiple units at once for a property (e.g., units 101-120).",
            "acceptance": "Units are created with sequential numbering and shared defaults.",
        },
    ],
    "Tenant Management": [
        {
            "summary": "Create Tenant Profile",
            "description": "Add a new tenant with personal info, emergency contact, and documents.",
            "acceptance": "Tenant profile is created and searchable in the tenant directory.",
        },
        {
            "summary": "Edit Tenant Profile",
            "description": "Update tenant contact info, emergency contacts, and notes.",
            "acceptance": "Changes are saved and visible on the tenant detail page.",
        },
        {
            "summary": "Tenant Portal Access",
            "description": "Provide tenants with a self-service portal for payments and requests.",
            "acceptance": "Tenant can log in, view lease, make payments, and submit requests.",
        },
        {
            "summary": "Tenant Payment History",
            "description": "Display all payments made by a tenant with dates and amounts.",
            "acceptance": "History is accurate, sortable, and exportable to CSV.",
        },
        {
            "summary": "Tenant Maintenance History",
            "description": "Show all maintenance requests submitted by a tenant.",
            "acceptance": "History shows status, dates, and resolution details.",
        },
        {
            "summary": "Tenant Screening Integration",
            "description": "Integrate with a tenant screening service for credit/background checks.",
            "acceptance": "Screening can be initiated from the app; results are stored.",
        },
        {
            "summary": "Tenant Move-In Workflow",
            "description": "Guided workflow for onboarding a new tenant (lease, deposit, keys).",
            "acceptance": "All steps are tracked; incomplete steps show as pending.",
        },
        {
            "summary": "Tenant Move-Out Workflow",
            "description": "Guided workflow for tenant move-out (inspection, deposit return).",
            "acceptance": "Workflow tracks inspection, damages, deposit deductions, and refund.",
        },
        {
            "summary": "Tenant Communication Preferences",
            "description": "Allow tenants to set notification preferences (email, SMS, push).",
            "acceptance": "Preferences are saved and honored by the notification system.",
        },
        {
            "summary": "Tenant Directory & Search",
            "description": "List all tenants with search by name, property, unit, and lease status.",
            "acceptance": "Search returns results in < 1s; filters combine correctly.",
        },
    ],
    "Lease Management": [
        {
            "summary": "Create Lease",
            "description": "Create a new lease linking tenant, unit, dates, rent, and terms.",
            "acceptance": "Lease is created with all required fields; tenant and unit are linked.",
        },
        {
            "summary": "Edit Lease",
            "description": "Modify lease terms, dates, or rent amount.",
            "acceptance": "Changes are versioned; previous terms are accessible in history.",
        },
        {
            "summary": "Lease Expiration Tracking",
            "description": "Dashboard showing leases expiring in 30/60/90 days.",
            "acceptance": "Expiration list is accurate and sortable by date.",
        },
        {
            "summary": "Lease Renewal Workflow",
            "description": "Automated workflow to offer renewal with updated terms.",
            "acceptance": "Renewal offer is sent; tenant can accept/reject; new lease is created.",
        },
        {
            "summary": "Security Deposit Tracking",
            "description": "Track deposit amounts, interest, deductions, and refunds per lease.",
            "acceptance": "Deposit ledger is accurate; refund calculation follows state rules.",
        },
        {
            "summary": "Lease Document Generation",
            "description": "Auto-generate lease PDF from template with filled-in terms.",
            "acceptance": "Generated PDF matches template; all variables are correctly replaced.",
        },
        {
            "summary": "E-Signature Integration",
            "description": "Allow tenants and managers to sign leases electronically.",
            "acceptance": "Signature workflow completes; signed document is stored.",
        },
        {
            "summary": "Lease Charge Schedule",
            "description": "Define recurring and one-time charges associated with a lease.",
            "acceptance": "Charges auto-generate invoices on schedule; amounts are correct.",
        },
        {
            "summary": "Month-to-Month Conversion",
            "description": "Automatically convert expired leases to month-to-month.",
            "acceptance": "Expired leases show as month-to-month; charges continue.",
        },
        {
            "summary": "Lease Termination Workflow",
            "description": "Process early lease termination with fees and notice periods.",
            "acceptance": "Termination calculates fees, sends notice, and closes lease.",
        },
    ],
    "Rent Payments": [
        {
            "summary": "Pay Rent Online",
            "description": "Allow tenants to pay rent via ACH or credit card through the portal.",
            "acceptance": "Payment is processed; receipt is generated; ledger is updated.",
        },
        {
            "summary": "Payment Ledger",
            "description": "Maintain a detailed ledger of all charges and payments per lease.",
            "acceptance": "Ledger shows charges, payments, and running balance; totals are correct.",
        },
        {
            "summary": "Late Fee Automation",
            "description": "Automatically apply late fees based on configurable rules.",
            "acceptance": "Late fee is applied after grace period; amount follows configured rules.",
        },
        {
            "summary": "Payment Receipts",
            "description": "Generate and email payment receipts to tenants.",
            "acceptance": "Receipt shows date, amount, method, and balance; PDF is downloadable.",
        },
        {
            "summary": "Payment Reports",
            "description": "Generate reports on collected, outstanding, and overdue payments.",
            "acceptance": "Report matches ledger data; export to CSV/PDF works.",
        },
        {
            "summary": "Recurring Payment Setup",
            "description": "Allow tenants to set up autopay for recurring rent payments.",
            "acceptance": "Autopay processes on due date; tenant can cancel anytime.",
        },
        {
            "summary": "Partial Payment Handling",
            "description": "Accept and track partial payments against outstanding balances.",
            "acceptance": "Partial payment reduces balance; remaining amount is tracked.",
        },
        {
            "summary": "NSF / Failed Payment Handling",
            "description": "Handle returned payments with automatic NSF fee and notifications.",
            "acceptance": "Failed payment reverses credit; NSF fee is applied; tenant is notified.",
        },
        {
            "summary": "Owner Disbursements",
            "description": "Calculate and send rent proceeds to property owners.",
            "acceptance": "Disbursement deducts management fees; owner receives correct amount.",
        },
        {
            "summary": "Payment Gateway Integration",
            "description": "Integrate with Stripe for payment processing.",
            "acceptance": "Stripe processes payments; webhooks update ledger in real time.",
        },
    ],
    "Maintenance Management": [
        {
            "summary": "Submit Maintenance Request",
            "description": "Allow tenants to submit maintenance requests with description and photos.",
            "acceptance": "Request is created with category, priority, and photo attachments.",
        },
        {
            "summary": "Assign Vendor to Request",
            "description": "Allow property managers to assign a vendor to a maintenance request.",
            "acceptance": "Vendor is notified; request shows assigned vendor and ETA.",
        },
        {
            "summary": "Maintenance Status Tracking",
            "description": "Track request status: Submitted, Assigned, In Progress, Completed.",
            "acceptance": "Status changes are logged with timestamps; tenant sees updates.",
        },
        {
            "summary": "Maintenance Notifications",
            "description": "Notify tenants and managers on status changes via email and push.",
            "acceptance": "Notifications fire on each status change; preferences are honored.",
        },
        {
            "summary": "Maintenance History",
            "description": "View full maintenance history per unit and property.",
            "acceptance": "History is filterable by date, category, and status.",
        },
        {
            "summary": "Maintenance Priority & SLA",
            "description": "Set priority levels (Emergency, High, Medium, Low) with SLA targets.",
            "acceptance": "SLA countdown starts on submission; overdue requests are flagged.",
        },
        {
            "summary": "Work Order Generation",
            "description": "Generate printable work orders from maintenance requests.",
            "acceptance": "Work order PDF includes all request details and vendor info.",
        },
        {
            "summary": "Maintenance Cost Tracking",
            "description": "Track parts, labor, and total cost per maintenance request.",
            "acceptance": "Costs are entered per request; property expense report reflects them.",
        },
        {
            "summary": "Recurring Maintenance Schedules",
            "description": "Schedule recurring preventive maintenance (e.g., HVAC servicing).",
            "acceptance": "Requests auto-create on schedule; assigned vendor is notified.",
        },
        {
            "summary": "Maintenance Dashboard",
            "description": "Overview of open, in-progress, and completed requests with metrics.",
            "acceptance": "Dashboard shows counts, avg resolution time, and SLA compliance.",
        },
    ],
    "Vendor Management": [
        {
            "summary": "Add Vendor",
            "description": "Add a new vendor with contact info, specialties, and service areas.",
            "acceptance": "Vendor is created and appears in the vendor directory.",
        },
        {
            "summary": "Edit Vendor Profile",
            "description": "Update vendor contact info, insurance, and license details.",
            "acceptance": "Changes are saved; expired insurance/license triggers a warning.",
        },
        {
            "summary": "Vendor Assignment to Properties",
            "description": "Assign preferred vendors to specific properties or categories.",
            "acceptance": "Assigned vendors appear as suggestions when creating work orders.",
        },
        {
            "summary": "Vendor Performance Tracking",
            "description": "Track response time, completion rate, and ratings per vendor.",
            "acceptance": "Performance metrics are calculated from work order data.",
        },
        {
            "summary": "Vendor Payment Tracking",
            "description": "Track invoices and payments to vendors.",
            "acceptance": "Vendor ledger shows invoices, payments, and outstanding balance.",
        },
        {
            "summary": "Vendor Insurance & License Tracking",
            "description": "Track expiration dates and receive alerts for renewals.",
            "acceptance": "Alerts fire 30 days before expiration; expired vendors are flagged.",
        },
        {
            "summary": "Vendor Portal Access",
            "description": "Provide vendors with a portal to view and update work orders.",
            "acceptance": "Vendor can log in, view assigned work orders, and update status.",
        },
        {
            "summary": "Vendor Directory & Search",
            "description": "Search vendors by name, specialty, rating, and service area.",
            "acceptance": "Search returns results quickly; filters combine correctly.",
        },
        {
            "summary": "Vendor Bid Request",
            "description": "Send bid requests to multiple vendors for a maintenance job.",
            "acceptance": "Vendors receive bid request; bids are collected and comparable.",
        },
        {
            "summary": "Vendor Contract Management",
            "description": "Store and manage vendor service contracts and agreements.",
            "acceptance": "Contracts are uploaded, viewable, and expiration-tracked.",
        },
    ],
    "Messaging System": [
        {
            "summary": "Tenant Messaging",
            "description": "Allow managers and tenants to communicate via in-app messaging.",
            "acceptance": "Messages are delivered in real time; read receipts are shown.",
        },
        {
            "summary": "Vendor Messaging",
            "description": "Allow managers and vendors to communicate about work orders.",
            "acceptance": "Messages are linked to work orders; vendor receives notifications.",
        },
        {
            "summary": "Internal Staff Messaging",
            "description": "Allow staff members to message each other within the organization.",
            "acceptance": "Staff can send DMs and create group conversations.",
        },
        {
            "summary": "Message Attachments",
            "description": "Support photo, document, and file attachments in messages.",
            "acceptance": "Attachments upload, preview inline, and are downloadable.",
        },
        {
            "summary": "Broadcast Announcements",
            "description": "Send announcements to all tenants of a property or portfolio.",
            "acceptance": "Announcement reaches all targeted tenants via preferred channels.",
        },
        {
            "summary": "Message Templates",
            "description": "Create reusable message templates for common communications.",
            "acceptance": "Templates support variables; manager can select and customize before sending.",
        },
        {
            "summary": "SMS Integration",
            "description": "Send and receive SMS messages to/from tenants and vendors.",
            "acceptance": "SMS is sent via Twilio; replies are captured in the conversation.",
        },
        {
            "summary": "Email Integration",
            "description": "Send messages as emails; capture email replies in the conversation.",
            "acceptance": "Outbound emails are branded; inbound replies are threaded correctly.",
        },
        {
            "summary": "Message Search",
            "description": "Full-text search across all conversations.",
            "acceptance": "Search returns relevant messages with context; results are paginated.",
        },
        {
            "summary": "Conversation Archive",
            "description": "Archive old conversations to keep the inbox clean.",
            "acceptance": "Archived conversations are hidden from inbox but searchable.",
        },
    ],
    "Reporting & Analytics": [
        {
            "summary": "Rent Roll Report",
            "description": "Generate a rent roll showing all units, tenants, and rent amounts.",
            "acceptance": "Report is accurate, shows current lease terms, and exports to CSV/PDF.",
        },
        {
            "summary": "Occupancy Report",
            "description": "Report on occupancy rates by property and portfolio.",
            "acceptance": "Report shows occupied/vacant counts and percentage over time.",
        },
        {
            "summary": "Delinquency Report",
            "description": "Report on overdue balances by tenant and property.",
            "acceptance": "Report lists delinquent tenants with amounts and days overdue.",
        },
        {
            "summary": "Owner Statement Report",
            "description": "Generate monthly owner statements with income, expenses, and net.",
            "acceptance": "Statement matches ledger; PDF is formatted for mailing.",
        },
        {
            "summary": "Maintenance Expense Report",
            "description": "Report on maintenance costs by property, category, and vendor.",
            "acceptance": "Report totals match individual work order costs.",
        },
        {
            "summary": "Lease Expiration Report",
            "description": "Report on upcoming lease expirations grouped by timeframe.",
            "acceptance": "Report shows leases expiring in 30/60/90/120 days.",
        },
        {
            "summary": "Revenue & Expense Report",
            "description": "Profit and loss report by property and portfolio.",
            "acceptance": "Report shows income categories, expense categories, and net income.",
        },
        {
            "summary": "Vacancy Loss Report",
            "description": "Calculate potential revenue lost due to vacant units.",
            "acceptance": "Report shows vacancy days and estimated lost rent per unit.",
        },
        {
            "summary": "Custom Report Builder",
            "description": "Allow users to build custom reports with selected fields and filters.",
            "acceptance": "User can select columns, apply filters, save report, and schedule it.",
        },
        {
            "summary": "Scheduled Report Delivery",
            "description": "Schedule reports to be emailed on a recurring basis.",
            "acceptance": "Reports are generated and emailed on schedule; format is configurable.",
        },
    ],
    "Document Management": [
        {
            "summary": "Upload Documents",
            "description": "Upload documents and associate them with properties, units, tenants, or leases.",
            "acceptance": "Documents upload successfully; association is correct; preview works.",
        },
        {
            "summary": "Document Categories & Tags",
            "description": "Organize documents with categories (lease, insurance, inspection) and tags.",
            "acceptance": "Documents can be filtered by category and tags.",
        },
        {
            "summary": "Document Version History",
            "description": "Track document versions when a new version is uploaded.",
            "acceptance": "Previous versions are accessible; current version is clearly marked.",
        },
        {
            "summary": "Document Expiration Alerts",
            "description": "Set expiration dates on documents and receive alerts.",
            "acceptance": "Alerts fire before expiration; expired documents are flagged.",
        },
        {
            "summary": "Bulk Document Upload",
            "description": "Upload multiple documents at once via drag-and-drop.",
            "acceptance": "Multiple files upload with progress indicators; errors are reported.",
        },
        {
            "summary": "Document Search",
            "description": "Full-text search within document names and metadata.",
            "acceptance": "Search returns relevant documents; results are filterable.",
        },
        {
            "summary": "Document Sharing",
            "description": "Share documents with tenants or vendors via secure link.",
            "acceptance": "Shared link requires authentication; access can be revoked.",
        },
        {
            "summary": "Lease Document Templates",
            "description": "Manage reusable lease and notice templates.",
            "acceptance": "Templates are editable; variables auto-fill from lease data.",
        },
        {
            "summary": "Document OCR Processing",
            "description": "Extract text from scanned documents for search indexing.",
            "acceptance": "Scanned documents are searchable after OCR processing.",
        },
        {
            "summary": "Document Retention Policy",
            "description": "Configure auto-archival and deletion policies for old documents.",
            "acceptance": "Documents are archived/deleted per policy; admin can override.",
        },
    ],
    "Notifications": [
        {
            "summary": "Email Notifications",
            "description": "Send email notifications for key events (payment, maintenance, lease).",
            "acceptance": "Emails are delivered with correct content and branding.",
        },
        {
            "summary": "Push Notifications",
            "description": "Send browser and mobile push notifications.",
            "acceptance": "Push notifications appear on subscribed devices.",
        },
        {
            "summary": "SMS Notifications",
            "description": "Send SMS for urgent notifications (emergency maintenance, payment due).",
            "acceptance": "SMS is delivered; opt-out is supported.",
        },
        {
            "summary": "In-App Notification Center",
            "description": "Display notifications within the app with read/unread status.",
            "acceptance": "Notifications appear in real time; marking as read works.",
        },
        {
            "summary": "Notification Preferences",
            "description": "Allow users to configure which notifications they receive and how.",
            "acceptance": "Preferences are saved per user and honored by all notification channels.",
        },
        {
            "summary": "Rent Due Reminders",
            "description": "Automatic reminders before rent is due (7 days, 3 days, due date).",
            "acceptance": "Reminders fire on schedule; only sent to tenants with balances.",
        },
        {
            "summary": "Lease Expiration Alerts",
            "description": "Notify managers of upcoming lease expirations at configurable intervals.",
            "acceptance": "Alerts fire at 90, 60, and 30 days before expiration.",
        },
        {
            "summary": "Maintenance Status Alerts",
            "description": "Notify tenants when maintenance request status changes.",
            "acceptance": "Alert is sent on each status transition via preferred channel.",
        },
        {
            "summary": "Payment Confirmation Alerts",
            "description": "Notify tenants when payment is received and processed.",
            "acceptance": "Confirmation includes amount, date, and updated balance.",
        },
        {
            "summary": "Overdue Payment Alerts",
            "description": "Notify managers and tenants of overdue payments.",
            "acceptance": "Alert includes amount overdue and days past due.",
        },
    ],
    "Dashboard & UI": [
        {
            "summary": "Manager Dashboard",
            "description": "Overview dashboard for property managers with key metrics and actions.",
            "acceptance": "Dashboard shows occupancy, revenue, open requests, and expiring leases.",
        },
        {
            "summary": "Tenant Dashboard",
            "description": "Tenant-facing dashboard showing balance, lease info, and requests.",
            "acceptance": "Dashboard shows current balance, next payment due, and open requests.",
        },
        {
            "summary": "Owner Dashboard",
            "description": "Property owner dashboard with portfolio performance and statements.",
            "acceptance": "Dashboard shows properties, revenue, expenses, and NOI.",
        },
        {
            "summary": "Global Search",
            "description": "Search across properties, units, tenants, and leases from one search bar.",
            "acceptance": "Results are grouped by entity type; navigation works correctly.",
        },
        {
            "summary": "Dark Mode",
            "description": "Support light and dark themes across the application.",
            "acceptance": "Theme toggle works; all components render correctly in both modes.",
        },
        {
            "summary": "Mobile Responsive Design",
            "description": "Ensure all pages are fully responsive on mobile devices.",
            "acceptance": "Pages render correctly on 320px to 1440px+ widths.",
        },
        {
            "summary": "Data Table Components",
            "description": "Reusable data tables with sorting, filtering, pagination, and export.",
            "acceptance": "Tables handle 10k+ rows; sorting and filtering are performant.",
        },
        {
            "summary": "Onboarding Wizard",
            "description": "Step-by-step wizard for new users to set up their organization.",
            "acceptance": "Wizard guides through org creation, property setup, and first unit.",
        },
        {
            "summary": "Quick Actions Menu",
            "description": "Floating action menu for common tasks (add property, create lease).",
            "acceptance": "Menu is accessible from all pages; actions navigate correctly.",
        },
        {
            "summary": "Accessibility Compliance (WCAG 2.1 AA)",
            "description": "Ensure the UI meets WCAG 2.1 AA accessibility standards.",
            "acceptance": "Audit passes with no critical violations; screen reader navigation works.",
        },
    ],
    "AI Assistant": [
        {
            "summary": "AI Maintenance Categorization",
            "description": "Automatically categorize and prioritize maintenance requests using AI.",
            "acceptance": "AI assigns correct category and priority for 90%+ of requests.",
        },
        {
            "summary": "AI Rent Reminder",
            "description": "AI-powered personalized rent reminders based on payment patterns.",
            "acceptance": "Reminders are tailored to tenant behavior; timing adapts over time.",
        },
        {
            "summary": "AI Lease Analyzer",
            "description": "AI analysis of lease documents to extract key terms and flag risks.",
            "acceptance": "AI extracts rent, dates, clauses; flags unusual terms.",
        },
        {
            "summary": "AI Tenant Assistant Chatbot",
            "description": "Chatbot for tenants to answer FAQs, submit requests, and check status.",
            "acceptance": "Chatbot handles common queries; escalates to human when needed.",
        },
        {
            "summary": "AI Expense Categorization",
            "description": "Auto-categorize expenses from receipts and invoices using AI.",
            "acceptance": "AI categorizes expenses with 95%+ accuracy; user can override.",
        },
        {
            "summary": "AI Market Rent Analysis",
            "description": "Suggest optimal rent prices based on market data and property features.",
            "acceptance": "AI provides rent range with comparable properties; sources are cited.",
        },
        {
            "summary": "AI Communication Drafting",
            "description": "Draft tenant and vendor communications using AI.",
            "acceptance": "AI generates contextual drafts; user can edit before sending.",
        },
        {
            "summary": "AI Anomaly Detection",
            "description": "Detect anomalies in payments, maintenance, and occupancy patterns.",
            "acceptance": "Anomalies are flagged with explanations; false positive rate is < 10%.",
        },
        {
            "summary": "AI Predictive Maintenance",
            "description": "Predict maintenance issues based on historical data and property age.",
            "acceptance": "Predictions are shown on property dashboard with confidence scores.",
        },
        {
            "summary": "AI Lease Renewal Recommendations",
            "description": "Recommend renewal terms based on market data and tenant history.",
            "acceptance": "Recommendations include suggested rent and term with justification.",
        },
    ],
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _adf_text(text: str) -> dict:
    """Return Atlassian Document Format (ADF) body for plain text."""
    return {
        "type": "doc",
        "version": 1,
        "content": [
            {
                "type": "paragraph",
                "content": [{"type": "text", "text": text}],
            }
        ],
    }


def _build_description(description: str, acceptance: str) -> dict:
    """Build an ADF description that includes acceptance criteria."""
    return {
        "type": "doc",
        "version": 1,
        "content": [
            {
                "type": "paragraph",
                "content": [{"type": "text", "text": description}],
            },
            {
                "type": "paragraph",
                "content": [
                    {
                        "type": "text",
                        "text": "Acceptance Criteria:",
                        "marks": [{"type": "strong"}],
                    }
                ],
            },
            {
                "type": "paragraph",
                "content": [{"type": "text", "text": acceptance}],
            },
        ],
    }


def _rate_limit_pause():
    """Small pause to avoid Jira rate limits."""
    time.sleep(0.3)


# ---------------------------------------------------------------------------
# Epic link field discovery
# ---------------------------------------------------------------------------
_epic_link_field_id: str | None = None
_epic_name_field_id: str | None = None


def discover_custom_fields():
    """Find the custom field IDs for Epic Link and Epic Name."""
    global _epic_link_field_id, _epic_name_field_id
    log.info("Discovering custom fields for Epic Link and Epic Name...")
    resp = requests.get(f"{BASE_URL}/field", headers=HEADERS, timeout=30)
    resp.raise_for_status()
    fields = resp.json()
    for f in fields:
        name_lower = (f.get("name") or "").lower()
        if name_lower == "epic link":
            _epic_link_field_id = f["id"]
            log.info("  Epic Link field: %s", _epic_link_field_id)
        if name_lower == "epic name":
            _epic_name_field_id = f["id"]
            log.info("  Epic Name field: %s", _epic_name_field_id)
    if not _epic_link_field_id:
        log.warning(
            "Could not find 'Epic Link' custom field. "
            "Stories will be linked to epics via the parent field instead."
        )


# ---------------------------------------------------------------------------
# Jira API wrappers
# ---------------------------------------------------------------------------

def create_epic(name: str, description: str) -> tuple[str, str]:
    """Create an Epic and return (issue key, issue id)."""
    payload: dict = {
        "fields": {
            "project": {"key": JIRA_PROJECT_KEY},
            "summary": name,
            "description": _adf_text(description),
            "issuetype": {"name": "Epic"},
            "labels": LABELS,
        }
    }
    # Some Jira instances require the Epic Name custom field
    if _epic_name_field_id:
        payload["fields"][_epic_name_field_id] = name

    resp = requests.post(
        f"{BASE_URL}/issue",
        headers=HEADERS,
        data=json.dumps(payload),
        timeout=30,
    )
    if resp.status_code not in (200, 201):
        log.error("Failed to create epic '%s': %s %s", name, resp.status_code, resp.text)
        resp.raise_for_status()
    data = resp.json()
    key = data["key"]
    issue_id = data["id"]
    log.info("✅ Created Epic: %s – %s", key, name)
    _rate_limit_pause()
    return key, issue_id


def create_story(
    summary: str,
    description: str,
    acceptance: str,
    epic_key: str,
    epic_id: str,
) -> str:
    """Create a Story linked to an Epic and return the issue key."""
    payload: dict = {
        "fields": {
            "project": {"key": JIRA_PROJECT_KEY},
            "summary": summary,
            "description": _build_description(description, acceptance),
            "issuetype": {"name": "Story"},
            "labels": LABELS,
        }
    }

    # Link to epic – try Epic Link custom field first, fall back to parent
    if _epic_link_field_id:
        payload["fields"][_epic_link_field_id] = epic_key
    else:
        # Next-gen / team-managed projects use the parent field
        payload["fields"]["parent"] = {"key": epic_key}

    resp = requests.post(
        f"{BASE_URL}/issue",
        headers=HEADERS,
        data=json.dumps(payload),
        timeout=30,
    )
    if resp.status_code not in (200, 201):
        log.error(
            "Failed to create story '%s' under %s: %s %s",
            summary,
            epic_key,
            resp.status_code,
            resp.text,
        )
        resp.raise_for_status()
    data = resp.json()
    key = data["key"]
    log.info("   ✅ Story: %s – %s (epic: %s)", key, summary, epic_key)
    _rate_limit_pause()
    return key


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    log.info("=" * 60)
    log.info("LeaseBase MVP Backlog Creator")
    log.info("Project: %s | Domain: %s", JIRA_PROJECT_KEY, JIRA_DOMAIN)
    log.info("=" * 60)

    discover_custom_fields()

    total_epics = 0
    total_stories = 0
    all_keys: list[str] = []

    for epic_name, stories in BACKLOG.items():
        epic_desc = f"Epic for all {epic_name} features in LeaseBase MVP."
        epic_key, epic_id = create_epic(epic_name, epic_desc)
        all_keys.append(epic_key)
        total_epics += 1

        for story in stories:
            story_key = create_story(
                summary=story["summary"],
                description=story["description"],
                acceptance=story["acceptance"],
                epic_key=epic_key,
                epic_id=epic_id,
            )
            all_keys.append(story_key)
            total_stories += 1

    log.info("=" * 60)
    log.info("🎉 Backlog creation complete!")
    log.info("   Epics created:   %d", total_epics)
    log.info("   Stories created:  %d", total_stories)
    log.info("   Total tickets:    %d", total_epics + total_stories)
    log.info("=" * 60)
    log.info("All ticket keys:\n%s", "\n".join(all_keys))


if __name__ == "__main__":
    main()
